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

import Memo
import Stagehand
import StageManager
//import StageManagerPrimitives
import UIKit

final class ManagedAnimationViewController: DemoViewController {

    // MARK: - Life Cycle

    override init() {
        super.init()

        contentView = mainView

        let leftToRightAnimation = stageManager.registerManagedAnimation(
            named: "Left to Right",
            blueprint: Self.makeLeftToRightBlueprint()
        )

        let rightToLeftAnimation = stageManager.registerManagedAnimation(
            named: "Right to Left",
            blueprint: Self.makeRightToLeftBlueprint()
        )

        let scaleAnimation = stageManager.registerManagedAnimation(
            named: "Scale View",
            blueprint: Self.makeScaleBlueprint(hapticFeedbackStyle: .medium)
        )

        let scaleBothAnimation = stageManager.registerManagedAnimation(
            named: "Scale Both",
            blueprint: Self.makeScaleBothBlueprint(scaleAnimation: scaleAnimation)
        )

        animationRows = [
            ("Left to Right", { [unowned self] in
                leftToRightAnimation.perform(on: self.mainView)
            }),
            ("Right to Left", { [unowned self] in
                rightToLeftAnimation.perform(on: self.mainView)
            }),
            ("Scale Both Views", { [unowned self] in
                scaleBothAnimation.perform(on: self.mainView)
            }),
        ]
    }

    // MARK: - Private Properties

    private let mainView: View = .init()

    private let stageManager: StageManager = .init()

    // MARK: - Private Static Methods

    private static func makeLeftToRightBlueprint() -> ManagedAnimationBlueprint<View> {
        var leftToRightAnimationBlueprint = ManagedAnimationBlueprint<View>()
        leftToRightAnimationBlueprint.addManagedKeyframes(
            named: "Left View Alpha",
            for: \View.leftView.alpha,
            keyframes: [(0, 1), (0.5, 0)]
        )
        leftToRightAnimationBlueprint.addManagedKeyframes(
            named: "Right View Alpha",
            for: \View.rightView.alpha,
            keyframes: [(0.5, 0), (1, 1)]
        )
        leftToRightAnimationBlueprint.addManagedKeyframes(
            named: "Left View Background Color",
            for: \View.leftView.layer.backgroundColor!,
            keyframes: [
                (0, UIColor.red.cgColor),
                (0.25, UIColor.green.cgColor),
                (1.0, UIColor.yellow.cgColor),
            ]
        )
        leftToRightAnimationBlueprint.addUnmanagedKeyframes(
            named: "Right View Scale",
            for: \View.rightView.transform,
            keyframes: [
                (0.5, CGAffineTransform.identity),
                (0.75, CGAffineTransform(scaleX: 1.2, y: 1.2)),
                (1.0, CGAffineTransform.identity),
            ]
        )
        return leftToRightAnimationBlueprint
    }

    private static func makeRightToLeftBlueprint() -> ManagedAnimationBlueprint<View> {
        var rightToLeftAnimationBlueprint = ManagedAnimationBlueprint<View>()
        rightToLeftAnimationBlueprint.addManagedKeyframes(
            named: "Left View Alpha",
            for: \View.leftView.alpha,
            keyframes: [(0.5, 0), (1, 1)]
        )
        rightToLeftAnimationBlueprint.addManagedKeyframes(
            named: "Right View Alpha",
            for: \View.rightView.alpha,
            keyframes: [(0, 1), (0.5, 0)]
        )
        return rightToLeftAnimationBlueprint
    }

    private static func makeScaleBlueprint(hapticFeedbackStyle: UIImpactFeedbackGenerator.FeedbackStyle) -> ManagedAnimationBlueprint<UIView> {
        var blueprint = ManagedAnimationBlueprint<UIView>()
        blueprint.addUnmanagedKeyframes(
            named: "Scale Transform",
            for: \UIView.transform,
            keyframes: [
                (0, CGAffineTransform.identity),
                (0.5, CGAffineTransform(scaleX: 1.5, y: 1.5)),
                (1, CGAffineTransform.identity),
            ]
        )
        blueprint.addManagedKeyframes(
            named: "Opacity",
            for: \.alpha,
            keyframes: [
                (0, 1),
                (0.5, 0.8),
                (1, 1),
            ]
        )
        blueprint.addManagedExecution(
            named: "Haptic Feedback",
            factory: { config in
                let generator = UIImpactFeedbackGenerator(style: config.selectedStyle)
                generator.prepare()

                return .init(
                    onForward: { _ in generator.impactOccurred() }
                )
            },
            config: HapticFeedbackConfig(selectedStyle: hapticFeedbackStyle),
            at: 0.5
        )
        return blueprint
    }

    private static func makeScaleBothBlueprint(scaleAnimation: ManagedAnimation<UIView>) -> ManagedAnimationBlueprint<View> {
        var blueprint = ManagedAnimationBlueprint<View>()
        blueprint.addManagedChild(
            named: "Left View Scale",
            scaleAnimation,
            for: \.leftView,
            startingAt: 0,
            relativeDuration: 0.75
        )
        blueprint.addManagedChild(
            named: "Right View Scale",
            scaleAnimation,
            for: \.rightView,
            startingAt: 0.25,
            relativeDuration: 0.75
        )
        return blueprint
    }

}

// MARK: -

extension ManagedAnimationViewController {

    final class View: UIView {

        // MARK: - Life Cycle

        override init(frame: CGRect) {
            super.init(frame: frame)

            leftView.backgroundColor = .red
            addSubview(leftView)

            rightView.backgroundColor = .blue
            rightView.alpha = 0
            addSubview(rightView)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        // MARK: - Public Properties

        let leftView: UIView = .init()

        let rightView: UIView = .init()

        // MARK: - UIView

        override func layoutSubviews() {
            leftView.bounds.size = .init(width: 50, height: 50)
            leftView.center = .init(
                x: bounds.width / 3,
                y: bounds.height / 2
            )

            rightView.bounds.size = .init(width: 50, height: 50)
            rightView.center = .init(
                x: bounds.width * 2 / 3,
                y: bounds.height / 2
            )
        }

    }

}

// MARK: -

struct HapticFeedbackConfig: ExecutionBlockConfig {

    init(selectedStyle: UIImpactFeedbackGenerator.FeedbackStyle) {
        controls = [
            .intSelection(
                .init(
                    id: .init(),
                    name: "Style",
                    availableOptions: [
                        (displayName: "Light", value: UIImpactFeedbackGenerator.FeedbackStyle.light.rawValue),
                        (displayName: "Medium", value: UIImpactFeedbackGenerator.FeedbackStyle.medium.rawValue),
                        (displayName: "Heavy", value: UIImpactFeedbackGenerator.FeedbackStyle.heavy.rawValue),
                        (displayName: "Soft", value: UIImpactFeedbackGenerator.FeedbackStyle.soft.rawValue),
                        (displayName: "Rigid", value: UIImpactFeedbackGenerator.FeedbackStyle.rigid.rawValue),
                    ],
                    selectedOption: selectedStyle.rawValue
                )
            ),
        ]
    }

    var controls: [ExecutionBlockControl]

    var selectedStyle: UIImpactFeedbackGenerator.FeedbackStyle {
        switch controls[0] {
        case let .intSelection(selection):
            return .init(rawValue: selection.selectedOption)!
        default:
            fatalError("Unexpected control type")
        }
    }

}
