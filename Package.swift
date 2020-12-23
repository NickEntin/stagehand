// swift-tools-version:5.0.1

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

import PackageDescription

let package = Package(
    name: "Stagehand",
    platforms: [
        .iOS(.v12),
    ],
    products: [
        .library(
            name: "Stagehand",
            targets: ["Stagehand"]
        ),
        .library(
            name: "StagehandTesting",
            targets: ["StagehandTesting"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/pointfreeco/swift-snapshot-testing.git",
            .exact("1.7.0")
        )
    ],
    targets: [
        .target(
            name: "Stagehand",
            dependencies: [],
            path: "Sources/Stagehand"
        ),
        .target(
            name: "StagehandTestingCore",
            dependencies: ["Stagehand"],
            path: "Sources/StagehandTesting/Core"
        ),
        .target(
            name: "StagehandTesting",
            dependencies: [
                "SnapshotTesting",
                "StagehandTestingCore",
            ],
            path: "Sources/StagehandTesting/SnapshotTesting"
        ),
    ],
    swiftLanguageVersions: [.v5]
)

let version = Version(3, 0, 0)
