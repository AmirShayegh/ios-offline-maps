//
//  Theme.swift
//  MapTest
//
//  Created by Amir Shayegh on 2020-03-05.
//  Copyright © 2020 Amir Shayegh. All rights reserved.
//

import Foundation
import UIKit

protocol Theme {}
extension Theme {
    
    func style(button: UIButton) {
        button.backgroundColor = Colors.primaryContrast
        button.layer.cornerRadius = 8
        button.tintColor = Colors.primary
        addShadow(to: button.layer, opacity: 1, height: 10)
    }
    
    public func style(segmentedControl: UISegmentedControl) {
        segmentedControl.selectedConfiguration(font: Fonts.regular(size: 16), color: .white)
        segmentedControl.defaultConfiguration(font: Fonts.regular(size: 16), color: Colors.primary)
    }
    
    private func styleButton(button: UIButton, bg: UIColor, borderColor: CGColor, titleColor: UIColor) {
        button.layer.cornerRadius = 5
        button.backgroundColor = bg
        button.layer.borderWidth = 1
        button.layer.borderColor = borderColor
        button.setTitleColor(titleColor, for: .normal)
    }
    
    // MARK: Colors
    // Gradiant UIView
    public func setGradiantBackground(view: UIView) {
        setGradientBackground(view: view, colorOne: UIColor(hex: "#0053A4"), colorTwo: UIColor(hex:"#002C71"));
    }
    
    // Gradiant Navbar
    public func setGradiantBackground(navigationBar: UINavigationBar) {
         navigationBar.setGradientBackground(colors: [UIColor(hex:"#002C71"), UIColor(hex: "#0053A4")], startPoint: .bottomRight, endPoint: .bottomLeft)
     }
    
    // Gradiant UIView with custom colors
    public func setGradientBackground(view: UIView, colorOne: UIColor, colorTwo: UIColor) {
        view.insertHorizontalGradient(colorTwo, colorOne)
    }
    
    public func addShadow(to layer: CALayer, opacity: Float, height: Int, radius: CGFloat? = 10) {
        layer.borderColor = UIColor(red:0.14, green:0.25, blue:0.46, alpha:0.2).cgColor
        layer.shadowOffset = CGSize(width: 0, height: height)
        layer.shadowColor = UIColor(red:0.14, green:0.25, blue:0.46, alpha:0.2).cgColor
        layer.shadowOpacity = opacity
        layer.shadowRadius = 10
    }
    
    // MARK: Circle
    // Circular view
    public func makeCircle(view: UIView) {
        view.layer.cornerRadius = view.frame.size.height/2
    }
    
    // Circular button
    public func makeCircle(button: UIButton) {
        makeCircle(layer: button.layer, height: button.bounds.height)
    }
    
    // Circular layer
    public func makeCircle(layer: CALayer, height: CGFloat) {
        layer.cornerRadius = height/2
    }
    
    // MARK: Contraints
    // Add Contraints to view to equal another
    public func addEqualSizeContraints(to toView: UIView, from fromView: UIView) {
        toView.translatesAutoresizingMaskIntoConstraints = false
        toView.heightAnchor.constraint(equalTo: fromView.heightAnchor, constant: 0).isActive = true
        toView.widthAnchor.constraint(equalTo: fromView.widthAnchor, constant: 0).isActive = true
        toView.leadingAnchor.constraint(equalTo: fromView.leadingAnchor, constant: 0).isActive = true
        toView.trailingAnchor.constraint(equalTo: fromView.trailingAnchor, constant: 0).isActive = true
    }
    
    // MARK: View & Layer
    public func roundCorners(layer: CALayer) {
        layer.cornerRadius = 8
    }
    
    public func styleCard(layer: CALayer) {
        roundCorners(layer: layer)
        addShadow(to: layer, opacity: 08, height: 2)
    }
    
    // MARK: ANIMATIONS
    public func fadeLabelMessage(label: UILabel, tempText: String, delay: Double? = 3, color: UIColor? = .black) {
        let defaultDelay: Double = 3
        let visibleAlpha: CGFloat = 1
        let invisibleAlpha: CGFloat = 0
        let originalText: String = label.text ?? ""
        let originalTextColor: UIColor = label.textColor
        // fade out current text
        UIView.animate(withDuration: 0.3, animations: {
            label.alpha = invisibleAlpha
            label.layoutIfNeeded()
        }) { (done) in
            // change text
            label.text = tempText
            // fade in warning text
            UIView.animate(withDuration: 0.3, animations: {
                label.textColor = color ?? .black
                label.alpha = visibleAlpha
                label.layoutIfNeeded()
            }, completion: { (done) in
                // revert after 3 seconds
                UIView.animate(withDuration: 0.3, delay: delay ?? defaultDelay, animations: {
                    // fade out text
                    label.alpha = invisibleAlpha
                    label.layoutIfNeeded()
                }, completion: { (done) in
                    // change text
                    label.text = originalText
                    // fade in text
                    UIView.animate(withDuration: 0.3, animations: {
                        label.textColor = originalTextColor
                        label.alpha = visibleAlpha
                        label.layoutIfNeeded()
                    })
                })
            })
        }
    }
}
