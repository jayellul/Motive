//
//  RequestTableViewCell.swift
//  wyd
//
//  Created by Jason Ellul on 2018-05-16.
//  Copyright © 2018 Jason Ellul. All rights reserved.
//

import UIKit

class RequestTableViewCell: UITableViewCell {
    
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
        label.font = UIFont.boldSystemFont(ofSize: 15.0)
        label.text = ""
        label.textAlignment = .left
        return label
    }()
    let usernameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = UIColor(red: 153/255, green: 153/255, blue: 153/255, alpha: 1.0)
        label.font = UIFont.systemFont(ofSize: 15.0)
        label.text = ""
        label.textAlignment = .left
        return label
    }()
    let acceptButton: LoadingButton = {
        let button = LoadingButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.cornerRadius = 5
        button.titleLabel?.font = UIFont.systemFont(ofSize: 15.0)
        button.setTitleColor(.white, for: .normal)
        button.setTitle("Accept", for: .normal)
        button.backgroundColor = UIColor(red: 51/255, green: 204/255, blue: 51/255, alpha: 1.0)
        return button
    }()
    let declineButton: LoadingButton = {
        let button = LoadingButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.cornerRadius = 5
        button.titleLabel?.font = UIFont.systemFont(ofSize: 15.0)
        button.setTitleColor(.white, for: .normal)
        button.setTitle("Decline", for: .normal)
        button.backgroundColor = UIColor(red: 255/255, green: 51/255, blue: 51/255, alpha: 1.0)
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

        print ("request: " + self.frame.size.width.description)
        addSubview(titleLabel)
        titleLabel.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 95).isActive = true
        titleLabel.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        titleLabel.widthAnchor.constraint(equalToConstant: self.frame.size.width - 270).isActive = true
        titleLabel.heightAnchor.constraint(equalToConstant: 30).isActive = true
        
        addSubview(usernameLabel)
        usernameLabel.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 95).isActive = true
        usernameLabel.centerYAnchor.constraint(equalTo: self.centerYAnchor, constant: 20).isActive = true
        usernameLabel.widthAnchor.constraint(equalToConstant: self.frame.size.width - 270).isActive = true
        usernameLabel.heightAnchor.constraint(equalToConstant: 20).isActive = true
        
        addSubview(declineButton)
        declineButton.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -10).isActive = true
        declineButton.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        declineButton.widthAnchor.constraint(equalToConstant: 60).isActive = true
        declineButton.heightAnchor.constraint(equalToConstant: 35).isActive = true
        
        addSubview(acceptButton)
        acceptButton.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -80).isActive = true
        acceptButton.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        acceptButton.widthAnchor.constraint(equalToConstant: 60).isActive = true
        acceptButton.heightAnchor.constraint(equalToConstant: 35).isActive = true        
        
        
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
