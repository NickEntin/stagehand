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

import Foundation

extension Animation {

    // MARK: - Internal Static Methods

    /// The number of samples used when compiling an animation cycle of the given duration into `CAKeyframeAnimation`s.
    ///
    /// Sampling densely (120 samples per second, capped at 240 samples) preserves the shape of *any*
    /// `AnimationCurve` — springs, custom cubic Béziers, etc. — without needing to translate curves into
    /// `CAMediaTimingFunction`s, which can only represent cubic Béziers.
    internal static func coreAnimationSampleCount(for cycleDuration: TimeInterval) -> Int {
        return min(max(2, Int(cycleDuration * 120)), 240)
    }

    // MARK: - Internal Methods

    /// Returns the value of the given `property` at the given `relativeTimestamp`, as it would be rendered by the
    /// display-link driver, without mutating any element.
    ///
    /// This mirrors the behavior of `apply(to:at:initialValues:)`, with one simplification: outside of a child
    /// animation's time window, the child's boundary value (its value at a relative timestamp of 0 or 1) is used,
    /// rather than whatever value happened to be rendered by an earlier frame. For monotonically-sampled timestamps —
    /// which is how the Core Animation compiler consumes this — the two are equivalent.
    ///
    /// - parameter property: The property to sample. Must be a member of `propertiesWithKeyframes`.
    /// - parameter relativeTimestamp: The raw (non-curved) timestamp at which to sample the value.
    /// - parameter initialValues: A dictionary mapping the property animated by each keyframe series to the value of
    /// that property when the animation begins.
    internal func sampleValue(
        for property: PartialKeyPath<ElementType>,
        at relativeTimestamp: Double,
        initialValues: [PartialKeyPath<ElementType>: Any]
    ) -> Any? {
        let adjustedRelativeTimestamp = curve.adjustedProgress(for: relativeTimestamp)

        var value: Any?

        for child in children {
            guard child.animation.propertiesWithKeyframes.contains(property) else {
                continue
            }

            // Allow for the child to be sampled _slightly_ outside its timestamp range to account for rounding error,
            // matching the behavior of `apply(to:at:initialValues:)`.
            let ε = 0.0000000001

            let childRelativeTimestamp = (adjustedRelativeTimestamp - child.relativeStartTimestamp) / child.relativeDuration

            guard childRelativeTimestamp >= -ε else {
                // The child hasn't started yet, so it doesn't contribute a value.
                continue
            }

            value = child.animation.sampleValue(
                for: property,
                at: childRelativeTimestamp.clamped(in: 0...1),
                initialValues: initialValues
            ) ?? value
        }

        if let keyframeSeries = keyframeSeriesByProperty[property] {
            value = keyframeSeries.value(at: adjustedRelativeTimestamp, initialValue: initialValues[property]!)
        }

        if value == nil, let earliestKeyframeSeries = keyframeSeries(for: property)?.0 {
            // Nothing is animating the property yet. Hold the animation's initial pose for the property, matching
            // `applyInitialKeyframes(to:initialValues:)`.
            value = earliestKeyframeSeries.value(at: 0, initialValue: initialValues[property]!)
        }

        return value
    }

    /// The raw (non-curved) relative timestamps at which execution blocks and property assignments occur, including
    /// those of child animations.
    ///
    /// Since execution block timestamps are defined against the curved progress of their animation, and curves are
    /// not necessarily monotonic, a single block can occur at multiple raw timestamps.
    internal var executionEventRawTimestamps: [Double] {
        var rawTimestamps = Set<Double>()

        let ownRelativeTimestamps = executionBlocks.map { $0.relativeTimestamp }
            + assignments.map { $0.relativeTimestamp }

        for relativeTimestamp in ownRelativeTimestamps {
            rawTimestamps.formUnion(curve.rawProgress(for: relativeTimestamp))
        }

        for child in children {
            for childRawTimestamp in child.animation.executionEventRawTimestamps {
                let timestampInParent = child.relativeStartTimestamp + childRawTimestamp * child.relativeDuration
                rawTimestamps.formUnion(curve.rawProgress(for: timestampInParent))
            }
        }

        return rawTimestamps.sorted()
    }

}
