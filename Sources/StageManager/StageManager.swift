//
//  Copyright 2022 Square Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Memo
import Stagehand
import StageManagerPrimitives

public final class StageManager {

    // MARK: - Life Cycle

    public init() {
        memoServer.delegate = self

        do {
            try memoServer.start()
        } catch {
            print("[StageManager] Failed to start Memo server")
        }
    }

    deinit {
        memoServer.stop()
    }

    // MARK: - Public Methods

    public func registerManagedAnimation<ElementType: AnyObject>(
        named name: String,
        blueprint: ManagedAnimationBlueprint<ElementType>
    ) -> ManagedAnimation<ElementType> {
        let animation = ManagedAnimation(blueprint: blueprint)
        let id = UUID()
        managedAnimations[id] = AnyManagedAnimation(managedAnimation: animation, id: id, name: name)
        return animation
    }

    // MARK: - Private Properties

    private let memoServer: Memo.Server = .init(config: .stageManager)

    private var managedAnimations: [UUID: AnyManagedAnimation] = [:]

    private var transceivers: [Transceiver] = []

    // MARK: - Private Methods

    private func register(_ blueprint: AnimationBlueprint, with transceiver: Transceiver) {
        let message = ServerToClientMessage.registerAnimation(blueprint)
        let jsonEncoder = JSONEncoder()

        let payload = try! jsonEncoder.encode(message)

        @Sendable
        func send(payload: Data, retryCount: Int) {
            Task {
                do {
                    try await transceiver.send(payload: payload)
                } catch {
                    if retryCount > 0 {
                        print("Failed to send blueprint")
                        try await Task.sleep(nanoseconds: UInt64(1 * Double(NSEC_PER_SEC)))
                        send(payload: payload, retryCount: retryCount - 1)
                    }
                }
            }
        }

        send(payload: payload, retryCount: 10)
    }

}

extension StageManager: Memo.ServerDelegate {

    public func server(_ server: Server, didReceiveIncomingConnection transceiver: Transceiver) {
        transceiver.addObserver(self)
        transceivers.append(transceiver)

        self.managedAnimations.forEach { (id, managedAnimation) in
            self.register(managedAnimation.serialize(), with: transceiver)
        }
    }

    public func server(_ server: Server, didFailWithError error: Error) {
        // TODO
    }

}

extension StageManager: Memo.TransceiverObserver {

    public func transceiver(_ transceiver: Transceiver, didReceivePayload payload: Data) {
        let decoder = JSONDecoder()
        do {
            let message = try decoder.decode(ClientToServerMessage.self, from: payload)

            switch message {
            case let .updateAnimation(blueprint):
                try managedAnimations[blueprint.id]?.update(from: blueprint)
            }

        } catch let error {
            print("Failed to complete received action: \(error)")
        }
    }

    public func transceiverDidUpdateConnection(_ transceiver: Transceiver) {
        // No-op.
    }

    public func transceiverDidLoseConnection(_ transceiver: Transceiver) {
        // No-op.
    }

}
