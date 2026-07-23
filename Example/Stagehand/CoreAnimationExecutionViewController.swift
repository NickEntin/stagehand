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

import Stagehand
import UIKit

final class CoreAnimationExecutionViewController: DemoViewController {

    // MARK: - Life Cycle

    override init() {
        super.init()

        contentView = mainView

        contentHeight = 250

        animationRows = [
            ("Slide Using Both Drivers", { [unowned self] in
                self.reset()

                self.displayLinkInstance = self.makeSlideAnimation()
                    .perform(on: self.mainView.displayLinkView)

                self.coreAnimationInstance = self.makeSlideAnimation()
                    .performUsingCoreAnimation(on: self.mainView.coreAnimationView)
            }),
            ("Stall Main Thread (500 ms)", {
                // Simulates an app hang while the animations are in flight. The display-link view freezes for the
                // duration of the stall, while the Core Animation view keeps moving since the render server animates
                // it out of process.
                Thread.sleep(forTimeInterval: 0.5)
            }),
            ("Reset", { [unowned self] in
                self.reset()
            }),
        ]
    }

    // MARK: - Private Properties

    private let mainView: View = .init()

    private var displayLinkInstance: AnimationInstance?

    private var coreAnimationInstance: CoreAnimationInstance?

    // MARK: - Private Methods

    private func makeSlideAnimation() -> Animation<UIView> {
        var animation = Animation<UIView>()
        animation.addKeyframe(for: \.transform, at: 0, value: .identity)
        animation.addKeyframe(for: \.transform, at: 1, value: .init(translationX: mainView.bounds.width - 100, y: 0))
        animation.curve = SinusoidalEaseInEaseOutAnimationCurve()
        animation.implicitDuration = 4
        return animation
    }

    private func reset() {
        displayLinkInstance?.cancel()
        displayLinkInstance = nil

        coreAnimationInstance?.cancel()
        coreAnimationInstance = nil

        mainView.displayLinkView.transform = .identity
        mainView.coreAnimationView.transform = .identity
    }

}

// MARK: -

extension CoreAnimationExecutionViewController {

    final class View: UIView {

        // MARK: - Life Cycle

        override init(frame: CGRect) {
            super.init(frame: frame)

            displayLinkLabel.text = "Display Link (perform)"
            displayLinkLabel.font = .systemFont(ofSize: 14)
            addSubview(displayLinkLabel)

            displayLinkView.frame.size = .init(width: 50, height: 50)
            displayLinkView.backgroundColor = .red
            addSubview(displayLinkView)

            coreAnimationLabel.text = "Core Animation (performUsingCoreAnimation)"
            coreAnimationLabel.font = .systemFont(ofSize: 14)
            addSubview(coreAnimationLabel)

            coreAnimationView.frame.size = .init(width: 50, height: 50)
            coreAnimationView.backgroundColor = .blue
            addSubview(coreAnimationView)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        // MARK: - Public Properties

        let displayLinkView: UIView = .init()

        let coreAnimationView: UIView = .init()

        // MARK: - Private Properties

        private let displayLinkLabel: UILabel = .init()

        private let coreAnimationLabel: UILabel = .init()

        // MARK: - UIView

        override func layoutSubviews() {
            displayLinkLabel.sizeToFit()
            displayLinkLabel.frame.origin = .init(x: 25, y: bounds.height * 0.15)

            displayLinkView.center = .init(
                x: 50,
                y: displayLinkLabel.frame.maxY + 8 + displayLinkView.bounds.height / 2
            )

            coreAnimationLabel.sizeToFit()
            coreAnimationLabel.frame.origin = .init(x: 25, y: bounds.height * 0.55)

            coreAnimationView.center = .init(
                x: 50,
                y: coreAnimationLabel.frame.maxY + 8 + coreAnimationView.bounds.height / 2
            )
        }

    }

}
