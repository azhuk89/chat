//
//  UserTableViewCell.swift
//  Chat
//
//  Created by Alexandr Zhuk on 4/18/16.
//  Copyright © 2016 Alexandr Zhuk. All rights reserved.
//

import UIKit

class UserTableViewCell: UITableViewCell {

    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        let screenWidth = UIScreen.mainScreen().bounds.width
        contentView.frame = CGRectMake(0, 0, screenWidth, 100)
        
        profileImageView.center = CGPointMake(50, 50)
        profileImageView.layer.cornerRadius = 10
        profileImageView.clipsToBounds = true
        
        nameLabel.center = CGPointMake(120, 50)
        nameLabel.textAlignment = .Left
        nameLabel.bounds.size.width = screenWidth / 2
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
