//
//  ExecutionBlockControl.swift
//  Pods
//
//  Created by Nick Entin on 3/9/22.
//

import Foundation

public enum ExecutionBlockControl {

    // MARK: - Selection

    public struct Selection<OptionType> {

        public init(
            id:  Token<ExecutionBlockControl>,
            name: String,
            availableOptions: [(displayName: String, value: OptionType)],
            selectedOption: OptionType
        ) {
            self.id = id
            self.name = name
            self.availableOptions = availableOptions
            self.selectedOption = selectedOption
        }

        public var id:  Token<ExecutionBlockControl>

        public var name: String

        public var availableOptions: [(displayName: String, value: OptionType)]

        public var selectedOption: OptionType

    }

    // case stringSelection(Selection<String>)

    case intSelection(Selection<Int>)

    // MARK: -

    // case freeformInt(name: String, defaultValue: Int, validRange: ClosedRange<Int>)

}

extension ExecutionBlockControl: TokenIdentifiable {

    public static let tokenPrefix: String = "EBC"

}

extension ExecutionBlockControl: Identifiable {

    public var id: Token<ExecutionBlockControl> {
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
                id: try selectionContainer.decode(Token<ExecutionBlockControl>.self, forKey: .id),
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
