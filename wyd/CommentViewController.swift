//
//  CommentViewController.swift
//  wyd
//
//  Created by Jason Ellul on 2018-10-16.
//  Copyright © 2018 Jason Ellul. All rights reserved.
//

import UIKit
import Firebase
import SDWebImage

class CommentViewController: UIViewController, CustomInputAccessoryDelegate {
    

    
    // firebase db refs
    static let kUsersListPath = "users"
    let usersReference = Database.database().reference(withPath: kUsersListPath)
    static let kMotivesListPath = "motives"
    let motivesReference = Database.database().reference(withPath: kMotivesListPath)
    static let kArchiveListPath = "archive"
    let archiveReference = Database.database().reference(withPath: kArchiveListPath)
    static let kCommentsListPath = "comments"
    let commentsReference = Database.database().reference(withPath: kCommentsListPath)
    static let kMotiveCommentsListPath = "motiveComments"
    let motiveCommentsReference = Database.database().reference(withPath: kMotiveCommentsListPath)
    lazy var functions = Functions.functions()

    private let reuseIdentifier = "commentTableViewCell"
    private let refreshIdentifier = "refreshIdentifier"

    let numCommentsToLoad: UInt = 15
    
    var lastCommentTime: Int = 0
    var outOfComments: Bool = false
    var loadingMoreComments: Bool = true
    
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var headerViewHeightConstraint: NSLayoutConstraint!
    // ui kit components
    var backgroundView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = true
        view.isUserInteractionEnabled = false
        view.isHidden = true
        view.backgroundColor = UIColor.black
        return view
    }()
    
    @IBOutlet weak var transitionView: UIView!
    var foregroundView: UIView = {
        let view = UIView()
        view.isUserInteractionEnabled = false
        view.translatesAutoresizingMaskIntoConstraints = true
        view.backgroundColor = UIColor.clear
        view.isHidden = true
        return view
    }()
    @IBOutlet weak var tableView: UITableView!
    // background view for pinch
    var pinchView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = true
        view.isUserInteractionEnabled = false
        view.backgroundColor = UIColor.black
        return view
    }()
    var isZooming = false
    var isPanning = false
    // pinch delegate to pop map VC to root when pinched
    var pinchDelegate: PinchDelegate?
    var yOrigin: CGFloat = 0
    var keyboardHeight: CGFloat = 0
    var keyboardDuration: Double = 0
    var keyboardAnimationCurve: UInt = 0

    var currentUser: CurrentUser?
    var userHashTableDelegate: UserHashTableDelegate?
    var motiveHashTableDelegate: MotiveHashTableDelegate?

    var motive: Motive?
    var commentAndUsers: [CommentAndUser] = []
    
    // custom input accessory view above keyboard
    lazy var bottomView: CustomInputAccessoryView = {
        let custom = CustomInputAccessoryView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 60))
        custom.customInputAccessoryDelegate = self
        custom.setupSubviews()
        return custom
    }()
    // https://www.youtube.com/watch?v=ky7YRh01by8
    override var inputAccessoryView: UIView? {
        get {
            return bottomView
        }
    }

    
    override var canBecomeFirstResponder: Bool { return true }

    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // additional setup after loading the view controller
        setupSubviews()
        userHashTableDelegate = tabBarController as? CustomTabBarController
        motiveHashTableDelegate = tabBarController as? CustomTabBarController

        // add keyboard obersvers
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: Notification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: Notification.Name.UIKeyboardWillHide, object: nil)
        
        //NotificationCenter.default.addObserver(self, selector: #selector(appMovedToBackground), name: Notification.Name.UIApplicationWillResignActive, object: nil)

        // add transition view swipe
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panGestureRecognizerAction(_:)))
        panGestureRecognizer.delegate = self
        // add transition view pinch
        let pinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(pinchGestureRecognizerAction(_:)))
        // delay for 0.5 seconds before enabling gestures
        self.run(after: 0.5) {
            self.transitionView.addGestureRecognizer(panGestureRecognizer)
            self.transitionView.addGestureRecognizer(pinchGestureRecognizer)
        }
        
        // get comments and users from database
        loadComments()
      
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        // Don't have to do this on iOS 9+, but it still works
        NotificationCenter.default.removeObserver(self)
    }
    
    
    
    func setupSubviews() {
        headerView.frame.size.height = 75
        headerView.frame.size.width = view.frame.width
        headerView.bounds.size.width = view.frame.width
        if isPhoneX() {
            headerViewHeightConstraint.constant = 100
            headerView.frame.size.height = 100
            yOrigin = 40
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
        transitionView.bounds = view.bounds
        transitionView.frame = view.bounds
        transitionView.addSubview(foregroundView)
        transitionView.bringSubview(toFront: foregroundView)
        foregroundView.frame = transitionView.frame
        // setup table
        tableView.frame.size.width = transitionView.frame.width
        tableView.bounds.size.width = transitionView.frame.width
        tableView.register(CommentTableViewCell.self, forCellReuseIdentifier: reuseIdentifier)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: refreshIdentifier)
        tableView.tableFooterView = UIView (frame: CGRect.zero)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = UITableViewCellSeparatorStyle.singleLine
        tableView.allowsMultipleSelection = false
        tableView.alwaysBounceVertical = true
        tableView.estimatedRowHeight = 50
        tableView.rowHeight = UITableViewAutomaticDimension
        // add interactive keyboard dismissal to table
        tableView.keyboardDismissMode = .interactive
        let insets = UIEdgeInsets(top: 0, left: 0, bottom: bottomView.frame.height, right: 0)
        tableView.contentInset = insets
        tableView.scrollIndicatorInsets = insets
        // download and set profile image
        if let currentUser = self.currentUser {
            if let url = URL(string: currentUser.user.photoURL) {
                bottomView.profileImageView.sd_setImage(with: url) { (image, error, cache, urls) in
                    if error == nil {
                        self.bottomView.profileImageView.image = image
                    } else {
                        self.bottomView.profileImageView.image = nil
                    }
                }
            }
        }
    }
    
    // initially load comments from database and place 
    func loadComments() {
        getComments { (comments) in
            self.getUsersForComments(comments, completionHandler: { (result) in
                self.commentAndUsers = result
                self.tableView.reloadData()
                // scroll to bottom (most recent)
                if self.commentAndUsers.count > 0 {
                    let indexPath = IndexPath(row: self.commentAndUsers.count, section: 0)
                    self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: false)
                }
                self.loadingMoreComments = false
            })
        }
    }

    func getComments(completionHandler:@escaping (_ result: [Comment]) -> Void) {
        guard let motive = self.motive else { return }
        var comments = [Comment]()
        var snapshotArray = [DataSnapshot]()
        motiveCommentsReference.child(motive.id).queryOrderedByValue().queryLimited(toFirst: numCommentsToLoad).observeSingleEvent(of: .value) { (snapshot) in
            if snapshot.exists() {
                // get all ids that the user is going
                for item in snapshot.children {
                    let snap = item as! DataSnapshot
                    snapshotArray.append(snap)
                }
                snapshotArray.sort(by: {( ($0.value as! Int) < ($1.value as! Int) )})
                self.lastCommentTime = snapshotArray.last?.value as! Int
                let myGroup = DispatchGroup()
                for (_, motiveCommentSnapshot) in snapshotArray.enumerated() {
                    myGroup.enter()
                    self.commentsReference.child(motiveCommentSnapshot.key).observeSingleEvent(of: .value, with: { (snapshot) in
                        if snapshot.exists() {
                            let comment = Comment(snapshot: snapshot)
                            comments.append(comment)
                        }
                        myGroup.leave()
                    })
                }
                myGroup.notify(queue: .main) {
                    if comments.count < self.numCommentsToLoad {
                        self.outOfComments = true
                    }
                    completionHandler(comments)
                    return
                }
                
            } else {
                self.outOfComments = true
                completionHandler(comments)
                return
            }
        }
    }
    
    // called if scrolled to the top
    func loadMoreComments() {
        loadingMoreComments = true
        getMoreComments { (comments) in
            self.getUsersForComments(comments, completionHandler: { (result) in
                self.commentAndUsers = result + self.commentAndUsers
                self.tableView.reloadData()
                self.tableView.layoutIfNeeded()
                // calculate added height
                var addedHeight: CGFloat = 0
                for i in 0...result.count {
                    let indexRow = i + 1
                    let tempIndexPath = IndexPath(row: Int(indexRow), section: 0)
                    addedHeight = addedHeight + self.tableView.rectForRow(at: tempIndexPath).height
                }
                self.tableView.contentOffset.y = self.tableView.contentOffset.y + addedHeight
                self.loadingMoreComments = false
            })
        }
    }
    
    func getMoreComments(completionHandler:@escaping (_ result: [Comment]) -> Void) {
        guard let motive = self.motive else { return }
        var comments = [Comment]()
        var snapshotArray = [DataSnapshot]()
        print ("GetMoreComments Query time: " + String(lastCommentTime + 1))
        motiveCommentsReference.child(motive.id).queryOrderedByValue().queryStarting(atValue: lastCommentTime + 1).queryLimited(toFirst: numCommentsToLoad).observeSingleEvent(of: .value, with: { (snapshot) in
            if snapshot.exists() {
                // get all ids that the user is going
                for item in snapshot.children {
                    let snap = item as! DataSnapshot
                    snapshotArray.append(snap)
                }
                snapshotArray.sort(by: {( ($0.value as! Int) < ($1.value as! Int) )})
                self.lastCommentTime = snapshotArray.last?.value as! Int
                let myGroup = DispatchGroup()
                for (_, motiveCommentSnapshot) in snapshotArray.enumerated() {
                    myGroup.enter()
                    self.commentsReference.child(motiveCommentSnapshot.key).observeSingleEvent(of: .value, with: { (snapshot) in
                        if snapshot.exists() {
                            let comment = Comment(snapshot: snapshot)
                            comments.append(comment)
                        }
                        myGroup.leave()
                    })
                }
                myGroup.notify(queue: .main) {
                    if comments.count < self.numCommentsToLoad {
                        self.outOfComments = true
                    }
                    completionHandler(comments)
                    return
                }
                
            } else {
                self.outOfComments = true
                completionHandler(comments)
                return
            }
        })
    }
    
    // download users and create the table of comments
    func getUsersForComments(_ comments: [Comment], completionHandler:@escaping (_ result: [CommentAndUser]) -> Void) {
        let myGroup = DispatchGroup()
        var commentAndUsers: [CommentAndUser] = []
        let sortedComments = comments.sorted(by: {( ($0.time) < ($1.time) )})
        for (i, comment) in sortedComments.enumerated() {
            myGroup.enter()
            // get creator data
            // check to see if its in hashtable
            if let user = self.userHashTableDelegate?.retrieveUser(uid: comment.creatorID) {
                let commentAndUser = CommentAndUser(comment: comment, user: user)
                commentAndUser.index = i
                commentAndUsers.append(commentAndUser)
                myGroup.leave()
            } else {
                // if not in hashtable then load from firebase and store in hashtable
                getUser(uid: comment.creatorID) { (result) in
                    if let user = result {
                        self.userHashTableDelegate?.storeUser(user: user)
                        let commentAndUser = CommentAndUser(comment: comment, user: user)
                        commentAndUser.index = i
                        commentAndUsers.append(commentAndUser)
                    }
                    myGroup.leave()
                }
                
            }
        }
        // once all users are finished loading
        myGroup.notify(queue: .main) {
            // sort by index to avoid async errors
            commentAndUsers.sort(by: { ($0.index > $1.index)})
            completionHandler(commentAndUsers)
            return
        }
    }

    // post comment to firebase. called from input accessory view delegate
    func postComment(text: String) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        guard let currentUser = self.currentUser else { return }
        guard let motive = self.motive else { return }
        let commentsChildReference = self.commentsReference.childByAutoId()
        let commentID = commentsChildReference.key
        let timestamp = Int64(NSDate().timeIntervalSince1970 * -1000)
        let newComment = [
            "id": commentID,
            "text": text,
            "user": uid,
            "time": timestamp
            
            ] as [String:Any]
        let comment = Comment(id: commentID, text: text, creatorID: uid, time: timestamp)
        let newCommentAndUser = CommentAndUser(comment: comment, user: currentUser.user)
        self.commentAndUsers.append(newCommentAndUser)
        self.tableView.reloadData()
        let indexPath = IndexPath(row: self.commentAndUsers.count, section: 0)
        if self.commentAndUsers.count > 0 {
            self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: false)
            let insets = UIEdgeInsetsMake(0, 0, self.keyboardHeight, 0)
            self.tableView.contentInset = insets
            self.tableView.scrollIndicatorInsets = insets
        }
        // add comment object to database
        commentsChildReference.setValue(newComment) { error, ref in
            if error != nil {
                AlertController.showAlert(self, title: "Error", message: "There was an error posting your comment.")
                self.commentAndUsers.removeLast()
                self.tableView.reloadData()
                return
            }
            // add to motive comments reference list - security rules check for exists
            self.motiveCommentsReference.child(motive.id).child(commentID).setValue(timestamp) { error, ref in
                if error != nil {
                    AlertController.showAlert(self, title: "Error", message: "There was an error posting your comment.")
                    commentsChildReference.removeValue()
                    self.commentAndUsers.removeLast()
                    self.tableView.reloadData()
                    return
                }
                
                // add to nC of the motive
                self.functions.httpsCallable("countComments").call(["id": motive.id, "creator": motive.creator, "name": currentUser.user.username, "commentText": comment.text]) { (result, error) in
                    if let error = error as NSError? {
                        if error.domain == FunctionsErrorDomain {
                            let message = error.localizedDescription
                            print (message)
                        }
                    }
                    if let numComments = (result?.data as? [String: Any])?["num"] as? Int {
                        print (numComments)
                        self.motivesReference.child(motive.id).child("nC").observeSingleEvent(of: .value, with: { (snapshot) in
                            if snapshot.exists() {
                                // set in motives reference if it exists
                                self.motivesReference.child(motive.id).child("nC").setValue(numComments)
                            } else {
                                self.archiveReference.child(motive.id).child("nC").observeSingleEvent(of: .value, with: { (snapshot) in
                                    if snapshot.exists() {
                                        // else set in the archive reference
                                        self.archiveReference.child(motive.id).child("nC").setValue(numComments)
                                    }
                                })
                            }
                        })
                        var updatedMotive = motive
                        updatedMotive.numComments = numComments
                        self.motiveHashTableDelegate?.storeMotive(motive: updatedMotive)
                    }
                }
            }
            
        }
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            keyboardHeight = keyboardSize.height
            
            print ("open " + keyboardSize.height.description)
        }
        if let duration = notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as? Double {
            keyboardDuration = duration
        }
        if let curve = notification.userInfo?[UIKeyboardAnimationCurveUserInfoKey] as? UInt {
            keyboardAnimationCurve = curve
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        textViewEndedEditing()
    }
    
    func textViewStartedEditing() {
        let insets = UIEdgeInsetsMake(0, 0, keyboardHeight, 0)

        //if tableView.contentSize.height >
        UIView.animate(withDuration: keyboardDuration, delay: 0, options: UIViewAnimationOptions(rawValue: keyboardAnimationCurve<<16), animations: {
            self.tableView.contentOffset.y = min(self.tableView.contentOffset.y + self.keyboardHeight - self.bottomView.frame.height, self.tableView.contentSize.height)
            self.tableView.contentInset = insets
            self.tableView.scrollIndicatorInsets = insets
        })

    }
    
    
    func textViewEndedEditing() {
        let insets = UIEdgeInsetsMake(0, 0, (bottomView.frame.height), 0)
        tableView.contentInset = insets
        tableView.scrollIndicatorInsets = insets
    }
    
    @objc func appMovedToBackground() {
        bottomView.textView.resignFirstResponder()
    }

}

// MARK: - table view data source and delegate
extension CommentViewController: UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate, CalloutViewDelegate {
 
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y <= 200 {
            if !outOfComments && !loadingMoreComments {
                loadMoreComments()
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return commentAndUsers.count + 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: refreshIdentifier)
            cell?.separatorInset = UIEdgeInsetsMake(0, tableView.frame.width / 2, 0, tableView.frame.width / 2)
            // if there are NO motives in going or posts
            if commentAndUsers.count == 0 || outOfComments {
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
            let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier) as! CommentTableViewCell
            // since awake from xib isnt called
            cell.frame.size.width = tableView.frame.width
            cell.cellViewDelegate = self
            cell.setupSubviews()
            cell.separatorInset = UIEdgeInsetsMake(0, tableView.frame.width / 2, 0, tableView.frame.width / 2)
            cell.selectionStyle = .none
            cell.layoutMargins = UIEdgeInsets.zero
            // -1 for refresh cell
            let cellRow = indexPath.row - 1
            let nextRow = indexPath.row
            // make insets if the next comment is from a different user
            if commentAndUsers.count > nextRow {
                if commentAndUsers[nextRow].user.uid != commentAndUsers[cellRow].user.uid {
                    cell.separatorInset = UIEdgeInsetsMake(0, 0, 0, 0)
                }
            }
            // setup cell user data
            cell.commentAndUser = commentAndUsers[cellRow]
            let commentAndUser = commentAndUsers[cellRow]
            cell.cellViewDelegate = self
            let user = commentAndUser.user
            if let url = URL(string: user.photoURL) {
                cell.profileImageView.sd_setImage(with: url) { (image, error, cache, urls) in
                    if error == nil {
                        cell.profileImageView.image = image
                    } else {
                        cell.profileImageView.image = nil
                    }
                }
            }
            let comment = commentAndUser.comment
            cell.timeLabel.text = timestampToText(timestamp: comment.time)
            cell.timeLabel.sizeToFit()
            let textWidth = cell.timeLabel.frame.width + 5
            cell.timeLabel.frame = CGRect(x: cell.frame.width - textWidth - 10, y: 12, width: textWidth, height: 20)
            cell.commentTextLabel.text = comment.text
            // set user username label
            cell.titleLabel.text = user.display
            cell.titleLabel.frame = CGRect(x: 60, y: 12, width: cell.frame.width - 68 - textWidth, height: 20)
            return cell
        }
    }
    
    // setting the height for all table rows
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        // nothing to see here chief
        if self.commentAndUsers.count == 0 && outOfComments {
            return 100
        }
        // out of comments
        if indexPath.row == 0 && outOfComments {
            return 0
        }
        // refresh cell
        if indexPath.row == 0 {
            return 50
        }
        return UITableViewAutomaticDimension
    }
    
    // setting the estimated height for all table rows
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        // nothing to see here chief
        if self.commentAndUsers.count == 0 && outOfComments {
            return 100
        }
        // out of comments
        if indexPath.row == 0 && outOfComments {
            return 0
        }
        // refresh cell
        if indexPath.row == 0 {
            return 50
        }
        return UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            tableView.deselectRow(at: indexPath, animated: false)
            return
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if indexPath.row == 0 {
            return false
        }
        let commentAndUser = commentAndUsers[indexPath.row - 1]
        if Auth.auth().currentUser?.uid == commentAndUser.comment.creatorID {
            return true
        } else {
            return false
        }
    }
    
    // slide to delete your post function
    func tableView(_ tableView: UITableView, editActionsForRowAt: IndexPath) -> [UITableViewRowAction]? {
        if editActionsForRowAt.row == 0 {
            return nil
        }
        guard let currentUserUid = Auth.auth().currentUser?.uid  else { return nil }
        guard let motive = self.motive else { return nil }
        // correct index path due to refresh cell
        let correctedIndexPath = IndexPath(row: editActionsForRowAt.row - 1, section: editActionsForRowAt.section)
        let commentAndUser = commentAndUsers[correctedIndexPath.row]
        if currentUserUid == commentAndUser.comment.creatorID {
            let delete = UITableViewRowAction(style: .destructive, title: "Delete Comment") { action, index in
                let commentId = commentAndUser.comment.id
                self.motiveCommentsReference.child(motive.id).child(commentId).removeValue() { error, ref in
                    if error == nil {
                        self.commentsReference.child(commentId).removeValue()
                        print ("deleted comment " + commentId)
                    }
                }
                self.tableView.beginUpdates()
                self.commentAndUsers.remove(at: correctedIndexPath.row)
                self.tableView.deleteRows(at: [editActionsForRowAt], with: .fade)
                self.tableView.endUpdates()
                // update the nC of the motive
                self.functions.httpsCallable("countComments").call(["id": motive.id]) { (result, error) in
                    if let error = error as NSError? {
                        if error.domain == FunctionsErrorDomain {
                            let message = error.localizedDescription
                            print (message)
                        }
                    }
                    if let numComments = (result?.data as? [String: Any])?["num"] as? Int {
                        print (numComments)
                        self.motivesReference.child(motive.id).child("nC").observeSingleEvent(of: .value, with: { (snapshot) in
                            if snapshot.exists() {
                                // set in motives reference if it exists
                                self.motivesReference.child(motive.id).child("nC").setValue(numComments)
                            } else {
                                self.archiveReference.child(motive.id).child("nC").observeSingleEvent(of: .value, with: { (snapshot) in
                                    if snapshot.exists() {
                                        // else set in the archive reference
                                        self.archiveReference.child(motive.id).child("nC").setValue(numComments)
                                    }
                                })
                            }
                        })
                        var updatedMotive = motive
                        updatedMotive.numComments = numComments
                        self.motiveHashTableDelegate?.storeMotive(motive: updatedMotive)
                    }
                }
            }
            return [delete]
        } else {
            return nil
        }
    }
    
    
    // push users profile that was clicked on from comment
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
    func calloutPressed() {
        return
    }
    func commentsPressed(motive: Motive) {
        return
    }
    func goingPressed(motive: Motive) {
        return
    }
    func unGoPressed(motive: Motive) {
        return
    }
    
}

// MARK: - view poppers
extension CommentViewController: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer is UIPanGestureRecognizer {
            if let panGestureRecognizer = gestureRecognizer as? UIPanGestureRecognizer {
                let translation = panGestureRecognizer.translation(in: view)
                // Allow multiple gestures at once if there is potentially a uirowaction
                if (translation.x < 0) {
                    return true
                }
            }
        }
        return false
    }
    
    // dynamic pop view controller
    @objc func panGestureRecognizerAction(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        if (translation.x >= 0) {
            transitionView.frame.origin.x = translation.x
            if !isPanning {
                isPanning = true
            }
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
                })
                // over half the screen, pop
            } else if (translation.x >= view.frame.width / 2) {
                UIView.animate(withDuration: 0.3, delay: 0.0, animations: {
                    // animate origin moring off screen
                    self.transitionView.frame.origin = CGPoint(x: self.view.frame.width, y: 0.0)
                }, completion: {(finished:Bool) in
                    // animation finishes
                    self.navigationController?.popViewController(animated: false)
                })
                // go back to origin
            } else {
                UIView.animate(withDuration: 0.3, delay: 0.0, animations: {
                    self.transitionView.frame.origin = CGPoint(x: 0.0, y: 0.0)
                }, completion: {(finished:Bool) in
                    self.foregroundView.isHidden = true
                    self.inputAccessoryView?.isHidden = false
                    self.isPanning = false
                })
            }
        }
    }
    
    @IBAction func goBackButtonPressed(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc func pinchGestureRecognizerAction(_ sender: UIPinchGestureRecognizer) {
        if sender.state == .began {
            if sender.scale <= 1 {
                if !isZooming {
                    isZooming = true
                    
                }
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
                // dont go bigger
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
                        print (blurView)
                        print (self.pinchView.subviews)
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
                    self.foregroundView.isHidden = true
                    self.inputAccessoryView?.isHidden = false
                })
            }
        }
    }
    
}
