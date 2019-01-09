//
//  PointViewController.swift
//  wyd
//
//  Created by Jason Ellul on 2018-05-30.
//  Copyright © 2018 Jason Ellul. All rights reserved.
//

import UIKit
import MapKit
import Mapbox

class PointViewController: UIViewController, MGLMapViewDelegate {
    
    // data to pass back to editProfileViewController
    var pointLatitude = 0.0
    var pointLongitude = 0.0
    var zoomLevel: Double = 15.0
    
    // animations
    var firstTimePressed = true
    lazy var animatedViewBottomConstraint = pressHoldView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -35)
    
    // ui kit members
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var headerViewHeightConstraint: NSLayoutConstraint!
    
    let mapView: MGLMapView = {
        let map = MGLMapView()
        map.translatesAutoresizingMaskIntoConstraints = false
        map.isPitchEnabled = false
        map.isRotateEnabled = false
        map.isUserInteractionEnabled = true
        return map
    }()
    
    let pointFeature: MGLPointFeature = {
        let annotation = MGLPointFeature()
        annotation.attributes = [
            "name": ""
        ]
        return annotation
    }()
    
    let pressHoldView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isUserInteractionEnabled = false
        view.backgroundColor = UIColor.white
        view.layer.cornerRadius = 15
        return view
    }()
    
    let holdLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = UIColor(red: 153/255, green: 153/255, blue: 153/255, alpha: 1.0)
        label.font = UIFont.boldSystemFont(ofSize: 12.0)
        label.text = "Press and hold on the map to choose a point"
        label.textAlignment = .center
        return label
    }()
    
    let informationView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isUserInteractionEnabled = false
        view.backgroundColor = UIColor.white
        view.layer.cornerRadius = 0
        return view
    }()
    
    let informationLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = UIColor(red: 153/255, green: 153/255, blue: 153/255, alpha: 1.0)
        label.font = UIFont.systemFont(ofSize: 11.0)
        label.text = "The Point you choose will appear as the banner of your profile."
        label.textAlignment = .center
        return label
    }()

    
    // view did load method
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        setupSubviews()
        mapView.reloadStyle(mapView)
        
        updatePoint(latitude: self.pointLatitude, longitude: self.pointLongitude)
        let tapRecogniser = UITapGestureRecognizer(target: self, action: #selector(PointViewController.pointMapPressed(_:)))
        mapView.addGestureRecognizer(tapRecogniser)
                
    }
    
    func mapView(_ mapView: MGLMapView, didFinishLoading style: MGLStyle) {
        addItemsToMap(features: [pointFeature])
    }
    
    // function to set the style for custom features on map
    func addItemsToMap(features: [MGLPointFeature]) {
        // MGLMapView.style is optional, so you must guard against it not being set.
        guard let style = mapView.style else { return }
        // You can add custom UIImages to the map style.
        // These can be referenced by an MGLSymbolStyleLayer’s iconImage property.
        let image = resizeImage(image: #imageLiteral(resourceName: "defaultAnnotation.png"), targetSize: CGSize(width: 40, height: 40))
        //image = image.withAlignmentRectInsets(UIEdgeInsets(top: 0, left: 0, bottom: 20, right: 0))
        style.setImage(image, forName: "lighthouse")
        
        // Add the features to the map as a shape source.
        let source = MGLShapeSource(identifier: "us-lighthouses", features: features, options: nil)
        style.addSource(source)
        
        // Use MGLSymbolStyleLayer for more complex styling of points including custom icons and text rendering.
        let symbols = MGLSymbolStyleLayer(identifier: "lighthouse-symbols", source: source)
        symbols.iconAllowsOverlap = NSExpression(forConstantValue: "YES")
        symbols.iconIgnoresPlacement = NSExpression(forConstantValue: "YES")
        symbols.iconImageName = NSExpression(forConstantValue: "lighthouse")
        symbols.iconAnchor = NSExpression(forConstantValue: "bottom")
        style.addLayer(symbols)
    }
    
    
    // everytime map is long pressed, new annotations
    @objc func pointMapPressed(_ gestureRecognizer : UITapGestureRecognizer){
        if gestureRecognizer.state != .ended { return }
        let touchPoint = gestureRecognizer.location(in: mapView)
        let touchMapCoordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)
        pointLatitude = touchMapCoordinate.latitude
        pointLongitude = touchMapCoordinate.longitude
        let coordinate = CLLocationCoordinate2DMake(pointLatitude, pointLongitude)
        pointFeature.coordinate = coordinate
        if let currentSource = self.mapView.style?.source(withIdentifier: "us-lighthouses") as? MGLShapeSource {
            currentSource.shape = self.pointFeature
        }
        
        if (self.firstTimePressed) {
            self.firstTimePressed = false
            self.animatedViewBottomConstraint.constant = 40
            UIView.animate(withDuration: 0.3, animations: {
                //self.pressHoldView.alpha = 0.0
                //self.holdLabel.alpha = 0.0
                self.view.layoutIfNeeded()
            }, completion: {(finished:Bool) in
                // animation finishes
                self.pressHoldView.removeFromSuperview()
            })
        }
    }
    
    // do this once on load
    func updatePoint (latitude: Double, longitude: Double) {
        let coordinate = CLLocationCoordinate2DMake(latitude, longitude)
        pointFeature.coordinate = coordinate
        mapView.setCenter(coordinate, animated: false)
        mapView.setZoomLevel(zoomLevel, animated: false)
        if let currentSource = self.mapView.style?.source(withIdentifier: "us-lighthouses") as? MGLShapeSource {
            currentSource.shape = self.pointFeature
        }
    }
    
    func setupSubviews() {
        headerView.frame.size.height = 75
        headerView.frame.size.width = view.frame.width
        headerView.bounds.size.width = view.frame.width
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


        self.view.addSubview(mapView)
        view.sendSubview(toBack: mapView)
        mapView.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        mapView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        mapView.widthAnchor.constraint(equalToConstant: self.view.frame.size.width).isActive = true
        mapView.heightAnchor.constraint(equalToConstant: self.view.frame.height).isActive = true
        
        // information view - to let user know what a point is
        self.view.addSubview(informationView)
        informationView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        informationView.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        informationView.widthAnchor.constraint(equalToConstant: self.view.frame.size.width).isActive = true
        informationView.heightAnchor.constraint(equalToConstant: 30).isActive = true
        
        self.informationView.addSubview(informationLabel)
        informationLabel.centerYAnchor.constraint(equalTo: self.informationView.centerYAnchor).isActive = true
        informationLabel.centerXAnchor.constraint(equalTo: self.informationView.centerXAnchor).isActive = true
        informationLabel.widthAnchor.constraint(equalToConstant: 330).isActive = true
        informationLabel.heightAnchor.constraint(equalToConstant: 20).isActive = true

        // press hold view - gets removed on first press
        self.view.addSubview(pressHoldView)
        self.animatedViewBottomConstraint.isActive = true
        pressHoldView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        pressHoldView.widthAnchor.constraint(equalToConstant: 295).isActive = true
        pressHoldView.heightAnchor.constraint(equalToConstant: 30).isActive = true
    
        self.pressHoldView.addSubview(holdLabel)
        holdLabel.centerYAnchor.constraint(equalTo: self.pressHoldView.centerYAnchor).isActive = true
        holdLabel.centerXAnchor.constraint(equalTo: self.pressHoldView.centerXAnchor).isActive = true
        holdLabel.widthAnchor.constraint(equalToConstant: 300).isActive = true
        holdLabel.heightAnchor.constraint(equalToConstant: 20).isActive = true
        


        
    }
    
    // save point edit
    @IBAction func donePointPressed(_ sender: Any) {
        self.performSegue(withIdentifier: "unwindToEditProfileAndSavePoint", sender: self)
    }
    
    // cancel point edit
    @IBAction func cancelButtonPressed(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    



}
