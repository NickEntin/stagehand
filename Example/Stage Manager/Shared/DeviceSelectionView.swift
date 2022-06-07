//
//  DeviceSelectionView.swift
//  Stagehand_Example
//
//  Created by Nick Entin on 2/6/22.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import Memo
import ChoreographerNetworking
import SwiftUI

struct DeviceSelectionView: View {

    init() {
        client = Client()
    }

    @ObservedObject
    var client: Client

    var body: some View {
        List(client.availableTransceivers) { transceiver in
            NavigationLink {
                AnimationSelectionView(transceiver: transceiver.memoTransceiver)
                    .navigationTitle(transceiver.displayName)
            } label: {
                Text(transceiver.displayName)
            }
        }
        .listStyle(SidebarListStyle())
        .frame(minWidth: 200)
        .navigationTitle("Devices")
    }

}

struct AvailableTransceiverModel: Identifiable {

    var id: UUID

    var displayName: String

    var memoTransceiver: Memo.Transceiver

}

final class Client: ObservableObject {

    init() {
        memoClient = Memo.Client(config: .stageManager)
        memoClient.delegate = self

        Task {
            do {
                try await memoClient.startSearchingForConnections()
            } catch {
                print("Failed to start searching for connections")
            }
        }
    }

    deinit {
        memoClient.stopSearchingForConnections()
    }

    let memoClient: Memo.Client

    @Published
    private(set) var availableTransceivers: [AvailableTransceiverModel] = []

}

extension Client: Memo.ClientDelegate {

    func clientDidUpdateAvailableTransceivers(client: Memo.Client) {
        print("Updating available transceivers")
        DispatchQueue.main.async {
            self.availableTransceivers = client.availableTransceivers.map { transceiver in
                AvailableTransceiverModel(
                    id: transceiver.deviceToken,
                    displayName: transceiver.name.isEmpty ? "Unknown Device" : transceiver.name,
                    memoTransceiver: transceiver
                )
            }
        }
    }

}
