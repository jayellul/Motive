//
//  FeedViewController.swift
//  wyd
//
//  Created by Jason Ellul on 2018-05-10.
//  Copyright © 2018 Jason Ellul. All rights reserved.
//

import UIKit
import Firebase
import SDWebImage
import ODRefreshControl



// delegate for passing to parent vc
// https://stackoverflow.com/questions/35439041/how-to-send-values-to-a-parent-view-controller-in-swift/35439116?utm_medium=organic&utm_source=google_rich_qa&utm_campaign=google_rich_qa
protocol FeedDelegate {
    func feedSentRefresh()
    func feedSelectedMotive(motive: Motive)
}
class FeedViewController: UIViewController, SliderDelegate, TabDelegate, PinchDelegate {

    

    
    
    // delegate for map view
    var delegate: FeedDelegate?
    var annotationDelegate: AnnotationDelegate?
    var pinchDelegate: PinchDelegate?
    // delegate for Tab view
    var tabDelegate: FeedDelegate?
    var loaded = false
    var completedFirstLoad = false
    
    var userHashTableDelegate: UserHashTableDelegate?
    var currentUserDelegate: CurrentUserDelegate?
    var currentUser: CurrentUser?
    var motiveHashTableDelegate: MotiveHashTableDelegate?

    var isZooming = false
    // firebase db refs
    static let kUsersListPath = "users"
    let usersReference = Database.database().reference(withPath: kUsersListPath)
    static let kMotivesListPath = "motives"
    let motivesReference = Database.database().reference(withPath: kMotivesListPath)
    static let kMotivesGoingListPath = "motivesGoing"
    let motivesGoingReference = Database.database().reference(withPath: kMotivesGoingListPath)
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
    // header view adjust for iphonex
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var headerViewHeightConstraint: NSLayoutConstraint!
    // top Feed label
    @IBOutlet weak var feedLabel: UILabel!

    // table variables
    @IBOutlet weak var tableView: UITableView!
    lazy var customRefreshControl = ODRefreshControl(in: self.tableView)

    // from tab bar
    var motiveAndUsers = [MotiveAndUser]()
    var motivesIdsSet: Set<String> = []
    
    var sort = 0 // default 0 is latest, 1 is popular, 2 is nearest

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
        // feed buton goes to top of table
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(feedLabelTapped(_:)))
        // delay for 0.5 seconds before enabling gestures
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // add gestures
            self.transitionView.addGestureRecognizer(pinchGestureRecognizer)
            self.feedLabel.isUserInteractionEnabled = true
            self.feedLabel.addGestureRecognizer(tapGestureRecognizer)
        }
        
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

        // tableView properties
        tableView.frame.size.width = transitionView.frame.width
        tableView.bounds.size.width = transitionView.frame.width 
        tableView.tableFooterView = UIView (frame: CGRect.zero)
        tableView.layoutMargins = UIEdgeInsets.zero
        tableView.separatorInset = UIEdgeInsets.zero
        tableView.estimatedRowHeight = 50
        tableView.rowHeight = UITableViewAutomaticDimension
    }

    
    // refresh control - just call tab bar and get new motives
    @objc func refreshControlAction(_ sender: Any) {
        tabDelegate?.feedSentRefresh()
    }
    
    
    func showLoading() {
        
    }
    
    // get all motives from tab bar and then load first numMotivesToLoad users
    func hideLoading() {
        let customTabBarController = self.tabBarController as! CustomTabBarController
        self.motiveAndUsers = customTabBarController.feedMotives
        annotationDelegate?.addMotivesToMap(motiveAndUsers: self.motiveAndUsers)
        // defualt back to latest
        //self.sort = 0
        // if xib has been initialized
        if loaded {
            loadMotiveTable()
        }
    }
    
    
    func loadMotiveTable() {
        // sort by time
        if (self.sort == 0) {
            self.motiveAndUsers.sort(by: { ($0.motive.time < $1.motive.time)})
        // sort by numGoing and then time as tiebreaker
        } else if (self.sort == 1) {
            // https://stackoverflow.com/questions/37603960/swift-sort-array-of-objects-with-multiple-criteria
            self.motiveAndUsers.sort(by: {( $0.motive.numGoing == $1.motive.numGoing ? $0.motive.time < $1.motive.time : $0.motive.numGoing > $1.motive.numGoing)})
        // sort by nearest?
        } else {
            self.motiveAndUsers.sort(by: { ($0.motive.time < $1.motive.time)})
        }
        // has to be done on main thread
        if self.customRefreshControl?.isRefreshing == true {
            self.tableView.reloadData()
            self.completedFirstLoad = true
            self.run(after: 0.3, closure: {
                self.customRefreshControl?.endRefreshing()
            })
        } else {
            self.tableView.setContentOffset(.zero, animated: true)
            self.tableView.reloadData()
            self.completedFirstLoad = true
        }
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
    // slider modal selected a row
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
                //if let pinchSnapshotView = self.pinchView {
                    let userViewController = storyboard?.instantiateViewController(withIdentifier: "userViewController") as! UserViewController
                    userViewController.backgroundView = snapshotView
                    userViewController.pinchView = pinchView
                    userViewController.uid = currentUser.user.uid
                    userViewController.user = currentUser.user
                    userViewController.pinchDelegate = self
                    self.navigationController?.pushViewController(userViewController, animated: true)
                //}
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
    
    // view pinched and went to map view
    func viewPinched() {
        self.navigationController?.popToRootViewController(animated: false)
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
extension FeedViewController: UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate, CalloutViewDelegate, UIActionSheetDelegate {
    func morePressed(motive: Motive) {
        let actionSheet = UIActionSheet(title: "Choose Option", delegate: self, cancelButtonTitle: "Cancel", destructiveButtonTitle: nil, otherButtonTitles: "Save", "Delete")
        
        actionSheet.show(in: self.view)
    }
    func actionSheet(actionSheet: UIActionSheet, clickedButtonAtIndex buttonIndex: Int)
    {
        switch (buttonIndex){
            
        case 0:
            print("Cancel")
        case 1:
            print("Save")
        case 2:
            print("Delete")
        default:
            print("Default")
            //Some code here..
            
        }
    }
    
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print ("num posts " + self.motiveAndUsers.count.description)
        return self.motiveAndUsers.count
    }
    
    // if table scrolled
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
    }
    
    
    // setting the height for all table rows
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    // setting the estimated height for all table rows
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
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
        // send info to map view controller and tab controller delegate
        let motive = motiveAndUsers[indexPath.row].motive
        tabDelegate?.feedSelectedMotive(motive: motive)
        delegate?.feedSelectedMotive(motive: motive)
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



// MARK - pinch gesture
extension FeedViewController {
    
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




