//
//  AnyManagedAnimation.swift
//  StageManager
//
//  Created by Nick Entin on 2/14/22.
//

import Foundation
import StageManagerPrimitives

internal final class AnyManagedAnimation {

    // MARK: - Life Cycle

    internal init<ElementType: AnyObject>(managedAnimation: ManagedAnimation<ElementType>, id: UUID, name: String) {
        self.managedAnimation = managedAnimation

        self.updateBlueprintAction = { blueprint, error in
            do {
                try managedAnimation.blueprint.update(from: blueprint)
            } catch let updateError {
                error = updateError
            }
        }

        self.serializeAction = {
            return AnimationBlueprint(blueprint: managedAnimation.blueprint, id: id, name: name)
        }
    }

    // MARK: - Public Methods

    public func update(from blueprint: AnimationBlueprint) throws {
        var error: Error? = nil
        updateBlueprintAction(blueprint, &error)
        if let error = error {
            throw error
        }
    }

    public func serialize() -> AnimationBlueprint {
        return serializeAction()
    }

    // MARK: - Private Properties

    private let managedAnimation: AnyObject

    private let updateBlueprintAction: (AnimationBlueprint, inout Error?) -> Void

    private let serializeAction: () -> AnimationBlueprint

}
