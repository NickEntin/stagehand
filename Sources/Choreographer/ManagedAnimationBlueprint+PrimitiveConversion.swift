//
//  ManagedAnimationBlueprint+PrimitiveConversion.swift
//  StageManager
//
//  Created by Nick Entin on 2/15/22.
//

import ChoreographerNetworking
import Stagehand

extension SerializableAnimationBlueprint {

    init<ElementType: AnyObject>(
        blueprint: ManagedAnimationBlueprint<ElementType>,
        id: Token<SerializableAnimationBlueprint>,
        name: String,
        curve: SerializableAnimationBlueprint.Curve
    ) {
        self.init(
            id: id,
            name: name,
            implicitDuration: blueprint.implicitDuration,
            implicitRepeatStyle: RepeatStyle(repeatStyle: blueprint.implicitRepeatStyle),
            curve: curve,
            managedKeyframeSeries: blueprint.managedKeyframeSeries
                .map(SerializableAnimationBlueprint.ManagedKeyframeSeries.init(series:)),
            unmanagedKeyframeSeries: blueprint.unmanagedKeyframeSeries
                .map(SerializableAnimationBlueprint.UnmanagedKeyframeSeries.init(series:)),
            managedExecutionBlockConfigs: blueprint.managedExeuctionBlocks
                .map(SerializableAnimationBlueprint.ManagedExecutionBlockConfig.init(managedExecution:)),
            managedChildAnimations: blueprint.childManagedAnimations
                .map(SerializableAnimationBlueprint.ManagedChildAnimation.init(child:))
        )
    }

}

extension ManagedAnimationBlueprint {

    mutating func update(from blueprint: SerializableAnimationBlueprint) throws {
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

        // TODO: Update unmanaged property assignments

        self.managedExeuctionBlocks = self.managedExeuctionBlocks.map { execution in
            guard let serializedExecutionConfig = blueprint.managedExecutionBlockConfigs.first(where: { $0.id == execution.id }) else {
                return execution
            }

            execution.enabled = serializedExecutionConfig.enabled
            execution.config.controls = serializedExecutionConfig.controls

            return execution
        }

        // TODO: Update unmanaged execution blocks

        // TODO: Update unmanaged per-frame execution blocks

        self.childManagedAnimations = self.childManagedAnimations.map { child in
            guard let serializedChild = blueprint.managedChildAnimations.first(where: { $0.id == child.id }) else {
                return child
            }

            var child = child

            child.enabled = serializedChild.enabled

            return child
        }

        // TODO: Update child blueprints

        // TODO: Update unmanaged child animations
    }

    enum BlueprintUpdateError: Swift.Error {
        case keyframeSeriesTypeMistmatch(id: Token<SerializableAnimationBlueprint.ManagedKeyframeSeries>)
    }

}

// MARK: -

extension SerializableAnimationBlueprint.RepeatStyle {

    init(repeatStyle: AnimationRepeatStyle) {
        switch repeatStyle {
        case let .repeating(count, autoreversing):
            self = .init(count: count, autoreversing: autoreversing)
        }
    }

}

extension AnimationRepeatStyle {

    init(repeatStyle: SerializableAnimationBlueprint.RepeatStyle) {
        self = .repeating(count: repeatStyle.count, autoreversing: repeatStyle.autoreversing)
    }

}

// MARK: -

//extension SerializableAnimationBlueprint.Curve {
//
//    init(unmanagedCurve curve: AnimationCurve) {
//        self = .unmanaged(SerializableUnmanagedAnimationCurve(id: <#T##Token<SerializableUnmanagedAnimationCurve>#>, name: <#T##String#>))
//    }
//
//}

// MARK: -

extension SerializableAnimationBlueprint.ManagedKeyframeSeries {

    init<ElementType: AnyObject>(series: ManagedKeyframeSeries<ElementType>) {
        self.init(id: series.id, name: series.name, enabled: series.enabled, keyframeSequence: series.keyframeSequence)
    }

}

extension SerializableAnimationBlueprint.UnmanagedKeyframeSeries {

    init<ElementType: AnyObject>(series: UnmanagedKeyframeSeries<ElementType>) {
        self.init(id: series.id, name: series.name, enabled: series.enabled)
    }

}

extension SerializableAnimationBlueprint.ManagedExecutionBlockConfig {

    init<ElementType: AnyObject>(managedExecution: ManagedExecutionBlock<ElementType>) {
        self.init(
            id: managedExecution.id,
            name: managedExecution.name,
            enabled: managedExecution.enabled,
            controls: managedExecution.config.controls
        )
    }

}

extension SerializableAnimationBlueprint.ManagedChildAnimation {

    init<ElementType: AnyObject>(child: ChildManagedAnimation<ElementType>) {
        self.init(id: child.id, name: child.name, enabled: child.enabled, animationID: child.managedAnimationID)
    }

}
