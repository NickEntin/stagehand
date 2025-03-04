// Created by Nick Entin on 3/3/25.

import Foundation

public final class InteractiveAnimationInstance {
    // MARK: Initialization

    internal init<ElementType: AnyObject>(
        animation: Animation<ElementType>,
        element: ElementType,
        driver: InteractiveDriver
    ) {
        // @NICK TODO
    }

    // MARK: Public

    public func setProgress(_ progress: Double) {
        switch status {
        case .complete:
            // If the animation is already complete, we can't animate it again.
            return

        case .pending, .interactive, .animating:
            break
        }

        // @NICK TODO
    }

    /// Begins animating a segment of the animation from the current relative timestamp to a specific point in the animation.
    ///
    /// The `curve` will be applied to the segment on top of any existing animation curve.
    ///
    /// The duration of the animation segment will be determined based on the follow order of preference:
    /// 1. The explicit segment duration, if specified using the `duration` parameter
    /// 2. A relative portion of the explicit end-to-end duration, if specified when performing the animation
    /// 3. A relative portion of the animation's implicit duration
    ///
    /// - parameter relativeTimestamp: The target relative timestamp.
    /// - parameter curve: The curve to apply over the segment of the animation.
    /// - parameter duration: The duration over which to perfom the specified segment of the animation.
    public func animate(
        to relativeTimestamp: Double,
        using curve: AnimationCurve = LinearAnimationCurve(),
        duration: TimeInterval? = nil
    ) {
        switch status {
        case .pending, .interactive, .animating:
            break

        case .complete:
            // If the animation is already complete, or was canceled, we can't animate it again.
            return
        }

        driver.animate(to: relativeTimestamp, using: curve, duration: duration)
    }

    public func animateToBeginning(
        using curve: AnimationCurve = LinearAnimationCurve(),
        duration: TimeInterval? = nil
    ) {
        animate(to: 0, using: curve, duration: duration)
    }

    public func animateToEnd(
        using curve: AnimationCurve = LinearAnimationCurve(),
        duration: TimeInterval? = nil
    ) {
        animate(to: 1, using: curve, duration: duration)
    }

    public func markAsComplete() {
        status = .complete
    }

    public enum Status {
        case pending
        case interactive(progress: Double)
        case animating(progress: Double)
        case complete
    }

    public private(set) var status: Status = .pending
}
