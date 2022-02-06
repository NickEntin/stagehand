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
import Foundation

public final class ManagedAnimation<ElementType: AnyObject> {

    // MARK: - Life Cycle

    internal init(blueprint: ManagedAnimationBlueprint<ElementType>) {
        self.managedKeyframeSeries = blueprint.managedKeyframeSeries
    }

    // MARK: - Private Properties

    private var managedKeyframeSeries: [ManagedKeyframeSeries<ElementType>] = []

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

    // MARK: - Private Methods

    private func buildAnimation() -> Animation<ElementType> {
        var animation = Animation<ElementType>()

        for keyframeSeries in managedKeyframeSeries {
            switch keyframeSeries.keyframeSequence {
            case let .double(keyframes):
                add(keyframes: keyframes, for: keyframeSeries.property, to: &animation)
            case let .cgfloat(keyframes):
                add(keyframes: keyframes, for: keyframeSeries.property, to: &animation)
            }
        }

        return animation
    }

    private func add<PropertyType: AnimatableProperty>(
        keyframes: [(Double, PropertyType)],
        for property: PartialKeyPath<ElementType>,
        to animation: inout Animation<ElementType>
    ) {
        let writableProperty = property as! WritableKeyPath<ElementType, PropertyType>
        for (relativeTimestamp, value) in keyframes {
            animation.addKeyframe(for: writableProperty, at: relativeTimestamp, value: value)
        }
    }

}
