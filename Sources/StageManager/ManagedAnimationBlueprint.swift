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

import Stagehand
import StageManagerPrimitives

public struct ManagedAnimationBlueprint<ElementType: AnyObject> {

    // MARK: - Life Cycle

    public init() {}

    // MARK: - Public Properties

    public var implicitDuration: TimeInterval = 1

    public var implicitRepeatStyle: AnimationRepeatStyle = .noRepeat

    public var curve: ManagedAnimationBlueprintCurveProviding = LinearAnimationCurve()

    // MARK: - Internal Properties

    internal var managedKeyframeSeries: [ManagedKeyframeSeries<ElementType>] = []

    internal var unmanagedKeyframeSeries: [UnmanagedKeyframeSeries<ElementType>] = []

    internal var managedAssignmentSeries: [ManagedAssignmentSeries<ElementType>] = []

    internal var managedExeuctionBlocks: [ManagedExecutionBlock<ElementType>] = []

    internal var childManagedAnimations: [ChildManagedAnimation<ElementType>] = []

    // MARK: - Public Methods - Managed Keyframes

    public mutating func addManagedKeyframes(
        named name: String,
        for property: WritableKeyPath<ElementType, Double>,
        keyframes: [(relativeTimestamp: Double, value: Double)]
    ) {
        addManagedKeyframes(named: name, for: property, keyframeSequence: .double(keyframes.map(Keyframe.init(_:))))
    }

    public mutating func addManagedKeyframes(
        named name: String,
        for property: WritableKeyPath<ElementType, CGFloat>,
        keyframes: [(relativeTimestamp: Double, value: CGFloat)]
    ) {
        addManagedKeyframes(named: name, for: property, keyframeSequence: .cgfloat(keyframes.map(Keyframe.init(_:))))
    }

    public mutating func addManagedKeyframes(
        named name: String,
        for property: WritableKeyPath<ElementType, CGColor>,
        keyframes: [(relativeTimestamp: Double, color: CGColor)]
    ) {
        let keyframes = keyframes.map { (relativeTimestamp: $0.relativeTimestamp, color: RGBAColor(cgColor: $0.color)) }
        addManagedKeyframes(named: name, for: property, keyframeSequence: .color(keyframes.map(Keyframe.init(_:))))
    }

    // MARK: - Public Methods - Unmanaged Keyframes

    public mutating func addUnmanagedKeyframes<PropertyType: AnimatableProperty>(
        named name: String,
        for property: WritableKeyPath<ElementType, PropertyType>,
        keyframes: [(relativeTimestamp: Double, value: PropertyType)]
    ) {
        addUnmanagedKeyframes(
            named: name,
            for: property,
            keyframes: keyframes.map { (relativeTimestamp, value) in
                return (relativeTimestamp, { _ in value })
            }
        )
    }

    public mutating func addUnmanagedKeyframes<PropertyType: AnimatableProperty>(
        named name: String,
        for property: WritableKeyPath<ElementType, PropertyType>,
        keyframes: [(relativeTimestamp: Double, relativeValue: (_ initialValue: PropertyType) -> PropertyType)]
    ) {
        unmanagedKeyframeSeries.append(
            UnmanagedKeyframeSeries<ElementType>(
                id: .init(),
                name: name,
                enabled: true,
                property: property,
                keyframes: keyframes
            )
        )
    }

    // MARK: - Public Methods - Managed Property Assignments

    public mutating func addManagedAssignments(
        named name: String,
        for property: WritableKeyPath<ElementType, Int>,
        assignments: [(relativeTimestamp: Double, value: Int)]
    ) {
        addManagedPropertyAssignments(
            named: name,
            for: property,
            assignmentSequence: .int(assignments.map(Assignment.init(_:)))
        )
    }

    public mutating func addManagedAssignments(
        named name: String,
        for property: WritableKeyPath<ElementType, Double>,
        assignments: [(relativeTimestamp: Double, value: Double)]
    ) {
        addManagedPropertyAssignments(
            named: name,
            for: property,
            assignmentSequence: .double(assignments.map(Assignment.init(_:)))
        )
    }

    public mutating func addManagedAssignments(
        named name: String,
        for property: WritableKeyPath<ElementType, CGFloat>,
        assignments: [(relativeTimestamp: Double, value: CGFloat)]
    ) {
        addManagedPropertyAssignments(
            named: name,
            for: property,
            assignmentSequence: .cgfloat(assignments.map(Assignment.init(_:)))
        )
    }

    // MARK: - Public Methods - Unmanaged Property Assignments

    @available(*, unavailable, message: "Not yet implemented")
    public mutating func addUnmanagedAssignments<PropertyType>(
        named name: String,
        for property: WritableKeyPath<ElementType, PropertyType>,
        assignments: [(relativeTimestamp: Double, value: PropertyType)]
    ) {
        // TODO: Support unmanaged property assignments
    }

    // MARK: - Public Methods - Execution

    public struct ManagedExecution {

        public init(
            onForward forwardBlock: @escaping (ElementType) -> Void,
            onReverse reverseBlock: @escaping (ElementType) -> Void = { _ in }
        ) {
            self.forwardBlock = forwardBlock
            self.reverseBlock = reverseBlock
        }

        public var forwardBlock: (ElementType) -> Void

        public var reverseBlock: (ElementType) -> Void

    }

    public mutating func addManagedExecution<Config: ExecutionBlockConfig>(
        named name: String,
        factory: @escaping (Config) -> ManagedExecution,
        config: Config,
        at relativeTimestamp: Double
    ) {
        managedExeuctionBlocks.append(
            .init(
                id: .init(),
                name: name,
                enabled: true,
                factory: factory,
                config: config,
                relativeTimestamp: relativeTimestamp
            )
        )
    }

    private struct EmptyConfig: ExecutionBlockConfig {

        var controls: [ExecutionBlockControl] = []

    }

    public mutating func addUnmanagedExecution(
        named name: String,
        onForward forwardBlock: @escaping (ElementType) -> Void,
        onReverse reverseBlock: @escaping (ElementType) -> Void = { _ in },
        at relativeTimestamp: Double
    ) {
        addManagedExecution(
            named: name,
            factory: { _ in ManagedExecution(onForward: forwardBlock, onReverse: reverseBlock) },
            config: EmptyConfig(),
            at: relativeTimestamp
        )
    }

    // MARK: - Public Methods - Per-Frame Execution

    @available(*, unavailable, message: "Not yet implemented")
    public mutating func addUnmanagedPerFrameExecution(
        named name: String,
        _ block: @escaping PerFrameExecutionBlock
    ) {
        // TODO: Support unmanaged per-frame execution blocks
    }

    // MARK: - Public Methods - Composition

    public mutating func addManagedChild<SubelementType: AnyObject>(
        named name: String,
        _ childAnimation: ManagedAnimation<SubelementType>,
        for subelement: KeyPath<ElementType, SubelementType>,
        startingAt relativeStartTimestamp: Double,
        relativeDuration: Double
    ) {
        childManagedAnimations.append(
            ChildManagedAnimation<ElementType>(
                id: .init(),
                name: name,
                enabled: true,
                managedAnimation: childAnimation,
                subelement: subelement,
                relativeStartTimestamp: relativeStartTimestamp,
                relativeDuration: relativeDuration
            )
        )
    }

    @available(*, unavailable, message: "Not yet implemented")
    public mutating func addChildBlueprint<SubelementType: AnyObject>(
        _ childBlueprint: ManagedAnimationBlueprint<SubelementType>,
        for subelement: KeyPath<ElementType, SubelementType>,
        startingAt relativeStartTimestamp: Double,
        relativeDuration: Double
    ) {
        // TODO: Support child blueprints
    }

    @available(*, unavailable, message: "Not yet implemented")
    public mutating func addUnmanagedChild<SubelementType: AnyObject>(
        _ childAnimation: Animation<SubelementType>,
        for subelement: KeyPath<ElementType, SubelementType>,
        startingAt relativeStartTimestamp: Double,
        relativeDuration: Double
    ) {
        // TODO: Support unmanaged child animations
    }

    // MARK: - Private Methods

    private mutating func addManagedKeyframes(
        named name: String,
        for property: PartialKeyPath<ElementType>,
        keyframeSequence: KeyframeSequence
    ) {
        managedKeyframeSeries.append(
            ManagedKeyframeSeries(
                id: .init(),
                name: name,
                property: property,
                enabled: true,
                keyframeSequence: keyframeSequence
            )
        )
    }

    private mutating func addManagedPropertyAssignments(
        named name: String,
        for property: PartialKeyPath<ElementType>,
        assignmentSequence: AssignmentSequence
    ) {
        // TODO: Support managed property assignments
    }

    // MARK: - Public Types

    public struct FrameContext {

        /// The element being animated.
        public let element: ElementType

        /// Value in the range [0, 1] representing the uncurved progress of the animation.
        public let uncurvedProgress: Double

        /// Value representing the progress into the animation, adjusted based on the animation's curve.
        public let progress: Double

    }

    public typealias PerFrameExecutionBlock = (FrameContext) -> Void

}

// MARK: -

public protocol ExecutionBlockConfig {

    var controls: [ExecutionBlockControl] { get set }

}

// MARK: -

internal struct ManagedKeyframeSeries<ElementType: AnyObject> {

    var id: Token<SerializableAnimationBlueprint.ManagedKeyframeSeries>

    var name: String

    var property: PartialKeyPath<ElementType>

    var enabled: Bool

    var keyframeSequence: KeyframeSequence

}

internal struct UnmanagedKeyframeSeries<ElementType: AnyObject> {

    init<PropertyType: AnimatableProperty>(
        id: Token<SerializableAnimationBlueprint.UnmanagedKeyframeSeries>,
        name: String,
        enabled: Bool,
        property: WritableKeyPath<ElementType, PropertyType>,
        keyframes: [(Double, (PropertyType) -> PropertyType)]
    ) {
        self.id = id
        self.name = name
        self.enabled = enabled

        self.addToAnimation = { animation in
            for (relativeTimestamp, relativeValue) in keyframes {
                animation.addKeyframe(for: property, at: relativeTimestamp, relativeValue: relativeValue)
            }
        }
    }

    var id: Token<SerializableAnimationBlueprint.UnmanagedKeyframeSeries>

    var name: String

    var enabled: Bool

    var addToAnimation: (_ animation: inout Animation<ElementType>) -> Void

}

internal struct ManagedAssignmentSeries<ElementType: AnyObject> {

    var id: UUID

    var name: String

    var property: PartialKeyPath<ElementType>

    var enabled: Bool

    var assignmentSequence: AssignmentSequence

}

internal final class ManagedExecutionBlock<ElementType: AnyObject> {

    init<Config: ExecutionBlockConfig>(
        id: Token<SerializableAnimationBlueprint.ManagedExecutionBlockConfig>,
        name: String,
        enabled: Bool,
        factory: @escaping (Config) -> ManagedAnimationBlueprint<ElementType>.ManagedExecution,
        config: Config,
        relativeTimestamp: Double
    ) {
        self.id = id
        self.name = name
        self.enabled = enabled
        self.config = config
        self.addToAnimation = { _ in }

        self.addToAnimation = { [unowned self] animation in
            let managedExecution = factory(self.config as! Config)
            animation.addExecution(
                onForward: managedExecution.forwardBlock,
                onReverse: managedExecution.reverseBlock,
                at: relativeTimestamp
            )
        }
    }

    var id: Token<SerializableAnimationBlueprint.ManagedExecutionBlockConfig>

    var name: String

    var enabled: Bool

    var config: ExecutionBlockConfig

    var addToAnimation: (_ animation: inout Animation<ElementType>) -> Void

}

internal struct ChildManagedAnimation<ElementType: AnyObject> {

    init<SubelementType: AnyObject>(
        id: Token<SerializableAnimationBlueprint.ManagedChildAnimation>,
        name: String,
        enabled: Bool,
        managedAnimation: ManagedAnimation<SubelementType>,
        subelement: KeyPath<ElementType, SubelementType>,
        relativeStartTimestamp: Double,
        relativeDuration: Double
    ) {
        self.id = id
        self.name = name
        self.enabled = enabled
        self.managedAnimationID = managedAnimation.id
        self.relativeStartTimestamp = relativeStartTimestamp
        self.relativeDuration = relativeDuration

        self.addToAnimation = { animation in
            animation.addChild(
                managedAnimation.buildAnimation(),
                for: subelement,
                startingAt: relativeStartTimestamp,
                relativeDuration: relativeDuration
            )
        }
    }

    var id: Token<SerializableAnimationBlueprint.ManagedChildAnimation>

    var name: String

    var enabled: Bool

    var managedAnimationID: Token<SerializableAnimationBlueprint>

    var relativeStartTimestamp: Double

    var relativeDuration: Double

    var addToAnimation: (_ animation: inout Animation<ElementType>) -> Void

}
