//
//  ContentView.swift
//  Shared
//
//  Created by Nick Entin on 2/6/22.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import StageManagerPrimitives
import SwiftUI

struct ContentView: View {

    @State
    var animationDetailsParams: (AnimationBlueprint, Transceiver)?

    var body: some View {
        HStack {
            NavigationView {
                DeviceSelectionView(
                    animationSelectionAction: { (animation, transceiver) in
                        animationDetailsParams = (animation, transceiver)
                    }
                )
                .navigationTitle("Devices")
            }
//            .frame(minWidth: 350)
//            .layoutPriority(0.3)
//            ZStack {
//                Color.purple
//                if let (animation, transceiver) = animationDetailsParams {
//                    AnimationDetailsView(animation: animation, transceiver: transceiver)
//                }
//            }
//            .layoutPriority(0.7)

        }
    }

}
