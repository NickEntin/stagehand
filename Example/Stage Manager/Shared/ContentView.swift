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
    var animationDetailsParams: (SerializableAnimationBlueprint, Transceiver)?

    var body: some View {
        HStack {
            NavigationView {
                DeviceSelectionView()
                EmptyView()
                EmptyView()
            }
            .toolbar {
                ToolbarItem(placement: ToolbarItemPlacement.navigation) {
                    Button {
                        #if os(macOS)
                            NSApp.keyWindow?.firstResponder?.tryToPerform(
                                #selector(NSSplitViewController.toggleSidebar(_:)),
                                with: nil
                            )
                        #endif
                    } label: {
                        Label("Toggle sidebar", systemImage: "sidebar.left")
                    }
                }
            }

        }
    }

}
