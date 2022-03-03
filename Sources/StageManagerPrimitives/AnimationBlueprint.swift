//
//  AnimationBlueprint.swift
//  StageManagerPrimitives
//
//  Created by Nick Entin on 2/6/22.
//

import Foundation

public struct AnimationBlueprint: Codable, Identifiable {

    // MARK: - Public Static Properties

    public static let key = "blueprint"

    // MARK: - Life Cycle

    public init(
        id: UUID,
        name: String,
        implicitDuration: TimeInterval,
        implicitRepeatStyle: AnimationBlueprint.RepeatStyle,
        managedKeyframeSeries: [AnimationBlueprint.ManagedKeyframeSeries],
        unmanagedKeyframeSeries: [AnimationBlueprint.UnmanagedKeyframeSeries]
    ) {
        self.id = id
        self.name = name
        self.implicitDuration = implicitDuration
        self.implicitRepeatStyle = implicitRepeatStyle
        self.managedKeyframeSeries = managedKeyframeSeries
        self.unmanagedKeyframeSeries = unmanagedKeyframeSeries
    }

    // MARK: - Public Properties

    public var id: UUID

    public var name: String

    public var implicitDuration: TimeInterval

    public var implicitRepeatStyle: RepeatStyle

    // TODO: Include curve

    public var managedKeyframeSeries: [ManagedKeyframeSeries]

    public var unmanagedKeyframeSeries: [UnmanagedKeyframeSeries]

    // TODO

    // MARK: - Public Types

    public struct RepeatStyle: Codable {

        // MARK: - Life Cycle

        public init(count: UInt, autoreversing: Bool) {
            self.count = count
            self.autoreversing = autoreversing
        }

        // MARK: - Public Properties

        public var count: UInt

        public var autoreversing: Bool

    }

    public struct ManagedKeyframeSeries: Codable, Identifiable {

        // MARK: - Life Cycle

        public init(id: UUID, name: String, enabled: Bool, keyframeSequence: KeyframeSequence) {
            self.id = id
            self.name = name
            self.enabled = enabled
            self.keyframeSequence = keyframeSequence
        }

        // MARK: - Public Properties

        public var id: UUID

        public var name: String

        public var enabled: Bool

        public var keyframeSequence: KeyframeSequence

    }

    public struct UnmanagedKeyframeSeries: Codable, Identifiable {

        // MARK: - Life Cycle

        public init(id: UUID, name: String, enabled: Bool) {
            self.id = id
            self.name = name
            self.enabled = enabled
        }

        // MARK: - Public Properties

        public var id: UUID

        public var name: String

        public var enabled: Bool

    }

}
