//
//  StepperRow.swift
//  Stagehand
//
//  Created by Nick Entin on 2/18/22.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import SwiftUI

struct SwitchRow<Destination: View>: View {

    init(
        title: String,
        isOn: Binding<Bool>,
        titleDestination: (() -> Destination)?
    ) {
        self.title = title
        self.isOn = isOn
        self.titleDestination = titleDestination
    }

    let title: String
    let isOn: Binding<Bool>
    let titleDestination: (() -> Destination)?

    var body: some View {
        HStack {
//            if let titleDestination = titleDestination {
//                NavigationLink(destination: titleDestination) {
//                    Text(title)
//                        .layoutPriority(1)
//                }
//            } else {
                Text(title)
                    .layoutPriority(1)
//            }
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

extension SwitchRow where Destination == EmptyView {

    init(
        title: String,
        isOn: Binding<Bool>
    ) {
        self.init(title: title, isOn: isOn, titleDestination: nil)
    }

}