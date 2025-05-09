//
//  Copyright 2020 Square Inc.
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

import FBSnapshotTestCase

@MainActor
class SnapshotTestCase: FBSnapshotTestCase {

    // MARK: - Private Types

    @MainActor
    private struct TestDeviceConfig {

        // MARK: - Public Properties

        let systemVersion: String
        let screenSize: CGSize
        let screenScale: CGFloat

        // MARK: - Public Methods

        func matchesCurrentDevice() -> Bool {
            let device = UIDevice.current
            let screen = UIScreen.main

            return device.systemVersion == systemVersion
                && screen.bounds.size == screenSize
                && screen.scale == screenScale
        }

    }

    // MARK: - Private Static Properties

    @MainActor
    private static let testedDevices = [
        // iPhone 16 Pro - iOS 18.2
        TestDeviceConfig(systemVersion: "18.2", screenSize: CGSize(width: 402, height: 874), screenScale: 3),
    ]

    // MARK: - FBSnapshotTestCase

    override func setUp() {
        super.setUp()

        executeOnMainActor {
            guard SnapshotTestCase.testedDevices.contains(where: { $0.matchesCurrentDevice() }) else {
                fatalError("Attempting to run tests on a device for which we have not collected test data")
            }
        }

        guard ProcessInfo.processInfo.environment["FB_REFERENCE_IMAGE_DIR"] != nil else {
            fatalError("The environment variable FB_REFERENCE_IMAGE_DIR must be set for the current scheme")
        }

        fileNameOptions = [.OS, .screenSize, .screenScale]

        recordMode = false
    }

    nonisolated
    private func executeOnMainActor(_ block: @escaping @MainActor () -> Void) {
        if Thread.isMainThread {
            MainActor.assumeIsolated {
                block()
            }
        } else {
            DispatchQueue.main.sync {
                MainActor.assumeIsolated {
                    block()
                }
            }
        }
    }

}
