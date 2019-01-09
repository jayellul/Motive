//
//  SliderViewController.swift
//  wyd
//
//  Created by Jason Ellul on 2018-07-04.
//  Copyright © 2018 Jason Ellul. All rights reserved.
//

import UIKit
import Firebase
import SDWebImage

protocol SliderDelegate {
    func sliderSelected(row: Int)
    func pushProfile()
    func pushFollowers()
    func pushFollowing()

}
class SliderViewController: UIViewController {
    
    var delegate: SliderDelegate?
    
    var currentUser: CurrentUser?
    var requestsCount = 0
    
    // ui kit components
    
    var backgroundView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.clear
        return view
    }()
    
    let shaderView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isUserInteractionEnabled = true
        view.backgroundColor = UIColor.black
        view.alpha = 0.0
        return view
    }()
    
    let transitionView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isUserInteractionEnabled = true
        view.backgroundColor = UIColor.white
        view.isHidden = true
        return view
    }()
    
    let topView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isUserInteractionEnabled = true
        view.backgroundColor = UIColor.white
        return view
    }()
    
    let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = true
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius =  25
        // fix pathing to have default image
        imageView.image = UIImage(named: "Images/default user icon.png")
        imageView.isUserInteractionEnabled = false
        return imageView
    }()
    let displayLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = true
        label.textColor = UIColor.black
        label.font = UIFont.boldSystemFont(ofSize: 20.0)
        label.text = ""
        label.textAlignment = .left
        return label
    }()
    let usernameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = true
        label.textColor = UIColor(red: 153/255, green: 153/255, blue: 153/255, alpha: 1.0)
        label.font = UIFont.systemFont(ofSize: 16.0)
        label.text = ""
        label.textAlignment = .left
        return label
    }()
    
    let followersLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = true
        label.textColor = UIColor(red: 153/255, green: 153/255, blue: 153/255, alpha: 1.0)
        label.font = UIFont.systemFont(ofSize: 12.0)
        label.text = "Followers"
        label.textAlignment = .left
        return label
    }()
    
    let followingLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = true
        label.textColor = UIColor(red: 153/255, green: 153/255, blue: 153/255, alpha: 1.0)
        label.font = UIFont.systemFont(ofSize: 12.0)
        label.text = "Following"
        label.textAlignment = .left
        return label
    }()
    
    var tableView: UITableView = {
        let table = UITableView()
        table.translatesAutoresizingMaskIntoConstraints = false
        table.tableHeaderView = UIView (frame: CGRect.zero)
        table.tableFooterView = UIView (frame: CGRect.zero)
        table.layoutMargins = UIEdgeInsets.zero
        table.separatorInset = UIEdgeInsets.zero
        table.alwaysBounceVertical = true
        return table
    }()
    // loading indicator within refresh button
    let activityIndicator: UIActivityIndicatorView = {
        let activityIndicator = UIActivityIndicatorView(frame: CGRect(x: 25, y: 70, width: 25, height: 25))
        activityIndicator.translatesAutoresizingMaskIntoConstraints = true
        activityIndicator.hidesWhenStopped = true
        activityIndicator.color = UIColor.lightGray
        activityIndicator.isUserInteractionEnabled = false
        return activityIndicator
    }()
    
    var itemsToLoad: [String] = ["Profile", "Feed" ,"Explore", "Settings"]
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        setupSubviews()
        addTapGestureRecognizers()
        loadUserProfile()
        slideIn()
        // setup table
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(SliderTableViewCell.self, forCellReuseIdentifier: "sliderTableViewCell")
        tableView.separatorStyle = .none
        tableView.allowsMultipleSelection = false

        // add swipe to close
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panGestureRecognizerAction(_:)))
        // add swipe right gesture
        self.view.addGestureRecognizer(panGestureRecognizer)
    }
    
    func setupSubviews() {

        self.view.addSubview(shaderView)
        shaderView.frame = self.view.bounds
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(shaderViewTapped(_:)))
        shaderView.addGestureRecognizer(tapGestureRecognizer)
        // set transition view off screen to the left
        transitionView.frame = CGRect(x: (290) * -1, y: 0, width: 290, height: self.view.bounds.height)
        self.view.addSubview(transitionView)
        transitionView.widthAnchor.constraint(equalToConstant: transitionView.frame.width).isActive = true
        transitionView.heightAnchor.constraint(equalToConstant: transitionView.frame.height).isActive = true
        // topview contains all of the profile stuff
        topView.frame = CGRect(x: 0, y: 0, width: transitionView.frame.width, height: 180)
        self.transitionView.addSubview(topView)
        topView.widthAnchor.constraint(equalToConstant: transitionView.frame.width).isActive = true
        topView.heightAnchor.constraint(equalToConstant: 180).isActive = true
        // add subviews to topview
        // activity indicator display before loaduser profile is done
        topView.addSubview(activityIndicator)
        activityIndicator.startAnimating()

        profileImageView.frame = CGRect(x: 25, y: 35, width: 50, height: 50)
        topView.addSubview(profileImageView)
        
        displayLabel.frame = CGRect(x: 25, y: 90, width: transitionView.frame.width - 30, height: 30)
        topView.addSubview(displayLabel)
        
        usernameLabel.frame = CGRect(x: 25, y: 114, width: transitionView.frame.width - 30, height: 20)
        topView.addSubview(usernameLabel)

        followersLabel.frame = CGRect(x: 25, y: 145, width: (transitionView.frame.width - 10) / 2, height: 20)
        topView.addSubview(followersLabel)

        // set followers label
        let attrs1 = [NSAttributedStringKey.font : UIFont.boldSystemFont(ofSize: 17), NSAttributedStringKey.foregroundColor : UIColor.black]
        let attrs2 = [NSAttributedStringKey.font : UIFont.systemFont(ofSize: 16), NSAttributedStringKey.foregroundColor : UIColor(red: 153/255, green: 153/255, blue: 153/255, alpha: 1.0)]
        let attributedString1 = NSMutableAttributedString(string: "0", attributes:attrs1)
        let attributedString2 = NSMutableAttributedString(string:" Followers", attributes:attrs2)
        attributedString1.append(attributedString2)
        followersLabel.attributedText = attributedString1
        followersLabel.sizeToFit()

        // set following label
        followingLabel.frame = CGRect(x: followersLabel.frame.origin.x + followersLabel.frame.width + 12, y: 145, width: (transitionView.frame.width - 10) / 2, height: 20)
        topView.addSubview(followingLabel)
        let attributedString3 = NSMutableAttributedString(string: "0", attributes:attrs1)
        let attributedString4 = NSMutableAttributedString(string:" Following", attributes:attrs2)
        attributedString3.append(attributedString4)
        followingLabel.attributedText = attributedString3

        // add tableview to transition view
        tableView.frame = CGRect(x: 0, y: 180, width: transitionView.frame.width, height: transitionView.frame.height - 180)
        transitionView.addSubview(tableView)

    }
    
    // turn header profile display and point map into buttons
    func addTapGestureRecognizers() {
        // turn profile image into a button
        let profileGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(profileTapped(_:)))
        profileImageView.isUserInteractionEnabled = true
        profileImageView.addGestureRecognizer(profileGestureRecognizer)
        let profileGestureRecognizer2 = UITapGestureRecognizer(target: self, action: #selector(profileTapped(_:)))
        displayLabel.isUserInteractionEnabled = true
        displayLabel.addGestureRecognizer(profileGestureRecognizer2)
        let profileGestureRecognizer3 = UITapGestureRecognizer(target: self, action: #selector(profileTapped(_:)))
        usernameLabel.isUserInteractionEnabled = true
        usernameLabel.addGestureRecognizer(profileGestureRecognizer3)
        
        // turn followers into a button
        let followersGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(followersTapped(_:)))
        followersLabel.isUserInteractionEnabled = true
        followersLabel.addGestureRecognizer(followersGestureRecognizer)
        
        // turn following into a button
        let followingGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(followingTapped(_:)))
        followingLabel.isUserInteractionEnabled = true
        followingLabel.addGestureRecognizer(followingGestureRecognizer)
        
    }
    
    @objc func profileTapped(_ sender: Any) {
        slideOut()
        delegate?.pushProfile()
    }
    
    @objc func followersTapped(_ sender: Any) {
        slideOut()
        delegate?.pushFollowers()
    }
    
    @objc func followingTapped(_ sender: Any) {
        slideOut()
        delegate?.pushFollowing()
    }
    
    // load user into ui components
    func loadUserProfile() {
        if let userAndLists = self.currentUser {
            activityIndicator.stopAnimating()
            let user = userAndLists.user
            // display and user name label
            let oldDisplayFrame = displayLabel.frame
            displayLabel.text = user.display
            displayLabel.sizeToFit()
            displayLabel.frame = CGRect(x: oldDisplayFrame.origin.x, y: oldDisplayFrame.origin.y, width: min(displayLabel.frame.width, transitionView.frame.width - 30), height: oldDisplayFrame.height)
            // make frames size to Fit
            let oldUsernameFrame = usernameLabel.frame
            usernameLabel.text = "@" + user.username
            usernameLabel.sizeToFit()
            usernameLabel.frame = CGRect(x: oldUsernameFrame.origin.x, y: oldUsernameFrame.origin.y, width: min(usernameLabel.frame.width, transitionView.frame.width - 30), height: oldUsernameFrame.height)
            // set followers label
            let followers = user.numFollowers
            let attrs1 = [NSAttributedStringKey.font : UIFont.boldSystemFont(ofSize: 17), NSAttributedStringKey.foregroundColor : UIColor.black]
            let attrs2 = [NSAttributedStringKey.font : UIFont.systemFont(ofSize: 16), NSAttributedStringKey.foregroundColor : UIColor(red: 153/255, green: 153/255, blue: 153/255, alpha: 1.0)]
            let attributedString1 = NSMutableAttributedString(string: String(followers), attributes:attrs1)
            var attributedString2 = NSMutableAttributedString(string:" Followers", attributes:attrs2)
            if followers == 1 {
                attributedString2 = NSMutableAttributedString(string:" Follower", attributes:attrs2)
            }
            attributedString1.append(attributedString2)
            let oldFollowersFrame = followersLabel.frame
            followersLabel.attributedText = attributedString1
            followersLabel.sizeToFit()
            followersLabel.frame = CGRect(x: oldFollowersFrame.origin.x, y: oldFollowersFrame.origin.y, width: min(followersLabel.frame.width, transitionView.frame.width - 30), height: oldFollowersFrame.height)
            let requests = userAndLists.requests
            self.requestsCount = requests.count
            // set following label
            let following = user.numFollowing
            let attributedString3 = NSMutableAttributedString(string: String(following), attributes:attrs1)
            let attributedString4 = NSMutableAttributedString(string:" Following", attributes:attrs2)
            attributedString3.append(attributedString4)
            let oldFollowingFrame = followingLabel.frame
            followingLabel.attributedText = attributedString3
            followingLabel.sizeToFit()
            followingLabel.frame = CGRect(x: followersLabel.frame.origin.x + followersLabel.frame.width + 12, y: oldFollowingFrame.origin.y, width: min(followingLabel.frame.width, transitionView.frame.width - 30), height: oldFollowingFrame.height)
            // download profile image
            if let url = URL(string: user.photoURL) {
                self.profileImageView.sd_setImage(with: url) { (image, error, cache, urls) in
                    if (error != nil) {
                        //Failure code here - defualt image
                        self.profileImageView.image = #imageLiteral(resourceName: "default user icon.png")
                    } else {
                        //Success code here
                        self.profileImageView.image = image
                    }
                }
            }
            // add follow requests to items to load if user is private
            if userAndLists.isPrivate {
                itemsToLoad.append("Follow Requests")
                tableView.reloadData()
            }
        } else {
            // error handle if user doesnt exist
            
        }
    }
    
    func slideIn() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            self.transitionView.isHidden = false
            self.transitionView.frame = CGRect(x: (290) * -1, y: 0, width: 290, height: self.view.bounds.height)
            UIView.animate(withDuration: 0.295, animations: {
                self.shaderView.alpha = 0.3
                self.transitionView.frame = CGRect(x: 0, y: 0, width: 290, height: self.view.bounds.height)
            }, completion: { (finished: Bool) in
                self.transitionView.isHidden = false
            })
        }
        
    }
    
    func slideOut() {
        UIView.animate(withDuration: 0.295, animations: {
            self.shaderView.alpha = 0.0
            self.transitionView.frame = CGRect(x: 290 * -1, y: 0, width: 290, height: self.view.bounds.height)
            
        }, completion: { (finished: Bool) in
            //self.navigationController?.popViewController(animated: false)
            self.dismiss(animated: false, completion: nil)
        })
    }
    
    // view poppers
    @objc func panGestureRecognizerAction(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        if (translation.x <= 0) {
            transitionView.frame.origin.x = translation.x
            shaderView.alpha = 0.3 + (translation.x / 1000)
        }

        let velocity = gesture.velocity(in: view)
        if gesture.state == .ended {
            // if velocity is fast enough, pop
            if (velocity.x <= -600) {
                UIView.animate(withDuration: TimeInterval((self.view.frame.width - translation.x) / (velocity.x * -1) / 2), delay: 0.0, animations: {
                    // animate origin moring off screen
                    self.transitionView.frame.origin = CGPoint(x: self.transitionView.frame.width * -1, y: 0.0)
                    self.shaderView.alpha = 0.0
                }, completion: {(finished:Bool) in
                    // animation finishes
                    //self.navigationController?.popViewController(animated: false)
                    self.dismiss(animated: false, completion: nil)
                })
            // over half the screen, pop
            } else if (translation.x * -1 >= self.transitionView.frame.width / 2) {
                UIView.animate(withDuration: 0.3, delay: 0.0, animations: {
                    // animate origin moring off screen
                    self.transitionView.frame.origin = CGPoint(x: self.transitionView.frame.width * -1, y: 0.0)
                    self.shaderView.alpha = 0.0
                }, completion: {(finished:Bool) in
                    // animation finishes
                    //self.navigationController?.popViewController(animated: false)
                    self.dismiss(animated: false, completion: nil)
                })
            // cancel / go back to origin
            } else {
                UIView.animate(withDuration: 0.3) {
                    self.transitionView.frame.origin.x = 0
                    self.shaderView.alpha = 0.3
                }
            }
        }
    }
    
    @objc func shaderViewTapped (_ sender: Any) {
        slideOut()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    


}

extension SliderViewController: UITableViewDelegate , UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return itemsToLoad.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "sliderTableViewCell", for: indexPath as IndexPath) as! SliderTableViewCell
        cell.awakeFromNib()
        cell.selectionStyle = UITableViewCellSelectionStyle.none
        cell.titleLabel.text = self.itemsToLoad[indexPath.row]
        switch indexPath.row {
        case 0:
            cell.iconImageView.image = resizeImage(image: #imageLiteral(resourceName: "profile.png"), targetSize: CGSize(width: 25, height: 25))
        case 1:
            cell.iconImageView.image = resizeImage(image: #imageLiteral(resourceName: "feed.png"), targetSize: CGSize(width: 25, height: 25))
        case 2:
            cell.iconImageView.image = resizeImage(image: #imageLiteral(resourceName: "world.png"), targetSize: CGSize(width: 25, height: 25))
        case 3:
            cell.iconImageView.image = resizeImage(image: #imageLiteral(resourceName: "settings.png"), targetSize: CGSize(width: 25, height: 25))
        case 4:
            // setup follow request cell if user is private
            cell.iconImageView.image = nil
            // draw circle layer and add num requests text on top
            let circleLayer = CAShapeLayer()
            let radius: CGFloat = 12.5
            circleLayer.path = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: 2.0 * radius, height: 2.0 * radius), cornerRadius: radius).cgPath
            circleLayer.position = CGPoint(x: cell.iconImageView.frame.midX, y: cell.iconImageView.frame.midY)
            circleLayer.fillColor = UIColor(red:1.00, green:0.60, blue:0.20, alpha:1.0).cgColor
            cell.iconImageView.layer.addSublayer(circleLayer)
            let label = UILabel(frame: CGRect(x: 0, y: 0, width: 25, height: 25))
            label.translatesAutoresizingMaskIntoConstraints = false
            label.font = UIFont.boldSystemFont(ofSize: 16)
            label.textColor = UIColor.white
            var numString = "0"
            if let count = currentUser?.requests.count {
                if count > 99 {
                    numString = "+99"
                } else {
                    numString = String(count)
                }
            }
            label.text = numString
            cell.iconImageView.addSubview(label)
            label.centerXAnchor.constraint(equalTo: cell.iconImageView.centerXAnchor).isActive = true
            label.centerYAnchor.constraint(equalTo: cell.iconImageView.centerYAnchor).isActive = true
        default:
            cell.iconImageView.image = nil
            cell.titleLabel.text = ""
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //print("User selected table row \(indexPath.row) and item \(itemsToLoad[indexPath.row])")
        delegate?.sliderSelected(row: indexPath.row)
        slideOut()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }

}
