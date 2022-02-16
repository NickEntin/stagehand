//
//  AnimationSelectionView.swift
//  Stagehand
//
//  Created by Nick Entin on 2/6/22.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import Memo
import StageManagerPrimitives
import SwiftUI

struct AnimationSelectionView: View {

    init(transceiver: Memo.Transceiver) {
        self.transceiver = Transceiver(memoTransceiver: transceiver)
    }

    @ObservedObject
    var transceiver: Transceiver

    var body: some View {
        ScrollView {
            HStack {
                VStack(alignment: .leading) {
                    ForEach(transceiver.managedAnimations) { animation in
                        NavigationLink {
                            AnimationDetailsView(animation: animation.blueprint, transceiver: transceiver)
                        } label: {
                            Text(animation.displayName)
                                .padding()
                        }
                    }
                }
                Spacer()
            }
            Spacer()
        }
        .navigationTitle("Animations")
    }

}

struct ManagedAnimation: Identifiable {

    var id: String

    var displayName: String

    var blueprint: AnimationBlueprint

}

final class Transceiver: ObservableObject {

    init(memoTransceiver: Memo.Transceiver) {
        self.memoTransceiver = memoTransceiver
        memoTransceiver.delegate = self
    }

    @Published
    var managedAnimations: [ManagedAnimation] = []

    private let memoTransceiver: Memo.Transceiver

    public func updateAnimation(_ blueprint: AnimationBlueprint) async throws {
        let encoder = JSONEncoder()
        let payload = try encoder.encode(ClientToServerMessage.updateAnimation(blueprint))
        try await memoTransceiver.send(payload: payload)
    }

}

extension Transceiver: Memo.TransceiverDelegate {

    func transceiver(_ transceiver: Memo.Transceiver, didReceivePayload payload: Data) {
        let jsonDecoder = JSONDecoder()

        do {
            let message = try jsonDecoder.decode(ServerToClientMessage.self, from: payload)

            switch message {
            case let .registerAnimation(blueprint):
                managedAnimations.append(
                    ManagedAnimation(
                        id: blueprint.name, // TODO
                        displayName: blueprint.name,
                        blueprint: blueprint
                    )
                )
            }

        } catch let error {
            print("Failed to decode message: \(error)")
        }
    }

}
