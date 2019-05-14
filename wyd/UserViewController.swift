//
//  UserViewController.swift
//  wyd
//
//  Created by Jason Ellul on 2018-05-24.
//  Copyright © 2018 Jason Ellul. All rights reserved.
//

import UIKit
import Firebase
import Mapbox
import SDWebImage
import ODRefreshControl

class UserViewController: UIViewController, EditProfileDelegate {


    // firebase db refs
    static let kUsersListPath = "users"
    let usersReference = Database.database().reference(withPath: kUsersListPath)
    static let kUsersGoingListPath = "usersGoing"
    let usersGoingReference = Database.database().reference(withPath: kUsersGoingListPath)
    static let kUsersPostListPath = "usersPost"
    let usersPostReference = Database.database().reference(withPath: kUsersPostListPath)
    static let kFollowersListPath = "followers"
    let followersReference = Database.database().reference(withPath: kFollowersListPath)
    static let kFollowingListPath = "following"
    let followingReference = Database.database().reference(withPath: kFollowingListPath)
    static let kMotivesListPath = "motives"
    let motivesReference = Database.database().reference(withPath: kMotivesListPath)
    static let kMotivesGoingListPath = "motivesGoing"
    let motivesGoingReference = Database.database().reference(withPath: kMotivesGoingListPath)
    static let kBlockedListPath = "blocked"
    let blockedReference = Database.database().reference(withPath: kBlockedListPath)
    static let kPrivateListPath = "private"
    let privateReference = Database.database().reference(withPath: kPrivateListPath)
    static let kRequestsListPath = "requests"
    let requestsReference = Database.database().reference(withPath: kRequestsListPath)
    
    // functions call
    lazy var functions = Functions.functions()

    // user id whose profile it is - "view user"
    var uid: String?
    // the user to load
    var user: User?
    
    // delegate so that table this was clicked on from knows to update
    var friendViewControllerDelegate: FriendViewControllerDelegate?
    var pinchDelegate: PinchDelegate?

    // table and map class variables
    var postedMotives = [Motive]()
    var goingMotives = [Motive]()
    var storedContentOffsets: [CGFloat] = [220,220,220]
    var previousSelectedSegmentIndex = 0
    
    var motiveAndUsers = [MotiveAndUser]()
    var userHashTableDelegate: UserHashTableDelegate?
    var motiveHashTableDelegate: MotiveHashTableDelegate?
    let numMotivesToLoad: UInt = 10
    var outOfPostedMotives = false
    var outOfGoingMotives = false
    var loadingMorePostedMotives = false
    var loadingMoreGoingMotives = false
    var lastPostedTime: Int = 0
    var lastGoingTime: Int = 0
    
    var mapFirstLoad = true
    var tableSelected = false
    
    private let reuseIdentifier = "motiveCell"
    private let refreshIdentifier = "refreshCell"

    
    
    // ui kit components
    @IBOutlet weak var transitionView: UIView!
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var headerViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var headerLabel: UILabel!
    lazy var customRefreshControl = ODRefreshControl(in: self.scrollView)

    // view for slide
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
    
    let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius =  50
        // fix pathing to have default image
        imageView.image = UIImage(named: "Images/default user icon.png")
        return imageView
    }()
    let displayLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = UIColor.black
        label.font = UIFont.boldSystemFont(ofSize: 20.0)
        label.text = ""
        label.textAlignment = .left
        return label
    }()
    let usernameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = UIColor(red: 153/255, green: 153/255, blue: 153/255, alpha: 1.0)
        label.font = UIFont.systemFont(ofSize: 16.0)
        label.text = ""
        label.textAlignment = .left
        return label
    }()
    let pictureBorderView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isUserInteractionEnabled = false
        view.backgroundColor = UIColor.white
        return view
    }()
    // point map view is banner - mapView is map
    let pointMapView: MGLMapView = {
        let map = MGLMapView()
        map.translatesAutoresizingMaskIntoConstraints = false
        map.isZoomEnabled = false
        map.isPitchEnabled = false
        map.isScrollEnabled = false
        map.isRotateEnabled = false
        map.isUserInteractionEnabled = false
        return map
    }()
    
    let pointFeature: MGLPointFeature = {
        let annotation = MGLPointFeature()
        annotation.attributes = [
            "name": ""
        ]
        return annotation
    }()
    
    let hideLegalView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isUserInteractionEnabled = true
        view.backgroundColor = UIColor.white
        return view
    }()
    // followers components
    let followersButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitleColor(UIColor(red: 153/255, green: 153/255, blue: 153/255, alpha: 1.0), for: .normal)
        button.setTitle("", for: .normal)
        //button.titleLabel?.font = UIFont.systemFont(ofSize: 15.0)
        button.layer.borderWidth = 0
        //button.layer.borderColor = UIColor(red: 242/255, green: 242/255, blue: 242/255, alpha: 1.0).cgColor
        //button.layer.cornerRadius = 5
        button.backgroundColor = UIColor.clear
        return button
    }()
    let followersLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = UIColor(red: 153/255, green: 153/255, blue: 153/255, alpha: 1.0)
        label.font = UIFont.systemFont(ofSize: 12.0)
        label.text = "followers"
        label.textAlignment = .center
        return label
    }()
    let numFollowersLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = UIColor.black
        label.font = UIFont.boldSystemFont(ofSize: 15.0)
        label.text = "0"
        label.textAlignment = .center
        return label
    }()
    // following buttons
    let followingButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitleColor(UIColor(red: 153/255, green: 153/255, blue: 153/255, alpha: 1.0), for: .normal)
        button.setTitle("", for: .normal)
        //button.titleLabel?.font = UIFont.systemFont(ofSize: 15.0)
        button.layer.borderWidth = 0
        //button.layer.borderColor = UIColor(red: 242/255, green: 242/255, blue: 242/255, alpha: 1.0).cgColor
        //button.layer.cornerRadius = 5
        button.backgroundColor = UIColor.clear
        return button
    }()
    let followingLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = UIColor(red: 153/255, green: 153/255, blue: 153/255, alpha: 1.0)
        label.font = UIFont.systemFont(ofSize: 12.0)
        label.text = "following"
        label.textAlignment = .center
        return label
    }()
    let numFollowingLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = UIColor.black
        label.font = UIFont.boldSystemFont(ofSize: 15.0)
        label.text = "0"
        label.textAlignment = .center
        return label
    }()
    // show for loading button
    let loadingButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitleColor(UIColor.black, for: .normal)
        button.setTitle("Loading", for: .normal)
        button.titleLabel?.textAlignment = .center
        button.titleLabel?.font = UIFont.systemFont(ofSize: 15.0)
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor(red: 242/255, green: 242/255, blue: 242/255, alpha: 1.0).cgColor
        button.layer.cornerRadius = 5
        button.backgroundColor = UIColor.white
        return button
    }()
    // segmented control
    let segmentedControl: UISegmentedControl = {
        let items = ["Posts", "Going", "Map"]
        let control = UISegmentedControl(items: items)
        control.tintColor = UIColor.clear
        control.backgroundColor = UIColor.white
        control.setTitleTextAttributes([NSAttributedStringKey.foregroundColor: UIColor.black, NSAttributedStringKey.font: UIFont.systemFont(ofSize: 16)], for: .normal)
        control.setTitleTextAttributes([NSAttributedStringKey.foregroundColor: UIColor.black, NSAttributedStringKey.font: UIFont.boldSystemFont(ofSize: 16)], for: .selected)
        control.selectedSegmentIndex = 0
        return control
    }()
    // bars for segmneted control
    let buttonBar: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 1.00, green: 0.60, blue: 0.20, alpha: 1.0)
        return view
    }()
    let greyBar: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 0.783922, green: 0.780392, blue: 0.8, alpha: 1.0)
        return view
    }()
    // table view of users posts and posts they are going to
    let tableView: UITableView = {
        let table = UITableView()
        table.tableFooterView = UIView (frame: CGRect.zero)
        table.layoutMargins = UIEdgeInsets.zero
        table.separatorInset = UIEdgeInsets.zero
        table.estimatedRowHeight = UITableViewAutomaticDimension
        table.rowHeight = UITableViewAutomaticDimension
        return table
    }()
    
    // map view of users posts and posts they are going to - only shown in map tab
    let mapView: MGLMapView = {
        let map = MGLMapView()
        map.isPitchEnabled = false
        map.isRotateEnabled = false
        return map
    }()
    
    // loading indicator for main part of profile
    let activityIndicator: UIActivityIndicatorView = {
        let activityIndicator = UIActivityIndicatorView()
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.hidesWhenStopped = true
        activityIndicator.color = UIColor.lightGray
        return activityIndicator
    }()
    // lock image and privacy label
    let lockImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.masksToBounds = true
        // fix pathing to have default image
        imageView.image = #imageLiteral(resourceName: "padlock.png")
        return imageView
    }()
    let privacyLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = UIColor(red: 153/255, green: 153/255, blue: 153/255, alpha: 1.0)
        //label.textColor = UIColor.black
        label.font = UIFont.systemFont(ofSize: 14.0)
        label.text = "You need to be Friends to view this content"
        label.textAlignment = .center
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        customRefreshControl?.addTarget(self, action: #selector(refreshUserDetails(_:)), for: .valueChanged)
        pointMapView.delegate = self
        userHashTableDelegate = self.tabBarController as? CustomTabBarController
        motiveHashTableDelegate = self.tabBarController as? CustomTabBarController
        if let uid = self.uid {
            print (uid)
            // if there is already a user and lists loaded
            if self.user != nil {
                self.setupSubviews()
                self.addTapGestureRecognizers()
                self.loadUserDetails()
                self.setupUserStatus()
            } else {
                setupSubviews()
                loadUserDetails()
                pointMapView.reloadStyle(pointMapView)
                getUser(uid: uid) { (resultUser) in
                    if let user = resultUser {
                        self.user = user
                        self.addTapGestureRecognizers()
                        self.loadUserDetails()
                        self.setupUserStatus()
                    } else {
                        AlertController.showAlert(self, title: "Error", message: "User Profile cannot be displayed.")
                        self.navigationController?.popViewController(animated: false)
                    }
                }
            }
        } else {
            AlertController.showAlert(self, title: "Error", message: "User Profile cannot be displayed.")
            self.navigationController?.popViewController(animated: false)
        }
        // add transition view swipe
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panGestureRecognizerAction(_:)))
        panGestureRecognizer.delegate = self
        // add transition view pinch
        let pinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(pinchGestureRecognizerAction(_:)))
        // delay for 0.5 seconds before enabling gestures
        run(after: 0.5) {
            // add swipe right gesture
            self.transitionView.addGestureRecognizer(panGestureRecognizer)
            self.transitionView.addGestureRecognizer(pinchGestureRecognizer)
        }
        
        
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // programmatically setup all the subviews
    func setupSubviews() {
        transitionView.frame = view.frame
        transitionView.bounds = view.bounds
        print (transitionView.frame.debugDescription)
        headerView.frame.size.height = 75
        headerView.frame.size.width = view.frame.width
        headerView.bounds.size.width = view.frame.width
        if pointMapView.subviews[1] is UIImageView {
            // adjust the logo position
            let mapBoxLogo = pointMapView.subviews[1] as! UIImageView
            mapBoxLogo.frame = CGRect(x: 8, y: (10.5 / 1.5), width: mapBoxLogo.frame.width / 1.5, height: mapBoxLogo.frame.height / 1.5)
            // adjust i button position
            let mapBoxButton = pointMapView.attributionButton
            mapBoxButton.frame = CGRect(x: 8 + mapBoxLogo.frame.width + 4, y: (10.5 / 1.5), width: mapBoxLogo.frame.height, height: mapBoxLogo.frame.height)
        }
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
        // set transition and scrollView view frames
        self.transitionView.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height)
        self.scrollView.frame = CGRect(x: 0, y: headerView.frame.height, width: self.transitionView.frame.width, height: self.transitionView.frame.height - headerView.frame.height)
        self.scrollView.contentSize = CGSize(width: self.scrollView.frame.width, height: self.scrollView.frame.height)
        //self.scrollView.translatesAutoresizingMaskIntoConstraints = false
        self.scrollView.autoresizingMask = []
        self.scrollView.addSubview(pointMapView)
        pointMapView.leftAnchor.constraint(equalTo: self.scrollView.leftAnchor).isActive = true
        pointMapView.topAnchor.constraint(equalTo: self.scrollView.topAnchor).isActive = true
        pointMapView.widthAnchor.constraint(equalToConstant: self.scrollView.frame.size.width).isActive = true
        pointMapView.heightAnchor.constraint(equalToConstant: 100).isActive = true
        pointMapView.frame = CGRect(x: 0, y: 0, width: scrollView.frame.width, height: 100)
        pointMapView.delegate = self
        
        self.scrollView.addSubview(hideLegalView)
        hideLegalView.leftAnchor.constraint(equalTo: self.scrollView.leftAnchor).isActive = true
        hideLegalView.topAnchor.constraint(equalTo: self.scrollView.topAnchor, constant: 80).isActive = true
        hideLegalView.widthAnchor.constraint(equalToConstant: self.scrollView.frame.size.width).isActive = true
        hideLegalView.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        scrollView.scrollIndicatorInsets = UIEdgeInsetsMake(260, 0, 0, 0)
        
        self.scrollView.addSubview(pictureBorderView)
        pictureBorderView.leftAnchor.constraint(equalTo: self.scrollView.leftAnchor, constant: 18).isActive = true
        pictureBorderView.topAnchor.constraint(equalTo: self.scrollView.topAnchor, constant: 58).isActive = true
        pictureBorderView.widthAnchor.constraint(equalToConstant: 104).isActive = true
        pictureBorderView.heightAnchor.constraint(equalToConstant: 104).isActive = true
        pictureBorderView.layer.cornerRadius = 52
        
        self.scrollView.addSubview(profileImageView)
        profileImageView.leftAnchor.constraint(equalTo: self.scrollView.leftAnchor, constant: 20).isActive = true
        profileImageView.topAnchor.constraint(equalTo: self.scrollView.topAnchor, constant: 60).isActive = true
        profileImageView.widthAnchor.constraint(equalToConstant: 100).isActive = true
        profileImageView.heightAnchor.constraint(equalToConstant: 100).isActive = true
        
        
        self.scrollView.addSubview(displayLabel)
        displayLabel.leftAnchor.constraint(equalTo: self.scrollView.leftAnchor, constant: 20).isActive = true
        displayLabel.topAnchor.constraint(equalTo: self.scrollView.topAnchor, constant: 167).isActive = true
        displayLabel.widthAnchor.constraint(equalToConstant: self.scrollView.frame.size.width - 20).isActive = true
        displayLabel.heightAnchor.constraint(equalToConstant: 30).isActive = true
        
        self.scrollView.addSubview(usernameLabel)
        usernameLabel.leftAnchor.constraint(equalTo: self.scrollView.leftAnchor, constant: 20).isActive = true
        usernameLabel.topAnchor.constraint(equalTo: self.scrollView.topAnchor, constant: 192).isActive = true
        usernameLabel.widthAnchor.constraint(equalToConstant: self.scrollView.frame.size.width - 40).isActive = true
        usernameLabel.heightAnchor.constraint(equalToConstant: 20).isActive = true
        
        self.scrollView.addSubview(followersLabel)
        followersLabel.centerXAnchor.constraint(equalTo: self.scrollView.centerXAnchor).isActive = true
        followersLabel.topAnchor.constraint(equalTo: self.scrollView.topAnchor, constant: 105).isActive = true
        followersLabel.widthAnchor.constraint(equalToConstant: 60).isActive = true
        followersLabel.heightAnchor.constraint(equalToConstant: 20).isActive = true
        followersLabel.sizeToFit()
        
        self.scrollView.addSubview(numFollowersLabel)
        numFollowersLabel.centerXAnchor.constraint(equalTo: self.scrollView.centerXAnchor).isActive = true
        numFollowersLabel.topAnchor.constraint(equalTo: self.scrollView.topAnchor, constant: 90).isActive = true
        numFollowersLabel.widthAnchor.constraint(equalToConstant: 60).isActive = true
        numFollowersLabel.heightAnchor.constraint(equalToConstant: 20).isActive = true
        
        self.scrollView.addSubview(followersButton)
        followersButton.centerXAnchor.constraint(equalTo: self.scrollView.centerXAnchor).isActive = true
        followersButton.topAnchor.constraint(equalTo: self.scrollView.topAnchor, constant: 80).isActive = true
        followersButton.widthAnchor.constraint(equalToConstant: 60).isActive = true
        followersButton.heightAnchor.constraint(equalToConstant: 45).isActive = true
        followersButton.addTarget(self, action: #selector(UserViewController.numFollowersPressed(_:)), for: .touchUpInside)
        
        self.scrollView.addSubview(followingLabel)
        followingLabel.topAnchor.constraint(equalTo: self.scrollView.topAnchor, constant: 105).isActive = true
        followingLabel.widthAnchor.constraint(equalToConstant: 60).isActive = true
        followingLabel.sizeToFit()
        followingLabel.heightAnchor.constraint(equalToConstant: 20).isActive = true
        followingLabel.leftAnchor.constraint(equalTo: self.scrollView.centerXAnchor, constant: (scrollView.frame.width / 4) - 5).isActive = true
        
        self.scrollView.addSubview(numFollowingLabel)
        numFollowingLabel.topAnchor.constraint(equalTo: self.scrollView.topAnchor, constant: 90).isActive = true
        numFollowingLabel.widthAnchor.constraint(equalToConstant: 60).isActive = true
        numFollowingLabel.frame.size.width = 60
        numFollowingLabel.heightAnchor.constraint(equalToConstant: 20).isActive = true
        numFollowingLabel.leftAnchor.constraint(equalTo: self.scrollView.centerXAnchor, constant: (scrollView.frame.width / 4) - 5).isActive = true
        
        self.scrollView.addSubview(followingButton)
        followingButton.topAnchor.constraint(equalTo: self.scrollView.topAnchor, constant: 80).isActive = true
        followingButton.widthAnchor.constraint(equalToConstant: 60).isActive = true
        followingButton.heightAnchor.constraint(equalToConstant: 45).isActive = true
        followingButton.leftAnchor.constraint(equalTo: self.scrollView.centerXAnchor, constant: (scrollView.frame.width / 4) - 5).isActive = true
        followingButton.addTarget(self, action: #selector(UserViewController.numFollowingPressed(_:)), for: .touchUpInside)
        
        self.scrollView.addSubview(loadingButton)
        loadingButton.topAnchor.constraint(equalTo: self.scrollView.topAnchor, constant: 135).isActive = true
        loadingButton.widthAnchor.constraint(equalToConstant: (self.scrollView.frame.width / 4) + (followersLabel.frame.width / 2) + (followingLabel.frame.width)).isActive = true
        loadingButton.heightAnchor.constraint(equalToConstant: 27.5).isActive = true
        loadingButton.leftAnchor.constraint(equalTo: self.scrollView.centerXAnchor, constant: (followersLabel.frame.width / -2)).isActive = true
        
        self.scrollView.addSubview(activityIndicator)
        activityIndicator.centerXAnchor.constraint(equalTo: self.scrollView.centerXAnchor).isActive = true
        activityIndicator.topAnchor.constraint(equalTo: self.scrollView.topAnchor, constant: 270).isActive = true
        // add table view
        scrollView.addSubview(tableView)
        tableView.frame = CGRect(x: 0, y: 220 + segmentedControl.frame.height, width: self.scrollView.frame.width, height: scrollView.frame.height - segmentedControl.frame.height)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(MotiveTableViewCell.self, forCellReuseIdentifier: reuseIdentifier)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: refreshIdentifier)

        tableView.alwaysBounceVertical = false
        tableView.isScrollEnabled = false
        tableView.isHidden = true
        // add mapview (hidden by default)
        scrollView.addSubview(mapView)
        mapView.frame = CGRect(x: 0, y: 220 + segmentedControl.frame.height, width: self.scrollView.frame.width, height: scrollView.frame.height - segmentedControl.frame.height)
        mapView.isHidden = true
        // causes NSException same source error crash cus theres two maps on one VC
        //mapView.delegate = self
        
        // set initial contentSize of scrollView
        self.scrollView.contentSize.height = self.scrollView.frame.height + segmentedControl.frame.origin.y
        self.scrollView.delegate = self
        
    }

    // action of custom refresh control - refresh from firebase and check if friends - network call
    @objc func refreshUserDetails(_ sender: Any) {
        // if user data has been initialized
        let currentUserDelegate = self.tabBarController as? CurrentUserDelegate
        if let uid = uid {
            pointMapView.isUserInteractionEnabled = false
            profileImageView.isUserInteractionEnabled = false
            outOfGoingMotives = false
            outOfPostedMotives = false
            // if its current users profile then load current user
            // only store new current user in tab if its the current users profile view
            if uid == Auth.auth().currentUser?.uid {
                getCurrentUser(uid: uid) { (currentUser) in
                    if let currentUser = currentUser {
                        self.userHashTableDelegate?.storeUser(user: currentUser.user)
                        currentUserDelegate?.storeCurrentUser(currentUser: currentUser)
                        self.user = currentUser.user
                        self.loadUserDetails()
                        self.setupUserStatus()
                    } else {
                        // user snap didnt exist - pop
                        self.navigationController?.popViewController(animated: false)
                        AlertController.showAlert(self, title: "Error", message: "User Profile cannot be displayed.")
                    }
                }
            } else {
                // reload userandlists from database
                getUser(uid: uid) { (resultUser) in
                    if let user = resultUser {
                        self.userHashTableDelegate?.storeUser(user: user)
                        self.user = user
                        self.loadUserDetails()
                        self.setupUserStatus()
                    } else {
                        // user snap didnt exist - pop
                        self.navigationController?.popViewController(animated: false)
                        AlertController.showAlert(self, title: "Error", message: "User Profile cannot be displayed.")
                    }
                }
            }
        } else {
            // uid isnt there
            self.navigationController?.popViewController(animated: false)
            AlertController.showAlert(self, title: "Error", message: "User Profile cannot be displayed.")
        }

    }

    // function that sets all of the labels from the user object
    func loadUserDetails() {
        if let user = self.user {
            // set username and display labels
            self.displayLabel.text = user.display
            self.usernameLabel.text = "@" + user.username
            // load point banner
            self.updatePoint(latitude: user.pointLatitude, longitude: user.pointLongitude, zoomLevel: user.zoomLevel)
            // set followers label and following labels
            let followers = user.numFollowers
            numFollowersLabel.text = numToText(num: followers)
            if (followers == 1) {
                self.followersLabel.text = "follower"
            } else {
                self.followersLabel.text = "followers"
            }
            // set followers label and following labels
            let following = user.numFollowing
            numFollowingLabel.text = numToText(num: following)
            // download and set profile image
            if let url = URL(string: user.photoURL) {
                self.profileImageView.sd_setImage(with: url) { (image, error, cache, urls) in
                    if (error != nil) {
                        //Failure code here - defualt image
                        self.profileImageView.image = #imageLiteral(resourceName: "default user icon.png")
                        self.profileImageView.isUserInteractionEnabled = true
                        self.pointMapView.isUserInteractionEnabled = true
                    } else {
                        //Success code here
                        self.profileImageView.image = image
                        self.profileImageView.isUserInteractionEnabled = true
                        self.pointMapView.isUserInteractionEnabled = true
                    }
                }
            } else {
                self.pointMapView.isUserInteractionEnabled = true
            }
        }
    }
    // draw point and add annotation for banner
    func updatePoint (latitude: Double, longitude: Double, zoomLevel: Double) {
        let coordinate = CLLocationCoordinate2DMake(latitude, longitude)
        pointMapView.setCenter(coordinate, animated: false)
        pointMapView.setZoomLevel(zoomLevel, animated: false)
        pointFeature.coordinate = coordinate
        // replace current shape
        if let currentSource = self.pointMapView.style?.source(withIdentifier: "us-lighthouses") as? MGLShapeSource {
            currentSource.shape = self.pointFeature
        }
    }

    // function to determine what the users status is with the userviewcontroller user and display proper subviews
    func setupUserStatus() {
        // check if currently friends with current user
        if let currentUser = (self.tabBarController as? CustomTabBarController)?.currentUser {
            let currentUserUid = currentUser.user.uid
            activityIndicator.startAnimating()
            if currentUserUid == self.uid {
                setupProfile()
                setupSegmentedControl()
                return
            } else {
                if let user = self.user {
                    blockedReference.child(user.uid).child(currentUserUid).observeSingleEvent(of: .value) { (blockedSnapshot) in
                        if blockedSnapshot.exists() {
                            // if current user is blocked
                            self.setupBlocked()
                            self.removeSegmentedControl()
                            return
                        }
                        // if the current users following set contains the user and lists uid
                        if currentUser.followingSet.contains(user.uid) {
                            self.setupFollowing()
                            self.setupSegmentedControl()
                            return
                        }
                        // check if user is private
                        self.privateReference.child(user.uid).observeSingleEvent(of: .value) { (snapshot) in
                            // user is set to private
                            if snapshot.exists() {
                                // current User is already following
                                if user.requestSent {
                                    self.setupRequestSent()
                                    self.removeSegmentedControl()
                                    return
                                } else {
                                    self.setupFollowPrivate()
                                    self.removeSegmentedControl()
                                    return
                                }
                            } else {
                                // user is not private and you arent following them
                                self.setupFollow()
                                self.setupSegmentedControl()
                                return
                            }
                        }
                    }
                    
                }
            }
        }
    }
    
    // show the users own profile
    func setupProfile() {
        // add edit profile
        loadingButton.setTitle("Edit Profile", for: .normal)
        loadingButton.addTarget(self, action: #selector(editProfilePressed(_:)), for: .touchUpInside)
        
    }
    
    // function to setup appropriate subviews if user hasnt followed and user isnt private
    func setupFollow() {
        loadingButton.setTitleColor(UIColor.white, for: .normal)
        loadingButton.layer.borderWidth = 0
        loadingButton.backgroundColor = UIColor(red: 51/255, green: 204/255, blue: 51/255, alpha: 1.0)
        loadingButton.setTitle("Follow", for: .normal)
        
        loadingButton.removeTarget(self, action: #selector(followingPressed(_:)), for: .touchUpInside)
        loadingButton.removeTarget(self, action: #selector(editProfilePressed(_:)), for: .touchUpInside)
        loadingButton.removeTarget(self, action: #selector(followPrivatePressed(_:)), for: .touchUpInside)
        loadingButton.removeTarget(self, action: #selector(requestSentPressed(_:)), for: .touchUpInside)
        loadingButton.addTarget(self, action: #selector(followPressed(_:)), for: .touchUpInside)
    }
    
    // function to setup views if users account is private and current user is not following them
    func setupRequestSent() {
        loadingButton.setTitleColor(UIColor.black, for: .normal)
        loadingButton.layer.borderWidth = 1
        loadingButton.backgroundColor = UIColor.white
        loadingButton.setTitle("Request Sent", for: .normal)
        loadingButton.removeTarget(self, action: #selector(followingPressed(_:)), for: .touchUpInside)
        loadingButton.removeTarget(self, action: #selector(editProfilePressed(_:)), for: .touchUpInside)
        loadingButton.removeTarget(self, action: #selector(followPressed(_:)), for: .touchUpInside)
        loadingButton.removeTarget(self, action: #selector(followPrivatePressed(_:)), for: .touchUpInside)
        loadingButton.addTarget(self, action: #selector(requestSentPressed(_:)), for: .touchUpInside)
        setupLock()
        self.privacyLabel.text = "This Account is Private\nFollow this account to see their photos and videos."
    }
    
    // setup follow if the user is private
    func setupFollowPrivate() {
        loadingButton.setTitleColor(UIColor.white, for: .normal)
        loadingButton.layer.borderWidth = 0
        loadingButton.backgroundColor = UIColor(red: 51/255, green: 204/255, blue: 51/255, alpha: 1.0)
        loadingButton.setTitle("Follow", for: .normal)
        loadingButton.removeTarget(self, action: #selector(followingPressed(_:)), for: .touchUpInside)
        loadingButton.removeTarget(self, action: #selector(editProfilePressed(_:)), for: .touchUpInside)
        loadingButton.removeTarget(self, action: #selector(followPressed(_:)), for: .touchUpInside)
        loadingButton.removeTarget(self, action: #selector(requestSentPressed(_:)), for: .touchUpInside)
        loadingButton.addTarget(self, action: #selector(followPrivatePressed(_:)), for: .touchUpInside)
        setupLock()
        self.privacyLabel.text = "This Account is Private\nFollow this account to see their photos and videos."
    }
    
    
    // function to setup appriopriate subviews if user is already following
    func setupFollowing() {
        self.lockImageView.removeFromSuperview()
        self.privacyLabel.removeFromSuperview()
        // display already friend button
        loadingButton.setTitleColor(UIColor.black, for: .normal)
        loadingButton.layer.borderWidth = 1
        loadingButton.backgroundColor = UIColor.white
        loadingButton.setTitle("Following", for: .normal)
        
        loadingButton.removeTarget(self, action: #selector(editProfilePressed(_:)), for: .touchUpInside)
        loadingButton.removeTarget(self, action: #selector(followPressed(_:)), for: .touchUpInside)
        loadingButton.removeTarget(self, action: #selector(followPrivatePressed(_:)), for: .touchUpInside)
        loadingButton.removeTarget(self, action: #selector(requestSentPressed(_:)), for: .touchUpInside)
        loadingButton.addTarget(self, action: #selector(followingPressed(_:)), for: .touchUpInside)
    
    }


    func setupBlocked() {
        self.loadingButton.removeFromSuperview()
        // dont display thier motives - since user blocked you - privacy warning
        setupLock()
        self.privacyLabel.text = "This user has blocked you."

    }
    
    func setupLock() {
        self.scrollView.addSubview(self.lockImageView)
        self.lockImageView.centerXAnchor.constraint(equalTo: self.scrollView.centerXAnchor).isActive = true
        self.lockImageView.topAnchor.constraint(equalTo: self.scrollView.topAnchor, constant: 265).isActive = true
        self.lockImageView.widthAnchor.constraint(equalToConstant: 32).isActive = true
        self.lockImageView.heightAnchor.constraint(equalToConstant: 32).isActive = true
        
        self.scrollView.addSubview(self.privacyLabel)
        self.privacyLabel.centerXAnchor.constraint(equalTo: self.scrollView.centerXAnchor).isActive = true
        self.privacyLabel.topAnchor.constraint(equalTo: self.scrollView.topAnchor, constant: 300).isActive = true
        self.privacyLabel.widthAnchor.constraint(equalToConstant: self.scrollView.frame.width - 20).isActive = true
        self.privacyLabel.heightAnchor.constraint(equalToConstant: 30).isActive = true
        self.activityIndicator.stopAnimating()
    }
    
    func setupSegmentedControl() {
        // show current and past motives??
        self.scrollView.addSubview(segmentedControl)
        segmentedControl.frame = CGRect(x: 0, y: 220, width: self.scrollView.frame.width, height: 40)
        self.segmentedControl.addSubview(greyBar)
        greyBar.frame = CGRect(x: 0, y: segmentedControl.frame.height - 1, width: segmentedControl.frame.width, height: 1)
        self.segmentedControl.addSubview(buttonBar)
        segmentedControl.addTarget(self, action: #selector(segmentedControlValueChanged(_:)), for: UIControlEvents.valueChanged)
        if segmentedControl.selectedSegmentIndex == 0 {
            buttonBar.frame = CGRect(x: 0, y: segmentedControl.frame.height - 5, width: segmentedControl.frame.width / CGFloat(segmentedControl.numberOfSegments), height: 5)
        } else if segmentedControl.selectedSegmentIndex == 1 {
            buttonBar.frame = CGRect(x: segmentedControl.frame.width / CGFloat(segmentedControl.numberOfSegments), y: segmentedControl.frame.height - 5, width: segmentedControl.frame.width / CGFloat(segmentedControl.numberOfSegments), height: 5)
        } else if segmentedControl.selectedSegmentIndex == 2 {
            buttonBar.frame = CGRect(x: segmentedControl.frame.width - (segmentedControl.frame.width / (CGFloat(segmentedControl.numberOfSegments))), y: segmentedControl.frame.height - 5, width: segmentedControl.frame.width / CGFloat(segmentedControl.numberOfSegments), height: 5)
        } else {
            buttonBar.frame = CGRect(x: 0, y: segmentedControl.frame.height - 5, width: segmentedControl.frame.width / CGFloat(segmentedControl.numberOfSegments), height: 5)
        }
        self.activityIndicator.stopAnimating()
        loadMotives()

    }
    
    func removeSegmentedControl() {
        greyBar.removeFromSuperview()
        buttonBar.removeFromSuperview()
        segmentedControl.removeFromSuperview()
        self.run(after: 0.5, closure: {
            self.customRefreshControl?.endRefreshing()
        })
    }

    @objc func editProfilePressed(_ sender: UIButton!) {
        if let user = self.user {
            let editProfileViewController = storyboard?.instantiateViewController(withIdentifier: "editProfileViewController") as! EditProfileViewController
            editProfileViewController.user = user
            editProfileViewController.editProfileDelegate = self
            self.navigationController?.pushViewController(editProfileViewController, animated: true)
        }
    }
    
    // when user saves profile edits
    func profileChanged() {
        refreshUserDetails(self)
    }

    
    // follow the user in view
    @objc func followPressed (_ sender: UIButton!) {
        guard let user = self.user else { return }
        guard let currentUserUid = Auth.auth().currentUser?.uid else { return }
        let timestamp = Int64(NSDate().timeIntervalSince1970 * -1000)
        let uid = user.uid
        // add to view users followers
        self.followersReference.child(uid).child(currentUserUid).setValue(timestamp)
        // add to current users following
        self.followingReference.child(currentUserUid).child(uid).setValue(true)
        // update objects in tab bar
        if let currentUser = (self.tabBarController as? CustomTabBarController)?.currentUser {
            // nfers call
            self.functions.httpsCallable("countFollowers").call(["id": uid, "name": currentUser.user.username]) { (result, error) in
                if let error = error as NSError? {
                    if error.domain == FunctionsErrorDomain {
                        let message = error.localizedDescription
                        print (message)
                    }
                } else if let numFollowers = (result?.data as? [String: Any])?["num"] as? Int {
                    print (numFollowers)
                    self.usersReference.child(uid).child("nFers").setValue(numFollowers)
                }
            }
            // update current user object
            (self.tabBarController as? CustomTabBarController)?.currentUser?.followingSet.insert(uid)
            var updatedUser = currentUser.user
            updatedUser.numFollowing += 1
            currentUser.user = updatedUser
            (self.tabBarController as? CustomTabBarController)?.currentUser = currentUser
            self.usersReference.child(currentUserUid).child("nFing").setValue(currentUser.followingSet.count)
        }
        // change num followers button
        let updatedUser = User(uid: user.uid, username: user.username, display: user.display, photoURL: user.photoURL, numFollowers: user.numFollowers + 1, numFollowing: user.numFollowing, pointLatitude: user.pointLatitude, pointLongitude: user.pointLongitude, zoomLevel: user.zoomLevel)
        self.numFollowersLabel.text = String(updatedUser.numFollowers)
        self.user = updatedUser
        self.userHashTableDelegate?.storeUser(user: updatedUser)
        // change follow button to following button
        self.loadingButton.removeTarget(self, action: #selector(self.followPressed(_:)), for: .touchUpInside)
        self.loadingButton.addTarget(self, action: #selector(self.followingPressed(_:)), for: .touchUpInside)
        self.setupFollowing()
    }
    
    // unfollow the user in view
    @objc func followingPressed (_ sender: UIButton!) {
        // Create the alert controller.
        guard let user = self.user else { return }
        let alert = UIAlertController(title: "Confirm", message: "Are you sure you want to unfollow @" + user.username, preferredStyle: .alert)
        
        // add a cancel button
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil))
        
        // remove user from both people friends list
        alert.addAction(UIAlertAction(title: "Unfollow", style: .default, handler: {(action:UIAlertAction!) in
            // update tab bar objects
            guard let user = self.user else { return }
            if let customTabBarController = self.tabBarController as? CustomTabBarController {
                if let currentUser = customTabBarController.currentUser {
                    let currentUserUid = currentUser.user.uid
                    // remove from view users followers
                    self.followersReference.child(user.uid).child(currentUserUid).removeValue()
                    // remove from current users following
                    self.followingReference.child(currentUserUid).child(user.uid).removeValue()
                    // functions call to count nFers
                    self.functions.httpsCallable("countFollowers").call(["id": user.uid]) { (result, error) in
                        if let error = error as NSError? {
                            if error.domain == FunctionsErrorDomain {
                                let message = error.localizedDescription
                                print (message)
                            }
                        } else if let numFollowers = (result?.data as? [String: Any])?["num"] as? Int {
                            print (numFollowers)
                            self.usersReference.child(user.uid).child("nFers").setValue(numFollowers)
                        }
                    }
                    // update current user object
                    currentUser.followingSet.remove(user.uid)
                    var updatedCurrentUserUser = currentUser.user
                    updatedCurrentUserUser.numFollowing -= 1
                    currentUser.user = updatedCurrentUserUser
                    customTabBarController.currentUser = currentUser
                    // set num following
                    self.usersReference.child(currentUserUid).child("nFing").setValue(currentUser.followingSet.count)
                    // change friend button to add button
                    self.loadingButton.removeTarget(self, action: #selector(UserViewController.followingPressed(_:)), for: .touchUpInside)
                    self.setupFollow()
                    // update followers label
                    var updatedUser = user
                    updatedUser.numFollowers -= 1
                    self.numFollowersLabel.text = String(updatedUser.numFollowers)
                    self.user = updatedUser
                    self.userHashTableDelegate?.storeUser(user: updatedUser)
                }
                
            }
            
        }))
        
        // Present the alert.
        self.present(alert, animated: true, completion: nil)
    }

    // send request to other user
    @objc func followPrivatePressed(_ sender: UIButton!) {
        guard let user = self.user else { return }
        guard let currentUserUid = Auth.auth().currentUser?.uid else { return }
        let userUid = user.uid
        let timestamp = Int64(NSDate().timeIntervalSince1970 * -1000)
        self.requestsReference.child(userUid).child(currentUserUid).setValue(timestamp)
        // update user objects
        var updatedUser = user
        updatedUser.requestSent = true
        userHashTableDelegate?.storeUser(user: updatedUser)
        self.user = updatedUser
        // change button targets
        loadingButton.removeTarget(self, action: #selector(self.followPrivatePressed(_:)), for: .touchUpInside)
        loadingButton.addTarget(self, action: #selector(self.requestSentPressed(_:)), for: .touchUpInside)
        // change follow button to following button
        setupRequestSent()
    }
    
    // undo the follow request
    @objc func requestSentPressed(_ sender: UIButton!) {
        guard let user = self.user else { return }
        guard let currentUserUid = Auth.auth().currentUser?.uid else { return }
        let userUid = user.uid
        self.requestsReference.child(userUid).child(currentUserUid).removeValue()
        // update user objects
        var updatedUser = user
        updatedUser.requestSent = false
        userHashTableDelegate?.storeUser(user: updatedUser)
        self.user = updatedUser
        // change request sent button to follow button
        loadingButton.removeTarget(self, action: #selector(requestSentPressed(_:)), for: .touchUpInside)
        setupFollowPrivate()
    }
    
    
    func addTapGestureRecognizers() {
        let headerGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(headerLabelTapped(_:)))
        headerLabel.isUserInteractionEnabled = true
        headerLabel.addGestureRecognizer(headerGestureRecognizer)
        // turn profile image into a button
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(profileImageTapped(_:)))
        profileImageView.isUserInteractionEnabled = false
        profileImageView.addGestureRecognizer(tapGestureRecognizer)
        
        // turn map into a button
        // turn profile image into a button
        let mapTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(mapTapped(_:)))
        pointMapView.isUserInteractionEnabled = false
        pointMapView.addGestureRecognizer(mapTapGestureRecognizer)
    }
    
    
    // scrollView to the top of the scrollView
    @objc func headerLabelTapped(_ sender: Any) {
        self.scrollView.setContentOffset(.zero, animated: true)
        self.tableView.setContentOffset(.zero, animated: false)
        self.storedContentOffsets = [220, 220, 220]
    }
    
    
    @objc func profileImageTapped(_ sender: Any) {
        // keywindow snapshot to get tab bar in view
        if let snapshotView = UIApplication.shared.keyWindow?.snapshotView(afterScreenUpdates: true) {
            let profileImageViewController = storyboard?.instantiateViewController(withIdentifier: "profileImageViewController") as! ProfileImageViewController
            profileImageViewController.backgroundView = snapshotView
            profileImageViewController.profileImageView.image = self.profileImageView.image
            profileImageViewController.hidesBottomBarWhenPushed = true
            self.navigationController?.pushViewController(profileImageViewController, animated: true)
        }

    }
    
    @objc func mapTapped(_ sender: Any) {
        if let snapshotView = UIApplication.shared.keyWindow?.snapshotView(afterScreenUpdates: true) {
            if let user = self.user {
                let profilePointViewController = storyboard?.instantiateViewController(withIdentifier: "profilePointViewController") as! ProfilePointViewController
                profilePointViewController.backgroundView = snapshotView
                profilePointViewController.pointLatitude = user.pointLatitude
                profilePointViewController.pointLongitude = user.pointLongitude
                profilePointViewController.zoomLevel = user.zoomLevel
                profilePointViewController.display = user.display
                profilePointViewController.hidesBottomBarWhenPushed = true
                self.navigationController?.pushViewController(profilePointViewController, animated: true)
            }
        }
    }
    
    @objc func numFollowersPressed (_ sender: UIButton!) {
        if let user = self.user {
            if user.numFollowers == 0 { return }
            if let snapshotView = self.view.snapshotView(afterScreenUpdates: true) {
                for subview in pinchView.subviews {
                    if subview is UIVisualEffectView { subview.isHidden = true }
                }
                if let pinchSnapshotView = self.pinchView.snapshotView(afterScreenUpdates: true) {
                    let friendViewController = storyboard?.instantiateViewController(withIdentifier: "friendViewController") as! FriendViewController
                    friendViewController.backgroundView = snapshotView
                    for subview in pinchView.subviews {
                        if subview is UIVisualEffectView { subview.isHidden = false }
                    }
                    friendViewController.pinchView = pinchSnapshotView
                    friendViewController.pinchDelegate = self.pinchDelegate
                    friendViewController.type = .followers
                    friendViewController.id = user.uid
                    friendViewController.previousViewId = user.uid
                    self.navigationController?.pushViewController(friendViewController, animated: true)
                }
            }
        }
    }
    // instantiate a friendViewController
    @objc func numFollowingPressed (_ sender: UIButton!) {
        if let user = self.user {
            if user.numFollowing == 0 { return }
            if let snapshotView = self.view.snapshotView(afterScreenUpdates: true) {
                for subview in pinchView.subviews {
                    if subview is UIVisualEffectView { subview.isHidden = true }
                }
                if let pinchSnapshotView = self.pinchView.snapshotView(afterScreenUpdates: true) {
                    let friendViewController = storyboard?.instantiateViewController(withIdentifier: "friendViewController") as! FriendViewController
                    friendViewController.backgroundView = snapshotView
                    for subview in pinchView.subviews {
                        if subview is UIVisualEffectView { subview.isHidden = false }
                    }
                    friendViewController.pinchView = pinchSnapshotView
                    friendViewController.pinchDelegate = self.pinchDelegate
                    friendViewController.type = .following
                    friendViewController.id = user.uid
                    friendViewController.previousViewId = user.uid
                    self.navigationController?.pushViewController(friendViewController, animated: true)
                }
            }
        }
    }
    
    // function to refresh the table and add motive annotations to map
    func loadMotives() {
        // get GOING motives
        _ = self.getMotives(type: 1) { (_ goingMotives: [Motive])  in
            if goingMotives.count == 0 {
                self.outOfGoingMotives = true
            }
            self.goingMotives = goingMotives
            self.goingMotives.sort(by: { ($0.time < $1.time)})
            // get posted motives
            _ = self.getMotives(type: 0) { (_ postedMotives: [Motive])  in
                if postedMotives.count == 0 {
                    self.outOfPostedMotives = true
                }
                self.postedMotives = postedMotives
                self.postedMotives.sort(by: { ($0.time < $1.time)})
                // remove annotations from map
                // add annotations user created on map
                for (_, motive) in postedMotives.enumerated() {
                    
                }
                // add annotations user is going to on map
                for (_, motive) in goingMotives.enumerated() {
                    
                }
                // display the table or map view depending on segmentcontrol
                if self.segmentedControl.selectedSegmentIndex < 2 {
                    self.createTable(appending: false)
                } else if self.segmentedControl.selectedSegmentIndex == 2 {
                    self.createMap()
                }
                self.run(after: 0.5, closure: {
                    self.customRefreshControl?.endRefreshing()
                })
                
            }
            
        }
        
    }
    
    // function to initially get motives from database the user has posted and is going to.
    // param - type: represents which reference to pick from ----> POSTED = 0, GOING = 1
    func getMotives(type: Int, completionHandler:@escaping (_ result: [Motive]) -> Void) {
        guard let currentUser = (self.tabBarController as? CustomTabBarController)?.currentUser else { return }
        var motives = [Motive]()
        var snapshotArray = [DataSnapshot]()
        if let uid = self.uid {
            var reference = usersPostReference
            if type == 1 {
                reference = usersGoingReference
            }
            // query current motives for ones the user has posted
            reference.child(uid).queryOrderedByValue().queryLimited(toFirst: numMotivesToLoad).observeSingleEvent(of: .value) { (snapshot) in
                if snapshot.exists() {
                    // get all ids that the user is going
                    for item in snapshot.children {
                        let snap = item as! DataSnapshot
                        snapshotArray.append(snap)
                    }
                    snapshotArray.sort(by: {( ($0.value as! Int) < ($1.value as! Int) )})
                    if type == 0 {
                        self.lastPostedTime = snapshotArray.last?.value as! Int
                        print ("last posted time " + String(self.lastPostedTime))
                    } else if type == 1 {
                        self.lastGoingTime = snapshotArray.last?.value as! Int
                        print ("last going time " + String(self.lastGoingTime))
                    }
                    let myGroup = DispatchGroup()
                    // number of motives loaded that doesnt exist in motive or archive directory
                    var numRemoved: UInt = 0
                    // load motives from ids
                    for (_, goingSnapshot) in snapshotArray.enumerated() {
                        myGroup.enter()
                        // look in motive reference
                        self.motivesReference.child(goingSnapshot.key).observeSingleEvent(of: .value, with: { (snapshot) in
                            if snapshot.exists() {
                                let motive = Motive(snapshot: snapshot)
                                motives.append(motive)
                                // determine if the user is going to the motive after you load it
                                self.usersGoingReference.child(currentUser.user.uid).child(goingSnapshot.key).observeSingleEvent(of: .value, with: { (snapshot) in
                                    if snapshot.exists() {
                                        // add to the user going set
                                        (self.tabBarController as? CustomTabBarController)?.userMotiveGoingSet.insert(goingSnapshot.key)
                                    }
                                    myGroup.leave()
                                })
                            } else {
                                // remove from usersGoing or usersPosted if motive doesnt exist in archive or motives
                                reference.child(uid).child(goingSnapshot.key).removeValue()
                                numRemoved += 1
                                myGroup.leave()
                            }
                        })
                    }
                    // after all motives user has went to or is going have been added
                    myGroup.notify(queue: .main) {
                        if motives.count == 0 {
                            if type == 0 {
                                self.outOfPostedMotives = true
                            } else if type == 1 {
                                self.outOfGoingMotives = true
                            }
                        }

                        completionHandler(motives)
                        return
                    }
                } else {
                    completionHandler(motives)
                    return
                }
            }
        } else {
            completionHandler(motives)
            return
        }
    }
    
    // function called when reaching the bottom of the table
    func getMoreMotives(type: Int) {
        guard let currentUser = (self.tabBarController as? CustomTabBarController)?.currentUser else { return }
        var motives = [Motive]()
        var snapshotArray = [DataSnapshot]()
        if let uid = self.uid {
            var reference = usersPostReference
            var time: Int = 0
            if type == 0 {
                loadingMorePostedMotives = true
                time = lastPostedTime
            } else if type == 1 {
                reference = usersGoingReference
                loadingMoreGoingMotives = true
                time = lastGoingTime
            }
            print ("GetMoreType: " + String(type) + " Query time: " + String(time))
            // query current motives for ones the user has posted
            reference.child(uid).queryOrderedByValue().queryStarting(atValue: time + 1).queryLimited(toFirst: numMotivesToLoad).observeSingleEvent(of: .value) { (snapshot) in
                if snapshot.exists() {
                    // get all ids that the user is going and sort by time
                    for item in snapshot.children {
                        let snap = item as! DataSnapshot
                        snapshotArray.append(snap)
                    }
                    snapshotArray.sort(by: {( ($0.value as! Int) < ($1.value as! Int) )})
                    // get the oldest (least negative) value to start the next potential query at
                    if type == 0 {
                        self.lastPostedTime = snapshotArray.last?.value as! Int
                    } else if type == 1 {
                        self.lastGoingTime = snapshotArray.last?.value as! Int
                    }
                    let myGroup = DispatchGroup()
                    var numRemoved: UInt = 0
                    // load motives from ids
                    for (i, goingSnapshot) in snapshotArray.enumerated() {
                        print ("index: " + String(i) + " value: " + String(goingSnapshot.value.debugDescription))
                        myGroup.enter()
                        // look for id in motive reference
                        self.motivesReference.child(goingSnapshot.key).observeSingleEvent(of: .value, with: { (snapshot) in
                            if snapshot.exists() {
                                let motive = Motive(snapshot: snapshot)
                                motives.append(motive)
                                // determine if the user is going to the motive after you load it
                                self.usersGoingReference.child(currentUser.user.uid).child(goingSnapshot.key).observeSingleEvent(of: .value, with: { (snapshot) in
                                    if snapshot.exists() {
                                        // add to the user going set
                                        (self.tabBarController as? CustomTabBarController)?.userMotiveGoingSet.insert(goingSnapshot.key)
                                    }
                                    myGroup.leave()
                                })
                            } else {
                                // remove from usersGoing or usersPosted if motive doesnt exist in archive or motives
                                reference.child(uid).child(goingSnapshot.key).removeValue()
                                numRemoved += 1
                                myGroup.leave()
                            }
                        })
                    }
                    // after all motives user has went to or is going have been added
                    myGroup.notify(queue: .main) {
                        if type == 0 {
                            self.postedMotives = self.postedMotives + motives
                            if motives.count == 0  {
                                self.outOfPostedMotives = true
                            }
                        } else if type == 1 {
                            self.goingMotives = self.goingMotives + motives
                            if motives.count == 0 {
                                self.outOfGoingMotives = true
                            }
                        }
                        self.createTable(appending: true)
                        return
                    }
                } else {
                    if type == 0 {
                        self.outOfPostedMotives = true
                        self.loadingMorePostedMotives = false
                    } else if type == 1 {
                        self.outOfGoingMotives = true
                        self.loadingMoreGoingMotives = false
                    }
                    self.tableView.reloadData()
                    return
                }
            }
        } else {
            self.loadingMorePostedMotives = false
            self.loadingMoreGoingMotives = false
            return
        }
        
    }
    // get user data to corresponding motives, set motiveandusers and update table data
    func createTable(appending: Bool) {
        let myGroup = DispatchGroup()
        var motiveAndUsers: [MotiveAndUser] = []
        var motives = [Motive]()
        // load users for first numMotivesToLoad
        if (segmentedControl.selectedSegmentIndex == 0) {
            motives = self.postedMotives
        } else if (segmentedControl.selectedSegmentIndex == 1) {
            motives = self.goingMotives
        }
        for (i, motive) in motives.enumerated() {
            myGroup.enter()
            // get creator data
            // check to see if its in hashtable
            if let user = self.userHashTableDelegate?.retrieveUser(uid: motive.creator) {
                let motiveAndUser = MotiveAndUser(motive: motive, user: user)
                motiveAndUser.index = i
                motiveAndUsers.append(motiveAndUser)
                myGroup.leave()
            } else {
                // if not in hashtable then load from firebase and store in hashtable
                getUser(uid: motive.creator) { (result) in
                    if let user = result {
                        self.userHashTableDelegate?.storeUser(user: user)
                        let motiveAndUser = MotiveAndUser(motive: motive, user: user)
                        motiveAndUser.index = i
                        motiveAndUsers.append(motiveAndUser)
                    }
                    myGroup.leave()
                }

            }
        }
        // once all users are finished loading
        myGroup.notify(queue: .main) {
            // sort by index to avoid async errors
            motiveAndUsers.sort(by: { ($0.index < $1.index)})
            self.motiveAndUsers = motiveAndUsers
            self.mapView.isHidden = true
            self.tableView.isHidden = false
            self.stopRefreshing()
            self.tableView.reloadData()
            if appending {
                self.adjustContentSize(setContentOffset: false)
            } else {
                self.adjustContentSize(setContentOffset: true)
            }
            self.loadingMorePostedMotives = false
            self.loadingMoreGoingMotives = false
        }
        
    }
    
    // make map visable and adjust content size of scrollView
    func createMap() {
        if mapFirstLoad {
            //zoomMapToFitAnnotations()
            mapFirstLoad = false
        }
        tableView.isHidden = true
        mapView.isHidden = false
        stopRefreshing()
        adjustContentSize(setContentOffset: true)
    }
    
    // stop refreshing the customRefreshControl after 1 second
    func stopRefreshing() {
        activityIndicator.stopAnimating()
        segmentedControl.isHidden = false
        if customRefreshControl?.isRefreshing == true {
            run(after: 1.0) {
                self.customRefreshControl?.endRefreshing()

            }
        }
    }
    
    // the profile segment control was changed
    @objc func segmentedControlValueChanged(_ sender: UISegmentedControl) {
        print ("segmented control on: " + String(segmentedControl.selectedSegmentIndex))
        // animate buttonBar to move to selected index
        UIView.animate(withDuration: 0.3) {
            self.buttonBar.frame.origin.x = (self.segmentedControl.frame.width / CGFloat(self.segmentedControl.numberOfSegments)) * CGFloat(self.segmentedControl.selectedSegmentIndex)
        }
        // stop moving scrollView
        scrollView.setContentOffset(scrollView.contentOffset, animated: false)
        // store the content offset if the previous index was posts or going
        if self.previousSelectedSegmentIndex < 2 {
            storedContentOffsets[self.previousSelectedSegmentIndex] = max(scrollView.contentOffset.y, 220)
        }
        // posts or going was selected
        if segmentedControl.selectedSegmentIndex < 2 {
            createTable(appending: false)
            // map was selected
        } else if segmentedControl.selectedSegmentIndex == 2 {
            createMap()
        }
        // update previous selected index
        self.previousSelectedSegmentIndex = segmentedControl.selectedSegmentIndex
    }
    
    // adjust the content size of the scrollView view according to the length of the table view
    func adjustContentSize(setContentOffset: Bool) {
        // adjust contentSize and contentOffset of scrollView for table view
        if segmentedControl.selectedSegmentIndex < 2 {
            tableView.layoutIfNeeded()
            // calculate the height of table
            var height = CGFloat(0)
            for index in 0..<tableView.numberOfRows(inSection: 0) {
                let i = IndexPath(row: index, section: 0)
                height += tableView.rectForRow(at: i).height
            }
            tableView.contentSize.height = height
            tableView.frame = CGRect(x: 0, y: 220 + segmentedControl.frame.height, width: scrollView.frame.width, height: tableView.contentSize.height)
            scrollView.contentSize.height = max(220 + tableView.contentSize.height + segmentedControl.frame.height, view.frame.height - headerView.frame.height)
            print (scrollView.contentSize.height)
            // store the offset if the content is below the segmented control
            if scrollView.contentOffset.y >= 220 && setContentOffset {
                scrollView.contentOffset.y = storedContentOffsets[segmentedControl.selectedSegmentIndex]
                print (storedContentOffsets.debugDescription)
            }
            // adjust contentSize and contentOffset of scrollView for map view
        } else if segmentedControl.selectedSegmentIndex == 2 {
            scrollView.contentSize.height = view.frame.height - headerView.frame.height + 220
            scrollView.setContentOffset(CGPoint(x: scrollView.contentOffset.x, y: 220), animated: true)
        }
    }



}

// table and scrollView view delegates
extension UserViewController: UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate, CalloutViewDelegate, UIActionSheetDelegate {
    
    func morePressed(motive: Motive) {
        //Create the AlertController and add Its action like button in Actionsheet
        let actionSheetControllerIOS8: UIAlertController = UIAlertController(title: "Other Options", message: nil, preferredStyle: .actionSheet)
        
        if let popoverController = actionSheetControllerIOS8.popoverPresentationController {
            popoverController.sourceView = self.view //to set the source of your alert
            popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0) // you can set this as per your requirement.
            popoverController.permittedArrowDirections = [] //to hide the arrow of any particular direction
        }
        
        let cancelActionButton = UIAlertAction(title: "Cancel", style: .cancel) { _ in
            print("Cancel")
        }
        actionSheetControllerIOS8.addAction(cancelActionButton)
        
        let blockActionButton = UIAlertAction(title: "Block User", style: .default) { _ in
            if let uid = Auth.auth().currentUser?.uid {
                if (motive.creator != uid) {
                    if let currentUser = (self.tabBarController as? CustomTabBarController)?.currentUser {
                        let kBlockedListPath = "blocked/" + uid
                        let blockedReference = Database.database().reference(withPath: kBlockedListPath)
                        let timestamp = Int64(NSDate().timeIntervalSince1970 * -1000)
                        blockedReference.child(motive.creator).setValue(timestamp)
                        currentUser.blockedSet.insert(motive.creator)
                        (self.tabBarController as? CustomTabBarController)?.currentUser = currentUser
                        AlertController.showAlert(self, title: "Blocked", message: "This user is now blocked.")
                    }
                }
            }
        }
        
        actionSheetControllerIOS8.addAction(blockActionButton)
        
        let reportActionButton = UIAlertAction(title: "Report Post", style: .default) { _ in
            AlertController.showAlert(self, title: "Reported", message: "This post has been reported and will reviewed by a moderator.")
        }
        actionSheetControllerIOS8.addAction(reportActionButton)
        self.present(actionSheetControllerIOS8, animated: true, completion: nil)
    }
    
    
    // manage the segmented control sticking to the top of the scrollView view
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // scrollView view scrolls past seg control
        if scrollView.contentOffset.y >= 220 {
            // add segmented control to view - so it sticks to top
            if self.scrollView.subviews.contains(segmentedControl) {
                self.segmentedControl.removeFromSuperview()
                self.transitionView.addSubview(segmentedControl)
                segmentedControl.frame.origin.y = headerView.frame.height
            }
        } else {
            if self.transitionView.subviews.contains(segmentedControl) {
                // add segmneted control back to scrollView view
                self.segmentedControl.removeFromSuperview()
                self.scrollView.addSubview(segmentedControl)
                segmentedControl.frame.origin.y = 220
                self.storedContentOffsets = [220, 220, 220]
            }
        }
        // toggle verticle indictor
        if scrollView.contentOffset.y <= 0 {
            scrollView.showsVerticalScrollIndicator = false
        } else {
            scrollView.showsVerticalScrollIndicator = true
        }
        
        if scrollView.contentOffset.y + 300 >= scrollView.contentSize.height - scrollView.frame.height {
            if ((segmentedControl.selectedSegmentIndex == 0 && outOfPostedMotives) || (segmentedControl.selectedSegmentIndex == 1 && outOfGoingMotives)) {
                //activityIndicator.stopAnimating()
            } else if (!loadingMorePostedMotives && !loadingMoreGoingMotives) {
                getMoreMotives(type: segmentedControl.selectedSegmentIndex)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print ("count: " + String(self.motiveAndUsers.count))
        return self.motiveAndUsers.count + 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == motiveAndUsers.count {
            let cell = tableView.dequeueReusableCell(withIdentifier: refreshIdentifier)
            cell?.separatorInset = UIEdgeInsetsMake(0, tableView.frame.width / 2, 0, tableView.frame.width / 2)
            // if there are NO motives in going or posts
            if (self.motiveAndUsers.count == 0 && segmentedControl.selectedSegmentIndex == 0 && outOfPostedMotives) || (self.motiveAndUsers.count == 0 && segmentedControl.selectedSegmentIndex == 1 && outOfGoingMotives)  {
                let label = UILabel(frame: CGRect(x: 0, y: 0, width: (cell?.frame.width)!, height: 30))
                cell?.addSubview(label)
                label.translatesAutoresizingMaskIntoConstraints = false
                label.centerXAnchor.constraint(equalTo: (cell?.centerXAnchor)!).isActive = true
                label.centerYAnchor.constraint(equalTo: (cell?.centerYAnchor)!).isActive = true
                label.font = UIFont.systemFont(ofSize: 16)
                label.text = "Nothing to see here chief."
                return cell!
            }
            if (segmentedControl.selectedSegmentIndex == 0 && outOfPostedMotives) || (segmentedControl.selectedSegmentIndex == 1 && outOfGoingMotives) {
                cell?.frame = CGRect.zero
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
            // create a MotiveTableViewCell profile feed post
            let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier) as! MotiveTableViewCell
            // since awake from nib isnt called
            cell.frame.size.width = tableView.frame.width
            cell.selectionStyle = .none
            cell.layoutMargins = UIEdgeInsets.zero
            cell.awakeFromNib()
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
    }
    
    // display motive on mapView
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // if its refesh cell then cancel
        if (indexPath.row >= self.motiveAndUsers.count) {
            tableView.deselectRow(at: indexPath, animated: false)
            return
        }
        // send info to map view controller and tab controller delegate
        //let motive = motiveAndUsers[indexPath.row].motive
        tableSelected = true
        //selectMotiveOnMap(id: motive.id)
    }
    // stub
    func calloutPressed() {
        return
    }
    
    func profileImagePressed(user: User) {
        if user.uid == self.user?.uid { return }
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
    }
    
    func unGoPressed(motive: Motive) {
        (tabBarController as? CustomTabBarController)?.userMotiveGoingSet.remove(motive.id)
        motiveHashTableDelegate?.storeMotive(motive: motive)
    }

    // setting the height for all table rows
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        // nothing to see here chief
        if self.motiveAndUsers.count == 0 && segmentedControl.selectedSegmentIndex == 0 && outOfPostedMotives {
            return 100
        }
        if self.motiveAndUsers.count == 0 && segmentedControl.selectedSegmentIndex == 1 && outOfGoingMotives {
            return 100
        }
        // out of posted motives
        if indexPath.row >= self.motiveAndUsers.count && segmentedControl.selectedSegmentIndex == 0 && outOfPostedMotives {
            return 0
        }
        // out of going motives
        if indexPath.row >= self.motiveAndUsers.count && segmentedControl.selectedSegmentIndex == 1 && outOfGoingMotives {
            return 0
        }
        // refresh cell
        if (indexPath.row >= self.motiveAndUsers.count) {
            return 50
        }
        return UITableViewAutomaticDimension
    }
    
    // setting the estimated height for all table rows
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        // nothing to see here chief
        if self.motiveAndUsers.count == 0 && segmentedControl.selectedSegmentIndex == 0 && outOfPostedMotives {
            return 100
        }
        if self.motiveAndUsers.count == 0 && segmentedControl.selectedSegmentIndex == 1 && outOfGoingMotives {
            return 100
        }
        // out of posted motives
        if indexPath.row >= self.motiveAndUsers.count && segmentedControl.selectedSegmentIndex == 0 && outOfPostedMotives {
            return 0
        }
        // out of going motives
        if indexPath.row >= self.motiveAndUsers.count && segmentedControl.selectedSegmentIndex == 1 && outOfGoingMotives {
            return 0
        }
        // refresh cell
        if (indexPath.row >= self.motiveAndUsers.count) {
            return 50
        }
        return UITableViewAutomaticDimension
    }
    
    // slide to delete your post function
    func tableView(_ tableView: UITableView, editActionsForRowAt: IndexPath) -> [UITableViewRowAction]? {
        if editActionsForRowAt.row == motiveAndUsers.count {
            return nil
        }
        let motiveAndUser = motiveAndUsers[editActionsForRowAt.row]
        guard let currentUserUid = Auth.auth().currentUser?.uid  else { return nil }
        if currentUserUid == motiveAndUser.motive.creator {
            let delete = UITableViewRowAction(style: .destructive, title: "Delete Post") { action, index in
                let motiveId = motiveAndUser.motive.id
                self.usersPostReference.child(currentUserUid).child(motiveId).removeValue() { error, ref in
                    if error == nil {
                        let kMotiveCommentsListPath = "motiveComments"
                        let motiveCommentsReference = Database.database().reference(withPath: kMotiveCommentsListPath)
                        motiveCommentsReference.child(motiveId).removeValue()
                        self.motivesGoingReference.child(motiveId).removeValue()
                        self.motivesReference.child(motiveId).removeValue()
                        let kExploreMotivesListPath = "exploreMotives"
                        let exploreMotivesReference = Database.database().reference(withPath: kExploreMotivesListPath)
                        exploreMotivesReference.child(motiveId).removeValue()
                        print ("deleted post " + motiveId)
                    }
                }
                self.tableView.beginUpdates()
                self.motiveAndUsers.remove(at: editActionsForRowAt.row)
                self.tableView.deleteRows(at: [editActionsForRowAt], with: .fade)
                self.tableView.endUpdates()
            }
            return [delete]
        } else {
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if indexPath.row == motiveAndUsers.count {
            return false
        }
        let motiveAndUser = motiveAndUsers[indexPath.row]
        if Auth.auth().currentUser?.uid == motiveAndUser.motive.creator {
            return true
        } else {
            return false
        }
    }
    
}

// disable point callout and user interaction - map delegate
extension UserViewController: MGLMapViewDelegate {
    
    func mapView(_ mapView: MGLMapView, didFinishLoading style: MGLStyle) {
        addItemsToMap(features: [pointFeature])
    }
    
    // function to set the style for custom features on map
    func addItemsToMap(features: [MGLPointFeature]) {
        guard let style = pointMapView.style else { return }
        let image = resizeImage(image: #imageLiteral(resourceName: "defaultAnnotation.png"), targetSize: CGSize(width: 40, height: 40))
        style.setImage(image, forName: "lighthouse")
        let source = MGLShapeSource(identifier: "us-lighthouses", features: features, options: nil)
        style.addSource(source)
        let symbols = MGLSymbolStyleLayer(identifier: "lighthouse-symbols", source: source)
        symbols.iconAllowsOverlap = NSExpression(forConstantValue: "YES")
        symbols.iconIgnoresPlacement = NSExpression(forConstantValue: "YES")
        symbols.iconImageName = NSExpression(forConstantValue: "lighthouse")
        symbols.iconAnchor = NSExpression(forConstantValue: "bottom")
        style.addLayer(symbols)
    }

}

// MARK - view poppers - pinch / pan functionality
extension UserViewController: UIGestureRecognizerDelegate {
    
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
    
    // navigate back to previous screen by popping VC
    @IBAction func goBackPressed(_ sender: Any) {
        self.friendViewControllerDelegate?.refreshTable()
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
                    self.friendViewControllerDelegate?.refreshTable()
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
                    self.friendViewControllerDelegate?.refreshTable()
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
                // reset viewf
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
