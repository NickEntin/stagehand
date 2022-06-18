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

import ChoreographerNetworking
import Memo
import Stagehand

public final class ManagedAnimation<ElementType: AnyObject> {

    // MARK: - Life Cycle

    internal init(blueprint: ManagedAnimationBlueprint<ElementType>, id: Token<SerializableAnimationBlueprint>) {
        self.blueprint = blueprint
        self.id = id
    }

    // MARK: - Internal Properties

    internal var blueprint: ManagedAnimationBlueprint<ElementType>

    internal let id: Token<SerializableAnimationBlueprint>

    // MARK: - Public Methods

    @discardableResult
    public func perform(
        on element: ElementType,
        delay: TimeInterval = 0,
        duration: TimeInterval? = nil,
        repeatStyle: AnimationRepeatStyle? = nil,
        completion: ((_ finished: Bool) -> Void)? = nil
    ) -> AnimationInstance {
        let animation = buildAnimation()

        return animation.perform(
            on: element,
            delay: delay,
            duration: duration,
            repeatStyle: repeatStyle,
            completion: completion
        )
    }

    // MARK: - Internal Methods

    internal func buildAnimation() -> Animation<ElementType> {
        var animation = Animation<ElementType>()

        animation.implicitDuration = blueprint.implicitDuration
        animation.implicitRepeatStyle = blueprint.implicitRepeatStyle
        animation.curve = blueprint.curve.animationCurve

        for keyframeSeries in blueprint.managedKeyframeSeries.filter({ $0.enabled }) {
            switch keyframeSeries.keyframeSequence {
            case let .double(keyframes):
                add(keyframes: keyframes, for: keyframeSeries.property, to: &animation)
            case let .cgfloat(keyframes):
                add(keyframes: keyframes, for: keyframeSeries.property, to: &animation)
            case let .color(keyframes):
                add(keyframes: keyframes, for: keyframeSeries.property, to: &animation)
            }
        }

        for keyframeSeries in blueprint.unmanagedKeyframeSeries.filter({ $0.enabled }) {
            keyframeSeries.addToAnimation(&animation)
        }

        // TODO: Add managed property assignments

        // TODO: Add unmanaged property assignments

        for executionBlock in blueprint.managedExeuctionBlocks.filter({ $0.enabled }) {
            executionBlock.addToAnimation(&animation)
        }

        // TODO: Add unmanaged execution blocks

        // TODO: Add unmanaged per-frame execution blocks

        for child in blueprint.childManagedAnimations.filter({ $0.enabled }) {
            child.addToAnimation(&animation)
        }

        // TODO: Add child blueprints

        // TODO: Add unmanaged child animations

        return animation
    }

    // MARK: - Private Methods

    private func add<PropertyType: AnimatableProperty>(
        keyframes: [Keyframe<PropertyType>],
        for property: PartialKeyPath<ElementType>,
        to animation: inout Animation<ElementType>
    ) {
        let writableProperty = property as! WritableKeyPath<ElementType, PropertyType>
        for keyframe in keyframes {
            animation.addKeyframe(for: writableProperty, at: keyframe.relativeTimestamp, value: keyframe.value)
        }
    }

    private func add(
        keyframes: [Keyframe<RGBAColor>],
        for property: PartialKeyPath<ElementType>,
        to animation: inout Animation<ElementType>
    ) {
        let writableProperty = property as! WritableKeyPath<ElementType, CGColor>
        for keyframe in keyframes {
            animation.addKeyframe(
                for: writableProperty,
                at: keyframe.relativeTimestamp,
                value: keyframe.value.toCGColor()
            )
        }
    }

}
