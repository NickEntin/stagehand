//
//  CurveDetailsView.swift
//  Stagehand
//
//  Created by Nick Entin on 3/12/22.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import Memo
import ChoreographerNetworking
import SwiftUI

struct CurveDetailsView: View {

    init(
        curve: SerializableCubicBezierAnimationCurve,
        transceiver: Transceiver
    ) {
        self._curve = State(initialValue: curve)
        self.transceiver = transceiver

        self.undoManager = .init(curve)
    }

    @State
    var curve: SerializableCubicBezierAnimationCurve

    @ObservedObject
    var transceiver: Transceiver

    @ObservedObject
    private var undoManager: UndoManager<SerializableCubicBezierAnimationCurve>

    @GestureState
    private var controlPoint1DragOffset: CGSize = .zero

    @GestureState
    private var controlPoint2DragOffset: CGSize = .zero

    #if os(iOS)
    @Environment(\.horizontalSizeClass)
    private var horizontalSizeClass
    #endif

    private var shouldUseSingleToolbarItem: Bool {
        #if os(iOS)
        return horizontalSizeClass == .compact
        #else
        return false
        #endif
    }

    var body: some View {
        VStack(spacing: 0) {
            GeometryReader { geometry in
                Grid(width: geometry.size.width, height: geometry.size.height, rows: 5)
                    .opacity(0.2)
            }
            .frame(height: 75)
            .padding([.horizontal, .top])
            GeometryReader { geometry in
                let width: CGFloat = geometry.size.width
                let height: CGFloat = geometry.size.height

                let controlPointSize = CGSize(width: 8, height: 8)
                let controlPointHitTargetSize = CGSize(width: 44, height: 44)

                let horizontalOutset = (controlPointHitTargetSize.width - controlPointSize.width) / 2
                let verticalOutset = (controlPointHitTargetSize.height - controlPointHitTargetSize.height) / 2

                let effectiveControlPoint1 = CGPoint(
                    x: (curve.controlPoint1X * width + controlPoint1DragOffset.width)
                        .clamped(in: (-controlPointSize.width / 2)...(width - controlPointSize.width / 2)),
                    y: (1 - curve.controlPoint1Y) * height + controlPoint1DragOffset.height
                )

                let effectiveControlPoint2 = CGPoint(
                    x: (curve.controlPoint2X * width + controlPoint2DragOffset.width)
                        .clamped(in: (-controlPointSize.width / 2)...(width - controlPointSize.width / 2)),
                    y: (1 - curve.controlPoint2Y) * height + controlPoint2DragOffset.height
                )

                ZStack(alignment: .topLeading) {
                    Grid(width: width, height: height)
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: height))
                        path.addCurve(
                            to: CGPoint(x: width, y: 0),
                            control1: effectiveControlPoint1,
                            control2: effectiveControlPoint2
                        )
                    }
                    .stroke(lineWidth: 2)
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: height))
                        path.addLine(
                            to: CGPoint(
                                x: effectiveControlPoint1.x + controlPointSize.width / 2,
                                y: effectiveControlPoint1.y + controlPointSize.height / 2
                            )
                        )
                    }
                    .stroke(Color.blue, lineWidth: 0.5)
                    Circle()
                        .fill(Color.blue)
                        .frame(width: controlPointSize.width, height: controlPointSize.height, alignment: .center)
                        .padding(EdgeInsets(top: verticalOutset, leading: horizontalOutset, bottom: verticalOutset, trailing: horizontalOutset))
                        .offset(
                            x: effectiveControlPoint1.x - horizontalOutset,
                            y: effectiveControlPoint1.y - verticalOutset
                        )
                        .simultaneousGesture(
                            DragGesture()
                                .updating($controlPoint1DragOffset) { value, state, _ in
                                    state = value.translation
                                }
                                .onEnded { value in
                                    curve.controlPoint1X += Double(value.translation.width / width)
                                    curve.controlPoint1Y -= Double(value.translation.height / height)
                                }
                        )
                    Path { path in
                        path.move(to: CGPoint(x: width, y: 0))
                        path.addLine(
                            to: CGPoint(
                                x: effectiveControlPoint2.x + controlPointSize.width / 2,
                                y: effectiveControlPoint2.y + controlPointSize.height / 2
                            )
                        )
                    }
                    .stroke(Color.blue, lineWidth: 0.5)
                    Circle()
                        .fill(Color.blue)
                        .frame(width: controlPointSize.width, height: controlPointSize.height, alignment: .center)
                        .padding(EdgeInsets(top: verticalOutset, leading: horizontalOutset, bottom: verticalOutset, trailing: horizontalOutset))
                        .offset(
                            x: effectiveControlPoint2.x - horizontalOutset,
                            y: effectiveControlPoint2.y - verticalOutset
                        )
                        .simultaneousGesture(
                            DragGesture()
                                .updating($controlPoint2DragOffset) { value, state, _ in
                                    state = value.translation
                                }
                                .onEnded { value in
                                    curve.controlPoint2X += Double(value.translation.width / width)
                                    curve.controlPoint2Y -= Double(value.translation.height / height)
                                }
                        )
                }
            }
            .frame(height: 150)
            .padding(.horizontal)
            GeometryReader { geometry in
                Grid(width: geometry.size.width, height: geometry.size.height, rows: 5)
                    .opacity(0.2)
            }
            .frame(height: 75)
            .padding(.horizontal)
        }
        Spacer()
        Button {
            Task {
                // TODO: Hook up the updater
            }
        } label: {
            Text("Update")
                .frame(maxWidth: .infinity)
                .padding([.vertical])
                .background(Color.blue)
                .foregroundColor(Color.white)
                .cornerRadius(8)
        }
        .disabled(!transceiver.hasActiveConnection)
        .padding()
        .onChange(of: curve) { newValue in
            undoManager.register(newValue)
        }
        .toolbar {
            HStack {
                if shouldUseSingleToolbarItem {
                    Menu {
                        Button {
                            curve = undoManager.undo()
                        } label: {
                            Label("Undo", systemImage: "arrow.uturn.backward")
                        }
                        .flipsForRightToLeftLayoutDirection(false)
                        .disabled(!undoManager.canUndo)
                        Button {
                            curve = undoManager.redo()
                        } label: {
                            Label("Redo", systemImage: "arrow.uturn.forward")
                        }
                        .flipsForRightToLeftLayoutDirection(false)
                        .disabled(!undoManager.canRedo)
                        Button {
                            // TODO: Export curve data
                        } label: {
                            Label("Export", systemImage: "square.and.arrow.up")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                    }

                } else {
                    Button {
                        curve = undoManager.undo()
                    } label: {
                        Image(systemName: "arrow.uturn.backward")
                            .accessibilityLabel("Undo")
                    }
                    .flipsForRightToLeftLayoutDirection(false)
                    .disabled(!undoManager.canUndo)
                    Button {
                        curve = undoManager.redo()
                    } label: {
                        Image(systemName: "arrow.uturn.forward")
                            .accessibilityLabel("Redo")
                    }
                    .flipsForRightToLeftLayoutDirection(false)
                    .disabled(!undoManager.canRedo)
                    Button {
                        // TODO: Export curve data
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .accessibilityLabel("Export")
                    }
                }
            }
        }
    }

}
