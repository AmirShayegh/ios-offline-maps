//
//  BasicSettingTableViewCell.swift
//  MapTest
//
//  Created by Amir Shayegh on 2020-03-05.
//  Copyright © 2020 Amir Shayegh. All rights reserved.
//

import UIKit

class BasicSettingTableViewCell: UITableViewCell {
    
    @IBOutlet weak var bottomDivider: UIView!
    @IBOutlet weak var valueLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var iconImageView: UIImageView!
    
    var onClick: (()-> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
        style()
    }
    
    func setup(name: String, icon: String, value: String? = "", onClick: (()-> Void)? = nil) {
        self.onClick = onClick
        nameLabel.text = name
        valueLabel.text = value
        if let icon = UIImage(systemName: icon) {
            iconImageView.image = icon
        } else {
            iconImageView.image = UIImage(systemName: "questionmark")
        }
        style()
    }
    
    func style() {
        iconImageView.tintColor = Colors.primary
        nameLabel.textColor = Colors.primary
        valueLabel.textColor = Colors.primary
        bottomDivider.backgroundColor = Colors.inactive.withAlphaComponent(0.4)
    }
    
}
