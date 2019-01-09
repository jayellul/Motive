//
//  MapBoxAnnotation.swift
//  wyd
//
//  Created by Jason Ellul on 2018-07-31.
//  Copyright © 2018 Jason Ellul. All rights reserved.
//

import Foundation
import Mapbox

// annotation for motives
class MapBoxAnnotation: NSObject, MGLAnnotation {
    let coordinate: CLLocationCoordinate2D
    let motive: Motive
    
    init(coordinate: CLLocationCoordinate2D, motive: Motive) {
        self.coordinate = coordinate
        self.motive = motive
        super.init()
    }
}

// extension to modify pod
extension MGLMapView {
    // function override to avoid setting constraints on the mapview's attribution labels
    // https://github.com/mapbox/mapbox-gl-native/blob/master/platform/ios/src/MGLMapView.mm#L871
    // https://github.com/mapbox/mapbox-gl-native/issues/1781
    override open func updateConstraints() {
        super.updateConstraints()
        // adjust attributed text to top left corner
        if self.subviews[1] is UIImageView {
            // adjust the logo position
            let mapBoxLogo = self.subviews[1] 
            mapBoxLogo.translatesAutoresizingMaskIntoConstraints = true
            mapBoxLogo.frame = CGRect(x: 8, y: (10.5 / 1.2) + 75, width: mapBoxLogo.frame.width / 1.2, height: mapBoxLogo.frame.height / 1.2)
            mapBoxLogo.alpha = 0.85
            // adjust i button position
            let mapBoxButton = self.attributionButton
            mapBoxButton.translatesAutoresizingMaskIntoConstraints = true
            mapBoxButton.frame = CGRect(x: 8 + mapBoxLogo.frame.width + 4, y: (10.5 / 1.2) + 75, width: mapBoxLogo.frame.height, height: mapBoxLogo.frame.height)
            mapBoxButton.alpha = 0.80
        }
        
        setNeedsLayout()

    }
}
