// Created by Nick Entin on 3/3/25.

import Foundation

internal final class InteractiveDriver: Driver {

    // MARK: - Driver

    // Note that the animation instance is held strongly here. This creates a retain cycle between the driver and the
    // animation instance. This allows the pair to continue animating even when the consumer discards the result of
    // `Animation.perform(...)` and doesn't hold a reference to the animation instance. Once the animation completes,
    // this reference will be set to `nil` and the retain cycle will be broken.
    var animationInstance: (any DrivenAnimationInstance)!

    func animationInstanceDidInitialize() {
        // @NICK TODO
    }
    
    func animationInstanceDidCancel(behavior: AnimationInstance.CancelationBehavior) {
        // @NICK TODO
    }
    

}
