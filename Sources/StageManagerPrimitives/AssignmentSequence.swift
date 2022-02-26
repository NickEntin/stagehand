//
//  KeyframeSequence.swift
//  StageManagerPrimitives
//
//  Created by Nick Entin on 2/6/22.
//

import Foundation

public struct Assignment<PropertyType: Codable>: Codable {

    // MARK: - Life Cycle

    public init(relativeTimestamp: Double, value: PropertyType) {
        self.relativeTimestamp = relativeTimestamp
        self.value = value
    }

    public init(_ keyframe: (relativeTimestamp: Double, value: PropertyType)) {
        self.relativeTimestamp = keyframe.relativeTimestamp
        self.value = keyframe.value
    }

    // MARK: - Public Properties

    public var relativeTimestamp: Double

    public var value: PropertyType

}

public enum AssignmentSequence {

    case int([Assignment<Int>])

    case double([Assignment<Double>])

    case cgfloat([Assignment<CGFloat>])

}

extension AssignmentSequence {

    enum CodingKeys: CodingKey {
        case int
        case double
        case cgfloat
    }

}

extension AssignmentSequence: Encodable {

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case let .int(assignments):
            try container.encode(assignments, forKey: .int)

        case let .double(assignments):
            try container.encode(assignments, forKey: .double)

        case let .cgfloat(assignments):
            try container.encode(assignments, forKey: .cgfloat)
        }
    }

}

extension AssignmentSequence: Decodable {

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

        switch key {
        case .int:
            self = .int(try container.decode(Array<Assignment<Int>>.self, forKey: .int))
        case .double:
            self = .double(try container.decode(Array<Assignment<Double>>.self, forKey: .double))
        case .cgfloat:
            self = .cgfloat(try container.decode(Array<Assignment<CGFloat>>.self, forKey: .cgfloat))
        }
    }

}
