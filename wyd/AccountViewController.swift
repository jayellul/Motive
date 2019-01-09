//
//  AccountViewController.swift
//  wyd
//
//  Created by Jason Ellul on 2018-09-14.
//  Copyright © 2018 Jason Ellul. All rights reserved.
//

import UIKit
import Firebase
import SDWebImage


class AccountViewController: UIViewController, SettingsUpdateDelegate {

    
    var pinchDelegate: PinchDelegate?
    var user: User!
    
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var headerViewHeightConstraint: NSLayoutConstraint!
    // ui kit components
    var backgroundView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = true
        view.isUserInteractionEnabled = false
        view.backgroundColor = UIColor.black
        return view
    }()
    var isZooming = false
    // background view for pinch
    var pinchView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = true
        view.isUserInteractionEnabled = false
        view.backgroundColor = UIColor.black
        return view
    }()
    let loginLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = UIColor.black
        label.font = UIFont.boldSystemFont(ofSize: 18.0)
        label.text = "Login"
        label.textAlignment = .left
        return label
    }()
    // tableView for login options
    let tableView: UITableView = {
        let table = UITableView()
        table.translatesAutoresizingMaskIntoConstraints = false
        //table.tableFooterView = UIView (frame: CGRect.zero)
        table.isScrollEnabled = false
        return table
    }()
    let privacyLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = UIColor.black
        label.font = UIFont.boldSystemFont(ofSize: 18.0)
        label.text = "Privacy"
        label.textAlignment = .left
        return label
    }()
    let privateAccountLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = UIColor.black
        label.font = UIFont.systemFont(ofSize: 18.0)
        label.text = "Private Account"
        label.textAlignment = .left
        return label
    }()
    let privateSwitch: UISwitch = {
        let s = UISwitch()
        s.translatesAutoresizingMaskIntoConstraints = true
        return s
    }()
    let warningLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = UIColor(red: 153/255, green: 153/255, blue: 153/255, alpha: 1.0)
        label.font = UIFont.systemFont(ofSize: 12.0)
        label.text = "When your account is private, only people you approve can see the Motives you post. Your existing followers won't be affected."
        label.numberOfLines = 0
        label.textAlignment = .left
        return label
    }()
    
    let signOutButton: LoadingButton = {
        let button = LoadingButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Sign Out", for: UIControlState.normal)
        button.setTitleColor(UIColor.red, for: UIControlState.normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18.0)
        button.titleLabel?.textAlignment = .center
        button.layer.borderColor = UIColor(red:0.85, green:0.85, blue:0.85, alpha:1.0).cgColor
        button.layer.borderWidth = 0.5
        button.layer.cornerRadius = 5
        return button
    }()
    
    @IBOutlet weak var transitionView: UIView!
    @IBOutlet weak var scroll: UIScrollView!
    
    var itemsToLoad: [String] = ["Username", "Email"]

    override func viewDidLoad() {
        super.viewDidLoad()
        setupSubviews()
        tableView.reloadData()
        
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panGestureRecognizerAction(_:)))
        let pinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(pinchGestureRecognizerAction(_:)))
        // delay for 0.5 seconds before enabling panGesture
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // add swipe right gesture
            self.transitionView.addGestureRecognizer(panGestureRecognizer)
            self.transitionView.addGestureRecognizer(pinchGestureRecognizer)

        }
        

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
        
        self.scroll.frame.size.width = self.view.frame.size.width
        self.scroll.contentSize.height = 500
        
        self.scroll.addSubview(loginLabel)
        loginLabel.topAnchor.constraint(equalTo: self.scroll.topAnchor, constant: 0).isActive = true
        loginLabel.leftAnchor.constraint(equalTo: self.scroll.leftAnchor, constant: 25).isActive = true
        loginLabel.widthAnchor.constraint(equalToConstant: 150).isActive = true
        loginLabel.heightAnchor.constraint(equalToConstant: 70).isActive = true
        
        self.scroll.addSubview(tableView)
        tableView.topAnchor.constraint(equalTo: scroll.topAnchor, constant: 70).isActive = true
        tableView.leftAnchor.constraint(equalTo: scroll.leftAnchor).isActive = true
        tableView.widthAnchor.constraint(equalToConstant: scroll.frame.width).isActive = true
        tableView.heightAnchor.constraint(equalToConstant: 140).isActive = true
        
        self.scroll.addSubview(privacyLabel)
        privacyLabel.topAnchor.constraint(equalTo: self.scroll.topAnchor, constant: 210).isActive = true
        privacyLabel.leftAnchor.constraint(equalTo: self.scroll.leftAnchor, constant: 25).isActive = true
        privacyLabel.widthAnchor.constraint(equalToConstant: 150).isActive = true
        privacyLabel.heightAnchor.constraint(equalToConstant: 70).isActive = true
        
        self.scroll.addSubview(privateAccountLabel)
        privateAccountLabel.topAnchor.constraint(equalTo: self.scroll.topAnchor, constant: 280).isActive = true
        privateAccountLabel.leftAnchor.constraint(equalTo: self.scroll.leftAnchor, constant: 25).isActive = true
        privateAccountLabel.widthAnchor.constraint(equalToConstant: 150).isActive = true
        privateAccountLabel.heightAnchor.constraint(equalToConstant: 70).isActive = true
        
        privateSwitch.frame = CGRect(x: scroll.frame.width - 20 - privateSwitch.frame.width, y: 280 + privateSwitch.frame.width / 3, width: privateSwitch.frame.width, height: privateSwitch.frame.width)
        self.scroll.addSubview(privateSwitch)
        privateSwitch.addTarget(self, action: #selector(switchChanged), for: UIControlEvents.valueChanged)
        if let isPrivate = (tabBarController as? CustomTabBarController)?.currentUser?.isPrivate {
            if isPrivate {
                privateSwitch.isOn = true
            }
        }
        

        self.scroll.addSubview(warningLabel)
        warningLabel.topAnchor.constraint(equalTo: self.scroll.topAnchor, constant: 335).isActive = true
        warningLabel.leftAnchor.constraint(equalTo: self.scroll.leftAnchor, constant: 25).isActive = true
        warningLabel.widthAnchor.constraint(equalToConstant: self.scroll.frame.width - 50).isActive = true
        let textHeight = warningLabel.text?.height(withConstrainedWidth: self.scroll.frame.width - 50, font: UIFont.systemFont(ofSize: 12))
        warningLabel.heightAnchor.constraint(equalToConstant: textHeight ?? 70).isActive = true
        
        self.scroll.addSubview(signOutButton)
        signOutButton.topAnchor.constraint(equalTo: self.scroll.topAnchor, constant: 460).isActive = true
        signOutButton.centerXAnchor.constraint(equalTo: self.scroll.centerXAnchor).isActive = true
        signOutButton.widthAnchor.constraint(equalToConstant: 160).isActive = true
        signOutButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
        signOutButton.addTarget(nil, action: #selector(signOutPressed(_:)), for: .touchUpInside)
        
        
        // setup table
        tableView.register(SliderTableViewCell.self, forCellReuseIdentifier: "accountTableViewCell")
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = UITableViewCellSeparatorStyle.singleLine
        tableView.allowsMultipleSelection = false
        

        

    }
    
    // adjust users privacy setting
    @objc func switchChanged(mySwitch: UISwitch) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        guard let currentUser = (tabBarController as? CustomTabBarController)?.currentUser else { return }
        let kPrivateListPath = "private"
        let privateReference = Database.database().reference(withPath: kPrivateListPath)
        if mySwitch.isOn {
            privateReference.child(uid).setValue(true)
            currentUser.isPrivate = true
            (tabBarController as? CustomTabBarController)?.currentUser = currentUser
        } else {
            privateReference.child(uid).removeValue()
            currentUser.isPrivate = false
            (tabBarController as? CustomTabBarController)?.currentUser = currentUser
        }
     }
    
    
    // user wants to sign out
    @objc func signOutPressed(_ sender: LoadingButton!) {
        // create alert
        let alert = UIAlertController(title: "Sign Out", message: "Are you sure you want to proceed with signing out?", preferredStyle: .alert)
        let cancelButton = UIAlertAction(title: "Cancel", style: .cancel, handler: {(_ action: UIAlertAction) -> Void in
            // do nothing, close alert
        })
        let yesButton = UIAlertAction(title: "Sign out", style: .default, handler: {(_ action: UIAlertAction) -> Void in
            // sign out the user from firebase
            self.signOutButton.showLoading()
            let firebaseAuth = Auth.auth()
            do {
                try firebaseAuth.signOut()
                // remove userID from keychain
                //KeychainWrapper.standard.removeObject(forKey: "uid")
                print ("user has been signed out.")
                // remove hashtable objects so they dont stay for next user
                if let customTabBarController = self.tabBarController as? CustomTabBarController {
                    customTabBarController.currentUser = nil
                    customTabBarController.userHashTable.removeAll()
                    customTabBarController.motiveHashTable.removeAll()
                }
                // segue back to login screen
                self.signOutButton.hideLoading()
                self.performSegue(withIdentifier: "userSignOut", sender: nil)
                
            } catch let signOutError as NSError {
                // error signing out
                print ("Error signing out: %@", signOutError)
                AlertController.showAlert(self, title: "Error", message: "Sign out request could not be completed.")
                self.signOutButton.hideLoading()
                return
            }
            self.signOutButton.hideLoading()
        })
        alert.addAction(cancelButton)
        alert.addAction(yesButton)
        present(alert, animated: true)
        
    }
    // refresh the current details when an update VC is popped
    func refreshCurrentUserDetails() {
        tableView.reloadData()
    }
    

    

}

// MARK :- Login table view
extension AccountViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return itemsToLoad.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "accountTableViewCell", for: indexPath as IndexPath) as! SliderTableViewCell
        cell.awakeFromNib()
        cell.selectionStyle = UITableViewCellSelectionStyle.none
        cell.preservesSuperviewLayoutMargins = false
        cell.separatorInset = UIEdgeInsets.zero
        cell.layoutMargins = UIEdgeInsets.zero
        // change the title label constant and setup a login Cell
        cell.imageView?.image = nil
        cell.titleLabelLeftConstraint.constant = 25
        cell.titleLabel.text = self.itemsToLoad[indexPath.row]
        cell.accessoryType = .disclosureIndicator
        cell.setupDetailLabel()
        if indexPath.row == 0 {
            if let username = (self.tabBarController as? CustomTabBarController)?.currentUser?.user.username {
                cell.detailLabel.text = "@" + username
            }
        } else if indexPath.row == 1 {
            cell.detailLabel.text = Auth.auth().currentUser?.email
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        
        cell?.backgroundColor = UIColor.white
        if indexPath.row == 0 {
            print ("username")
            if let snapshotView = self.view.snapshotView(afterScreenUpdates: true) {
                for subview in pinchView.subviews {
                    if subview is UIVisualEffectView { subview.isHidden = true }
                }
                if let pinchSnapshotView = pinchView.snapshotView(afterScreenUpdates: true) {
                    let updateViewController = storyboard?.instantiateViewController(withIdentifier: "updateViewController") as! UpdateViewController
                    updateViewController.backgroundView = snapshotView
                    for subview in pinchView.subviews {
                        if subview is UIVisualEffectView { subview.isHidden = false }
                    }
                    updateViewController.pinchView = pinchSnapshotView
                    updateViewController.pinchDelegate = self.pinchDelegate
                    updateViewController.type = .username
                    updateViewController.settingsUpdateDelegate = self
                    self.navigationController?.pushViewController(updateViewController, animated: true)
                }
            }
        } else if indexPath.row == 1 {
            if let snapshotView = self.view.snapshotView(afterScreenUpdates: true) {
                for subview in pinchView.subviews {
                    if subview is UIVisualEffectView { subview.isHidden = true }
                }
                if let pinchSnapshotView = pinchView.snapshotView(afterScreenUpdates: true) {
                    let updateViewController = storyboard?.instantiateViewController(withIdentifier: "updateViewController") as! UpdateViewController
                    updateViewController.backgroundView = snapshotView
                    for subview in pinchView.subviews {
                        if subview is UIVisualEffectView { subview.isHidden = false }
                    }
                    updateViewController.pinchView = pinchSnapshotView
                    updateViewController.type = .email
                    updateViewController.settingsUpdateDelegate = self
                    self.navigationController?.pushViewController(updateViewController, animated: true)
                }
            }
        }
        tableView.deselectRow(at: indexPath, animated: false)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
    
}

// MARK :- view poppers
extension AccountViewController {
    
    // view poppers
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
                UIView.animate(withDuration: 0.3) {
                    self.transitionView.frame.origin = CGPoint(x: 0.0, y: 0.0)
                }
            }
        }
    }
    
    @IBAction func backButtonPressed(_ sender: Any) {
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
                    self.transitionView.frame.origin.x = 0
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

