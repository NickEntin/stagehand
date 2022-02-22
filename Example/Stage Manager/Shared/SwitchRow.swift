//
//  StepperRow.swift
//  Stagehand
//
//  Created by Nick Entin on 2/18/22.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import SwiftUI

struct SwitchRow: View {

    init(
        title: String,
        isOn: Binding<Bool>
    ) {
        self.title = title
        self.isOn = isOn
    }

    let title: String
    let isOn: Binding<Bool>

    var body: some View {
        HStack {
            Text(title)
                .layoutPriority(1)
            Spacer()
                .layoutPriority(0.5)
            Toggle(title, isOn: isOn)
                .layoutPriority(0.5)
                .labelsHidden()
                .frame(width: 100, height: nil, alignment: .trailing)
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
