//
//  ChooseLocationViewController.swift
//  wyd
//
//  Created by Jason Ellul on 2018-06-04.
//  Copyright © 2018 Jason Ellul. All rights reserved.
//

import UIKit
import MapKit
import Mapbox
import CoreLocation
import Firebase

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

protocol ChooseLocationDelegate {
    func panToNewMotiveAndSelect(motive: Motive)
    func chooseLocationCancelled(currentCamera: MGLMapCamera, centerButtonIsHidden: Bool)
}

class ChooseLocationViewController: UIViewController, CLLocationManagerDelegate {
 
    var delegate: ChooseLocationDelegate?

    // firebase db refs
    static let kUsersListPath = "users"
    let usersReference = Database.database().reference(withPath: kUsersListPath)
    static let kMotivesListPath = "motives"
    let motivesReference = Database.database().reference(withPath: kMotivesListPath)
    static let kUsersPostListPath = "usersPost"
    let usersPostReference = Database.database().reference(withPath: kUsersPostListPath)

    // default on home map region
    var currentRegion = MKCoordinateRegion()
    var currentCamera = MGLMapCamera()
    var firstLoad = true
    // user location manager
    let locationManager = CLLocationManager()

    // details about the motive the user is creating
    // lat and long gathered in this window
    var motiveLatitude = 0.0
    var motiveLongitude = 0.0
    // name and description gathered in next window
    var motiveText = ""
    var motiveIcon = 1
    
    // move pressHoldView
    var firstTimePressed = true
    // if changing the region will resign first responder of bottom view
    var regionChangeCancelsKeyboard: Bool = false
    var keyboardHeight: CGFloat = 0
    // ui kit members
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var headerViewHeightConstraint: NSLayoutConstraint!
    // MapBox view
    let mapView: MGLMapView = {
        let url = URL(string: "mapbox://styles/mapbox/streets-v10")
        let map = MGLMapView(frame: CGRect(x: 0, y: 75, width: 128, height: 128), styleURL: url)
        map.styleURL = url
        map.isPitchEnabled = false
        map.isRotateEnabled = false
        map.userLocation?.title = ""
        map.showsUserLocation = true
        map.translatesAutoresizingMaskIntoConstraints = true
        return map
    }()
    
    let pressHoldView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isUserInteractionEnabled = false
        view.backgroundColor = UIColor.white
        view.layer.cornerRadius = 30
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.30
        view.layer.shadowOffset = CGSize.zero
        view.layer.shadowRadius = 2
        view.alpha = 1.0
        return view
    }()
    
    var centerButtonVisible = true
    let centerButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("", for: .normal)
        button.layer.borderWidth = 0
        button.layer.cornerRadius = 15
        button.backgroundColor = UIColor.clear
        let image = #imageLiteral(resourceName: "gps-fixed-indicator.png")
        button.setImage(image, for: .normal)
        button.setImage(image, for: UIControlState.highlighted)
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.30
        button.layer.shadowOffset = CGSize.zero
        button.layer.shadowRadius = 2
        button.isHidden = true
        return button
    }()
    
    let holdLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = UIColor(red: 153/255, green: 153/255, blue: 153/255, alpha: 1.0)
        label.font = UIFont.systemFont(ofSize: 10)
        label.text = "Tap to Change Location"
        label.textAlignment = .center
        return label
    }()
    
    let pointFeature: MGLPointFeature = {
        let annotation = MGLPointFeature()
        annotation.attributes = ["name":"", "icon":1]

        return annotation
    }()
    
    // custom input accessory view above keyboard
    lazy var bottomView: CustomInputAccessoryView = {
        let custom = CustomInputAccessoryView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 100))
        custom.customInputAccessoryDelegate = self
        custom.customInputAccesoryInLocationViewDelegate = self
        // choose location view modifiers
        custom.inChooseLocationView = true
        // set placeholder text
        custom.placeholderText = "What's the Motive?"
        custom.textView.text = "What's the Motive?"
        // add icon bar
        custom.setupSubviews()
        custom.addIconBar()
        return custom
    }()
    // https://www.youtube.com/watch?v=ky7YRh01by8
    override var inputAccessoryView: UIView? {
        get {
            return bottomView
        }
    }
    override var canBecomeFirstResponder: Bool { return true }

    
    // view did load method
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        setupSubviews()
        mapView.reloadStyle(mapView)

        mapView.setCamera(currentCamera, animated: false)
        // set initial location on centre of map view
        /*let centerCoordinate = currentCamera.centerCoordinate
        self.motiveLatitude = centerCoordinate.latitude
        self.motiveLongitude = centerCoordinate.longitude
        pointFeature.coordinate = centerCoordinate
        // replace current shape
        if let source = self.mapView.style?.source(withIdentifier: "featureSource") as? MGLShapeSource {
            let collection = MGLShapeCollectionFeature(shapes: [pointFeature])
            source.shape = collection
        }
        // refresh and add address
        updatePointAddress()*/
        // setup location delegate
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        // set visiblity from map controller
        centerButton.isHidden = centerButtonVisible
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: Notification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: Notification.Name.UIKeyboardWillHide, object: nil)

        let tapRecogniser = UITapGestureRecognizer(target: self, action: #selector(ChooseLocationViewController.pointMapPressed(_:)))
        mapView.addGestureRecognizer(tapRecogniser)
        
        //startPulseAnimation()
     
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        // Don't have to do this on iOS 9+, but it still works
        NotificationCenter.default.removeObserver(self)
    }
    
    
    func setupSubviews() {
        headerView.frame.size.height = 75
        if self.isPhoneX() {
            print ("iphoneX")
            headerViewHeightConstraint.constant = 100
            headerView.frame.size.height = 100
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
        
        
        mapView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)
        mapView.setContentInset(UIEdgeInsets.zero, animated: false)
        view.addSubview(mapView)
        view.sendSubview(toBack: mapView)
        
        mapView.addSubview(pressHoldView)
        pressHoldView.centerYAnchor.constraint(equalTo: mapView.centerYAnchor, constant: mapView.frame.height / -4).isActive = true
        pressHoldView.centerXAnchor.constraint(equalTo: mapView.centerXAnchor).isActive = true
        pressHoldView.widthAnchor.constraint(equalToConstant: 60).isActive = true
        pressHoldView.heightAnchor.constraint(equalToConstant: 60).isActive = true
        
        self.pressHoldView.addSubview(holdLabel)
        holdLabel.centerYAnchor.constraint(equalTo: self.pressHoldView.centerYAnchor).isActive = true
        holdLabel.centerXAnchor.constraint(equalTo: self.pressHoldView.centerXAnchor).isActive = true
        holdLabel.widthAnchor.constraint(equalToConstant: 60).isActive = true
        holdLabel.heightAnchor.constraint(equalToConstant: 60).isActive = true
        holdLabel.numberOfLines = 0
 
        mapView.addSubview(centerButton)
        centerButton.bottomAnchor.constraint(equalTo: mapView.bottomAnchor, constant: -14.5).isActive = true
        centerButton.rightAnchor.constraint(equalTo: mapView.rightAnchor, constant: -14.5).isActive = true
        centerButton.widthAnchor.constraint(equalToConstant: 30).isActive = true
        centerButton.heightAnchor.constraint(equalToConstant: 30).isActive = true
        centerButton.addTarget(self, action: #selector(ChooseLocationViewController.centerOnUserLocation(_:)), for: .touchUpInside)
        
        // download and set profile image of input accessory view
        if let currentUser = (tabBarController as? CustomTabBarController)?.currentUser {
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
    // pulse animation for press anywhere view
    func startPulseAnimation() {
        firstTimePressed = false
        UIView.animate(withDuration: 1.5, delay: 0.0, options: [.repeat, .autoreverse], animations: {
            self.pressHoldView.transform = CGAffineTransform(scaleX: 1.12, y: 1.12)
            //self.pressHoldView.layer.transform = CATransform3DMakeScale(1.1, 1.1, 1.0)

        }, completion: nil)
        
    }
    
    // set the map region to the users current location
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations[0]
        let userLocation: CLLocationCoordinate2D = CLLocationCoordinate2DMake(location.coordinate.latitude, location.coordinate.longitude)
        self.mapView.showsUserLocation = true
        self.motiveLatitude = location.coordinate.latitude
        self.motiveLongitude = location.coordinate.longitude
        //let address = getAddressLabel()
        let coordinate = CLLocationCoordinate2DMake(motiveLatitude, motiveLongitude)
        pointFeature.coordinate = coordinate
        // replace current shape
        if let source = self.mapView.style?.source(withIdentifier: "featureSource") as? MGLShapeSource {
            let collection = MGLShapeCollectionFeature(shapes: [pointFeature])
            source.shape = collection
        }
        // refresh and add address
        updatePointAddress()
        // hide center button once its pressed
        if !firstLoad {
            if centerButton.isHidden == false {
                UIView.animate(withDuration: 0.3, animations: {
                    self.centerButton.alpha = 0.0
                }, completion: {
                    (value: Bool) in
                    self.centerButton.isHidden = true
                })
            }
            // zoom into user location
            mapView.setCenter(userLocation, zoomLevel: max(14, mapView.zoomLevel), direction: 0, animated: true)
        } else {
            // once first load is complete, make center button visible and make it center in on user location
            firstLoad = false
        }
        // dont update the map based on location anymore
        locationManager.stopUpdatingLocation()
    }
    
    

    func showCenterButton() {
        if centerButton.isHidden {
            print ("moved")
            centerButton.alpha = 0.0
            centerButton.isHidden = false
            UIView.animate(withDuration: 0.3, animations: {
                self.centerButton.alpha = 1.0
            }, completion: {
                (value: Bool) in
                self.centerButton.isHidden = false
            })
        }
    }
    
    // everytime map is tapped, new annotations
    @objc func pointMapPressed(_ gestureRecognizer : UITapGestureRecognizer){
        if gestureRecognizer.state != .ended { return }
        //mapView.removeAnnotations(mapView.annotations!)
        //let address = getAddressLabel()
        let touchPoint = gestureRecognizer.location(in: mapView)
        let touchMapCoordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)
        motiveLatitude = touchMapCoordinate.latitude
        motiveLongitude = touchMapCoordinate.longitude
        let coordinate = CLLocationCoordinate2DMake(motiveLatitude, motiveLongitude)
        pointFeature.coordinate = coordinate
        pointFeature.attributes["name"] = ""
        // replace current shape
        if let source = self.mapView.style?.source(withIdentifier: "featureSource") as? MGLShapeSource {
            let collection = MGLShapeCollectionFeature(shapes: [self.pointFeature])
            source.shape = collection
        }
        // move camera if the user is typing
        if bottomView.textView.isFirstResponder {
            regionChangeCancelsKeyboard = false
            let currentCamera = mapView.camera
            let newCamera = MGLMapCamera(lookingAtCenter: pointFeature.coordinate, fromDistance: currentCamera.altitude, pitch: currentCamera.pitch, heading: currentCamera.heading)
            mapView.setContentInset(UIEdgeInsetsMake(0, 0, ((mapView.frame.height - keyboardHeight) / 2) + 100, 0), animated: true)
            mapView.fly(to: newCamera) {
                self.regionChangeCancelsKeyboard = true
            }
        }
        // remove instant annotation and add address annotation
        updatePointAddress()

        // animate away press and hold view
        if firstTimePressed {
            firstTimePressed = false
            UIView.animate(withDuration: 0.3, delay: 0.0, options: .curveEaseIn, animations: {
                //self.pressHoldView.alpha = 0.0
                self.pressHoldView.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
                self.holdLabel.alpha = 0.0
            }, completion: {(finished:Bool) in
                // animation finishes
                self.pressHoldView.removeFromSuperview()
            })
        }
        showCenterButton()
    }

    
    @objc func centerOnUserLocation(_ sender: UIButton) {
        // center on user location
        locationManager.startUpdatingLocation()
    }

    func updatePointAddress() {
        var address = ""
        let geocoder = CLGeocoder()
        // Look up the location and pass it to the completion handler
        let coord = CLLocation(latitude: self.motiveLatitude, longitude: self.motiveLongitude)
        geocoder.reverseGeocodeLocation(coord, completionHandler: { (placemarks, error) in
            if error == nil {
                let firstLocation = placemarks?[0]
                if (firstLocation?.subThoroughfare != nil && firstLocation?.thoroughfare != nil) {
                    address = (firstLocation?.subThoroughfare)! + " " + (firstLocation?.thoroughfare)!
                } else if (firstLocation?.locality != nil) {
                    address = (firstLocation?.locality)!
                } else if (firstLocation?.inlandWater != nil) {
                    address = (firstLocation?.inlandWater)!
                } else if (firstLocation?.country != nil) {
                    address = (firstLocation?.country)!
                } else if (firstLocation?.ocean != nil) {
                    address = (firstLocation?.ocean)!
                } else {
                    address = ""
                }
            } else {
                // An error occurred during geocoding.
                print ("error while reverse geocoding")
                address = ""
            }
            self.pointFeature.attributes["name"] = address
            // replace current shape
            if let source = self.mapView.style?.source(withIdentifier: "featureSource") as? MGLShapeSource {
                let collection = MGLShapeCollectionFeature(shapes: [self.pointFeature])
                source.shape = collection
            }
        })
    }
 
    
    // cancel motive creation
    @IBAction func cancelButtonPressed(_ sender: Any) {
        delegate?.chooseLocationCancelled(currentCamera: mapView.camera, centerButtonIsHidden: centerButton.isHidden)
        self.navigationController?.popViewController(animated: true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

extension ChooseLocationViewController: MGLMapViewDelegate {
    
    // make center button visible
    func mapView(_ mapView: MGLMapView, regionWillChangeAnimated animated: Bool) {
        if !firstLoad {
            showCenterButton()
        }
        if regionChangeCancelsKeyboard {
            bottomView.textView.resignFirstResponder()
            mapView.setContentInset(UIEdgeInsets.zero, animated: true)
        }
    }
    
    func mapView(_ mapView: MGLMapView, didFinishLoading style: MGLStyle) {
        addItemsToMap(features: [pointFeature])
    }

    // function to set the style for custom features on map
    func addItemsToMap(features: [MGLPointFeature]) {
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
        // Use MGLSymbolStyleLayer for more complex styling of points including custom icons and text rendering.
        let featureLayer = MGLSymbolStyleLayer(identifier: "featureLayer", source: featureSource)
        featureLayer.iconAllowsOverlap = NSExpression(forConstantValue: "YES")
        featureLayer.iconIgnoresPlacement = NSExpression(forConstantValue: "YES")
        featureLayer.iconAnchor = NSExpression(forConstantValue: "bottom")
        featureLayer.iconScale = NSExpression(format: "mgl_interpolate:withCurveType:parameters:stops:($zoomLevel, 'linear', nil, %@)", [10: 0.5, 14: 1])
        featureLayer.iconImageName = NSExpression(format: "FUNCTION(icon, 'mgl_stepWithMinimum:stops:', '', %@)", stops)
        // address text
        featureLayer.textIgnoresPlacement = NSExpression(forConstantValue: "YES")
        featureLayer.textAllowsOverlap = NSExpression(forConstantValue: "YES")
        featureLayer.text = NSExpression(forKeyPath: "name")
        featureLayer.textColor = NSExpression(forConstantValue: UIColor.black)
        featureLayer.textFontSize = NSExpression(forConstantValue: 12)
        featureLayer.textTranslation = NSExpression(forConstantValue: NSValue(cgVector: CGVector(dx: 0, dy: 16)))
        featureLayer.textHaloColor = NSExpression(forConstantValue: UIColor.white.withAlphaComponent(0.5))
        featureLayer.textHaloWidth = NSExpression(forConstantValue: 1)
        featureLayer.textJustification = NSExpression(forConstantValue: NSValue(mglTextJustification: .center))
        featureLayer.textAnchor = NSExpression(forConstantValue: NSValue(mglTextAnchor: .bottom))
        style.addLayer(featureLayer)
    }
    
    
}


extension ChooseLocationViewController: CustomInputAccessoryDelegate, CustomInputAccessoryInLocationViewDelegate {
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            keyboardHeight = keyboardSize.height
            print ("end " + keyboardSize.height.description)
        }
        // animate away press and hold view
        if (self.firstTimePressed) {
            self.firstTimePressed = false
            UIView.animate(withDuration: 0.3, delay: 0.0, options: .curveEaseIn, animations: {
                //self.pressHoldView.alpha = 0.0
                self.pressHoldView.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
                self.holdLabel.alpha = 0.0
            }, completion: {(finished:Bool) in
                // animation finishes
                self.pressHoldView.removeFromSuperview()
            })
        }

    }
    @objc func keyboardWillHide(notification: NSNotification) {
        mapView.setContentInset(UIEdgeInsets.zero, animated: true)
    }
    
    func postMotive(text: String) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        let motiveReference = self.motivesReference.childByAutoId()
        let motiveID = motiveReference.key
        let timestamp = Int64(NSDate().timeIntervalSince1970 * -1000)
        let icon = self.bottomView.iconMenuChoice
        let newMotive = [
            "id": motiveID,
            "creator": uid,
            "time": timestamp,
            "text": text,
            "latitude": self.motiveLatitude,
            "longitude": self.motiveLongitude,
            "numGoing": 0,
            "nC": 0,
            "icon": icon
            
            ] as [String:Any]
        motiveReference.setValue(newMotive)
        // set users Post ref so that we can query on users profile
        usersPostReference.child(uid).child(motiveID).setValue(timestamp)
        // add to public postings if the user is not private
        let privateReference = Database.database().reference(withPath: "private")
        privateReference.child(uid).observeSingleEvent(of: .value, with: { (snapshot) in
            if !snapshot.exists() {
                // add to the public listing of posts
                let publicReference = Database.database().reference(withPath: "exploreMotives")
                publicReference.child(motiveID).setValue(timestamp)
            }
        })
        // pop view controller from naviagation stack and select new posted motive
        let motive = Motive(id: motiveID, text: text, creator: uid, latitude: self.motiveLatitude, longitude: self.motiveLongitude, time: timestamp, numGoing: 0, numComments: 0, icon: icon)
        //DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2), execute: {
        self.navigationController?.popViewController(animated: true)
        // tell map that we added a motive so next iteration of db it will select it
        delegate?.panToNewMotiveAndSelect(motive: motive)
    }
    
    func iconChanged() {
        pointFeature.attributes["icon"] = bottomView.iconMenuChoice
        // update map shapes
        if let source = self.mapView.style?.source(withIdentifier: "featureSource") as? MGLShapeSource {
            let collection = MGLShapeCollectionFeature(shapes: [pointFeature])
            source.shape = collection
        }
    }
    
    
    
    func postComment(text: String) {
        return
    }
    
    func textViewStartedEditing() {
        regionChangeCancelsKeyboard = false
        let currentCamera = mapView.camera
        let newCamera = MGLMapCamera(lookingAtCenter: pointFeature.coordinate, fromDistance: currentCamera.altitude, pitch: currentCamera.pitch, heading: currentCamera.heading)
        mapView.setContentInset(UIEdgeInsetsMake(0, 0, ((mapView.frame.height - keyboardHeight) / 2) + 100, 0), animated: true)
        mapView.fly(to: newCamera) {
            self.regionChangeCancelsKeyboard = true
        }
    }
    
    func textViewEndedEditing() {
        
    }

}
