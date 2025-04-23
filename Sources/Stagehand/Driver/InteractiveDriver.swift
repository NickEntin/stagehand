// Created by Nick Entin on 3/3/25.

import Foundation

internal final class InteractiveDriver {
    // MARK: Initialization

    init(endToEndDuration: TimeInterval) {
        self.endToEndDuration = endToEndDuration
    }

    // MARK: Internal

    // Note the animation instance is held strongly here. This creates a retain cycle between the driver and the
    // animation instance. This allows the pair to continue animating even when the consumer discards the result of
    // `Animation.performInteractive(...)` and doesn't hold a reference to the animation instance. Once the animation
    // completes, this reference will be set to `nil` and the retain cycle will be broken.
    var animationInstance: InteractiveAnimationInstance!

    // @NICK TODO: Might not need this exactly
    func animationInstanceDidCancel(behavior: AnimationInstance.CancelationBehavior) {
        guard !status.isComplete else {
            // We're already complete. Nothing to do here.
            return
        }

        switch behavior {
        case .revert:
            mode = .manual(relativeTimestamp: 0)

        case .halt:
            switch mode {
            case .manual:
                break // No-op.

            case let .automatic(context):
                mode = .manual(relativeTimestamp: context.currentRelativeTimestamp())

                context.displayLink.invalidate()
            }

        case .complete:
            mode = .manual(relativeTimestamp: 1)
        }

        renderCurrentFrame()
        status = .completed(success: false)
        animationInstance = nil
    }

    func animate(
        to targetRelativeTimestamp: Double,
        using curve: AnimationCurve = LinearAnimationCurve(),
        duration: TimeInterval? = nil
    ) {
        guard !status.isComplete else {
            // The animation has already completed, so there's nothing to animate.
            return
        }

        // Invalidate any in-progress automatic animation.
        if case let .automatic(context) = mode {
            context.displayLink.invalidate()
        }

        let startRelativeTimestamp = lastRenderedFrame?.relativeTimestamp ?? 0
        let segmentRelativeDuration = (targetRelativeTimestamp - startRelativeTimestamp)
        let segmentDuration = duration ?? abs(segmentRelativeDuration * endToEndDuration)

        let context = AutomaticContext(
            displayLink: .init(target: self, selector: #selector(renderCurrentFrame)),
            startTime: CACurrentMediaTime(),
            segmentDuration: segmentDuration,
            segmentCurve: curve,
            startRelativeTimestamp: startRelativeTimestamp,
            endRelativeTimestamp: targetRelativeTimestamp
        )

        mode = .automatic(context)

        context.displayLink.add(to: .current, forMode: .common)
    }

    func updateProgress(to relativeTimestamp: Double) {
        guard !status.isComplete else {
            // The animation has already completed, so there's nothing to animate.
            return
        }

        // Invalidate any in-progress automatic animation.
        if case let .automatic(context) = mode {
            context.displayLink.invalidate()
        }

        mode = .manual(relativeTimestamp: relativeTimestamp)

        renderCurrentFrame()
    }

    // MARK: Private

    private let endToEndDuration: TimeInterval

    private enum Status {
        case active
        case completed(success: Bool)

        var isComplete: Bool {
            switch self {
            case .active: false
            case .completed: true
            }
        }
    }

    private var status: Status = .active

    private enum Mode {
        case manual(relativeTimestamp: Double)
        case automatic(AutomaticContext)
    }

    private var mode: Mode = .manual(relativeTimestamp: 0)

    private struct AutomaticContext {
        /// The display link that's driving the current context.
        var displayLink: CADisplayLink

        /// The time at which the display link was added to the run loop.
        var startTime: TimeInterval

        /// The duration of the segment between the `startRelativeTimestamp` and `endRelativeTimestamp`.
        var segmentDuration: TimeInterval

        /// The animation curve applied on top of the segment between the `startRelativeTimestamp` and
        /// `endRelativeTimestamp`.
        var segmentCurve: AnimationCurve

        var startRelativeTimestamp: Double

        var endRelativeTimestamp: Double

        /// The current progress, based on the display link's timestamp, with the `segmentCurve` applied.
        func currentRelativeTimestamp() -> Double {
            let relativeDuration = (endRelativeTimestamp - startRelativeTimestamp)
            let progress = (displayLink.timestamp - startTime) / segmentDuration
            let curvedProgress = segmentCurve.adjustedProgress(for: progress)
            let rawRelativeTimestamp = (relativeDuration * curvedProgress + startRelativeTimestamp)
            return rawRelativeTimestamp.clamped(in: 0...1)
        }
    }

    private struct Frame {
        var relativeTimestamp: Double
        var executingInReverse: Bool
    }

    private var lastRenderedFrame: Frame?

    @objc private func renderCurrentFrame() {
        guard !status.isComplete else {
            // The animation has already completed, so there's nothing to animate.
            return
        }

        let relativeTimestamp = switch mode {
        case let .manual(timestamp):
            timestamp
        case let .automatic(context):
            context.currentRelativeTimestamp()
        }

        // @NICK TODO: If you hit a frame then start dragging backwards, we need to hit the reverse execution block for that last rendered frame (inclusive if direction is changing?)
        if let lastRenderedFrame = lastRenderedFrame {
            animationInstance.executeBlocks(
                from: lastRenderedFrame.relativeTimestamp,
                .exclusive,
                to: relativeTimestamp
            )
        } else {
            animationInstance.executeBlocks(
                from: 0,
                .inclusive,
                to: relativeTimestamp
            )
        }

        animationInstance.renderFrame(at: relativeTimestamp)

        // @NICK TODO: False seems wrong here when relativeTimestamp < lastRenderedFrame.relativeTimestamp
        lastRenderedFrame = .init(relativeTimestamp: relativeTimestamp, executingInReverse: false)

        if case let .automatic(context) = mode, context.endRelativeTimestamp == relativeTimestamp {
            // The automatic part of the animation is complete.
            context.displayLink.invalidate()
            mode = .manual(relativeTimestamp: relativeTimestamp)
        }
    }
}
