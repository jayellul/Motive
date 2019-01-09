//
//  ProfilePointViewController.swift
//  wyd
//
//  Created by Jason Ellul on 2018-07-16.
//  Copyright © 2018 Jason Ellul. All rights reserved.
//

import UIKit
import Mapbox

class ProfilePointViewController: UIViewController, MGLMapViewDelegate {

    @IBOutlet weak var transitionView: UIView!
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var headerViewHeightConstraint: NSLayoutConstraint!
    
    var backgroundView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = true
        view.isUserInteractionEnabled = false
        view.backgroundColor = UIColor.black
        return view
    }()
    
    let mapView: MGLMapView = {
        let map = MGLMapView()
        map.translatesAutoresizingMaskIntoConstraints = false
        map.isPitchEnabled = false
        map.isRotateEnabled = false
        map.isScrollEnabled = false
        return map
    }()
    
    let pointFeature: MGLPointFeature = {
        let annotation = MGLPointFeature()
        annotation.attributes = [
            "name": ""
        ]
        return annotation
    }()
    
    var pointLatitude = 0.0
    var pointLongitude = 0.0
    var zoomLevel: Double = 15
    
    var display = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        mapView.delegate = self
        setupSubviews()
        mapView.reloadStyle(mapView)
        // add point and change camera of map
        updatePoint()
        
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panGestureRecognizerAction(_:)))
        // delay for 0.5 seconds before enabling panGesture
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // add swipe right gesture
            self.transitionView.addGestureRecognizer(panGestureRecognizer)
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

        
        backgroundView.frame = view.bounds
        view.addSubview(backgroundView)
        view.sendSubview(toBack: backgroundView)
        self.transitionView.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height)
        transitionView.backgroundColor = UIColor.white
        
        self.transitionView.addSubview(mapView)
        transitionView.sendSubview(toBack: mapView)
        mapView.topAnchor.constraint(equalTo: self.transitionView.topAnchor).isActive = true
        mapView.leftAnchor.constraint(equalTo: self.transitionView.leftAnchor).isActive = true
        mapView.widthAnchor.constraint(equalToConstant: self.transitionView.frame.width).isActive = true
        mapView.heightAnchor.constraint(equalToConstant: self.transitionView.frame.height).isActive = true
        
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
        // "name" references the "name" key in an MGLPointFeature’s attributes dictionary.
        symbols.textIgnoresPlacement = NSExpression(forConstantValue: "YES")
        symbols.textAllowsOverlap = NSExpression(forConstantValue: "YES")
        symbols.text = NSExpression(forKeyPath: "name")
        symbols.textColor = NSExpression(forConstantValue: UIColor.black)
        symbols.textFontSize = NSExpression(forConstantValue: 12)
        symbols.textTranslation = NSExpression(forConstantValue: NSValue(cgVector: CGVector(dx: 0, dy: 16)))
        symbols.textHaloColor = NSExpression(forConstantValue: UIColor.white.withAlphaComponent(0.5))
        symbols.textHaloWidth = NSExpression(forConstantValue: 1)
        symbols.textJustification = NSExpression(forConstantValue: NSValue(mglTextJustification: .center))
        symbols.textAnchor = NSExpression(forConstantValue: NSValue(mglTextAnchor: .bottom))
        
        style.addLayer(symbols)
    }
    
    
    // do this once on load
    func updatePoint () {
        let coordinate = CLLocationCoordinate2D(latitude: pointLatitude, longitude: pointLongitude)
        mapView.centerCoordinate = coordinate
        mapView.zoomLevel = Double(zoomLevel)
    
        pointFeature.coordinate = coordinate
        self.pointFeature.attributes = [
            "name": display
        ]
        // replace current shape
        if let currentSource = self.mapView.style?.source(withIdentifier: "us-lighthouses") as? MGLShapeSource {
            currentSource.shape = self.pointFeature
        }
        
        
    }
    
    @IBAction func backButtonPressed(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
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


}
