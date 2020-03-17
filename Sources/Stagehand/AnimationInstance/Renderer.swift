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

import Foundation

internal final class Renderer<ElementType: AnyObject>: AnyRenderer {

    // MARK: - Life Cycle

    internal init(
        animation: Animation<ElementType>,
        element: ElementType,
        initialValues: Dictionary<PartialKeyPath<ElementType>, Any>
    ) {
        self.animation = animation
        self.element = element
        self.initialValues = initialValues
    }

    // MARK: - Private Properties

    private let animation: Animation<ElementType>

    private weak var element: ElementType?

    private let initialValues: Dictionary<PartialKeyPath<ElementType>, Any>

    // MARK: - Internal Methods

    func canRenderFrame() -> Bool {
        return (element != nil)
    }

    func renderFrame(at relativeTimestamp: Double) {
        guard var element = self.element else {
            return
        }

        animation.apply(to: &element, at: relativeTimestamp, initialValues: initialValues)
    }

    func renderInitialFrame() {
        guard var element = self.element else {
            return
        }

        animation.applyInitialKeyframes(to: &element, initialValues: initialValues)
    }

}

// MARK: -

internal protocol AnyRenderer {

    func canRenderFrame() -> Bool

    func renderFrame(at relativeTimestamp: Double)

    func renderInitialFrame()

}
