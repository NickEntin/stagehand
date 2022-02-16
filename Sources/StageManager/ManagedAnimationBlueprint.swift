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

    public var curve: AnimationCurve = LinearAnimationCurve()

    // MARK: - Internal Properties

    internal var managedKeyframeSeries: [ManagedKeyframeSeries<ElementType>] = []

    // MARK: - Public Methods

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

    // MARK: - Internal Methods

//    internal func serialize(name: String) -> AnimationBlueprint {
//        let repeatStyle: AnimationBlueprint.RepeatStyle
//        switch implicitRepeatStyle {
//        case let .repeating(count, autoreversing):
//            repeatStyle = .init(count: count, autoreversing: autoreversing)
//        }
//
//        return AnimationBlueprint(
//            name: name,
//            implicitDuration: implicitDuration,
//            implicitRepeatStyle: repeatStyle,
//            managedKeyframeSeries: managedKeyframeSeries.map(AnimationBlueprint.ManagedKeyframeSeries.init(series:))
//        )
//    }

    // MARK: - Private Methods

    private mutating func addManagedKeyframes(
        named name: String,
        for property: PartialKeyPath<ElementType>,
        keyframeSequence: KeyframeSequence
    ) {
        managedKeyframeSeries.append(
            ManagedKeyframeSeries(
                id: UUID(),
                name: name,
                property: property,
                keyframeSequence: keyframeSequence
            )
        )
    }

}

internal struct ManagedKeyframeSeries<ElementType: AnyObject> {

    var id: UUID

    var name: String

    var property: PartialKeyPath<ElementType>

    var keyframeSequence: KeyframeSequence

}
