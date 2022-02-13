//
//  DeviceSelectionView.swift
//  Stagehand_Example
//
//  Created by Nick Entin on 2/6/22.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import Memo
import SwiftUI

struct DeviceSelectionView: View {

    init() {
        client = Client()
    }

    @ObservedObject
    var client: Client

    var body: some View {
        ScrollView {
            HStack {
                VStack(alignment: .leading) {
                    ForEach(client.availableTransceivers) { transceiver in
                        NavigationLink {
                            AnimationSelectionView(transceiver: transceiver.memoTransceiver)
                        } label: {
                            Text(transceiver.displayName)
                                .padding()
                        }
                    }
                }
                Spacer()
            }
            Spacer()
        }

    }

}

struct DeviceSelectionView_Previews: PreviewProvider {

    static var previews: some View {
        DeviceSelectionView()
    }

}

struct AvailableTransceiver: Identifiable {

    var id: String

    var displayName: String

    var memoTransceiver: Memo.Transceiver

}

final class Client: NSObject, ObservableObject {

    override init() {
        memoClient = Memo.Client()

        super.init()

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
    private(set) var availableTransceivers: [AvailableTransceiver] = []

}

extension Client: Memo.ClientDelegate {

    func clientDidUpdateAvailableTransceivers(client: Memo.Client) {
        print("Updating available transceivers")
        availableTransceivers = client.availableTransceivers.map { transceiver in
            AvailableTransceiver(
                id: transceiver.deviceToken.uuidString,
                displayName: transceiver.name.isEmpty ? "(null)" : transceiver.name,
                memoTransceiver: transceiver
            )
        }
    }

}
