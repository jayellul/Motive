//
//  UserTableViewCell.swift
//  wyd
//
//  Created by Jason Ellul on 2018-05-16.
//  Copyright © 2018 Jason Ellul. All rights reserved.
//

import UIKit


class UserTableViewCell: UITableViewCell {

    let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius =  35
        // fix pathing
        imageView.image = UIImage(named: "Images/default user icon.png")
        return imageView
    }()
    let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = UIColor.black
        label.font = UIFont.boldSystemFont(ofSize: 15.0)
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
    
    // show if not on current user's friend list
    let followButton: LoadingButton = {
        let button = LoadingButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitleColor(UIColor.white, for: .normal)
        button.setTitle("Follow", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 15.0)
        button.layer.borderWidth = 0
        button.layer.borderColor = UIColor(red: 242/255, green: 242/255, blue: 242/255, alpha: 1.0).cgColor
        button.layer.cornerRadius = 5
        button.backgroundColor = UIColor(red: 51/255, green: 204/255, blue: 51/255, alpha: 1.0)
        return button
    }()
    // show if already an existing friend
    let followingButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitleColor(UIColor.black, for: .normal)
        button.setTitle("Following", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 15.0)
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor(red: 242/255, green: 242/255, blue: 242/255, alpha: 1.0).cgColor
        button.isUserInteractionEnabled = false
        button.layer.cornerRadius = 5
        button.backgroundColor = UIColor.white
        return button
    }()
    
    let loadingButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitleColor(UIColor.black, for: .normal)
        button.setTitle("Loading", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 15.0)
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor(red: 242/255, green: 242/255, blue: 242/255, alpha: 1.0).cgColor
        button.layer.cornerRadius = 5
        button.backgroundColor = UIColor.white
        
        return button
    }()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        setupSubviews()

    }
    
    func setupSubviews() {
        // setup subviews in cell
        self.addSubview(profileImageView)
        profileImageView.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 10).isActive = true
        profileImageView.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        profileImageView.widthAnchor.constraint(equalToConstant: 70).isActive = true
        profileImageView.heightAnchor.constraint(equalToConstant: 70).isActive = true
        
        self.addSubview(titleLabel)
        titleLabel.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 95).isActive = true
        titleLabel.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        titleLabel.widthAnchor.constraint(equalToConstant: self.frame.size.width - 255).isActive = true
        titleLabel.heightAnchor.constraint(equalToConstant: 30).isActive = true
        
        self.addSubview(usernameLabel)
        usernameLabel.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 95).isActive = true
        usernameLabel.centerYAnchor.constraint(equalTo: self.centerYAnchor, constant: 20).isActive = true
        usernameLabel.widthAnchor.constraint(equalToConstant: self.frame.size.width - 255).isActive = true
        usernameLabel.heightAnchor.constraint(equalToConstant: 20).isActive = true
        
        self.addSubview(loadingButton)
        loadingButton.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -20).isActive = true
        loadingButton.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        loadingButton.widthAnchor.constraint(equalToConstant: 100).isActive = true
        loadingButton.heightAnchor.constraint(equalToConstant: 35).isActive = true
        

    }
    
    func setupAlreadyFollowingButton() {
        loadingButton.removeFromSuperview()
        followButton.removeFromSuperview()
        addSubview(followingButton)
        followingButton.setTitle("Following", for: .normal)
        followingButton.rightAnchor.constraint(equalTo: rightAnchor, constant: -20).isActive = true
        followingButton.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        followingButton.widthAnchor.constraint(equalToConstant: 100).isActive = true
        followingButton.heightAnchor.constraint(equalToConstant: 35).isActive = true
        followingButton.isUserInteractionEnabled = false
    }
    
    func setupRequestSentButton() {
        loadingButton.removeFromSuperview()
        followButton.removeFromSuperview()
        addSubview(followingButton)
        followingButton.setTitle("Request Sent", for: .normal)
        followingButton.rightAnchor.constraint(equalTo: rightAnchor, constant: -20).isActive = true
        followingButton.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        followingButton.widthAnchor.constraint(equalToConstant: 100).isActive = true
        followingButton.heightAnchor.constraint(equalToConstant: 35).isActive = true
        followingButton.isUserInteractionEnabled = true
    }
    
    func setupFollowButton() {
        loadingButton.removeFromSuperview()
        followingButton.removeFromSuperview()
        addSubview(followButton)
        followButton.rightAnchor.constraint(equalTo: rightAnchor, constant: -20).isActive = true
        followButton.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        followButton.widthAnchor.constraint(equalToConstant: 100).isActive = true
        followButton.heightAnchor.constraint(equalToConstant: 35).isActive = true
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
    
    override func prepareForReuse() {
        super.prepareForReuse()
        // make everything nil because of reuse bugs
        titleLabel.text = nil
        usernameLabel.text = nil
        profileImageView.image = nil
        followButton.removeFromSuperview()
        followingButton.removeFromSuperview()
    }
    

}
