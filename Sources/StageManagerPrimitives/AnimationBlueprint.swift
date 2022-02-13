//
//  AnimationBlueprint.swift
//  StageManagerPrimitives
//
//  Created by Nick Entin on 2/6/22.
//

import Foundation

public struct AnimationBlueprint: Codable {

    // MARK: - Public Static Properties

    public static let key = "blueprint"

    // MARK: - Life Cycle

    public init(
        name: String,
        implicitDuration: TimeInterval,
        implicitRepeatStyle: AnimationBlueprint.RepeatStyle,
        managedKeyframeSeries: [AnimationBlueprint.ManagedKeyframeSeries]
    ) {
        self.name = name
        self.implicitDuration = implicitDuration
        self.implicitRepeatStyle = implicitRepeatStyle
        self.managedKeyframeSeries = managedKeyframeSeries
    }

    // MARK: - Public Properties

    public var name: String

    public var implicitDuration: TimeInterval

    public var implicitRepeatStyle: RepeatStyle

    public var managedKeyframeSeries: [ManagedKeyframeSeries]

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

    public struct ManagedKeyframeSeries: Codable {

        // MARK: - Life Cycle

        public init(name: String, keyframeSequence: KeyframeSequence) {
            self.name = name
            self.keyframeSequence = keyframeSequence
        }

        // MARK: - Public Properties

        public var name: String

        public var keyframeSequence: KeyframeSequence

    }

}
