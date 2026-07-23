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

/// An instance of an animation that has been triggered to begin using the Core Animation execution mode.
///
/// Do not create a `CoreAnimationInstance` directly. Instead, construct an `Animation` (or `AnimationGroup`), then
/// call its `performUsingCoreAnimation(...)` method to begin the animation. That method will return an instance of
/// this class, which can be used to check the status of or cancel the animation.
///
/// Unlike the display-link execution mode, the Core Animation execution mode compiles the animation *once* into
/// `CAKeyframeAnimation`s that are committed to the render server. The render server animates out-of-process, so a
/// stalled main thread (layout storms, app hangs, etc.) cannot drop the animation's frames. The trade-offs:
///
/// * The element's animated properties hold their *final* model values for the entire animation. Reading them
///   mid-flight returns the final value, not the value currently being displayed.
/// * Execution blocks and property assignments are app-side code, so they cannot run on the render server. They are
///   scheduled on the main queue at their expected times; under a main-thread stall they may fire late even though
///   the visuals stay smooth.
/// * If the animation can't be represented on the render server at all (see
///   `Animation.performUsingCoreAnimation(on:delay:duration:repeatStyle:completion:)`), the instance transparently
///   falls back to the display-link execution mode, as indicated by `executionMode`.
@MainActor
public final class CoreAnimationInstance {

    // MARK: - Life Cycle

    internal init(
        compiledElements: [CompiledCoreAnimationElement],
        delay: TimeInterval,
        cycleDuration: TimeInterval,
        repeatStyle: AnimationRepeatStyle,
        executor: Executor,
        executionEventRawTimestamps: [Double],
        applyModelValues: @escaping @MainActor (Double) -> Void,
        completions: [(Bool) -> Void]
    ) {
        self.executionMode = .coreAnimation
        self.fallbackInstance = nil

        self.compiledElements = compiledElements
        self.delay = delay
        self.cycleDuration = cycleDuration

        switch repeatStyle {
        case let .repeating(count: count, autoreversing: autoreversing):
            self.cycleCount = count
            self.autoreversing = autoreversing
        }

        self.executor = executor
        self.executionEventRawTimestamps = executionEventRawTimestamps
        self.applyModelValues = applyModelValues
        self.completions = completions
    }

    internal init(fallingBackTo instance: AnimationInstance) {
        self.executionMode = .displayLinkFallback
        self.fallbackInstance = instance

        self.compiledElements = []
        self.delay = 0
        self.cycleDuration = 0
        self.cycleCount = 1
        self.autoreversing = false
        self.executor = nil
        self.executionEventRawTimestamps = []
        self.applyModelValues = { _ in }
        self.completions = []
    }

    // MARK: - Public Types

    public enum ExecutionMode: Equatable {

        /// The animation was compiled into `CAKeyframeAnimation`s that are executed by the render server.
        case coreAnimation

        /// The animation could not be represented on the render server, and is being executed by the display-link
        /// driver instead (equivalent to having called `perform(...)`).
        case displayLinkFallback

    }

    public enum Status {

        /// The animation is in progress (or is waiting out its delay).
        case animating

        /// The animation has successfully completed.
        case complete

        /// The animation was canceled with the specified behavior.
        case canceled(behavior: AnimationInstance.CancelationBehavior)

    }

    // MARK: - Public Properties

    /// The mechanism actually executing the animation.
    public let executionMode: ExecutionMode

    public var status: Status {
        if let fallbackInstance = fallbackInstance {
            switch fallbackInstance.status {
            case .pending, .animating:
                return .animating
            case .complete:
                return .complete
            case let .canceled(behavior):
                return .canceled(behavior: behavior)
            }
        }

        return coreAnimationStatus
    }

    // MARK: - Private Properties

    private let fallbackInstance: AnimationInstance?

    private let compiledElements: [CompiledCoreAnimationElement]

    private let delay: TimeInterval

    private let cycleDuration: TimeInterval

    /// The number of cycles the animation executes, where `0` represents an animation that repeats indefinitely.
    private let cycleCount: UInt

    private let autoreversing: Bool

    private let executor: Executor?

    /// The raw relative timestamps within a cycle at which execution blocks and property assignments occur.
    private let executionEventRawTimestamps: [Double]

    /// Applies the animation's model values at the given raw relative timestamp within a cycle.
    private let applyModelValues: @MainActor (Double) -> Void

    private var completions: [(Bool) -> Void]

    private var coreAnimationStatus: Status = .animating

    private var startMediaTime: CFTimeInterval = 0

    private var addedAnimationKeysByLayer: [(layer: CALayer, keys: [String])] = []

    private var scheduledTasks: [Task<Void, Never>] = []

    private var completionProxy: CoreAnimationCompletionProxy?

    /// The position through which execution blocks have already been executed, as a cycle index and the directional
    /// raw timestamp within that cycle (ascending for forward cycles, descending for reversed cycles).
    private var lastExecutedPosition: (cycle: Int, timestamp: Double)?

    // MARK: - Private Computed Properties

    private var finalCycleIsReversed: Bool {
        return autoreversing && cycleCount != 0 && cycleCount % 2 == 0
    }

    private var finalCycleIndex: Int {
        return (cycleCount == 0) ? 0 : Int(cycleCount) - 1
    }

    // MARK: - Public Methods

    /// Cancel the animation using the specified `behavior`.
    ///
    /// The behaviors match those of `AnimationInstance.cancel(behavior:)`:
    /// * `.revert` removes the compiled animations and returns the element's model values to their state at the
    ///   beginning of the animation.
    /// * `.halt` removes the compiled animations and freezes the element's model values at the animation's current
    ///   progress, as derived from the time elapsed since the animation began.
    /// * `.complete` removes the compiled animations, leaving the element at the animation's final values.
    ///
    /// If the animation has already concluded (either by completing normally, or by having already been cancelled),
    /// this method is a no-op.
    public func cancel(behavior: AnimationInstance.CancelationBehavior = .halt) {
        if let fallbackInstance = fallbackInstance {
            fallbackInstance.cancel(behavior: behavior)
            return
        }

        guard case .animating = coreAnimationStatus else {
            return
        }

        // Bring the execution blocks up to the animation's current progress before unwinding them, matching the
        // display-link driver, which executes up to the last rendered frame before canceling. During the delay no
        // frame has been "rendered" yet, so no blocks should have executed.
        let currentPosition: (cycle: Int, timestamp: Double)
        if CACurrentMediaTime() > startMediaTime + delay {
            currentPosition = currentWallClockPosition()
            advanceExecution(toCycle: currentPosition.cycle, timestamp: currentPosition.timestamp)
        } else {
            currentPosition = (cycle: 0, timestamp: 0)
        }

        let modelValueTimestamp: Double
        switch behavior {
        case .revert:
            unwindExecutionToBeginning(from: currentPosition)
            modelValueTimestamp = 0

        case .halt:
            modelValueTimestamp = currentPosition.timestamp

        case .complete:
            if finalCycleIsReversed {
                unwindExecutionToBeginning(from: currentPosition)
                modelValueTimestamp = 0
            } else {
                windExecutionToEnd(from: currentPosition)
                modelValueTimestamp = 1
            }
        }

        coreAnimationStatus = .canceled(behavior: behavior)

        // Apply the model values before removing the compiled animations so the presentation never flashes the final
        // model values that were set when the animation began.
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        applyModelValues(modelValueTimestamp)
        removeCompiledAnimations()
        CATransaction.commit()

        cleanUp()

        completions.forEach { $0(false) }
    }

    // MARK: - Internal Methods

    internal func start() {
        startMediaTime = CACurrentMediaTime()

        guard cycleDuration > 0 else {
            // A zero-duration animation is applied immediately, matching the display-link driver, which renders its
            // final frame on the first pass.
            applyModelValuesDisablingActions(at: 1)
            advanceExecution(toCycle: 0, timestamp: 1)
            coreAnimationStatus = .complete
            let completions = self.completions
            Task { @MainActor in
                completions.forEach { $0(true) }
            }
            return
        }

        // Set the final model values up front. The compiled animations provide the presentation values for the whole
        // run, so the model can already reflect where the element will end up.
        applyModelValuesDisablingActions(at: finalCycleIsReversed ? 0 : 1)

        addCompiledAnimations()

        scheduleExecutionEvents()

        if compiledElements.allSatisfy({ $0.animations.isEmpty }), cycleCount != 0 {
            // There are no compiled animations to attach a completion to, so complete on a timer.
            let deadline = startMediaTime + delay + Double(cycleCount) * cycleDuration
            scheduledTasks.append(Task { @MainActor in
                await Self.sleep(until: deadline)
                guard !Task.isCancelled else {
                    return
                }
                self.handleAnimationsDidStop(finished: true)
            })
        }
    }

    // MARK: - Private Methods - Core Animation

    private func addCompiledAnimations() {
        let repeatCount: Float
        let autoreverses: Bool
        if cycleCount == 0 {
            repeatCount = .infinity
            autoreverses = autoreversing
        } else if autoreversing {
            // Each Core Animation repetition of an autoreversing animation covers two Stagehand cycles (one forward,
            // one back), so a fractional repeat count expresses an odd number of cycles.
            repeatCount = Float(cycleCount) / 2
            autoreverses = true
        } else {
            repeatCount = Float(cycleCount)
            autoreverses = false
        }

        let proxy = CoreAnimationCompletionProxy()
        proxy.didStop = { [self] finished in
            handleAnimationsDidStop(finished: finished)
        }
        completionProxy = proxy

        var needsCompletionDelegate = true

        let now = CACurrentMediaTime()

        for element in compiledElements {
            let layer = element.layer
            var keys: [String] = []

            for (index, animation) in element.animations.enumerated() {
                animation.duration = cycleDuration
                animation.repeatCount = repeatCount
                animation.autoreverses = autoreverses

                // Begin after the delay, filling backwards so the first keyframe's pose holds during the delay.
                animation.beginTime = layer.convertTime(now, from: nil) + delay
                animation.fillMode = .backwards

                // The model values were set to their final state when the animation began, so the animations can be
                // removed on completion without the element visually snapping.
                animation.isRemovedOnCompletion = true

                if needsCompletionDelegate {
                    animation.delegate = proxy
                    needsCompletionDelegate = false
                }

                let key = "Stagehand.CoreAnimationInstance.\(ObjectIdentifier(self).hashValue).\(index)"
                layer.add(animation, forKey: key)
                keys.append(key)
            }

            if !keys.isEmpty {
                addedAnimationKeysByLayer.append((layer: layer, keys: keys))
            }
        }
    }

    private func removeCompiledAnimations() {
        for (layer, keys) in addedAnimationKeysByLayer {
            for key in keys {
                layer.removeAnimation(forKey: key)
            }
        }
        addedAnimationKeysByLayer = []
    }

    private func applyModelValuesDisablingActions(at relativeTimestamp: Double) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        applyModelValues(relativeTimestamp)
        CATransaction.commit()
    }

    private func handleAnimationsDidStop(finished: Bool) {
        guard case .animating = coreAnimationStatus else {
            return
        }

        if finished {
            advanceExecution(toCycle: finalCycleIndex, timestamp: finalCycleIsReversed ? 0 : 1)
            coreAnimationStatus = .complete
            cleanUp()
            completions.forEach { $0(true) }

        } else {
            // The animations were removed out from under us (e.g. the layer left the render tree), so there is
            // nothing left animating. Halt, matching the display-link driver's behavior when its element disappears.
            coreAnimationStatus = .canceled(behavior: .halt)
            cleanUp()
            completions.forEach { $0(false) }
        }
    }

    private func cleanUp() {
        scheduledTasks.forEach { $0.cancel() }
        scheduledTasks = []

        completionProxy?.didStop = nil
        completionProxy = nil
    }

    // MARK: - Private Methods - Execution Blocks

    private func scheduleExecutionEvents() {
        guard !executionEventRawTimestamps.isEmpty, cycleCount != 0 else {
            // Execution events with an infinite repeat style fall back to the display-link driver before an instance
            // is created, so there is nothing to schedule here.
            return
        }

        struct Fire {
            var wallProgress: Double
            var cycle: Int
            var timestamp: Double
        }

        var fires: [Fire] = []
        for cycle in 0..<Int(cycleCount) {
            let cycleIsReversed = isCycleReversed(cycle)

            if cycle > 0 {
                // Fire at each cycle boundary so the between-cycle rewind of execution blocks (for looping,
                // non-autoreversing animations) happens on time.
                fires.append(Fire(wallProgress: Double(cycle), cycle: cycle, timestamp: cycleIsReversed ? 1 : 0))
            }

            for eventTimestamp in executionEventRawTimestamps {
                fires.append(Fire(
                    wallProgress: Double(cycle) + (cycleIsReversed ? 1 - eventTimestamp : eventTimestamp),
                    cycle: cycle,
                    timestamp: eventTimestamp
                ))
            }
        }

        fires.sort { $0.wallProgress < $1.wallProgress }

        for fire in fires {
            let deadline = startMediaTime + delay + fire.wallProgress * cycleDuration
            scheduledTasks.append(Task { @MainActor in
                await Self.sleep(until: deadline)
                guard !Task.isCancelled else {
                    return
                }
                guard case .animating = self.coreAnimationStatus else {
                    return
                }
                self.advanceExecution(toCycle: fire.cycle, timestamp: fire.timestamp)
            })
        }
    }

    /// Executes blocks (and assignments) forward through the given position, replaying the same walk the display-link
    /// driver performs frame by frame, including the between-cycle rewind for looping animations.
    private func advanceExecution(toCycle targetCycle: Int, timestamp targetTimestamp: Double) {
        guard let executor = executor else {
            return
        }

        // Scheduled tasks can resume slightly out of order, so ignore targets that are already behind us.
        let targetWallProgress = wallProgress(cycle: targetCycle, timestamp: targetTimestamp)
        if let lastPosition = lastExecutedPosition,
            wallProgress(cycle: lastPosition.cycle, timestamp: lastPosition.timestamp) >= targetWallProgress {
            return
        }

        var currentCycle: Int
        var currentTimestamp: Double
        var fromInclusivity: Executor.Inclusivity

        if let lastPosition = lastExecutedPosition {
            (currentCycle, currentTimestamp) = lastPosition
            fromInclusivity = .exclusive
        } else {
            (currentCycle, currentTimestamp) = (0, 0)
            fromInclusivity = .inclusive
        }

        while currentCycle < targetCycle {
            let endTimestamp: Double = isCycleReversed(currentCycle) ? 0 : 1
            executor.executeBlocks(from: currentTimestamp, fromInclusivity, to: endTimestamp)

            let nextCycle = currentCycle + 1
            let nextStartTimestamp: Double = isCycleReversed(nextCycle) ? 1 : 0

            if endTimestamp != nextStartTimestamp {
                // A looping (non-autoreversing) animation rewinds its execution blocks between cycles, matching the
                // display-link driver.
                executor.executeBlocks(from: endTimestamp, .inclusive, to: nextStartTimestamp)
            }

            currentCycle = nextCycle
            currentTimestamp = nextStartTimestamp
            fromInclusivity = .inclusive
        }

        executor.executeBlocks(from: currentTimestamp, fromInclusivity, to: targetTimestamp)

        lastExecutedPosition = (cycle: targetCycle, timestamp: targetTimestamp)
    }

    /// Unwinds execution blocks from the given position back to the animation's beginning, matching the display-link
    /// driver's `.revert` cancelation behavior.
    private func unwindExecutionToBeginning(from position: (cycle: Int, timestamp: Double)) {
        guard let executor = executor else {
            return
        }

        if isCycleReversed(position.cycle) {
            executor.executeBlocks(from: position.timestamp, executionFromInclusivity, to: 0)
        } else {
            executor.executeBlocks(from: position.timestamp, executionFromInclusivity, to: 1)
            executor.executeBlocks(from: 1, .inclusive, to: 0)
        }
    }

    /// Winds execution blocks from the given position through to the animation's end, matching the display-link
    /// driver's `.complete` cancelation behavior.
    private func windExecutionToEnd(from position: (cycle: Int, timestamp: Double)) {
        guard let executor = executor else {
            return
        }

        if isCycleReversed(position.cycle) {
            executor.executeBlocks(from: position.timestamp, executionFromInclusivity, to: 0)
            executor.executeBlocks(from: 0, .inclusive, to: 1)
        } else {
            executor.executeBlocks(from: position.timestamp, executionFromInclusivity, to: 1)
        }
    }

    /// Whether a walk starting from the current position should include blocks at the position itself: once frames
    /// have executed up to a position, its blocks have already run.
    private var executionFromInclusivity: Executor.Inclusivity {
        return (lastExecutedPosition == nil) ? .inclusive : .exclusive
    }

    // MARK: - Private Methods - Timing

    private func isCycleReversed(_ cycle: Int) -> Bool {
        return autoreversing && cycle % 2 != 0
    }

    private func wallProgress(cycle: Int, timestamp: Double) -> Double {
        return Double(cycle) + (isCycleReversed(cycle) ? 1 - timestamp : timestamp)
    }

    /// The animation's current position, as derived from the time elapsed since the animation began.
    ///
    /// The render server executes the compiled animations against the same clock, so this matches what is being
    /// displayed (to within a frame) whenever the render server is keeping up — which is the point of this execution
    /// mode.
    private func currentWallClockPosition() -> (cycle: Int, timestamp: Double) {
        guard cycleDuration > 0 else {
            return (cycle: finalCycleIndex, timestamp: finalCycleIsReversed ? 0 : 1)
        }

        let elapsed = CACurrentMediaTime() - startMediaTime - delay
        var overallProgress = max(elapsed / cycleDuration, 0)

        if cycleCount != 0 {
            overallProgress = min(overallProgress, Double(cycleCount))
        }

        var cycle = Int(overallProgress)
        if cycleCount != 0 {
            cycle = min(cycle, Int(cycleCount) - 1)
        }

        let progressInCycle = overallProgress - Double(cycle)
        let timestamp = isCycleReversed(cycle) ? 1 - progressInCycle : progressInCycle

        return (cycle: cycle, timestamp: timestamp)
    }

    // MARK: - Private Static Methods

    private static func sleep(until mediaTime: CFTimeInterval) async {
        let remaining = mediaTime - CACurrentMediaTime()
        guard remaining > 0 else {
            return
        }

        try? await Task.sleep(nanoseconds: UInt64(remaining * TimeInterval(NSEC_PER_SEC)))
    }

}

// MARK: -

internal struct CompiledCoreAnimationElement {

    /// The layer to which the compiled animations should be added.
    var layer: CALayer

    /// The compiled animations, with `keyPath`, `values`, `keyTimes`, and `calculationMode` configured. Timing
    /// properties (duration, delay, repeat) are configured by the `CoreAnimationInstance` when it starts.
    var animations: [CAKeyframeAnimation]

}

// MARK: -

internal enum CoreAnimationFallbackAssertions {

    /// Invoked whenever a `performUsingCoreAnimation(...)` call falls back to the display-link driver because the
    /// animation can't be represented on the render server. Raises a debug assertion by default (release builds
    /// degrade gracefully to the fallback); tests can override this to intercept the assertion.
    @MainActor
    internal static var assertionHandler: @MainActor (String) -> Void = { message in
        assertionFailure(message)
    }

}

// MARK: -

/// Safety: the only mutable state (`didStop`) is main-actor-isolated, and the `CAAnimationDelegate` callback is
/// bridged onto the main actor before touching it.
private final class CoreAnimationCompletionProxy: NSObject, CAAnimationDelegate, @unchecked Sendable {

    // MARK: - Internal Properties

    @MainActor
    var didStop: ((_ finished: Bool) -> Void)?

    // MARK: - CAAnimationDelegate

    nonisolated func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        // CAAnimation delegates are messaged on the thread whose run loop the animation was scheduled on, which is
        // always the main thread here since the perform methods are main-actor-isolated.
        MainActor.assumeIsolated {
            didStop?(flag)
        }
    }

}
