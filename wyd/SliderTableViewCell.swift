//
//  SliderTableViewCell.swift
//  wyd
//
//  Created by Jason Ellul on 2018-08-02.
//  Copyright © 2018 Jason Ellul. All rights reserved.
//

import UIKit

class SliderTableViewCell: UITableViewCell {
    
    // image of icon
    let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.cornerRadius = 5
        return imageView
    }()
    // text of cell
    let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = UIColor.black
        label.font = UIFont.systemFont(ofSize: 18.0)
        label.text = ""
        label.textAlignment = .left
        return label
    }()
    // text of cell
    let detailLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = UIColor(red: 153/255, green: 153/255, blue: 153/255, alpha: 1.0)
        label.font = UIFont.systemFont(ofSize: 18.0)
        label.text = ""
        label.textAlignment = .right
        return label
    }()
    
    lazy var titleLabelLeftConstraint = titleLabel.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 70)
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        addSubview(iconImageView)
        iconImageView.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 25).isActive = true
        iconImageView.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        iconImageView.widthAnchor.constraint(equalToConstant: 25).isActive = true
        iconImageView.heightAnchor.constraint(equalToConstant: 25).isActive = true

        addSubview(titleLabel)
        titleLabelLeftConstraint.isActive = true
        titleLabel.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        titleLabel.widthAnchor.constraint(equalToConstant: self.frame.size.width - 150).isActive = true
        titleLabel.heightAnchor.constraint(equalToConstant: 30).isActive = true
        
    }

    override func layoutSubviews() {
        super.layoutSubviews()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
        if selected {
            self.backgroundColor = UIColor(red: 230/255, green: 230/255, blue: 230/255, alpha: 1.0)
        }
    }
    
    func setupFriendRequestBadge(badgeText: Int) {
        // declare text and fit to size
        let text = UILabel(frame: CGRect(x: 0, y: 0, width: 25, height: 25))
        text.textAlignment = .center
        text.font = UIFont.boldSystemFont(ofSize: 18)
        text.textColor = UIColor.white
        text.text = String(badgeText)
        text.adjustsFontSizeToFitWidth = true

        // add circle to cell
        let circle = UIView(frame: CGRect(x: 0, y: 0, width: 25, height: 25))
        circle.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(circle)
        circle.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 25).isActive = true
        circle.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        circle.widthAnchor.constraint(equalToConstant: 25).isActive = true
        circle.heightAnchor.constraint(equalToConstant: 25).isActive = true
        circle.layer.cornerRadius = 12.5
        circle.layer.masksToBounds = true
        circle.backgroundColor = UIColor(red: 255/255, green: 153/255, blue: 51/255, alpha: 1.0)
        // add text to circle and set contraints
        circle.addSubview(text)
        text.centerXAnchor.constraint(equalTo: circle.centerXAnchor).isActive = true
        text.centerYAnchor.constraint(equalTo: circle.centerYAnchor).isActive = true

    }
    
    func setupDetailLabel() {
        titleLabel.sizeToFit()
        self.addSubview(detailLabel)
        detailLabel.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -35).isActive = true
        detailLabel.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        detailLabel.widthAnchor.constraint(equalToConstant: self.frame.size.width - 75 - titleLabel.frame.width).isActive = true
        detailLabel.heightAnchor.constraint(equalToConstant: 30).isActive = true
        
    }
    
    

}
