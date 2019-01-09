//
//  EditProfileViewController.swift
//  wyd
//
//  Created by Jason Ellul on 2018-05-27.
//  Copyright © 2018 Jason Ellul. All rights reserved.
//

import UIKit
import Firebase
import Mapbox
import SDWebImage

protocol EditProfileDelegate {
    func profileChanged()
}

class EditProfileViewController: UIViewController, MGLMapViewDelegate {
    
    // point defaults for instantiating a pointViewController
    var pointLatitude = 0.0
    var pointLongitude = 0.0
    var zoomLevel: Double = 15.0
    var timer: Timer?
    
    var editProfileDelegate: EditProfileDelegate?

    
    // db ref
    static let kUsersListPath = "users"
    let usersReference = Database.database().reference(withPath: kUsersListPath)
    
    var user: User?

    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var headerViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var saveButton: LoadingButton!
    @IBOutlet weak var scroll: UIScrollView!

    // segue coming from select point VC, for save button
    // https://medium.com/yay-its-erica/how-to-pass-data-in-an-unwind-segue-swift-3-1c3fa095cde1
    @IBAction func unwindToEditProfileAndSavePoint(segue: UIStoryboardSegue) {
        if segue.source is PointViewController {
            if let senderVC = segue.source as? PointViewController {
                self.updatePoint(latitude: senderVC.pointLatitude, longitude: senderVC.pointLongitude)
            }
        }
    }

    var imagePicker: UIImagePickerController!

    // cancel profile edits
    @IBAction func cancelButtonPressed(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }

    
    // ui kit components
    let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius =  50
        // fix pathing to have default image
        imageView.image = UIImage(named: "Images/default user icon.png")
        return imageView
    }()
    
    let tapToChangeLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = UIColor.black
        label.font = UIFont.systemFont(ofSize: 15.0)
        label.text = "Tap to Change"
        label.textAlignment = .center
        return label
    }()
    
    let imageButtonOverlay: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitleColor(.clear, for: .normal)
        button.setTitle("", for: .normal)
        button.backgroundColor = UIColor.clear
        return button
    }()
    
    let displayLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = UIColor.black
        label.font = UIFont.boldSystemFont(ofSize: 15.0)
        label.text = "Name"
        label.textAlignment = .left
        return label
    }()
    
    let displayTextField: UITextField = {
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.textColor = UIColor.black
        textField.font = UIFont.systemFont(ofSize: 15.0)
        textField.text = " "
        textField.textAlignment = .left
        textField.backgroundColor = UIColor.clear
        return textField
    }()
    
    let displayPadding: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor(red: 230/255, green: 230/255, blue: 230/255, alpha: 1.0)
        view.layer.cornerRadius = 5
        return view
    }()
    
    let mapView: MGLMapView = {
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
        view.isUserInteractionEnabled = false
        view.backgroundColor = UIColor.white
        return view
    }()
    
    let tapToChangePointView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isUserInteractionEnabled = false
        view.backgroundColor = UIColor.white
        view.layer.cornerRadius = 15
        return view
    }()
    
    let tapToChangePointLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = UIColor(red: 153/255, green: 153/255, blue: 153/255, alpha: 1.0)
        label.font = UIFont.systemFont(ofSize: 15.0)
        label.text = "Tap to Change Point"
        label.textAlignment = .center
        return label
    }()
    
    let pointButtonOverlay: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitleColor(.clear, for: .normal)
        button.setTitle("", for: .normal)
        button.backgroundColor = UIColor.clear
        return button
    }()
    
    let plusButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitleColor(.black, for: .normal)
        button.setTitle("", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 30.0)
        button.layer.borderWidth = 2
        button.layer.borderColor = UIColor(red: 242/255, green: 242/255, blue: 242/255, alpha: 1.0).cgColor
        button.setImage(#imageLiteral(resourceName: "plus.png"), for: .normal)
        button.layer.cornerRadius = 5
        //button.layer.maskedCorners = [.layerMaxXMaxYCorner] ios 11 :(
        button.backgroundColor = UIColor.white
        return button
    }()
    
    let minusButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitleColor(.black, for: .normal)
        button.setTitle("", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 30.0)
        button.layer.borderWidth = 2
        button.layer.borderColor = UIColor(red: 242/255, green: 242/255, blue: 242/255, alpha: 1.0).cgColor
        button.setImage(#imageLiteral(resourceName: "minus.png"), for: .normal)
        button.layer.cornerRadius = 5
        //button.layer.maskedCorners = [.layerMinXMaxYCorner] ios 11 only
        button.backgroundColor = UIColor.white
        return button
    }()
    
    let zoomLevelLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = UIColor(red: 153/255, green: 153/255, blue: 153/255, alpha: 1.0)
        label.font = UIFont.systemFont(ofSize: 12.0)
        label.text = "zoom level"
        label.textAlignment = .center
        return label
    }()
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.hideKeyboardWhenTappedAround()
        mapView.delegate = self
        setupSubviews()
        mapView.reloadStyle(mapView)
        // get user information
        if Auth.auth().currentUser != nil {
            if let user = self.user {
                self.displayTextField.text = user.display
                self.pointLatitude = user.pointLatitude
                self.pointLongitude = user.pointLongitude
                self.zoomLevel = user.zoomLevel
                self.updatePoint(latitude: user.pointLatitude, longitude: user.pointLongitude)
                // download profile image
                if let url = URL(string: user.photoURL) {
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
            // no user ?
            } else {
                
            }
        } else {
            // TODO: error handle if user is not signed in and is on profile page edits
        }
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

        // set content size to support small devices
        self.scroll.frame.size.width = self.view.frame.size.width
        self.scroll.contentSize.height = 500

        // add everything to scroll view
        
        self.scroll.addSubview(mapView)
        mapView.leftAnchor.constraint(equalTo: self.scroll.leftAnchor).isActive = true
        mapView.topAnchor.constraint(equalTo: self.scroll.topAnchor).isActive = true
        mapView.widthAnchor.constraint(equalToConstant: self.scroll.frame.size.width).isActive = true
        mapView.heightAnchor.constraint(equalToConstant: 100).isActive = true
        
        self.scroll.addSubview(hideLegalView)
        hideLegalView.leftAnchor.constraint(equalTo: self.scroll.leftAnchor).isActive = true
        hideLegalView.topAnchor.constraint(equalTo: self.scroll.topAnchor, constant: 80).isActive = true
        hideLegalView.widthAnchor.constraint(equalToConstant: self.scroll.frame.size.width).isActive = true
        hideLegalView.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        // tap to change point
        self.scroll.addSubview(tapToChangePointView)
        tapToChangePointView.topAnchor.constraint(equalTo: self.scroll.topAnchor, constant: 50).isActive = true
        tapToChangePointView.centerXAnchor.constraint(equalTo: self.scroll.centerXAnchor).isActive = true
        tapToChangePointView.widthAnchor.constraint(equalToConstant: 150).isActive = true
        tapToChangePointView.heightAnchor.constraint(equalToConstant: 25).isActive = true
        
        self.tapToChangePointView.addSubview(tapToChangePointLabel)
        tapToChangePointLabel.centerYAnchor.constraint(equalTo: self.tapToChangePointView.centerYAnchor).isActive = true
        tapToChangePointLabel.centerXAnchor.constraint(equalTo: self.tapToChangePointView.centerXAnchor).isActive = true
        tapToChangePointLabel.widthAnchor.constraint(equalToConstant: 150).isActive = true
        tapToChangePointLabel.heightAnchor.constraint(equalToConstant: 20).isActive = true
        
        self.scroll.addSubview(pointButtonOverlay)
        pointButtonOverlay.leftAnchor.constraint(equalTo: self.scroll.leftAnchor).isActive = true
        pointButtonOverlay.topAnchor.constraint(equalTo: self.scroll.topAnchor).isActive = true
        pointButtonOverlay.widthAnchor.constraint(equalToConstant: self.scroll.frame.size.width).isActive = true
        pointButtonOverlay.heightAnchor.constraint(equalToConstant: 80).isActive = true
        pointButtonOverlay.addTarget(self, action: #selector(EditProfileViewController.choosePointPressed(_:)), for: .touchUpInside)
        
        self.scroll.addSubview(plusButton)
        plusButton.topAnchor.constraint(equalTo: self.scroll.topAnchor, constant: 80).isActive = true
        plusButton.leftAnchor.constraint(equalTo: self.scroll.leftAnchor, constant: 60).isActive = true
        plusButton.widthAnchor.constraint(equalToConstant: 40).isActive = true
        plusButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
        plusButton.addTarget(self, action: #selector(buttonDownIncrease), for: .touchDown)
        plusButton.addTarget(self, action: #selector(buttonUp), for: [.touchUpInside, .touchUpOutside])
        
        self.scroll.addSubview(minusButton)
        minusButton.topAnchor.constraint(equalTo: self.scroll.topAnchor, constant: 80).isActive = true
        minusButton.leftAnchor.constraint(equalTo: self.scroll.leftAnchor, constant: 22).isActive = true
        minusButton.widthAnchor.constraint(equalToConstant: 40).isActive = true
        minusButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
        minusButton.addTarget(self, action: #selector(buttonDownDecrease), for: .touchDown)
        minusButton.addTarget(self, action: #selector(buttonUp), for: [.touchUpInside, .touchUpOutside])
        
        self.scroll.addSubview(zoomLevelLabel)
        zoomLevelLabel.topAnchor.constraint(equalTo: self.scroll.topAnchor, constant: 116).isActive = true
        zoomLevelLabel.leftAnchor.constraint(equalTo: self.scroll.leftAnchor, constant: 10).isActive = true
        zoomLevelLabel.widthAnchor.constraint(equalToConstant: 100).isActive = true
        zoomLevelLabel.heightAnchor.constraint(equalToConstant: 20).isActive = true
        
        self.scroll.addSubview(profileImageView)
        profileImageView.topAnchor.constraint(equalTo: self.scroll.topAnchor, constant: 110).isActive = true
        profileImageView.centerXAnchor.constraint(equalTo: self.scroll.centerXAnchor).isActive = true
        profileImageView.widthAnchor.constraint(equalToConstant: 100).isActive = true
        profileImageView.heightAnchor.constraint(equalToConstant: 100).isActive = true
        
        self.scroll.addSubview(tapToChangeLabel)
        tapToChangeLabel.topAnchor.constraint(equalTo: self.scroll.topAnchor, constant: 215).isActive = true
        tapToChangeLabel.centerXAnchor.constraint(equalTo: self.scroll.centerXAnchor).isActive = true
        tapToChangeLabel.widthAnchor.constraint(equalToConstant: 140).isActive = true
        tapToChangeLabel.heightAnchor.constraint(equalToConstant: 20).isActive = true
        
        self.scroll.addSubview(imageButtonOverlay)
        imageButtonOverlay.topAnchor.constraint(equalTo: self.scroll.topAnchor, constant: 110).isActive = true
        imageButtonOverlay.centerXAnchor.constraint(equalTo: self.scroll.centerXAnchor).isActive = true
        imageButtonOverlay.widthAnchor.constraint(equalToConstant: 110).isActive = true
        imageButtonOverlay.heightAnchor.constraint(equalToConstant: 125).isActive = true
        imageButtonOverlay.addTarget(self, action: #selector(EditProfileViewController.imageTapped(_:)), for: .touchUpInside)
        
        self.scroll.addSubview(displayPadding)
        displayPadding.topAnchor.constraint(equalTo: self.scroll.topAnchor, constant: 270).isActive = true
        displayPadding.leftAnchor.constraint(equalTo: self.scroll.leftAnchor, constant: 90).isActive = true
        displayPadding.heightAnchor.constraint(equalToConstant: 30).isActive = true
        displayPadding.widthAnchor.constraint(equalToConstant: self.scroll.frame.width - 115).isActive = true

        self.scroll.addSubview(displayLabel)
        displayLabel.topAnchor.constraint(equalTo: self.scroll.topAnchor, constant: 270).isActive = true
        displayLabel.leftAnchor.constraint(equalTo: self.scroll.leftAnchor, constant: 25).isActive = true
        displayLabel.widthAnchor.constraint(equalToConstant: 50).isActive = true
        displayLabel.heightAnchor.constraint(equalToConstant: 30).isActive = true
        
        self.scroll.addSubview(displayTextField)
        displayTextField.topAnchor.constraint(equalTo: self.scroll.topAnchor, constant: 270).isActive = true
        displayTextField.leftAnchor.constraint(equalTo: self.scroll.leftAnchor, constant: 100).isActive = true
        displayTextField.heightAnchor.constraint(equalToConstant: 30).isActive = true
        displayTextField.widthAnchor.constraint(equalToConstant: self.scroll.frame.width - 125).isActive = true
        displayTextField.delegate = self
        
        // setup image picker
        imagePicker = UIImagePickerController()
        imagePicker.allowsEditing = true
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = self
        

    }
    // save profile pressed - update users profile
    @IBAction func saveButtonPressed(_ sender: Any) {
        self.saveButton.showLoading()
        guard let firebaseUser = Auth.auth().currentUser else {
            // error handle if user is not signed in
            self.saveButton.hideLoading()
            return
        }
        if let user = self.user {
            let uid = firebaseUser.uid
            let kCurrentUserPath = "users/" + uid
            let currentUserReference = Database.database().reference(withPath: kCurrentUserPath)
            // upload image to firebase storage
            guard let image = self.profileImageView.image else {
                self.saveButton.hideLoading()
                return
            }
            // upload new image
            self.uploadProfileImage(image) { url in
                if url != nil {
                    // update firebase user profile
                    let changeReqest = firebaseUser.createProfileChangeRequest()
                    changeReqest.photoURL = url
                    changeReqest.commitChanges(completion: { (error) in
                        guard error == nil else {
                            AlertController.showAlert(self, title: "Error", message: error!.localizedDescription)
                            self.saveButton.hideLoading()
                            return
                        }
                        let userObject = [
                            "uid": uid,
                            "un": user.username,
                            "dis": self.displayTextField.text ?? user.display,
                            "pURL": url?.absoluteString ?? user.photoURL,
                            "nFers": user.numFollowers,
                            "nFing": user.numFollowing,
                            "pLat": self.pointLatitude,
                            "pLong": self.pointLongitude,
                            "zl": self.zoomLevel
                            ] as [String:Any]
                        currentUserReference.setValue(userObject)
                        self.editProfileDelegate?.profileChanged()
                        self.saveButton.hideLoading()
                        self.navigationController?.popViewController(animated: true)
                    })
                } else {
                    // error handle upload
                    self.saveButton.hideLoading()
                    AlertController.showAlert(self, title: "Error", message: "Profile photo could not be uploaded")
                    self.navigationController?.popViewController(animated: true)
                }
            }
        }
    }
    
    // uploads image to firebase, returns URL
    func uploadProfileImage(_ image:UIImage, completion: @escaping ((_ url:URL?)->())) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let storageRef = Storage.storage().reference().child("user/\(uid)")
        guard let imageData = UIImageJPEGRepresentation(image, 0.75) else { return  }
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
    
    // user presses the map banner
    @objc func choosePointPressed(_ sender: UIButton!) {
        let pointViewController = storyboard?.instantiateViewController(withIdentifier: "pointViewController") as! PointViewController
        pointViewController.pointLatitude = self.pointLatitude
        pointViewController.pointLongitude = self.pointLongitude
        pointViewController.zoomLevel = self.zoomLevel
        self.navigationController?.pushViewController(pointViewController, animated: true)
    }
    // 0.0025 is default
    @objc func increaseZoomLevel (_ sender: UIButton!) {
        if (zoomLevel * 1.015 > 18) {
            return
        }
        zoomLevel = zoomLevel * 1.015
        mapView.zoomLevel = zoomLevel
    }
    
    @objc func decreaseZoomLevel (_ sender: UIButton!) {
        if (zoomLevel / 1.015 < 0.1) {
            return
        }
        zoomLevel = zoomLevel / 1.015
        mapView.zoomLevel = zoomLevel
    }
    
    @objc func buttonDownIncrease(_ sender: UIButton) {
        increaseZoomLevel(sender)
        timer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(increaseZoomLevel(_:)), userInfo: nil, repeats: true)
    }
    
    @objc func buttonDownDecrease(_ sender: UIButton) {
        decreaseZoomLevel(sender)
        timer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(decreaseZoomLevel(_:)), userInfo: nil, repeats: true)
    }
    
    @objc func buttonUp(_ sender: UIButton) {
        timer?.invalidate()
    }

    
    @objc func imageTapped(_ sender: UIButton!) {
        self.present(imagePicker, animated: true, completion: nil)
    }
    
    func updatePoint (latitude: Double, longitude: Double) {
        self.pointLatitude = latitude
        self.pointLongitude = longitude
        // set camera
        let coordinate = CLLocationCoordinate2DMake(latitude, longitude)
        mapView.setCenter(coordinate, animated: false)
        mapView.setZoomLevel(zoomLevel, animated: false)
        // set shape and feature
        pointFeature.coordinate = coordinate
        if let currentSource = self.mapView.style?.source(withIdentifier: "us-lighthouses") as? MGLShapeSource {
            currentSource.shape = self.pointFeature
        }
    }

}

// to disable OS logging / discovery errors that come up with this implmentation of imagePicker
// https://stackoverflow.com/questions/40024316/reading-from-public-effective-user-settings-in-ios-10?utm_medium=organic&utm_source=google_rich_qa&utm_campaign=google_rich_qa
extension EditProfileViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextViewDelegate, UITextFieldDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let pickedImage = info[UIImagePickerControllerEditedImage] as? UIImage {
            self.profileImageView.image = pickedImage
        }
        
        picker.dismiss(animated: true, completion: nil)
    }
    
    // max amount of characters in display text field
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard string.count > 0 else {
            return true
        }
        let maxLength = 25
        let currentText = textField.text ?? ""
        let prospectiveText = (currentText as NSString).replacingCharacters(in: range, with: string)
        return prospectiveText.count <= maxLength
    }
    
    // max amount of characters in bio text view
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText string: String) -> Bool {
        // disable enter key
        if (string == "\n") {
            return false
        }
        // update character count label
        //self.charCountLabel.text = textView.text.count.description + "/140"
        guard string.count > 0 else {
            return true
        }
        let maxLength = 140
        let currentText = textView.text ?? ""
        let prospectiveText = (currentText as NSString).replacingCharacters(in: range, with: string)
        return prospectiveText.count <= maxLength
    }
    
    // hide keyboard on return key
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        //self.scroll.setContentOffset(CGPoint(x: 0, y: 150.0), animated: true)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        //self.scroll.setContentOffset(.zero, animated: true)
    }
    
}

// view bio stuff

/*let bioLabel: UILabel = {
 let label = UILabel()
 label.translatesAutoresizingMaskIntoConstraints = false
 label.textColor = UIColor.black
 label.font = UIFont.boldSystemFont(ofSize: 15.0)
 label.text = "Bio"
 label.textAlignment = .left
 return label
 }()
 
 let bioTextView: UITextView = {
 let textView = UITextView()
 textView.translatesAutoresizingMaskIntoConstraints = false
 textView.textColor = UIColor.black
 textView.font = UIFont.systemFont(ofSize: 15.0)
 textView.text = " "
 textView.textAlignment = .left
 textView.backgroundColor = UIColor.clear
 return textView
 }()
 
 let bioPadding: UIView = {
 let view = UIView()
 view.translatesAutoresizingMaskIntoConstraints = false
 view.backgroundColor = UIColor(red: 230/255, green: 230/255, blue: 230/255, alpha: 1.0)
 view.layer.cornerRadius = 5
 return view
 }()
 
 let charCountLabel: UILabel = {
 let label = UILabel()
 label.translatesAutoresizingMaskIntoConstraints = false
 label.textColor = UIColor(red: 153/255, green: 153/255, blue: 153/255, alpha: 1.0)
 label.font = UIFont.systemFont(ofSize: 15.0)
 label.text = "0/140"
 label.textAlignment = .left
 return label
 }() */

/*  self.scroll.addSubview(bioPadding)
 bioPadding.topAnchor.constraint(equalTo: self.scroll.topAnchor, constant: 230).isActive = true
 bioPadding.leftAnchor.constraint(equalTo: self.scroll.leftAnchor, constant: 90).isActive = true
 bioPadding.heightAnchor.constraint(equalToConstant: 70).isActive = true
 bioPadding.widthAnchor.constraint(equalToConstant: self.scroll.frame.width - 115).isActive = true
 
 self.scroll.addSubview(bioLabel)
 bioLabel.topAnchor.constraint(equalTo: self.scroll.topAnchor, constant: 230).isActive = true
 bioLabel.leftAnchor.constraint(equalTo: self.scroll.leftAnchor, constant: 25).isActive = true
 bioLabel.widthAnchor.constraint(equalToConstant: 50).isActive = true
 bioLabel.heightAnchor.constraint(equalToConstant: 30).isActive = true
 
 self.scroll.addSubview(bioTextView)
 bioTextView.topAnchor.constraint(equalTo: self.scroll.topAnchor, constant: 230).isActive = true
 bioTextView.leftAnchor.constraint(equalTo: self.scroll.leftAnchor, constant: 95).isActive = true
 bioTextView.heightAnchor.constraint(equalToConstant: 70).isActive = true
 bioTextView.widthAnchor.constraint(equalToConstant: self.scroll.frame.width - 125).isActive = true
 bioTextView.delegate = self
 
 self.scroll.addSubview(charCountLabel)
 charCountLabel.topAnchor.constraint(equalTo: self.scroll.topAnchor, constant: 295).isActive = true
 charCountLabel.leftAnchor.constraint(equalTo: self.scroll.leftAnchor, constant: 90).isActive = true
 charCountLabel.widthAnchor.constraint(equalToConstant: 80).isActive = true
 charCountLabel.heightAnchor.constraint(equalToConstant: 30).isActive = true*/
