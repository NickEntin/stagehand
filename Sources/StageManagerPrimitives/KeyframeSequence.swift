//
//  KeyframeSequence.swift
//  StageManagerPrimitives
//
//  Created by Nick Entin on 2/6/22.
//

import Foundation

public struct Keyframe<PropertyType: Codable>: Codable {

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

public enum KeyframeSequence {

    case double([Keyframe<Double>])

    case cgfloat([Keyframe<CGFloat>])

}

extension KeyframeSequence {

    enum CodingKeys: CodingKey {
        case double
        case cgfloat
    }

}

extension KeyframeSequence: Encodable {

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case let .double(keyframes):
            try container.encode(keyframes, forKey: .double)

        case let .cgfloat(keyframes):
            try container.encode(keyframes, forKey: .cgfloat)
        }
    }

}

extension KeyframeSequence: Decodable {

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
        case .double:
            self = .double(try container.decode(Array<Keyframe<Double>>.self, forKey: .double))
        case .cgfloat:
            self = .cgfloat(try container.decode(Array<Keyframe<CGFloat>>.self, forKey: .cgfloat))
        }
    }

}
