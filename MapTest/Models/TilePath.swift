//
//  TilePath.swift
//  MapTest
//
//  Created by Amir Shayegh on 2020-02-28.
//  Copyright © 2020 Amir Shayegh. All rights reserved.
//

import Foundation
import MapKit

class TilePath {
    var root: MKTileOverlayPath
    var subTiles: [TilePath] = [TilePath]()
    init(root: MKTileOverlayPath) {
        self.root = root
    }
}
