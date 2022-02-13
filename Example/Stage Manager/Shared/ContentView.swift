//
//  ContentView.swift
//  Shared
//
//  Created by Nick Entin on 2/6/22.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import SwiftUI

struct ContentView: View {

    var body: some View {
        NavigationView {
            DeviceSelectionView()
                .navigationTitle("Devices")
//            Text("Hello, World!")
//                .navigationTitle("Navigation")
//            Text("Hello, World!")
//                .navigationTitle("Navigation")
        }
    }

}

struct ContentView_Previews: PreviewProvider {

    static var previews: some View {
        ContentView()
    }

}
