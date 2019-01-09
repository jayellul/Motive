//
//  MapViewController.swift
//  wyd
//
//  Created by Jason Ellul on 2018-04-14.
//  Copyright © 2018 Jason Ellul. All rights reserved.
//

import UIKit
import Firebase
import SDWebImage

import CoreLocation
import MapKit
import Mapbox

// motive annotation
private let defaultAnnotation = #imageLiteral(resourceName: "defaultAnnotation.png")
private let starAnnotation = #imageLiteral(resourceName: "starAnnotation.png")
private let heartAnnotation = #imageLiteral(resourceName: "heartAnnotation.png")
private let fireAnnotation = #imageLiteral(resourceName: "fireAnnotation.png")
private let moneyAnnotation = #imageLiteral(resourceName: "moneyAnnotation.png")
private let beerAnnotation = #imageLiteral(resourceName: "beerAnnotation.png")
private let wineAnnotation = #imageLiteral(resourceName: "wineAnnotation.png")
private let coffeeAnnotation = #imageLiteral(resourceName: "coffee-cup annotation.png")
private let cutleryAnnotation = #imageLiteral(resourceName: "cutleryAnnotation.png")
private let musicAnnotation = #imageLiteral(resourceName: "musicNoteAnnotation.png")
private let ballAnnotation = #imageLiteral(resourceName: "basketballAnnotation.png")

// button icons
private let rightArrowIcon = #imageLiteral(resourceName: "right-arrow.png")
private let locationIcon = #imageLiteral(resourceName: "gps-fixed-indicator.png")
private let refreshIcon = #imageLiteral(resourceName: "reload.png")
// defualt reuseId
private let reuseIdentifier = "reuse"

// for transferring coordinates between chooselocationVC
protocol LocationDelegate {
    func sendUserCoordinates(latitude: Double, longitude: Double)
}
// for tab bar controller
protocol MapDelegate {
    func goToFeed()
    func mapSentRefresh()
}
// so that this pops all views from navigation stack when app is pinched anywhere other than home
protocol PinchDelegate {
    func viewPinched()
}

protocol AnnotationDelegate {
    func addMotivesToMap(motiveAndUsers: [MotiveAndUser])
}

class MapViewController: UIViewController, CLLocationManagerDelegate, ChooseLocationDelegate, FeedDelegate, TabDelegate, PinchDelegate, AnnotationDelegate {



    var delegate: MapDelegate?
    var currentUserDelegate: CurrentUserDelegate?
    var userHashTableDelegate: UserHashTableDelegate?
    var motiveHashTableDelegate: MotiveHashTableDelegate?
    var currentUser: CurrentUser?

    // only do this once on startup
    var firstLoad = true
    // firebase db refs
    static let kUsersListPath = "users"
    let usersReference = Database.database().reference(withPath: kUsersListPath)
    static let kMotivesListPath = "motives"
    let motivesReference = Database.database().reference(withPath: kMotivesListPath)
    static let kMotivesGoingListPath = "motivesGoing"
    let motivesGoingReference = Database.database().reference(withPath: kMotivesGoingListPath)
    
    // location manager for displaying user location
    let locationManager = CLLocationManager()
    
    // from tab bar controller
    var motiveAndUsers = [MotiveAndUser]()
    var motivesIdsSet : Set<String> = []
        
    // annotations currently on map
    var motivesOnMap : Set<String> = []

    // feed delegate stuff
    var feedButtonShowing = false
    var motiveToSelect = ""
    // fixing the selecting from feed if already selected bug
    var previouslySelectedMotive = ""
    var calloutViewShowing = false
    var calloutViewQueued: MotiveAndUser?
    
    var centerButtonShowing = false
    
    // ui kit components
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var headerViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var headerViewLabel: UILabel!
    @IBOutlet weak var sliderButton: UIButton!

    
    let homeMapView: MKMapView = {
        let map = MKMapView()
        map.isPitchEnabled = false
        map.isRotateEnabled = false
        map.isUserInteractionEnabled = true
        map.userLocation.title = ""
        return map
    }()
    
    // MapBox view
    let mapView: MGLMapView = {
        let url = URL(string: "mapbox://styles/mapbox/streets-v10")
        let map = MGLMapView(frame: CGRect(x: 0, y: 75, width: 128, height: 128), styleURL: url)
        map.isPitchEnabled = false
        map.isRotateEnabled = false
        map.userLocation?.title = ""
        map.showsUserLocation = true
        map.translatesAutoresizingMaskIntoConstraints = true
        map.clipsToBounds = true
        return map
    }()
    
    var motiveFeatures: [MGLPointFeature] = []
    
    let centerButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("", for: .normal)
        button.layer.borderWidth = 0
        button.layer.cornerRadius = 15
        button.backgroundColor = UIColor.clear
        let image = locationIcon
        button.setImage(image, for: .normal)
        button.setImage(image, for: UIControlState.highlighted)
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.30
        button.layer.shadowOffset = CGSize.zero
        button.layer.shadowRadius = 2
        button.isHidden = true
        //button.imageEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5)
        return button
    }()
    
    let refreshButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("", for: .normal)
        button.layer.borderWidth = 0
        button.layer.cornerRadius = 15
        button.backgroundColor = UIColor.clear
        let refreshImage = refreshIcon
        button.setImage(refreshImage, for: .normal)
        button.setImage(refreshImage, for: UIControlState.highlighted)
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.30
        button.layer.shadowOffset = CGSize.zero
        button.layer.shadowRadius = 2
        button.imageEdgeInsets = UIEdgeInsetsMake(2, 2, 2, 2)
        return button
    }()
    // loading indicator within refresh button
    let activityIndicator: UIActivityIndicatorView = {
        let activityIndicator = UIActivityIndicatorView()
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.hidesWhenStopped = true
        activityIndicator.color = UIColor.white
        activityIndicator.layer.shadowColor = UIColor.black.cgColor
        activityIndicator.layer.shadowOpacity = 0.30
        activityIndicator.layer.shadowOffset = CGSize.zero
        activityIndicator.layer.shadowRadius = 2
        return activityIndicator
    }()
    
    let feedButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("", for: .normal)
        button.layer.borderWidth = 0
        button.layer.cornerRadius = 25
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.30
        button.layer.shadowOffset = CGSize.zero
        button.layer.shadowRadius = 2
        button.backgroundColor = UIColor.white
        button.setImage(rightArrowIcon, for: .normal)
        button.setImage(rightArrowIcon, for: .highlighted)
        button.imageEdgeInsets = UIEdgeInsetsMake(12.5, 12.5, 12.5, 12.5)
        button.isHidden = true
        button.tag = 1
        return button
    }()
    
    let calloutView: MotiveView = {
        let view = MotiveView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.30
        view.layer.shadowOffset = CGSize.zero
        view.layer.shadowRadius = 2
        view.isHidden = true
        return view
    }()
    lazy var calloutTopConstraint = calloutView.topAnchor.constraint(equalTo: self.view.bottomAnchor, constant: 100)
    lazy var calloutHeightConstraint = calloutView.heightAnchor.constraint(equalToConstant: 110)

    // set the map region to the users current location - do this once on app startup
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // TODO ** prompt user to change settings if locationManager is not enabled...
        let location = locations[0]
        let userLocation = CLLocationCoordinate2DMake(location.coordinate.latitude, location.coordinate.longitude)
        // make first time load zoomed out on user location more
        if firstLoad {
            mapView.setCenter(userLocation, zoomLevel: 12, direction: 0, animated: false)
            firstLoad = false
        } else {
            // hide center button once its pressed
            if centerButton.isHidden == false {
                UIView.animate(withDuration: 0.3, animations: {
                    self.centerButton.alpha = 0.0
                }, completion: {
                    (value: Bool) in
                    self.centerButton.isHidden = true
                })
            }
            // fly into user location
            let camera = MGLMapCamera(lookingAtCenter: userLocation, fromDistance: 1700, pitch: 0, heading: 0)
            mapView.fly(to: camera, completionHandler: nil)
        }
        // dont update the map based on location anymore
        locationManager.stopUpdatingLocation()
    }
    
    // set up subviews and tap gestures
    override func viewDidLoad() {
        super.viewDidLoad()
        // set tab bar as delegates
        currentUserDelegate = self.tabBarController as? CustomTabBarController
        motiveHashTableDelegate = self.tabBarController as? CustomTabBarController
        userHashTableDelegate = self.tabBarController as? CustomTabBarController

        mapView.delegate = self
        // set frames and constraints of view controller's ui kit members
        setupSubviews()
        mapView.reloadStyle(mapView)
        // motive label on top view zooms out of map a bit
        let headerTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(headerViewLabelTapped(_:)))
        headerViewLabel.isUserInteractionEnabled = true
        headerViewLabel.addGestureRecognizer(headerTapGestureRecognizer)
        
        locationManager.delegate = self
        // nearest 10 meters to save power
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        // SUPER FIREBASE RESET - CARE
        /*self.motivesReference.setValue(nil)
        self.motivesGoingReference.setValue(nil)
        Database.database().reference(withPath: "archive").setValue(nil)
        Database.database().reference(withPath: "archiveGoing").setValue(nil)*/
 
        if Auth.auth().currentUser?.uid == nil {
            // no user signed in - error handle
        } else {
            // load current user and then motives onto map
            firstLoadCurrentUser()
            print("Mission Complete")
            
        }
        // completed viewDidLoad Method
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setupSubviews () {
        headerView.frame.size.height = 75
        headerView.frame.size.width = view.frame.width
        headerView.bounds.size.width = view.frame.width
        if self.isPhoneX() {
            print ("iphoneX")
            headerViewHeightConstraint.constant = 100
            headerView.frame.size.height = 100
            headerView.bounds.size.height = 100
            // adjust attributed text to fix increashed header top
            if mapView.subviews[1] is UIImageView {
                // adjust the logo position
                let mapBoxLogo = mapView.subviews[1] as! UIImageView
                mapBoxLogo.frame = CGRect(x: 8, y: (10.5 / 1.2) + 100, width: mapBoxLogo.frame.width / 1.2, height: mapBoxLogo.frame.height / 1.2)
                // adjust i button position
                let mapBoxButton = mapView.attributionButton
                mapBoxButton.frame = CGRect(x: 8 + mapBoxLogo.frame.width + 4, y: (10.5 / 1.2) + 100, width: mapBoxLogo.frame.height, height: mapBoxLogo.frame.height)
            }
            
        }
        addGradientToView(headerView)
        addGradientToView(feedButton)
        
        
        // set frame of MGL map view
        mapView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)

        // CAREFUL that this doesnt overlap uiview
        self.view.addSubview(mapView)
        view.sendSubview(toBack: mapView)
        
        mapView.addSubview(centerButton)
        centerButton.bottomAnchor.constraint(equalTo: mapView.bottomAnchor, constant: -14.5 - (self.tabBarController?.tabBar.frame.height)!).isActive = true
        centerButton.rightAnchor.constraint(equalTo: mapView.rightAnchor, constant: -14.5).isActive = true
        centerButton.widthAnchor.constraint(equalToConstant: 30).isActive = true
        centerButton.heightAnchor.constraint(equalToConstant: 30).isActive = true
        centerButton.addTarget(self, action: #selector(MapViewController.centerOnUserLocation(_:)), for: .touchUpInside)
        
        mapView.addSubview(refreshButton)
        refreshButton.bottomAnchor.constraint(equalTo: mapView.bottomAnchor, constant: -14.5 - (self.tabBarController?.tabBar.frame.height)!).isActive = true
        refreshButton.leftAnchor.constraint(equalTo: mapView.leftAnchor, constant: 14.5).isActive = true
        refreshButton.widthAnchor.constraint(equalToConstant: 30).isActive = true
        refreshButton.heightAnchor.constraint(equalToConstant: 30).isActive = true
        refreshButton.addTarget(self, action: #selector(MapViewController.refreshPressed(_:)), for: .touchUpInside)
        
        refreshButton.addSubview(activityIndicator)
        activityIndicator.centerXAnchor.constraint(equalTo: refreshButton.centerXAnchor).isActive = true
        activityIndicator.centerYAnchor.constraint(equalTo: refreshButton.centerYAnchor).isActive = true
        
        view.addSubview(calloutView)
        calloutView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        calloutView.widthAnchor.constraint(equalToConstant: view.frame.width - 32).isActive = true
        calloutHeightConstraint.isActive = true
        calloutTopConstraint.isActive = true
        // setup subviews after constraints
        calloutView.frame = CGRect(x: 0, y: 0, width: view.frame.width - 32, height: calloutHeightConstraint.constant)
        calloutView.setupSubviews()
        calloutView.calloutViewDelegate = self
        
        view.addSubview(feedButton)
        feedButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        feedButton.widthAnchor.constraint(equalToConstant: 50).isActive = true
        feedButton.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -6).isActive = true
        feedButton.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant:(self.tabBarController?.tabBar.frame.height)! / -2).isActive = true
        feedButton.addTarget(nil, action: #selector(goToFeed(_:)), for: UIControlEvents.touchUpInside)
        
        
    }
    

    // Zoom out or go to feed?
    @objc func headerViewLabelTapped(_ sender: Any) {
        let currentCamera = mapView.camera
        currentCamera.altitude *= 2
        mapView.fly(to: currentCamera, completionHandler: nil)
    }
    
    // function that loads current user and then sends a refresh to tab bar to get motives
    func firstLoadCurrentUser() {
        if let currentUserUid = Auth.auth().currentUser?.uid {
            // get the signed in users profile
            getCurrentUser(uid: currentUserUid) { (result) in
                if let newCurrentUser = result {
                    // store the result
                    self.currentUser = newCurrentUser
                    (self.tabBarController as? CustomTabBarController)?.currentUser = newCurrentUser
                    self.userHashTableDelegate?.storeUser(user: newCurrentUser.user)
                    // after current user has been loaded load the motives
                    (self.tabBarController as? CustomTabBarController)?.loadMotivesIntoView()
                    self.showActivityIndicator()
                }
            }
        }
    }

    // MARK: - new Motive and functions
    @IBAction func newMotivePressed(_ sender: Any) {
        let chooseLocationViewController = storyboard?.instantiateViewController(withIdentifier: "chooseLocationViewController") as! ChooseLocationViewController
        chooseLocationViewController.delegate = self
        let currentCamera = mapView.camera
        chooseLocationViewController.currentCamera = currentCamera
        chooseLocationViewController.centerButtonVisible = centerButton.isHidden
        self.navigationController?.pushViewController(chooseLocationViewController, animated: true)
    }
    // choose location view controller was cancelled
    func chooseLocationCancelled(currentCamera: MGLMapCamera, centerButtonIsHidden: Bool) {
        mapView.camera = currentCamera
        centerButton.isHidden = centerButtonIsHidden
        return
    }
    
    // user just created a motive
    func panToNewMotiveAndSelect(motive: Motive) {
        if let currentUser = currentUser {
            let user = currentUser.user
            // add just created to motive and users
            motiveAndUsers.append(MotiveAndUser(motive: motive, user: user))
            motiveHashTableDelegate?.storeMotive(motive: motive)
            // add to the map
            updateMapAnnotations()
            // select if the user just created
            selectMotive(motive: motive)
        }
    }
    
    

    // MARK: - Motive tranferring from tabBar and placing features on map
    // show loading when tab bar requests when tab bar starts loading its motives
    func showLoading() {
        showActivityIndicator()
    }
    
    // hide loading and set self.motives when tab bar finishes loading its motives
    func hideLoading() {
        hideActivityIndicator()
    }
    
    @objc func refreshPressed(_ sender: UIButton!) {
        delegate?.mapSentRefresh()
    }
    
    // feed or explore added more motives to table - add them to the map
    func addMotivesToMap(motiveAndUsers: [MotiveAndUser]) {
        for motiveAndUser in motiveAndUsers {
            if !motivesOnMap.contains(motiveAndUser.motive.id) {
                self.motiveAndUsers.append(motiveAndUser)
                self.motivesOnMap.insert(motiveAndUser.motive.id)
            }
        }
        updateMapAnnotations()
    }
    

    // update annotations on map
    func updateMapAnnotations() {
        var features: [MGLPointFeature] = []
        // iterate through motives gotten from Db
        motivesOnMap.removeAll()
        for (_, motiveAndUser) in self.motiveAndUsers.enumerated() {
            // if the motive is not contained in current annotation ID set add to map
            let motive = motiveAndUser.motive
            if !motivesOnMap.contains(motive.id) {
                motivesOnMap.insert(motiveAndUser.motive.id)
                // Initialize and add the point annotation.
                let coordinate = CLLocationCoordinate2DMake(motive.latitude, motive.longitude)
                let feature = MGLPointFeature()
                feature.coordinate = coordinate
                feature.identifier = motive.id
                feature.attributes = ["name":motive.id, "icon":motive.icon]
                features.append(feature)
            }
        }
        // assign shapes to sources
        if let source = self.mapView.style?.source(withIdentifier: "featureSource") as? MGLShapeSource {
            let collection = MGLShapeCollectionFeature(shapes: features)
            source.shape = collection
        }
        self.hideActivityIndicator()
    }


    // dummy stub
    func feedSentRefresh() {
        return
    }
    
    
    // cancel all subviews, set feed background view and select tab bar index 1 (feed)
    @objc func goToFeed(_ sender: UIButton) {
        if calloutViewShowing {
            calloutViewQueued = nil
            hideCalloutView(animated: false)
        }
        if feedButton.isHidden == false {
            feedButton.isHidden = true
        }
        if let pinchSnapshotView = self.view.snapshotView(afterScreenUpdates: true) {
            if let tabBarViews = self.tabBarController?.viewControllers {
                if tabBarViews.count >= 2 {
                    if let navigationViewController = tabBarViews[sender.tag] as? UINavigationController {
                        if let feedViewController = navigationViewController.visibleViewController as? FeedViewController {
                            let blurSnapshotView = self.applyBlurEffect(toView: pinchSnapshotView)
                            feedViewController.pinchView.removeFromSuperview()
                            feedViewController.pinchView = blurSnapshotView
                            feedViewController.setupPinchView()
                        }
                    }
                }
            }
        }

        self.tabBarController?.selectedIndex = sender.tag
    }
    
    @objc func centerOnUserLocation(_ sender: UIButton!) {
        // deselect annotation
        for annotation in mapView.selectedAnnotations {
            mapView.deselectAnnotation(annotation, animated: true)
        }
        // center on user location
        locationManager.startUpdatingLocation()
    
    }
    
    // view pinched and went to map view
    func viewPinched() {
        self.navigationController?.popToRootViewController(animated: false)
    }
    
}

// MARK: - callout view extension and functionalities
extension MapViewController: CalloutViewDelegate {
    
    // show motive detail view
    func calloutPressed() {
        guard let motive = calloutView.motiveAndUser?.motive else { return }
        guard let user = calloutView.motiveAndUser?.user else { return }
        displayViewControllerForMotive(motive: motive, creator: user)
    }
    
    func profileImagePressed(user: User) {
        if let snapshotView = self.view.snapshotView(afterScreenUpdates: true) {
            if let pinchSnapshotView = self.view.snapshotView(afterScreenUpdates: true) {
                let userViewController = storyboard?.instantiateViewController(withIdentifier: "userViewController") as! UserViewController
                userViewController.backgroundView = snapshotView
                userViewController.pinchView = pinchSnapshotView
                userViewController.uid = user.uid
                userViewController.user = user
                self.navigationController?.pushViewController(userViewController, animated: true)
            }
        }
    }
    
    func commentsPressed(motive: Motive) {
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
    
    func goingPressed(motive: Motive) {
        // does animation in view
        // add to tabbar controller set of going
        (tabBarController as? CustomTabBarController)?.userMotiveGoingSet.insert(motive.id)
        motiveHashTableDelegate?.storeMotive(motive: motive)
        calloutView.goingLabel.setTitle(" " + String(motive.numGoing) + " going", for: .normal)
        calloutView.goingLabel.setTitle(" " + String(motive.numGoing) + " going", for: .highlighted)
        calloutView.motiveAndUser?.motive = motive
        calloutView.setupUserGoing()
        calloutView.goingLabel.sizeToFit()
        calloutView.goingLabelWidthConstraint.constant = calloutView.goingLabel.frame.width + 15
    }
    
    func unGoPressed(motive: Motive) {
        // remove from tab bar controller set of going
        (tabBarController as? CustomTabBarController)?.userMotiveGoingSet.remove(motive.id)
        motiveHashTableDelegate?.storeMotive(motive: motive)
        calloutView.goingLabel.setTitle(" " + String(motive.numGoing) + " going", for: .normal)
        calloutView.goingLabel.setTitle(" " + String(motive.numGoing) + " going", for: .highlighted)
        calloutView.motiveAndUser?.motive = motive
        calloutView.setupUserNotGoing()
        calloutView.goingLabel.sizeToFit()
        calloutView.goingLabelWidthConstraint.constant = calloutView.goingLabel.frame.width + 15
    }
    
    // function to change the constant value of calloutTopConstraint to animate the calloutview going down
    func hideCalloutView(animated: Bool) {
        // hide callout view
        calloutViewShowing = false
        view.layoutIfNeeded()
        if animated {
            UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveEaseOut, animations: {
                self.calloutTopConstraint.constant = 0
                self.view.layoutIfNeeded()
                self.centerButton.alpha = 1.0
                self.refreshButton.alpha = 1.0
                self.activityIndicator.alpha = 1.0
            }) { (completed) in
                self.calloutView.isHidden = true
                self.centerButton.isHidden = false
                // if there is another view that sohuld be shown
                if let motiveAndUser = self.calloutViewQueued {
                    // remove the queued view
                    self.calloutViewQueued = nil
                    self.showCalloutView(motiveAndUser: motiveAndUser, animated: true)
                }
            }
        } else {
            self.calloutTopConstraint.constant = 0
            self.view.layoutIfNeeded()
            self.centerButton.alpha = 1.0
            self.refreshButton.alpha = 1.0
            self.activityIndicator.alpha = 1.0
            self.calloutView.isHidden = true
            self.centerButton.isHidden = false
            // if there is another view that sohuld be shown
            if let motiveAndUser = self.calloutViewQueued {
                // remove the queued view
                self.calloutViewQueued = nil
                self.showCalloutView(motiveAndUser: motiveAndUser, animated: false)
            }
        }
    }
    
    // dequeue a calloutview
    func showCalloutView(motiveAndUser: MotiveAndUser, animated: Bool) {
        // load user details for post
        calloutView.motiveAndUser = motiveAndUser
        let user = motiveAndUser.user
        // create attributed text for title of motive feed (display + @username)
        let attrs1 = [NSAttributedStringKey.font : UIFont.boldSystemFont(ofSize: 16), NSAttributedStringKey.foregroundColor : UIColor.black]
        let attrs2 = [NSAttributedStringKey.font : UIFont.systemFont(ofSize: 16), NSAttributedStringKey.foregroundColor : UIColor(red: 153/255, green: 153/255, blue: 153/255, alpha: 1.0)]
        let attributedString1 = NSMutableAttributedString(string: user.display, attributes:attrs1)
        let attributedString2 = NSMutableAttributedString(string: " @" + user.username, attributes:attrs2)
        attributedString1.append(attributedString2)
        calloutView.titleLabel.attributedText = attributedString1
        // default while loading ** Fix
        calloutView.profileImageView.image = nil
        // download profile image
        if let url = URL(string: user.photoURL) {
            calloutView.profileImageView.sd_setImage(with: url) { (image, error, cache, urls) in
                if (error != nil) {
                    //Failure code here - defualt image
                    self.calloutView.profileImageView.image = nil
                } else {
                    //Success code here
                    self.calloutView.profileImageView.image = image
                }
            }
        }
        
        let motive = motiveAndUser.motive
        // setup time label
        calloutView.timeLabel.text = timestampToText(timestamp: motive.time)
        calloutView.timeLabel.sizeToFit()
        let textWidth = calloutView.timeLabel.frame.width + 5
        calloutView.timeLabel.frame = CGRect(x: calloutView.frame.width - textWidth - 10, y: 12, width: textWidth, height: 20)
        // adjust title based off time label
        calloutView.titleLabel.frame = CGRect(x: 70, y: 12, width: calloutView.frame.width - 78 - textWidth, height: 20)
        // load number of comments and adjust frame
        // set num comments label
        let numComments = motive.numComments
        calloutView.commentsLabel.setTitle(" " + numToText(num: numComments), for: .normal)
        calloutView.commentsLabel.setTitle(" " + numToText(num: numComments), for: .highlighted)
        calloutView.commentsLabel.sizeToFit()
        calloutView.commentsLabelWidthConstraint.constant = calloutView.commentsLabel.frame.width + 15
        // load number of people going and adjust frame
        calloutView.goingLabel.setTitle(" " + numToText(num: motive.numGoing) + " going", for: .normal)
        calloutView.goingLabel.setTitle(" " + numToText(num: motive.numGoing) + " going", for: .highlighted)
        calloutView.goingLabel.sizeToFit()
        calloutView.goingLabelWidthConstraint.constant = calloutView.goingLabel.frame.width + 15
        // determine if user is going to motive and setup accordingly
        if ((tabBarController as? CustomTabBarController)?.userMotiveGoingSet.contains(motive.id) ?? false) {
            calloutView.setupUserGoing()
            print ("going")
        } else {
            calloutView.setupUserNotGoing()
            print ("NOT going")
        }

        // setup motive text
        calloutView.motiveTextLabel.numberOfLines = 0
        calloutView.motiveTextLabel.text = motive.text
        var estimatedTextHeight = 32 + 40 + motive.text.height(withConstrainedWidth: calloutView.frame.width - 80, font: UIFont.systemFont(ofSize: 16))
        // if height of callout view is too big
        if estimatedTextHeight >= (self.view.frame.height / 3) - 16 {
            estimatedTextHeight = (self.view.frame.height / 3) - 16
            // cap number of lines based on 1/3 of screen height
            calloutView.motiveTextLabel.numberOfLines =  Int(((estimatedTextHeight - 72) / calloutView.motiveTextLabel.font.lineHeight))
        }
        // adjust height
        calloutHeightConstraint.constant = estimatedTextHeight
        calloutView.isHidden = false
        view.layoutIfNeeded()
        // change constraint
        if animated {
            UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveEaseOut, animations: {
                self.calloutTopConstraint.constant = -self.calloutHeightConstraint.constant - 16 - (self.tabBarController?.tabBar.frame.height)!
                self.view.layoutIfNeeded()
                self.centerButton.alpha = 0.0
                self.refreshButton.alpha = 0.0
                self.activityIndicator.alpha = 0.0
            }) { (completed) in
                
            }
        } else {
            self.calloutTopConstraint.constant = -self.calloutHeightConstraint.constant - 16 - (self.tabBarController?.tabBar.frame.height)!
            self.view.layoutIfNeeded()
            self.centerButton.alpha = 0.0
            self.refreshButton.alpha = 0.0
            self.activityIndicator.alpha = 0.0
        }
    }
    
    func feedSelectedMotive(motive: Motive) {
        selectMotive(motive: motive)
        feedButton.alpha = 1.0
        feedButton.isHidden = false
        feedButton.tag = 1
    }
    
    func selectMotive(motive: Motive) {
        self.navigationController?.popToRootViewController(animated: false)
        if let user = userHashTableDelegate?.retrieveUser(uid: motive.creator) {
            if calloutViewShowing {
                calloutViewQueued = MotiveAndUser(motive: motive, user: user)
                hideCalloutView(animated: false)
            } else {
                showCalloutView(motiveAndUser: MotiveAndUser(motive: motive, user: user), animated: false)
            }
            // instantly set mapviews camera
            let distance = min(1700, mapView.camera.altitude)
            let coordinate = CLLocationCoordinate2DMake(motive.latitude, motive.longitude)
            let camera = MGLMapCamera(lookingAtCenter: coordinate, fromDistance: distance, pitch: 0, heading: 0)
            mapView.setCamera(camera, animated: false)
            calloutViewShowing = true
        }
    }
    
}

// MARK: - Map delegate and map functionality
extension MapViewController: MGLMapViewDelegate {
    
    func mapView(_ mapView: MGLMapView, regionWillChangeAnimated animated: Bool) {
        if centerButton.isHidden {
            centerButton.isHidden = false
            UIView.animate(withDuration: 0.3, animations: {
                self.centerButton.alpha = 1.0
            }, completion: {
                (value: Bool) in
                self.centerButton.isHidden = false
            })
        }
        if feedButton.isHidden == false {
            UIView.animate(withDuration: 0.15, animations: {
                self.feedButton.alpha = 0.0
            }, completion: {
                (value: Bool) in
                self.feedButton.isHidden = true
            })
        }
        // hide callout view
        if calloutViewShowing {
            hideCalloutView(animated: true)
        }

        previouslySelectedMotive = ""
    }

    // Feature interaction
    @objc func handleMapTap(sender: UITapGestureRecognizer) {
        if sender.state == .ended {
            // Limit feature selection to just the following layer identifiers.
            let layerIdentifiers: Set = ["featureLayer"]
            let point = sender.location(in: sender.view!)
            // Get all features within a rect the size of a touch (44x44).
            let touchRect = CGRect(origin: point, size: .zero).insetBy(dx: -22.0, dy: -22.0)
            let touchCoordinate = mapView.convert(point, toCoordinateFrom: sender.view!)
            let touchLocation = CLLocation(latitude: touchCoordinate.latitude, longitude: touchCoordinate.longitude)
            let possibleFeatures = mapView.visibleFeatures(in: touchRect, styleLayerIdentifiers: Set(layerIdentifiers)).filter { $0 is MGLPointFeature }
            let closestFeatures = possibleFeatures.sorted(by: {
                return CLLocation(latitude: $0.coordinate.latitude, longitude: $0.coordinate.longitude).distance(from: touchLocation) < CLLocation(latitude: $1.coordinate.latitude, longitude: $1.coordinate.longitude).distance(from: touchLocation)
            })
            // select the feature if there is only one
            if possibleFeatures.count == 1 || mapView.zoomLevel >= mapView.maximumZoomLevel - 1 {
                if let feature = closestFeatures.first {
                    if let motive = self.motiveHashTableDelegate?.retrieveMotive(id: feature.identifier as! String) {
                        if let user = self.userHashTableDelegate?.retrieveUser(uid: motive.creator) {
                            // adjust camera and show callout view
                            // if there is a calloutViewAlready shown queue this tap to go next
                            if calloutViewShowing {
                                calloutViewQueued = MotiveAndUser(motive: motive, user: user)
                                hideCalloutView(animated: true)
                            } else {
                                showCalloutView(motiveAndUser: MotiveAndUser(motive: motive, user: user), animated: true)
                            }
                            let distance = min(1700, mapView.camera.altitude)
                            let camera = MGLMapCamera(lookingAtCenter: feature.coordinate, fromDistance: distance, pitch: 0, heading: 0)
                            // set the calloutviewshowing after the flight animation to prevent it from disappearing while flying
                            mapView.fly(to: camera, withDuration: 0.5) {
                                self.calloutViewShowing = true
                                /*let layer = self.mapView.style?.layer(withIdentifier: "featureLayer") as! MGLSymbolStyleLayer
                                let expression = NSExpression(format: "TERNARY(name = %@, 1.2, 1)", motive.id)
                                UIView.animate(withDuration: 0.5) {
                                    layer.iconScale = expression
                                }*/
                            }
                        }
                    }
                }
            // zoom to fit the features and dont select anything if there is more then one
            } else if possibleFeatures.count > 1 {
                if let first = possibleFeatures.first {
                    var northMost = first.coordinate.latitude
                    var eastMost = first.coordinate.longitude
                    var southMost = first.coordinate.latitude
                    var westMost = first.coordinate.longitude
                    for feature in possibleFeatures {
                        if feature.coordinate.latitude > northMost {
                            northMost = feature.coordinate.latitude
                        }
                        if feature.coordinate.latitude < southMost {
                            southMost = feature.coordinate.latitude
                        }
                        if feature.coordinate.longitude > eastMost {
                            eastMost = feature.coordinate.longitude
                        }
                        if feature.coordinate.longitude < westMost {
                            westMost = feature.coordinate.longitude
                        }
                    }
                    // make coordinates out of most
                    let sw = CLLocationCoordinate2DMake(southMost, westMost)
                    let ne = CLLocationCoordinate2DMake(northMost, eastMost)
                    zoomMapToFitCoordinates(sw: sw, ne: ne)
                }
            } else {
                // show circle where user tapped if there are no possible features
                let tapView = UIView(frame: touchRect)
                tapView.backgroundColor = UIColor.clear
                tapView.alpha = 0.4
                tapView.layer.cornerRadius = tapView.frame.height / 2
                tapView.layer.borderColor = UIColor.white.cgColor
                tapView.layer.borderWidth = 4
                let transform = CGAffineTransform.init(scaleX: 0.5, y: 0.5)
                transform.translatedBy(x: tapView.frame.width / 2, y: tapView.frame.height / 2)
                tapView.transform = transform
                mapView.addSubview(tapView)
                UIView.animate(withDuration: 0.35, delay: 0.0, options: .curveEaseOut, animations: {
                    tapView.alpha = 0.0
                    tapView.transform = CGAffineTransform.identity
                }) { (complete) in
                    tapView.removeFromSuperview()
                }
            }

            // delselect any annotations if any
            mapView.deselectAnnotation(mapView.selectedAnnotations.first, animated: true)
        }
    }
    
    func mapView(_ mapView: MGLMapView, didFinishLoading style: MGLStyle) {
        addMapSources()
        addTapGestureRecognizer()
    }
    
    // function to set the style for custom features on map
    func addMapSources() {
        // MGLMapView.style is optional, so you must guard against it not being set.
        guard let style = mapView.style else { return }
        // custom feature images
        let def = resizeImage(image: defaultAnnotation, targetSize: CGSize(width: 40, height: 40))
        let star = resizeImage(image: starAnnotation, targetSize: CGSize(width: 40, height: 40))
        let heart = resizeImage(image: heartAnnotation, targetSize: CGSize(width: 40, height: 40))
        let fire = resizeImage(image: fireAnnotation, targetSize: CGSize(width: 40, height: 40))
        let money = resizeImage(image: moneyAnnotation, targetSize: CGSize(width: 40, height: 40))
        let beer = resizeImage(image: beerAnnotation, targetSize: CGSize(width: 40, height: 40))
        let wine = resizeImage(image: wineAnnotation, targetSize: CGSize(width: 40, height: 40))
        let coffee = resizeImage(image: coffeeAnnotation, targetSize: CGSize(width: 40, height: 40))
        let cutlery = resizeImage(image: cutleryAnnotation, targetSize: CGSize(width: 40, height: 40))
        let music = resizeImage(image: musicAnnotation, targetSize: CGSize(width: 40, height: 40))
        let ball = resizeImage(image: ballAnnotation, targetSize: CGSize(width: 40, height: 40))
        // set image identifier for style
        style.setImage(def, forName: "def")
        style.setImage(star, forName: "star")
        style.setImage(heart, forName: "heart")
        style.setImage(fire, forName: "fire")
        style.setImage(money, forName: "money")
        style.setImage(beer, forName: "beer")
        style.setImage(wine, forName: "wine")
        style.setImage(coffee, forName: "coffee")
        style.setImage(cutlery, forName: "cutlery")
        style.setImage(music, forName: "music")
        style.setImage(ball, forName: "ball")
        
        // Add the features to the map as a shape source.
        let features = [MGLPointFeature]()
        let featureSource = MGLShapeSource(identifier: "featureSource", features: features, options: nil)
        // add sources to style
        style.addSource(featureSource)
        // add predicate stops to the iconImageName of the layer
        let stops = [1: "def",
                     2: "star",
                     3: "heart",
                     4: "fire",
                     5: "money",
                     6: "beer",
                     7: "wine",
                     8: "coffee",
                     9: "cutlery",
                     10: "music",
                     11: "ball"]
        let featureLayer = MGLSymbolStyleLayer(identifier: "featureLayer", source: featureSource)
        featureLayer.iconAllowsOverlap = NSExpression(forConstantValue: "YES")
        featureLayer.iconIgnoresPlacement = NSExpression(forConstantValue: "YES")
        //featureLayer.iconImageName = NSExpression(forConstantValue: "star")
        featureLayer.iconAnchor = NSExpression(forConstantValue: "bottom")
        featureLayer.iconScale = NSExpression(format: "mgl_interpolate:withCurveType:parameters:stops:($zoomLevel, 'linear', nil, %@)", [10: 0.5, 14: 1])
        featureLayer.iconImageName = NSExpression(format: "FUNCTION(icon, 'mgl_stepWithMinimum:stops:', '', %@)", stops)
        style.addLayer(featureLayer)
    }
    
    // add feature interaction
    func addTapGestureRecognizer() {
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(handleMapTap(sender:)))
        for recognizer in mapView.gestureRecognizers! where recognizer is UITapGestureRecognizer {
            singleTap.require(toFail: recognizer)
        }
        mapView.addGestureRecognizer(singleTap)
    }
    
    // changes map region to fit all the annotations in a rect with edge insets
    func zoomMapToFitCoordinates(sw: CLLocationCoordinate2D, ne: CLLocationCoordinate2D) {
        let rect = MGLCoordinateBoundsMake(sw, ne)
        let camera = mapView.cameraThatFitsCoordinateBounds(rect, edgePadding: UIEdgeInsetsMake(175, 80, 100, 80))
        mapView.fly(to: camera, withDuration: 0.5) {
            
        }
    }
    
    // https://stackoverflow.com/questions/42378051/animate-cashapelayer-path-change
    func animatePathChangeIn(for layer: CAShapeLayer, toPath: CGPath) {
        let animation = CABasicAnimation(keyPath: "path")
        animation.duration = 0.3
        animation.fromValue = layer.path
        animation.toValue = toPath
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        layer.add(animation, forKey: "path")
        layer.path = toPath
    }
    
    func animatePathChangeOut(for layer: CAShapeLayer, toPath: CGPath) {
        let animation = CABasicAnimation(keyPath: "path")
        animation.duration = 0.3
        animation.fromValue = layer.path
        animation.toValue = toPath
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn)
        layer.add(animation, forKey: "path")
        layer.path = toPath
    }

    
    // delegate functions
    // display going from motive ID - chain delegate from Motive View and annotation view
    func displayGoingForMotive(motive: Motive) {
        // push a friend view controller with going type
    }
    // display view controller for motive
    func displayViewControllerForMotive(motive: Motive, creator: User) {
        if let snapshotView = self.view.snapshotView(afterScreenUpdates: true) {
            if let pinchSnapshotView = self.view.snapshotView(afterScreenUpdates: true) {
                let motiveViewController = storyboard?.instantiateViewController(withIdentifier: "motiveViewController") as! MotiveViewController
                motiveViewController.backgroundView = snapshotView
                motiveViewController.pinchView = pinchSnapshotView
                motiveViewController.pinchDelegate = self
                motiveViewController.motive = motive
                motiveViewController.creator = creator
                motiveViewController.calloutViewDelegate = self
                self.navigationController?.pushViewController(motiveViewController, animated: true)
            }
        }
    }
    
    func showActivityIndicator() {
        refreshButton.isEnabled = false
        refreshButton.imageView?.isHidden = true
        calloutViewShowing = false
        activityIndicator.startAnimating()
    }
    
    func hideActivityIndicator() {
        refreshButton.isEnabled = true
        refreshButton.imageView?.isHidden = false
        // the callout view is now showing
        calloutViewShowing = true
        activityIndicator.stopAnimating()
    }
    
}

extension MapViewController: ExploreDelegate {
    
    func exploreSentRefresh() {
        return
    }
    func exploreGetMoreMotives() {
        return
    }
    
    func exploreSelectedMotive(motive: Motive) {
        selectMotive(motive: motive)
        feedButton.alpha = 1.0
        feedButton.isHidden = false
        feedButton.tag = 2
    }
    
    
}

// MARK: - slider extension and functions
extension MapViewController: SliderDelegate {
    
    @IBAction func hamburgerButtonPressed(_ sender: Any) {
        let sliderViewController = storyboard?.instantiateViewController(withIdentifier: "sliderViewController") as! SliderViewController
        // if tab bar has a user take it
        if let tabBarCurrentUser = self.currentUserDelegate?.retrieveCurrentUser() {
            self.currentUser = tabBarCurrentUser
        } else {
            if let currentUserUid = Auth.auth().currentUser?.uid {
                // get the signed in users profile
                getCurrentUser(uid: currentUserUid) { (result) in
                    if let newCurrentUser = result {
                        // store the result
                        self.currentUser = newCurrentUser
                        self.currentUserDelegate?.storeCurrentUser(currentUser: newCurrentUser)
                        self.userHashTableDelegate?.storeUser(user: newCurrentUser.user)
                        // load profile done from here - stop activity indicator spinning
                        sliderViewController.currentUser = newCurrentUser
                        // load user data from this view once it is done loading
                        sliderViewController.loadUserProfile()
                        sliderViewController.tableView.reloadData()
                    }
                }
            }
        }
        sliderViewController.hidesBottomBarWhenPushed = true
        sliderViewController.delegate = self
        sliderViewController.modalPresentationStyle = .overCurrentContext
        sliderViewController.currentUser = currentUser
        // push slider view onto current view
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
            feedButton.tag = 1
            goToFeed(feedButton)
        // explore
        case 2:
            feedButton.tag = 2
            goToFeed(feedButton)
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
                if let pinchSnapshotView = self.view.snapshotView(afterScreenUpdates: true) {
                    let userViewController = storyboard?.instantiateViewController(withIdentifier: "userViewController") as! UserViewController
                    userViewController.backgroundView = snapshotView
                    userViewController.pinchView = pinchSnapshotView
                    userViewController.uid = currentUser.user.uid
                    userViewController.user = currentUser.user
                    userViewController.pinchDelegate = self
                    self.navigationController?.pushViewController(userViewController, animated: true)
                }
            }
        }
    }
    // push current users followers view onto navigation view stack
    func pushFollowers() {
        if let user = currentUser {
            if let snapshotView = self.view.snapshotView(afterScreenUpdates: true) {
                if let pinchSnapshotView = self.view.snapshotView(afterScreenUpdates: true) {
                    let friendViewController = storyboard?.instantiateViewController(withIdentifier: "friendViewController") as! FriendViewController
                    friendViewController.backgroundView = snapshotView
                    friendViewController.pinchView = pinchSnapshotView
                    friendViewController.pinchDelegate = self
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
                if let pinchSnapshotView = self.view.snapshotView(afterScreenUpdates: true) {
                    let friendViewController = storyboard?.instantiateViewController(withIdentifier: "friendViewController") as! FriendViewController
                    friendViewController.backgroundView = snapshotView
                    friendViewController.pinchView = pinchSnapshotView
                    friendViewController.pinchDelegate = self
                    friendViewController.type = .following
                    friendViewController.id = user.user.uid
        
                    self.navigationController?.pushViewController(friendViewController, animated: true)
                }
            }
        }
    }
    func pushSettings() {
        if let snapshotView = self.view.snapshotView(afterScreenUpdates: true) {
            if let pinchSnapshotView = self.view.snapshotView(afterScreenUpdates: true) {
                let settingsViewController = storyboard?.instantiateViewController(withIdentifier: "settingsViewController") as! SettingsViewController
                settingsViewController.backgroundView = snapshotView
                settingsViewController.pinchView = pinchSnapshotView
                settingsViewController.pinchDelegate = self
                self.navigationController?.pushViewController(settingsViewController, animated: true)
            }
        }    
    }
    func pushFollowRequests() {
        if let currentUser = currentUser {
            if let snapshotView = self.view.snapshotView(afterScreenUpdates: true) {
                if let pinchSnapshotView = self.view.snapshotView(afterScreenUpdates: true) {
                    let requestsViewController = storyboard?.instantiateViewController(withIdentifier: "requestsViewController") as! RequestsViewController
                    requestsViewController.backgroundView = snapshotView
                    requestsViewController.pinchView = pinchSnapshotView
                    requestsViewController.pinchDelegate = self
                    requestsViewController.currentUser = currentUser
                    self.navigationController?.pushViewController(requestsViewController, animated: true)
                }
            }
        }
    }

}

// TEST FUNCTIONS
extension MapViewController {
    
    
    func REMOVE_ARCHIVE() {
        let archiveReference = Database.database().reference(withPath: "archive")
        archiveReference.removeValue()
        let archiveGoingReference = Database.database().reference(withPath: "archiveGoing")
        archiveGoingReference.removeValue()
    }

    func TEST_CREATE_MOTIVES(num: Int) {
        var i = 0
        // lat 43.53948731583682
        // long 80.2230372522435
        guard let uid = Auth.auth().currentUser?.uid else {
            // error handle if user is not signed in
            return
        }
        while i < num {
            let motiveReference = self.motivesReference.childByAutoId()
            let motiveID = motiveReference.key
            let timestamp = Int64(NSDate().timeIntervalSince1970 * -1000)
            let newMotive = [
                "id": motiveID,
                "creator": uid,
                "time": timestamp,
                "text": "TEST_MOTIVE",
                "numGoing": 0,
                "latitude": 43.53948731583682 + CGFloat(Float(arc4random()) / Float(UINT32_MAX)) - CGFloat(Float(arc4random()) / Float(UINT32_MAX)),
                "longitude": -80.2230372522435 - CGFloat(Float(arc4random()) / Float(UINT32_MAX)) + CGFloat(Float(arc4random()) / Float(UINT32_MAX)),
                "icon": arc4random_uniform(1) + 2
                ] as [String:Any]
            motiveReference.setValue(newMotive)
            i += 1
        }
    }
    
    func TEST_CREATE_USERS(num: Int) {
        var i = 0
        while i < num {
            let userReference = self.usersReference.childByAutoId()
            let uid = userReference.key
            let latitude = 43.61912036
            let longitude = -79.44891133
            let userObject = [
                "uid": uid,
                "username": "testuser" + String(i),
                "display": "TEST_" + String(i),
                "email": "noemail@gmail.com",
                "pointLatitude": latitude,
                "pointLongitude": longitude,
                "zoomLevel": 15,
                "photoURL": "idk what to put here"
                ] as [String:Any]
            userReference.setValue(userObject)
            i += 1
        }
    }
    
    func FOLLOW_EVERYONE() {
        let kFollowersListPath = "followers"
        let followersReference = Database.database().reference(withPath: kFollowersListPath)
        let kFollowingListPath = "following"
        let followingReference = Database.database().reference(withPath: kFollowingListPath)
        var userIds: [String] = []
        usersReference.observeSingleEvent(of: .value) { (snapshot) in
            for item in snapshot.children.allObjects as! [DataSnapshot] {
                userIds.append(item.key)
            }
            for uid in userIds {
                for uid2 in userIds {
                    if uid != uid2 {
                        let timestamp = Int64(NSDate().timeIntervalSince1970 * -1000)
                        followersReference.child(uid).child(uid2).setValue(timestamp)
                        followingReference.child(uid2).child(uid).setValue(timestamp)
                    }
                }
            }
        }
    }
    
    func EVERYONE_FOLLOW_CURRENT() {
        let kFollowersListPath = "followers"
        let followersReference = Database.database().reference(withPath: kFollowersListPath)
        let kFollowingListPath = "following"
        let followingReference = Database.database().reference(withPath: kFollowingListPath)
        var userIds: [String] = []
        if let currentUserUid = Auth.auth().currentUser?.uid {
            usersReference.observeSingleEvent(of: .value) { (snapshot) in
                for item in snapshot.children.allObjects as! [DataSnapshot] {
                    userIds.append(item.key)
                }
                for uid in userIds {
                    let timestamp = Int64(NSDate().timeIntervalSince1970 * -1000)
                    followersReference.child(currentUserUid).child(uid).setValue(timestamp)
                    followingReference.child(uid).child(currentUserUid).setValue(timestamp)
                    
                }
            }
        }
    }
    
    func UPDATE_USERNAME_DIRECTORY() {
        let usernameReference = Database.database().reference(withPath: "username")
        usersReference.observeSingleEvent(of: .value) { (usersSnapshot) in
            var users: [User] = []
            var snapshotArray: [DataSnapshot] = []
            for item in usersSnapshot.children {
                let snap = item as! DataSnapshot
                snapshotArray.append(snap)
            }
            let myGroup = DispatchGroup()
            // load users from values
            for (_, usernameSnapshot) in snapshotArray.enumerated() {
                myGroup.enter()
                let uid = usernameSnapshot.key
                // if not in hashtable then load from firebase and store in hashtable
                self.getUser(uid: uid) { (result) in
                    if let user = result {
                        self.userHashTableDelegate?.storeUser(user: user)
                        users.append(user)
                    }
                    myGroup.leave()
                }
            }
            
            myGroup.notify(queue: .main) {
                for user in users {
                    usernameReference.child(user.username.lowercased()).setValue(user.uid)
                }
            }
        }
    }
    
    // add numfollowers and numfollowing to every user
    func ADD_NUM_COMMENTS() {
        let kUsersListPath = "archive"
        let motivesReference = Database.database().reference(withPath: kUsersListPath)
        
        motivesReference.observeSingleEvent(of: .value) { (usersSnapshot) in
            var snapshotArray: [DataSnapshot] = []
            for item in usersSnapshot.children {
                let snap = item as! DataSnapshot
                snapshotArray.append(snap)
            }
            let myGroup = DispatchGroup()
            for (_, usernameSnapshot) in snapshotArray.enumerated() {
                let uid = usernameSnapshot.key
                myGroup.enter()
                motivesReference.child(uid).child("nC").setValue(0) { error, ref in
                    myGroup.leave()
                }
            }
            myGroup.notify(queue: .main) {
                print ("fini chap")
                return
            }
        }
    }
    func SHORTEN_DB_NAMES() {
        let kUsersListPath = "users"
        let usersReference = Database.database().reference(withPath: kUsersListPath)
        usersReference.observeSingleEvent(of: .value) { (usersSnapshot) in
            let myGroup = DispatchGroup()
            for item in usersSnapshot.children {
                myGroup.enter()
                let snap = item as! DataSnapshot
                let user = User(snapshot: snap)
                let uid = user.uid
                usersReference.child(uid).child("nFers").setValue(0) { error, ref in
                    usersReference.child(uid).child("nFing").setValue(0) { error, ref in
                        usersReference.child(uid).child("pLat").setValue(user.pointLatitude) { error, ref in
                            usersReference.child(uid).child("pLong").setValue(user.pointLongitude) { error, ref in
                                usersReference.child(uid).child("un").setValue(user.username) { error, ref in
                                    usersReference.child(uid).child("zl").setValue(user.zoomLevel) { error, ref in
                                        usersReference.child(uid).child("pURL").setValue(user.photoURL) { error, ref in
                                            usersReference.child(uid).child("dis").setValue(user.display) { error, ref in
                                                myGroup.leave()
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            myGroup.notify(queue: .main) {
                print ("fini chap")
                return
            }
        }
    }
    func REMOVE_DB_NAMES() {
        let kUsersListPath = "users"
        let usersReference = Database.database().reference(withPath: kUsersListPath)
        usersReference.observeSingleEvent(of: .value) { (usersSnapshot) in
            let myGroup = DispatchGroup()
            for item in usersSnapshot.children {
                myGroup.enter()
                let snap = item as! DataSnapshot
                let user = User(snapshot: snap)
                let uid = user.uid
                usersReference.child(uid).child("numFollowers").removeValue() { error, ref in
                    usersReference.child(uid).child("numFollowing").removeValue() { error, ref in
                        usersReference.child(uid).child("pointLatitude").removeValue() { error, ref in
                            usersReference.child(uid).child("pointLongitude").removeValue() { error, ref in
                                usersReference.child(uid).child("username").removeValue() { error, ref in
                                    usersReference.child(uid).child("zoomLevel").removeValue() { error, ref in
                                        usersReference.child(uid).child("photoURL").removeValue() { error, ref in
                                            usersReference.child(uid).child("display").removeValue() { error, ref in
                                                myGroup.leave()
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            myGroup.notify(queue: .main) {
                print ("fini chap")
                return
            }
        }
    }
    
    func EVERYONE_GO_TO_MOTIVE(motive: Motive) {
        let kUsersListPath = "users"
        let usersReference = Database.database().reference(withPath: kUsersListPath)
        let kMotivesGoingListPath = "motivesGoing"
        let motivesGoingReference = Database.database().reference(withPath: kMotivesGoingListPath)
        usersReference.observeSingleEvent(of: .value) { (usersSnapshot) in
            let myGroup = DispatchGroup()
            for item in usersSnapshot.children {
                myGroup.enter()
                let snap = item as! DataSnapshot
                let user = User(snapshot: snap)
                let uid = user.uid
                motivesGoingReference.child(motive.id).child(uid).setValue(Int64(NSDate().timeIntervalSince1970 * -1000)) { error, ref in
                    
                }
            }
            myGroup.notify(queue: .main) {
                print ("fini chap")
                return
            }
        }
    }
}


