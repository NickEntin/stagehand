//
//  ManagedExecutionView.swift
//  Stagehand
//
//  Created by Nick Entin on 3/8/22.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import StageManagerPrimitives
import SwiftUI

struct ManagedExecutionView: View {

    init(
        managedExecutionConfig: Binding<AnimationBlueprint.ManagedExecutionBlockConfig>
    ) {
        self.managedExecutionConfig = managedExecutionConfig
    }

    let managedExecutionConfig: Binding<AnimationBlueprint.ManagedExecutionBlockConfig>

    var body: some View {
        ForEach(managedExecutionConfig.controls) { control in
            switch control.wrappedValue {
            case let .intSelection(selection):
                SelectionControlView(selectionControl: selection) { updatedSelectedOption in
                    managedExecutionConfig.wrappedValue.controls = managedExecutionConfig.wrappedValue.controls.map { existingControl in
                        if existingControl.id == control.wrappedValue.id {
                            return .intSelection(
                                ExecutionBlockControl.Selection<Int>(
                                    id: selection.id,
                                    name: selection.name,
                                    availableOptions: selection.availableOptions,
                                    selectedOption: updatedSelectedOption
                                )
                            )
                        } else {
                            return existingControl
                        }
                    }
                }
            }
        }
    }

}

private struct SelectionControlView<OptionType: Hashable>: View {

    // SwiftUI requires `Picker` to use a `Binding`, which doesn't work when you're trying to update the associated
    // value of an enum, like we need to do with `ExecutionBlockControl.Selection`. This view is essentially a `Picker`
    // that uses an update closure instead.

    init(selectionControl: ExecutionBlockControl.Selection<OptionType>, onUpdate: @escaping (OptionType) -> Void) {
        self.name = selectionControl.name
        self.onUpdate = onUpdate

        self.availableOptions = selectionControl.availableOptions.map { displayName, value in
            AvailableOption(displayName: displayName, value: value)
        }

        _selectedValue = State(wrappedValue: selectionControl.selectedOption)
    }

    struct AvailableOption: Identifiable {

        var id: OptionType {
            return value
        }

        var displayName: String

        var value: OptionType

    }

    let name: String
    let onUpdate: (OptionType) -> Void
    let availableOptions: [AvailableOption]

    @State
    var selectedValue: OptionType

    var body: some View {
        HStack {
            Text(name)
            Spacer()
            Picker(name, selection: $selectedValue) {
                ForEach(availableOptions) { option in
                    Text(option.displayName).tag(option.value)
                }
            }
            .onChange(of: selectedValue) { newValue in
                onUpdate(newValue)
            }
        }
        .padding()
    }

}
