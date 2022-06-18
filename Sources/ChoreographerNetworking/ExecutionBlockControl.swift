//
//  ExecutionBlockControl.swift
//  Pods
//
//  Created by Nick Entin on 3/9/22.
//

import Memo

public enum ExecutionBlockControl: Equatable {

    // MARK: - Selection

    public struct Selection<OptionType: Equatable>: Equatable {

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

        public static func == (lhs: ExecutionBlockControl.Selection<OptionType>, rhs: ExecutionBlockControl.Selection<OptionType>) -> Bool {
            return lhs.id == rhs.id
                && lhs.name == rhs.name
                && lhs.selectedOption == rhs.selectedOption
                && lhs.availableOptions.count == rhs.availableOptions.count
                && zip(lhs.availableOptions, rhs.availableOptions)
                    .allSatisfy { $0.0 == $1.0 && $0.1 == $1.1 }
        }

    }

    case intSelection(Selection<Int>)

    // MARK: -

    public struct Freeform<OptionType: Comparable>: Equatable {

        public init(
            id: Token<ExecutionBlockControl>,
            name: String,
            validRange: Range<OptionType>?,
            selectedValue: OptionType
        ) {
            self.id = id
            self.name = name
            self.validRange = validRange
            self.selectedValue = selectedValue
        }

        public var id: Token<ExecutionBlockControl>

        public var name: String

        public var validRange: Range<OptionType>?

        public var selectedValue: OptionType

    }

    case intFreeform(Freeform<Int>)

}

extension ExecutionBlockControl: TokenIdentifiable {

    public static let tokenPrefix: String = "EBC"

}

extension ExecutionBlockControl: Identifiable {

    public var id: Token<ExecutionBlockControl> {
        switch self {
        case let .intSelection(selection):
            return selection.id
        case let .intFreeform(freeform):
            return freeform.id
        }
    }

}

extension ExecutionBlockControl: Codable {

    private enum CodingKeys: CodingKey {
        case intSelection
        case intFreeform
    }

    private enum SelectionKeys: CodingKey {
        case id
        case name
        case availableOptionDisplayNames
        case availableOptionValues
        case selectedOption
    }

    private enum FreeformKeys: CodingKey {
        case id
        case name
        case validRange
        case selectedValue
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

        func encodeFreeform<OptionType: Encodable>(
            _ freeform: Freeform<OptionType>,
            in container: inout KeyedEncodingContainer<FreeformKeys>
        ) throws {
            try container.encode(freeform.id, forKey: .id)
            try container.encode(freeform.name, forKey: .name)
            try container.encodeIfPresent(freeform.validRange, forKey: .validRange)
            try container.encode(freeform.selectedValue, forKey: .selectedValue)
        }

        switch self {
        case let .intSelection(selection):
            var selectionContainer = container.nestedContainer(keyedBy: SelectionKeys.self, forKey: .intSelection)
            try encodeSelection(selection, in: &selectionContainer)
        case let .intFreeform(freeform):
            var selectionContainer = container.nestedContainer(keyedBy: FreeformKeys.self, forKey: .intFreeform)
            try encodeFreeform(freeform, in: &selectionContainer)
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

        func decodeFreeform<ValueType: Decodable>(
            _ container: KeyedDecodingContainer<FreeformKeys>
        ) throws -> Freeform<ValueType> {
            return Freeform<ValueType>(
                id: try container.decode(Token<ExecutionBlockControl>.self, forKey: .id),
                name: try container.decode(String.self, forKey: .name),
                validRange: try container.decodeIfPresent(Range<ValueType>.self, forKey: .validRange),
                selectedValue: try container.decode(ValueType.self, forKey: .selectedValue)
            )
        }

        switch key {
        case .intSelection:
            self = .intSelection(
                try decodeSelection(container.nestedContainer(keyedBy: SelectionKeys.self, forKey: .intSelection))
            )
        case .intFreeform:
            self = .intFreeform(
                try decodeFreeform(container.nestedContainer(keyedBy: FreeformKeys.self, forKey: .intFreeform))
            )
        }
    }

}
