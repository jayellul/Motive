//
//  UpdateViewController.swift
//  wyd
//
//  Created by Jason Ellul on 2018-09-16.
//  Copyright © 2018 Jason Ellul. All rights reserved.
//

import UIKit
import Firebase
import SDWebImage

protocol SettingsUpdateDelegate {
    func refreshCurrentUserDetails()
}

class UpdateViewController: UIViewController {

    var pinchDelegate: PinchDelegate?
    // what type of VC this is updating - username or email
    enum viewType {
        case username
        case email
    }
    
    // defualt to username ...
    var type = UpdateViewController.viewType.username
    
    static let kUsersListPath = "users"
    let usersReference = Database.database().reference(withPath: kUsersListPath)
    static let kUsernameListPath = "username"
    let usernameReference = Database.database().reference(withPath: kUsernameListPath)
    
    var user: User!
    
    var settingsUpdateDelegate: SettingsUpdateDelegate?
    var currentUserDelegate: CurrentUserDelegate?
    var userHashTableDelegate: UserHashTableDelegate?

    
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var headerViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var headerViewLabel: UILabel!
    @IBOutlet weak var saveButton: LoadingButton!
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
    let currentLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = UIColor.black
        label.font = UIFont.boldSystemFont(ofSize: 16.0)
        label.text = "Current"
        label.textAlignment = .left
        return label
    }()
    let userLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = UIColor.black
        label.font = UIFont.systemFont(ofSize: 16.0)
        label.text = ""
        label.textAlignment = .left
        return label
    }()
    let newLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = UIColor.black
        label.font = UIFont.boldSystemFont(ofSize: 16.0)
        label.text = "New"
        label.textAlignment = .left
        return label
    }()
    let textField: UITextField = {
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.textColor = UIColor.black
        textField.font = UIFont.systemFont(ofSize: 16.0)
        textField.text = ""
        textField.textAlignment = .left
        textField.backgroundColor = UIColor.clear
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        // add bottom line
        textField.borderStyle = .none
        textField.layer.backgroundColor = UIColor.white.cgColor
        textField.layer.masksToBounds = false
        textField.layer.shadowColor = UIColor.lightGray.cgColor
        textField.layer.shadowOffset = CGSize(width: 0.0, height: 1.0)
        textField.layer.shadowOpacity = 1.0
        textField.layer.shadowRadius = 0.0
        return textField
    }()
    
    
    
    @IBOutlet weak var transitionView: UIView!
    @IBOutlet weak var scroll: UIScrollView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        hideKeyboardWhenTappedAround()
        setupSubviews()
        setupUserDetails()
        currentUserDelegate = tabBarController as? CustomTabBarController
        userHashTableDelegate = tabBarController as? CustomTabBarController

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
        
        self.scroll.addSubview(currentLabel)
        currentLabel.topAnchor.constraint(equalTo: self.scroll.topAnchor, constant: 10).isActive = true
        currentLabel.leftAnchor.constraint(equalTo: self.scroll.leftAnchor, constant: 25).isActive = true
        currentLabel.widthAnchor.constraint(equalToConstant: 150).isActive = true
        currentLabel.heightAnchor.constraint(equalToConstant: 25).isActive = true
        
        self.scroll.addSubview(userLabel)
        userLabel.topAnchor.constraint(equalTo: self.scroll.topAnchor, constant: 40).isActive = true
        userLabel.leftAnchor.constraint(equalTo: self.scroll.leftAnchor, constant: 25).isActive = true
        userLabel.widthAnchor.constraint(equalToConstant: self.view.frame.width - 50).isActive = true
        userLabel.heightAnchor.constraint(equalToConstant: 35).isActive = true
        
        self.scroll.addSubview(newLabel)
        newLabel.topAnchor.constraint(equalTo: self.scroll.topAnchor, constant: 90).isActive = true
        newLabel.leftAnchor.constraint(equalTo: self.scroll.leftAnchor, constant: 25).isActive = true
        newLabel.widthAnchor.constraint(equalToConstant: 150).isActive = true
        newLabel.heightAnchor.constraint(equalToConstant: 25).isActive = true
        
        self.scroll.addSubview(textField)
        textField.topAnchor.constraint(equalTo: self.scroll.topAnchor, constant: 120).isActive = true
        textField.leftAnchor.constraint(equalTo: self.scroll.leftAnchor, constant: 25).isActive = true
        textField.widthAnchor.constraint(equalToConstant: self.view.frame.width - 50).isActive = true
        textField.heightAnchor.constraint(equalToConstant: 35).isActive = true
        textField.delegate = self
        
        saveButton.isEnabled = false
        saveButton.alpha = 0.5


    }
    
    func setupUserDetails() {
        guard let currentUser = (tabBarController as? CustomTabBarController)?.currentUser else { displayAlert(); return }
        self.user = currentUser.user
        guard let firebaseUser = Auth.auth().currentUser else { displayAlert(); return }
        if type == .username {
            headerViewLabel.text = "Update Username"
            textField.placeholder = "Username"
            userLabel.text = currentUser.user.username
            
        } else if type == .email {
            headerViewLabel.text = "Update Email"
            textField.placeholder = "Email"
            textField.keyboardType = .emailAddress
            userLabel.text = firebaseUser.email
        }
    }
    
    func displayAlert() {
        AlertController.showAlert(self, title: "Error", message: "You are not logged in.")
        navigationController?.popViewController(animated: true)
    }
    
    // user presses the save button - update username in Firebase, username directory + user directory
    @IBAction func saveButtonPressed(_ sender: Any) {
        if let updateString = textField.text {
            // make sure they are logged in and there is a current user in tabbar
            guard let currentUser = (tabBarController as? CustomTabBarController)?.currentUser else { displayAlert(); return }
            guard let firebaseUser = Auth.auth().currentUser else { displayAlert(); return }
            saveButton.showLoading()
            // if this is updating the username view
            if type == .username {
                if isValidUsername(updateString) {
                    // check if the username is taken
                    usernameReference.child(updateString.lowercased()).observeSingleEvent(of: .value, with: { snapshot in
                        if snapshot.exists() {
                            AlertController.showAlert(self, title: "Error", message: "That username is already taken.")
                            self.textField.becomeFirstResponder()
                            self.saveButton.hideLoading()
                            return
                        } else {
                            // update the user's username
                            self.usersReference.child(currentUser.user.uid).child("un").observeSingleEvent(of: .value) { (usersSnapshot) in
                                if usersSnapshot.exists() {
                                    self.usernameReference.child(currentUser.user.username.lowercased()).observeSingleEvent(of: .value, with: { (usernameSnapshot) in
                                        if usernameSnapshot.exists() {
                                            // both snapshots exist, so we can cleanly update the database
                                            self.usernameReference.child(updateString.lowercased()).setValue(currentUser.user.uid) { error, ref in
                                                if error == nil {
                                                    // if no errors when updating the first entry...
                                                    self.usernameReference.child(currentUser.user.username.lowercased()).removeValue()
                                                    self.usersReference.child(currentUser.user.uid).child("un").setValue(updateString)
                                                    let oldUser = currentUser.user
                                                    let updatedUser = User(uid: oldUser.uid, username: updateString, display: oldUser.display, photoURL: oldUser.photoURL, numFollowers: oldUser.numFollowers, numFollowing: oldUser.numFollowing, pointLatitude: oldUser.pointLatitude, pointLongitude: oldUser.pointLongitude, zoomLevel: oldUser.zoomLevel)
                                                    let updatedCurrentUser = CurrentUser(user: updatedUser, followingSet: currentUser.followingSet, requests: currentUser.requests, blockedSet: currentUser.blockedSet)
                                                    self.currentUserDelegate?.storeCurrentUser(currentUser: updatedCurrentUser)
                                                    self.userHashTableDelegate?.storeUser(user: updatedUser)
                                                    self.settingsUpdateDelegate?.refreshCurrentUserDetails()
                                                    self.saveButton.hideLoading()
                                                    self.navigationController?.popViewController(animated: true)
                                                } else {
                                                    AlertController.showAlert(self, title: "Error", message: "There was an error updating your account.")
                                                    self.saveButton.hideLoading()
                                                    return
                                                }
                                            }
                                        } else {
                                            AlertController.showAlert(self, title: "Error", message: "There was an error updating your account.")
                                            self.saveButton.hideLoading()
                                            return
                                        }
                                    })
                                } else {
                                    AlertController.showAlert(self, title: "Error", message: "There was an error updating your account.")
                                    self.saveButton.hideLoading()
                                    return
                                }
                            }
                        }
                    })
                }
            } else if type == .email {
                
                // Create the alert controller.
                let alert = UIAlertController(title: "Reauthenticate", message: "Please re-enter your password:", preferredStyle: .alert)
                
                // Add the text field
                alert.addTextField { (textField) in
                    textField.placeholder = "Password"
                    textField.autocorrectionType = .no
                    textField.autocapitalizationType = .none
                    textField.isSecureTextEntry = true
                }
                
                // add a cancel button - contain action to stop spinning for savebutton
                alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: { [weak alert] (_) in
                    self.saveButton.hideLoading()
                }))
                
                // Grab the value from the text field, and print it when the user clicks OK.
                alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { [weak alert] (_) in
                    let textField = alert?.textFields![0]
                    if let password = textField?.text {
                        let credential = EmailAuthProvider.credential(withEmail: firebaseUser.email!, password: password)
                        firebaseUser.reauthenticate(with: credential) { (error) in
                            if error != nil {
                                AlertController.showAlert(self, title: "Error", message: (error?.localizedDescription)!)
                                self.saveButton.hideLoading()
                                return
                            }
                            firebaseUser.updateEmail(to: updateString, completion: { (error) in
                                if error != nil {
                                    AlertController.showAlert(self, title: "Error", message: (error?.localizedDescription)!)
                                    self.saveButton.hideLoading()
                                    return
                                }
                                self.settingsUpdateDelegate?.refreshCurrentUserDetails()
                                self.saveButton.hideLoading()
                                self.navigationController?.popViewController(animated: true)
                                
                            })
                        }
                    }
                }))
                // Present the password alert.
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
}

// MARK :- text Field functionality
extension UpdateViewController: UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        var maxLength = 18
        let currentText = textField.text ?? ""
        let prospectiveText = (currentText as NSString).replacingCharacters(in: range, with: string)
        if type == .username {
            if isValidUsername(prospectiveText) {
                saveButton.isEnabled = true
                saveButton.alpha = 1.0
            } else {
                saveButton.isEnabled = false
                saveButton.alpha = 0.5
            }
        } else if type == .email {
            maxLength = 40
            if isValidEmail(prospectiveText) {
                saveButton.isEnabled = true
                saveButton.alpha = 1.0
            } else {
                saveButton.isEnabled = false
                saveButton.alpha = 0.5
            }
        }
        
        return prospectiveText.count < maxLength
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false
    }
    
    
    // username validity regex - only a-z, A-Z, 0-9, -_
    func isValidUsername(_ username : String) -> Bool {
        if username.count > 2 && username.count <= 18 {
            // letters, numbers, -_
            let regex =  "^[a-zA-Z0-9_-]{3,18}$"
            let usernameTest = NSPredicate(format: "SELF MATCHES %@", regex)
            return usernameTest.evaluate(with: username)
        } else {
            return false
        }
    }
    // email validity regex 
    func isValidEmail(_ string : String) -> Bool {
        let regex = "(?:[\\p{L}0-9!#$%\\&'*+/=?\\^_`{|}~-]+(?:\\.[\\p{L}0-9!#$%\\&'*+/=?\\^_`{|}" +
            "~-]+)*|\"(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21\\x23-\\x5b\\x5d-\\" +
            "x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])*\")@(?:(?:[\\p{L}0-9](?:[a-" +
            "z0-9-]*[\\p{L}0-9])?\\.)+[\\p{L}0-9](?:[\\p{L}0-9-]*[\\p{L}0-9])?|\\[(?:(?:25[0-5" +
            "]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-" +
            "9][0-9]?|[\\p{L}0-9-]*[\\p{L}0-9]:(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21" +
        "-\\x5a\\x53-\\x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])+)\\])"
        let emailTest = NSPredicate(format: "SELF MATCHES %@", regex)
        return emailTest.evaluate(with: string)

    }
}

// MARK :- view poppers
extension UpdateViewController {
    
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

