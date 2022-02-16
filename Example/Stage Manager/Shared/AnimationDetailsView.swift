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
        self._animation = State(initialValue: animation)
        self.transceiver = transceiver
    }

    @State
    var animation: AnimationBlueprint // = .init(id: UUID(), name: "", implicitDuration: 0, implicitRepeatStyle: .init(count: 0, autoreversing: false), managedKeyframeSeries: [])

    @ObservedObject
    var transceiver: Transceiver

    var body: some View {
        ScrollView {
            Text("Implicit Duration")
            HStack {
                Stepper("\(animation.implicitDuration) sec") {
                    animation.implicitDuration += 0.1
                } onDecrement: {
                    animation.implicitDuration -= 0.1
                }
            }
        }
        .navigationTitle(animation.name)
        Button("Update") {
            Task {
                try await transceiver.updateAnimation(animation)
            }
        }
    }

}
