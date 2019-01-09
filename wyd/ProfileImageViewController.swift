//
//  ProfileImageViewController.swift
//  wyd
//
//  Created by Jason Ellul on 2018-07-04.
//  Copyright © 2018 Jason Ellul. All rights reserved.
//

import UIKit
import SDWebImage

class ProfileImageViewController: UIViewController, UIGestureRecognizerDelegate {

    @IBOutlet weak var transitionView: UIView!
    
    
    var backgroundView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = true
        view.isUserInteractionEnabled = false
        view.backgroundColor = UIColor.black
        return view
    }()
    
    let closeButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = UIColor.clear
        button.setTitle("", for: .normal)
        button.setImage(#imageLiteral(resourceName: "left-arrow.png"), for: .normal)
        button.imageEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 10)
        return button
    }()
    
    let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.masksToBounds = true
        return imageView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        setupSubviews()

        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panGestureRecognizerAction(_:)))
        // delay for 0.5 seconds before enabling panGesture
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // add swipe right gesture
            self.transitionView.addGestureRecognizer(panGestureRecognizer)
        }
        self.view.clipsToBounds = false
        profileImageView.isUserInteractionEnabled = true
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(self.pinch(sender:)))
        pinch.delegate = self
        self.profileImageView.addGestureRecognizer(pinch)
        
        let pan = UIPanGestureRecognizer(target: self, action: #selector(self.pan(sender:)))
        pan.delegate = self
        self.profileImageView.addGestureRecognizer(pan)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setupSubviews() {
        backgroundView.frame = view.frame
        view.addSubview(backgroundView)
        view.sendSubview(toBack: backgroundView)
        transitionView.frame = view.frame
        transitionView.backgroundColor = UIColor.black
        //self.transitionView.backgroundColor = UIColor.black
        // close button
        self.transitionView.addSubview(closeButton)
        closeButton.topAnchor.constraint(equalTo: self.transitionView.topAnchor, constant: 21).isActive = true
        closeButton.leftAnchor.constraint(equalTo: self.transitionView.leftAnchor, constant: 0).isActive = true
        closeButton.heightAnchor.constraint(equalToConstant: 45).isActive = true
        closeButton.widthAnchor.constraint(equalToConstant: 45).isActive = true
        closeButton.addTarget(self, action: #selector(closeView(_:)), for: .touchUpInside)
        
        self.transitionView.addSubview(profileImageView)
        profileImageView.centerYAnchor.constraint(equalTo: self.transitionView.centerYAnchor).isActive = true
        profileImageView.widthAnchor.constraint(equalToConstant: self.transitionView.frame.width).isActive = true
        profileImageView.heightAnchor.constraint(equalToConstant: self.transitionView.frame.width).isActive = true
        profileImageView.frame = CGRect(x: profileImageView.frame.origin.x, y: profileImageView.frame.origin.y, width: transitionView.frame.width, height: transitionView.frame.width)
    }
    
    // pinch to zoom
    // taken from https://github.com/jjjeeerrr111/PinchToZoom/blob/master/PinchToZoom/PostCell.swift
    var isZooming = false
    var originalImageCenter:CGPoint?
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    @objc func pan(sender: UIPanGestureRecognizer) {
        if self.isZooming && sender.state == .began {
            self.originalImageCenter = sender.view?.center
        } else if self.isZooming && sender.state == .changed {
            let translation = sender.translation(in: self.transitionView)
            if let view = sender.view {
                view.center = CGPoint(x:view.center.x + translation.x,
                                      y:view.center.y + translation.y)
            }
            sender.setTranslation(CGPoint.zero, in: self.profileImageView.superview)
        }
    }
    
    @objc func pinch(sender:UIPinchGestureRecognizer) {
        
        if sender.state == .began {
            let currentScale = self.profileImageView.frame.size.width / self.profileImageView.bounds.size.width
            let newScale = currentScale*sender.scale
            
            if newScale > 1 {
                self.isZooming = true
            }
        } else if sender.state == .changed {
            
            guard let view = sender.view else {return}
            
            let pinchCenter = CGPoint(x: sender.location(in: view).x - view.bounds.midX,
                                      y: sender.location(in: view).y - view.bounds.midY)
            let transform = view.transform.translatedBy(x: pinchCenter.x, y: pinchCenter.y)
                .scaledBy(x: sender.scale, y: sender.scale)
                .translatedBy(x: -pinchCenter.x, y: -pinchCenter.y)
            
            let currentScale = self.profileImageView.frame.size.width / self.profileImageView.bounds.size.width
            var newScale = currentScale*sender.scale
            
            if newScale < 1 {
                newScale = 1
                let transform = CGAffineTransform(scaleX: newScale, y: newScale)
                self.profileImageView.transform = transform
                sender.scale = 1
            }else {
                view.transform = transform
                sender.scale = 1
            }
            
        } else if sender.state == .ended || sender.state == .failed || sender.state == .cancelled {
            
            guard let center = self.originalImageCenter else {return}
            
            UIView.animate(withDuration: 0.3, animations: {
                self.profileImageView.transform = CGAffineTransform.identity
                self.profileImageView.center = center
            }, completion: { _ in
                self.isZooming = false
            })
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
    @objc func closeView(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    

}
