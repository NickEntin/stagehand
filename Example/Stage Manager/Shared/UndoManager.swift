//
//  UndoManager.swift
//  Stagehand
//
//  Created by Nick Entin on 3/10/22.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import ChoreographerNetworking
import SwiftUI

final class UndoManager<ValueType: Equatable>: ObservableObject {

    init(_ initialValue: ValueType) {
        self.valueStack = [initialValue]
        self.currentIndex = 0
    }

    // MARK: - Public Properties

    @Published
    var canUndo: Bool = false

    @Published
    var canRedo: Bool = false

    // MARK: - Private Properties

    private var currentIndex: Int

    private var valueStack: [ValueType]

    private var currentValue: ValueType {
        return valueStack[currentIndex]
    }

    // MARK: - Public Methods

    func register(_ value: ValueType) {
        guard value != currentValue else {
            return
        }

        valueStack = valueStack[0...currentIndex] + [value]
        currentIndex += 1

        updatePublishedProperties()
    }

    func undo() -> ValueType {
        guard canUndo else {
            return currentValue
        }

        currentIndex -= 1

        updatePublishedProperties()

        return currentValue
    }

    func redo() -> ValueType {
        guard canRedo else {
            return currentValue
        }

        currentIndex += 1

        updatePublishedProperties()

        return currentValue
    }

    // MARK: - Private Methods

    private func updatePublishedProperties() {
        canUndo = currentIndex > 0
        canRedo = currentIndex < (valueStack.count - 1)
    }

}
