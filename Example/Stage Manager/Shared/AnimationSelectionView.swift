//
//  AnimationSelectionView.swift
//  Stagehand
//
//  Created by Nick Entin on 2/6/22.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import Memo
import StageManagerPrimitives
import SwiftUI

struct AnimationSelectionView: View {

    init(transceiver: Memo.Transceiver) {
        self.transceiver = Transceiver(memoTransceiver: transceiver)
    }

    @ObservedObject
    var transceiver: Transceiver

    var body: some View {
        #if os(iOS)
        switch UIDevice.current.userInterfaceIdiom {
        case .pad, .mac:
            list.listStyle(SidebarListStyle())
        case .phone:
            list.listStyle(InsetGroupedListStyle())
        default:
            fatalError("Unexpected user interface idiom")
        }
        #else
        list.listStyle(SidebarListStyle())
        #endif
    }

    var list: some View {
        List {
            Section(
                header: Text("Animations")
                    .font(.headline)
            ) {
                ForEach(transceiver.managedAnimations) { animation in
                    NavigationLink {
                        AnimationDetailsView(
                            animation: animation.blueprint,
                            transceiver: transceiver,
                            blueprintForID: { id in
                                return transceiver.managedAnimations
                                    .first(where: { $0.blueprint.id == id })?
                                    .blueprint
                            }
                        )
                    } label: {
                        Text(animation.displayName)
                    }
                }
            }
            Section(
                header: Text("Curves")
                    .font(.headline)
            ) {
                ForEach(transceiver.managedCurves) { curve in
                    NavigationLink {
                        CurveDetailsView(
                            curve: curve.curve,
                            transceiver: transceiver
                        )
                    } label: {
                        Text(curve.displayName)
                    }
                }
            }
        }
        .frame(minWidth: 200)
    }

}

struct ManagedAnimationModel: Identifiable {

    var id: Token<SerializableAnimationBlueprint>

    var displayName: String

    var blueprint: SerializableAnimationBlueprint

}

struct ManagedCurveModel: Identifiable {

    var id: Token<SerializableCubicBezierAnimationCurve>

    var displayName: String

    var curve: SerializableCubicBezierAnimationCurve

}
