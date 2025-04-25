// Created by Nick Entin on 3/3/25.

import Foundation

@MainActor
public final class InteractiveAnimationInstance {
    // MARK: Initialization

    internal init<ElementType: AnyObject>(
        animation: Animation<ElementType>,
        element: ElementType,
        driver: InteractiveDriver
    ) {
        let animation = animation.optimized()

        self.keyframeRelativeTimestamps = animation.keyframeRelativeTimestamps

        self.renderer = Renderer(animation: animation, element: element)
        self.executor = Executor(animation: animation, element: element)

        self.perFrameExecutionBlocks = animation.perFrameExecutionBlocks
            .map { block in
                return { [weak element] relativeTimestamp in
                    guard let element else {
                        return
                    }

                    block(
                        .init(
                            element: element,
                            uncurvedProgress: relativeTimestamp,
                            progress: animation.curve.adjustedProgress(for: relativeTimestamp)
                        )
                    )
                }
            }

        self.driver = driver
        driver.animationInstance = self
    }

    // MARK: Public

    public func setProgress(_ progress: Double) {
        guard !status.isComplete else {
            // The animation is already complete, there's nothing to animate here.
            return
        }

        driver.updateProgress(to: progress)
    }

    public func pause() {
        switch status {
        case let .animating(progress):
            driver.updateProgress(to: progress)
        case .interactive, .complete, .pending, .canceled:
            break
        }
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
        duration: TimeInterval? = nil,
        completion: ((_ finished: Bool) -> Void)? = nil,
    ) {
        guard !status.isComplete else {
            // The animation is already complete, there's nothing to animate here.
            return
        }

        driver.animate(to: relativeTimestamp, using: curve, duration: duration, completion: completion)
    }

    public func animateToBeginning(
        using curve: AnimationCurve = LinearAnimationCurve(),
        duration: TimeInterval? = nil,
        completion: ((_ finished: Bool) -> Void)? = nil,
    ) {
        animate(to: 0, using: curve, duration: duration, completion: completion)
    }

    public func animateToEnd(
        using curve: AnimationCurve = LinearAnimationCurve(),
        duration: TimeInterval? = nil,
        completion: ((_ finished: Bool) -> Void)? = nil,
    ) {
        animate(to: 1, using: curve, duration: duration, completion: completion)
    }

    public func markAsComplete() {
        driver.markAsComplete()
        status = .complete
    }

    public enum CancelationBehavior {
        /// Return the element back to its state at the beginning of the animation. This will cause the completion handlers to be called with a `finished` of false.
        case revert
        /// Stop the animation at its current progress. This will cause the completion handlers to be called with a `finished` of false.
        case halt
        /// Apply the final values of the animation. This will cause the completion handlers to be called with a `finished` of true.
        case complete
    }

    public func cancel(behavior: CancelationBehavior = .halt) {
        guard !status.isComplete else {
            return
        }

        status = .canceled(behavior: behavior)
        driver.animationInstanceDidCancel(behavior: behavior)
    }

    public enum Status {
        case pending
        case interactive(progress: Double)
        case animating(progress: Double)
        case complete
        case canceled(behavior: CancelationBehavior)

        var isComplete: Bool {
            switch self {
            case .pending, .interactive, .animating:
                false
            case .complete, .canceled:
                true
            }
        }
    }

    public private(set) var status: Status = .pending

    public var endToEndDuration: TimeInterval {
        driver.endToEndDuration
    }

    // MARK: Internal

    func executeBlocks(
        from startingRelativeTimestamp: Double,
        _ fromInclusivity: Executor.Inclusivity,
        to endingRelativeTimestamp: Double
    ) {
        executor.executeBlocks(from: startingRelativeTimestamp, fromInclusivity, to: endingRelativeTimestamp)
    }

    /// Renders the frame at the specific timestamp, including rendering any keyframes between the timestamp between the
    /// previously rendered frame and the specific timestamp.
    ///
    /// - parameter relativeTimestamp: The relative timestamp to render, with no curves applied.
    func renderFrame(
        at relativeTimestamp: Double
    ) {
        // If our renderer doesn't have an element to render, halt the animation since there's nothing to do.
        guard renderer.canRenderFrame() else {
            cancel(behavior: .halt)
            return
        }

        status = .animating(progress: relativeTimestamp)

        // If we skipped any keyframes since the last frame we rendered, render them now. If we don't do this, we might
        // skip rendering the last keyframe of a child animation, leaving the properties of that animation in their
        // value just shy of the value specified by the final keyframe.
        let skippedKeyframesToRender: [Double]

        if let lastRenderedTimestamp = lastRenderedFrameRelativeTimestamp {
            let skippedRangeToCheck = ClosedRange(unorderedBounds: (lastRenderedTimestamp, relativeTimestamp))
            skippedKeyframesToRender = keyframeRelativeTimestamps.filter { skippedRangeToCheck.contains($0) }

        } else {
            // We haven't rendered any frames yet. Render the initial value of each property (even if it doesn't start
            // at a relative timestamp of 0).
            renderer.renderInitialFrame()

            // If the first relative timestamp we get is greater than 0 (which is unlikely in the production usage, but
            // happens a lot in snapshot tests), we might be missing some keyframes.
            if relativeTimestamp > 0 {
                let skippedRangeToCheck = 0..<relativeTimestamp
                skippedKeyframesToRender = keyframeRelativeTimestamps.filter { skippedRangeToCheck.contains($0) }

            } else {
                skippedKeyframesToRender = []
            }
        }

        for keyframe in skippedKeyframesToRender {
            renderer.renderFrame(at: keyframe)
        }

        renderer.renderFrame(at: relativeTimestamp)

        perFrameExecutionBlocks.forEach { $0(relativeTimestamp) }

        lastRenderedFrameRelativeTimestamp = relativeTimestamp
    }

    // MARK: Private

    private let driver: InteractiveDriver

    private let renderer: AnyRenderer
    private let executor: Executor
    private let perFrameExecutionBlocks: [(Double) -> Void]

    /// The relative timestamps corresponding to keyframes in the animation, without any curves applied.
    private let keyframeRelativeTimestamps: [Double]

    private var lastRenderedFrameRelativeTimestamp: Double?
}
