//
//  ExploreViewController.swift
//  wyd
//
//  Created by Jason Ellul on 2018-09-02.
//  Copyright © 2018 Jason Ellul. All rights reserved.
//

import UIKit
import Firebase
import SDWebImage
import ODRefreshControl



protocol ExploreDelegate {
    func exploreSentRefresh()
    func exploreGetMoreMotives()
    func exploreSelectedMotive(motive: Motive)
}
class ExploreViewController: UIViewController, SliderDelegate, TabDelegate {
    
    
    
    
    
    // delegate for map view
    var delegate: ExploreDelegate?
    var annotationDelegate: AnnotationDelegate?
    var pinchDelegate: PinchDelegate?
    // delegate for Tab view
    var tabDelegate: ExploreDelegate?
    var loadingMoreMotives: Bool = true
    var loaded = false
    var completedFirstLoad = false
    
    var userHashTableDelegate: UserHashTableDelegate?
    var currentUserDelegate: CurrentUserDelegate?
    var currentUser: CurrentUser?
    var motiveHashTableDelegate: MotiveHashTableDelegate?
    
    var isZooming = false
    // search stuff
    var isSearching = false
    var searchResults = [User]()
    var savedContentOffset = CGPoint.zero

    
    // firebase db refs
    static let kUsersListPath = "users"
    let usersReference = Database.database().reference(withPath: kUsersListPath)
    static let kMotivesListPath = "motives"
    let motivesReference = Database.database().reference(withPath: kMotivesListPath)
    static let kMotivesGoingListPath = "motivesGoing"
    let motivesGoingReference = Database.database().reference(withPath: kMotivesGoingListPath)
    static let kFollowersListPath = "followers"
    let followersReference = Database.database().reference(withPath: kFollowersListPath)
    static let kFollowingListPath = "following"
    let followingReference = Database.database().reference(withPath: kFollowingListPath)
    static let kPrivateListPath = "private"
    let privateReference = Database.database().reference(withPath: kPrivateListPath)
    static let kRequestsListPath = "requests"
    let requestsReference = Database.database().reference(withPath: kRequestsListPath)
    static let kRequestSentListPath = "requestsSent"
    let requestsSentReference = Database.database().reference(withPath: kRequestSentListPath)
    // functions ref for search
    lazy var functions = Functions.functions()

    
    // ui kit components
    @IBOutlet weak var transitionView: UIView!
    // background view for pinch
    var pinchView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = true
        view.isUserInteractionEnabled = false
        view.backgroundColor = UIColor.clear
        return view
    }()
    
    var searchTextField: UITextField = {
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.autocapitalizationType = UITextAutocapitalizationType.none
        textField.autocorrectionType = .no
        textField.layer.cornerRadius = 5
        textField.backgroundColor = UIColor(red:0.96, green:0.48, blue:0.24, alpha:1.0)
        textField.textColor = UIColor.white
        textField.tintColor = UIColor.white
        textField.textAlignment = .center
        return textField
    }()
    lazy var searchTextFieldRightConstraint = searchTextField.rightAnchor.constraint(equalTo: headerView.rightAnchor, constant: -18)
    
    var cancelButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = UIColor.clear
        button.titleLabel?.textAlignment = .left
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        button.titleLabel?.textColor = UIColor.white
        button.setTitle("Cancel", for: .normal)
        button.isHidden = true
        button.alpha = 0.0
        return button
    }()
    
    // header view adjust for iphonex
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var headerViewHeightConstraint: NSLayoutConstraint!
    
    // table variables
    @IBOutlet weak var tableView: UITableView!
    lazy var customRefreshControl = ODRefreshControl(in: self.tableView)
    
    // from tab bar
    var motiveAndUsers = [MotiveAndUser]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // setup subviews
        setupSubviews()
        // Do any additional setup after loading the view.
        self.currentUserDelegate = self.tabBarController as? CustomTabBarController
        // load current user
        // if tab bar has a user take it
        if let tabBarCurrentUser = self.currentUserDelegate?.retrieveCurrentUser() {
            self.currentUser = tabBarCurrentUser
        } else {
            // get the signed in users profile
            if let currentUserUid = Auth.auth().currentUser?.uid {
                getCurrentUser(uid: currentUserUid) { (result) in
                    if let newCurrentUser = result {
                        // store the result
                        self.currentUser = newCurrentUser
                        self.currentUserDelegate?.storeCurrentUser(currentUser: newCurrentUser)
                    }
                }
            }
        }
        
        // refresh control
        customRefreshControl?.addTarget(self, action: #selector(refreshControlAction(_:)), for: .valueChanged)
        
        
        // get loaded motives from tab bar
        loaded = true
        hideLoading()
        // add transition view pinch
        let pinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(pinchGestureRecognizerAction(_:)))
        // delay for 0.5 seconds before enabling gestures
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // add gestures
            self.transitionView.addGestureRecognizer(pinchGestureRecognizer)
        }
        self.hideKeyboardWhenTappedAround()
        
    }
    
    // setup subviews of the view controller
    func setupSubviews() {
        headerView.frame.size.height = 75
        headerView.frame.size.width = view.frame.width
        headerView.bounds.size.width = view.frame.width
        if self.isPhoneX() {
            headerViewHeightConstraint.constant = 100
            headerView.frame.size.height = 100
        }
        addGradientToView(headerView)

        // setup search bar
        headerView.addSubview(searchTextField)
        searchTextField.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -17).isActive = true
        searchTextField.leftAnchor.constraint(equalTo: headerView.leftAnchor, constant: 65).isActive = true
        searchTextFieldRightConstraint.isActive = true
        searchTextField.heightAnchor.constraint(equalToConstant: 30).isActive = true
        searchTextField.delegate = self
        // set left view
        searchTextField.leftViewMode = .always
        // set placeholder string
        let string = NSMutableAttributedString(string: "Search", attributes: [NSAttributedStringKey.foregroundColor: UIColor.white, NSAttributedStringKey.font: searchTextField.font ?? UIFont.systemFont(ofSize: 14)])
        searchTextField.attributedPlaceholder = string
        // add cancel button for searches
        headerView.addSubview(cancelButton)
        cancelButton.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -17).isActive = true
        cancelButton.rightAnchor.constraint(equalTo: headerView.rightAnchor).isActive = true
        cancelButton.heightAnchor.constraint(equalToConstant: 30).isActive = true
        cancelButton.widthAnchor.constraint(equalToConstant: 65).isActive = true
        cancelButton.addTarget(self, action: #selector(cancelButtonPressed(_:)), for: .touchDown)


        // tableView properties
        tableView.frame.size.width = transitionView.frame.width
        tableView.bounds.size.width = transitionView.frame.width 
        tableView.tableFooterView = UIView (frame: CGRect.zero)
        tableView.layoutMargins = UIEdgeInsets.zero
        tableView.separatorInset = UIEdgeInsets.zero
        tableView.estimatedRowHeight = 50
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.register(UserTableViewCell.self, forCellReuseIdentifier: "userTableViewCell")

    }
    
    
    // refresh control - just call tab bar and get new motives
    @objc func refreshControlAction(_ sender: Any) {
        if isSearching {
            guard let searchText = searchTextField.text else { customRefreshControl?.endRefreshing(); return }
            searchUsers(startingWith: searchText)
            return
        }
        loadingMoreMotives = true
        tabDelegate?.exploreSentRefresh()
    }
    
    
    func showLoading() {
        
    }
    
    // get all motives from tab bar and then load first numMotivesToLoad users
    func hideLoading() {
        let customTabBarController = self.tabBarController as! CustomTabBarController
        self.motiveAndUsers = customTabBarController.exploreMotives
        annotationDelegate?.addMotivesToMap(motiveAndUsers: self.motiveAndUsers)
        // if xib has been initialized
        if loaded {
            loadMotiveTable()
        }
    }
    
    
    func loadMotiveTable() {
        // sort by time
        self.motiveAndUsers.sort(by: { ($0.motive.time < $1.motive.time)})
        // has to be done on main thread
        if self.customRefreshControl?.isRefreshing == true {
            self.tableView.reloadData()
            self.completedFirstLoad = true
            self.run(after: 0.3, closure: {
                self.customRefreshControl?.endRefreshing()
            })
        } else {
            self.tableView.reloadData()
            self.completedFirstLoad = true
        }
        loadingMoreMotives = false
    }
    
    
    // the hamburger menu icon was pressed - push sliderviewcontroller
    @IBAction func hamburgerPressed(_ sender: Any) {
        let sliderViewController = storyboard?.instantiateViewController(withIdentifier: "sliderViewController") as! SliderViewController
        // if tab bar has a user take it
        if let tabBarCurrentUser = self.currentUserDelegate?.retrieveCurrentUser() {
            self.currentUser = tabBarCurrentUser
        } else {
            // get the signed in users profile if it doesnt exist in tab bar
            if let currentUserUid = Auth.auth().currentUser?.uid {
                getCurrentUser(uid: currentUserUid) { (result) in
                    if let newCurrentUser = result {
                        // store the result
                        self.currentUser = newCurrentUser
                        self.currentUserDelegate?.storeCurrentUser(currentUser: newCurrentUser)
                        self.userHashTableDelegate?.storeUser(user: newCurrentUser.user)
                        // load user profile into slider - stop animating loading
                        sliderViewController.currentUser = newCurrentUser
                        sliderViewController.loadUserProfile()
                        sliderViewController.tableView.reloadData()
                    }
                }
            }
        }
        sliderViewController.hidesBottomBarWhenPushed = true
        sliderViewController.delegate = self
        sliderViewController.currentUser = currentUser
        sliderViewController.modalPresentationStyle = .overCurrentContext
        // present slider view onto tabbar view to overlap it
        self.tabBarController?.present(sliderViewController, animated: false, completion: nil)
    }
    
    /// slider modal selected a row
    func sliderSelected(row: Int) {
        switch row {
        // profile
        case 0:
            pushProfile()
        // feed
        case 1:
            return
        // explore
        case 2:
            return
        // settings
        case 3:
            pushSettings()
            
        case 4:
            pushFollowRequests()
        default:
            return
        }
    }
    // push current users profile view onto navigation view stack
    func pushProfile() {
        if let currentUser = currentUser {
            if let snapshotView = self.view.snapshotView(afterScreenUpdates: true) {
                if let pinchSnapshotView = self.pinchView.snapshotView(afterScreenUpdates: true) {
                    let userViewController = storyboard?.instantiateViewController(withIdentifier: "userViewController") as! UserViewController
                    userViewController.backgroundView = snapshotView
                    userViewController.pinchView = pinchSnapshotView
                    userViewController.uid = currentUser.user.uid
                    userViewController.user = currentUser.user
                    self.navigationController?.pushViewController(userViewController, animated: true)
                }
            }
        }
    }
    // push current users followers view onto navigation view stack
    func pushFollowers() {
        if let user = currentUser {
            if let snapshotView = self.view.snapshotView(afterScreenUpdates: true) {
                if let pinchSnapshotView = self.pinchView.snapshotView(afterScreenUpdates: true) {
                    let friendViewController = storyboard?.instantiateViewController(withIdentifier: "friendViewController") as! FriendViewController
                    friendViewController.backgroundView = snapshotView
                    friendViewController.pinchView = pinchSnapshotView
                    friendViewController.type = .followers
                    friendViewController.id = user.user.uid
                    self.navigationController?.pushViewController(friendViewController, animated: true)
                }
            }
        }
    }
    // push current users following view onto navigation view stack
    func pushFollowing() {
        if let user = currentUser {
            if let snapshotView = self.view.snapshotView(afterScreenUpdates: true) {
                if let pinchSnapshotView = self.pinchView.snapshotView(afterScreenUpdates: true) {
                    let friendViewController = storyboard?.instantiateViewController(withIdentifier: "friendViewController") as! FriendViewController
                    friendViewController.backgroundView = snapshotView
                    friendViewController.pinchView = pinchSnapshotView
                    friendViewController.type = .following
                    friendViewController.id = user.user.uid
                    
                    self.navigationController?.pushViewController(friendViewController, animated: true)
                }
            }
        }
    }
    func pushSettings() {
        if let snapshotView = self.view.snapshotView(afterScreenUpdates: true) {
            if let pinchSnapshotView = self.pinchView.snapshotView(afterScreenUpdates: true) {
                let settingsViewController = storyboard?.instantiateViewController(withIdentifier: "settingsViewController") as! SettingsViewController
                settingsViewController.backgroundView = snapshotView
                settingsViewController.pinchView = pinchSnapshotView
                self.navigationController?.pushViewController(settingsViewController, animated: true)
            }
        }
    }
    func pushFollowRequests() {
        if let currentUser = currentUser {
            if let snapshotView = self.view.snapshotView(afterScreenUpdates: true) {
                if let pinchSnapshotView = self.pinchView.snapshotView(afterScreenUpdates: true) {
                    let requestsViewController = storyboard?.instantiateViewController(withIdentifier: "requestsViewController") as! RequestsViewController
                    requestsViewController.backgroundView = snapshotView
                    requestsViewController.pinchView = pinchSnapshotView
                    requestsViewController.currentUser = currentUser
                    self.navigationController?.pushViewController(requestsViewController, animated: true)
                }
            }
        }
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}

// tableView Functions
// delagate table
// https://www.codementor.io/brettr/two-basic-ways-to-populate-your-uitableview-du107rsyx
// https://www.weheartswift.com/firebase-101/
extension ExploreViewController: UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate, CalloutViewDelegate, FriendViewControllerDelegate, UIActionSheetDelegate {
    func morePressed(motive: Motive) {
        //Create the AlertController and add Its action like button in Actionsheet
        let actionSheetControllerIOS8: UIAlertController = UIAlertController(title: "Other Options", message: nil, preferredStyle: .actionSheet)
        
        let cancelActionButton = UIAlertAction(title: "Cancel", style: .cancel) { _ in
            print("Cancel")
        }
        actionSheetControllerIOS8.addAction(cancelActionButton)
        
        let blockActionButton = UIAlertAction(title: "Block User", style: .default) { _ in
            if let uid = Auth.auth().currentUser?.uid {
                if (motive.creator != uid) {
                    let kBlockedListPath = "users/" + uid + "/blocked"
                    let blockedReference = Database.database().reference(withPath: kBlockedListPath)
                    let timestamp = Int64(NSDate().timeIntervalSince1970 * -1000)
                    blockedReference.child(motive.creator).setValue(timestamp)
                }
            }
        }
        actionSheetControllerIOS8.addAction(blockActionButton)
        
        let reportActionButton = UIAlertAction(title: "Report Post", style: .default) { _ in
            AlertController.showAlert(self, title: "Reported", message: "This post has been reported and will reviewed by a moderator.")
        }
        actionSheetControllerIOS8.addAction(reportActionButton)
        self.present(actionSheetControllerIOS8, animated: true, completion: nil)
    }
    
    
    // if table scrolled
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if searchTextField.isFirstResponder {
            searchTextField.resignFirstResponder()
        }
        if scrollView.contentOffset.y + 300 >= scrollView.contentSize.height - scrollView.frame.height {
            if !isSearching && !loadingMoreMotives {
                print ("requesting more motives")
                loadingMoreMotives = true
                tabDelegate?.exploreGetMoreMotives()
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isSearching {
            print ("num results: " + self.searchResults.count.description)
            return searchResults.count
        }
        print ("num posts " + self.motiveAndUsers.count.description)
        return self.motiveAndUsers.count
    }
    
    // setting the height for all table rows
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if isSearching {
            return 90
        }
        return UITableViewAutomaticDimension
    }
    
    // setting the estimated height for all table rows
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        if isSearching {
            return 90
        }
        return UITableViewAutomaticDimension
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // if table is searching then deque a usertableviewcell and populate with search results
        if isSearching {
            let cell = tableView.dequeueReusableCell(withIdentifier: "userTableViewCell") as! UserTableViewCell
            cell.frame.size.width = tableView.frame.width
            cell.selectionStyle = .none
            cell.layoutMargins = UIEdgeInsets.zero
            cell.setupSubviews()
            print (indexPath.row)
            print (searchResults.count)
            let user = searchResults[indexPath.row]
            cell.titleLabel.text = user.display
            cell.usernameLabel.text = "@" + user.username
            cell.profileImageView.image = nil
            // download profile image
            if let url = URL(string: user.photoURL) {
                cell.profileImageView.sd_setImage(with: url) { (image, error, cache, urls) in
                    if (error != nil) {
                        //Failure code here - defualt image
                        cell.profileImageView.image = #imageLiteral(resourceName: "default user icon.png")
                    } else {
                        //Success code here
                        cell.profileImageView.image = image
                    }
                }
            }
            // setup side button
            cell.followingButton.tag = indexPath.row
            cell.followButton.tag = indexPath.row
            if let currentUser = (self.tabBarController as? CustomTabBarController)?.currentUser {
                // if the cell is the current user
                if currentUser.user.uid == user.uid {
                    // remove side button
                    cell.loadingButton.removeFromSuperview()
                    return cell
                } else {
                    // if current user is following cell user
                    if currentUser.followingSet.contains(user.uid) {
                        cell.setupAlreadyFollowingButton()
                        cell.followingButton.isUserInteractionEnabled = false
                        cell.followingButton.addTarget(self, action: #selector(alreadyFollowingPressed(_:)), for: .touchUpInside)
                        return cell
                    }
                    // if current user has requested to follow cell user
                    if user.requestSent {
                        cell.setupRequestSentButton()
                        cell.followingButton.removeTarget(self, action: #selector(self.alreadyFollowingPressed(_:)), for: .touchUpInside)
                        cell.followingButton.addTarget(self, action: #selector(self.requestSentPressed(_:)), for: .touchUpInside)
                        return cell
                    }
                    // not currently following
                    // display addFriendButton
                    cell.setupFollowButton()
                    cell.followButton.addTarget(self, action: #selector(followPressed(_:)), for: .touchUpInside)
                    
                    return cell
                }
            }
            // error - remove side button and return
            cell.loadingButton.removeFromSuperview()
            return cell
        }
        // create a MotiveTableViewCell profile feed post
        let cell = tableView.dequeueReusableCell(withIdentifier: "motiveTableViewCell") as! MotiveTableViewCell
        // since awake from xib isnt called
        cell.frame.size.width = tableView.frame.width
        cell.selectionStyle = .none
        cell.layoutMargins = UIEdgeInsets.zero
        // setup cell
        cell.motiveAndUser = motiveAndUsers[indexPath.row]
        cell.cellViewDelegate = self
        // load motive for post
        let motive = motiveAndUsers[indexPath.row].motive
        // set time label
        cell.timeLabel.text = timestampToText(timestamp: motive.time)
        cell.timeLabel.sizeToFit()
        let textWidth = cell.timeLabel.frame.width + 5
        cell.timeLabel.frame = CGRect(x: cell.frame.width - textWidth - 10, y: 12, width: textWidth, height: 20)
        // set text label
        cell.motiveTextLabel.text = motive.text
        cell.motiveTextLabel.sizeToFit()
        // load number of people going
        let numGoing = motive.numGoing
        cell.goingLabel.setTitle(" " + numToText(num: numGoing), for: .normal)
        cell.goingLabel.setTitle(" " + numToText(num: numGoing), for: .highlighted)
        if ((tabBarController as? CustomTabBarController)?.userMotiveGoingSet.contains(motive.id) ?? false) {
            cell.setupUserGoing()
        } else {
            cell.setupUserNotGoing()
        }
        // set num comments label
        let numComments = motive.numComments
        cell.commentsLabel.setTitle(" " + numToText(num: numComments), for: .normal)
        cell.commentsLabel.setTitle(" " + numToText(num: numComments), for: .highlighted)
        
        // load user details for post
        let user = motiveAndUsers[indexPath.row].user
        // create attributed text for title of motive feed (display + @username)
        let attrs1 = [NSAttributedStringKey.font : UIFont.boldSystemFont(ofSize: 16), NSAttributedStringKey.foregroundColor : UIColor.black]
        let attrs2 = [NSAttributedStringKey.font : UIFont.systemFont(ofSize: 16), NSAttributedStringKey.foregroundColor : UIColor(red: 153/255, green: 153/255, blue: 153/255, alpha: 1.0)]
        let attributedString1 = NSMutableAttributedString(string: user.display, attributes:attrs1)
        let attributedString2 = NSMutableAttributedString(string: " @" + user.username, attributes:attrs2)
        attributedString1.append(attributedString2)
        cell.titleLabel.attributedText = attributedString1
        cell.titleLabel.frame = CGRect(x: 70, y: 12, width: cell.frame.width - 78 - textWidth, height: 20)
        // default while loading ** Fix
        cell.profileImageView.image = nil
        // download profile image
        if let url = URL(string: user.photoURL) {
            cell.profileImageView.sd_setImage(with: url) { (image, error, cache, urls) in
                if (error != nil) {
                    //Failure code here - defualt image
                    cell.profileImageView.image = #imageLiteral(resourceName: "default user icon.png")
                } else {
                    //Success code here
                    cell.profileImageView.image = image
                }
            }
        }
        // return a MotiveTableViewCell
        return cell
    }
    
    // display motive on map
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if isSearching {
            let user = searchResults[indexPath.row]
            profileImagePressed(user: user)
            return
        }
        // send info to map view controller and tab controller delegate
        let motive = motiveAndUsers[indexPath.row].motive
        tabDelegate?.exploreSelectedMotive(motive: motive)
        delegate?.exploreSelectedMotive(motive: motive)
    }

    func refreshTable() {
        if isSearching {
            tableView.reloadData()
        }
    }
    

    
    // stub
    func calloutPressed() {
        return
    }
    
    func profileImagePressed(user: User) {
        if let snapshotView = self.view.snapshotView(afterScreenUpdates: true) {
            for subview in pinchView.subviews {
                if subview is UIVisualEffectView { subview.isHidden = true }
            }
            if let pinchSnapshotView = pinchView.snapshotView(afterScreenUpdates: true) {
                let userViewController = storyboard?.instantiateViewController(withIdentifier: "userViewController") as! UserViewController
                userViewController.backgroundView = snapshotView
                for subview in pinchView.subviews {
                    if subview is UIVisualEffectView { subview.isHidden = false }
                }
                userViewController.pinchView = pinchSnapshotView
                userViewController.pinchDelegate = self.pinchDelegate
                userViewController.uid = user.uid
                userViewController.user = user
                userViewController.friendViewControllerDelegate = self
                self.navigationController?.pushViewController(userViewController, animated: true)
            }
        }
    }
    
    func commentsPressed(motive: Motive) {
        guard let currentUser = (self.tabBarController as? CustomTabBarController)?.currentUser else { return }
        if let snapshotView = UIApplication.shared.keyWindow?.snapshotView(afterScreenUpdates: true) {
            for subview in pinchView.subviews {
                if subview is UIVisualEffectView { subview.isHidden = true }
            }
            if let pinchSnapshotView = pinchView.snapshotView(afterScreenUpdates: true) {
                let commentViewController = storyboard?.instantiateViewController(withIdentifier: "commentViewController") as! CommentViewController
                commentViewController.backgroundView = snapshotView
                commentViewController.pinchView = pinchSnapshotView
                for subview in pinchView.subviews {
                    if subview is UIVisualEffectView { subview.isHidden = false }
                }
                commentViewController.motive = motive
                commentViewController.currentUser = currentUser
                commentViewController.hidesBottomBarWhenPushed = true
                self.navigationController?.pushViewController(commentViewController, animated: true)
            }
        }
    }
    
    func goingPressed(motive: Motive) {
        (tabBarController as? CustomTabBarController)?.userMotiveGoingSet.insert(motive.id)
        motiveHashTableDelegate?.storeMotive(motive: motive)
        guard let currentUser = (self.tabBarController as? CustomTabBarController)?.currentUser else { return }
        // make http call
        functions.httpsCallable("countGoing").call(["id": motive.id, "creator": motive.creator, "name": currentUser.user.username]) { (result, error) in
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
    }
    
    func unGoPressed(motive: Motive) {
        (tabBarController as? CustomTabBarController)?.userMotiveGoingSet.remove(motive.id)
        motiveHashTableDelegate?.storeMotive(motive: motive)
        // make http call
        functions.httpsCallable("countGoing").call(["id": motive.id, "creator": motive.creator, "name": ""]) { (result, error) in
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
    }
    // scroll to the top of the table
    @objc func feedLabelTapped(_ sender: Any) {
        if tableView.contentOffset == .zero {
            // select map if scrolled to top already
            self.tabBarController?.selectedIndex = 0
        } else {
            // if not then set content offset to 0
            tableView.setContentOffset(.zero, animated: true)
        }
        
    }
    
    
}

// MARK :- search functionality
extension ExploreViewController: UITextFieldDelegate {
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        startSearch()
    }
    
    func startSearch() {
        let leftView = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        leftView.backgroundColor = UIColor.clear
        searchTextField.leftView = leftView
        tableView.setContentOffset(tableView.contentOffset, animated: false)
        savedContentOffset = tableView.contentOffset
        isSearching = true
        self.headerView.layoutSubviews()
        UIView.animate(withDuration: 0.2, delay: 0.15, usingSpringWithDamping: 0.5, initialSpringVelocity: 5, options: .curveEaseOut, animations: {
            self.searchTextFieldRightConstraint.constant = -65
            self.headerView.layoutSubviews()
            self.searchTextField.textAlignment = .left
        }) { (complete) in
            
        }
        cancelButton.isHidden = false
        UIView.animate(withDuration: 0.2, delay: 0.15, options: .curveEaseOut, animations: {
            self.cancelButton.alpha = 1.0
        }) { (complete) in
            
        }
    }
    

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let maxLength = 20
        let currentText = searchTextField.text ?? ""
        let prospectiveText = (currentText as NSString).replacingCharacters(in: range, with: string)
        
        // end search if there is no text
        /*if prospectiveText == "" {
            cancelButtonPressed(searchTextField)
            return false
        } else {
            startSearch()
        }*/
        
        if prospectiveText.count < maxLength && prospectiveText != "" && prospectiveText != "\n" {
            searchUsers(startingWith: prospectiveText)
            tableView.reloadData()
        }
        

        
        return prospectiveText.count < maxLength
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        searchTextField.resignFirstResponder()
        return true
    }
    
    func searchUsers(startingWith: String) {
        guard let currentUser = self.currentUser else { return }
        let usernameReference = Database.database().reference(withPath: "username")
        let queryString = startingWith.lowercased()
        usernameReference.queryOrderedByKey().queryStarting(atValue: queryString).queryEnding(atValue: queryString + "\u{f8ff}").queryLimited(toFirst: 10).observeSingleEvent(of: .value) { (querySnapshot) in
            var users: [User] = []
            var snapshotArray: [DataSnapshot] = []
            for item in querySnapshot.children {
                let snap = item as! DataSnapshot
                snapshotArray.append(snap)
            
            }
            // order by similarity to the query string
            let snapshotArraySorted = snapshotArray.sorted {
                if $0.key == queryString && $1.key != queryString {
                    return true
                } else if $0.key.hasPrefix(queryString) && !$1.key.hasPrefix(queryString)  {
                    return true
                } else if $0.key.hasPrefix(queryString) && $1.key.hasPrefix(queryString) && $0.key.count < $1.key.count  {
                    return true
                } else if $0.key.contains(queryString) && !$1.key.contains(queryString) {
                    return true
                } else if $0.key.contains(queryString) && $1.key.contains(queryString) && $0.key.count < $1.key.count {
                    return true
                }
                return false
            }
            print (snapshotArray.debugDescription)
            let myGroup = DispatchGroup()
            // load users from values
            for (_, usernameSnapshot) in snapshotArraySorted.enumerated() {
                myGroup.enter()
                let uid = usernameSnapshot.value as! String
                // check to see if user is in hashtable
                if let user = self.userHashTableDelegate?.retrieveUser(uid: uid) {
                    users.append(user)
                    myGroup.leave()
                } else {
                    // if not in hashtable then load from firebase and store in hashtable
                    self.getUser(uid: uid) { (result) in
                        if let user = result {
                            self.userHashTableDelegate?.storeUser(user: user)
                            users.append(user)
                        }
                        myGroup.leave()
                    }
                    
                }
            }
            
            myGroup.notify(queue: .main) {
                if (self.customRefreshControl?.isRefreshing)! {
                    self.run(after: 0.5, closure: {
                        self.customRefreshControl?.endRefreshing()
                    })
                }
                self.searchResults = users
                self.tableView.reloadData()
            }

        }
    
    }
    
    // follow is pressed
    @objc func followPressed (_ sender: UIButton!) {
        guard let currentUserUid = Auth.auth().currentUser?.uid else { return }
        let indexPath = IndexPath(row: sender.tag, section: 0)
        let cell = tableView.cellForRow(at: indexPath) as! UserTableViewCell
        cell.followButton.showLoading()
        // change requestSent status in userHashTable
        let user = searchResults[indexPath.row]
        let cellUid = user.uid
        // send friend request to view user
        let timestamp = Int64(NSDate().timeIntervalSince1970 * -1000)
        // determine if user is private
        privateReference.child(cellUid).observeSingleEvent(of: .value) { (snapshot) in
            if snapshot.exists() {
                // user is private - send request to cell user
                self.requestsReference.child(cellUid).child(currentUserUid).setValue(timestamp)
                // update hash table user object
                var updatedUser = user
                updatedUser.requestSent = true
                self.userHashTableDelegate?.storeUser(user: updatedUser)
                self.searchResults[indexPath.row] = updatedUser
                cell.setupRequestSentButton()
                cell.followingButton.removeTarget(self, action: #selector(self.alreadyFollowingPressed(_:)), for: .touchUpInside)
                cell.followingButton.addTarget(self, action: #selector(self.requestSentPressed(_:)), for: .touchUpInside)
            } else {
                // user is not private - follow cell user
                self.followersReference.child(cellUid).child(currentUserUid).setValue(timestamp)
                self.followingReference.child(currentUserUid).child(cellUid).setValue(true)
                // call function to count num following for user in cell
                self.functionsNumFollowersCall(cellUid)
                // update objects in tab bar
                if let currentUser = (self.tabBarController as? CustomTabBarController)?.currentUser {
                    // update current user object
                    currentUser.followingSet.insert(cellUid)
                    var updatedCurrentUser = currentUser.user
                    updatedCurrentUser.numFollowing += 1
                    currentUser.user = updatedCurrentUser
                    (self.tabBarController as? CustomTabBarController)?.currentUser = currentUser
                    self.userHashTableDelegate?.storeUser(user: updatedCurrentUser)
                    self.usersReference.child(currentUserUid).child("nFing").setValue(currentUser.followingSet.count)
                }
                // update object is table
                var updatedUser = user
                updatedUser.numFollowers += 1
                self.userHashTableDelegate?.storeUser(user: updatedUser)
                self.searchResults[indexPath.row] = updatedUser
                // change add button to request Sent button
                cell.setupAlreadyFollowingButton()
                cell.followingButton.removeTarget(self, action: #selector(self.requestSentPressed(_:)), for: .touchUpInside)
                cell.followingButton.removeTarget(self, action: #selector(self.alreadyFollowingPressed(_:)), for: .touchUpInside)
                //cell.followingButton.addTarget(self, action: #selector(self.alreadyFollowingPressed(_:)), for: .touchUpInside)
            }
            cell.followButton.hideLoading()
        }
    }
    // call firebase functions to write num followers for user
    func functionsNumFollowersCall(_ uid: String) {
        self.functions.httpsCallable("countFollowers").call(["id": uid]) { (result, error) in
            if let error = error as NSError? {
                if error.domain == FunctionsErrorDomain {
                    let message = error.localizedDescription
                    print (message)
                }
            } else if let numFollowers = (result?.data as? [String: Any])?["num"] as? Int {
                print ("countFollowers result: " + String(numFollowers))
                self.usersReference.child(uid).child("nFers").setValue(numFollowers)
            } else {
                print ("MAJOR COUNT FOLLOWERS ERROR")
            }
        }
    }
    @objc func alreadyFollowingPressed (_ sender: UIButton!) {
        
    }
    // undo the follow request
    @objc func requestSentPressed(_ sender: UIButton!) {
        guard let currentUserUid = Auth.auth().currentUser?.uid else { return }
        let indexPath = IndexPath(row: sender.tag, section: 0)
        let cell = tableView.cellForRow(at: indexPath) as! UserTableViewCell
        // change requestSent status in userHashTable
        let user = searchResults[indexPath.row]
        let cellUid = user.uid
        self.requestsReference.child(cellUid).child(currentUserUid).removeValue()
        // update hash table user object
        if var hashUser = self.userHashTableDelegate?.retrieveUser(uid: cellUid) {
            hashUser.requestSent = false
            self.userHashTableDelegate?.storeUser(user: hashUser)
        }
        cell.setupFollowButton()
        cell.followingButton.removeTarget(self, action: #selector(self.requestSentPressed(_:)), for: .touchUpInside)
        cell.followingButton.addTarget(self, action: #selector(self.followPressed(_:)), for: .touchUpInside)
    }
    
    @objc func cancelButtonPressed(_ sender: Any) {
        searchTextField.resignFirstResponder()
        // update tables
        let leftView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        leftView.backgroundColor = UIColor.clear
        searchTextField.leftView = leftView
        searchTextField.text = ""
        isSearching = false
        // set to saved content offset
        tableView.reloadData()
        tableView.setContentOffset(savedContentOffset, animated: false)
        // animate search bar expand
        self.headerView.layoutSubviews()
        UIView.animate(withDuration: 0.2, delay: 0.1, usingSpringWithDamping: 0.5, initialSpringVelocity: 5, options: .curveEaseOut, animations: {
            self.searchTextFieldRightConstraint.constant = -18
            self.headerView.layoutSubviews()
            self.searchTextField.textAlignment = .center
        }) { (complete) in

        }
        
        // animate out cancel button
        cancelButton.isHidden = false
        UIView.animate(withDuration: 0.1, delay: 0.0, options: .curveEaseOut, animations: {
            self.cancelButton.alpha = 0.0
        }) { (complete) in
            self.cancelButton.isHidden = true
        }

    }
}





// MARK - pinch gesture
extension ExploreViewController {
    
    func setupPinchView() {
        pinchView.frame = view.bounds
        view.addSubview(pinchView)
        view.sendSubview(toBack: pinchView)
    }
    
    @objc func pinchGestureRecognizerAction(_ sender: UIPinchGestureRecognizer) {
        if sender.state == .began {
            if sender.scale <= 1 {
                isZooming = true
                pinchView.isHidden = false
            }
            
        } else if sender.state == .changed {
            guard let view = sender.view else { return }
            let transform = view.transform.scaledBy(x: sender.scale, y: sender.scale)
            if sender.scale <= 1 {
                transitionView.transform = transform
                transitionView.alpha = transitionView.alpha * sender.scale
                sender.scale = 1
                // if smaller still transform
            } else if isZooming {
                if transitionView.transform.a + (sender.scale / 10) >= 1 || transitionView.transform.d + (sender.scale / 10) >= 1 {
                    transitionView.transform.a = 1
                    transitionView.transform.d = 1
                    transitionView.alpha = 1.0
                } else {
                    transitionView.transform = transform
                    transitionView.alpha = transitionView.alpha * sender.scale
                }
            }
            
        } else if sender.state == .ended || sender.state == .failed || sender.state == .cancelled {
            let center = CGPoint(x: view.bounds.midX, y: view.bounds.midY)
            if sender.scale <= 1 {
                // animate and pop to root view
                let transform = transitionView.transform.scaledBy(x: 0.15, y: 0.15)
                UIView.animate(withDuration: 0.25, animations: {
                    self.transitionView.transform = transform
                    self.transitionView.center = center
                    self.transitionView.alpha = 0.0
                    if self.pinchView.subviews.count > 0 {
                        let blurView = self.pinchView.subviews[0]
                        blurView.alpha = 0.0
                    }
                }, completion: { _ in
                    // reset and change to map view
                    self.transitionView.transform = CGAffineTransform.identity
                    self.transitionView.alpha = 1.0
                    self.transitionView.center = center
                    self.cancelButtonPressed(self.searchTextField)
                    self.pinchDelegate?.viewPinched()
                    self.tabBarController?.selectedIndex = 0
                })
            } else {
                // reset view
                UIView.animate(withDuration: 0.25, animations: {
                    self.transitionView.transform = CGAffineTransform.identity
                    self.transitionView.alpha = 1.0
                    self.transitionView.frame = self.view.frame
                }, completion: { _ in
                    self.isZooming = false
                })
            }
        }
        
    }
}


