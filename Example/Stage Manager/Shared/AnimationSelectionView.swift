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
        #if os(iOS)
        switch UIDevice.current.userInterfaceIdiom {
        case .pad, .mac:
            list.listStyle(SidebarListStyle())
        case .phone:
            list.listStyle(InsetGroupedListStyle())
        default:
            fatalError("Unexpected user interface idiom")
        }
        #else
        list.listStyle(SidebarListStyle())
        #endif
    }

    var list: some View {
        List {
            Section(
                header: Text("Animations")
                    .font(.headline)
            ) {
                ForEach(transceiver.managedAnimations) { animation in
                    NavigationLink {
                        AnimationDetailsView(
                            animation: animation.blueprint,
                            transceiver: transceiver,
                            blueprintForID: { id in
                                return transceiver.managedAnimations
                                    .first(where: { $0.blueprint.id == id })?
                                    .blueprint
                            }
                        )
                    } label: {
                        Text(animation.displayName)
                    }
                }
            }
        }
        .frame(minWidth: 200)
    }

}

struct ManagedAnimation: Identifiable {

    var id: Token<SerializableAnimationBlueprint>

    var displayName: String

    var blueprint: SerializableAnimationBlueprint

}

final class Transceiver: ObservableObject {

    init(memoTransceiver: Memo.Transceiver) {
        self.memoTransceiver = memoTransceiver
        memoTransceiver.addObserver(self)
    }

    @Published
    var managedAnimations: [ManagedAnimation] = []

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
                    ManagedAnimation(
                        id: blueprint.id,
                        displayName: blueprint.name,
                        blueprint: blueprint
                    )
                )
            }

        } catch let error {
            print("Failed to decode message: \(error)")
        }
    }

    func transceiverDidUpdateConnection(_ transceiver: Memo.Transceiver) {
        // No-op.
    }

    func transceiverDidLoseConnection(_ transceiver: Memo.Transceiver) {
        // No-op.
    }

}
