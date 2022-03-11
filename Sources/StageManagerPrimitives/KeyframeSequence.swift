//
//  KeyframeSequence.swift
//  StageManagerPrimitives
//
//  Created by Nick Entin on 2/6/22.
//

import Foundation

public struct Keyframe<PropertyType: Codable & Equatable>: Codable, Equatable {

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

public enum KeyframeSequence: Equatable {

    case double([Keyframe<Double>])

    case cgfloat([Keyframe<CGFloat>])

    case color([Keyframe<RGBAColor>])

}

extension KeyframeSequence {

    enum CodingKeys: CodingKey {
        case double
        case cgfloat
        case color
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

        case let .color(keyframes):
            try container.encode(keyframes, forKey: .color)
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
        case .color:
            self = .color(try container.decode(Array<Keyframe<RGBAColor>>.self, forKey: .color))
        }
    }

}

public struct RGBAColor: Codable, Equatable {

    public init(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }

    public init(cgColor: CGColor) {
        guard let components = cgColor.components, components.count == 4 else {
            fatalError()
        }

        self.red = components[0]
        self.green = components[1]
        self.blue = components[2]
        self.alpha = components[3]
    }

    public var red: CGFloat
    public var green: CGFloat
    public var blue: CGFloat
    public var alpha: CGFloat

    public func toCGColor() -> CGColor {
        return CGColor(red: red, green: green, blue: blue, alpha: alpha)
    }

}
