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
        .padding()
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
                .init(relativeTimestamp: 0.00, value: 0.5),
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
