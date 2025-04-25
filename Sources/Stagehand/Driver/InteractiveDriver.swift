// Created by Nick Entin on 3/3/25.

import Foundation
import UIKit

@MainActor
internal final class InteractiveDriver {
    // MARK: Initialization

    init(
        endToEndDuration: TimeInterval,
        completion: ((Bool) -> Void)?
    ) {
        self.endToEndDuration = endToEndDuration
        self.completion = completion
    }

    // MARK: Internal

    // Note the animation instance is held strongly here. This creates a retain cycle between the driver and the
    // animation instance. This allows the pair to continue animating even when the consumer discards the result of
    // `Animation.performInteractive(...)` and doesn't hold a reference to the animation instance. Once the animation
    // completes, this reference will be set to `nil` and the retain cycle will be broken.
    var animationInstance: InteractiveAnimationInstance!

    func animationInstanceDidCancel(behavior: InteractiveAnimationInstance.CancelationBehavior) {
        guard !status.isComplete else {
            // We're already complete. Nothing to do here.
            return
        }

        // Note: Halting currently always counts as "not finishing" the animation, even when relativeTimestamp = 1. We may want to reconsider this at some point. Right now it follows the intention of the method call (halt where you are, don't finish the animation), rather than the visual state (at 1 the animation is visually finished).

        let (relativeTimestamp, didComplete): (Double, Bool) = switch (behavior, mode) {
        case (.revert, _):
            (0, false)
        case let (.halt, .manual(relativeTimestamp)):
            (relativeTimestamp, false)
        case let (.halt, .automatic(context)):
            (context.currentRelativeTimestamp(), false)
        case (.complete, _):
            (1, true)
        }

        if case let .automatic(context) = mode {
            context.displayLink.invalidate()
            context.completion?(didComplete)
        }

        mode = .manual(relativeTimestamp: relativeTimestamp)

        renderCurrentFrame()
        status = .completed(success: false)
        completion?(false)
        animationInstance = nil
    }

    func animate(
        to targetRelativeTimestamp: Double,
        using curve: AnimationCurve = LinearAnimationCurve(),
        duration: TimeInterval? = nil,
        completion: ((_ finished: Bool) -> Void)? = nil
    ) {
        guard !status.isComplete else {
            // The animation has already completed, so there's nothing to animate.
            return
        }

        // Invalidate any in-progress automatic animation.
        if case let .automatic(context) = mode {
            context.displayLink.invalidate()
            context.completion?(false)
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
            endRelativeTimestamp: targetRelativeTimestamp,
            completion: completion
        )

        mode = .automatic(context)

        context.displayLink.add(to: .main, forMode: .common)
    }

    func updateProgress(to relativeTimestamp: Double) {
        guard !status.isComplete else {
            // The animation has already completed, so there's nothing to animate.
            return
        }

        // Invalidate any in-progress automatic animation.
        if case let .automatic(context) = mode {
            context.displayLink.invalidate()
            context.completion?(false)
        }

        mode = .manual(relativeTimestamp: relativeTimestamp)

        renderCurrentFrame()
    }

    func markAsComplete() {
        guard !status.isComplete else {
            return
        }

        status = .completed(success: true)

        // Invalidate any in-progress automatic animation.
        if case let .automatic(context) = mode {
            context.displayLink.invalidate()
            context.completion?(true)
        }

        completion?(true)
        animationInstance = nil
    }

    let endToEndDuration: TimeInterval

    // MARK: Private

    private let completion: ((Bool) -> Void)?

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

        var completion: ((Bool) -> Void)?

        /// The current progress, based on the display link's timestamp, with the `segmentCurve` applied.
        func currentRelativeTimestamp() -> Double {
            let relativeDuration = (endRelativeTimestamp - startRelativeTimestamp)
            if relativeDuration == 0 || segmentDuration == 0 {
                return endRelativeTimestamp
            } else {
                let progress = (displayLink.timestamp - startTime) / segmentDuration
                let curvedProgress = segmentCurve.adjustedProgress(for: progress)
                let rawRelativeTimestamp = (relativeDuration * curvedProgress + startRelativeTimestamp)
                return rawRelativeTimestamp.clamped(in: 0...1)
            }
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

        let executingInReverse: Bool
        if let lastRenderedFrame = lastRenderedFrame {
            if relativeTimestamp != lastRenderedFrame.relativeTimestamp {
                executingInReverse = if relativeTimestamp == lastRenderedFrame.relativeTimestamp {
                    lastRenderedFrame.executingInReverse
                } else {
                    relativeTimestamp < lastRenderedFrame.relativeTimestamp
                }

                animationInstance.executeBlocks(
                    from: lastRenderedFrame.relativeTimestamp,
                    executingInReverse == lastRenderedFrame.executingInReverse ? .exclusive : .inclusive,
                    to: relativeTimestamp
                )
            } else {
                executingInReverse = lastRenderedFrame.executingInReverse
            }
        } else {
            animationInstance.executeBlocks(
                from: 0,
                .inclusive,
                to: relativeTimestamp
            )
            executingInReverse = false
        }

        animationInstance.renderFrame(at: relativeTimestamp)

        lastRenderedFrame = .init(relativeTimestamp: relativeTimestamp, executingInReverse: executingInReverse)

        if case let .automatic(context) = mode, context.endRelativeTimestamp == relativeTimestamp {
            // The automatic part of the animation is complete.
            context.displayLink.invalidate()
            context.completion?(true)
            mode = .manual(relativeTimestamp: relativeTimestamp)
        }
    }
}
