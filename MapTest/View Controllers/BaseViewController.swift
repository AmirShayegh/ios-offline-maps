//
//  BaseViewController.swift
//  MapTest
//
//  Created by Amir Shayegh on 2020-03-05.
//  Copyright © 2020 Amir Shayegh. All rights reserved.
//

import UIKit

class BaseViewController: UIViewController, Theme {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setTabBarColor()
    }
    
    
    func setTabBarColor() {
        self.tabBarController?.tabBar.barTintColor = Colors.primaryContrast
        self.tabBarController?.tabBar.selectedImageTintColor = Colors.primary
        self.tabBarController?.tabBar.unselectedItemTintColor = Colors.inactive
    }
    
    func alert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func alert(title: String, message: String, yes: @escaping()-> Void, no: @escaping()-> Void) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Yes", style: UIAlertAction.Style.default, handler: { action in
            return yes();
        }))
        alert.addAction(UIAlertAction(title: "No", style: UIAlertAction.Style.cancel, handler: { action in
            return no();
        }))
        self.present(alert, animated: true, completion: nil)
    }
}
