//
//  Copyright 2026 Square Inc.
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

import QuartzCore

extension AnimationGroup {

    // MARK: - Public Methods

    /// Perform the animations in the group using the Core Animation execution mode.
    ///
    /// Each element's animation is compiled into `CAKeyframeAnimation`s added to that element's rendering layer. See
    /// `Animation.performUsingCoreAnimation(on:delay:duration:repeatStyle:completion:)` for a description of the
    /// execution mode, its trade-offs, and the conditions under which it raises a debug assertion and falls back to
    /// the display-link execution mode. For a group, every element must conform to `CoreAnimationRenderableElement`
    /// and every animated property must have a Core Animation mapping, otherwise the entire group falls back.
    ///
    /// The duration and repeat style for each cycle of the animation group are determined the same way as in
    /// `perform(delay:duration:repeatStyle:completion:)`.
    ///
    /// - parameter delay: The time interval to wait before performing the animation.
    /// - parameter duration: The duration to use for each cycle the animation group.
    /// - parameter repeatStyle: The repeat style to use for the animation group.
    /// - parameter groupCompletion: The completion block to call when the animation has concluded, with a parameter
    /// indicated whether the animation completed (as opposed to being cancelled).
    /// - returns: An instance that can be used to check the status of or cancel the animation group.
    @discardableResult
    public func performUsingCoreAnimation(
        delay: TimeInterval = 0,
        duration: TimeInterval? = nil,
        repeatStyle: AnimationRepeatStyle? = nil,
        completion groupCompletion: ((_ finished: Bool) -> Void)? = nil
    ) -> CoreAnimationInstance {
        let animation = self.animation.optimized()
        let cycleDuration = duration ?? implicitDuration
        let repeatStyle = repeatStyle ?? implicitRepeatStyle

        func fallBackToDisplayLink(_ reason: String) -> CoreAnimationInstance {
            CoreAnimationFallbackAssertions.assertionHandler(reason)
            return CoreAnimationInstance(
                fallingBackTo: perform(
                    delay: delay,
                    duration: cycleDuration,
                    repeatStyle: repeatStyle,
                    completion: groupCompletion
                )
            )
        }

        guard animation.perFrameExecutionBlocks.isEmpty else {
            return fallBackToDisplayLink(
                "Animations with per-frame execution blocks can't run on the render server. Falling back to the display-link driver."
            )
        }

        let executionEventRawTimestamps = animation.executionEventRawTimestamps

        if case .repeating(count: 0, autoreversing: _) = repeatStyle, !executionEventRawTimestamps.isEmpty {
            return fallBackToDisplayLink(
                "Indefinitely repeating animations with execution blocks or property assignments can't be scheduled ahead of time. Falling back to the display-link driver."
            )
        }

        // The group's curve is applied when compiling, so the compiled animations run on the group's raw timeline.
        let groupCurve = animation.curve
        let sampleCount = Animation<ElementContainer>.coreAnimationSampleCount(for: cycleDuration)

        var compiledElements: [CompiledCoreAnimationElement] = []

        for child in coreAnimationChildren {
            guard let payload = child.payload as? CoreAnimationGroupChildCompiling else {
                return fallBackToDisplayLink(
                    "The group animates an element that doesn't conform to CoreAnimationRenderableElement. Falling back to the display-link driver."
                )
            }

            let progressTransform = child.progressTransform

            guard
                let compiledElement = payload.compileCoreAnimations(
                    timelineToLocalRawProgress: { timelineProgress in
                        progressTransform(groupCurve.adjustedProgress(for: timelineProgress))
                    },
                    sampleCount: sampleCount
                )
            else {
                return fallBackToDisplayLink(
                    "The group includes a keyframe series whose property has no Core Animation mapping on its element. Falling back to the display-link driver."
                )
            }

            compiledElements.append(compiledElement)
        }

        let elementContainer = self.elementContainer
        let initialValues: [PartialKeyPath<ElementContainer>: Any] = Dictionary(
            uniqueKeysWithValues: animation.propertiesWithKeyframes.map { ($0, elementContainer[keyPath: $0]) }
        )

        let instance = CoreAnimationInstance(
            compiledElements: compiledElements,
            delay: delay,
            cycleDuration: cycleDuration,
            repeatStyle: repeatStyle,
            executor: Executor(animation: animation, element: elementContainer),
            executionEventRawTimestamps: executionEventRawTimestamps,
            applyModelValues: { relativeTimestamp in
                var elementContainer = elementContainer
                animation.apply(to: &elementContainer, at: relativeTimestamp, initialValues: initialValues)
            },
            completions: [
                { finished in
                    // Load-bearing: This line creates a retain on self until the animation completes, which transitively retains the elementContainer until the animation completes.
                    self.completions.forEach { $0(finished) }
                    groupCompletion?(finished)
                },
            ]
        )

        instance.start()

        return instance
    }

}

// MARK: -

/// An element animation added to an `AnimationGroup`, in the form consumed by the group's Core Animation execution
/// mode: the group's merged animation erases each element behind container key paths, so the group keeps this
/// parallel record of the original (element, animation) pairs and where they sit on the group's timeline.
internal struct CoreAnimationGroupChild {

    /// Maps the group's curve-adjusted cycle progress to the child element animation's raw progress, clamped to the
    /// child's time window.
    var progressTransform: @MainActor (Double) -> Double

    /// A `CoreAnimationGroupChildPayload`, type-erased so children of heterogeneous element types can be stored
    /// together. Conforms to `CoreAnimationGroupChildCompiling` exactly when the element type supports Core Animation
    /// rendering.
    var payload: Any

}

// MARK: -

@MainActor
internal struct CoreAnimationGroupChildPayload<ElementType: AnyObject> {

    var animation: Animation<ElementType>

    var element: ElementType

}

// MARK: -

@MainActor
internal protocol CoreAnimationGroupChildCompiling {

    /// Compiles the child's animation into `CAKeyframeAnimation`s targeting its element's rendering layer, or returns
    /// `nil` when any animated property has no Core Animation mapping.
    func compileCoreAnimations(
        timelineToLocalRawProgress: @escaping @MainActor (Double) -> Double,
        sampleCount: Int
    ) -> CompiledCoreAnimationElement?

}

// MARK: -

extension CoreAnimationGroupChildPayload: CoreAnimationGroupChildCompiling where ElementType: CoreAnimationRenderableElement {

    internal func compileCoreAnimations(
        timelineToLocalRawProgress: @escaping @MainActor (Double) -> Double,
        sampleCount: Int
    ) -> CompiledCoreAnimationElement? {
        let animation = self.animation.optimized()

        let initialValues: [PartialKeyPath<ElementType>: Any] = Dictionary(
            uniqueKeysWithValues: animation.propertiesWithKeyframes.map { ($0, element[keyPath: $0]) }
        )

        return animation.compileCoreAnimations(
            for: element,
            initialValues: initialValues,
            timelineToLocalRawProgress: timelineToLocalRawProgress,
            sampleCount: sampleCount
        )
    }

}
