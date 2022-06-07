//
//  ContentView.swift
//  Shared
//
//  Created by Nick Entin on 2/6/22.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import ChoreographerNetworking
import SwiftUI

struct ContentView: View {

    @State
    var animationDetailsParams: (SerializableAnimationBlueprint, Transceiver)?

    var body: some View {
        HStack {
            // TODO: This NavigationView works as a proof of concept, but it's a really bad experience since it starts
            // with focus on the second view and hides the first column (device selection) on iOS devices. As far as I
            // can tell, there's no way to control this behavior.
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
                        Label("Toggle Device List", systemImage: "sidebar.left")
                    }
                }
            }

        }
    }

}
