//
//  DeviceSelectionView.swift
//  Stagehand_Example
//
//  Created by Nick Entin on 2/6/22.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import Memo
import StageManagerPrimitives
import SwiftUI

struct DeviceSelectionView: View {

    init(animationSelectionAction: @escaping (AnimationBlueprint, Transceiver) -> Void) {
        self.animationSelectionAction = animationSelectionAction

        client = Client()
    }

    @ObservedObject
    var client: Client

    var animationSelectionAction: (AnimationBlueprint, Transceiver) -> Void

    var body: some View {
        ScrollView {
            HStack {
                VStack(alignment: .leading) {
                    ForEach(client.availableTransceivers) { transceiver in
                        NavigationLink {
                            AnimationSelectionView(
                                transceiver: transceiver.memoTransceiver,
                                animationSelectionAction: animationSelectionAction
                            )
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

struct AvailableTransceiver: Identifiable {

    var id: String

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
