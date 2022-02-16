//
//  ClientToServerMessage.swift
//  StageManager
//
//  Created by Nick Entin on 2/15/22.
//

import Foundation

public enum ClientToServerMessage {

    case updateAnimation(AnimationBlueprint)

}

extension ClientToServerMessage {

    enum CodingKeys: CodingKey {
        case updateAnimation
    }

}

extension ClientToServerMessage: Decodable {

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
        case .updateAnimation:
            self = .updateAnimation(try container.decode(AnimationBlueprint.self, forKey: .updateAnimation))
        }
    }

}

extension ClientToServerMessage: Encodable {

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case let .updateAnimation(blueprint):
            try container.encode(blueprint, forKey: .updateAnimation)
        }
    }

}
