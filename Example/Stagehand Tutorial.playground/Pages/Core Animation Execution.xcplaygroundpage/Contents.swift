//: [Previous](@previous)

import PlaygroundSupport
import Stagehand
import UIKit

/*:

 # Core Animation Execution

 The `perform(on:delay:completion:)` method renders each frame of an animation on the main thread, driven by a
 `CADisplayLink`. This gives Stagehand its flexibility - any property can be animated, and code can run on every frame -
 but it also means a main thread stall (a layout storm, an app hang) freezes any in-flight animations.

 The `performUsingCoreAnimation(on:delay:duration:repeatStyle:completion:)` method trades some of that flexibility for
 resilience. It compiles the animation *once* into `CAKeyframeAnimation`s that are committed to the render server, which
 animates out-of-process - so a main thread stall can no longer drop the animation's frames.

 */

let animation = AnimationFactory.makeBasicViewAnimation()

let view = UIView(frame: .init(x: 0, y: 0, width: 100, height: 100))
view.backgroundColor = .red
PlaygroundPage.current.liveView = WrapperView(wrappedView: view)

let instance = animation.performUsingCoreAnimation(on: view)

/*:

 The returned `CoreAnimationInstance` can be used to check the status of the animation or cancel it, just like an
 `AnimationInstance`.

 ## Which Properties Can Be Animated?

 The render server can only animate properties that map onto a `CALayer` property. Elements declare their mappings by
 conforming to `CoreAnimationRenderableElement`. Stagehand ships with conformances for `UIView` and `CALayer`:

 | Element Type | Stagehand Property   | Layer Key Path      |
 |--------------|----------------------|---------------------|
 | `UIView`     | `\.alpha`            | `"opacity"`         |
 | `UIView`     | `\.transform`        | `"transform"`       |
 | `UIView`     | `\.backgroundColor`  | `"backgroundColor"` |
 | `CALayer`    | `\.opacity`          | `"opacity"`         |
 | `CALayer`    | `\.transform`        | `"transform"`       |
 | `CALayer`    | `\.cornerRadius`     | `"cornerRadius"`    |

 Custom elements can conform to `CoreAnimationRenderableElement` to expose their own backing layer and mappings.

 Note that child animations' composed key paths (e.g. `\.subview.alpha`) are never in the root element's mapping
 registry, so an animation with children that animate a *different* element can't be compiled. Use an `AnimationGroup`
 to animate multiple layer-backed elements in this mode - `AnimationGroup` has a matching
 `performUsingCoreAnimation(delay:duration:repeatStyle:completion:)` method that compiles each element's animations
 separately.

 ## Trade-Offs

 Committing the animation to the render server changes a few behaviors:

 * The element's final model values are set as soon as the animation begins. While the animation is in flight, reading
   an animated property returns its final value, not the value currently displayed.

 * Execution blocks and property assignments are app-side code and can't run on the render server. They are scheduled
   on the main queue at their expected times, so under a main thread stall they may fire late while the visuals stay
   smooth.

 ## Falling Back to the Display Link

 Some animations can't be represented on the render server at all:

 * Animations with per-frame execution blocks (added via `addPerFrameExecution(_:)`), since the app isn't rendering the
   frames.

 * Animations with a keyframe series whose property has no Core Animation mapping.

 * Indefinitely repeating animations that contain execution blocks or property assignments, since their execution
   events can't be scheduled ahead of time.

 When `performUsingCoreAnimation` encounters one of these, it raises a debug assertion and falls back to the
 display-link execution mode, so release behavior degrades gracefully. The returned instance's `executionMode`
 indicates which mode ended up executing the animation.

 */

var perFrameAnimation = AnimationFactory.makeBasicViewAnimation()
perFrameAnimation.addPerFrameExecution { context in
    print("Rendering frame at \(context.progress)")
}

let fallbackInstance = perFrameAnimation.performUsingCoreAnimation(on: view)

switch fallbackInstance.executionMode {
case .coreAnimation:
    print("Our animation is running on the render server.")

case .displayLinkFallback:
    print("Our animation fell back to the display-link driver.")
}

/*:

 To see the difference between the two execution modes side by side, check out the "Core Animation Execution" screen in
 the demo app - it runs the same slide animation through both drivers and lets you stall the main thread while they're
 in flight.

 */

//: [Next](@next)
