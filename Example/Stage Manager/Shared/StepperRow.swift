//
//  StepperRow.swift
//  Stagehand
//
//  Created by Nick Entin on 2/18/22.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import SwiftUI

struct StepperRow: View {

    init(
        title: String,
        onIncrement: @escaping (() -> Void),
        onDecrement: @escaping (() -> Void),
        getValue: @escaping (() -> String)
    ) {
        self.title = title
        self.onIncrement = onIncrement
        self.onDecrement = onDecrement
        self.getValue = getValue
    }

    let title: String
    let onIncrement: (() -> Void)
    let onDecrement: (() -> Void)
    let getValue: (() -> String)

    var body: some View {
        HStack {
            Text(title)
                .layoutPriority(1)
            Spacer()
                .layoutPriority(0.5)
            Stepper(getValue(), onIncrement: onIncrement, onDecrement: onDecrement)
                .layoutPriority(0.5)
                .frame(width: 250, height: nil, alignment: .trailing)
        }
        .padding()
    }
    
}

//struct StepperRow_Previews: PreviewProvider {
//
//    static var value = 0
//
//    static var previews: some View {
//        StepperRow(title: "Some Value") {
//            StepperRow_Previews.value += 1
//        } onDecrement: {
//            StepperRow_Previews.value -= 1
//        } getValue: {
//            return "\(value) units"
//        }
//
//    }
//}
