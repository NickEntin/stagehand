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

    init(animation: AnimationBlueprint, transceiver: Transceiver) {
        self.durationFormatter = NumberFormatter()
        durationFormatter.maximumFractionDigits = 2

        self._animation = State(initialValue: animation)
        self._selectedEffectiveRepeatStyle = State(initialValue: .init(animation.implicitRepeatStyle))
        self.transceiver = transceiver
    }

    @State
    var animation: AnimationBlueprint

    @ObservedObject
    var transceiver: Transceiver

    @State
    private var selectedEffectiveRepeatStyle: EffectiveRepeatStyle

    let durationFormatter: NumberFormatter
    var formattedImplicitDuration: String {
        let formattedNumber = durationFormatter.string(from: animation.implicitDuration as NSNumber)!
        return "\(formattedNumber) sec"
    }

    @State
    private var showDocumentPicker: Bool = false

    @State
    private var dataToImport: Data?

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
            // TODO: Show managed execution blocks
        }
        .navigationTitle(animation.name)
        HStack {
            Button("Update") {
                Task {
                    try await transceiver.updateAnimation(animation)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
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
        .toolbar {
            Button {
                print("Import file")
                showDocumentPicker = true
            } label: {
                Image(systemName: "square.and.arrow.down")
            }
            Button {
                print("Export file")
            } label: {
                Image(systemName: "square.and.arrow.up")
            }
        }
        .onChange(of: dataToImport) { dataToImport in

        }
    }

}

struct RepeatStyleRows: View {

    init(
        selectedEffectiveRepeatStyle: Binding<EffectiveRepeatStyle>,
        animation: Binding<AnimationBlueprint>
    ) {
        self.selectedEffectiveRepeatStyle = selectedEffectiveRepeatStyle
        self.animation = animation
    }

    let selectedEffectiveRepeatStyle: Binding<EffectiveRepeatStyle>
    let animation: Binding<AnimationBlueprint>

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

    init(_ repeatStyle: AnimationBlueprint.RepeatStyle) {
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
