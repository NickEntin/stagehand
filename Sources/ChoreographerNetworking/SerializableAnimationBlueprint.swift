//
//  AnimationBlueprint.swift
//  StageManagerPrimitives
//
//  Created by Nick Entin on 2/6/22.
//

import Memo

public struct SerializableAnimationBlueprint: Codable, Equatable, Identifiable, TokenIdentifiable {

    // MARK: - TokenIdentifiable

    public static let tokenPrefix: String = "ABP"

    // MARK: - Life Cycle

    public init(
        id: Token<SerializableAnimationBlueprint>,
        name: String,
        implicitDuration: TimeInterval,
        implicitRepeatStyle: SerializableAnimationBlueprint.RepeatStyle,
        curve: SerializableAnimationBlueprint.Curve,
        managedKeyframeSeries: [SerializableAnimationBlueprint.ManagedKeyframeSeries],
        unmanagedKeyframeSeries: [SerializableAnimationBlueprint.UnmanagedKeyframeSeries],
        managedExecutionBlockConfigs: [SerializableAnimationBlueprint.ManagedExecutionBlockConfig],
        managedChildAnimations: [SerializableAnimationBlueprint.ManagedChildAnimation]
    ) {
        self.id = id
        self.name = name
        self.implicitDuration = implicitDuration
        self.implicitRepeatStyle = implicitRepeatStyle
        self.curve = curve
        self.managedKeyframeSeries = managedKeyframeSeries
        self.unmanagedKeyframeSeries = unmanagedKeyframeSeries
        self.managedExecutionBlockConfigs = managedExecutionBlockConfigs
        self.managedChildAnimations = managedChildAnimations
    }

    // MARK: - Public Properties

    public var id: Token<SerializableAnimationBlueprint>

    public var name: String

    public var implicitDuration: TimeInterval

    public var implicitRepeatStyle: RepeatStyle

    public var curve: Curve

    public var managedKeyframeSeries: [ManagedKeyframeSeries]

    public var unmanagedKeyframeSeries: [UnmanagedKeyframeSeries]

    // TODO: Add the rest of the properties

    public var managedExecutionBlockConfigs: [ManagedExecutionBlockConfig]

    public var managedChildAnimations: [ManagedChildAnimation]

    // MARK: - Public Types

    public struct RepeatStyle: Codable, Equatable {

        // MARK: - Life Cycle

        public init(count: UInt, autoreversing: Bool) {
            self.count = count
            self.autoreversing = autoreversing
        }

        // MARK: - Public Properties

        public var count: UInt

        public var autoreversing: Bool

    }

    public enum Curve: Codable, Equatable {

        case managedCubicBezier(Token<SerializableCubicBezierAnimationCurve>)

        case unmanaged(SerializableUnmanagedAnimationCurve)

    }

    public struct ManagedKeyframeSeries: Codable, Equatable, Identifiable, TokenIdentifiable {

        // MARK: - TokenIdentifiable

        public static let tokenPrefix: String = "MKS"

        // MARK: - Life Cycle

        public init(id: Token<ManagedKeyframeSeries>, name: String, enabled: Bool, keyframeSequence: KeyframeSequence) {
            self.id = id
            self.name = name
            self.enabled = enabled
            self.keyframeSequence = keyframeSequence
        }

        // MARK: - Public Properties

        public var id: Token<ManagedKeyframeSeries>

        public var name: String

        public var enabled: Bool

        public var keyframeSequence: KeyframeSequence

    }

    public struct UnmanagedKeyframeSeries: Codable, Equatable, Identifiable, TokenIdentifiable {

        // MARK: - TokenIdentifiable

        public static let tokenPrefix: String = "UKS"

        // MARK: - Life Cycle

        public init(id: Token<UnmanagedKeyframeSeries>, name: String, enabled: Bool) {
            self.id = id
            self.name = name
            self.enabled = enabled
        }

        // MARK: - Public Properties

        public var id: Token<UnmanagedKeyframeSeries>

        public var name: String

        public var enabled: Bool

    }

    public struct ManagedExecutionBlockConfig: Codable, Equatable, Identifiable, TokenIdentifiable {

        // MARK: - TokenIdentifiable

        public static let tokenPrefix: String = "MEB"

        // MARK: - Life Cycle

        public init(
            id: Token<ManagedExecutionBlockConfig>,
            name: String,
            enabled: Bool,
            controls: [ExecutionBlockControl]
        ) {
            self.id = id
            self.name = name
            self.enabled = enabled
            self.controls = controls
        }

        // MARK: - Public Properties

        public var id: Token<ManagedExecutionBlockConfig>

        public var name: String

        public var enabled: Bool

        public var controls: [ExecutionBlockControl]

    }

    public struct ManagedChildAnimation: Codable, Equatable, Identifiable, TokenIdentifiable {

        // MARK: - TokenIdentifiable

        public static let tokenPrefix: String = "MCA"

        // MARK: - Life Cycle

        public init(
            id: Token<ManagedChildAnimation>,
            name: String,
            enabled: Bool,
            animationID: Token<SerializableAnimationBlueprint>
        ) {
            self.id = id
            self.name = name
            self.enabled = enabled
            self.animationID = animationID
        }

        // MARK: - Public Properties

        public var id: Token<ManagedChildAnimation>

        public var name: String

        public var enabled: Bool

        public var animationID: Token<SerializableAnimationBlueprint>

    }

}
