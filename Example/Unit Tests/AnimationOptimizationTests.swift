//
//  Copyright 2019 Square Inc.
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

final class AnimationOptimizationTests: XCTestCase {

    // MARK: - Tests - Ubiquitous Bezier Curve

    func testUbiquitousBezierCurveElevation_singleChild() {
        var parentAnimation = Animation<UIView>()

        var childAnimation = Animation<UIView>()
        childAnimation.addKeyframe(for: \.alpha, at: 0, value: 0)
        childAnimation.curve = CubicBezierAnimationCurve.easeInEaseOut
        parentAnimation.addChild(childAnimation, for: \.self, startingAt: 0, relativeDuration: 1)

        let optimizedAnimation = parentAnimation.optimized(initialValues: [\UIView.alpha: 0])

        XCTAssertEqual(optimizedAnimation.curve as? CubicBezierAnimationCurve, CubicBezierAnimationCurve.easeInEaseOut)
        XCTAssert(optimizedAnimation.children.allSatisfy { $0.animation.curve is LinearAnimationCurve })
    }

    func testUbiquitousBezierCurveElevation_multipleChildren() {
        var parentAnimation = Animation<UIView>()

        var firstChildAnimation = Animation<UIView>()
        firstChildAnimation.addKeyframe(for: \.alpha, at: 0, value: 0)
        firstChildAnimation.curve = CubicBezierAnimationCurve.easeInEaseOut
        parentAnimation.addChild(firstChildAnimation, for: \.self, startingAt: 0, relativeDuration: 1)

        var secondChildAnimation = Animation<UIView>()
        secondChildAnimation.addKeyframe(for: \.alpha, at: 0, value: 0)
        secondChildAnimation.curve = CubicBezierAnimationCurve.easeInEaseOut
        parentAnimation.addChild(secondChildAnimation, for: \.self, startingAt: 0, relativeDuration: 1)

        let optimizedAnimation = parentAnimation.optimized(initialValues: [\UIView.alpha: 0])

        XCTAssertEqual(optimizedAnimation.curve as? CubicBezierAnimationCurve, CubicBezierAnimationCurve.easeInEaseOut)
        XCTAssert(optimizedAnimation.children.allSatisfy { $0.animation.curve is LinearAnimationCurve })
    }

    func testUbiquitousBezierCurveElevation_grandchild() {
        var parentAnimation = Animation<UIView>()

        var grandchildAnimation = Animation<UIView>()
        grandchildAnimation.addKeyframe(for: \.alpha, at: 0, value: 0)
        grandchildAnimation.curve = CubicBezierAnimationCurve.easeInEaseOut

        var childAnimation = Animation<UIView>()
        childAnimation.addChild(grandchildAnimation, for: \.self, startingAt: 0, relativeDuration: 1)
        parentAnimation.addChild(childAnimation, for: \.self, startingAt: 0, relativeDuration: 1)

        let optimizedAnimation = parentAnimation.optimized(initialValues: [\UIView.alpha: 0])

        XCTAssertEqual(optimizedAnimation.curve as? CubicBezierAnimationCurve, CubicBezierAnimationCurve.easeInEaseOut)
        XCTAssert(optimizedAnimation.children.allSatisfy {
            $0.animation.curve is LinearAnimationCurve
            && $0.animation.children.allSatisfy { $0.animation.curve is LinearAnimationCurve }
        })
    }

    func testUbiquitousBezierCurveElevation_notElevatedWhenParentHasContent() {
        var parentAnimation = Animation<UIView>()
        parentAnimation.addKeyframe(for: \.alpha, at: 0, value: 1)

        var childAnimation = Animation<UIView>()
        childAnimation.addKeyframe(for: \.alpha, at: 0, value: 0)
        childAnimation.curve = CubicBezierAnimationCurve.easeInEaseOut
        parentAnimation.addChild(childAnimation, for: \.self, startingAt: 0, relativeDuration: 1)

        let optimizedAnimation = parentAnimation.optimized(initialValues: [\UIView.alpha: 0])

        XCTAssert(optimizedAnimation.curve is LinearAnimationCurve)
        XCTAssert(optimizedAnimation.children.allSatisfy {
            $0.animation.curve as? CubicBezierAnimationCurve == CubicBezierAnimationCurve.easeInEaseOut
        })
    }

    func testUbiquitousBezierCurveElevation_notElevatedWhenParentCurveIsNotLinear() {
        var parentAnimation = Animation<UIView>()
        parentAnimation.curve = ParabolicEaseInAnimationCurve()

        var childAnimation = Animation<UIView>()
        childAnimation.addKeyframe(for: \.alpha, at: 0, value: 0)
        childAnimation.curve = CubicBezierAnimationCurve.easeInEaseOut
        parentAnimation.addChild(childAnimation, for: \.self, startingAt: 0, relativeDuration: 1)

        let optimizedAnimation = parentAnimation.optimized(initialValues: [\UIView.alpha: 0])

        XCTAssert(optimizedAnimation.curve is ParabolicEaseInAnimationCurve)
        XCTAssert(optimizedAnimation.children.allSatisfy {
            $0.animation.curve as? CubicBezierAnimationCurve == CubicBezierAnimationCurve.easeInEaseOut
        })
    }

    func testUbiquitousBezierCurveElevation_notElevatedWhenAChildDoesNotCoverFullInterval() {
        var parentAnimation = Animation<UIView>()

        var firstChildAnimation = Animation<UIView>()
        firstChildAnimation.addKeyframe(for: \.alpha, at: 0, value: 0)
        firstChildAnimation.curve = CubicBezierAnimationCurve.easeInEaseOut
        parentAnimation.addChild(firstChildAnimation, for: \.self, startingAt: 0, relativeDuration: 1)

        var secondChildAnimation = Animation<UIView>()
        secondChildAnimation.addKeyframe(for: \.alpha, at: 0, value: 0)
        secondChildAnimation.curve = CubicBezierAnimationCurve.easeInEaseOut
        parentAnimation.addChild(secondChildAnimation, for: \.self, startingAt: 0.5, relativeDuration: 0.5)

        let optimizedAnimation = parentAnimation.optimized(initialValues: [\UIView.alpha: 0])

        XCTAssert(optimizedAnimation.curve is LinearAnimationCurve)
        XCTAssert(optimizedAnimation.children.allSatisfy {
            $0.animation.curve as? CubicBezierAnimationCurve == CubicBezierAnimationCurve.easeInEaseOut
        })
    }

    func testUbiquitousBezierCurveElevation_notElevatedWhenNotAllChildrenHaveSameCurve() {
        var parentAnimation = Animation<UIView>()

        var firstChildAnimation = Animation<UIView>()
        firstChildAnimation.addKeyframe(for: \.alpha, at: 0, value: 0)
        firstChildAnimation.curve = CubicBezierAnimationCurve.easeIn
        parentAnimation.addChild(firstChildAnimation, for: \.self, startingAt: 0, relativeDuration: 1)

        var secondChildAnimation = Animation<UIView>()
        secondChildAnimation.addKeyframe(for: \.alpha, at: 0, value: 0)
        secondChildAnimation.curve = CubicBezierAnimationCurve.easeOut
        parentAnimation.addChild(secondChildAnimation, for: \.self, startingAt: 0, relativeDuration: 1)

        let optimizedAnimation = parentAnimation.optimized(initialValues: [\UIView.alpha: 0])

        XCTAssert(optimizedAnimation.curve is LinearAnimationCurve)
        XCTAssert(optimizedAnimation.children[0].animation.curve as? CubicBezierAnimationCurve == .easeIn)
        XCTAssert(optimizedAnimation.children[1].animation.curve as? CubicBezierAnimationCurve == .easeOut)
    }

    // MARK: - Tests - Remove Obsolete Keyframes

    func testObsoleteKeyframeRemoval_selfProperty() {
        var parentAnimation = Animation<UIView>()
        parentAnimation.addKeyframe(for: \.alpha, at: 0, value: 1)

        var childAnimation = Animation<UIView>()
        childAnimation.addKeyframe(for: \.alpha, at: 0.5, value: 0.5)
        childAnimation.addKeyframe(for: \.transform, at: 0, value: .identity)
        parentAnimation.addChild(childAnimation, for: \.self, startingAt: 0, relativeDuration: 1)

        let optimizedAnimation = parentAnimation.optimized(
            initialValues: [
                \UIView.alpha: 0,
                \UIView.transform: CGAffineTransform.identity,
            ]
        )

        XCTAssertEqual(Array(optimizedAnimation.keyframeSeriesByProperty.keys), [\UIView.alpha])
        XCTAssertEqual(Array(optimizedAnimation.children[0].animation.keyframeSeriesByProperty.keys), [\UIView.transform])
    }

    func testObsoleteKeyframeRemoval_subelementProperty() {
        var parentAnimation = Animation<Element>()
        parentAnimation.addKeyframe(for: \.subelement.propertyOne, at: 0, value: 1)

        var childAnimation = Animation<Subelement>()
        childAnimation.addKeyframe(for: \.propertyOne, at: 0.5, value: 0.5)
        childAnimation.addKeyframe(for: \.propertyTwo, at: 0.5, value: 0.5)
        parentAnimation.addChild(childAnimation, for: \.subelement, startingAt: 0, relativeDuration: 1)

        let optimizedAnimation = parentAnimation.optimized(initialValues: Factory.initialElementValues)

        XCTAssertEqual(Array(optimizedAnimation.keyframeSeriesByProperty.keys), [\Element.subelement.propertyOne])
        XCTAssertEqual(Array(optimizedAnimation.children[0].animation.keyframeSeriesByProperty.keys), [\Element.subelement.propertyTwo])
    }

    func testObsoleteKeyframeRemoval_removesEmptyChildAfterRemovingKeyframes() {
        var parentAnimation = Animation<Element>()
        parentAnimation.addKeyframe(for: \.subelement.propertyOne, at: 0, value: 1)

        var childAnimation = Animation<Subelement>()
        childAnimation.addKeyframe(for: \.propertyOne, at: 0.5, value: 0.5)
        parentAnimation.addChild(childAnimation, for: \.subelement, startingAt: 0, relativeDuration: 1)

        let optimizedAnimation = parentAnimation.optimized(initialValues: Factory.initialElementValues)

        XCTAssertEqual(Array(optimizedAnimation.keyframeSeriesByProperty.keys), [\Element.subelement.propertyOne])
        XCTAssert(optimizedAnimation.children.isEmpty)
    }

    // MARK: - Tests - Synthesize Nil Colors

    func testSynthesizeNilCGColors_nilFirstColor() {
        let finalColor = UIColor.red.cgColor

        var animation = Animation<Element>()
        animation.addKeyframe(for: \.optionalCGColorProperty, at: 0, value: nil)
        animation.addKeyframe(for: \.optionalCGColorProperty, at: 1, value: finalColor)

        let optimizedAnimation = animation.optimized(initialValues: Factory.initialElementValues)

        guard let keyframeSeries = optimizedAnimation.keyframeSeriesByProperty[\Element.optionalCGColorProperty] as? Animation<Element>.KeyframeSeries<CGColor?> else {
            XCTFail("Missing keyframe series")
            return
        }

        XCTAssertEqual(keyframeSeries.valuesByRelativeTimestamp.count, 2)
        XCTAssertEqual(keyframeSeries.keyframeRelativeTimestamps, [0, 1])
        XCTAssertEqual(keyframeSeries.valuesByRelativeTimestamp[0]?(nil), finalColor.copy(alpha: 0))
        XCTAssertEqual(keyframeSeries.valuesByRelativeTimestamp[1]?(nil), finalColor)
    }

    func testSynthesizeNilCGColors_nilLastColor() {
        let initialColor = UIColor.red.cgColor

        var animation = Animation<Element>()
        animation.addKeyframe(for: \.optionalCGColorProperty, at: 0, value: initialColor)
        animation.addKeyframe(for: \.optionalCGColorProperty, at: 1, value: nil)

        let optimizedAnimation = animation.optimized(initialValues: Factory.initialElementValues)

        guard let keyframeSeries = optimizedAnimation.keyframeSeriesByProperty[\Element.optionalCGColorProperty] as? Animation<Element>.KeyframeSeries<CGColor?> else {
            XCTFail("Missing keyframe series")
            return
        }

        XCTAssertEqual(keyframeSeries.valuesByRelativeTimestamp.count, 2)
        XCTAssertEqual(keyframeSeries.keyframeRelativeTimestamps, [0, 1])
        XCTAssertEqual(keyframeSeries.valuesByRelativeTimestamp[0]?(nil), initialColor)
        XCTAssertEqual(keyframeSeries.valuesByRelativeTimestamp[1]?(nil), initialColor.copy(alpha: 0))
    }

    func testSynthesizeNilCGColors_nilFirstAndLastColor() {
        var animation = Animation<Element>()
        animation.addKeyframe(for: \.optionalCGColorProperty, at: 0, value: nil)
        animation.addKeyframe(for: \.optionalCGColorProperty, at: 1, value: nil)

        let optimizedAnimation = animation.optimized(initialValues: Factory.initialElementValues)

        guard let keyframeSeries = optimizedAnimation.keyframeSeriesByProperty[\Element.optionalCGColorProperty] as? Animation<Element>.KeyframeSeries<CGColor?> else {
            XCTFail("Missing keyframe series")
            return
        }

        XCTAssertEqual(keyframeSeries.valuesByRelativeTimestamp.count, 2)
        XCTAssertEqual(keyframeSeries.keyframeRelativeTimestamps, [0, 1])
        XCTAssertEqual(keyframeSeries.valuesByRelativeTimestamp[0]?(nil), nil)
        XCTAssertEqual(keyframeSeries.valuesByRelativeTimestamp[1]?(nil), nil)
    }

    func testSynthesizeNilUIColors_nilFirstColor() {
        let finalColor = UIColor.red

        var animation = Animation<Element>()
        animation.addKeyframe(for: \.optionalUIColorProperty, at: 0, value: nil)
        animation.addKeyframe(for: \.optionalUIColorProperty, at: 1, value: finalColor)

        let optimizedAnimation = animation.optimized(initialValues: Factory.initialElementValues)

        guard let keyframeSeries = optimizedAnimation.keyframeSeriesByProperty[\Element.optionalUIColorProperty] as? Animation<Element>.KeyframeSeries<UIColor?> else {
            XCTFail("Missing keyframe series")
            return
        }

        XCTAssertEqual(keyframeSeries.valuesByRelativeTimestamp.count, 2)
        XCTAssertEqual(keyframeSeries.keyframeRelativeTimestamps, [0, 1])
        XCTAssertEqual(keyframeSeries.valuesByRelativeTimestamp[0]?(nil), finalColor.withAlphaComponent(0))
        XCTAssertEqual(keyframeSeries.valuesByRelativeTimestamp[1]?(nil), finalColor)
    }

    func testSynthesizeNilUIColors_nilLastColor() {
        let initialColor = UIColor.red

        var animation = Animation<Element>()
        animation.addKeyframe(for: \.optionalUIColorProperty, at: 0, value: initialColor)
        animation.addKeyframe(for: \.optionalUIColorProperty, at: 1, value: nil)

        let optimizedAnimation = animation.optimized(initialValues: Factory.initialElementValues)

        guard let keyframeSeries = optimizedAnimation.keyframeSeriesByProperty[\Element.optionalUIColorProperty] as? Animation<Element>.KeyframeSeries<UIColor?> else {
            XCTFail("Missing keyframe series")
            return
        }

        XCTAssertEqual(keyframeSeries.valuesByRelativeTimestamp.count, 2)
        XCTAssertEqual(keyframeSeries.keyframeRelativeTimestamps, [0, 1])
        XCTAssertEqual(keyframeSeries.valuesByRelativeTimestamp[0]?(nil), initialColor)
        XCTAssertEqual(keyframeSeries.valuesByRelativeTimestamp[1]?(nil), initialColor.withAlphaComponent(0))
    }

    func testSynthesizeNilUIColors_nilFirstAndLastColor() {
        var animation = Animation<Element>()
        animation.addKeyframe(for: \.optionalUIColorProperty, at: 0, value: nil)
        animation.addKeyframe(for: \.optionalUIColorProperty, at: 1, value: nil)

        let optimizedAnimation = animation.optimized(initialValues: Factory.initialElementValues)

        guard let keyframeSeries = optimizedAnimation.keyframeSeriesByProperty[\Element.optionalUIColorProperty] as? Animation<Element>.KeyframeSeries<UIColor?> else {
            XCTFail("Missing keyframe series")
            return
        }

        XCTAssertEqual(keyframeSeries.valuesByRelativeTimestamp.count, 2)
        XCTAssertEqual(keyframeSeries.keyframeRelativeTimestamps, [0, 1])
        XCTAssertEqual(keyframeSeries.valuesByRelativeTimestamp[0]?(nil), nil)
        XCTAssertEqual(keyframeSeries.valuesByRelativeTimestamp[1]?(nil), nil)
    }

}

// MARK: -

private extension AnimationOptimizationTests {

    final class Element {

        init() { }

        var subelement: Subelement = .init()

        var optionalCGColorProperty: CGColor?

        var optionalUIColorProperty: UIColor?

    }

    final class Subelement {

        init() { }

        var propertyOne: Double = 0

        var propertyTwo: Double = 0

    }

}

// MARK: -

private enum Factory {

    static let initialElementValues: [PartialKeyPath<AnimationOptimizationTests.Element>: Any] = [
        \AnimationOptimizationTests.Element.subelement.propertyOne: 0,
        \AnimationOptimizationTests.Element.subelement.propertyTwo: 0,
        \AnimationOptimizationTests.Element.optionalCGColorProperty: UIColor.black.cgColor,
        \AnimationOptimizationTests.Element.optionalUIColorProperty: UIColor.black,
    ]

}
