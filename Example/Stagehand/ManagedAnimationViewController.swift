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

        animationRows = [
            ("Left to Right", { [unowned self] in
                leftToRightAnimation.perform(on: self.mainView)
            }),
            ("Right to Left", { [unowned self] in
                rightToLeftAnimation.perform(on: self.mainView)
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
        return leftToRightAnimationBlueprint
    }

    private static func makeRightToLeftBlueprint() -> ManagedAnimationBlueprint<View> {
        var leftToRightAnimationBlueprint = ManagedAnimationBlueprint<View>()
        leftToRightAnimationBlueprint.addManagedKeyframes(
            named: "Left View Alpha",
            for: \View.leftView.alpha,
            keyframes: [(0.5, 0), (1, 1)]
        )
        leftToRightAnimationBlueprint.addManagedKeyframes(
            named: "Right View Alpha",
            for: \View.rightView.alpha,
            keyframes: [(0, 1), (0.5, 0)]
        )
        return leftToRightAnimationBlueprint
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
