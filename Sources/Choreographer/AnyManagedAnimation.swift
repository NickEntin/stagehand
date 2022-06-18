//
//  AnyManagedAnimation.swift
//  StageManager
//
//  Created by Nick Entin on 2/14/22.
//

import ChoreographerNetworking
import Memo

internal final class AnyManagedAnimation {

    // MARK: - Life Cycle

    internal init<ElementType: AnyObject>(
        managedAnimation: ManagedAnimation<ElementType>,
        id: Token<SerializableAnimationBlueprint>,
        name: String,
        curve: SerializableAnimationBlueprint.Curve
    ) {
        self.managedAnimation = managedAnimation

        self.updateBlueprintAction = { blueprint, error in
            do {
                try managedAnimation.blueprint.update(from: blueprint)
            } catch let updateError {
                error = updateError
            }
        }

        self.serializeAction = {
            return SerializableAnimationBlueprint(
                blueprint: managedAnimation.blueprint,
                id: id,
                name: name,
                curve: curve
            )
        }
    }

    // MARK: - Public Methods

    public func update(from blueprint: SerializableAnimationBlueprint) throws {
        var error: Error? = nil
        updateBlueprintAction(blueprint, &error)
        if let error = error {
            throw error
        }
    }

    public func serialize() -> SerializableAnimationBlueprint {
        return serializeAction()
    }

    // MARK: - Private Properties

    private let managedAnimation: AnyObject

    private let updateBlueprintAction: (SerializableAnimationBlueprint, inout Error?) -> Void

    private let serializeAction: () -> SerializableAnimationBlueprint

}
