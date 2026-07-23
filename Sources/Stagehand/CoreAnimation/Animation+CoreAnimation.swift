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

extension Animation where ElementType: CoreAnimationRenderableElement {

    // MARK: - Public Methods - Execution

    /// Perform the animation on the given `element` using the Core Animation execution mode.
    ///
    /// Where `perform(on:delay:duration:repeatStyle:completion:)` renders each frame on the main thread via a
    /// `CADisplayLink` — so any main-thread stall (layout storms, keyboard work, app hangs) freezes the in-flight
    /// animation — this method compiles the animation *once* into `CAKeyframeAnimation`s that are committed to the
    /// render server. The render server animates out-of-process, so main-thread stalls can no longer drop the
    /// animation's frames.
    ///
    /// The compiled animations are produced by densely sampling each animated property through the animation's curves
    /// (and those of its child animations), which preserves the shape of *any* `AnimationCurve` without translating
    /// curves into `CAMediaTimingFunction`s.
    ///
    /// This mode comes with trade-offs:
    ///
    /// * The element's final model values are set as soon as the animation begins. While the animation is in flight,
    ///   reading an animated property returns its final value, not the value currently displayed.
    /// * Execution blocks (`addExecution(onForward:onReverse:at:)`) and property assignments
    ///   (`addAssignment(for:at:value:)`) are app-side code and cannot run on the render server. They are scheduled
    ///   on the main queue at their expected times, so under a main-thread stall they may fire late while the visuals
    ///   stay smooth — which is the point of this mode.
    /// * Only properties with a Core Animation mapping (see `CoreAnimationRenderableElement`) can be animated. This
    ///   includes properties animated by child animations, whose composed key paths (e.g. `\.subview.alpha`) are
    ///   never in the root element's mapping registry — use an `AnimationGroup` to animate multiple layer-backed
    ///   elements in this mode.
    ///
    /// When the animation *can't* be represented on the render server — it animates an unmapped property, has
    /// per-frame execution blocks, or repeats indefinitely while containing execution blocks or property assignments —
    /// this method raises a debug assertion and falls back to the display-link execution mode, so release behavior
    /// degrades gracefully. The returned instance's `executionMode` indicates which mode is executing the animation.
    ///
    /// The duration and repeat style for each cycle of the animation are determined the same way as in
    /// `perform(on:delay:duration:repeatStyle:completion:)`.
    ///
    /// - parameter element: The element to be animated.
    /// - parameter delay: The time interval to wait before performing the animation.
    /// - parameter duration: The duration to use for each cycle the animation.
    /// - parameter repeatStyle: The repeat style to use for the animation.
    /// - parameter completion: The completion block to call when the animation has concluded, with a parameter
    /// indicated whether the animation completed (as opposed to being cancelled).
    /// - returns: An instance that can be used to check the status of or cancel the animation.
    @discardableResult
    public func performUsingCoreAnimation(
        on element: ElementType,
        delay: TimeInterval = 0,
        duration: TimeInterval? = nil,
        repeatStyle: AnimationRepeatStyle? = nil,
        completion: ((_ finished: Bool) -> Void)? = nil
    ) -> CoreAnimationInstance {
        let animation = optimized()
        let cycleDuration = duration ?? implicitDuration
        let repeatStyle = repeatStyle ?? implicitRepeatStyle

        func fallBackToDisplayLink(_ reason: String) -> CoreAnimationInstance {
            CoreAnimationFallbackAssertions.assertionHandler(reason)
            return CoreAnimationInstance(
                fallingBackTo: perform(
                    on: element,
                    delay: delay,
                    duration: cycleDuration,
                    repeatStyle: repeatStyle,
                    completion: completion
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

        let initialValues: [PartialKeyPath<ElementType>: Any] = Dictionary(
            uniqueKeysWithValues: animation.propertiesWithKeyframes.map { ($0, element[keyPath: $0]) }
        )

        guard
            let compiledElement = animation.compileCoreAnimations(
                for: element,
                initialValues: initialValues,
                timelineToLocalRawProgress: nil,
                sampleCount: Animation.coreAnimationSampleCount(for: cycleDuration)
            )
        else {
            return fallBackToDisplayLink(
                "The animation includes a keyframe series whose property has no Core Animation mapping on \(ElementType.self). Falling back to the display-link driver."
            )
        }

        let instance = CoreAnimationInstance(
            compiledElements: [compiledElement],
            delay: delay,
            cycleDuration: cycleDuration,
            repeatStyle: repeatStyle,
            executor: Executor(animation: animation, element: element),
            executionEventRawTimestamps: executionEventRawTimestamps,
            applyModelValues: { [weak element] relativeTimestamp in
                guard var element = element else {
                    return
                }

                animation.apply(to: &element, at: relativeTimestamp, initialValues: initialValues)
            },
            completions: [completion].compactMap { $0 }
        )

        instance.start()

        return instance
    }

    // MARK: - Internal Methods

    /// Compiles the animation's keyframe series into `CAKeyframeAnimation`s targeting the `element`'s rendering
    /// layer, or returns `nil` when any animated property has no Core Animation mapping.
    ///
    /// - parameter element: The element to be animated.
    /// - parameter initialValues: A dictionary mapping the property animated by each keyframe series to the value of
    /// that property when the animation begins.
    /// - parameter timelineToLocalRawProgress: Maps the raw progress of the compiled animations' timeline to this
    /// animation's raw progress. Pass `nil` when the animation itself defines the timeline.
    /// - parameter sampleCount: The number of evenly spaced samples to compile each property's values into.
    internal func compileCoreAnimations(
        for element: ElementType,
        initialValues: [PartialKeyPath<ElementType>: Any],
        timelineToLocalRawProgress: (@MainActor (Double) -> Double)?,
        sampleCount: Int
    ) -> CompiledCoreAnimationElement? {
        let mappings = ElementType.coreAnimationPropertyMappings(rootedAt: ElementType.self)

        let keyTimes = (0..<sampleCount).map { NSNumber(value: Double($0) / Double(sampleCount - 1)) }

        var animations: [CAKeyframeAnimation] = []

        for property in propertiesWithKeyframes {
            guard let mapping = mappings[property] else {
                return nil
            }

            var values: [Any] = []
            for sampleIndex in 0..<sampleCount {
                let timelineProgress = Double(sampleIndex) / Double(sampleCount - 1)
                let rawProgress = timelineToLocalRawProgress?(timelineProgress) ?? timelineProgress

                guard let value = sampleValue(for: property, at: rawProgress, initialValues: initialValues) else {
                    return nil
                }

                values.append(mapping.makeAnimationValue(value))
            }

            let keyframeAnimation = CAKeyframeAnimation(keyPath: mapping.layerKeyPath)
            keyframeAnimation.values = values
            keyframeAnimation.keyTimes = keyTimes

            // The samples are already dense enough to preserve the animation's curves, so simple linear interpolation
            // between them reproduces the display-link driver's rendering.
            keyframeAnimation.calculationMode = .linear

            animations.append(keyframeAnimation)
        }

        return CompiledCoreAnimationElement(
            layer: element.layerForCoreAnimationRendering,
            animations: animations
        )
    }

}
