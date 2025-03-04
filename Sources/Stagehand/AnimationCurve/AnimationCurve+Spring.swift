// Created by Nick Entin on 3/3/25.

import Foundation

public struct SpringAnimationCurve: AnimationCurve {

    public init(damping: CGFloat, initialVelocity: CGFloat) {
        self.damping = damping
        self.initialVelocity = initialVelocity
    }

    private let damping: CGFloat
    private let initialVelocity: CGFloat

    public func adjustedProgress(for progress: Double) -> Double {
        // Ensure input progress is within bounds
        let t = min(max(progress, 0.0), 1.0)

        // If we're exactly at the end, we should be exactly at the destination
        if t >= 1.0 {
            return 1.0
        }

        // Calculate the base spring value
        let dampingRatio = min(max(Double(damping), 0.0), 1.0)
        let naturalFreq = 10.0
        let dampedFreq = naturalFreq * sqrt(1.0 - dampingRatio * dampingRatio)

        // Fix: Reverse the sign of initial velocity to match expected behavior
        // In UIKit, positive velocity means the animation starts moving toward the target
        let velocity = -Double(initialVelocity) * naturalFreq

        let springValue: Double
        if dampingRatio >= 1.0 {
            // Critically damped or overdamped spring
            let zeta = dampingRatio
            let expTerm = exp(-zeta * naturalFreq * t)
            springValue = 1.0 - expTerm * (1.0 + (zeta * naturalFreq + velocity) * t)
        } else {
            // Underdamped spring (with oscillation)
            let zeta = dampingRatio
            let expTerm = exp(-zeta * naturalFreq * t)

            let sinCoeff = velocity / dampedFreq + (zeta * naturalFreq) / dampedFreq
            springValue = 1.0 - expTerm * (cos(dampedFreq * t) + sinCoeff * sin(dampedFreq * t))
        }

        // Apply a progressive damping effect as we approach t = 1.0
        let endDampingStart = 0.7 // When to start forcing convergence

        if t > endDampingStart {
            // Calculate how far into the damping region we are (0 to 1)
            let dampingFactor = (t - endDampingStart) / (1.0 - endDampingStart)

            // Use a smooth easing function for the blend
            let smoothDampingFactor = dampingFactor * dampingFactor * (3.0 - 2.0 * dampingFactor)

            // Blend between spring value and 1.0 using the smooth damping factor
            return springValue * (1.0 - smoothDampingFactor) + 1.0 * smoothDampingFactor
        } else {
            return springValue
        }
    }

    public func rawProgress(for adjustedProgress: Double) -> [Double] {
        // Handle boundary cases
        if adjustedProgress >= 1.0 {
            return [1.0]
        }

        if adjustedProgress <= 0.0 {
            return [0.0]
        }

        // For intermediate values, find crossings with numerical approach
        let targetValue = adjustedProgress
        let sampleCount = 1000
        var crossingPoints: [Double] = []

        var prevValue = self.adjustedProgress(for: 0.0) - targetValue

        for i in 1...sampleCount {
            let t = Double(i) / Double(sampleCount)
            let currentValue = self.adjustedProgress(for: t) - targetValue

            // If we crossed zero, we found a point
            if prevValue * currentValue <= 0.0 {
                // Linear interpolation for better accuracy
                let ratio = abs(prevValue) / (abs(prevValue) + abs(currentValue))
                let refinedT = t - Double(1) / Double(sampleCount) + ratio * Double(1) / Double(sampleCount)

                if refinedT >= 0.0 && refinedT <= 1.0 {
                    // Check if this point is unique enough
                    let isUnique = crossingPoints.allSatisfy { abs($0 - refinedT) > 0.01 }
                    if isUnique {
                        crossingPoints.append(refinedT)
                    }
                }
            }

            prevValue = currentValue
        }

        // Handle case where no crossing points are found
        if crossingPoints.isEmpty {
            var bestT = 0.0
            var minDiff = Double.infinity

            for i in 0...sampleCount {
                let t = Double(i) / Double(sampleCount)
                let diff = abs(self.adjustedProgress(for: t) - targetValue)
                if diff < minDiff {
                    minDiff = diff
                    bestT = t
                }
            }

            return [bestT]
        }

        return crossingPoints
    }
}
