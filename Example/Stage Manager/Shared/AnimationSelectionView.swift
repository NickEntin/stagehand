//
//  AnimationSelectionView.swift
//  Stagehand
//
//  Created by Nick Entin on 2/6/22.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import Memo
import SwiftUI
import StageManagerPrimitives

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
                        Text(animation.displayName)
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

final class Transceiver: NSObject, ObservableObject {

    init(memoTransceiver: Memo.Transceiver) {
        self.memoTransceiver = memoTransceiver
    }

    @State
    var managedAnimations: [ManagedAnimation] = []

    private let memoTransceiver: Memo.Transceiver

}

extension Transceiver: Memo.TransceiverDelegate {

    func transceiver(_ transceiver: Memo.Transceiver, didReceivePayload payload: Data) {
        let jsonDecoder = JSONDecoder()

        do {
            let message = try jsonDecoder.decode(StageManagerMessage.self, from: payload)

            switch message {
            case let .registerAnimation(blueprint):
                managedAnimations.append(
                    ManagedAnimation(
                        id: blueprint.name,
                        displayName: blueprint.name,
                        blueprint: blueprint
                    )
                )
            }

        } catch {
            return
        }
    }

}
