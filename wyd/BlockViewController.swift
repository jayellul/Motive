//
//  FeedViewController.swift
//  wyd
//
//  Created by Jason Ellul on 2018-06-06.
//  Copyright © 2018 Jason Ellul. All rights reserved.
//

import UIKit
import Firebase

class BlockViewController: UIViewController {

    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var headerViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var transitionView: UIView!
    @IBOutlet weak var tableView: UITableView!
    
    var userHashTableDelegate: UserHashTableDelegate?
    var pinchDelegate: PinchDelegate?
    var isZooming: Bool = false
    var pinchView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = true
        view.isUserInteractionEnabled = false
        view.backgroundColor = UIColor.black
        return view
    }()
    var backgroundView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = true
        view.isUserInteractionEnabled = false
        view.backgroundColor = UIColor.black
        return view
    }()
    static let kUsersListPath = "users"
    let usersReference = Database.database().reference(withPath: kUsersListPath)
    
    var currentUser: CurrentUser?
    var users = [User]()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

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
        
        self.userHashTableDelegate = self.tabBarController as? UserHashTableDelegate

        tableView.tableFooterView = UIView (frame: CGRect.zero)
        tableView.layoutMargins = UIEdgeInsets.zero
        tableView.separatorInset = UIEdgeInsets.zero
        updateTable()
        
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panGestureRecognizerAction(_:)))
        let pinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(pinchGestureRecognizerAction(_:)))
        // delay for 0.5 seconds before enabling panGesture
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // add swipe right gesture
            self.transitionView.addGestureRecognizer(panGestureRecognizer)
            self.transitionView.addGestureRecognizer(pinchGestureRecognizer)

        }
    }
    
    // function to update table rows with users from current users' block ref
    func updateTable () {
        // dispatch group - fixing the asynchronus network of firebase requests
        let myGroup = DispatchGroup()
        var items: [User] = []
        guard let blockedUids = currentUser?.blockedSet else { return }
        print (blockedUids)
        for uid in blockedUids {
            // dispatch lock
            myGroup.enter()
            // check to see if its in hashtable
            if let user = self.userHashTableDelegate?.retrieveUser(uid: uid) {
                items.append(user)
                myGroup.leave()
                // if not in hashtable then load from firebase and store in hashtable
            } else {
                self.usersReference.child(uid).observeSingleEvent(of: .value, with: {
                    snapshot in
                    // add motive to feed if user exists
                    if (snapshot.exists()) {
                        let user = User(snapshot: snapshot)
                        self.userHashTableDelegate?.storeUser(user: user)
                        items.append(user)
                    }
                    myGroup.leave()
                })
            }
            
        }
        
        // wait until every member of mygroup is finished
        myGroup.notify(queue: .main) {
            self.users = items
            self.tableView.reloadData()
        }

    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
  
    @IBAction func addBlockPressed(_ sender: Any) {
        // Create the alert controller.
        let alert = UIAlertController(title: "Block User", message: "Enter your friend's @username: ", preferredStyle: .alert)
        
        // Add the text field
        alert.addTextField { (textField) in
            textField.placeholder = "Username"
        }
        
        // add a cancel button
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil))
        
        // Grab the value from the text field, and print it when the user clicks OK.
        alert.addAction(UIAlertAction(title: "Block", style: .default, handler: { [weak alert] (_) in
            let textField = alert?.textFields![0]
            let username = textField?.text?.lowercased()
            //alert?.dismiss(animated: true, completion: nil)
            self.usersReference.queryOrdered(byChild: "username").queryEqual(toValue: username).observeSingleEvent(of: .value, with: { snapshot in
                if snapshot.exists() {
                    // add snapshot user to current users block list
                    for item in snapshot.children {
                        let user = User(snapshot: item as! DataSnapshot)
                        if (user.uid == Auth.auth().currentUser?.uid) {
                            AlertController.showAlert(self, title: "Error", message: "You can't block yourself!")
                            return
                        }
                        let kBlockedListPath = "users/" + (Auth.auth().currentUser?.uid)! + "/blocked"
                        let blockedReference = Database.database().reference(withPath: kBlockedListPath)
                        let timestamp = Int64(NSDate().timeIntervalSince1970 * -1000)
                        blockedReference.child(user.uid).setValue(timestamp)
                    }
                    self.updateTable()
                    AlertController.showAlert(self, title: "User has been Blocked", message: "You have blocked @\(username ?? "username")")
                    
                } else {
                    // user doesn't exist in snapshot
                    AlertController.showAlert(self, title: "Error", message: "That @username is not associated with any users.")
                }
            })
        }))
        
        
        // Present the alert.
        self.present(alert, animated: true, completion: nil)

    }
    

}

// MARK :- table view functionality
extension BlockViewController: UITableViewDelegate , UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.users.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BlockTableViewCell") as! BlockTableViewCell
        let user = users[indexPath.row]
        cell.selectionStyle = .none
        cell.layoutMargins = UIEdgeInsets.zero
        //cell.textLabel?.text = user.username
        //cell.detailTextLabel?.text = user.email
        cell.titleLabel.text = user.display
        cell.usernameLabel.text = "@" + user.username
        // default while loading ** Fix
        cell.profileImageView.image = nil

        
        let url = URL(string: user.photoURL)
        URLSession.shared.dataTask(with: url!, completionHandler: {(data, response, error) in
            //download hit error
            if error != nil {
                print(error!.localizedDescription)
                return
            }
            
            DispatchQueue.main.async() {
                //cell.imageView?.image = UIImage(data: data!)
                cell.profileImageView.image = UIImage(data: data!)
            }
        }).resume()
        // add button functions as target and set tag as the indexPath row
        cell.unblockButton.addTarget(self, action: #selector(BlockViewController.unblockPressed(_:)), for: .touchUpInside)
        cell.unblockButton.tag = indexPath.row
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //self.performSegue(withIdentifier: "userProfileSegue", sender: nil)
        let userViewController = storyboard?.instantiateViewController(withIdentifier: "userViewController") as! UserViewController
        userViewController.uid = users[indexPath.row].uid
        //userViewController.user = users[indexPath.row]
        self.navigationController?.pushViewController(userViewController, animated: true)

    }
    
    @objc func unblockPressed(_ sender: LoadingButton!) {
        if let currentUser = (self.tabBarController as? CustomTabBarController)?.currentUser {
            let indexPath = IndexPath(row: sender.tag, section: 0)
            let cell = tableView.cellForRow(at: indexPath) as! BlockTableViewCell
            cell.unblockButton.showLoading()
            let user = users[indexPath.row]
            let kBlockedListPath = "users/" + (Auth.auth().currentUser?.uid)! + "/blocked"
            let blockedReference = Database.database().reference(withPath: kBlockedListPath)
            blockedReference.child(user.uid).removeValue()
            cell.unblockButton.hideLoading()
            currentUser.blockedSet.remove(user.uid)
            (self.tabBarController as? CustomTabBarController)?.currentUser = currentUser
            self.updateTable()
        }
    }


}


// MARK :- view poppers
extension BlockViewController {
    
    // go back to settings
    @IBAction func goBackPressed(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    // or swiping right
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
