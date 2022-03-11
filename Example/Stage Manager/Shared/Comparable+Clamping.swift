//
//  Comparable+Clamping.swift
//  Stagehand
//
//  Created by Nick Entin on 3/11/22.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import Foundation

extension Comparable {

    func clamped(min minValue: Self, max maxValue: Self) -> Self {
        return max(minValue, min(maxValue, self))
    }

    func clamped(in range: ClosedRange<Self>) -> Self {
        return clamped(min: range.lowerBound, max: range.upperBound)
    }

}
