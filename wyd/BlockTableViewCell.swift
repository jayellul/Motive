//
//  BlockTableViewCell.swift
//  wyd
//
//  Created by Jason Ellul on 2018-06-06.
//  Copyright © 2018 Jason Ellul. All rights reserved.
//

import UIKit

class BlockTableViewCell: UITableViewCell {
    
    let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius =  35
        // fix pathing to have default image
        return imageView
    }()
    let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = UIColor.black
        label.font = UIFont.systemFont(ofSize: 20.0)
        label.text = "Username"
        label.textAlignment = .left
        return label
    }()
    let usernameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = UIColor(red: 153/255, green: 153/255, blue: 153/255, alpha: 1.0)
        label.font = UIFont.systemFont(ofSize: 15.0)
        label.text = "Email"
        label.textAlignment = .left
        return label
    }()
    let unblockButton: LoadingButton = {
        let button = LoadingButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.cornerRadius = 5
        button.titleLabel?.font = UIFont.systemFont(ofSize: 15.0)
        button.setTitleColor(.black, for: .normal)
        button.setTitle("Unblock", for: .normal)
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor(red: 242/255, green: 242/255, blue: 242/255, alpha: 1.0).cgColor
        button.layer.cornerRadius = 5
        button.backgroundColor = UIColor.white
        return button
    }()

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        addSubview(profileImageView)
        profileImageView.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 10).isActive = true
        profileImageView.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        profileImageView.widthAnchor.constraint(equalToConstant: 70).isActive = true
        profileImageView.heightAnchor.constraint(equalToConstant: 70).isActive = true

        addSubview(usernameLabel)
        usernameLabel.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 95).isActive = true
        usernameLabel.centerYAnchor.constraint(equalTo: self.centerYAnchor, constant: 20).isActive = true
        usernameLabel.widthAnchor.constraint(equalToConstant: self.frame.size.width - 200).isActive = true
        usernameLabel.heightAnchor.constraint(equalToConstant: 20).isActive = true

        addSubview(titleLabel)
        titleLabel.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 95).isActive = true
        titleLabel.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        titleLabel.widthAnchor.constraint(equalToConstant: self.frame.size.width - 200).isActive = true
        titleLabel.heightAnchor.constraint(equalToConstant: 30).isActive = true
        
        addSubview(unblockButton)
        unblockButton.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -20).isActive = true
        unblockButton.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        unblockButton.widthAnchor.constraint(equalToConstant: 100).isActive = true
        unblockButton.heightAnchor.constraint(equalToConstant: 35).isActive = true
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    /*override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        
    }*/

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    

}
