//
//  SerializableAnimationCurve.swift
//  Pods
//
//  Created by Nick Entin on 3/12/22.
//

import Foundation

public struct SerializableUnmanagedAnimationCurve: Codable, Equatable, Identifiable, TokenIdentifiable {

    // MARK: - TokenIdentifiable

    public static let tokenPrefix: String = "UAC"

    // MARK: - Life Cycle

    public init(
        id: Token<SerializableUnmanagedAnimationCurve>,
        name: String
    ) {
        self.id = id
        self.name = name
    }

    // MARK: - Public Properties

    public var id: Token<SerializableUnmanagedAnimationCurve>

    public var name: String

}
