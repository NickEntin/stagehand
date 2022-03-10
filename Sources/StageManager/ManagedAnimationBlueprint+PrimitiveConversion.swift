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
        id: Token<AnimationBlueprint>,
        name: String
    ) {
        self.init(
            id: id,
            name: name,
            implicitDuration: blueprint.implicitDuration,
            implicitRepeatStyle: RepeatStyle(repeatStyle: blueprint.implicitRepeatStyle),
            managedKeyframeSeries: blueprint.managedKeyframeSeries
                .map(AnimationBlueprint.ManagedKeyframeSeries.init(series:)),
            unmanagedKeyframeSeries: blueprint.unmanagedKeyframeSeries
                .map(AnimationBlueprint.UnmanagedKeyframeSeries.init(series:)),
            managedExecutionBlockConfigs: blueprint.managedExeuctionBlocks
                .map(AnimationBlueprint.ManagedExecutionBlockConfig.init(managedExecution:)),
            managedChildAnimations: blueprint.childManagedAnimations
                .map(AnimationBlueprint.ManagedChildAnimation.init(child:))
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

            case (.double, _), (.cgfloat, _), (.color, _):
                throw BlueprintUpdateError.keyframeSeriesTypeMistmatch(id: series.id)
            }

            series.keyframeSequence = serializedSeries.keyframeSequence
            return series
        }

        self.unmanagedKeyframeSeries = self.unmanagedKeyframeSeries.map { series in
            guard let serializedSeries = blueprint.unmanagedKeyframeSeries.first(where: { $0.id == series.id }) else {
                return series
            }

            var series = series

            series.enabled = serializedSeries.enabled

            return series
        }

        // TODO: Update managed property assignments

        self.managedExeuctionBlocks = self.managedExeuctionBlocks.map { execution in
            guard let serializedExecutionConfig = blueprint.managedExecutionBlockConfigs.first(where: { $0.id == execution.id }) else {
                return execution
            }

            execution.enabled = serializedExecutionConfig.enabled
            execution.config.controls = serializedExecutionConfig.controls

            return execution
        }

        self.childManagedAnimations = self.childManagedAnimations.map { child in
            guard let serializedChild = blueprint.managedChildAnimations.first(where: { $0.id == child.id }) else {
                return child
            }

            var child = child

            child.enabled = serializedChild.enabled

            return child
        }

        // TODO: Update the rest of the properties
    }

    enum BlueprintUpdateError: Swift.Error {
        case keyframeSeriesTypeMistmatch(id: Token<AnimationBlueprint.ManagedKeyframeSeries>)
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

extension AnimationBlueprint.UnmanagedKeyframeSeries {

    init<ElementType: AnyObject>(series: UnmanagedKeyframeSeries<ElementType>) {
        self.init(id: series.id, name: series.name, enabled: series.enabled)
    }

}

extension AnimationBlueprint.ManagedExecutionBlockConfig {

    init<ElementType: AnyObject>(managedExecution: ManagedExecutionBlock<ElementType>) {
        self.init(
            id: managedExecution.id,
            name: managedExecution.name,
            enabled: managedExecution.enabled,
            controls: managedExecution.config.controls
        )
    }

}

extension AnimationBlueprint.ManagedChildAnimation {

    init<ElementType: AnyObject>(child: ChildManagedAnimation<ElementType>) {
        self.init(id: child.id, name: child.name, enabled: child.enabled, animationID: child.managedAnimationID)
    }

}
