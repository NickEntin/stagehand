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

    var keyframeValues: [(CGFloat, CGFloat)] {
        switch keyframeSequence.wrappedValue {
        case let .double(keyframes):
            return keyframes.map { (CGFloat($0.relativeTimestamp), CGFloat($0.value)) }
        case let .cgfloat(keyframes):
            return keyframes.map { (CGFloat($0.relativeTimestamp), $0.value) }
        }
    }

    var body: some View {
        GeometryReader { geometry in
            let width: CGFloat = geometry.size.width
            let height: CGFloat = geometry.size.height

            ZStack {
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
                Path { path in
                    guard
                        let firstValue = keyframeValues.first?.1,
                        let (lastTimestamp, lastValue) = keyframeValues.last
                    else {
                        return
                    }

                    path.move(
                        to: CGPoint(
                            x: 0,
                            y: height * firstValue // TODO: Adjust for value range
                        )
                    )

                    for (timestamp, value) in keyframeValues {
                        path.addLine(
                            to: CGPoint(
                                x: timestamp * width,
                                y: value * height
                            )
                        )
                    }

                    if lastTimestamp != 1 {
                        path.addLine(to: CGPoint(x: width, y: lastValue * height))
                    }
                }
                .stroke(lineWidth: 2)
            }

        }
        .frame(height: 120)
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
