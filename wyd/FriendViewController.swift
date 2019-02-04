//
//  FriendViewController.swift
//  wyd
//
//  Created by Jason Ellul on 2018-05-10.
//  Copyright © 2018 Jason Ellul. All rights reserved.
//

import UIKit
import Firebase
import SDWebImage


protocol FriendViewControllerDelegate {
    func refreshTable()
}
// delagate table tutorials
// https://www.codementor.io/brettr/two-basic-ways-to-populate-your-uitableview-du107rsyx
// https://www.weheartswift.com/firebase-101/
//
class FriendViewController: UIViewController, FriendViewControllerDelegate {

    
    
    
    // members of VC object
    // what type of friend VC this is - followers, following, or going
    enum tableType {
        case followers
        case following
        case going
    }
    // default type
    var type = FriendViewController.tableType.followers
    // firebase refs
    static let kUsersListPath = "users"
    let usersReference = Database.database().reference(withPath: kUsersListPath)
    static let kFollowersListPath = "followers"
    let followersReference = Database.database().reference(withPath: kFollowersListPath)
    static let kFollowingListPath = "following"
    let followingReference = Database.database().reference(withPath: kFollowingListPath)
    static let kPrivateListPath = "private"
    let privateReference = Database.database().reference(withPath: kPrivateListPath)
    static let kRequestsListPath = "requests"
    let requestsReference = Database.database().reference(withPath: kRequestsListPath)
    // functions ref
    lazy var functions = Functions.functions()

    // id set - could be motive id or user id for followers / following
    var id: String = "default"
    // refresh identier and boolean to determine if there are more users to laod from the query
    private let refreshIdentifier = "refreshIdentifier"
    var outOfUsers: Bool = false
    var loadingMoreUsers: Bool = false
    // getmoreueser query parameters
    let numUsersToLoad: UInt = 15
    var lastKey: String = ""
    
    var previousViewId = ""
    // array of users to display in table
    var users = [User]()
    
    var userHashTableDelegate: UserHashTableDelegate?
    var pinchDelegate: PinchDelegate?
    // is zooming for pinch pop
    var isZooming = false

    // ui kit
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var transitionView: UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var headerViewHeightConstraint: NSLayoutConstraint!
    
    var backgroundView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = true
        view.isUserInteractionEnabled = false
        view.backgroundColor = UIColor.black
        return view
    }()
    // background view for pinch
    var pinchView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = true
        view.isUserInteractionEnabled = false
        view.backgroundColor = UIColor.black
        return view
    }()

    // loading indicator
    let activityIndicator: UIActivityIndicatorView = {
        let activityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 25, height: 25))
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.hidesWhenStopped = true
        activityIndicator.color = UIColor.lightGray
        activityIndicator.isUserInteractionEnabled = false
        return activityIndicator
    }()
    

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        setupSubviews()
        // set tab bar delegate
        self.userHashTableDelegate = self.tabBarController as? UserHashTableDelegate
        // set up table
        tableView.tableFooterView = UIView (frame: CGRect.zero)
        tableView.layoutMargins = UIEdgeInsets.zero
        tableView.separatorInset = UIEdgeInsets.zero
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: refreshIdentifier)
        setupActivityIndicator()
        loadFriendsTable()
        
        // add transition view swipe
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panGestureRecognizerAction(_:)))
        // add transition view pinch
        let pinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(pinchGestureRecognizerAction(_:)))
        // tap to go to top of table
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(headerLabelTapped(_:)))
        // delay for 0.5 seconds before enabling gestures
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // add swipe right gesture
            self.transitionView.addGestureRecognizer(panGestureRecognizer)
            self.transitionView.addGestureRecognizer(pinchGestureRecognizer)
            self.headerLabel.isUserInteractionEnabled = true
            self.headerLabel.addGestureRecognizer(tapGestureRecognizer)
        }
    }
    // scroll to the top of the table
    @objc func headerLabelTapped(_ sender: Any) {
        tableView.setContentOffset(.zero, animated: true)
    }
    
    func setupSubviews() {
        headerView.frame.size.height = 75
        headerView.frame.size.width = view.frame.width
        headerView.bounds.size.width = view.frame.width
        if self.isPhoneX() {
            headerViewHeightConstraint.constant = 100
            headerView.frame.size.height = 100
        }
        addGradientToView(headerView)

        backgroundView.frame = view.bounds
        pinchView.frame = view.bounds
        let blurView = self.applyBlurEffect(toView: pinchView)
        pinchView = blurView
        view.addSubview(backgroundView)
        view.addSubview(pinchView)
        view.sendSubview(toBack: pinchView)
        view.sendSubview(toBack: backgroundView)
    }
    
    func setupActivityIndicator() {
        self.transitionView.addSubview(activityIndicator)
        transitionView.bringSubview(toFront: activityIndicator)
        activityIndicator.centerXAnchor.constraint(equalTo: transitionView.centerXAnchor).isActive = true
        activityIndicator.centerYAnchor.constraint(equalTo: transitionView.centerYAnchor).isActive = true
        activityIndicator.startAnimating()
    }
    
    // function that loads users into table
    func loadFriendsTable() {
        // type switch - decides headerLabel text and what type of table to load
        loadingMoreUsers = true
        var dbPath = "followers"
        switch type {
        case .followers:
            headerLabel.text = "Followers"
        case .following:
            dbPath = "following"
            headerLabel.text = "Following"
        case .going:
            dbPath = "usersGoing"
            headerLabel.text = "Going"
            // make a new load function for going cus u will need a backend call to get going
        }
        // get uid list
        let uidReference = Database.database().reference(withPath: dbPath)
        uidReference.child(id).queryOrderedByKey().queryLimited(toFirst: numUsersToLoad).observeSingleEvent(of: .value) { (snapshot) in
            if snapshot.exists() {
                var uids: [String] = []
                for item in snapshot.children.allObjects as! [DataSnapshot] {
                    uids.append(item.key)
                }
                uids.sort(by: {( ($0) < ($1) )})
                self.lastKey = uids.last ?? ""
                print ("OG Last Key " + self.lastKey)
                // load users from original ids
                let myGroup = DispatchGroup()
                var items: [User] = []
                for uid in uids {
                    // dispatch lock
                    myGroup.enter()
                    // check to see if its in hashtable
                    if let user = self.userHashTableDelegate?.retrieveUser(uid: uid) {
                        items.append(user)
                        myGroup.leave()
                        // if not in hashtable then load from firebase and store in hashtable
                    } else {
                        self.getUser(uid: uid) { (result) in
                            if let user = result {
                                // store result and append to table data source
                                self.userHashTableDelegate?.storeUser(user: user)
                                items.append(user)
                            }
                            myGroup.leave()
                        }
                    }
                }
                // wait until every member of mygroup is finished
                myGroup.notify(queue: .main) {
                    self.activityIndicator.stopAnimating()
                    self.users = items
                    if items.count < self.numUsersToLoad {
                        self.outOfUsers = true
                    }
                    self.loadingMoreUsers = false
                    self.tableView.reloadData()
                }
                
            } else {
                self.activityIndicator.stopAnimating()
                self.outOfUsers = true
                self.loadingMoreUsers = false
                self.users.removeAll()
                self.tableView.reloadData()
            }
        }
    
    }
    
    func getMoreUsers() {
        loadingMoreUsers = true
        // type switch - decides headerLabel text and what type of table to load
        var dbPath = "followers"
        switch type {
        case .followers:
            headerLabel.text = "Followers"
        case .following:
            dbPath = "following"
            headerLabel.text = "Following"
        case .going:
            dbPath = "usersGoing"
            headerLabel.text = "Going"
            // make a new load function for going cus u will need a backend call to get going
        }
        // get uid list
        let uidReference = Database.database().reference(withPath: dbPath)
        uidReference.child(id).queryOrderedByKey().queryStarting(atValue: lastKey).queryLimited(toFirst: numUsersToLoad + 1).observeSingleEvent(of: .value) { (snapshot) in
            if snapshot.exists() {
                var snapshotArray = [DataSnapshot]()
                // get all ids that the user is going and sort by time
                for item in snapshot.children {
                    let snap = item as! DataSnapshot
                    if snap.key != self.lastKey {
                        snapshotArray.append(snap)
                    }
                }
                if snapshotArray.count == 0 {
                    self.outOfUsers = true
                    self.loadingMoreUsers = false
                    self.tableView.reloadData()
                    return
                }
                snapshotArray.sort(by: {( ($0.key) < ($1.key) )})
                // get the largest key / uid?
                self.lastKey = snapshotArray.last?.key ?? ""
                print ("new Last Key " + self.lastKey)
                let myGroup = DispatchGroup()
                var items: [User] = []
                // load motives from snapshotted ids
                for (i, goingSnapshot) in snapshotArray.enumerated() {
                    print ("index: " + String(i) + " value: " + String(goingSnapshot.key.debugDescription))
                    myGroup.enter()
                    // check to see if its in hashtable
                    let uid = goingSnapshot.key
                    if let user = self.userHashTableDelegate?.retrieveUser(uid: uid) {
                        items.append(user)
                        myGroup.leave()
                        // if not in hashtable then load from firebase and store in hashtable
                    } else {
                        self.getUser(uid: uid) { (result) in
                            if let user = result {
                                // store result and append to table data source
                                self.userHashTableDelegate?.storeUser(user: user)
                                items.append(user)
                            }
                            myGroup.leave()
                        }
                    }
                }
                // wait until every member of mygroup is finished
                myGroup.notify(queue: .main) {
                    self.users = self.users + items
                    self.loadingMoreUsers = false
                    if snapshotArray.count < self.numUsersToLoad {
                        print ("less then")
                        self.outOfUsers = true
                    }
                    self.tableView.reloadData()
                }
            } else {
                self.outOfUsers = true
                self.loadingMoreUsers = false
                self.tableView.reloadData()
                return
            }
        }
    }
    

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
}

extension FriendViewController: UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y + 300 >= scrollView.contentSize.height - scrollView.frame.height {
            if !outOfUsers && !loadingMoreUsers {
                getMoreUsers()
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count + 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == users.count {
            let cell = tableView.dequeueReusableCell(withIdentifier: refreshIdentifier)
            cell?.separatorInset = UIEdgeInsetsMake(0, tableView.frame.width / 2, 0, tableView.frame.width / 2)
            // if there are NO motives in going or posts
            if users.count == 0 || outOfUsers {
                return cell!
            }
            // else refresh cell
            let activityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
            cell?.addSubview(activityIndicator)
            activityIndicator.translatesAutoresizingMaskIntoConstraints = false
            activityIndicator.centerXAnchor.constraint(equalTo: (cell?.centerXAnchor)!).isActive = true
            activityIndicator.centerYAnchor.constraint(equalTo: (cell?.centerYAnchor)!).isActive = true
            activityIndicator.activityIndicatorViewStyle = .gray
            activityIndicator.hidesWhenStopped = true
            activityIndicator.startAnimating()
            return cell!
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "UserTableViewCell") as! UserTableViewCell
            // THE user of the user table view cell
            let user = users[indexPath.row]
            cell.selectionStyle = .none
            cell.layoutMargins = UIEdgeInsets.zero
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
                        cell.followingButton.removeTarget(self, action: #selector(self.requestSentPressed(_:)), for: .touchUpInside)
                        cell.followingButton.addTarget(self, action: #selector(FriendViewController.alreadyFollowingPressed(_:)), for: .touchUpInside)
                        return cell
                    }
                    // if current user has requested to follow cell user
                    if user.requestSent {
                        cell.setupRequestSentButton()
                        cell.followingButton.removeTarget(self, action: #selector(self.alreadyFollowingPressed(_:)), for: .touchUpInside)
                        cell.followingButton.addTarget(self, action: #selector(self.requestSentPressed(_:)), for: .touchUpInside)
                        return cell
                    }
                    // not currently following or requested
                    // display addFriendButton
                    cell.setupFollowButton()
                    cell.followButton.addTarget(self, action: #selector(FriendViewController.followPressed(_:)), for: .touchUpInside)
                    return cell
                }
            }
            // error - remove side button and return
            cell.loadingButton.removeFromSuperview()
            return cell
        }
    }
    // add friend is pressed when user is not private
    @objc func followPressed (_ sender: UIButton!) {
        guard let currentUserUid = Auth.auth().currentUser?.uid else { return }
        let indexPath = IndexPath(row: sender.tag, section: 0)
        let cell = tableView.cellForRow(at: indexPath) as! UserTableViewCell
        cell.followButton.showLoading()
        // change requestSent status in userHashTable
        let user = users[indexPath.row]
        let cellUid = user.uid
        // send friend request to view user
        let timestamp = Int64(NSDate().timeIntervalSince1970 * -1000)
        privateReference.child(cellUid).observeSingleEvent(of: .value) { (snapshot) in
            if snapshot.exists() {
                // user is private - send request to cell user
                self.requestsReference.child(cellUid).child(currentUserUid).setValue(timestamp)
                // update hash table user object
                var updatedUser = user
                updatedUser.requestSent = true
                self.userHashTableDelegate?.storeUser(user: updatedUser)
                self.users[indexPath.row] = updatedUser
                cell.setupRequestSentButton()
                cell.followingButton.removeTarget(self, action: #selector(self.alreadyFollowingPressed(_:)), for: .touchUpInside)
                cell.followingButton.addTarget(self, action: #selector(self.requestSentPressed(_:)), for: .touchUpInside)
            } else {
                // user is not private - follow cell user
                self.followersReference.child(cellUid).child(currentUserUid).setValue(timestamp)
                self.followingReference.child(currentUserUid).child(cellUid).setValue(true)
                // update objects in tab bar
                if let currentUser = (self.tabBarController as? CustomTabBarController)?.currentUser {
                    // push notification and followers counter for user in cell
                    self.functions.httpsCallable("countFollowers").call(["id": cellUid, "name": currentUser.user.username]) { (result, error) in
                        if let error = error as NSError? {
                            if error.domain == FunctionsErrorDomain {
                                let message = error.localizedDescription
                                print (message)
                            }
                        } else if let numFollowers = (result?.data as? [String: Any])?["num"] as? Int {
                            print (numFollowers)
                            self.usersReference.child(cellUid).child("nFers").setValue(numFollowers)
                        }
                    }
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
                self.users[indexPath.row] = updatedUser
                // change add button to request Sent button
                cell.setupAlreadyFollowingButton()
                cell.followingButton.removeTarget(self, action: #selector(self.requestSentPressed(_:)), for: .touchUpInside)
                cell.followingButton.removeTarget(self, action: #selector(self.alreadyFollowingPressed(_:)), for: .touchUpInside)
                //cell.followingButton.addTarget(self, action: #selector(self.alreadyFollowingPressed(_:)), for: .touchUpInside)
            }
            cell.followButton.hideLoading()
        }

    }
    
    
    @objc func alreadyFollowingPressed (_ sender: UIButton!) {
        /*let currentUserUid = (Auth.auth().currentUser?.uid)!
        let cellUser = users[sender.tag]
        // Create the alert controller.
        let alert = UIAlertController(title: "Remove Friend", message: "Are you sure you want to remove @" + cellUser.username + " as a friend?" , preferredStyle: .alert)
        
        // add a cancel button
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil))
        
        // remove user from both people friends list
        alert.addAction(UIAlertAction(title: "Remove", style: .default, handler: { [] (_) in
            self.usersReference.child(currentUserUid).child("friends").child(cellUser.uid).removeValue()
            self.usersReference.child(cellUser.uid).child("friends").child(currentUserUid).removeValue()
            self.users.remove(at: sender.tag)
            self.tableView.reloadData()
        }))
        
        // Present the alert.
        self.present(alert, animated: true, completion: nil)*/
    }
    
    // undo the follow request
    @objc func requestSentPressed(_ sender: UIButton!) {
        guard let currentUserUid = Auth.auth().currentUser?.uid else { return }
        let indexPath = IndexPath(row: sender.tag, section: 0)
        let cell = tableView.cellForRow(at: indexPath) as! UserTableViewCell
        // change requestSent status in userHashTable
        let user = users[indexPath.row]
        let cellUid = user.uid
        self.requestsReference.child(cellUid).child(currentUserUid).removeValue()
        // update tab bar objects
        // update hash table user object
        var updatedUser = user
        updatedUser.requestSent = false
        userHashTableDelegate?.storeUser(user: updatedUser)
        users[indexPath.row] = updatedUser
        cell.setupFollowButton()
        cell.followingButton.removeTarget(self, action: #selector(self.requestSentPressed(_:)), for: .touchUpInside)
        cell.followingButton.addTarget(self, action: #selector(self.followPressed(_:)), for: .touchUpInside)
    }
    
    // impletmented the height methods so that its not jumpy on reload
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        // finished cell (no more users to load)
        if outOfUsers && indexPath.row >= users.count {
            return 0
        }
        // refresh cell
        if indexPath.row >= users.count {
            return 50
        }
        return 90
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        if outOfUsers && indexPath.row >= users.count {
            return 0
        }
        if indexPath.row >= users.count {
            return 50
        }
        return 90
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row >= users.count {
            tableView.deselectRow(at: indexPath, animated: false)
            return
        }
        let user = users[indexPath.row]
        if user.uid == previousViewId { self.navigationController?.popViewController(animated: true); return }
        if let snapshotView = self.view.snapshotView(afterScreenUpdates: true) {
            for subview in pinchView.subviews {
                if subview is UIVisualEffectView { subview.isHidden = true }
            }
            if let pinchSnapshotView = self.pinchView.snapshotView(afterScreenUpdates: true) {
                let userViewController = storyboard?.instantiateViewController(withIdentifier: "userViewController") as! UserViewController
                userViewController.backgroundView = snapshotView
                for subview in pinchView.subviews {
                    if subview is UIVisualEffectView { subview.isHidden = false }
                }
                userViewController.pinchView = pinchSnapshotView
                userViewController.pinchDelegate = self.pinchDelegate
                userViewController.uid = user.uid
                userViewController.user = user
                // set delegate since its from a table
                userViewController.friendViewControllerDelegate = self
                self.navigationController?.pushViewController(userViewController, animated: true)
            }
        }
    }
    
    func refreshTable() {
        tableView.reloadData()
    }
    
    
    
}

// MARK - view poppers
extension FriendViewController {
    // pop view controller - dont know how many are nested
    @IBAction func goBackPressed(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    
    @objc func panGestureRecognizerAction(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        if (translation.x >= 0) {
            backgroundView.isHidden = false
            pinchView.isHidden = true
            transitionView.frame.origin.x = translation.x
        }
        
        let velocity = gesture.velocity(in: view)
        
        if gesture.state == .ended {
            // if velocity is fast enough, pop
            if (velocity.x >= 600) {
                UIView.animate(withDuration: TimeInterval((self.view.frame.width - translation.x) / velocity.x), delay: 0.0, animations: {
                    // animate origin moring off screen
                    self.transitionView.frame.origin = CGPoint(x: self.view.frame.width, y: 0.0)
                }, completion: {(finished:Bool) in
                    // animation finishes
                    self.navigationController?.popViewController(animated: false)
                    //self.dismiss(animated: true, completion: nil)
                })
                // over half the screen, pop
            } else if (translation.x >= view.frame.width / 2) {
                UIView.animate(withDuration: 0.3, delay: 0.0, animations: {
                    // animate origin moring off screen
                    self.transitionView.frame.origin = CGPoint(x: self.view.frame.width, y: 0.0)
                }, completion: {(finished:Bool) in
                    // animation finishes
                    self.navigationController?.popViewController(animated: false)
                    //self.dismiss(animated: true, completion: nil)
                })
                // go back to origin
            } else {
                UIView.animate(withDuration: 0.3, delay: 0.0, animations: {
                    // reset transitionview frame
                    self.transitionView.frame.origin = CGPoint(x: 0.0, y: 0.0)
                }, completion: {(finished:Bool) in
                    self.pinchView.isHidden = false
                })
            }
        }
    }
    
    
    @objc func pinchGestureRecognizerAction(_ sender: UIPinchGestureRecognizer) {
        if sender.state == .began {
            if sender.scale <= 1 {
                isZooming = true
                backgroundView.isHidden = true
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
                    self.tabBarController?.selectedIndex = 0
                    self.pinchDelegate?.viewPinched()
                    self.navigationController?.popToRootViewController(animated: false)
                })
            } else {
                // reset view
                UIView.animate(withDuration: 0.25, animations: {
                    self.transitionView.transform = CGAffineTransform.identity
                    self.transitionView.alpha = 1.0
                    self.transitionView.frame = self.view.frame
                }, completion: { _ in
                    self.isZooming = false
                    self.backgroundView.isHidden = false
                    
                })
            }
        }
        
    }
    
}


