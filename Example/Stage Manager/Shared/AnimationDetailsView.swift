//
//  AnimationDetailsView.swift
//  Stagehand
//
//  Created by Nick Entin on 2/15/22.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import Memo
import StageManagerPrimitives
import SwiftUI

struct AnimationDetailsView: View {

    init(
        animation: SerializableAnimationBlueprint,
        transceiver: Transceiver,
        blueprintForID: @escaping (Token<SerializableAnimationBlueprint>) -> SerializableAnimationBlueprint?
    ) {
        self.durationFormatter = NumberFormatter()
        durationFormatter.maximumFractionDigits = 2

        self._animation = State(initialValue: animation)
        self._selectedEffectiveRepeatStyle = State(initialValue: .init(animation.implicitRepeatStyle))
        self.transceiver = transceiver
        self.blueprintForID = blueprintForID

        self.undoManager = .init(animation)
    }

    @State
    var animation: SerializableAnimationBlueprint

    @ObservedObject
    var transceiver: Transceiver

    private let blueprintForID: (Token<SerializableAnimationBlueprint>) -> SerializableAnimationBlueprint?

    @State
    private var selectedEffectiveRepeatStyle: EffectiveRepeatStyle

    let durationFormatter: NumberFormatter
    var formattedImplicitDuration: String {
        let formattedNumber = durationFormatter.string(from: animation.implicitDuration as NSNumber)!
        return "\(formattedNumber) sec"
    }

    @State
    private var showDocumentPicker: Bool = false

    // TODO: This doesn't current track changes to `selectedEffectiveRepeatStyle`
    @ObservedObject
    private var undoManager: UndoManager<SerializableAnimationBlueprint>

    #if os(iOS)
    @Environment(\.horizontalSizeClass)
    private var horizontalSizeClass
    #endif

    private var shouldUseSingleToolbarItem: Bool {
        #if os(iOS)
        return horizontalSizeClass == .compact
        #else
        return false
        #endif
    }

    var body: some View {
        ScrollView {
            StepperRow(
                title: "Implicit Duration",
                onIncrement: { animation.implicitDuration += 0.1 },
                onDecrement: { animation.implicitDuration -= 0.1 },
                getValue: { formattedImplicitDuration }
            )
            RepeatStyleRows(selectedEffectiveRepeatStyle: $selectedEffectiveRepeatStyle, animation: $animation)
            ForEach($animation.managedKeyframeSeries) { series in
                KeyframeSeriesView(keyframeSeries: series)
            }
            ForEach($animation.unmanagedKeyframeSeries) { series in
                SwitchRow(title: series.wrappedValue.name, isOn: series.enabled)
            }
            // TODO: Show managed property assignments
            // TODO: Show unmanaged property assignments
            ForEach($animation.managedExecutionBlockConfigs) { config in
                ManagedExecutionView(managedExecutionConfig: config)
            }
            // TODO: Show unmanaged execution blocks
            // TODO: Show unmanaged per-frame execution blocks
            ForEach($animation.managedChildAnimations) { child in
                SwitchRow(
                    title: child.wrappedValue.name,
                    isOn: child.enabled,
                    titleDestination: blueprintForID(child.wrappedValue.animationID).map { blueprint in
                        {
                            AnimationDetailsView(
                                animation: blueprint,
                                transceiver: transceiver,
                                blueprintForID: blueprintForID
                            )
                        }
                    }
                )
            }
            // TODO: Show child blueprints
            // TODO: Show unmanaged child animations
        }
        .navigationTitle(animation.name)
        // TODO: Disable the update button when transceiver has no active connection
        Button {
            Task {
                try await transceiver.updateAnimation(animation)
            }
        } label: {
            Text("Update")
                .frame(maxWidth: .infinity)
                .padding([.vertical])
                .background(Color.blue)
                .foregroundColor(Color.white)
                .cornerRadius(8)
        }
        .padding()
        .onChange(of: selectedEffectiveRepeatStyle) { newValue in
            switch selectedEffectiveRepeatStyle {
            case .noRepeat:
                animation.implicitRepeatStyle.count = 1
            case .repeating:
                animation.implicitRepeatStyle.count = max(animation.implicitRepeatStyle.count, 2)
            case .infinitelyRepeating:
                animation.implicitRepeatStyle.count = 0
            }
        }
        .onChange(of: animation) { newValue in
            undoManager.register(newValue)
        }
        .toolbar {
            HStack {
                if shouldUseSingleToolbarItem {
                    Menu {
                        Button {
                            animation = undoManager.undo()
                        } label: {
                            Label("Undo", systemImage: "arrow.uturn.backward")
                        }
                        .flipsForRightToLeftLayoutDirection(false)
                        .disabled(!undoManager.canUndo)
                        Button {
                            animation = undoManager.redo()
                        } label: {
                            Label("Redo", systemImage: "arrow.uturn.forward")
                        }
                        .flipsForRightToLeftLayoutDirection(false)
                        .disabled(!undoManager.canRedo)
                        Button {
                            print("Export spec")
                        } label: {
                            Label("Export", systemImage: "square.and.arrow.up")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                    }

                } else {
                    Button {
                        animation = undoManager.undo()
                    } label: {
                        Image(systemName: "arrow.uturn.backward")
                            .accessibilityLabel("Undo")
                    }
                    .flipsForRightToLeftLayoutDirection(false)
                    .disabled(!undoManager.canUndo)
                    Button {
                        animation = undoManager.redo()
                    } label: {
                        Image(systemName: "arrow.uturn.forward")
                            .accessibilityLabel("Redo")
                    }
                    .flipsForRightToLeftLayoutDirection(false)
                    .disabled(!undoManager.canRedo)
                    Button {
                        print("Export spec")
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .accessibilityLabel("Export")
                    }
                }
            }
        }
    }

}

struct RepeatStyleRows: View {

    init(
        selectedEffectiveRepeatStyle: Binding<EffectiveRepeatStyle>,
        animation: Binding<SerializableAnimationBlueprint>
    ) {
        self.selectedEffectiveRepeatStyle = selectedEffectiveRepeatStyle
        self.animation = animation
    }

    let selectedEffectiveRepeatStyle: Binding<EffectiveRepeatStyle>
    let animation: Binding<SerializableAnimationBlueprint>

    var body: some View {
        HStack {
            Text("Implicit Repeat Style")
            Spacer()
            Picker("Implicit Repeat Style", selection: selectedEffectiveRepeatStyle) {
                Text("No Repeat").tag(EffectiveRepeatStyle.noRepeat)
                Text("Repeating").tag(EffectiveRepeatStyle.repeating)
                Text("Infinitely Repeating").tag(EffectiveRepeatStyle.infinitelyRepeating)
            }
        }
        .padding()
        if case .repeating = selectedEffectiveRepeatStyle.wrappedValue {
            HStack {
                Spacer(minLength: 32)
                StepperRow(
                    title: "Repeat Count",
                    onIncrement: { animation.wrappedValue.implicitRepeatStyle.count += 1 },
                    onDecrement: { animation.wrappedValue.implicitRepeatStyle.count = max(animation.wrappedValue.implicitRepeatStyle.count - 1, 2) },
                    getValue: { "\(animation.wrappedValue.implicitRepeatStyle.count)" }
                )
            }
            HStack {
                Spacer(minLength: 32)
                SwitchRow(
                    title: "Autoreversing",
                    isOn: animation.implicitRepeatStyle.autoreversing
                )
            }
        }
        if case .infinitelyRepeating = selectedEffectiveRepeatStyle.wrappedValue {
            HStack {
                Spacer(minLength: 32)
                SwitchRow(
                    title: "Autoreversing",
                    isOn: animation.implicitRepeatStyle.autoreversing
                )
            }
        }
    }

}

enum EffectiveRepeatStyle {
    case noRepeat
    case infinitelyRepeating
    case repeating

    init(_ repeatStyle: SerializableAnimationBlueprint.RepeatStyle) {
        switch repeatStyle.count {
        case 1:
            self = .noRepeat
        case 0:
            self = .infinitelyRepeating
        default:
            self = .repeating
        }
    }
}
