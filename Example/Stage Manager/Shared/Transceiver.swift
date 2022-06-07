//
//  Transceiver.swift
//  Stagehand
//
//  Created by Nick Entin on 3/11/22.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import ChoreographerNetworking
import Memo

final class Transceiver: ObservableObject {

    init(memoTransceiver: Memo.Transceiver) {
        self.memoTransceiver = memoTransceiver
        memoTransceiver.addObserver(self)
    }

    @Published
    private(set) var managedAnimations: [ManagedAnimationModel] = []

    @Published
    private(set) var managedCurves: [ManagedCurveModel] = []

    @Published
    private(set) var hasActiveConnection: Bool = false

    private let memoTransceiver: Memo.Transceiver

    public func updateAnimation(_ blueprint: SerializableAnimationBlueprint) async throws {
        let encoder = JSONEncoder()
        let payload = try encoder.encode(ClientToServerMessage.updateAnimation(blueprint))
        try await memoTransceiver.send(payload: payload)
    }

}

extension Transceiver: Memo.TransceiverObserver {

    func transceiver(_ transceiver: Memo.Transceiver, didReceivePayload payload: Data) {
        let jsonDecoder = JSONDecoder()

        do {
            let message = try jsonDecoder.decode(ServerToClientMessage.self, from: payload)

            switch message {
            case let .registerAnimation(blueprint):
                print("[AnimationSelectionView] Adding managed animation: \"\(blueprint.name)\"")
                managedAnimations.append(
                    ManagedAnimationModel(
                        id: blueprint.id,
                        displayName: blueprint.name,
                        blueprint: blueprint
                    )
                )

            case let .registerCubicBezierCurve(curve):
                managedCurves.append(
                    ManagedCurveModel(
                        id: curve.id,
                        displayName: curve.name,
                        curve: curve
                    )
                )
            }

        } catch let error {
            print("Failed to decode message: \(error)")
        }
    }

    func transceiverDidUpdateConnection(_ transceiver: Memo.Transceiver) {
        DispatchQueue.main.async {
            self.hasActiveConnection = true
        }
    }

    func transceiverDidLoseConnection(_ transceiver: Memo.Transceiver) {
        DispatchQueue.main.async {
            self.hasActiveConnection = false
        }
    }

}
