//
//  SerializableCubicBezierAnimationCurve.swift
//  Pods
//
//  Created by Nick Entin on 3/11/22.
//

import Memo

public struct SerializableCubicBezierAnimationCurve: Codable, Equatable, Identifiable, TokenIdentifiable {

    // MARK: - TokenIdentifiable

    public static let tokenPrefix: String = "CBC"

    // MARK: - Life Cycle

    public init(
        id: Token<SerializableCubicBezierAnimationCurve>,
        name: String,
        controlPoint1X: Double,
        controlPoint1Y: Double,
        controlPoint2X: Double,
        controlPoint2Y: Double
    ) {
        self.id = id
        self.name = name
        self.controlPoint1X = controlPoint1X
        self.controlPoint1Y = controlPoint1Y
        self.controlPoint2X = controlPoint2X
        self.controlPoint2Y = controlPoint2Y
    }

    // MARK: - Public Properties

    public var id: Token<SerializableCubicBezierAnimationCurve>

    public var name: String

    public var controlPoint1X: Double

    public var controlPoint1Y: Double

    public var controlPoint2X: Double

    public var controlPoint2Y: Double

}
