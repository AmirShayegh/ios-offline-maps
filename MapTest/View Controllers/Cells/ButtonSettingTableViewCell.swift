//
//  ButtonSettingTableViewCell.swift
//  MapTest
//
//  Created by Amir Shayegh on 2020-03-05.
//  Copyright © 2020 Amir Shayegh. All rights reserved.
//

import UIKit

class ButtonSettingTableViewCell: UITableViewCell {

    @IBOutlet weak var bottomDivider: UIView!
    @IBOutlet weak var button: UIButton!
    
    var onClick: (()-> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        style()
    }
    
    @IBAction func buttonAction(_ sender: UIButton) {
        guard let callback = onClick else {return}
        return callback()
    }
    
    func setup(name: String, icon: String, onClick: (()-> Void)? = nil) {
        self.onClick = onClick
        button.setTitle(name, for: .normal)
        if let icon = UIImage(systemName: icon) {
            button.setImage(icon, for: .normal)
        }
        style()
    }
    
    func style() {
        button.tintColor = Colors.primaryContrast
        button.backgroundColor = Colors.primary
        button.layer.cornerRadius = 9
        bottomDivider.backgroundColor = Colors.inactive.withAlphaComponent(0.4)
    }
}
