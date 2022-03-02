//
//  ManagedAnimationBlueprint+PrimitiveConversion.swift
//  StageManager
//
//  Created by Nick Entin on 2/15/22.
//

import Stagehand
import StageManagerPrimitives

extension AnimationBlueprint {

    init<ElementType: AnyObject>(
        blueprint: ManagedAnimationBlueprint<ElementType>,
        id: UUID,
        name: String
    ) {
        self.init(
            id: id,
            name: name,
            implicitDuration: blueprint.implicitDuration,
            implicitRepeatStyle: RepeatStyle(repeatStyle: blueprint.implicitRepeatStyle),
            managedKeyframeSeries: blueprint.managedKeyframeSeries
                .map(AnimationBlueprint.ManagedKeyframeSeries.init(series:))
        )
    }

}

extension ManagedAnimationBlueprint {

    mutating func update(from blueprint: AnimationBlueprint) throws {
        self.implicitDuration = blueprint.implicitDuration
        self.implicitRepeatStyle = .init(repeatStyle: blueprint.implicitRepeatStyle)

        // TODO: Update curve

        self.managedKeyframeSeries = try self.managedKeyframeSeries.map { series in
            guard let serializedSeries = blueprint.managedKeyframeSeries.first(where: { $0.id == series.id }) else {
                return series
            }

            var series = series

            series.enabled = serializedSeries.enabled

            switch (serializedSeries.keyframeSequence, series.keyframeSequence) {
            case (.double, .double), (.cgfloat, .cgfloat), (.color, .color):
                break

//            case (.double, .cgfloat), (.cgfloat, .double):
            default:
                throw BlueprintUpdateError.keyframeSeriesTypeMistmatch(id: series.id)
            }

            series.keyframeSequence = serializedSeries.keyframeSequence
            return series
        }

        // TODO: Update unmanaged keyframe series

        // TODO: Update managed property assignments
    }

    enum BlueprintUpdateError: Swift.Error {
        case keyframeSeriesTypeMistmatch(id: UUID)
    }

}

// MARK: -

extension AnimationBlueprint.RepeatStyle {

    init(repeatStyle: AnimationRepeatStyle) {
        switch repeatStyle {
        case let .repeating(count, autoreversing):
            self = .init(count: count, autoreversing: autoreversing)
        }
    }

}

extension AnimationRepeatStyle {

    init(repeatStyle: AnimationBlueprint.RepeatStyle) {
        self = .repeating(count: repeatStyle.count, autoreversing: repeatStyle.autoreversing)
    }

}

// MARK: -

extension AnimationBlueprint.ManagedKeyframeSeries {

    init<ElementType: AnyObject>(series: ManagedKeyframeSeries<ElementType>) {
        self.init(id: series.id, name: series.name, enabled: series.enabled, keyframeSequence: series.keyframeSequence)
    }

}
