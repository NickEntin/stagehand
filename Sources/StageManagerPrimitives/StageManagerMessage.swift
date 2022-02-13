//
//  Payload.swift
//  StageManagerPrimitives
//
//  Created by Nick Entin on 2/12/22.
//

import Foundation

public enum StageManagerMessage {

    case registerAnimation(AnimationBlueprint)

}

extension StageManagerMessage {

    enum CodingKeys: CodingKey {
        case registerAnimation
    }

}

extension StageManagerMessage: Decodable {

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
        case .registerAnimation:
            self = .registerAnimation(try container.decode(AnimationBlueprint.self, forKey: .registerAnimation))
        }
    }

}

extension StageManagerMessage: Encodable {

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case let .registerAnimation(blueprint):
            try container.encode(blueprint, forKey: .registerAnimation)
        }
    }

}
