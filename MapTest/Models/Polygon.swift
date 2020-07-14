//
//  Polygon.swift
//  MapTest
//
//  Created by Amir Shayegh on 2020-02-28.
//  Copyright © 2020 Amir Shayegh. All rights reserved.
//

import Foundation
import MapKit
import UIKit

// technically a model, but is kind of an extention to enable custom colors
// for separate polygons
class Polygon: MKPolygon {
    var color: UIColor = UIColor.black
}
