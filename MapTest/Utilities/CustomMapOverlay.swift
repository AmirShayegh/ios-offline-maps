//
//  CustomMapOverlay.swift
//  MapTest
//
//  Created by Amir Shayegh on 2020-02-28.
//  Copyright © 2020 Amir Shayegh. All rights reserved.
//

import Foundation
import UIKit
import MapKit

// custom map overlays
class CustomMapOverlay: MKTileOverlay {
    
    // grabs the tile for the current x y z
    override func url(forTilePath path: MKTileOverlayPath) -> URL {
        if TileService.shared.tileExistsLocally(for: path) {
            // return local URL
            return TileService.shared.localPath(for: TileService.shared.fileName(for: path))
        } else {
            // Otherwise download and save if caching enabled
            if TileService.shared.cacheVisitedTiles {
                TileService.shared.downloadTile(for: path) { (success) in}
            }
            // let tileUrl = "https://tile.openstreetmap.org/\(path.z)/\(path.x)/\(path.y).png"
            let url = TileService.shared.getTileProviderURL(for: path)!
            return url
        }
    }
}
