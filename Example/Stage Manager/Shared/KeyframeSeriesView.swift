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
            return keyframes.map { Keyframe(relativeTimestamp: CGFloat($0.relativeTimestamp), relativeValue: CGFloat($0.value)) }
        case let .cgfloat(keyframes):
            return keyframes.map { Keyframe(relativeTimestamp: CGFloat($0.relativeTimestamp), relativeValue: $0.value) }
        }
    }

    @State
    var inProgressTranslation: CGSize = .zero

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

                    path.move(
                        to: CGPoint(
                            x: 0,
                            y: height - height * firstValue // TODO: Adjust for value range
                        )
                    )

                    for keyframe in keyframeValues {
                        path.addLine(
                            to: CGPoint(
                                x: keyframe.relativeTimestamp * width,
                                y: height - keyframe.relativeValue * height
                            )
                        )
                    }

                    if lastKeyframe.relativeTimestamp != 1 {
                        path.addLine(to: CGPoint(x: width, y: height - lastKeyframe.relativeValue * height))
                    }
                }
                .stroke(lineWidth: 2)
                ForEach(keyframeValues) { keyframe in
                    let offsetX: CGFloat = keyframe.relativeTimestamp * width - controlPointSize.width / 2 + inProgressTranslation.width
                    let offsetY: CGFloat = height - keyframe.relativeValue * height - controlPointSize.height / 2 - inProgressTranslation.height
                    Circle()
                        .fill(Color.blue)
                        .frame(width: controlPointSize.width, height: controlPointSize.height, alignment: .center)
                        .offset(
                            x: offsetX,
                            y: offsetY
                        )
//                        .gesture(
//                            DragGesture()
//                                .onChanged { value in
//                                    inProgressTranslation = value.translation
//                                }
//                        )
                }
            }

        }
        .frame(height: 120)
    }

    struct Keyframe: Identifiable {

        var id: UUID = UUID()

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

struct KeyframeSeriesView_Previews: PreviewProvider {

    static var value = 0

    @State
    static var series: AnimationBlueprint.ManagedKeyframeSeries = .init(
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

    static var previews: some View {
        KeyframeSeriesView(
            keyframeSeries: $series
        )
    }
}
