//
//  ManagedAnimationBlueprintCurveProvider.swift
//  Pods
//
//  Created by Nick Entin on 3/11/22.
//

import Stagehand

public protocol ManagedAnimationBlueprintCurveProviding {

    var animationCurve: AnimationCurve { get }

    var displayName: String { get }

}

extension LinearAnimationCurve: ManagedAnimationBlueprintCurveProviding {

    public var animationCurve: AnimationCurve {
        return self
    }

    public var displayName: String {
        return "Linear"
    }

}

extension ParabolicEaseInAnimationCurve: ManagedAnimationBlueprintCurveProviding {

    public var animationCurve: AnimationCurve {
        return self
    }

    public var displayName: String {
        return "Parabolic Ease In"
    }

}

extension ParabolicEaseOutAnimationCurve: ManagedAnimationBlueprintCurveProviding {

    public var animationCurve: AnimationCurve {
        return self
    }

    public var displayName: String {
        return "Parabolic Ease Out"
    }

}

extension SinusoidalEaseInEaseOutAnimationCurve: ManagedAnimationBlueprintCurveProviding {

    public var animationCurve: AnimationCurve {
        return self
    }

    public var displayName: String {
        return "Sinusoidal Ease In Ease Out"
    }

}

extension CubicBezierAnimationCurve: ManagedAnimationBlueprintCurveProviding {

    public var animationCurve: AnimationCurve {
        return self
    }

    public var displayName: String {
        switch self {
        case .easeIn:
            return "Cubic Bezier Ease In"
        case .easeOut:
            return "Cubic Bezier Ease Out"
        case .easeInEaseOut:
            return "Cubic Bezier Ease In Ease Out"
        default:
            return "Cubic Bezier"
        }
    }

}
