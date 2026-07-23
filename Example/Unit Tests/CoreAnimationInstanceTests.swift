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

import XCTest

@testable import Stagehand

@MainActor
final class CoreAnimationInstanceTests: XCTestCase {

    // MARK: - Tests - Compilation

    func testCompiledValuesMatchDisplayLinkRendererWithLinearCurve() {
        var animation = Animation<UIView>()
        animation.curve = LinearAnimationCurve()
        animation.addKeyframe(for: \.alpha, at: 0, value: 0.25)
        animation.addKeyframe(for: \.alpha, at: 0.4, value: 1)
        animation.addKeyframe(for: \.alpha, at: 1, value: 0.5)

        let element = UIView()

        let instance = animation.performUsingCoreAnimation(on: element, duration: 1)
        XCTAssertEqual(instance.executionMode, .coreAnimation)

        guard let keyframeAnimation = compiledKeyframeAnimation(on: element.layer, keyPath: "opacity") else {
            XCTFail("Expected a compiled opacity animation on the element's layer")
            return
        }

        guard let keyTimes = keyframeAnimation.keyTimes, let values = keyframeAnimation.values as? [NSNumber] else {
            XCTFail("Expected the compiled animation to have key times and numeric values")
            return
        }

        XCTAssertEqual(keyTimes.count, 120)
        XCTAssertEqual(values.count, keyTimes.count)
        XCTAssertEqual(keyframeAnimation.calculationMode, .linear)

        // The key times should be dense and evenly spaced.
        for (index, keyTime) in keyTimes.enumerated() {
            XCTAssertEqual(keyTime.doubleValue, Double(index) / Double(keyTimes.count - 1), accuracy: 1e-9)
        }

        // The model values should already reflect the end of the animation.
        XCTAssertEqual(element.alpha, 0.5, accuracy: 1e-6)

        // Each sampled value should match what the display-link renderer produces at the same progress.
        let referenceElement = UIView()
        let driver = TestDriver()
        let referenceInstance = AnimationInstance(animation: animation, element: referenceElement, driver: driver)

        for (index, keyTime) in keyTimes.enumerated() {
            driver.runForward(to: keyTime.doubleValue)
            XCTAssertEqual(values[index].doubleValue, Double(referenceElement.alpha), accuracy: 1e-6)
        }

        _ = referenceInstance

        instance.cancel()
    }

    func testCompiledValuesMatchDisplayLinkRendererWithCubicBezierCurve() {
        var animation = Animation<UIView>()
        animation.curve = CubicBezierAnimationCurve.easeInEaseOut
        animation.addKeyframe(for: \.transform, at: 0, value: .identity)
        animation.addKeyframe(for: \.transform, at: 1, value: CGAffineTransform(translationX: 120, y: -40).rotated(by: 1.2))

        let element = UIView()

        let instance = animation.performUsingCoreAnimation(on: element, duration: 1)
        XCTAssertEqual(instance.executionMode, .coreAnimation)

        guard let keyframeAnimation = compiledKeyframeAnimation(on: element.layer, keyPath: "transform") else {
            XCTFail("Expected a compiled transform animation on the element's layer")
            return
        }

        guard let keyTimes = keyframeAnimation.keyTimes, let values = keyframeAnimation.values as? [NSValue] else {
            XCTFail("Expected the compiled animation to have key times and transform values")
            return
        }

        XCTAssertEqual(values.count, keyTimes.count)

        let referenceElement = UIView()
        let driver = TestDriver()
        let referenceInstance = AnimationInstance(animation: animation, element: referenceElement, driver: driver)

        for (index, keyTime) in keyTimes.enumerated() {
            driver.runForward(to: keyTime.doubleValue)

            let expectedTransform = CATransform3DMakeAffineTransform(referenceElement.transform)
            assertTransformsEqual(values[index].caTransform3DValue, expectedTransform, accuracy: 1e-6)
        }

        _ = referenceInstance

        instance.cancel()
    }

    func testSampleCountScalesWithDurationAndIsCapped() {
        var animation = Animation<UIView>()
        animation.addKeyframe(for: \.alpha, at: 0, value: 0)
        animation.addKeyframe(for: \.alpha, at: 1, value: 1)

        let shortElement = UIView()
        let shortInstance = animation.performUsingCoreAnimation(on: shortElement, duration: 0.01)
        // Sampling requires at least the two boundary values.
        XCTAssertEqual(compiledKeyframeAnimation(on: shortElement.layer, keyPath: "opacity")?.keyTimes?.count, 2)
        shortInstance.cancel()

        let longElement = UIView()
        let longInstance = animation.performUsingCoreAnimation(on: longElement, duration: 10)
        // Long animations are capped rather than sampled at 120 samples per second forever.
        XCTAssertEqual(compiledKeyframeAnimation(on: longElement.layer, keyPath: "opacity")?.keyTimes?.count, 240)
        longInstance.cancel()
    }

    func testSubclassRootedKeyPathsCompile() {
        // Key paths rooted at a subclass (`\UILabel.alpha`) are distinct from base-class-rooted key paths
        // (`\UIView.alpha`), so this exercises the per-element-type mapping registry.
        var animation = Animation<UILabel>()
        animation.addKeyframe(for: \.alpha, at: 0, value: 0)
        animation.addKeyframe(for: \.alpha, at: 1, value: 1)

        let element = UILabel()

        let instance = animation.performUsingCoreAnimation(on: element, duration: 1)
        XCTAssertEqual(instance.executionMode, .coreAnimation)
        XCTAssertNotNil(compiledKeyframeAnimation(on: element.layer, keyPath: "opacity"))

        instance.cancel()
    }

    func testLayerElementCompiles() {
        var animation = Animation<CALayer>()
        animation.addKeyframe(for: \.cornerRadius, at: 0, value: 0)
        animation.addKeyframe(for: \.cornerRadius, at: 1, value: 8)

        let element = CALayer()

        let instance = animation.performUsingCoreAnimation(on: element, duration: 1)
        XCTAssertEqual(instance.executionMode, .coreAnimation)
        XCTAssertNotNil(compiledKeyframeAnimation(on: element, keyPath: "cornerRadius"))
        XCTAssertEqual(element.cornerRadius, 8, accuracy: 1e-6)

        instance.cancel(behavior: .complete)
    }

    // MARK: - Tests - Fallback

    func testUnmappedPropertyFallsBackToDisplayLink() {
        var animation = Animation<ElementWithUnmappedProperty>()
        animation.addKeyframe(for: \.customProperty, at: 0, value: 1)
        animation.addKeyframe(for: \.customProperty, at: 1, value: 2)

        let element = ElementWithUnmappedProperty()

        let (instance, assertionMessages) = performCapturingFallbackAssertions {
            animation.performUsingCoreAnimation(on: element, duration: 1)
        }

        XCTAssertEqual(instance.executionMode, .displayLinkFallback)
        XCTAssertEqual(assertionMessages.count, 1)

        // No animations should have been committed to the layer.
        XCTAssertNil(element.layer.animationKeys())

        // The fallback instance should actually be driving the element.
        instance.cancel(behavior: .complete)
        XCTAssertEqual(element.customProperty, 2)
    }

    func testPerFrameExecutionBlockFallsBackToDisplayLink() {
        var animation = Animation<UIView>()
        animation.addKeyframe(for: \.alpha, at: 0, value: 0)
        animation.addKeyframe(for: \.alpha, at: 1, value: 1)
        animation.addPerFrameExecution { _ in }

        let (instance, assertionMessages) = performCapturingFallbackAssertions {
            animation.performUsingCoreAnimation(on: UIView(), duration: 1)
        }

        XCTAssertEqual(instance.executionMode, .displayLinkFallback)
        XCTAssertEqual(assertionMessages.count, 1)

        instance.cancel()
    }

    func testInfinitelyRepeatingAnimationWithExecutionBlocksFallsBackToDisplayLink() {
        var animation = Animation<UIView>()
        animation.addKeyframe(for: \.alpha, at: 0, value: 0)
        animation.addKeyframe(for: \.alpha, at: 1, value: 1)
        animation.addExecution(onForward: { _ in }, at: 0.5)

        let (instance, assertionMessages) = performCapturingFallbackAssertions {
            animation.performUsingCoreAnimation(
                on: UIView(),
                duration: 1,
                repeatStyle: .infinitelyRepeating(autoreversing: false)
            )
        }

        XCTAssertEqual(instance.executionMode, .displayLinkFallback)
        XCTAssertEqual(assertionMessages.count, 1)

        instance.cancel()
    }

    func testInfinitelyRepeatingAnimationWithoutExecutionBlocksCompiles() {
        var animation = Animation<UIView>()
        animation.addKeyframe(for: \.alpha, at: 0, value: 0)
        animation.addKeyframe(for: \.alpha, at: 1, value: 1)

        let element = UIView()

        let instance = animation.performUsingCoreAnimation(
            on: element,
            duration: 1,
            repeatStyle: .infinitelyRepeating(autoreversing: true)
        )

        XCTAssertEqual(instance.executionMode, .coreAnimation)

        let keyframeAnimation = compiledKeyframeAnimation(on: element.layer, keyPath: "opacity")
        XCTAssertEqual(keyframeAnimation?.repeatCount, .infinity)
        XCTAssertEqual(keyframeAnimation?.autoreverses, true)

        instance.cancel()
    }

    // MARK: - Tests - Cancelation

    func testCancelRevertRestoresInitialModelValues() {
        var animation = Animation<UIView>()
        animation.addKeyframe(for: \.alpha, at: 0, value: 0.25)
        animation.addKeyframe(for: \.alpha, at: 1, value: 0.75)

        let element = UIView()

        var completionResult: Bool?
        let instance = animation.performUsingCoreAnimation(on: element, duration: 10) { finished in
            completionResult = finished
        }

        XCTAssertEqual(element.alpha, 0.75, accuracy: 1e-6)

        instance.cancel(behavior: .revert)

        XCTAssertEqual(element.alpha, 0.25, accuracy: 1e-6)
        XCTAssertEqual(completionResult, false)
        XCTAssertNil(element.layer.animationKeys())

        if case .canceled(behavior: .revert) = instance.status {
            // Expected.
        } else {
            XCTFail("Expected the instance to be canceled as reverted")
        }
    }

    func testCancelHaltFreezesModelValuesAtCurrentProgress() {
        var animation = Animation<UIView>()
        animation.addKeyframe(for: \.alpha, at: 0, value: 0.25)
        animation.addKeyframe(for: \.alpha, at: 1, value: 0.75)

        let element = UIView()

        let instance = animation.performUsingCoreAnimation(on: element, duration: 60)

        instance.cancel(behavior: .halt)

        // Effectively no time has elapsed relative to the animation's duration, so the animation should freeze at
        // (approximately) its starting values, rather than staying at the final model values applied when it began.
        XCTAssertEqual(element.alpha, 0.25, accuracy: 0.05)
        XCTAssertNil(element.layer.animationKeys())
    }

    func testCancelCompleteAppliesFinalModelValuesAndExecutesRemainingBlocks() {
        var forwardExecutionCount = 0

        var animation = Animation<UIView>()
        animation.addKeyframe(for: \.alpha, at: 0, value: 0.25)
        animation.addKeyframe(for: \.alpha, at: 1, value: 0.75)
        animation.addExecution(onForward: { _ in forwardExecutionCount += 1 }, at: 0.9)

        let element = UIView()

        var completionResult: Bool?
        let instance = animation.performUsingCoreAnimation(on: element, duration: 10) { finished in
            completionResult = finished
        }

        instance.cancel(behavior: .complete)

        XCTAssertEqual(element.alpha, 0.75, accuracy: 1e-6)
        XCTAssertEqual(forwardExecutionCount, 1)
        XCTAssertEqual(completionResult, false)
        XCTAssertNil(element.layer.animationKeys())

        // Canceling again should be a no-op.
        instance.cancel(behavior: .revert)
        XCTAssertEqual(element.alpha, 0.75, accuracy: 1e-6)
    }

    // MARK: - Tests - Completion and Execution Blocks

    func testCompletionIsCalledWithFinishedTrue() {
        var animation = Animation<UIView>()
        animation.addKeyframe(for: \.alpha, at: 0, value: 0)
        animation.addKeyframe(for: \.alpha, at: 1, value: 1)

        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        window.isHidden = false

        let element = UIView(frame: window.bounds)
        window.addSubview(element)

        let completionExpectation = expectation(description: "Animation should complete")

        let instance = animation.performUsingCoreAnimation(on: element, duration: 0.1) { finished in
            XCTAssertTrue(finished)
            completionExpectation.fulfill()
        }

        XCTAssertEqual(instance.executionMode, .coreAnimation)

        waitForExpectations(timeout: 5)

        if case .complete = instance.status {
            // Expected.
        } else {
            XCTFail("Expected the instance to be complete")
        }
    }

    func testExecutionBlocksAreScheduled() {
        let executionExpectation = expectation(description: "Execution block should be executed")

        var animation = Animation<UIView>()
        animation.addKeyframe(for: \.alpha, at: 0, value: 0)
        animation.addKeyframe(for: \.alpha, at: 1, value: 1)
        animation.addExecution(
            onForward: { _ in executionExpectation.fulfill() },
            at: 0.5
        )

        // Core Animation stops animations on layers outside of a render tree, so host the element in a window.
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        window.isHidden = false

        let element = UIView(frame: window.bounds)
        window.addSubview(element)

        let instance = animation.performUsingCoreAnimation(on: element, duration: 0.2)
        XCTAssertEqual(instance.executionMode, .coreAnimation)

        waitForExpectations(timeout: 5)

        instance.cancel()
    }

    func testZeroDurationAnimationAppliesFinalValuesImmediately() {
        var animation = Animation<UIView>()
        animation.addKeyframe(for: \.alpha, at: 0, value: 0)
        animation.addKeyframe(for: \.alpha, at: 1, value: 1)

        let element = UIView()
        element.alpha = 0

        let completionExpectation = expectation(description: "Animation should complete")

        animation.performUsingCoreAnimation(on: element, duration: 0) { finished in
            XCTAssertTrue(finished)
            completionExpectation.fulfill()
        }

        XCTAssertEqual(element.alpha, 1, accuracy: 1e-6)

        waitForExpectations(timeout: 5)
    }

    // MARK: - Tests - Animation Groups

    func testAnimationGroupCompilesPerElement() {
        var firstAnimation = Animation<UIView>()
        firstAnimation.addKeyframe(for: \.alpha, at: 0, value: 0)
        firstAnimation.addKeyframe(for: \.alpha, at: 1, value: 1)

        var secondAnimation = Animation<UIView>()
        secondAnimation.addKeyframe(for: \.alpha, at: 0, value: 0.5)
        secondAnimation.addKeyframe(for: \.alpha, at: 1, value: 1)

        let firstElement = UIView()
        let secondElement = UIView()

        var animationGroup = AnimationGroup()
        animationGroup.addAnimation(firstAnimation, for: firstElement, startingAt: 0, relativeDuration: 1)
        animationGroup.addAnimation(secondAnimation, for: secondElement, startingAt: 0.5, relativeDuration: 0.5)

        let instance = animationGroup.performUsingCoreAnimation(duration: 1)
        XCTAssertEqual(instance.executionMode, .coreAnimation)

        guard
            let firstKeyframeAnimation = compiledKeyframeAnimation(on: firstElement.layer, keyPath: "opacity"),
            let secondKeyframeAnimation = compiledKeyframeAnimation(on: secondElement.layer, keyPath: "opacity")
        else {
            XCTFail("Expected compiled opacity animations on both elements' layers")
            return
        }

        // Both animations run on the group's timeline.
        XCTAssertEqual(firstKeyframeAnimation.keyTimes?.count, 120)
        XCTAssertEqual(secondKeyframeAnimation.keyTimes?.count, 120)

        guard let secondValues = secondKeyframeAnimation.values as? [NSNumber] else {
            XCTFail("Expected the second compiled animation to have numeric values")
            return
        }

        // The second element's animation doesn't start until halfway through the group, so its values should hold its
        // starting value for the first half of the timeline.
        XCTAssertEqual(secondValues.first?.doubleValue ?? -1, 0.5, accuracy: 1e-6)
        XCTAssertEqual(secondValues[59].doubleValue, 0.5, accuracy: 1e-6)
        XCTAssertEqual(secondValues.last?.doubleValue ?? -1, 1, accuracy: 1e-6)

        // The model values of both elements should reflect the end of the group.
        XCTAssertEqual(firstElement.alpha, 1, accuracy: 1e-6)
        XCTAssertEqual(secondElement.alpha, 1, accuracy: 1e-6)

        instance.cancel()
    }

    func testAnimationGroupCancelRevertRestoresInitialModelValues() {
        var animation = Animation<UIView>()
        animation.addKeyframe(for: \.alpha, at: 0, value: 0.25)
        animation.addKeyframe(for: \.alpha, at: 1, value: 0.75)

        let element = UIView()

        var animationGroup = AnimationGroup()
        animationGroup.addAnimation(animation, for: element, startingAt: 0, relativeDuration: 1)

        var completionResult: Bool?
        animationGroup.addCompletionHandler { finished in
            completionResult = finished
        }

        let instance = animationGroup.performUsingCoreAnimation(duration: 10)
        XCTAssertEqual(instance.executionMode, .coreAnimation)
        XCTAssertEqual(element.alpha, 0.75, accuracy: 1e-6)

        instance.cancel(behavior: .revert)

        XCTAssertEqual(element.alpha, 0.25, accuracy: 1e-6)
        XCTAssertEqual(completionResult, false)
        XCTAssertNil(element.layer.animationKeys())
    }

    func testAnimationGroupWithUnmappedPropertyFallsBackToDisplayLink() {
        var animation = Animation<ElementWithUnmappedProperty>()
        animation.addKeyframe(for: \.customProperty, at: 0, value: 1)
        animation.addKeyframe(for: \.customProperty, at: 1, value: 2)

        let element = ElementWithUnmappedProperty()

        var animationGroup = AnimationGroup()
        animationGroup.addAnimation(animation, for: element, startingAt: 0, relativeDuration: 1)

        let (instance, assertionMessages) = performCapturingFallbackAssertions {
            animationGroup.performUsingCoreAnimation(duration: 1)
        }

        XCTAssertEqual(instance.executionMode, .displayLinkFallback)
        XCTAssertEqual(assertionMessages.count, 1)

        instance.cancel(behavior: .complete)
        XCTAssertEqual(element.customProperty, 2)
    }

    // MARK: - Private Methods

    private func compiledKeyframeAnimation(on layer: CALayer, keyPath: String) -> CAKeyframeAnimation? {
        return (layer.animationKeys() ?? [])
            .compactMap { layer.animation(forKey: $0) as? CAKeyframeAnimation }
            .first { $0.keyPath == keyPath }
    }

    private func performCapturingFallbackAssertions<ResultType>(
        _ body: () -> ResultType
    ) -> (ResultType, assertionMessages: [String]) {
        let originalHandler = CoreAnimationFallbackAssertions.assertionHandler

        var assertionMessages: [String] = []
        CoreAnimationFallbackAssertions.assertionHandler = { message in
            assertionMessages.append(message)
        }

        defer {
            CoreAnimationFallbackAssertions.assertionHandler = originalHandler
        }

        return (body(), assertionMessages)
    }

    private func assertTransformsEqual(
        _ actual: CATransform3D,
        _ expected: CATransform3D,
        accuracy: Double,
        line: UInt = #line
    ) {
        XCTAssertEqual(Double(actual.m11), Double(expected.m11), accuracy: accuracy, line: line)
        XCTAssertEqual(Double(actual.m12), Double(expected.m12), accuracy: accuracy, line: line)
        XCTAssertEqual(Double(actual.m13), Double(expected.m13), accuracy: accuracy, line: line)
        XCTAssertEqual(Double(actual.m14), Double(expected.m14), accuracy: accuracy, line: line)
        XCTAssertEqual(Double(actual.m21), Double(expected.m21), accuracy: accuracy, line: line)
        XCTAssertEqual(Double(actual.m22), Double(expected.m22), accuracy: accuracy, line: line)
        XCTAssertEqual(Double(actual.m23), Double(expected.m23), accuracy: accuracy, line: line)
        XCTAssertEqual(Double(actual.m24), Double(expected.m24), accuracy: accuracy, line: line)
        XCTAssertEqual(Double(actual.m31), Double(expected.m31), accuracy: accuracy, line: line)
        XCTAssertEqual(Double(actual.m32), Double(expected.m32), accuracy: accuracy, line: line)
        XCTAssertEqual(Double(actual.m33), Double(expected.m33), accuracy: accuracy, line: line)
        XCTAssertEqual(Double(actual.m34), Double(expected.m34), accuracy: accuracy, line: line)
        XCTAssertEqual(Double(actual.m41), Double(expected.m41), accuracy: accuracy, line: line)
        XCTAssertEqual(Double(actual.m42), Double(expected.m42), accuracy: accuracy, line: line)
        XCTAssertEqual(Double(actual.m43), Double(expected.m43), accuracy: accuracy, line: line)
        XCTAssertEqual(Double(actual.m44), Double(expected.m44), accuracy: accuracy, line: line)
    }

}

// MARK: -

private final class ElementWithUnmappedProperty: UIView {

    var customProperty: CGFloat = 0

}
