//
//  MotiveViewController.swift
//  wyd
//
//  Created by Jason Ellul on 2018-06-19.
//  Copyright © 2018 Jason Ellul. All rights reserved.
//

import UIKit
import Firebase
import CoreLocation
import SDWebImage
import MapKit

private let starFill = #imageLiteral(resourceName: "starFill.png")
private let starUnfill = #imageLiteral(resourceName: "starUnfill.png")
private let commentImage = #imageLiteral(resourceName: "speech bubble.png")

class MotiveViewController: UIViewController, CLLocationManagerDelegate {
    // refresh Ids
    private let reuseIdentifier = "userCell"
    private let refreshIdentifier = "refreshCell"
    // firebase refs
    static let kMotivesListPath = "motives"
    let motivesReference = Database.database().reference(withPath: kMotivesListPath)
    static let kUsersListPath = "users"
    let usersReference = Database.database().reference(withPath: kUsersListPath)
    static let kPrivateListPath = "private"
    let privateReference = Database.database().reference(withPath: kPrivateListPath)
    static let kFollowersListPath = "followers"
    let followersReference = Database.database().reference(withPath: kFollowersListPath)
    static let kFollowingListPath = "following"
    let followingReference = Database.database().reference(withPath: kFollowingListPath)
    static let kMotivesGoingListPath = "motivesGoing"
    let motivesGoingReference = Database.database().reference(withPath: kMotivesGoingListPath)
    static let kUsersGoingListPath = "usersGoing"
    let usersGoingReference = Database.database().reference(withPath: kUsersGoingListPath)
    static let kRequestsListPath = "requests"
    let requestsReference = Database.database().reference(withPath: kRequestsListPath)
    // functions call
    lazy var functions = Functions.functions()
    // location manager
    let locationManager = CLLocationManager()

    // motive and its creator
    var motive: Motive!
    var creator: User!
    // hashtable delegates
    var userHashTableDelegate: UserHashTableDelegate?
    
    // ui kit
    @IBOutlet weak var transitionView: UIView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var headerViewHeightConstraint: NSLayoutConstraint!
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
    var isZooming = false
    var pinchDelegate: PinchDelegate?

    let displayLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = true
        label.textColor = UIColor.black
        label.font = UIFont.boldSystemFont(ofSize: 15.0)
        label.text = ""
        label.textAlignment = .left
        return label
    }()
    let usernameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = true
        label.textColor = UIColor(red: 153/255, green: 153/255, blue: 153/255, alpha: 1.0)
        label.font = UIFont.systemFont(ofSize: 15.0)
        label.text = ""
        label.textAlignment = .left
        return label
    }()
    let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius =  35
        // fix pathing to have default image
        return imageView
    }()
    
    let textLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = UIColor.black
        label.font = UIFont.systemFont(ofSize: 20.0)
        label.text = ""
        label.textAlignment = .center
        label.lineBreakMode = .byWordWrapping
        label.numberOfLines = 0
        return label
    }()
    
    let descriptionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = UIColor(red: 153/255, green: 153/255, blue: 153/255, alpha: 1.0)
        label.font = UIFont.systemFont(ofSize: 16.0)
        label.text = ""
        label.textAlignment = .center
        return label
    }()
    let mapButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = UIColor(red:0.12, green:0.53, blue:0.94, alpha:1.0)
        button.setTitleColor(UIColor.white, for: .normal)
        button.setTitle("Open In Maps", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 9)
        button.titleLabel?.numberOfLines = 0
        return button
    }()
    
    let addressLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = UIColor(red: 153/255, green: 153/255, blue: 153/255, alpha: 1.0)
        label.font = UIFont.systemFont(ofSize: 16.0)
        label.text = ""
        label.textAlignment = .right
        return label
    }()
    
    let distanceLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = UIColor(red: 153/255, green: 153/255, blue: 153/255, alpha: 1.0)
        label.font = UIFont.systemFont(ofSize: 16.0)
        label.text = ""
        label.textAlignment = .right
        return label
    }()
    let commentsButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitleColor(UIColor(red: 153/255, green: 153/255, blue: 153/255, alpha: 1.0), for: .normal)
        button.titleLabel?.textAlignment = .center
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16.0)
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor(red: 242/255, green: 242/255, blue: 242/255, alpha: 1.0).cgColor
        button.layer.cornerRadius = 5
        button.backgroundColor = UIColor.white
        button.contentHorizontalAlignment = .center
        return button
    }()
    let goingButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16.0)
        button.setTitleColor(UIColor(red: 153/255, green: 153/255, blue: 153/255, alpha: 1.0), for: .normal)
        button.setTitleColor(UIColor(red: 153/255, green: 153/255, blue: 153/255, alpha: 1.0), for: .highlighted)
        button.backgroundColor = UIColor.clear
        button.contentHorizontalAlignment = .left
        //button.backgroundColor = UIColor.cyan
        return button
    }()
    let reportButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitleColor(UIColor(red:1.00, green:0.60, blue:0.20, alpha:1.0), for: .normal)
        button.titleLabel?.textAlignment = .center
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14.0)
        button.setTitle("report post", for: .normal)
        button.contentHorizontalAlignment = .center
        return button
    }()
    // going table view elements
    var outOfUsers: Bool = false
    var loadingMoreUsers: Bool = false
    var queryTime: Int64 = 0
    // getmoreueser query parameters
    let numUsersToLoad: UInt = 15
    // array of users to display in table
    var users = [User]()
    // table view of users going to this motive
    let tableView: UITableView = {
        let table = UITableView()
        table.tableFooterView = UIView (frame: CGRect.zero)
        table.layoutMargins = UIEdgeInsets.zero
        table.separatorInset = UIEdgeInsets.zero
        table.estimatedRowHeight = UITableViewAutomaticDimension
        table.rowHeight = UITableViewAutomaticDimension
        return table
    }()
    var calloutViewDelegate: CalloutViewDelegate?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        // set distance
        locationManager.delegate = self
        locationManager.startUpdatingLocation()
        setAddressLabel()
        // set posters name and username
        self.displayLabel.text = creator.display
        self.usernameLabel.text = "@" + creator.username
        setupSubviews()
        userHashTableDelegate = self.tabBarController as? CustomTabBarController
        // load posters profile picture
        // download profile image
        if let url = URL(string: creator.photoURL) {
            self.profileImageView.sd_setImage(with: url) { (image, error, cache, urls) in
                if (error != nil) {
                    //Failure code here - defualt image
                    self.profileImageView.image = #imageLiteral(resourceName: "default user icon.png")
                } else {
                    //Success code here
                    self.profileImageView.image = image
                }
            }
        }
        // set motive details and labels
        self.textLabel.text = motive.text
        addTapGestureRecognizers()
        // add transition view swipe
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panGestureRecognizerAction(_:)))
        // add transition view pinch
        let pinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(pinchGestureRecognizerAction(_:)))
        // delay for 0.5 seconds before enabling gestures
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // add swipe right gesture
            self.transitionView.addGestureRecognizer(panGestureRecognizer)
            self.transitionView.addGestureRecognizer(pinchGestureRecognizer)
        }
        // make query time current time and load users into table
        queryTime = Int64(NSDate().timeIntervalSince1970 * -1000)
        getTableData()
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
        
        self.scrollView.frame.size.width = self.view.frame.size.width
        self.scrollView.contentSize.height = self.view.frame.size.height - headerView.frame.height
        self.scrollView.delegate = self
        self.scrollView.addSubview(profileImageView)
        profileImageView.leftAnchor.constraint(equalTo: self.scrollView.leftAnchor, constant: 10).isActive = true
        profileImageView.topAnchor.constraint(equalTo: self.scrollView.topAnchor, constant: 10).isActive = true
        profileImageView.widthAnchor.constraint(equalToConstant: 70).isActive = true
        profileImageView.heightAnchor.constraint(equalToConstant: 70).isActive = true
 
        let timeLabel = UILabel()
        self.scrollView.addSubview(timeLabel)
        timeLabel.translatesAutoresizingMaskIntoConstraints = true
        timeLabel.textColor = UIColor(red: 153/255, green: 153/255, blue: 153/255, alpha: 1.0)
        timeLabel.font = UIFont.systemFont(ofSize: 16.0)
        timeLabel.text = timestampToText(timestamp: motive.time)
        timeLabel.textAlignment = .right
        timeLabel.sizeToFit()
        timeLabel.frame = CGRect(x: scrollView.frame.width - 10 - timeLabel.frame.width, y: (90 / 2) - (timeLabel.frame.height / 2), width: timeLabel.frame.width, height: timeLabel.frame.height)
        
        self.scrollView.addSubview(displayLabel)
        displayLabel.sizeToFit()
        displayLabel.frame = CGRect(x: 95, y: (90 / 2) - (displayLabel.frame.height / 2), width: min(displayLabel.frame.width, scrollView.frame.width - 100 - timeLabel.frame.width), height: displayLabel.frame.height)
        
        self.scrollView.addSubview(usernameLabel)
        usernameLabel.sizeToFit()
        usernameLabel.frame = CGRect(x: 95, y: ((90 / 2) - (usernameLabel.frame.height / 2)) + 20, width: usernameLabel.frame.width, height: usernameLabel.frame.height)
        

        self.scrollView.addSubview(textLabel)
        textLabel.centerXAnchor.constraint(equalTo: self.scrollView.centerXAnchor).isActive = true
        textLabel.topAnchor.constraint(equalTo: self.scrollView.topAnchor, constant: 105).isActive = true
        textLabel.widthAnchor.constraint(equalToConstant: self.scrollView.frame.size.width - 16).isActive = true
        textLabel.heightAnchor.constraint(equalToConstant: 105).isActive = true
        
        self.scrollView.addSubview(descriptionLabel)
        descriptionLabel.centerXAnchor.constraint(equalTo: self.scrollView.centerXAnchor).isActive = true
        descriptionLabel.topAnchor.constraint(equalTo: self.scrollView.topAnchor, constant: 105).isActive = true
        descriptionLabel.widthAnchor.constraint(equalToConstant: self.scrollView.frame.size.width - 20).isActive = true
        descriptionLabel.heightAnchor.constraint(equalToConstant: 100).isActive = true
        descriptionLabel.numberOfLines = 0
        // add comments button and setup images
        self.scrollView.addSubview(commentsButton)
        commentsButton.setTitle(" " + String(motive.numComments) + " comments", for: .normal)
        commentsButton.setImage(resizeImage(image: commentImage, targetSize: CGSize(width: 15, height: 15)), for: .normal)
        commentsButton.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 237).isActive = true
        commentsButton.widthAnchor.constraint(equalToConstant: (scrollView.frame.width / 4) + 45).isActive = true
        commentsButton.leftAnchor.constraint(equalTo: scrollView.leftAnchor, constant: 10).isActive = true
        commentsButton.heightAnchor.constraint(equalToConstant: 35).isActive = true
        commentsButton.addTarget(self, action: #selector(commentsButtonPressed(_:)), for: .touchUpInside)

        // add map button and location information labels
        self.scrollView.addSubview(mapButton)
        mapButton.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 237).isActive = true
        mapButton.widthAnchor.constraint(equalToConstant: 35).isActive = true
        mapButton.frame.size.width = 35
        mapButton.heightAnchor.constraint(equalToConstant: 35).isActive = true
        mapButton.leftAnchor.constraint(equalTo: scrollView.leftAnchor, constant: scrollView.frame.width - (mapButton.frame.width + 10)).isActive = true
        mapButton.layer.cornerRadius = 5
        mapButton.addTarget(self, action: #selector(mapButtonPressed(_:)), for: .touchUpInside)
        
        self.scrollView.addSubview(addressLabel)
        addressLabel.topAnchor.constraint(equalTo: self.scrollView.topAnchor, constant: 230).isActive = true
        addressLabel.widthAnchor.constraint(equalToConstant: (self.scrollView.frame.size.width / 2) - (mapButton.frame.width)).isActive = true
        addressLabel.heightAnchor.constraint(equalToConstant: 30).isActive = true
        addressLabel.rightAnchor.constraint(equalTo: scrollView.leftAnchor, constant: scrollView.frame.width - (mapButton.frame.width + 20)).isActive = true

        self.scrollView.addSubview(distanceLabel)
        distanceLabel.topAnchor.constraint(equalTo: self.scrollView.topAnchor, constant: 250).isActive = true
        distanceLabel.widthAnchor.constraint(equalToConstant: self.scrollView.frame.size.width / 2).isActive = true
        distanceLabel.heightAnchor.constraint(equalToConstant: 30).isActive = true
        distanceLabel.rightAnchor.constraint(equalTo: scrollView.leftAnchor, constant: scrollView.frame.width - (mapButton.frame.width + 20)).isActive = true
        
        self.scrollView.addSubview(reportButton)
        reportButton.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 9).isActive = true
        if let reportButtonTextWidth = reportButton.titleLabel?.text?.width(withConstrainedHeight: 14, font: UIFont.systemFont(ofSize: 14)) {
            reportButton.widthAnchor.constraint(equalToConstant: reportButtonTextWidth).isActive = true
            reportButton.frame.size.width = reportButtonTextWidth
            reportButton.heightAnchor.constraint(equalToConstant: 14).isActive = true
            reportButton.leftAnchor.constraint(equalTo: scrollView.leftAnchor, constant: scrollView.frame.width - (reportButton.frame.width + 10)).isActive = true
            reportButton.addTarget(self, action: #selector(reportPressed(_:)), for: .touchUpInside)
        }

        // add segmented control like going button - height 40px
        let fakeSegmentedControlView = UIView(frame: CGRect(x: 0, y: 280, width: scrollView.frame.width, height: 40))
        fakeSegmentedControlView.translatesAutoresizingMaskIntoConstraints = true
        fakeSegmentedControlView.backgroundColor = UIColor.white
        scrollView.addSubview(fakeSegmentedControlView)
        // add bottom 1px grey bar
        let greyBar = UIView(frame: CGRect(x: 0, y: fakeSegmentedControlView.frame.height - 1, width: fakeSegmentedControlView.frame.width, height: 1))
        greyBar.isUserInteractionEnabled = false
        greyBar.backgroundColor = UIColor(red: 0.783922, green: 0.780392, blue: 0.8, alpha: 1.0)
        greyBar.translatesAutoresizingMaskIntoConstraints = true
        fakeSegmentedControlView.addSubview(greyBar)
        // add goingButton to fakeSegmentedControl
        fakeSegmentedControlView.addSubview(goingButton)
        goingButton.centerXAnchor.constraint(equalTo: fakeSegmentedControlView.centerXAnchor, constant: 0).isActive = true
        goingButton.centerYAnchor.constraint(equalTo: fakeSegmentedControlView.centerYAnchor, constant: 0).isActive = true
        goingButton.setTitle(" " + String(motive.numGoing) + " going", for: .normal)
        goingButton.setTitle(" " + String(motive.numGoing) + " going", for: .highlighted)
        goingButton.sizeToFit()
        goingButton.frame.size.width += 15
        if ((self.tabBarController as? CustomTabBarController)?.userMotiveGoingSet.contains(motive.id) ?? false) {
            setupUserGoing()
        } else {
            setupUserNotGoing()
        }
        // add table view to bottom
        scrollView.addSubview(tableView)
        tableView.frame = CGRect(x: 0, y: 320, width: scrollView.frame.width, height: scrollView.frame.height)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UserTableViewCell.self, forCellReuseIdentifier: reuseIdentifier)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: refreshIdentifier)
        tableView.alwaysBounceVertical = false
        tableView.isScrollEnabled = false
    }
    
    func setupUserGoing() {
        // change button image
        let starFillImage = resizeImage(image: starFill, targetSize: CGSize(width: 18, height: 18))
        goingButton.setImage(starFillImage, for: .normal)
        goingButton.setImage(starFillImage, for: .highlighted)
        // set title color
        goingButton.setTitleColor(UIColor(red:1.00, green:0.60, blue:0.20, alpha:1.0), for: .normal)
        goingButton.setTitleColor(UIColor(red:1.00, green:0.60, blue:0.20, alpha:1.0), for: .highlighted)
        // change action
        goingButton.removeTarget(self, action: #selector(goingButtonTapped(_:)), for: .touchUpInside)
        goingButton.addTarget(self, action: #selector(ungoingLabelTapped(_:)), for: .touchUpInside)
    }
    
    func setupUserNotGoing() {
        // set images and text back to grey
        let starOutlineImage = resizeImage(image: starUnfill, targetSize: CGSize(width: 18, height: 18))
        goingButton.setImage(resizeImage(image: starOutlineImage, targetSize: CGSize(width: 15, height: 15)), for: .normal)
        goingButton.setImage(resizeImage(image: starOutlineImage, targetSize: CGSize(width: 15, height: 15)), for: .highlighted)
        // set title color
        goingButton.setTitleColor(UIColor(red: 153/255, green: 153/255, blue: 153/255, alpha: 1.0), for: .normal)
        goingButton.setTitleColor(UIColor(red: 153/255, green: 153/255, blue: 153/255, alpha: 1.0), for: .highlighted)
        // set target back to normal
        goingButton.removeTarget(self, action: #selector(ungoingLabelTapped(_:)), for: .touchUpInside)
        goingButton.addTarget(self, action: #selector(goingButtonTapped(_:)), for: .touchUpInside)
    }
    
    // turn header profile display into buttons
    func addTapGestureRecognizers() {
        // turn profile image into a button
        let profileGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(creatorProfilePressed(_:)))
        profileImageView.isUserInteractionEnabled = true
        profileImageView.addGestureRecognizer(profileGestureRecognizer)
        let profileGestureRecognizer2 = UITapGestureRecognizer(target: self, action: #selector(creatorProfilePressed(_:)))
        displayLabel.isUserInteractionEnabled = true
        displayLabel.addGestureRecognizer(profileGestureRecognizer2)
        let profileGestureRecognizer3 = UITapGestureRecognizer(target: self, action: #selector(creatorProfilePressed(_:)))
        usernameLabel.isUserInteractionEnabled = true
        usernameLabel.addGestureRecognizer(profileGestureRecognizer3)
    }
    
    @objc func reportPressed(_ sender: Any) {
        AlertController.showAlert(self, title: "Post Reported", message: "This post has been reported. This incident will be reviewed by a moderator.")
    }
    
    // set distance label to distance from user
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // TODO ** prompt user to change settings if locationManager is not enabled...
        let location = locations[0]
        let userCoord = CLLocation(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        let motiveCoord = CLLocation(latitude: self.motive.latitude, longitude: self.motive.longitude)
        
        let distance = userCoord.distance(from: motiveCoord)
        
        if (distance > 1000) {
            self.distanceLabel.text = String(round((distance / 1000) * 10) / 10) + " km away"
        } else {
            self.distanceLabel.text = String(round(distance * 10) / 10) + " m away"
        }
        // only do this once so it doesnt kill the battery
        locationManager.stopUpdatingLocation()
    }
    
    func setAddressLabel() {
        let geocoder = CLGeocoder()
        // Look up the location and pass it to the completion handler
        let coord = CLLocation(latitude: motive.latitude, longitude: motive.longitude)
        geocoder.reverseGeocodeLocation(coord, completionHandler: { (placemarks, error) in
            if error == nil {
                let firstLocation = placemarks?[0]
                if (firstLocation?.subThoroughfare != nil && firstLocation?.thoroughfare != nil) {
                    self.addressLabel.text = (firstLocation?.subThoroughfare)! + " " + (firstLocation?.thoroughfare)!
                } else if (firstLocation?.locality != nil) {
                    self.addressLabel.text = firstLocation?.locality
                } else if (firstLocation?.inlandWater != nil) {
                    self.addressLabel.text = firstLocation?.inlandWater
                } else if (firstLocation?.country != nil) {
                    self.addressLabel.text = firstLocation?.country
                } else if (firstLocation?.ocean != nil) {
                    self.addressLabel.text = firstLocation?.ocean
                } else {
                    self.addressLabel.text = ""
                }
            } else {
                // An error occurred during geocoding.
                self.addressLabel.text = ""
            }
        })
    }
    
    // open in maps pressed
    @objc func mapButtonPressed(_ sender: UIButton) {
        let latitude = motive.latitude
        let longitude = motive.longitude
        
        let regionDistance: CLLocationDistance = 500
        let coordinates = CLLocationCoordinate2DMake(latitude, longitude)
        let regionSpan = MKCoordinateRegionMakeWithDistance(coordinates, regionDistance, regionDistance)
        let options = [
            MKLaunchOptionsMapCenterKey: NSValue(mkCoordinate: regionSpan.center),
            MKLaunchOptionsMapSpanKey: NSValue(mkCoordinateSpan: regionSpan.span)
        ]
        let placemark = MKPlacemark(coordinate: coordinates, addressDictionary: nil)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = motive.text
        mapItem.openInMaps(launchOptions: options)
    }
    
    @objc func commentsButtonPressed(_ sender: UIButton) {
        guard let currentUser = (self.tabBarController as? CustomTabBarController)?.currentUser else { return }
        if let snapshotView = UIApplication.shared.keyWindow?.snapshotView(afterScreenUpdates: true) {
            if let pinchSnapshotView = UIApplication.shared.keyWindow?.snapshotView(afterScreenUpdates: true) {
                let commentViewController = storyboard?.instantiateViewController(withIdentifier: "commentViewController") as! CommentViewController
                commentViewController.backgroundView = snapshotView
                commentViewController.pinchView = pinchSnapshotView
                commentViewController.motive = motive
                commentViewController.currentUser = currentUser
                commentViewController.hidesBottomBarWhenPushed = true
                self.navigationController?.pushViewController(commentViewController, animated: true)
            }
        }
    }
    
    // push creator profile
    @objc func creatorProfilePressed(_ sender: UIButton) {
        if let snapshotView = self.view.snapshotView(afterScreenUpdates: true) {
            for subview in pinchView.subviews {
                if subview is UIVisualEffectView { subview.isHidden = true }
            }
            if let pinchSnapshotView = self.pinchView.snapshotView(afterScreenUpdates: true) {
                let userViewController = storyboard?.instantiateViewController(withIdentifier: "userViewController") as! UserViewController
                userViewController.backgroundView = snapshotView
                for subview in pinchView.subviews {
                    if subview is UIVisualEffectView { subview.isHidden = false }
                }
                userViewController.pinchView = pinchSnapshotView
                userViewController.pinchDelegate = self.pinchDelegate
                userViewController.uid = creator.uid
                userViewController.user = creator
                self.navigationController?.pushViewController(userViewController, animated: true)
            }
        }
    }
    
    // initially load the users into table view
    func getTableData() {
        // type switch - decides headerLabel text and what type of table to load
        loadingMoreUsers = true
        // get uid list
        motivesGoingReference.child(motive.id).queryOrderedByValue().queryStarting(atValue: queryTime + 1).queryLimited(toFirst: numUsersToLoad).observeSingleEvent(of: .value) { (snapshot) in
            if snapshot.exists() {
                var goingSnapshotArray: [DataSnapshot] = []
                for item in snapshot.children.allObjects as! [DataSnapshot] {
                    goingSnapshotArray.append(item)
                }
                goingSnapshotArray.sort(by: {( ($0.value as! Int) < ($1.value as! Int) )})
                self.queryTime = Int64(goingSnapshotArray.last?.value as! Int)
                // load users from original ids
                let myGroup = DispatchGroup()
                var newUsers: [User] = []
                for goingSnapshot in goingSnapshotArray {
                    // dispatch lock
                    myGroup.enter()
                    let uid = goingSnapshot.key
                    // check to see if its in hashtable
                    if let user = self.userHashTableDelegate?.retrieveUser(uid: uid) {
                        newUsers.append(user)
                        myGroup.leave()
                        // if not in hashtable then load from firebase and store in hashtable
                    } else {
                        self.getUser(uid: uid) { (result) in
                            if let user = result {
                                // store result and append to table data source
                                self.userHashTableDelegate?.storeUser(user: user)
                                newUsers.append(user)
                            }
                            myGroup.leave()
                        }
                    }
                }
                // wait until every member of mygroup is finished
                myGroup.notify(queue: .main) {
                    //self.activityIndicator.stopAnimating()
                    self.users = self.users + newUsers
                    if newUsers.count == 0 {
                        self.outOfUsers = true
                    }
                    self.loadingMoreUsers = false
                    self.tableView.reloadData()
                    self.adjustContentSize()

                }
                
            } else {
                //self.activityIndicator.stopAnimating()
                self.outOfUsers = true
                self.loadingMoreUsers = false
                self.tableView.reloadData()
                self.adjustContentSize()
            }
        }
    }
    
    func adjustContentSize() {
        tableView.layoutIfNeeded()
        // calculate the height of table
        var height = CGFloat(0)
        for index in 0..<tableView.numberOfRows(inSection: 0) {
            let i = IndexPath(row: index, section: 0)
            height += tableView.rectForRow(at: i).height
        }
        tableView.contentSize.height = height
        tableView.frame = CGRect(x: 0, y: 320, width: scrollView.frame.width, height: tableView.contentSize.height)
        scrollView.contentSize.height = max(280 + tableView.contentSize.height + 40, view.frame.height - headerView.frame.height)
    }
    

}
// MARK :- Function calls for goingButton
extension MotiveViewController {
    
    @objc func goingButtonTapped(_ sender: Any) {
        guard var motive = self.motive else { return }
        guard let uid = Auth.auth().currentUser?.uid else { return }
        // add user to motivesGoing firebase
        let timestamp = Int64(NSDate().timeIntervalSince1970 * -1000)
        // set value to time in going so user can see most recently going - also triggers backend count function
        motivesGoingReference.child(motive.id).child(uid).setValue(timestamp)
        // set value to true in inverted index to save space
        usersGoingReference.child(uid).child(motive.id).setValue(timestamp)
        // animate star fill
        let starFillImage = resizeImage(image: starFill, targetSize: CGSize(width: 15, height: 15))
        let expandTransform: CGAffineTransform = CGAffineTransform(scaleX: 1.5, y: 1.5);
        UIView.animate(withDuration: 0.1, delay: 0.0, options: .transitionCrossDissolve, animations: {
            self.goingButton.setImage(starFillImage, for: .normal)
            self.goingButton.setImage(starFillImage, for: .highlighted)
        }) { (completion) in
            // add springy transform
            // https://stackoverflow.com/questions/2834573/how-to-animate-the-change-of-image-in-an-uiimageview
            UIView.animate(withDuration: 1.2, delay: 0.0, usingSpringWithDamping: 0.25, initialSpringVelocity: 0.25, options: .curveEaseOut, animations: {
                self.goingButton.imageView?.transform = expandTransform.inverted()
            }) { (completion) in
                self.goingButton.imageView?.transform = CGAffineTransform.identity
            }
        }
        // set title color
        goingButton.setTitleColor(UIColor(red:1.00, green:0.60, blue:0.20, alpha:1.0), for: .normal)
        goingButton.setTitleColor(UIColor(red:1.00, green:0.60, blue:0.20, alpha:1.0), for: .highlighted)
        // change motive object
        motive.numGoing = motive.numGoing + 1
        if motive.numGoing < 0 {
            motive.numGoing = 0
        }
        self.motive = motive
        // change text
        goingButton.setTitle(" " + String(motive.numGoing) + " going", for: .normal)
        goingButton.setTitle(" " + String(motive.numGoing) + " going", for: .highlighted)
        goingButton.sizeToFit()
        goingButton.frame.size.width += 15
        //goingButtonWidthConstraint.constant = goingButton.frame.width + 15
        // add to tab bar in map view
        calloutViewDelegate?.goingPressed(motive: motive)
        // make http call
        functions.httpsCallable("countGoing").call(["id": motive.id]) { (result, error) in
            if let error = error as NSError? {
                if error.domain == FunctionsErrorDomain {
                    let message = error.localizedDescription
                    print (message)
                }
            }
            if let numGoing = (result?.data as? [String: Any])?["num"] as? Int {
                print (numGoing)
                self.motivesReference.child(motive.id).child("numGoing").setValue(numGoing)
            }
        }
        // add row to the table
        if let user = (self.tabBarController as? CustomTabBarController)?.currentUser?.user {
            self.tableView.beginUpdates()
            self.users.insert(user, at: 0)
            self.tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .fade)
            self.tableView.endUpdates()
            self.adjustContentSize()
        }
        (self.tabBarController as? CustomTabBarController)?.userMotiveGoingSet.insert(motive.id)
        // change action
        goingButton.removeTarget(self, action: #selector(goingButtonTapped(_:)), for: .touchUpInside)
        goingButton.addTarget(self, action: #selector(ungoingLabelTapped(_:)), for: .touchUpInside)
    }
    // when the user un goes to a motive
    @objc func ungoingLabelTapped(_ sender: Any) {
        guard var motive = self.motive else { return }
        guard let uid = Auth.auth().currentUser?.uid else { return }
        // remove from motives going - also triggers backend write function
        motivesGoingReference.child(motive.id).child(uid).removeValue()
        // remove from users going
        usersGoingReference.child(uid).child(motive.id).removeValue()
        // set images and text back to grey
        let starOutlineImage = resizeImage(image: starUnfill, targetSize: CGSize(width: 15, height: 15))
        goingButton.setImage(resizeImage(image: starOutlineImage, targetSize: CGSize(width: 15, height: 15)), for: .normal)
        goingButton.setImage(resizeImage(image: starOutlineImage, targetSize: CGSize(width: 15, height: 15)), for: .highlighted)
        goingButton.setTitleColor(UIColor(red: 153/255, green: 153/255, blue: 153/255, alpha: 1.0), for: .normal)
        goingButton.setTitleColor(UIColor(red: 153/255, green: 153/255, blue: 153/255, alpha: 1.0), for: .highlighted)
        // change motive object
        motive.numGoing = motive.numGoing - 1
        if motive.numGoing < 0 {
            motive.numGoing = 0
        }
        self.motive = motive
        // change text
        goingButton.setTitle(" " + String(motive.numGoing) + " going", for: .normal)
        goingButton.setTitle(" " + String(motive.numGoing) + " going", for: .highlighted)
        goingButton.sizeToFit()
        goingButton.frame.size.width += 15
        //goingButtonWidthConstraint.constant = goingButton.frame.width + 15
        // add to tab bar in map view
        calloutViewDelegate?.unGoPressed(motive: motive)
        // make http call
        functions.httpsCallable("countGoing").call(["id": motive.id]) { (result, error) in
            if let error = error as NSError? {
                if error.domain == FunctionsErrorDomain {
                    let message = error.localizedDescription
                    print (message)
                }
            }
            if let numGoing = (result?.data as? [String: Any])?["num"] as? Int {
                print (numGoing)
                self.motivesReference.child(motive.id).child("numGoing").setValue(numGoing)
            }
        }
        // delete row table if user is visable
        if let user = (self.tabBarController as? CustomTabBarController)?.currentUser?.user {
            self.tableView.beginUpdates()
            for (i, goingUsers) in self.users.enumerated() {
                if goingUsers.uid == user.uid {
                    users.remove(at: i)
                    self.tableView.deleteRows(at: [IndexPath(row: i, section: 0)], with: .fade)
                }
            }
            self.tableView.endUpdates()
            self.adjustContentSize()
        }
        (self.tabBarController as? CustomTabBarController)?.userMotiveGoingSet.remove(motive.id)

        // set target back to normal
        goingButton.removeTarget(self, action: #selector(ungoingLabelTapped(_:)), for: .touchUpInside)
        goingButton.addTarget(self, action: #selector(goingButtonTapped(_:)), for: .touchUpInside)
    }
}

// MARK :- Table View Delegate
extension MotiveViewController: UITableViewDelegate, UITableViewDataSource, FriendViewControllerDelegate, UIScrollViewDelegate {

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // toggle verticle indictor
        if scrollView.contentOffset.y <= 0 {
            scrollView.showsVerticalScrollIndicator = false
        } else {
            scrollView.showsVerticalScrollIndicator = true
        }
        
        if scrollView.contentOffset.y + 350 >= scrollView.contentSize.height - scrollView.frame.height {
            if !outOfUsers && !loadingMoreUsers {
                getTableData()
            }
        }
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // +1 for refresh cell at the end
        return users.count + 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == users.count {
            let cell = tableView.dequeueReusableCell(withIdentifier: refreshIdentifier)
            cell?.separatorInset = UIEdgeInsetsMake(0, tableView.frame.width / 2, 0, tableView.frame.width / 2)
            // if there are NO motives in going or posts
            if users.count == 0 || outOfUsers {
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
            let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier) as! UserTableViewCell
            // since awake from xib isnt called
            cell.frame.size.width = tableView.frame.width
            cell.selectionStyle = .none
            cell.layoutMargins = UIEdgeInsets.zero
            cell.awakeFromNib()
            // THE user of the user table view cell
            let user = users[indexPath.row]
            cell.titleLabel.text = user.display
            cell.usernameLabel.text = "@" + user.username
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
            // setup side button
            cell.followingButton.tag = indexPath.row
            cell.followButton.tag = indexPath.row
            if let currentUser = (self.tabBarController as? CustomTabBarController)?.currentUser {
                // if the cell is the current user
                if currentUser.user.uid == user.uid {
                    // remove side button
                    cell.loadingButton.removeFromSuperview()
                    return cell
                } else {
                    // if current user is following cell user
                    if currentUser.followingSet.contains(user.uid) {
                        cell.setupAlreadyFollowingButton()
                        cell.followingButton.removeTarget(self, action: #selector(self.requestSentPressed(_:)), for: .touchUpInside)
                        cell.followingButton.addTarget(self, action: #selector(FriendViewController.alreadyFollowingPressed(_:)), for: .touchUpInside)
                        return cell
                    }
                    // if current user has requested to follow cell user
                    if user.requestSent {
                        cell.setupRequestSentButton()
                        cell.followingButton.removeTarget(self, action: #selector(self.alreadyFollowingPressed(_:)), for: .touchUpInside)
                        cell.followingButton.addTarget(self, action: #selector(self.requestSentPressed(_:)), for: .touchUpInside)
                        return cell
                    }
                    // not currently following or requested
                    // display addFriendButton
                    cell.setupFollowButton()
                    cell.followButton.addTarget(self, action: #selector(FriendViewController.followPressed(_:)), for: .touchUpInside)
                    return cell
                }
            }
            // error - remove side button and return
            cell.loadingButton.removeFromSuperview()
            return cell
        }
    }
    // add friend is pressed when user is not private
    @objc func followPressed (_ sender: UIButton!) {
        guard let currentUserUid = Auth.auth().currentUser?.uid else { return }
        let indexPath = IndexPath(row: sender.tag, section: 0)
        let cell = tableView.cellForRow(at: indexPath) as! UserTableViewCell
        cell.followButton.showLoading()
        // change requestSent status in userHashTable
        let user = users[indexPath.row]
        let cellUid = user.uid
        // send friend request to view user
        let timestamp = Int64(NSDate().timeIntervalSince1970 * -1000)
        privateReference.child(cellUid).observeSingleEvent(of: .value) { (snapshot) in
            if snapshot.exists() {
                // user is private - send request to cell user
                self.requestsReference.child(cellUid).child(currentUserUid).setValue(timestamp)
                // update hash table user object
                var updatedUser = user
                updatedUser.requestSent = true
                self.userHashTableDelegate?.storeUser(user: updatedUser)
                self.users[indexPath.row] = updatedUser
                cell.setupRequestSentButton()
                cell.followingButton.removeTarget(self, action: #selector(self.alreadyFollowingPressed(_:)), for: .touchUpInside)
                cell.followingButton.addTarget(self, action: #selector(self.requestSentPressed(_:)), for: .touchUpInside)
            } else {
                // user is not private - follow cell user
                self.followersReference.child(cellUid).child(currentUserUid).setValue(timestamp)
                self.followingReference.child(currentUserUid).child(cellUid).setValue(true)
                // call function to count num following for user in cell
                self.functionsNumFollowersCall(cellUid)
                // update objects in tab bar
                if let currentUser = (self.tabBarController as? CustomTabBarController)?.currentUser {
                    // update current user object
                    currentUser.followingSet.insert(cellUid)
                    var updatedCurrentUser = currentUser.user
                    updatedCurrentUser.numFollowing += 1
                    currentUser.user = updatedCurrentUser
                    (self.tabBarController as? CustomTabBarController)?.currentUser = currentUser
                    self.userHashTableDelegate?.storeUser(user: updatedCurrentUser)
                    self.usersReference.child(currentUserUid).child("nFing").setValue(currentUser.followingSet.count)
                }
                // update object is table
                var updatedUser = user
                updatedUser.numFollowers += 1
                self.userHashTableDelegate?.storeUser(user: updatedUser)
                self.users[indexPath.row] = updatedUser
                // change add button to request Sent button
                cell.setupAlreadyFollowingButton()
                cell.followingButton.removeTarget(self, action: #selector(self.requestSentPressed(_:)), for: .touchUpInside)
                cell.followingButton.removeTarget(self, action: #selector(self.alreadyFollowingPressed(_:)), for: .touchUpInside)
                //cell.followingButton.addTarget(self, action: #selector(self.alreadyFollowingPressed(_:)), for: .touchUpInside)
            }
            cell.followButton.hideLoading()
        }
        
    }
    
    
    @objc func alreadyFollowingPressed (_ sender: UIButton!) {
        /*let currentUserUid = (Auth.auth().currentUser?.uid)!
         let cellUser = users[sender.tag]
         // Create the alert controller.
         let alert = UIAlertController(title: "Remove Friend", message: "Are you sure you want to remove @" + cellUser.username + " as a friend?" , preferredStyle: .alert)
         
         // add a cancel button
         alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil))
         
         // remove user from both people friends list
         alert.addAction(UIAlertAction(title: "Remove", style: .default, handler: { [] (_) in
         self.usersReference.child(currentUserUid).child("friends").child(cellUser.uid).removeValue()
         self.usersReference.child(cellUser.uid).child("friends").child(currentUserUid).removeValue()
         self.users.remove(at: sender.tag)
         self.tableView.reloadData()
         }))
         
         // Present the alert.
         self.present(alert, animated: true, completion: nil)*/
    }
    // call firebase functions to write num followers for user
    func functionsNumFollowersCall(_ uid: String) {
        self.functions.httpsCallable("countFollowers").call(["id": uid]) { (result, error) in
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
    }
    // undo the follow request
    @objc func requestSentPressed(_ sender: UIButton!) {
        guard let currentUserUid = Auth.auth().currentUser?.uid else { return }
        let indexPath = IndexPath(row: sender.tag, section: 0)
        let cell = tableView.cellForRow(at: indexPath) as! UserTableViewCell
        // change requestSent status in userHashTable
        let user = users[indexPath.row]
        let cellUid = user.uid
        self.requestsReference.child(cellUid).child(currentUserUid).removeValue()
        // update tab bar objects
        // update hash table user object
        var updatedUser = user
        updatedUser.requestSent = false
        userHashTableDelegate?.storeUser(user: updatedUser)
        users[indexPath.row] = updatedUser
        cell.setupFollowButton()
        cell.followingButton.removeTarget(self, action: #selector(self.requestSentPressed(_:)), for: .touchUpInside)
        cell.followingButton.addTarget(self, action: #selector(self.followPressed(_:)), for: .touchUpInside)
    }
    
    // impletmented the height methods so that its not jumpy on reload
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        // finished cell (no more users to load)
        if outOfUsers && indexPath.row >= users.count {
            return 0
        }
        // refresh cell
        if indexPath.row >= users.count {
            return 50
        }
        return 90
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        if outOfUsers && indexPath.row >= users.count {
            return 0
        }
        if indexPath.row >= users.count {
            return 50
        }
        return 90
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row >= users.count {
            tableView.deselectRow(at: indexPath, animated: false)
            return
        }
        let user = users[indexPath.row]
        if let snapshotView = self.view.snapshotView(afterScreenUpdates: true) {
            for subview in pinchView.subviews {
                if subview is UIVisualEffectView { subview.isHidden = true }
            }
            if let pinchSnapshotView = self.pinchView.snapshotView(afterScreenUpdates: true) {
                let userViewController = storyboard?.instantiateViewController(withIdentifier: "userViewController") as! UserViewController
                userViewController.backgroundView = snapshotView
                for subview in pinchView.subviews {
                    if subview is UIVisualEffectView { subview.isHidden = false }
                }
                userViewController.pinchView = pinchSnapshotView
                userViewController.pinchDelegate = self.pinchDelegate
                userViewController.uid = user.uid
                userViewController.user = user
                // set delegate since its from a table
                userViewController.friendViewControllerDelegate = self
                self.navigationController?.pushViewController(userViewController, animated: true)
            }
        }
    }
    
    // for FriendViewControllerDelegate - when popped refresh the table to update if you followed
    func refreshTable() {
        tableView.reloadData()
    }
    
}

// view poppers
extension MotiveViewController {
    
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
}


