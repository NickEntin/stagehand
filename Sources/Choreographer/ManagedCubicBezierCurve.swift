//
//  ManagedCubicBezierCurve.swift
//  Pods
//
//  Created by Nick Entin on 3/11/22.
//

import ChoreographerNetworking
import Stagehand

public final class ManagedCubicBezierCurve: ManagedAnimationBlueprintCurveProviding {

    // MARK: - Life Cycle

    internal init(curve: CubicBezierAnimationCurve, id: Token<SerializableCubicBezierAnimationCurve>, name: String) {
        self.curve = curve
        self.id = id
        self.displayName = name
    }

    // MARK: - Public Properties

    public var animationCurve: AnimationCurve {
        return curve
    }

    public let displayName: String

    // MARK: - Internal Properties

    internal var curve: CubicBezierAnimationCurve

    internal let id: Token<SerializableCubicBezierAnimationCurve>

    // MARK: - Internal Methods

    internal func serialize() -> SerializableCubicBezierAnimationCurve {
        return SerializableCubicBezierAnimationCurve(
            id: id,
            name: displayName,
            controlPoint1X: curve.controlPoint1.x,
            controlPoint1Y: curve.controlPoint1.y,
            controlPoint2X: curve.controlPoint2.x,
            controlPoint2Y: curve.controlPoint2.y
        )
    }

}
