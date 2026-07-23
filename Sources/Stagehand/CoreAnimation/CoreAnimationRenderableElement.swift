//
//  Copyright 2026 Square Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import UIKit

/// An element that can be animated by the Core Animation execution mode (see
/// `Animation.performUsingCoreAnimation(on:delay:duration:repeatStyle:completion:)`).
///
/// The Core Animation execution mode compiles an animation into `CAKeyframeAnimation`s that are committed to the
/// render server, so it can only animate elements that are backed by a `CALayer` and can only animate properties that
/// have a Core Animation counterpart. Conforming types expose the backing layer and a registry of property mappings.
@MainActor
public protocol CoreAnimationRenderableElement: AnyObject {

    /// The layer to which compiled `CAKeyframeAnimation`s are added when the element is animated using the Core
    /// Animation execution mode.
    var layerForCoreAnimationRendering: CALayer { get }

    /// Returns the registry of property mappings for animations whose element type is `ElementType`.
    ///
    /// The returned dictionary is keyed by the same key paths used to define keyframes (e.g. `\ElementType.alpha`),
    /// so the keys must be rooted at the *concrete* element type of the animation being compiled, which may be a
    /// subclass of the conforming type. Key paths rooted at different types are never equal, even when they reference
    /// the same property, which is why the registry is built per element type rather than once per conforming class.
    ///
    /// - parameter elementType: The concrete element type of the animation being compiled. This is `Self` or a
    /// subclass of `Self`.
    static func coreAnimationPropertyMappings<ElementType: AnyObject>(
        rootedAt elementType: ElementType.Type
    ) -> [PartialKeyPath<ElementType>: CoreAnimationPropertyMapping]

}

// MARK: -

/// Describes how a Stagehand-animated property maps onto a Core Animation layer property.
public struct CoreAnimationPropertyMapping {

    // MARK: - Life Cycle

    /// - parameter layerKeyPath: The Core Animation key path (relative to the element's
    /// `layerForCoreAnimationRendering`) that the property animates, e.g. `"opacity"`.
    /// - parameter makeAnimationValue: Boxes a sampled value of the property (e.g. a `CGFloat`) into an object that
    /// can be used in a `CAKeyframeAnimation`'s `values` array (e.g. an `NSNumber`).
    public init(
        layerKeyPath: String,
        makeAnimationValue: @escaping @MainActor (Any) -> Any
    ) {
        self.layerKeyPath = layerKeyPath
        self.makeAnimationValue = makeAnimationValue
    }

    // MARK: - Public Properties

    /// The Core Animation key path that the property animates, relative to the element's rendering layer.
    public let layerKeyPath: String

    /// Boxes a sampled value of the property into an object usable in a `CAKeyframeAnimation`'s `values` array.
    public let makeAnimationValue: @MainActor (Any) -> Any

}

// MARK: -

extension UIView: CoreAnimationRenderableElement {

    public var layerForCoreAnimationRendering: CALayer {
        return layer
    }

    public static func coreAnimationPropertyMappings<ElementType: AnyObject>(
        rootedAt elementType: ElementType.Type
    ) -> [PartialKeyPath<ElementType>: CoreAnimationPropertyMapping] {
        return CoreAnimationPropertyMappings.mappings(for: UIViewPropertyMappingTable<ElementType>.self)
    }

}

// MARK: -

extension CALayer: CoreAnimationRenderableElement {

    public var layerForCoreAnimationRendering: CALayer {
        return self
    }

    public static func coreAnimationPropertyMappings<ElementType: AnyObject>(
        rootedAt elementType: ElementType.Type
    ) -> [PartialKeyPath<ElementType>: CoreAnimationPropertyMapping] {
        return CoreAnimationPropertyMappings.mappings(for: CALayerPropertyMappingTable<ElementType>.self)
    }

}

// MARK: -

/// A table of property mappings that can be built once the element type it is rooted at is known.
///
/// The conditional conformances below are what let a conformance declared on a base class (e.g. `UIView`) provide
/// mappings rooted at a subclass: the metatype `UIViewPropertyMappingTable<ElementType>.self` can be dynamically cast
/// to `CoreAnimationPropertyMappingTable.Type`, which succeeds exactly when `ElementType` is a `UIView`, and the
/// conditional extension is a generic context in which subclass-rooted key path literals (`\Element.alpha`) can be
/// formed.
internal protocol CoreAnimationPropertyMappingTable {

    @MainActor
    static func makeMappings() -> [AnyKeyPath: CoreAnimationPropertyMapping]

}

// MARK: -

internal enum CoreAnimationPropertyMappings {

    /// Builds the mappings from `table`, rekeyed at the element type the table is rooted at.
    ///
    /// Returns an empty registry when `table` doesn't conform to `CoreAnimationPropertyMappingTable` (i.e. when the
    /// element type doesn't satisfy the table's conditional conformance).
    @MainActor
    internal static func mappings<ElementType: AnyObject>(
        for table: Any.Type
    ) -> [PartialKeyPath<ElementType>: CoreAnimationPropertyMapping] {
        guard let table = table as? CoreAnimationPropertyMappingTable.Type else {
            return [:]
        }

        return table.makeMappings().reduce(into: [:]) { mappings, entry in
            guard let property = entry.key as? PartialKeyPath<ElementType> else {
                return
            }

            mappings[property] = entry.value
        }
    }

}

// MARK: -

internal enum UIViewPropertyMappingTable<Element> {}

extension UIViewPropertyMappingTable: CoreAnimationPropertyMappingTable where Element: UIView {

    internal static func makeMappings() -> [AnyKeyPath: CoreAnimationPropertyMapping] {
        return [
            \Element.alpha: CoreAnimationPropertyMapping(
                layerKeyPath: "opacity",
                makeAnimationValue: { value in
                    return NSNumber(value: Double(value as! CGFloat))
                }
            ),
            \Element.transform: CoreAnimationPropertyMapping(
                layerKeyPath: "transform",
                makeAnimationValue: { value in
                    return NSValue(caTransform3D: CATransform3DMakeAffineTransform(value as! CGAffineTransform))
                }
            ),
            \Element.backgroundColor: CoreAnimationPropertyMapping(
                layerKeyPath: "backgroundColor",
                makeAnimationValue: { value in
                    // A `nil` background color renders the same as clear, and `CGColor` values can't be `nil` in a
                    // keyframe animation's `values` array.
                    return ((value as? UIColor) ?? .clear).cgColor
                }
            ),
        ]
    }

}

// MARK: -

internal enum CALayerPropertyMappingTable<Element> {}

extension CALayerPropertyMappingTable: CoreAnimationPropertyMappingTable where Element: CALayer {

    internal static func makeMappings() -> [AnyKeyPath: CoreAnimationPropertyMapping] {
        return [
            \Element.opacity: CoreAnimationPropertyMapping(
                layerKeyPath: "opacity",
                makeAnimationValue: { value in
                    return NSNumber(value: value as! Float)
                }
            ),
            \Element.transform: CoreAnimationPropertyMapping(
                layerKeyPath: "transform",
                makeAnimationValue: { value in
                    return NSValue(caTransform3D: value as! CATransform3D)
                }
            ),
            \Element.cornerRadius: CoreAnimationPropertyMapping(
                layerKeyPath: "cornerRadius",
                makeAnimationValue: { value in
                    return NSNumber(value: Double(value as! CGFloat))
                }
            ),
        ]
    }

}
