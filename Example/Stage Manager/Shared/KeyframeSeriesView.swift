//
//  KeyframeSeriesView.swift
//  Stagehand
//
//  Created by Nick Entin on 2/25/22.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import StageManagerPrimitives
import SwiftUI

struct KeyframeSeriesView: View {

    init(
        keyframeSeries: Binding<AnimationBlueprint.ManagedKeyframeSeries>
    ) {
        self.keyframeSeries = keyframeSeries
    }

    let keyframeSeries: Binding<AnimationBlueprint.ManagedKeyframeSeries>

    var body: some View {
        VStack {
            HStack {
                Text(keyframeSeries.name.wrappedValue)
                    .layoutPriority(1)
                Spacer()
                    .layoutPriority(0.5)
                Toggle("Enabled", isOn: keyframeSeries.enabled)
                    .layoutPriority(0.5)
                    .labelsHidden()
                    .frame(width: 100, height: nil, alignment: .trailing)
            }
            .padding([.horizontal, .top])
            switch keyframeSeries.keyframeSequence.wrappedValue {
            case .double, .cgfloat:
                NumericKeyframeChart(keyframeSequence: keyframeSeries.keyframeSequence)
                    .padding([.horizontal, .bottom])
            case .color:
                ColorKeyframeChart(keyframeSequence: keyframeSeries.keyframeSequence)
                    .padding([.horizontal, .bottom])
            }
        }
    }

}

struct NumericKeyframeChart: View {

    init(
        keyframeSequence: Binding<KeyframeSequence>
    ) {
        self.keyframeSequence = keyframeSequence
    }

    let keyframeSequence: Binding<KeyframeSequence>

    var keyframeValues: [Keyframe] {
        switch keyframeSequence.wrappedValue {
        case let .double(keyframes):
            return keyframes
                .enumerated()
                .map { index, keyframe in
                    Keyframe(
                        id: index,
                        relativeTimestamp: CGFloat(keyframe.relativeTimestamp),
                        relativeValue: CGFloat(keyframe.value)
                    )
                }

        case let .cgfloat(keyframes):
            return keyframes
                .enumerated()
                .map { index, keyframe in
                    Keyframe(
                        id: index,
                        relativeTimestamp: CGFloat(keyframe.relativeTimestamp),
                        relativeValue: keyframe.value
                    )
                }

        case .color:
            fatalError("Unexpected keyframe type")
        }
    }

    @State
    var inProgressTranslation: (Int, CGSize)? = nil

    func offsetForKeyframe(id: Int) -> CGSize {
        guard let inProgressTranslation = inProgressTranslation else {
            return .zero
        }

        return inProgressTranslation.0 == id ? inProgressTranslation.1 : .zero
    }

    func updateKeyframe(at index: Int, relativeTimestamp: CGFloat, value: CGFloat) {
        switch keyframeSequence.wrappedValue {
        case let .double(keyframes):
            var keyframes = keyframes
            keyframes[index].relativeTimestamp = relativeTimestamp
            keyframes[index].value = Double(value)
            keyframeSequence.wrappedValue = .double(keyframes)

        case let .cgfloat(keyframes):
            var keyframes = keyframes
            keyframes[index].relativeTimestamp = relativeTimestamp
            keyframes[index].value = value
            keyframeSequence.wrappedValue = .cgfloat(keyframes)

        case .color:
            fatalError("Unexpected keyframe type")
        }
    }

    var body: some View {
        GeometryReader { geometry in
            let width: CGFloat = geometry.size.width
            let height: CGFloat = geometry.size.height

            let controlPointSize = CGSize(width: 8, height: 8)

            ZStack(alignment: .topLeading) {
                Grid(width: width, height: height)
                Path { path in
                    guard
                        let firstValue = keyframeValues.first?.relativeValue,
                        let lastKeyframe = keyframeValues.last
                    else {
                        return
                    }

                    let firstOffset = offsetForKeyframe(id: 0)

                    path.move(
                        to: CGPoint(
                            x: 0,
                            y: (height - height * firstValue + firstOffset.height) // TODO: Adjust for value range
                                .clamped(in: 0...height)
                        )
                    )

                    for keyframe in keyframeValues {
                        let offset = offsetForKeyframe(id: keyframe.id)
                        path.addLine(
                            to: CGPoint(
                                x: keyframe.relativeTimestamp * width + offset.width,
                                y: (height - keyframe.relativeValue * height + offset.height)
                                    .clamped(in: 0...height)
                            )
                        )
                    }

                    if lastKeyframe.relativeTimestamp != 1 {
                        let lastOffset = offsetForKeyframe(id: lastKeyframe.id)
                        path.addLine(
                            to: CGPoint(
                                x: width,
                                y: (height - lastKeyframe.relativeValue * height + lastOffset.height)
                                    .clamped(in: 0...height)
                            )
                        )
                    }
                }
                .stroke(lineWidth: 2)
                ForEach(keyframeValues) { keyframe in
                    let inProgressOffset = offsetForKeyframe(id: keyframe.id)
                    let offsetX: CGFloat = keyframe.relativeTimestamp * width - controlPointSize.width / 2 + inProgressOffset.width
                    let offsetY: CGFloat = (height - keyframe.relativeValue * height - controlPointSize.height / 2 + inProgressOffset.height)
                        .clamped(in: (-controlPointSize.height / 2)...(height - controlPointSize.height / 2))
                    Circle()
                        .fill(Color.blue)
                        .frame(width: controlPointSize.width, height: controlPointSize.height, alignment: .center)
                        .offset(
                            x: offsetX,
                            y: offsetY
                        )
                        .simultaneousGesture(
                            DragGesture()
                                .onChanged { value in
                                    inProgressTranslation = (
                                        keyframe.id,
                                        CGSize(width: value.translation.width, height: value.translation.height)
                                    )
                                }
                                .onEnded { value in
                                    inProgressTranslation = nil

                                    let relativeTimestampDelta = (value.translation.width / geometry.size.width)
                                    let relativeTimestamp = (keyframe.relativeTimestamp + relativeTimestampDelta)
                                        .clamped(in: 0...1)

                                    let valueDelta = (-value.translation.height / geometry.size.height)
                                    let value = (keyframe.relativeValue + valueDelta) // TODO: Clamp

                                    updateKeyframe(at: keyframe.id, relativeTimestamp: relativeTimestamp, value: value)
                                }
                        )
                }
            }
        }
        .frame(height: 120)
    }

    struct Keyframe: Identifiable {

        var id: Int

        var relativeTimestamp: CGFloat

        var relativeValue: CGFloat

    }

}

struct Grid: View {

    init(width: CGFloat, height: CGFloat) {
        self.width = width
        self.height = height
    }

    let width: CGFloat
    let height: CGFloat

    var body: some View {
        Path { path in
            for y in stride(from: 0, through: height, by: height / 10) {
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: width, y: y))
            }
            for x in stride(from: 0, through: width, by: width / 10) {
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: height))
            }
        }
        .stroke(Color(white: 0.5), lineWidth: 0.5)
    }

}

struct ColorKeyframeChart: View {

    init(
        keyframeSequence: Binding<KeyframeSequence>
    ) {
        self.keyframeSequence = keyframeSequence

        switch keyframeSequence.wrappedValue {
        case let .color(keyframes):
            self._keyframes = State(wrappedValue: keyframes.map { keyframe in
                Keyframe(timestamp: CGFloat(keyframe.relativeTimestamp), color: keyframe.value.toCGColor())
            })

        default:
            fatalError()
        }
    }

    let keyframeSequence: Binding<KeyframeSequence>

    @State
    var keyframes: [Keyframe]

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                Path { path in
                    path.move(to: CGPoint(x: 0, y: geometry.size.height - 5))
                    path.addLine(to: CGPoint(x: geometry.size.width, y: geometry.size.height - 5))
                }
                .stroke(
                    LinearGradient(
                        stops: keyframes.map { keyframe in
                            Gradient.Stop(color: Color(keyframe.color), location: keyframe.timestamp)
                        },
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineWidth: 6
                )
                ForEach($keyframes) { keyframe in
                    ColorPicker(selection: keyframe.color) {}
                        .frame(width: 25, height: 25, alignment: .center)
                        .offset(
                            x: keyframe.timestamp.wrappedValue * geometry.size.width - 16,
                            y: 0
                        )
                    Rectangle()
                        .frame(width: 10, height: 10)
                        .rotationEffect(.degrees(45))
                        .offset(
                            x: keyframe.timestamp.wrappedValue * geometry.size.width - 5,
                            y: geometry.size.height - 10
                        )
                }
            }
        }
        .frame(height: 50)
        .onChange(of: keyframes) { keyframes in
            keyframeSequence.wrappedValue = .color(keyframes.map { keyframe in
                StageManagerPrimitives.Keyframe<RGBAColor>(
                    relativeTimestamp: Double(keyframe.timestamp),
                    value: RGBAColor(cgColor: keyframe.color)
                )
            })
        }
    }

    struct Keyframe: Identifiable, Equatable {

        var id: UUID = UUID()

        var timestamp: CGFloat

        var color: CGColor

    }

}

struct KeyframeSeriesView_Previews: PreviewProvider {

    @State
    static var series = colorKeyframeSeries

    static var previews: some View {
        KeyframeSeriesView(
            keyframeSeries: $series
        )
    }

    static var colorKeyframeSeries: AnimationBlueprint.ManagedKeyframeSeries = .init(
        id: UUID(),
        name: "Background Color",
        enabled: true,
        keyframeSequence: KeyframeSequence.color(
            [
                .init(relativeTimestamp: 0.0, value: RGBAColor(red: 1, green: 0, blue: 0, alpha: 1)),
                .init(relativeTimestamp: 0.5, value: RGBAColor(red: 1, green: 1, blue: 0, alpha: 1)),
                .init(relativeTimestamp: 1.0, value: RGBAColor(red: 0.5, green: 0, blue: 1, alpha: 1)),
            ]
        )
    )

    static var alphaKeyframeSeries: AnimationBlueprint.ManagedKeyframeSeries = .init(
        id: UUID(),
        name: "Alpha",
        enabled: true,
        keyframeSequence: KeyframeSequence.cgfloat(
            [
                .init(relativeTimestamp: 0.0, value: 0.5),
                .init(relativeTimestamp: 0.25, value: 0.0),
                .init(relativeTimestamp: 0.75, value: 1.0),
                .init(relativeTimestamp: 1.00, value: 0.5),
            ]
        )
    )

}

private extension Comparable {

    func clamped(min minValue: Self, max maxValue: Self) -> Self {
        return max(minValue, min(maxValue, self))
    }

    func clamped(in range: ClosedRange<Self>) -> Self {
        return clamped(min: range.lowerBound, max: range.upperBound)
    }

}
