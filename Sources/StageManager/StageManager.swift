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
        let id = Token<SerializableAnimationBlueprint>()
        let animation = ManagedAnimation(blueprint: blueprint, id: id)

        let curve: SerializableAnimationBlueprint.Curve
        if let managedCurve = blueprint.curve as? ManagedCubicBezierCurve {
            curve = .managedCubicBezier(managedCurve.id)
        } else if let existingCurve = unmanagedCurves.first(where: { $0.value.1.isEqual(to: blueprint.curve.animationCurve) }) {
            curve = .unmanaged(existingCurve.value.0)
        } else {
            curve = .unmanaged(registerUnmanagedCurve(named: blueprint.curve.displayName, curve: blueprint.curve.animationCurve))
        }

        managedAnimations[id] = AnyManagedAnimation(managedAnimation: animation, id: id, name: name, curve: curve)
        return animation
    }

    public func registerManagedCurve(
        named name: String,
        curve: CubicBezierAnimationCurve
    ) -> ManagedCubicBezierCurve {
        let id = Token<SerializableCubicBezierAnimationCurve>()
        let managedCurve = ManagedCubicBezierCurve(curve: curve, id: id, name: name)
        managedCubicBezierCurves[id] = managedCurve
        return managedCurve
    }

    @discardableResult
    public func registerUnmanagedCurve(
        named name: String,
        curve: AnimationCurve
    ) -> SerializableUnmanagedAnimationCurve {
        let id = Token<SerializableUnmanagedAnimationCurve>()
        let serializableCurve = SerializableUnmanagedAnimationCurve(id: id, name: name)
        unmanagedCurves[id] = (serializableCurve, curve)
        return serializableCurve
    }

    // MARK: - Private Properties

    private let memoServer: Memo.Server = .init(config: .stageManager)

    private var managedAnimations: [Token<SerializableAnimationBlueprint>: AnyManagedAnimation] = [:]

    private var managedCubicBezierCurves: [Token<SerializableCubicBezierAnimationCurve>: ManagedCubicBezierCurve] = [:]

    private var unmanagedCurves: [Token<SerializableUnmanagedAnimationCurve>: (SerializableUnmanagedAnimationCurve, AnimationCurve)] = [:]

    private var transceivers: [Transceiver] = []

    // MARK: - Private Methods

    private func send(_ message: ServerToClientMessage, with transceiver: Transceiver) {
        let payload = try! JSONEncoder().encode(message)

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

    private func register(_ blueprint: SerializableAnimationBlueprint, with transceiver: Transceiver) {
        let message = ServerToClientMessage.registerAnimation(blueprint)
        send(message, with: transceiver)
    }

    private func register(_ curve: SerializableCubicBezierAnimationCurve, with transceiver: Transceiver) {
        let message = ServerToClientMessage.registerCubicBezierCurve(curve)
        send(message, with: transceiver)
    }

}

extension StageManager: Memo.ServerDelegate {

    public func server(_ server: Server, didReceiveIncomingConnection transceiver: Transceiver) {
        transceiver.addObserver(self)
        transceivers.append(transceiver)

        self.managedAnimations.forEach { (id, managedAnimation) in
            self.register(managedAnimation.serialize(), with: transceiver)
        }

        self.managedCubicBezierCurves.forEach { (id, managedCubicBezierCurve) in
            self.register(managedCubicBezierCurve.serialize(), with: transceiver)
        }
    }

    public func server(_ server: Server, didFailWithError error: Error) {
        // TODO: Do we need to handle errors here? This method is never called currently.
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
