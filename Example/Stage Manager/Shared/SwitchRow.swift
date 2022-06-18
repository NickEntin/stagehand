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
            if let titleDestination = titleDestination {
                HStack {
                    Text(title)
                    NavigationLink(destination: titleDestination) {
                        Image(systemName: "link")
                    }
                }
                .layoutPriority(1)
            } else {
                Text(title)
                    .layoutPriority(1)
            }
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

extension SwitchRow where Destination == EmptyView {

    init(
        title: String,
        isOn: Binding<Bool>
    ) {
        self.init(title: title, isOn: isOn, titleDestination: nil)
    }

}
