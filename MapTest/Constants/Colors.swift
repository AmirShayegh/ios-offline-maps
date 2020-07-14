//
//  Colors.swift
//  MapTest
//
//  Created by Amir Shayegh on 2020-03-05.
//  Copyright © 2020 Amir Shayegh. All rights reserved.
//

import Foundation
import UIKit
import Extended

class Colors {
    
    private static let blueLight: UIColor =  UIColor(hex: "0C57A8")
    private static let white: UIColor = UIColor.white
    
    private static let blueDark: UIColor = UIColor(hex: "0D3E73")
    
    public static let primary: UIColor = {
        if #available(iOS 13, *) {
            return UIColor { (UITraitCollection: UITraitCollection) -> UIColor in
                if UITraitCollection.userInterfaceStyle == .dark {
                    return Colors.white
                } else {
                    return Colors.blueLight
                }
            }
        } else {
            return Colors.blueLight
        }
    }()
    
    static let primaryContrast: UIColor = {
        if #available(iOS 13, *) {
            return UIColor { (UITraitCollection: UITraitCollection) -> UIColor in
                if UITraitCollection.userInterfaceStyle == .dark {
                    return UIColor.black
                } else {
                    return Colors.white
                }
            }
        } else {
            return Colors.white
        }
    }()
    
    static let inactive: UIColor = {
        if #available(iOS 13, *) {
            return UIColor { (UITraitCollection: UITraitCollection) -> UIColor in
                if UITraitCollection.userInterfaceStyle == .dark {
                    return UIColor.gray
                } else {
                    return UIColor.lightGray
                }
            }
        } else {
            return UIColor.lightGray
        }
    }()
    
}
