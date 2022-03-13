//
//  GridView.swift
//  Stagehand
//
//  Created by Nick Entin on 3/11/22.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import SwiftUI

struct Grid: View {

    init(width: CGFloat, height: CGFloat, rows: Int = 10, columns: Int = 10) {
        self.width = width
        self.height = height
        self.rows = CGFloat(rows)
        self.columns = CGFloat(columns)
    }

    let width: CGFloat
    let height: CGFloat
    let rows: CGFloat
    let columns: CGFloat

    var body: some View {
        Path { path in
            for y in stride(from: 0, through: height, by: height / rows) {
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: width, y: y))
            }
            for x in stride(from: 0, through: width, by: width / columns) {
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: height))
            }
        }
        .stroke(Color(white: 0.5), lineWidth: 0.5)
    }

}
