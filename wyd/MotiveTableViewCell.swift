//
//  UserTableViewCell.swift
//  wyd
//
//  Created by Jason Ellul on 2018-05-16.
//  Copyright © 2018 Jason Ellul. All rights reserved.
//

import UIKit
import Firebase
import SDWebImage

private let starFill = #imageLiteral(resourceName: "starFill.png")
private let starUnfill = #imageLiteral(resourceName: "starUnfill.png")
private let commentImage = #imageLiteral(resourceName: "speech bubble.png")

class MotiveTableViewCell: UITableViewCell {
    // firebase refs
    static let kMotivesListPath = "motives"
    let motivesReference = Database.database().reference(withPath: kMotivesListPath)
    static let kMotivesGoingListPath = "motivesGoing"
    let motivesGoingReference = Database.database().reference(withPath: kMotivesGoingListPath)
    static let kUsersGoingListPath = "usersGoing"
    let usersGoingReference = Database.database().reference(withPath: kUsersGoingListPath)
    static let kUsersListPath = "users"
    let usersReference = Database.database().reference(withPath: kUsersListPath)
    lazy var functions = Functions.functions()
    
    var motiveAndUser: MotiveAndUser?
    var cellViewDelegate: CalloutViewDelegate?

    // user ui components
    let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.masksToBounds = true;
        imageView.layer.cornerRadius =  25
        return imageView
    }()
    let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = true
        label.textColor = UIColor.black
        label.font = UIFont.boldSystemFont(ofSize: 16.0)
        label.text = ""
        label.textAlignment = .left
        return label
    }()
    // motive ui components
    let timeLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = true
        label.textColor = UIColor(red: 153/255, green: 153/255, blue: 153/255, alpha: 1.0)
        label.font = UIFont.systemFont(ofSize: 16.0)
        label.text = ""
        label.textAlignment = .right
        return label
    }()
    
    let motiveTextLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = UIColor.black
        label.font = UIFont.systemFont(ofSize: 16.0)
        label.text = ""
        label.textAlignment = .left
        return label
    }()
    
    let commentsLabel: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14.0)
        button.setTitleColor(UIColor(red: 153/255, green: 153/255, blue: 153/255, alpha: 1.0), for: .normal)
        button.setTitle("", for: .normal)
        button.backgroundColor = UIColor.clear
        button.contentHorizontalAlignment = .left
        //button.backgroundColor = UIColor.cyan
        return button
    }()
    
    lazy var commentsLabelWidthConstraint = commentsLabel.widthAnchor.constraint(equalToConstant: 80)
    
    let goingLabel: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14.0)
        button.setTitleColor(UIColor(red: 153/255, green: 153/255, blue: 153/255, alpha: 1.0), for: .normal)
        button.setTitleColor(UIColor(red: 153/255, green: 153/255, blue: 153/255, alpha: 1.0), for: .highlighted)
        button.setTitle("", for: .normal)
        button.backgroundColor = UIColor.clear
        button.contentHorizontalAlignment = .left
        //button.backgroundColor = UIColor.cyan
        return button
    }()
    
    lazy var goingLabelWidthConstraint = goingLabel.widthAnchor.constraint(equalToConstant: 80)
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        setupSubviews()

    }
    
    // called in feed after self.creator is set
    func setupSubviews() {
        // setup subviews in cell
        self.addSubview(profileImageView)
        profileImageView.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 10).isActive = true
        profileImageView.topAnchor.constraint(equalTo: self.topAnchor, constant: 10).isActive = true
        profileImageView.widthAnchor.constraint(equalToConstant: 50).isActive = true
        profileImageView.heightAnchor.constraint(equalToConstant: 50).isActive = true
        // turn profile image into a button
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(profileImageTapped(_:)))
        profileImageView.isUserInteractionEnabled = true
        profileImageView.addGestureRecognizer(tapGestureRecognizer)
        
        // comments Label into button
        let tapCommentsGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(commentsTapped(_:)))
        commentsLabel.isUserInteractionEnabled = true
        commentsLabel.addGestureRecognizer(tapCommentsGestureRecognizer)
        
        titleLabel.frame = CGRect(x: 70, y: 12, width: self.frame.width - 145, height: 20)
        self.addSubview(titleLabel)

        timeLabel.frame = CGRect(x: self.frame.width, y: 12, width: 50, height: 20)
        self.addSubview(timeLabel)
        
        self.addSubview(motiveTextLabel)
        motiveTextLabel.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 70).isActive = true
        motiveTextLabel.topAnchor.constraint(equalTo: self.topAnchor, constant: 32).isActive = true
        motiveTextLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -40).isActive = true
        motiveTextLabel.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -20).isActive = true
        motiveTextLabel.numberOfLines = 0
        
        self.addSubview(commentsLabel)
        commentsLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: 0).isActive = true
        commentsLabel.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 70).isActive = true
        commentsLabelWidthConstraint.isActive = true
        commentsLabel.heightAnchor.constraint(equalToConstant: 30).isActive = true
    
        self.addSubview(goingLabel)
        goingLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: 0).isActive = true
        // constant align star with center
        goingLabel.leftAnchor.constraint(equalTo: self.centerXAnchor, constant: -7).isActive = true
        goingLabelWidthConstraint.isActive = true
        goingLabel.heightAnchor.constraint(equalToConstant: 30).isActive = true
        // set comments title
        commentsLabel.setImage(resizeImage(image: commentImage, targetSize: CGSize(width: 14, height: 15)).imageWithInset(insets: UIEdgeInsetsMake(1, 0, -1, 0)), for: .normal)
        commentsLabel.setImage(resizeImage(image: commentImage, targetSize: CGSize(width: 14, height: 15)).imageWithInset(insets: UIEdgeInsetsMake(1, 0, -1, 0)), for: .highlighted)
        commentsLabel.setTitle(" " + String(0), for: .normal)
        
        goingLabel.setTitle(" " + String(0), for: .normal)
        

    }

    
    // function if the user is already going to this motive
    func setupUserGoing() {
        // change button image
        let starFillImage = resizeImage(image: starFill, targetSize: CGSize(width: 15, height: 15))
        goingLabel.setImage(starFillImage, for: .normal)
        goingLabel.setImage(starFillImage, for: .highlighted)
        // set title color
        goingLabel.setTitleColor(UIColor(red:1.00, green:0.60, blue:0.20, alpha:1.0), for: .normal)
        goingLabel.setTitleColor(UIColor(red:1.00, green:0.60, blue:0.20, alpha:1.0), for: .highlighted)
        // change action
        goingLabel.removeTarget(self, action: #selector(goingLabelTapped(_:)), for: .touchUpInside)
        goingLabel.addTarget(self, action: #selector(ungoingLabelTapped(_:)), for: .touchUpInside)
    }
    
    func setupUserNotGoing() {
        // set images and text back to grey
        let starOutlineImage = resizeImage(image: starUnfill, targetSize: CGSize(width: 15, height: 15))
        goingLabel.setImage(resizeImage(image: starOutlineImage, targetSize: CGSize(width: 15, height: 15)), for: .normal)
        goingLabel.setImage(resizeImage(image: starOutlineImage, targetSize: CGSize(width: 15, height: 15)), for: .highlighted)
        // set title color
        goingLabel.setTitleColor(UIColor(red: 153/255, green: 153/255, blue: 153/255, alpha: 1.0), for: .normal)
        goingLabel.setTitleColor(UIColor(red: 153/255, green: 153/255, blue: 153/255, alpha: 1.0), for: .highlighted)
        // set target back to normal
        goingLabel.removeTarget(self, action: #selector(ungoingLabelTapped(_:)), for: .touchUpInside)
        goingLabel.addTarget(self, action: #selector(goingLabelTapped(_:)), for: .touchUpInside)
    }
    
    @objc func goingLabelTapped(_ sender: Any) {
        guard let motiveAndUser = self.motiveAndUser else { return }
        guard let uid = Auth.auth().currentUser?.uid else { return }
        var motive = motiveAndUser.motive
        // add user to motivesGoing firebase
        let timestamp = Int64(NSDate().timeIntervalSince1970 * -1000)
        // set value to time in going so user can see most recently going - also triggers backend count function
        motivesGoingReference.child(motive.id).child(uid).setValue(timestamp)
        // set value to true in inverted index to save space
        usersGoingReference.child(uid).child(motive.id).setValue(timestamp)
        // animate star fill
        let starFillImage = resizeImage(image: starFill, targetSize: CGSize(width: 15, height: 15))
        let expandTransform: CGAffineTransform = CGAffineTransform(scaleX: 1.5, y: 1.5)
        UIView.animate(withDuration: 0.1, delay: 0.0, options: .transitionCrossDissolve, animations: {
            self.goingLabel.setImage(starFillImage, for: .normal)
            self.goingLabel.setImage(starFillImage, for: .highlighted)
        }) { (completion) in
            // add springy transform
            // https://stackoverflow.com/questions/2834573/how-to-animate-the-change-of-image-in-an-uiimageview
            UIView.animate(withDuration: 1.2, delay: 0.0, usingSpringWithDamping: 0.25, initialSpringVelocity: 0.25, options: .curveEaseOut, animations: {
                self.goingLabel.imageView?.transform = expandTransform.inverted()
            }) { (completion) in
                self.goingLabel.imageView?.transform = CGAffineTransform.identity
            }
        }
        // set title color
        goingLabel.setTitleColor(UIColor(red:1.00, green:0.60, blue:0.20, alpha:1.0), for: .normal)
        goingLabel.setTitleColor(UIColor(red:1.00, green:0.60, blue:0.20, alpha:1.0), for: .highlighted)
        // change motive object
        motive.numGoing = motive.numGoing + 1
        if motive.numGoing < 0 {
            motive.numGoing = 0
        }
        motiveAndUser.motive = motive
        // change text
        goingLabel.setTitle(" " + String(motive.numGoing), for: .normal)
        goingLabel.setTitle(" " + String(motive.numGoing), for: .highlighted)
        // add to tab bar in map view
        cellViewDelegate?.goingPressed(motive: motive)
        // make http call
        functions.httpsCallable("countGoing").call(["id": motive.id, "creator": motive.creator, "name": motiveAndUser.user.username]) { (result, error) in
            if let error = error as NSError? {
                if error.domain == FunctionsErrorDomain {
                    let message = error.localizedDescription
                    print (message)
                }
            } else if let numGoing = (result?.data as? [String: Any])?["num"] as? Int {
                print (numGoing)
                self.motivesReference.child(motive.id).child("numGoing").setValue(numGoing)
            }
        }
        // change action
        goingLabel.removeTarget(self, action: #selector(goingLabelTapped(_:)), for: .touchUpInside)
        goingLabel.addTarget(self, action: #selector(ungoingLabelTapped(_:)), for: .touchUpInside)
    }
    // when the user un goes to a motive
    @objc func ungoingLabelTapped(_ sender: Any) {
        guard let motiveAndUser = self.motiveAndUser else { return }
        guard let uid = Auth.auth().currentUser?.uid else { return }
        var motive = motiveAndUser.motive
        // remove from motives going - also triggers backend write function
        motivesGoingReference.child(motive.id).child(uid).removeValue()
        // remove from users going
        usersGoingReference.child(uid).child(motive.id).removeValue()
        // set images and text back to grey
        let starOutlineImage = resizeImage(image: starUnfill, targetSize: CGSize(width: 15, height: 15))
        goingLabel.setImage(resizeImage(image: starOutlineImage, targetSize: CGSize(width: 15, height: 15)), for: .normal)
        goingLabel.setImage(resizeImage(image: starOutlineImage, targetSize: CGSize(width: 15, height: 15)), for: .highlighted)
        goingLabel.setTitleColor(UIColor(red: 153/255, green: 153/255, blue: 153/255, alpha: 1.0), for: .normal)
        goingLabel.setTitleColor(UIColor(red: 153/255, green: 153/255, blue: 153/255, alpha: 1.0), for: .highlighted)
        // change motive object
        motive.numGoing = motive.numGoing - 1
        if motive.numGoing < 0 {
            motive.numGoing = 0
        }
        motiveAndUser.motive = motive
        // change text
        goingLabel.setTitle(" " + String(motive.numGoing), for: .normal)
        goingLabel.setTitle(" " + String(motive.numGoing), for: .highlighted)
        // add to tab bar in map view
        cellViewDelegate?.unGoPressed(motive: motive)
        // make http call
        functions.httpsCallable("countGoing").call(["id": motive.id, "creator": motive.creator, "name": motiveAndUser.user.username]) { (result, error) in
            if let error = error as NSError? {
                if error.domain == FunctionsErrorDomain {
                    let message = error.localizedDescription
                    print (message)
                }
            } else if let numGoing = (result?.data as? [String: Any])?["num"] as? Int {
                print (numGoing)
                self.motivesReference.child(motive.id).child("numGoing").setValue(numGoing)
            }
        }
        // set target back to normal
        goingLabel.removeTarget(self, action: #selector(ungoingLabelTapped(_:)), for: .touchUpInside)
        goingLabel.addTarget(self, action: #selector(goingLabelTapped(_:)), for: .touchUpInside)
        
    }
    
    @objc func profileImageTapped(_ sender: Any) {
        guard let motiveAndUser = self.motiveAndUser else { return }
        cellViewDelegate?.profileImagePressed(user: motiveAndUser.user)
    }
    
    @objc func commentsTapped (_ sender: Any) {
        guard let motiveAndUser = self.motiveAndUser else { return }
        cellViewDelegate?.commentsPressed(motive: motiveAndUser.motive)

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
        /* self.titleLabel.text = nil
        self.usernameLabel.text = nil
        self.profileImageView.image = nil
         */
    }
    
    // resize image function
    // https://stackoverflow.com/questions/31314412/how-to-resize-image-in-swift
    func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        // Figure out what our orientation is, and use that to form the rectangle
        var newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
        }
        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }

    

}

// table view cell for table in comment View Controller
class CommentTableViewCell: UITableViewCell {

    var commentAndUser: CommentAndUser?
    var cellViewDelegate: CalloutViewDelegate?

    // user ui components
    let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.masksToBounds = true;
        imageView.layer.cornerRadius =  20
        return imageView
    }()
    let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = true
        label.textColor = UIColor.black
        label.font = UIFont.boldSystemFont(ofSize: 16.0)
        label.text = ""
        label.textAlignment = .left
        return label
    }()
    // comment ui components
    let timeLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = true
        label.textColor = UIColor(red: 153/255, green: 153/255, blue: 153/255, alpha: 1.0)
        label.font = UIFont.systemFont(ofSize: 16.0)
        label.text = ""
        label.textAlignment = .right
        return label
    }()
    
    let commentTextLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = UIColor.black
        label.font = UIFont.systemFont(ofSize: 16.0)
        label.text = ""
        label.textAlignment = .left
        return label
    }()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        setupSubviews()
        
    }
    
    // called in feed after self.creator is set
    func setupSubviews() {
        // setup subviews in cell
        self.addSubview(profileImageView)
        profileImageView.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 10).isActive = true
        profileImageView.topAnchor.constraint(equalTo: self.topAnchor, constant: 10).isActive = true
        profileImageView.widthAnchor.constraint(equalToConstant: 40).isActive = true
        profileImageView.heightAnchor.constraint(equalToConstant: 40).isActive = true
        // turn profile image into a button
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(profileImageTapped(_:)))
        profileImageView.isUserInteractionEnabled = true
        profileImageView.addGestureRecognizer(tapGestureRecognizer)
        
        titleLabel.frame = CGRect(x: 60, y: 12, width: self.frame.width - 145, height: 20)
        self.addSubview(titleLabel)
        
        timeLabel.frame = CGRect(x: self.frame.width - 60, y: 12, width: 50, height: 20)
        self.addSubview(timeLabel)
        
        self.addSubview(commentTextLabel)
        commentTextLabel.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 60).isActive = true
        commentTextLabel.topAnchor.constraint(equalTo: self.topAnchor, constant: 34).isActive = true
        commentTextLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -30).isActive = true
        commentTextLabel.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -20).isActive = true
        commentTextLabel.numberOfLines = 0
    }
    
   
    @objc func profileImageTapped(_ sender: Any) {
        guard let commentAndUser = self.commentAndUser else { return }
        cellViewDelegate?.profileImagePressed(user: commentAndUser.user)

        
    }
}

