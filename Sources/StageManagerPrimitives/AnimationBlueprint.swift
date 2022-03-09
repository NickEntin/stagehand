//
//  AnimationBlueprint.swift
//  StageManagerPrimitives
//
//  Created by Nick Entin on 2/6/22.
//

import Foundation

// TODO: Prefix with "Serializable"
public struct AnimationBlueprint: Codable, Identifiable {

    // MARK: - Public Static Properties

    public static let key = "blueprint"

    // MARK: - Life Cycle

    public init(
        id: UUID,
        name: String,
        implicitDuration: TimeInterval,
        implicitRepeatStyle: AnimationBlueprint.RepeatStyle,
        managedKeyframeSeries: [AnimationBlueprint.ManagedKeyframeSeries],
        unmanagedKeyframeSeries: [AnimationBlueprint.UnmanagedKeyframeSeries],
        managedExecutionBlockConfigs: [AnimationBlueprint.ManagedExecutionBlockConfig],
        managedChildAnimations: [AnimationBlueprint.ManagedChildAnimation]
    ) {
        self.id = id
        self.name = name
        self.implicitDuration = implicitDuration
        self.implicitRepeatStyle = implicitRepeatStyle
        self.managedKeyframeSeries = managedKeyframeSeries
        self.unmanagedKeyframeSeries = unmanagedKeyframeSeries
        self.managedExecutionBlockConfigs = managedExecutionBlockConfigs
        self.managedChildAnimations = managedChildAnimations
    }

    // MARK: - Public Properties

    public var id: UUID

    public var name: String

    public var implicitDuration: TimeInterval

    public var implicitRepeatStyle: RepeatStyle

    // TODO: Include curve

    public var managedKeyframeSeries: [ManagedKeyframeSeries]

    public var unmanagedKeyframeSeries: [UnmanagedKeyframeSeries]

    // TODO: Add the rest of the properties

    public var managedExecutionBlockConfigs: [ManagedExecutionBlockConfig]

    public var managedChildAnimations: [ManagedChildAnimation]

    // MARK: - Public Types

    public struct RepeatStyle: Codable {

        // MARK: - Life Cycle

        public init(count: UInt, autoreversing: Bool) {
            self.count = count
            self.autoreversing = autoreversing
        }

        // MARK: - Public Properties

        public var count: UInt

        public var autoreversing: Bool

    }

    public struct ManagedKeyframeSeries: Codable, Identifiable {

        // MARK: - Life Cycle

        public init(id: UUID, name: String, enabled: Bool, keyframeSequence: KeyframeSequence) {
            self.id = id
            self.name = name
            self.enabled = enabled
            self.keyframeSequence = keyframeSequence
        }

        // MARK: - Public Properties

        public var id: UUID

        public var name: String

        public var enabled: Bool

        public var keyframeSequence: KeyframeSequence

    }

    public struct UnmanagedKeyframeSeries: Codable, Identifiable {

        // MARK: - Life Cycle

        public init(id: UUID, name: String, enabled: Bool) {
            self.id = id
            self.name = name
            self.enabled = enabled
        }

        // MARK: - Public Properties

        public var id: UUID

        public var name: String

        public var enabled: Bool

    }

    public struct ManagedExecutionBlockConfig: Codable, Identifiable {

        // MARK: - Life Cycle

        public init(id: UUID, name: String, enabled: Bool, controls: [ExecutionBlockControl]) {
            self.id = id
            self.name = name
            self.enabled = enabled
            self.controls = controls
        }

        // MARK: - Public Properties

        public var id: UUID

        public var name: String

        public var enabled: Bool

        public var controls: [ExecutionBlockControl]

    }

    public struct ManagedChildAnimation: Codable, Identifiable {

        // MARK: - Life Cycle

        public init(id: UUID, name: String, enabled: Bool, animationID: UUID) {
            self.id = id
            self.name = name
            self.enabled = enabled
            self.animationID = animationID
        }

        // MARK: - Public Properties

        public var id: UUID

        public var name: String

        public var enabled: Bool

        public var animationID: UUID

    }

}

public enum ExecutionBlockControl {

    // MARK: - Selection

    public struct Selection<OptionType> {

        public init(id: UUID, name: String, availableOptions: [(displayName: String, value: OptionType)], selectedOption: OptionType) {
            self.id = id
            self.name = name
            self.availableOptions = availableOptions
            self.selectedOption = selectedOption
        }

        public var id: UUID

        public var name: String

        public var availableOptions: [(displayName: String, value: OptionType)]

        public var selectedOption: OptionType

    }

    // case stringSelection(Selection<String>)

    case intSelection(Selection<Int>)

    // MARK: -

    // case freeformInt(name: String, defaultValue: Int, validRange: ClosedRange<Int>)

}

extension ExecutionBlockControl: Identifiable {

    public var id: UUID {
        switch self {
        case let .intSelection(selection):
            return selection.id
        }
    }

}

extension ExecutionBlockControl: Codable {

    private enum CodingKeys: CodingKey {
        case intSelection
    }

    private enum SelectionKeys: CodingKey {
        case id
        case name
        case availableOptionDisplayNames
        case availableOptionValues
        case selectedOption
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        func encodeSelection<OptionType: Encodable>(
            _ selection: Selection<OptionType>,
            in selectionContainer: inout KeyedEncodingContainer<SelectionKeys>
        ) throws {
            try selectionContainer.encode(selection.id, forKey: .id)
            try selectionContainer.encode(selection.name, forKey: .name)
            try selectionContainer.encode(selection.selectedOption, forKey: .selectedOption)
            let (availableDisplayNames, availableValues) = selection.availableOptions
                .reduce((Array<String>(), Array<OptionType>())) { (partialResult, availableOption) in
                    let (displayName, value) = availableOption
                    var partialResult = partialResult
                    partialResult.0.append(displayName)
                    partialResult.1.append(value)
                    return partialResult
                }
            try selectionContainer.encode(availableDisplayNames, forKey: .availableOptionDisplayNames)
            try selectionContainer.encode(availableValues, forKey: .availableOptionValues)
        }

        switch self {
        case let .intSelection(selection):
            var selectionContainer = container.nestedContainer(keyedBy: SelectionKeys.self, forKey: .intSelection)
            try encodeSelection(selection, in: &selectionContainer)
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        guard let key = container.allKeys.first else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: "No valid key found"
                )
            )
        }

        func decodeSelection<ValueType: Decodable>(
            _ selectionContainer: KeyedDecodingContainer<SelectionKeys>
        ) throws -> Selection<ValueType> {
            return Selection<ValueType>(
                id: try selectionContainer.decode(UUID.self, forKey: .id),
                name: try selectionContainer.decode(String.self, forKey: .name),
                availableOptions: zip(
                    try selectionContainer.decode(Array<String>.self, forKey: .availableOptionDisplayNames),
                    try selectionContainer.decode(Array<ValueType>.self, forKey: .availableOptionValues)
                ).reduce([], { return $0 + [$1] }),
                selectedOption: try selectionContainer.decode(ValueType.self, forKey: .selectedOption)
            )
        }

        switch key {
        case .intSelection:
            self = .intSelection(
                try decodeSelection(container.nestedContainer(keyedBy: SelectionKeys.self, forKey: .intSelection))
            )
        }
    }

}
