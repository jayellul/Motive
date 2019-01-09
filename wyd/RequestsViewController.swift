//
//  RequestsViewController.swift
//  wyd
//
//  Created by Jason Ellul on 2018-05-22.
//  Copyright © 2018 Jason Ellul. All rights reserved.
//

import UIKit
import Firebase
import ODRefreshControl
import SDWebImage

// delagate table tutorials
// https://www.codementor.io/brettr/two-basic-ways-to-populate-your-uitableview-du107rsyx
// https://www.weheartswift.com/firebase-101/

class RequestsViewController: UIViewController {

    static let kUsersListPath = "users"
    let usersReference = Database.database().reference(withPath: kUsersListPath)
    // functions ref
    lazy var functions = Functions.functions()
    
    var currentUser: CurrentUser?
    var users = [User]()
    
    // get users from hash table instead of querying everytime
    var userHashTableDelegate: UserHashTableDelegate?
    var currentUserDelegate: CurrentUserDelegate?
    
    
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var headerViewHeightConstraint: NSLayoutConstraint!
    // ui kit components
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
    // is zooming for pinch pop
    var isZooming = false
    var pinchDelegate: PinchDelegate?
    // loading indicator
    let activityIndicator: UIActivityIndicatorView = {
        let activityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 25, height: 25))
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.hidesWhenStopped = true
        activityIndicator.color = UIColor.lightGray
        activityIndicator.isUserInteractionEnabled = false
        return activityIndicator
    }()
    
    @IBOutlet weak var transitionView: UIView!
    @IBOutlet weak var tableView: UITableView!
    lazy var customRefreshControl = ODRefreshControl(in: self.tableView)


    override func viewDidLoad() {
        super.viewDidLoad()
        setupSubviews()
        // set tabbarcontroller as delegate for access
        self.userHashTableDelegate = self.tabBarController as? UserHashTableDelegate
        self.currentUserDelegate = self.tabBarController as? CurrentUserDelegate
        tableView.tableFooterView = UIView (frame: CGRect.zero)
        tableView.layoutMargins = UIEdgeInsets.zero
        tableView.separatorInset = UIEdgeInsets.zero
        customRefreshControl?.addTarget(self, action: #selector(refreshControlAction(_:)), for: .valueChanged)
        // load users into the table
        loadTable()
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
        view.sendSubview(toBack: backgroundView)
        
        view.sendSubview(toBack: pinchView)
        self.view.addSubview(activityIndicator)
        view.bringSubview(toFront: activityIndicator)
        activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        activityIndicator.startAnimating()
    }
    
    // scroll to the top of the table
    @objc func headerLabelTapped(_ sender: Any) {
        tableView.setContentOffset(.zero, animated: true)
    }
    
    // function to populate table with cell - load users from database
    func loadTable() {
        if let currentUser = self.currentUser {
            let myGroup = DispatchGroup()
            var items: [User] = []
            for uid in currentUser.requests {
                // dispatch lock
                myGroup.enter()
                // check to see if userData is already in hashtable
                if let userData = self.userHashTableDelegate?.retrieveUser(uid: uid) {
                    items.append(userData)
                    myGroup.leave()
                    // if not in hashtable then load from firebase and store in hashtable
                } else {
                    getUser(uid: uid) { (result) in
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
                self.users = items
                self.tableView.reloadData()
                self.activityIndicator.stopAnimating()
                if (self.customRefreshControl?.isRefreshing)! {
                    self.run(after: 0.3, closure: {
                        self.customRefreshControl?.endRefreshing()
                    })
                }
            }
        }
    }
    
    // refresh control action - first update the current user then load the table
    @objc func refreshControlAction (_ sender: Any) {
        guard let currentUser = self.currentUser else { return }
        // get the signed in users profile
        getCurrentUser (uid: currentUser.user.uid) { (result) in
            if let newCurrentUser = result {
                // store the result
                self.currentUser = newCurrentUser
                self.currentUserDelegate?.storeCurrentUser(currentUser: newCurrentUser)
                self.userHashTableDelegate?.storeUser(user: newCurrentUser.user)
                self.loadTable()
            }
            self.run(after: 0.5, closure: {
                self.customRefreshControl?.endRefreshing()
            })
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
}

extension RequestsViewController: UITableViewDelegate , UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RequestTableViewCell") as! RequestTableViewCell
        let user = users[indexPath.row]
        cell.selectionStyle = .none
        cell.layoutMargins = UIEdgeInsets.zero
        // add title and username to cell
        cell.titleLabel.text = user.display
        cell.usernameLabel.text = "@" + user.username
        // default while loading = blank
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
        // add button functions as target and set tag as the indexPath row
        cell.acceptButton.addTarget(self, action: #selector(RequestsViewController.acceptTapped(_:)), for: .touchUpInside)
        cell.acceptButton.tag = indexPath.row
        cell.declineButton.addTarget(self, action: #selector(RequestsViewController.declineTapped(_:)), for: .touchUpInside)
        cell.declineButton.tag = indexPath.row
        return cell
    }
    
    // objective-c function for when user taps the accept button in any cell
    @objc func acceptTapped(_ sender: LoadingButton!) {
        // guard statements for optionals
        guard let currentUserUid = Auth.auth().currentUser?.uid else { return }
        guard let currentUser = (self.tabBarController as? CustomTabBarController)?.currentUser else { return }
        if currentUser.user.uid != currentUserUid { return }
        let indexPath = IndexPath(row: sender.tag, section: 0)
        let user = users[indexPath.row]
        let cell = tableView.cellForRow(at: indexPath) as! RequestTableViewCell
        cell.acceptButton.showLoading()
        cell.declineButton.isEnabled = false
        // remove from current users requests
        let kRequestsListPath = "requests"
        let requestsReference = Database.database().reference(withPath: kRequestsListPath)
        requestsReference.child(currentUserUid).child(user.uid).removeValue()
        // add to current users followers
        let kFollowersListPath = "followers"
        let followersReference = Database.database().reference(withPath: kFollowersListPath)
        let timestamp = Int64(NSDate().timeIntervalSince1970 * -1000)
        followersReference.child(currentUserUid).child(user.uid).setValue(timestamp)
        // add to other users following
        let kFollowingListPath = "following"
        let followingReference = Database.database().reference(withPath: kFollowingListPath)
        followingReference.child(user.uid).child(currentUserUid).setValue(true)
        // WRITE CURRENTUSERS NUM FOLLOWERS AND CELL USERS NUM FOLLOWING IN /USERS
        functionsRequestAcceptedCall(currentUserUid: currentUserUid, uid: user.uid)
        print ("db updated.")
        // update current user object
        currentUser.requests.remove(at: indexPath.row)
        currentUser.user.numFollowers += 1
        (self.tabBarController as? CustomTabBarController)?.currentUser = currentUser
        // store current user updated in hashtable
        var updatedCurrentUser = currentUser.user
        updatedCurrentUser.numFollowers += 1
        userHashTableDelegate?.storeUser(user: updatedCurrentUser)
        // update the cell user in hashtable delegate
        var updatedUser = user
        updatedUser.numFollowing += 1
        userHashTableDelegate?.storeUser(user: updatedUser)
        // remove cell, update table
        cell.acceptButton.hideLoading()
        cell.declineButton.isEnabled = true
        users.remove(at: indexPath.row)
        tableView.reloadData()
    }
    
    // call firebase functions to write num followers for user
    func functionsRequestAcceptedCall(currentUserUid: String, uid: String) {
        self.functions.httpsCallable("requestAccepted").call(["currentUserUid": currentUserUid, "uid": uid]) { (result, error) in
            if let error = error as NSError? {
                if error.domain == FunctionsErrorDomain {
                    let message = error.localizedDescription
                    print (message)
                }
            } else if let numFollowers = (result?.data as? [String: Any])?["numFollowers"] as? Int {
                if let numFollowing = (result?.data as? [String: Any])?["numFollowing"] as? Int {
                    // add to current users numfollowers count
                    self.usersReference.child(currentUserUid).child("nFers").setValue(numFollowers)
                    // add to other users numfollowing
                    self.usersReference.child(uid).child("nFing").setValue(numFollowing)
                }
                
            } else {
                print ("REQUEST ACCEPTED FUNCTION: BIG ERROR")
            }
        }
    }
    
    // objective-c function for when user taps the decline button in any cell
    @objc func declineTapped(_ sender: LoadingButton!) {
        guard let currentUserUid = Auth.auth().currentUser?.uid else { return }
        let indexPath = IndexPath(row: sender.tag, section: 0)
        let cell = tableView.cellForRow(at: indexPath) as! RequestTableViewCell
        let user = users[indexPath.row]
        cell.declineButton.showLoading()
        cell.acceptButton.isEnabled = false
        // update firebase
        let kRequestsListPath = "requests"
        let requestsReference = Database.database().reference(withPath: kRequestsListPath)
        requestsReference.child(currentUserUid).child(user.uid).removeValue()
        // update current user object
        if let customTabBarController = self.tabBarController as? CustomTabBarController {
            customTabBarController.currentUser?.requests.remove(at: indexPath.row)
        }
        cell.declineButton.hideLoading()
        cell.acceptButton.isEnabled = true
        // remove from table and reload
        users.remove(at: indexPath.row)
        tableView.reloadData()
    }

    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let user = users[indexPath.row]
        if let snapshotView = self.view.snapshotView(afterScreenUpdates: true) {
            let userViewController = storyboard?.instantiateViewController(withIdentifier: "userViewController") as! UserViewController
            userViewController.backgroundView = snapshotView
            userViewController.uid = user.uid
            userViewController.user = user
            self.navigationController?.pushViewController(userViewController, animated: true)
        }
    }
    

}

// MARK :- view poppers
extension RequestsViewController {
    
    // dynamic pop view controller
    @objc func panGestureRecognizerAction(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        if (translation.x >= 0) {
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
                UIView.animate(withDuration: 0.3) {
                    self.transitionView.frame.origin = CGPoint(x: 0.0, y: 0.0)
                }
            }
        }
    }
    
    @IBAction func goBackPressed(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
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
                    self.navigationController?.popToRootViewController(animated: false)
                    self.pinchDelegate?.viewPinched()
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
