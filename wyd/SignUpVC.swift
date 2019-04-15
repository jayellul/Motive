//
//  SignUpVC.swift
//  wyd
//
//  Created by Jason Ellul on 2018-04-14.
//  Copyright © 2018 Jason Ellul. All rights reserved.
//

import UIKit
import Firebase
import BEMCheckBox

class SignUpVC: UIViewController, BEMCheckBoxDelegate {
    
    // firebase db references
    static let kUsersListPath = "users"
    let usersReference = Database.database().reference(withPath: kUsersListPath)
    static let kUsernameListPath = "username"
    let usernameReference = Database.database().reference(withPath: kUsernameListPath)
    
    // ui kit components from storyboard
    @IBOutlet weak var scrollView: UIScrollView!
    
    // ui kit components from code
    var imagePicker: UIImagePickerController!

    let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius =  50
        // fix pathing to have default image literally just drag it in ?
        imageView.image = #imageLiteral(resourceName: "default user icon.png")
        return imageView
    }()
    
    let tapToChangeLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = UIColor.white
        label.font = UIFont.systemFont(ofSize: 16.0)
        label.text = "Tap to Change"
        label.textAlignment = .center
        return label
    }()
    
    let imageChangeButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitleColor(.clear, for: .normal)
        button.setTitle("", for: .normal)
        button.backgroundColor = UIColor.clear
        return button
    }()
    
    let usernameField: UITextField = {
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        textField.textColor = UIColor.white
        textField.backgroundColor = UIColor.clear
        textField.layer.cornerRadius = 25
        textField.layer.borderColor = UIColor.white.cgColor
        textField.layer.borderWidth = 1.5
        textField.font = UIFont.systemFont(ofSize: 16.0)
        textField.textAlignment = .center
        textField.attributedPlaceholder = NSAttributedString(string: "Username", attributes: [NSAttributedStringKey.foregroundColor: UIColor.white])
        textField.text = ""
        textField.tag = 0
        return textField
    }()
    
    let emailField: UITextField = {
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        textField.textColor = UIColor.white
        textField.backgroundColor = UIColor.clear
        textField.layer.cornerRadius = 25
        textField.layer.borderColor = UIColor.white.cgColor
        textField.layer.borderWidth = 1.5
        textField.font = UIFont.systemFont(ofSize: 16.0)
        textField.textAlignment = .center
        textField.attributedPlaceholder = NSAttributedString(string: "Email", attributes: [NSAttributedStringKey.foregroundColor: UIColor.white])
        textField.text = ""
        textField.tag = 1
        textField.keyboardType = UIKeyboardType.emailAddress
        return textField
    }()
    
    let passwordField: UITextField = {
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
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
    
    let confirmPasswordField: UITextField = {
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        textField.textColor = UIColor.white
        textField.backgroundColor = UIColor.clear
        textField.layer.cornerRadius = 25
        textField.layer.borderColor = UIColor.white.cgColor
        textField.layer.borderWidth = 1.5
        textField.font = UIFont.systemFont(ofSize: 16.0)
        textField.textAlignment = .center
        textField.attributedPlaceholder = NSAttributedString(string: "Confirm Password", attributes: [NSAttributedStringKey.foregroundColor: UIColor.white])
        textField.text = ""
        textField.isSecureTextEntry = true
        textField.tag = 3
        return textField
    }()
    
    let signUpButton: LoadingButton = {
        let button = LoadingButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitleColor(UIColor(red:1.00, green:0.60, blue:0.20, alpha:1.0), for: .normal)
        button.setTitle("Create Account", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16.0)
        button.backgroundColor = UIColor.white
        button.layer.cornerRadius = 5
        button.layer.borderColor = UIColor.white.cgColor
        button.layer.borderWidth = 1.5
        button.activityIndicator.activityIndicatorViewStyle = .gray
        return button
    }()
    
    let backButton: LoadingButton = {
        let button = LoadingButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitleColor(.white, for: .normal)
        button.setTitle("Already have an account?", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16.0)
        button.backgroundColor = UIColor.clear
        return button
    }()
    // check marks
    let usernameImageView: InputImageView = {
        let imageView = InputImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.setToError()
        return imageView
    }()
    let emailImageView: InputImageView = {
        let imageView = InputImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.setToError()
        return imageView
    }()
    let passwordImageView: InputImageView = {
        let imageView = InputImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.setToError()
        return imageView
    }()
    let confirmPasswordImageView: InputImageView = {
        let imageView = InputImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.setToError()
        return imageView
    }()
    let termsOfServiceButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("I agree to the Motive Terms of Service", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16.0)
        button.setTitleColor(UIColor.white, for: .normal)
        button.titleLabel?.textAlignment = .left
        return button
    }()
    
    let checkBox: BEMCheckBox = {
        let checkBox = BEMCheckBox(frame: CGRect(x: 0, y: 0, width: 32, height: 32))
        checkBox.boxType = BEMBoxType.square
        checkBox.onFillColor = UIColor.clear
        checkBox.onTintColor = UIColor.white
        checkBox.offFillColor = UIColor.clear
        checkBox.tintColor = UIColor.white
        checkBox.onAnimationType = BEMAnimationType.oneStroke
        checkBox.offAnimationType = BEMAnimationType.oneStroke
        checkBox.translatesAutoresizingMaskIntoConstraints = false
        return checkBox
    }()
        
    func setupSubviews() {
        addGradientToView(view)

        self.scrollView.frame.size.width = self.view.frame.size.width
        self.scrollView.contentSize = CGSize(width: view.frame.size.width, height: max(view.frame.size.height, 635))

        self.scrollView.addSubview(profileImageView)
        profileImageView.topAnchor.constraint(equalTo: self.scrollView.topAnchor, constant: 65).isActive = true
        profileImageView.centerXAnchor.constraint(equalTo: self.scrollView.centerXAnchor).isActive = true
        profileImageView.widthAnchor.constraint(equalToConstant: 100).isActive = true
        profileImageView.heightAnchor.constraint(equalToConstant: 100).isActive = true
        
        self.scrollView.addSubview(tapToChangeLabel)
        tapToChangeLabel.topAnchor.constraint(equalTo: self.scrollView.topAnchor, constant: 170).isActive = true
        tapToChangeLabel.centerXAnchor.constraint(equalTo: self.scrollView.centerXAnchor).isActive = true
        tapToChangeLabel.widthAnchor.constraint(equalToConstant: 110).isActive = true
        tapToChangeLabel.heightAnchor.constraint(equalToConstant: 20).isActive = true
        
        self.scrollView.addSubview(imageChangeButton)
        imageChangeButton.topAnchor.constraint(equalTo: self.scrollView.topAnchor, constant: 65).isActive = true
        imageChangeButton.centerXAnchor.constraint(equalTo: self.scrollView.centerXAnchor).isActive = true
        imageChangeButton.widthAnchor.constraint(equalToConstant: 110).isActive = true
        imageChangeButton.heightAnchor.constraint(equalToConstant: 125).isActive = true
        imageChangeButton.addTarget(self, action: #selector(SignUpVC.imageChangePressed(_:)), for: .touchUpInside)
        
        self.scrollView.addSubview(usernameField)
        usernameField.topAnchor.constraint(equalTo: self.scrollView.topAnchor, constant: 210).isActive = true
        usernameField.centerXAnchor.constraint(equalTo: self.scrollView.centerXAnchor).isActive = true
        usernameField.heightAnchor.constraint(equalToConstant: 50).isActive = true
        usernameField.widthAnchor.constraint(equalToConstant: self.scrollView.frame.width - 32).isActive = true
        usernameField.delegate = self
        
        self.scrollView.addSubview(emailField)
        emailField.topAnchor.constraint(equalTo: self.scrollView.topAnchor, constant: 285).isActive = true
        emailField.centerXAnchor.constraint(equalTo: self.scrollView.centerXAnchor).isActive = true
        emailField.heightAnchor.constraint(equalToConstant: 50).isActive = true
        emailField.widthAnchor.constraint(equalToConstant: self.scrollView.frame.width - 32).isActive = true
        emailField.delegate = self
        
        self.scrollView.addSubview(passwordField)
        passwordField.topAnchor.constraint(equalTo: self.scrollView.topAnchor, constant: 360).isActive = true
        passwordField.centerXAnchor.constraint(equalTo: self.scrollView.centerXAnchor).isActive = true
        passwordField.heightAnchor.constraint(equalToConstant: 50).isActive = true
        passwordField.widthAnchor.constraint(equalToConstant: self.scrollView.frame.width - 32).isActive = true
        passwordField.delegate = self
        
        self.scrollView.addSubview(confirmPasswordField)
        confirmPasswordField.topAnchor.constraint(equalTo: self.scrollView.topAnchor, constant: 435).isActive = true
        confirmPasswordField.centerXAnchor.constraint(equalTo: self.scrollView.centerXAnchor).isActive = true
        confirmPasswordField.heightAnchor.constraint(equalToConstant: 50).isActive = true
        confirmPasswordField.widthAnchor.constraint(equalToConstant: self.scrollView.frame.width - 32).isActive = true
        confirmPasswordField.delegate = self
        
        self.scrollView.addSubview(checkBox)
        checkBox.centerYAnchor.constraint(equalTo: self.scrollView.topAnchor, constant: 512).isActive = true
        checkBox.leftAnchor.constraint(equalTo: self.scrollView.leftAnchor, constant: 16).isActive = true
        checkBox.heightAnchor.constraint(equalToConstant: 32).isActive = true
        checkBox.widthAnchor.constraint(equalToConstant: 32).isActive = true
        checkBox.delegate = self
        
        self.scrollView.addSubview(termsOfServiceButton)
        termsOfServiceButton.centerYAnchor.constraint(equalTo: self.scrollView.topAnchor, constant: 512).isActive = true
        termsOfServiceButton.leftAnchor.constraint(equalTo: self.scrollView.leftAnchor, constant: 64).isActive = true
        termsOfServiceButton.heightAnchor.constraint(equalToConstant: 20).isActive = true
        termsOfServiceButton.addTarget(self, action: #selector(SignUpVC.goToEULA(_:)), for: .touchUpInside)
        
        self.scrollView.addSubview(signUpButton)
        signUpButton.topAnchor.constraint(equalTo: self.scrollView.topAnchor, constant: 540).isActive = true
        signUpButton.centerXAnchor.constraint(equalTo: self.scrollView.centerXAnchor).isActive = true
        signUpButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        signUpButton.widthAnchor.constraint(equalToConstant: self.scrollView.frame.width - 32).isActive = true
        signUpButton.addTarget(self, action: #selector(SignUpVC.createNewAccountPressed(_:)), for: .touchUpInside)
        
        self.scrollView.addSubview(backButton)
        backButton.topAnchor.constraint(equalTo: self.scrollView.topAnchor, constant: 605).isActive = true
        backButton.centerXAnchor.constraint(equalTo: self.scrollView.centerXAnchor).isActive = true
        backButton.heightAnchor.constraint(equalToConstant: 25).isActive = true
        backButton.widthAnchor.constraint(equalToConstant: 190).isActive = true
        backButton.addTarget(self, action: #selector(SignUpVC.backToSignInPressed(_:)), for: .touchUpInside)
        
        // setup image picker
        imagePicker = UIImagePickerController()
        imagePicker.allowsEditing = true
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = self
        
        // setup inputimageviews
        self.usernameField.addSubview(usernameImageView)
        usernameImageView.centerYAnchor.constraint(equalTo: usernameField.centerYAnchor).isActive = true
        usernameImageView.rightAnchor.constraint(equalTo: usernameField.rightAnchor, constant: -12.5).isActive = true
        usernameImageView.widthAnchor.constraint(equalToConstant: 25).isActive = true
        usernameImageView.heightAnchor.constraint(equalToConstant: 25).isActive = true
        
        self.emailField.addSubview(emailImageView)
        emailImageView.centerYAnchor.constraint(equalTo: emailField.centerYAnchor).isActive = true
        emailImageView.rightAnchor.constraint(equalTo: emailField.rightAnchor, constant: -12.5).isActive = true
        emailImageView.widthAnchor.constraint(equalToConstant: 25).isActive = true
        emailImageView.heightAnchor.constraint(equalToConstant: 25).isActive = true
        
        self.passwordField.addSubview(passwordImageView)
        passwordImageView.centerYAnchor.constraint(equalTo: passwordField.centerYAnchor).isActive = true
        passwordImageView.rightAnchor.constraint(equalTo: passwordField.rightAnchor, constant: -12.5).isActive = true
        passwordImageView.widthAnchor.constraint(equalToConstant: 25).isActive = true
        passwordImageView.heightAnchor.constraint(equalToConstant: 25).isActive = true
        
        self.confirmPasswordField.addSubview(confirmPasswordImageView)
        confirmPasswordImageView.centerYAnchor.constraint(equalTo: confirmPasswordField.centerYAnchor).isActive = true
        confirmPasswordImageView.rightAnchor.constraint(equalTo: confirmPasswordField.rightAnchor, constant: -12.5).isActive = true
        confirmPasswordImageView.widthAnchor.constraint(equalToConstant: 25).isActive = true
        confirmPasswordImageView.heightAnchor.constraint(equalToConstant: 25).isActive = true
        
    }
    

    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        setupSubviews()
        self.hideKeyboardWhenTappedAround()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: Notification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: Notification.Name.UIKeyboardWillHide, object: nil)
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
   
    // update view of profile image
    @objc func imageChangePressed(_ sender: UIButton) {
        self.present(imagePicker, animated: true, completion: nil)
    }
    
    @objc func createNewAccountPressed(_ sender: LoadingButton!) {
        self.signUpButton.showLoading()
        guard let username = usernameField.text,
        username != "",
        let email = emailField.text?.lowercased(),
        email != "",
        let password = passwordField.text,
        password != "",
        let confirmPassword = confirmPasswordField.text,
        confirmPassword != ""
            // if any fields are missing
            else {
                // display alert asking for fields
                AlertController.showAlert(self, title: "Missing Required Fields", message: "Please fill out all of the fields.")
                self.signUpButton.hideLoading()
                return
        }
        guard let image = profileImageView.image else {
            self.signUpButton.hideLoading()
            return
        }
        // username checks
        // check for regex - valid characters: letters, numbers and underscores
        if (isValidUsername(username) == false) {
            AlertController.showAlert(self, title: "Error", message: "Username contains invalid characters or is an invalid length.")
            self.signUpButton.hideLoading()
            return
        }
        if (password != confirmPassword) {
            AlertController.showAlert(self, title: "Error", message: "Passwords do not match.")
            self.signUpButton.hideLoading()
            return
        }
        // check username isnt already taken
        usernameReference.child(username.lowercased()).observeSingleEvent(of: .value, with: { snapshot in
            if snapshot.exists() {
                // username already taken
                AlertController.showAlert(self, title: "Error", message: "That username is already taken.")
                self.signUpButton.hideLoading()
                return
            } else {
                // add user to firebase
                Auth.auth().createUser(withEmail: email, password: password) { (user, error) in
                    guard error == nil else {
                        AlertController.showAlert(self, title: "Error", message: error!.localizedDescription)
                        self.signUpButton.hideLoading()
                        return
                    }
                    guard let user = user else {
                        self.signUpButton.hideLoading()
                        return
                    }
                    print (user.email ?? "No email for signup")
                    print (user.uid)
                
                    // upload image to firebase storage
                    self.uploadProfileImage(image) { url in
                        if url != nil {
                            let changeReqest = user.createProfileChangeRequest()
                            changeReqest.displayName = username
                            changeReqest.photoURL = url
                            changeReqest.commitChanges(completion: { (error) in
                                guard error == nil else {
                                    AlertController.showAlert(self, title: "Error", message: error!.localizedDescription)
                                    self.signUpButton.hideLoading()
                                    return
                                }
                                // save the profile data to firebase database
                                let latitude = 43.61912036
                                let longitude = -79.44891133
                                let display = username
                                self.saveProfile(username: username, display: display, latitude: latitude, longitude: longitude, profileImageURL: url!) { success in
                                    if success {
                                        // add lowercased usernames in database
                                        self.usernameReference.child(username.lowercased()).setValue(user.uid)
                                        // add error handling too
                                        // go to main feed of created user
                                        self.signUpButton.hideLoading()
                                        self.performSegue(withIdentifier: "successfulSignUpSegue", sender: nil)
                                    }
                                }
                            })
                        } else {
                            // unable to upload profile url
                            self.signUpButton.hideLoading()
                            
                        }
                        
                    }
                    
                }
            }
        })        
        
    }
    
    
    // uploads image to firebase, returns URL
    func uploadProfileImage(_ image:UIImage, completion: @escaping ((_ url:URL?)->())) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        let storageRef = Storage.storage().reference().child("user/\(uid)")
        guard let imageData = UIImageJPEGRepresentation(image, 0.75) else { return }
        let metaData = StorageMetadata()
        metaData.contentType = "image/jpg"
        storageRef.putData(imageData, metadata: metaData) { metaData, error in
            if error == nil, metaData != nil {
                // upload was successful
                if let url = metaData?.downloadURL() {
                    completion(url)
                } else {
                    completion(nil)
                }
            } else {
                
            }
            
        }
    }
    
    // saves username and profile image url to database
    func saveProfile(username:String, display:String, latitude:Double, longitude:Double, profileImageURL:URL, completion: @escaping ((_ success:Bool)->())) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let databaseRef = usersReference.child(uid)

        let userObject = [
            "uid": uid,
            "un": username,
            "dis": display,
            "nFers": 0,
            "nFing": 0,
            "pLat": latitude,
            "pLong": longitude,
            "zl": 18.0,
            "pURL": profileImageURL.absoluteString            
        ] as [String:Any]
        databaseRef.setValue(userObject) { error, ref in
            completion(true)
        }
        
    }
    
    @objc func goToEULA(_ sender: Any) {
        let EULAViewController = storyboard?.instantiateViewController(withIdentifier: "EULAViewController") as! EULAViewController
        self.navigationController?.pushViewController(EULAViewController, animated: true)
    }
    
    // go back to login screen button
    @objc func backToSignInPressed(_ sender: Any) {
        self.performSegue(withIdentifier: "createAccountToSignInSegue", sender: nil)
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
    
    func isValidEmail(_ email: String) -> Bool {
        let regex = "(?:[\\p{L}0-9!#$%\\&'*+/=?\\^_`{|}~-]+(?:\\.[\\p{L}0-9!#$%\\&'*+/=?\\^_`{|}" +
            "~-]+)*|\"(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21\\x23-\\x5b\\x5d-\\" +
            "x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])*\")@(?:(?:[\\p{L}0-9](?:[a-" +
            "z0-9-]*[\\p{L}0-9])?\\.)+[\\p{L}0-9](?:[\\p{L}0-9-]*[\\p{L}0-9])?|\\[(?:(?:25[0-5" +
            "]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-" +
            "9][0-9]?|[\\p{L}0-9-]*[\\p{L}0-9]:(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21" +
        "-\\x5a\\x53-\\x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])+)\\])"
        let usernameTest = NSPredicate(format: "SELF MATCHES %@", regex)
        return usernameTest.evaluate(with: email)
    }


}


extension SignUpVC: UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate {

    
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let pickedImage = info[UIImagePickerControllerEditedImage] as? UIImage {
            self.profileImageView.image = pickedImage
        }
        
        picker.dismiss(animated: true, completion: nil)
    }
    
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
    }
    
    // press enter to go to next field and submit form
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if (textField.tag == 0) {
            self.emailField.becomeFirstResponder()
        } else if (textField.tag == 1) {
            self.passwordField.becomeFirstResponder()
        } else if (textField.tag == 2) {
            self.confirmPasswordField.becomeFirstResponder()
        } else if (textField.tag == 3) {
            textField.resignFirstResponder()
            self.createNewAccountPressed(self.signUpButton)
        }
        return true
    }
    
    // max amount of characters in display text field
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {

        let currentText = textField.text ?? ""
        let prospectiveText = (currentText as NSString).replacingCharacters(in: range, with: string)
        var maxLength = 40
        switch textField.tag {
        case 0:
            maxLength = 18
            if isValidUsername(prospectiveText) {
                usernameImageView.setToSuccess()
            } else {
                usernameImageView.setToError()
            }
        case 1:
            maxLength = 40
            if isValidEmail(prospectiveText) {
                emailImageView.setToSuccess()
            } else {
                emailImageView.setToError()
            }
        case 2:
            maxLength = 20
            if prospectiveText.count >= 6 {
                passwordImageView.setToSuccess()
            } else {
                passwordImageView.setToError()
            }
        case 3:
            maxLength = 20
            if prospectiveText.count >= 6 && prospectiveText == passwordField.text {
                confirmPasswordImageView.setToSuccess()
            } else {
                confirmPasswordImageView.setToError()
            }
        default:
            maxLength = 40
        }
        //let currentText = textField.text ?? ""
        //let prospectiveText = (currentText as NSString).replacingCharacters(in: range, with: string)
        guard string.count > 0 else {
            return true
        }
        return prospectiveText.count <= maxLength
    }
}
