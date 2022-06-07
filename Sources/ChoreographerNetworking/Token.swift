//
//  Token.swift
//  Pods
//
//  Created by Nick Entin on 3/9/22.
//

import Foundation

public protocol TokenIdentifiable {

    static var tokenPrefix: String { get }

}

public enum TokenError: Swift.Error {

    case incorrectPrefix(token: String, expectedPrefix: String)

    case invalidToken

}

public struct Token<IdentifiedType: TokenIdentifiable> {

    // MARK: - Life Cycle

    public init() {
        self.uuid = UUID()
    }

    fileprivate init(_ rawValue: String) throws {
        guard rawValue.hasPrefix(IdentifiedType.tokenPrefix + "-") else {
            throw TokenError.incorrectPrefix(token: rawValue, expectedPrefix: IdentifiedType.tokenPrefix)
        }

        guard let parsedUUID = UUID(uuidString: String(rawValue.dropFirst(IdentifiedType.tokenPrefix.count + 1))) else {
            throw TokenError.invalidToken
        }

        self.uuid = parsedUUID
    }

    // MARK: - Private Properties

    private let uuid: UUID

}

extension Token: Hashable {

    public func hash(into hasher: inout Hasher) {
        hasher.combine(IdentifiedType.tokenPrefix)
        hasher.combine(uuid)
    }

}

extension Token: Equatable {}

extension Token: Encodable {

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(IdentifiedType.tokenPrefix + "-" + uuid.uuidString)
    }

}

extension Token: Decodable {

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        try self.init(container.decode(String.self))
    }

}
