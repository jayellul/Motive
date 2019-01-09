//
//  SettingsVC.swift
//  wyd
//
//  Created by Jason Ellul on 2018-04-14.
//  Copyright © 2018 Jason Ellul. All rights reserved.
//

import UIKit
import Firebase

class SettingsViewController: UIViewController {
    
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var headerViewHeightConstraint: NSLayoutConstraint!
    // ui kit components
    var backgroundView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = true
        view.isUserInteractionEnabled = false
        view.backgroundColor = UIColor.black
        return view
    }()
    
    @IBOutlet weak var transitionView: UIView!
    @IBOutlet weak var tableView: UITableView!
    // background view for pinch
    var pinchView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = true
        view.isUserInteractionEnabled = false
        view.backgroundColor = UIColor.black
        return view
    }()
    var isZooming = false
    let signOutButton: LoadingButton = {
        let button = LoadingButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitleColor(.white, for: .normal)
        button.setTitle("Sign Out", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 15.0)
        button.backgroundColor = UIColor(red: 255/255, green: 102/255, blue: 51/255, alpha: 1.0)
        return button
    }()
    
    let emailLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = UIColor(red: 153/255, green: 153/255, blue: 153/255, alpha: 1.0)
        label.font = UIFont.systemFont(ofSize: 15.0)
        label.text = ""
        label.textAlignment = .center
        return label
    }()
    
    let blockButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitleColor(UIColor.black, for: .normal)
        button.setTitle("Blocked Users", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 15.0)
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor(red: 242/255, green: 242/255, blue: 242/255, alpha: 1.0).cgColor
        button.layer.cornerRadius = 5
        button.backgroundColor = UIColor.white
        return button
    }()
    
    var itemsToLoad: [String] = ["Account and Privacy", "Blocked Users", "Terms of Use", "About Motive"]
    
    var pinchDelegate: PinchDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupSubviews()
        if let currentUser = Auth.auth().currentUser {
            emailLabel.text = currentUser.email
        } else {
            // user not signed in , error handle appropriately
        }
        
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
        
        // setup table
        tableView.register(SliderTableViewCell.self, forCellReuseIdentifier: "settingsTableViewCell")
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = UITableViewCellSeparatorStyle.singleLine
        tableView.allowsMultipleSelection = false

        let footer = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 0))
        footer.backgroundColor = UIColor.clear
        tableView.tableFooterView = footer
        
    }
    
    
}

// MARK :- table view functionality
extension SettingsViewController: UITableViewDelegate , UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return itemsToLoad.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "settingsTableViewCell", for: indexPath as IndexPath) as! SliderTableViewCell
        cell.awakeFromNib()
        cell.selectionStyle = UITableViewCellSelectionStyle.none
        cell.preservesSuperviewLayoutMargins = false
        cell.separatorInset = UIEdgeInsets.zero
        cell.layoutMargins = UIEdgeInsets.zero
        cell.titleLabel.text = self.itemsToLoad[indexPath.row]
        switch indexPath.row {
        case 0:
            cell.iconImageView.image = resizeImage(image: #imageLiteral(resourceName: "mask.png"), targetSize: CGSize(width: 25, height: 25))
        case 1:
            cell.iconImageView.image = resizeImage(image: #imageLiteral(resourceName: "block.png"), targetSize: CGSize(width: 25, height: 25))
        case 2:
            cell.iconImageView.image = resizeImage(image: #imageLiteral(resourceName: "legal.png"), targetSize: CGSize(width: 25, height: 25))
        case 3:
            cell.iconImageView.image = resizeImage(image: #imageLiteral(resourceName: "logo.png"), targetSize: CGSize(width: 25, height: 25))
        default:
            cell.iconImageView.image = nil
        }
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        cell?.backgroundColor = UIColor.white
        switch indexPath.row {
        case 0:
            print ("account")
            guard let currentUser = (tabBarController as? CustomTabBarController)?.currentUser else { return }
            if let snapshotView = self.view.snapshotView(afterScreenUpdates: true) {
                for subview in pinchView.subviews {
                    if subview is UIVisualEffectView { subview.isHidden = true }
                }
                if let pinchSnapshotView = pinchView.snapshotView(afterScreenUpdates: true) {
                    let accountViewController = storyboard?.instantiateViewController(withIdentifier: "accountViewController") as! AccountViewController
                    accountViewController.backgroundView = snapshotView
                    for subview in pinchView.subviews {
                        if subview is UIVisualEffectView { subview.isHidden = false }
                    }
                    accountViewController.user = currentUser.user
                    accountViewController.pinchView = pinchSnapshotView
                    accountViewController.pinchDelegate = self.pinchDelegate
                    self.navigationController?.pushViewController(accountViewController, animated: true)
                }
            }
        case 1:
            print ("block")
            guard let currentUser = (tabBarController as? CustomTabBarController)?.currentUser else { return }
            if let snapshotView = self.view.snapshotView(afterScreenUpdates: true) {
                for subview in pinchView.subviews {
                    if subview is UIVisualEffectView { subview.isHidden = true }
                }
                if let pinchSnapshotView = pinchView.snapshotView(afterScreenUpdates: true) {
                    let blockViewController = storyboard?.instantiateViewController(withIdentifier: "blockViewController") as! BlockViewController
                    blockViewController.backgroundView = snapshotView
                    for subview in pinchView.subviews {
                        if subview is UIVisualEffectView { subview.isHidden = false }
                    }
                    blockViewController.currentUser = currentUser
                    blockViewController.pinchView = pinchSnapshotView
                    blockViewController.pinchDelegate = self.pinchDelegate
                    self.navigationController?.pushViewController(blockViewController, animated: true)
                }
            }

        case 2:
            print ("terms")
        case 3:
            print ("about")
        default:
            print ("exaustive")
        }
        tableView.deselectRow(at: indexPath, animated: false)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
}

// MARK :- view poppers
extension SettingsViewController {
    
    // dynamic pop view controller
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
                    //self.dismiss(animated: true, completion: nil)
                })
                // over half the screen, pop
            } else if (translation.x >= view.frame.width / 2) {
                UIView.animate(withDuration: 0.3, delay: 0.0, animations: {
                    // animate origin moring off screen
                    self.transitionView.frame.origin = CGPoint(x: self.view.frame.width, y: 0.0)
                }, completion: {(finished:Bool) in
                    // animation finishes
                    self.navigationController?.popViewController(animated: false)
                    //self.dismiss(animated: true, completion: nil)
                })
                // go back to origin
            } else {
                UIView.animate(withDuration: 0.3) {
                    self.transitionView.frame.origin = CGPoint(x: 0.0, y: 0.0)
                }
            }
        }
    }
    
    @IBAction func goBackButtonPressed(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
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

}
