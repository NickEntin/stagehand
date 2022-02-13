//
//  Copyright 2022 Square Inc.
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
import StageManagerPrimitives

public final class StageManager {

    // MARK: - Life Cycle

    public init() {
        try! memoServer.start()
    }

    deinit {
        memoServer.stop()
    }

    // MARK: - Public Methods

    public func registerManagedAnimation<ElementType: AnyObject>(
        named name: String,
        blueprint: ManagedAnimationBlueprint<ElementType>
    ) -> ManagedAnimation<ElementType> {
        let animation = ManagedAnimation(blueprint: blueprint)
        managedAnimations[name] = animation
        return animation
    }

    // MARK: - Private Properties

    private let memoServer: Memo.Server = .init(name: UIDevice.current.name)

    private var managedAnimations: [String: AnyObject] = [:]

}
