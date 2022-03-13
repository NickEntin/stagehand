//
//  Payload.swift
//  StageManagerPrimitives
//
//  Created by Nick Entin on 2/12/22.
//

import Foundation

public enum ServerToClientMessage {

    case registerAnimation(SerializableAnimationBlueprint)

    case registerCubicBezierCurve(SerializableCubicBezierAnimationCurve)

}

extension ServerToClientMessage {

    enum CodingKeys: CodingKey {
        case registerAnimation
        case registerCubicBezierCurve
    }

}

extension ServerToClientMessage: Decodable {

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
            self = .registerAnimation(
                try container.decode(SerializableAnimationBlueprint.self, forKey: .registerAnimation)
            )

        case .registerCubicBezierCurve:
            self = .registerCubicBezierCurve(
                try container.decode(SerializableCubicBezierAnimationCurve.self, forKey: .registerCubicBezierCurve)
            )
        }
    }

}

extension ServerToClientMessage: Encodable {

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case let .registerAnimation(blueprint):
            try container.encode(blueprint, forKey: .registerAnimation)

        case let .registerCubicBezierCurve(curve):
            try container.encode(curve, forKey: .registerCubicBezierCurve)
        }
    }

}
