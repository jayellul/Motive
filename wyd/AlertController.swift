//
//  AlertController.swift
//  wyd
//
//  Created by Jason Ellul on 2018-04-14.
//  Copyright © 2018 Jason Ellul. All rights reserved.
//

import Foundation
import UIKit


// Alert controller class - allows easy creation and display of simple alerts using showAlert method
class AlertController {
    static func showAlert(_ inViewController: UIViewController, title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(action)
        inViewController.present(alert, animated: true, completion: nil);
    }
}
