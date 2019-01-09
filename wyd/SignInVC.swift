//
//  ViewController.swift
//  wyd
//
//  Created by Jason Ellul on 2018-04-12.
//  Copyright © 2018 Jason Ellul. All rights reserved.
//

import UIKit
import Firebase

class SignInVC: UIViewController {
    
    // firebase db refs
    static let kUsersListPath = "users"
    let usersReference = Database.database().reference(withPath: kUsersListPath)
    
    // ui kit objects
    @IBOutlet weak var scrollView: UIScrollView!
    
    
    let logoLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = UIColor.white
        label.font = UIFont(name: "DINAlternate-Bold", size: 100.0)
        label.text = "Motive"
        label.textAlignment = .center
        return label
    }()
    
    let emailField: UITextField = {
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.autocorrectionType = .no
        textField.textColor = UIColor.white
        textField.backgroundColor = UIColor.clear
        textField.layer.cornerRadius = 25
        textField.layer.borderColor = UIColor.white.cgColor
        textField.layer.borderWidth = 1.5
        textField.font = UIFont.systemFont(ofSize: 16.0)
        textField.textAlignment = .center
        textField.attributedPlaceholder = NSAttributedString(string: "Email", attributes: [NSAttributedStringKey.foregroundColor: UIColor.white])
        textField.text = ""
        textField.tag = 0
        textField.keyboardType = UIKeyboardType.emailAddress
        return textField
    }()
    
    let passwordField: UITextField = {
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.autocorrectionType = .no
        textField.textColor = UIColor.white
        textField.backgroundColor = UIColor.clear
        textField.layer.cornerRadius = 25
        textField.layer.borderColor = UIColor.white.cgColor
        textField.layer.borderWidth = 1.5
        textField.font = UIFont.systemFont(ofSize: 16.0)
        textField.textAlignment = .center
        textField.attributedPlaceholder = NSAttributedString(string: "Password", attributes: [NSAttributedStringKey.foregroundColor: UIColor.white])
        textField.text = ""
        textField.isSecureTextEntry = true
        textField.tag = 2
        return textField
    }()
    
    let signInButton: LoadingButton = {
        let button = LoadingButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitleColor(UIColor(red:1.00, green:0.60, blue:0.20, alpha:1.0), for: .normal)
        button.setTitle("Sign In", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16.0)
        button.backgroundColor = UIColor.white
        button.layer.cornerRadius = 5
        button.layer.borderColor = UIColor.white.cgColor
        button.layer.borderWidth = 1.5
        button.activityIndicator.activityIndicatorViewStyle = .gray
        return button
    }()
    
    let toSignUpButton: LoadingButton = {
        let button = LoadingButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitleColor(.white, for: .normal)
        button.setTitle("Create Account", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16.0)
        button.backgroundColor = UIColor.clear
        return button
    }()
    // loading indicator 
    let activityIndicator: UIActivityIndicatorView = {
        let activityIndicator = UIActivityIndicatorView()
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.hidesWhenStopped = true
        activityIndicator.color = UIColor.white
        return activityIndicator
    }()
    
    func setupSubviews() {
        addGradientToView(view)
        self.automaticallyAdjustsScrollViewInsets = false
        let UIScreenBounds = UIScreen.main.bounds
        self.scrollView.frame = UIScreenBounds
        self.scrollView.contentSize = CGSize(width: UIScreenBounds.width, height: UIScreenBounds.height)

        self.scrollView.addSubview(logoLabel)
        logoLabel.topAnchor.constraint(equalTo: self.scrollView.topAnchor, constant: 70).isActive = true
        logoLabel.centerXAnchor.constraint(equalTo: self.scrollView.centerXAnchor).isActive = true
        logoLabel.widthAnchor.constraint(equalToConstant: self.scrollView.frame.width - 32).isActive = true
        logoLabel.heightAnchor.constraint(equalToConstant: 200).isActive = true
        
        self.scrollView.addSubview(emailField)
        emailField.topAnchor.constraint(equalTo: self.scrollView.topAnchor, constant: 365).isActive = true
        emailField.centerXAnchor.constraint(equalTo: self.scrollView.centerXAnchor).isActive = true
        emailField.heightAnchor.constraint(equalToConstant: 50).isActive = true
        emailField.widthAnchor.constraint(equalToConstant: self.scrollView.frame.width - 32).isActive = true
        emailField.tag = 0
        emailField.delegate = self
        
        self.scrollView.addSubview(passwordField)
        passwordField.topAnchor.constraint(equalTo: self.scrollView.topAnchor, constant: 440).isActive = true
        passwordField.centerXAnchor.constraint(equalTo: self.scrollView.centerXAnchor).isActive = true
        passwordField.heightAnchor.constraint(equalToConstant: 50).isActive = true
        passwordField.widthAnchor.constraint(equalToConstant: self.scrollView.frame.width - 32).isActive = true
        passwordField.tag = 1
        passwordField.delegate = self
        
        self.scrollView.addSubview(signInButton)
        signInButton.topAnchor.constraint(equalTo: self.scrollView.topAnchor, constant: 540).isActive = true
        signInButton.centerXAnchor.constraint(equalTo: self.scrollView.centerXAnchor).isActive = true
        signInButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        signInButton.widthAnchor.constraint(equalToConstant: self.scrollView.frame.width - 32).isActive = true
        signInButton.addTarget(self, action: #selector(SignInVC.signInPressed(_:)), for: .touchUpInside)
        
        self.scrollView.addSubview(toSignUpButton)
        toSignUpButton.topAnchor.constraint(equalTo: self.scrollView.topAnchor, constant: 605).isActive = true
        toSignUpButton.centerXAnchor.constraint(equalTo: self.scrollView.centerXAnchor).isActive = true
        toSignUpButton.heightAnchor.constraint(equalToConstant: 25).isActive = true
        toSignUpButton.widthAnchor.constraint(equalToConstant: 125).isActive = true
        toSignUpButton.addTarget(self, action: #selector(SignInVC.toSignUpPressed(_:)), for: .touchUpInside)
        

        self.scrollView.addSubview(activityIndicator)
        activityIndicator.centerXAnchor.constraint(equalTo: self.scrollView.centerXAnchor).isActive = true
        activityIndicator.topAnchor.constraint(equalTo: self.scrollView.topAnchor, constant: 300).isActive = true
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        setupSubviews()

        self.hideKeyboardWhenTappedAround()

    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // add keyboard obersvers
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: Notification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: Notification.Name.UIKeyboardWillHide, object: nil)
    
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        // Don't have to do this on iOS 9+, but it still works
        NotificationCenter.default.removeObserver(self)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    @objc func toSignUpPressed(_ sender: LoadingButton!) {
        self.performSegue(withIdentifier: "signInToCreateAccountSegue", sender: nil)
    }

    @objc func signInPressed(_ sender: LoadingButton!) {

        self.signInButton.showLoading()
        guard let email = emailField.text,
        email != "",
        let password = passwordField.text,
        password != ""
        // if any fields are missing
        else {
            // display alert asking for fields
            self.signInButton.hideLoading()
            AlertController.showAlert(self, title: "Missing Required Fields", message: "Please fill out all of the fields.")
            return
        }
        // attempt a sign in
        Auth.auth().signIn(withEmail: email, password: password) { (user, error) in
            if error != nil {
                // problem with signing in
                AlertController.showAlert(self, title: "Error", message: error!.localizedDescription)
                self.signInButton.hideLoading()
                return
            } else {
                // login successful
                // add UID to keychain for this device and segue to main feed
                if let userID = user?.uid {
                    //KeychainWrapper.standard.set((userID), forKey: "uid")
                    print (userID)
                    self.performSegue(withIdentifier: "userLoggedIn", sender: nil)
                }
                self.signInButton.hideLoading()
                print ("user has signed in.");
            }
        }   
    }
    
    
}

extension SignInVC: UITextFieldDelegate {
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            let contentInsets = UIEdgeInsets(top: 0, left: 0, bottom: keyboardSize.size.height + 220, right: 0)
            scrollView.contentInset = contentInsets
            scrollView.scrollIndicatorInsets = contentInsets
            print ("open")
            print (scrollView.contentInset)
            
        }
        
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        scrollView.contentInset = .zero
        scrollView.scrollIndicatorInsets = .zero
        print ("hide")
    }
    
    // press enter to go to next field and submit form
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if (textField.tag == 0) {
            self.passwordField.becomeFirstResponder()
        } else if (textField.tag == 1) {
            
            self.signInPressed(self.signInButton)
        }
        return true
    }
    
    // max amount of characters in display text field
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard string.count > 0 else {
            return true
        }
        let maxLength = 35
        let currentText = textField.text ?? ""
        let prospectiveText = (currentText as NSString).replacingCharacters(in: range, with: string)
        return prospectiveText.count <= maxLength
    }
}

// tap to close keyboard - avaliable to all VC's with adding to viewToLoad method:
// self.hideKeyboardWhenTappedAround()
// https://stackoverflow.com/questions/24126678/close-ios-keyboard-by-touching-anywhere-using-swift?utm_medium=organic&utm_source=google_rich_qa&utm_campaign=google_rich_qa
extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}

extension UIViewController {

    // closure function to get users followers - param UID - returns array of uids that are following the user
    func getUserFollowers(uid: String, completionHandler:@escaping (_ followers: [String])-> Void) {
        // firebase db refs
        let kFollowersListPath = "followers"
        let followersReference = Database.database().reference(withPath: kFollowersListPath)
        var followers: [String] = []
        followersReference.child(uid).observeSingleEvent(of: .value) { (snapshot) in
            if snapshot.exists() {
                var snapshotArray: [DataSnapshot] = []
                for item in snapshot.children.allObjects as! [DataSnapshot] {
                    snapshotArray.append(item)
                }
                // sort by value - newest first
                snapshotArray.sort(by: { ((($0.value) as! Int) < ($1.value) as! Int)})
                for item in snapshotArray {
                    followers.append(item.key)
                }
                completionHandler(followers)
                return
            } else {
                followers.removeAll()
                completionHandler(followers)
                return
            }
        }
    }
    
    // closure function to get users following - param UID - returns array of uids that the user is following
    func getUserFollowing(uid: String, completionHandler:@escaping (_ following: [String])-> Void) {
        // firebase db refs
        let kFollowingListPath = "following"
        let followingReference = Database.database().reference(withPath: kFollowingListPath)
        var following: [String] = []
        followingReference.child(uid).observeSingleEvent(of: .value) { (snapshot) in
            if snapshot.exists() {
                var snapshotArray: [DataSnapshot] = []
                for item in snapshot.children.allObjects as! [DataSnapshot] {
                    snapshotArray.append(item)
                }
                // sort by value - newest first
                snapshotArray.sort(by: { ((($0.value) as! Int) < ($1.value) as! Int)})
                for item in snapshotArray {
                    following.append(item.key)
                }
                completionHandler(following)
                return
            } else {
                following.removeAll()
                completionHandler(following)
                return
            }
        }
    }
    // closure function to get users requests - param UID - returns set of uids that have requested to follow the user
    func getUserRequests(uid: String, completionHandler:@escaping (_ requests: [String])-> Void) {
        // firebase db refs
        let kRequestsListPath = "requests"
        let requestsReference = Database.database().reference(withPath: kRequestsListPath)
        var requests: [String] = []
        requestsReference.child(uid).observeSingleEvent(of: .value) { (snapshot) in
            if snapshot.exists() {
                for item in snapshot.children.allObjects as! [DataSnapshot] {
                    requests.append(item.key)
                }
                completionHandler(requests)
                return
            } else {
                requests.removeAll()
                completionHandler(requests)
                return
            }
        }
    }
    // closure function to get users blocked - param UID - returns set of uids that the user blocked
    func getUserBlocked(uid: String, completionHandler:@escaping (_ blocked: Set<String>)-> Void) {
        // firebase db refs
        let kBlockedListPath = "blocked"
        let blockedReference = Database.database().reference(withPath: kBlockedListPath)
        var blocked: Set<String> = []
        blockedReference.child(uid).observeSingleEvent(of: .value) { (snapshot) in
            if snapshot.exists() {
                for item in snapshot.children.allObjects as! [DataSnapshot] {
                    blocked.insert(item.key)
                }
                completionHandler(blocked)
                return
            } else {
                blocked.removeAll()
                completionHandler(blocked)
                return
            }
        }
    }
    
    

    // completion handler function to load uid param, following, followers, blocked, request from database - return nil if not found or not signed in
    func getCurrentUser(uid: String, completionHandler:@escaping (_ result: CurrentUser?)-> Void) {
        // firebase db refs
        let kUsersListPath = "users"
        let usersReference = Database.database().reference(withPath: kUsersListPath)
        usersReference.child(uid).observeSingleEvent(of: .value) { (snapshot) in
            if (snapshot.exists()) {
                let user = User(snapshot: snapshot)
                // get following
                self.getUserFollowing(uid: uid, completionHandler: { (following) in
                    // make followingSet
                    var followingSet: Set<String> = []
                    for uid in following {
                        followingSet.insert(uid)
                    }
                    // get blocked
                    self.getUserBlocked(uid: uid, completionHandler: { (blocked) in
                        // get requests sent to the user
                        self.getUserRequests(uid: uid, completionHandler: { (requests) in
                            // produce a current user object
                            let currentUser = CurrentUser(user: user, followingSet: followingSet, requests: requests, blockedSet: blocked)
                            let kPrivateListPath = "private"
                            let privateReference = Database.database().reference(withPath: kPrivateListPath)
                            privateReference.child(user.uid).observeSingleEvent(of: .value, with: { (snapshot) in
                                if snapshot.exists() {
                                    currentUser.isPrivate = true
                                }
                                completionHandler(currentUser)
                                return
                            })
                        })
                    })
                })
            
            } else {
                completionHandler(nil)
                return
            }
        }
    }
    
    // completion handler function to a user by uid param, return User object or nil if uid not in database
    func getUser(uid: String, completionHandler:@escaping (_ result: User?)-> Void) {
        guard let currentUserUid = Auth.auth().currentUser?.uid else { completionHandler(nil); return }
        // firebase db refs
        let kUsersListPath = "users"
        let usersReference = Database.database().reference(withPath: kUsersListPath)
        let kRequestsListPath = "requests"
        let requestsReference = Database.database().reference(withPath: kRequestsListPath)
        usersReference.child(uid).observeSingleEvent(of: .value) { (userSnapshot) in
            if userSnapshot.exists() {
                var user = User(snapshot: userSnapshot)
                requestsReference.child(uid).child(currentUserUid).observeSingleEvent(of: .value, with: { (requestsSnapshot) in
                    if requestsSnapshot.exists() {
                        user.requestSent = true
                    }
                    completionHandler(user)
                    return
                })
            } else {
                completionHandler(nil)
                return
            }
        }
    }
    
    // converts a timestamp from firebase into a string
    func timestampToText (timestamp: Int64) -> String {
        let currentTime = Int64(NSDate().timeIntervalSince1970)
        let motiveTime = timestamp / -1000
        let createdTime = currentTime - motiveTime
        if createdTime < 5 {
            return "Just now"
        } else if (createdTime < 60) {
            return String(createdTime) + "s"
            // less then an hour
        } else if (createdTime < 3600) {
            return String(createdTime / 60) + "m"
            // less then 2 days
        } else if (createdTime < 172800) {
            return String(createdTime / 60 / 60) + "h"
            // less then 6 days
        } else if (createdTime < 518400) {
            return String(createdTime / 60 / 60 / 24) + "d"
        } else {
            // longer than a week
            let date = Date(timeIntervalSince1970: TimeInterval(motiveTime))
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .none
            dateFormatter.locale = Locale(identifier: "en_US")

            return dateFormatter.string(from: date)
        }
    }
    
    func numToText(num: Int) -> String {
        if num < 1000 {
            return String(num)
        } else if num < 100000 {
            let d = Double(num) / 1000
            let rounded = Double(round(10*d)/10)
            return String(rounded) + "k"
        } else if num < 1000000 {
            let d = Double(num) / 1000
            let rounded = Double(round(d))
            let i = Int(rounded)
            return String(i) + "k"
        } else {
            let d = Double(num) / 1000000
            let rounded = Double(round(10*d)/10)
            return String(rounded) + "M"
        }
    }
    
    // apply a blur subview to a uiView
    func applyBlurEffect(toView: UIView) -> UIView {
        let blur = UIBlurEffect(style: UIBlurEffectStyle.regular)
        let blurEffectView = UIVisualEffectView(effect: blur)
        blurEffectView.frame = toView.bounds
        toView.addSubview(blurEffectView)
        return toView
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
    
    // function to determine if viewcontroller is iphone X - to adjust top view
    func isPhoneX() -> Bool {
        if UIDevice().userInterfaceIdiom == .phone {
            switch UIScreen.main.nativeBounds.height {
            case 2436:
                // iphone X / XS
                return true
            case 2688:
                // iphone XS MAX
                return true
            case 1792:
                // iphone XR
                return true
            case 2048:
                // i pad pro 12.9
                return true
            case 2224:
                // ipad pro 10.5 inch
                return true
            case 1536:
                // ipad pro 9.7 inch
                return true

            default:
                return false
            }
        } else {
            return false
        }
    }
    // wait a time interval on queue
    func run(after wait: TimeInterval, closure: @escaping () -> Void) {
        let queue = DispatchQueue.main
        queue.asyncAfter(deadline: DispatchTime.now() + wait, execute: closure)
    }

    
    func addGradientToView(_ view: UIView) {
        let gradient = CAGradientLayer()
        gradient.colors = [UIColor(red:0.95, green:0.45, blue:0.21, alpha:0.8).cgColor, UIColor(red:0.99, green:0.78, blue:0.19, alpha:0.8).cgColor]
        //gradient.colors = [UIColor(red:1.00, green:0.42, blue:0.00, alpha:1.0).cgColor, UIColor(red:0.93, green:0.04, blue:0.47, alpha:1.0).cgColor]
        //gradient.colors = [UIColor(red:0.07, green:0.60, blue:0.56, alpha:1.0).cgColor,UIColor(red:0.22, green:0.94, blue:0.49, alpha:1.0).cgColor]
        gradient.frame = view.bounds
        let angle: Double = 146
        let x: Double! = angle / 360.0
        let a = pow(sinf(Float(2.0 * .pi * ((x + 0.75) / 2.0))), 2.0)
        let b = pow(sinf(Float(2 * .pi * ((x + 0.0) / 2))), 2)
        let c = pow(sinf(Float(2 * .pi * ((x + 0.25) / 2))), 2)
        let d = pow(sinf(Float(2 * .pi * ((x + 0.5) / 2 ))), 2)
        
        gradient.endPoint = CGPoint(x: CGFloat(c),y: CGFloat(d))
        gradient.startPoint = CGPoint(x: CGFloat(a),y:CGFloat(b))
        
        view.layer.insertSublayer(gradient, at: 0)
    }
    
}

extension String {
    func height(withConstrainedWidth width: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [.font: font], context: nil)
        
        return ceil(boundingBox.height)
    }
    
    func width(withConstrainedHeight height: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: .greatestFiniteMagnitude, height: height)
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [.font: font], context: nil)
        
        return ceil(boundingBox.width)
    }
}

extension UIImage {
    func imageWithInsets(insetDimen: CGFloat) -> UIImage {
        return imageWithInset(insets: UIEdgeInsets(top: insetDimen, left: insetDimen, bottom: insetDimen, right: insetDimen))
    }
    
    func imageWithInset(insets: UIEdgeInsets) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(
            CGSize(width: self.size.width + insets.left + insets.right,
                   height: self.size.height + insets.top + insets.bottom), false, self.scale)
        let origin = CGPoint(x: insets.left, y: insets.top)
        self.draw(at: origin)
        let imageWithInsets = UIGraphicsGetImageFromCurrentImageContext()?.withRenderingMode(self.renderingMode)
        UIGraphicsEndImageContext()
        return imageWithInsets!
    }
    
}

/* code to force a sign out
 let firebaseAuth = Auth.auth()
 do {
 try firebaseAuth.signOut()
 // remove userID from keychain
 KeychainWrapper.standard.removeObject(forKey: "uid")
 print ("user has been signed out.")
 // segue back to login screen
 
 } catch let signOutError as NSError {
 // error signing out
 print ("Error signing out: %@", signOutError)
 AlertController.showAlert(self, title: "Error", message: "Sign out request could not be completed.")
 return
 }
 
 */

