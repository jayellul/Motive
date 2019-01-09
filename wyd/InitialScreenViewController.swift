//
//  InitialScreenViewController.swift
//  wyd
//
//  Created by Jason Ellul on 2018-12-03.
//  Copyright © 2018 Jason Ellul. All rights reserved.
//

import UIKit
import Firebase

class InitialScreenViewController: UIViewController {
    
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
        return button
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

        self.scrollView.frame.size.width = self.view.frame.size.width
        self.scrollView.contentSize = CGSize(width: view.frame.size.width, height: view.frame.size.height)
        
        self.scrollView.addSubview(logoLabel)
        logoLabel.topAnchor.constraint(equalTo: self.scrollView.topAnchor, constant: 70).isActive = true
        logoLabel.centerXAnchor.constraint(equalTo: self.scrollView.centerXAnchor).isActive = true
        logoLabel.widthAnchor.constraint(equalToConstant: self.scrollView.frame.width - 32).isActive = true
        logoLabel.heightAnchor.constraint(equalToConstant: 200).isActive = true
        
        self.scrollView.addSubview(signInButton)
        signInButton.topAnchor.constraint(equalTo: self.scrollView.topAnchor, constant: 365).isActive = true
        signInButton.centerXAnchor.constraint(equalTo: self.scrollView.centerXAnchor).isActive = true
        signInButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        signInButton.widthAnchor.constraint(equalToConstant: self.scrollView.frame.width - 32).isActive = true
        signInButton.addTarget(self, action: #selector(toSignInPressed(_:)), for: .touchUpInside)

        self.scrollView.addSubview(signUpButton)
        signUpButton.topAnchor.constraint(equalTo: self.scrollView.topAnchor, constant: 440).isActive = true
        signUpButton.centerXAnchor.constraint(equalTo: self.scrollView.centerXAnchor).isActive = true
        signUpButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        signUpButton.widthAnchor.constraint(equalToConstant: self.scrollView.frame.width - 32).isActive = true
        signUpButton.addTarget(self, action: #selector(toSignUpPressed(_:)), for: .touchUpInside)

        self.scrollView.addSubview(activityIndicator)
        activityIndicator.centerXAnchor.constraint(equalTo: self.scrollView.centerXAnchor).isActive = true
        activityIndicator.topAnchor.constraint(equalTo: self.scrollView.topAnchor, constant: 300).isActive = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        setupSubviews()

        if let user = Auth.auth().currentUser {
            // check if user is in db
            self.usersReference.child(user.uid).observeSingleEvent(of: .value) { (snapshot) in
                if (snapshot.exists()) {
                    self.performSegue(withIdentifier: "userAuthenticated", sender: nil)
                    print ("Firebase logged in and is in database.")
                } else {
                    print (user.uid + " exists in auth but not in database .. unsuccessful login.")
                    let firebaseAuth = Auth.auth()
                    do {
                        try firebaseAuth.signOut()
                        // remove userID from keychain
                        print ("user has been signed out.")
                        // segue back to login screen
 
                     } catch let signOutError as NSError {
                        // error signing out
                        print ("Error signing out: %@", signOutError)
                        AlertController.showAlert(self, title: "Error", message: "Sign out request could not be completed.")
                        return
                    }
                }
            }
            
        }
        self.signInButton.alpha = 0.0
        self.signUpButton.alpha = 0.0
        self.activityIndicator.startAnimating()
        // if current user is nil / not signed in then do the animation
        if (Auth.auth().currentUser == nil) {
            self.activityIndicator.stopAnimating()
            let old = self.logoLabel.center.y
            self.logoLabel.center.y -= 20
            self.logoLabel.alpha = 0.0
            UIView.animate(withDuration: 0.5, delay: 0.5, animations: {
                self.logoLabel.center.y = old
                self.logoLabel.alpha = 1.0
                self.signInButton.alpha = 1.0
                self.signUpButton.alpha = 1.0
            })
        }
        print ("initial view loaded")


    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // add keyboard obersvers
         // code to force a sign out
        /* let firebaseAuth = Auth.auth()
         do {
         try firebaseAuth.signOut()
         // remove userID from keychain
         print ("user has been signed out.")
         // segue back to login screen
         
         } catch let signOutError as NSError {
         // error signing out
         print ("Error signing out: %@", signOutError)
         AlertController.showAlert(self, title: "Error", message: "Sign out request could not be completed.")
         return
         }*/
        
    
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @objc func toSignInPressed(_ sender: LoadingButton!) {
        self.performSegue(withIdentifier: "toSignInScreen", sender: nil)
    }
    @objc func toSignUpPressed(_ sender: LoadingButton!) {
        self.performSegue(withIdentifier: "toSignUpScreen", sender: nil)
    }
    
    
}
