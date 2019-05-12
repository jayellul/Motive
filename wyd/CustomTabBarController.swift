//
//  CustomTabBarController.swift
//  wyd
//
//  Created by Jason Ellul on 2018-05-10.
//  Copyright © 2018 Jason Ellul. All rights reserved.
//

import UIKit
import Firebase

protocol TabDelegate {
    func showLoading()
    func hideLoading()
}
protocol CurrentUserDelegate {
    // send a loaded currentUser from database to tabdelegate hashtable
    func storeCurrentUser(currentUser: CurrentUser)
    // retrieve currentUser
    func retrieveCurrentUser() -> CurrentUser?
}
protocol UserHashTableDelegate {
    // send a loaded user from database to tabdelegate hashtable
    func storeUser(user: User)
    // retrieve a user in hashtable - optional - return nil if uid is not in table
    func retrieveUser(uid: String) -> User?
}
protocol MotiveHashTableDelegate {
    // send a loaded motive from database to tabdelegate hashtable
    func storeMotive(motive: Motive)
    // retrieve a motive in hashtable - optional - return nil if id is not in table
    func retrieveMotive(id: String) -> Motive?
}


class CustomTabBarController: UITabBarController,FeedDelegate, MapDelegate, CurrentUserDelegate, UserHashTableDelegate, MotiveHashTableDelegate, ExploreDelegate {

    

    
    


    // delegate for map view
    var mapViewDelegate: TabDelegate?
    // delegate for feedview
    var feedViewDelegate: TabDelegate?
    // delegate for explore
    var exploreViewDelegate: TabDelegate?
    
    let numMotivesToLoad: UInt = 20
    // sender = 0 means map requested refresh - sender = 1 means feed requested refresh
    var sender = 0
    
    // current User and lists
    var currentUser: CurrentUser?
    // replace the current Users object, friends, requests, and blocked list
    func storeCurrentUser(currentUser: CurrentUser) {
        self.currentUser = currentUser
    }
    // send currentUser
    func retrieveCurrentUser() -> CurrentUser? {
        if currentUser != nil {
            return currentUser
        }
        return nil
    }

    
    // firebase db refs
    static let kUsersListPath = "users"
    let usersReference = Database.database().reference(withPath: kUsersListPath)
    static let kMotivesListPath = "motives"
    let motivesReference = Database.database().reference(withPath: kMotivesListPath)
    static let kMotivesGoingListPath = "motivesGoing"
    let motivesGoingReference = Database.database().reference(withPath: kMotivesGoingListPath)
    static let kUsersGoingListPath = "usersGoing"
    let usersGoingReference = Database.database().reference(withPath: kUsersGoingListPath)
    static let kUsersPostListPath = "usersPost"
    let usersPostReference = Database.database().reference(withPath: kUsersPostListPath)
    static let kExploreMotivesListPath = "exploreMotives"
    let exploreMotivesReference = Database.database().reference(withPath: kExploreMotivesListPath)
    static let kFollowingListPath = "following"
    let followingReference = Database.database().reference(withPath: kFollowingListPath)
    
    // tab bar selection animations
    var firstItemImageView: UIImageView!
    var secondItemImageView: UIImageView!
    var thirdItemImageView: UIImageView!
    
    // setup all the main views
    override func viewDidLoad() {
        super.viewDidLoad()
        // to make mapViewController delegate 
        let mapNavigationController = self.viewControllers![0] as! UINavigationController
        let feedNavigationController = self.viewControllers![1] as! UINavigationController
        let exploreNavigationController = self.viewControllers![2] as! UINavigationController

        let mapViewController = mapNavigationController.viewControllers[0] as! MapViewController
        let feedViewController = feedNavigationController.viewControllers[0] as! FeedViewController
        let exploreViewController = exploreNavigationController.viewControllers[0] as! ExploreViewController

        mapViewController.delegate = self
        mapViewController.userHashTableDelegate = self
        
        self.feedViewDelegate = feedViewController
        self.mapViewDelegate = mapViewController
        self.exploreViewDelegate = exploreViewController
        
        feedViewController.delegate = mapViewController
        feedViewController.annotationDelegate = mapViewController
        feedViewController.tabDelegate = self
        feedViewController.userHashTableDelegate = self
        feedViewController.motiveHashTableDelegate = self
        feedViewController.pinchDelegate = mapViewController
        
        exploreViewController.delegate = mapViewController
        exploreViewController.annotationDelegate = mapViewController
        exploreViewController.tabDelegate = self
        exploreViewController.userHashTableDelegate = self
        exploreViewController.motiveHashTableDelegate = self
        exploreViewController.pinchDelegate = mapViewController
        
        // set tab bar image views to animate them later
        let firstItemView = self.tabBar.subviews[0]
        for subview in firstItemView.subviews {
            if subview is UIImageView {
                self.firstItemImageView = subview as? UIImageView
            }
        }
        let secondItemView = self.tabBar.subviews[1]
        for subview in secondItemView.subviews {
            if subview is UIImageView {
                self.secondItemImageView = subview as? UIImageView
            }
        }
        let thirdItemView = self.tabBar.subviews[2]
        for subview in thirdItemView.subviews {
            if subview is UIImageView {
                self.thirdItemImageView = subview as? UIImageView
            }
        }
        self.spinAnimation()
    
    }

    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        // take screenshot of map
        guard let tabBarViews = self.viewControllers else { return }
        if tabBarViews.count >= 2 {
            guard let mapNavViewController = tabBarViews[0] as? UINavigationController else { return }
            guard let mapViewController = mapNavViewController.viewControllers[0] as? MapViewController else { return }
            guard let pinchSnapshotView1 = mapViewController.view.snapshotView(afterScreenUpdates: true) else { return }
            guard let pinchSnapshotView2 = mapViewController.view.snapshotView(afterScreenUpdates: true) else { return }
            guard let feedNavViewController = tabBarViews[1] as? UINavigationController else { return }
            guard let feedViewController = feedNavViewController.viewControllers[0] as? FeedViewController else { return }
            guard let exploreNavViewController = tabBarViews[2] as? UINavigationController else { return }
            guard let exploreViewController = exploreNavViewController.viewControllers[0] as? ExploreViewController else { return }
            let blurSnapshotView1 = self.applyBlurEffect(toView: pinchSnapshotView1)
            feedViewController.pinchView.removeFromSuperview()
            feedViewController.pinchView = blurSnapshotView1
            feedViewController.setupPinchView()
            let blurSnapshotView2 = self.applyBlurEffect(toView: pinchSnapshotView2)
            exploreViewController.pinchView.removeFromSuperview()
            exploreViewController.pinchView = blurSnapshotView2
            exploreViewController.setupPinchView()
        }
        
        // animate tab bar item pic
        var imageView: UIImageView? = nil
        if item.tag == 1{
            imageView = self.firstItemImageView
        } else if item.tag == 2 {
            imageView = self.secondItemImageView
        } else if item.tag == 3 {
            imageView = self.thirdItemImageView
        }
        if let imageView = imageView {
            imageView.transform = CGAffineTransform.identity
            imageView.transform = CGAffineTransform(scaleX: 1.15, y: 1.15)
            UIView.animate(withDuration: 1.2, delay: 0.0, usingSpringWithDamping: 0.25, initialSpringVelocity: 0.25, options: .curveEaseOut, animations: {
                imageView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            }) { (completion) in
                imageView.transform = CGAffineTransform.identity

            }

        }
    }
    
    // spin all of the tab bar icons
    func spinAnimation() {
        let rotation = CABasicAnimation(keyPath: "transform.rotation")
        rotation.fromValue = NSNumber(floatLiteral: 0)
        rotation.toValue = NSNumber(floatLiteral: Double(CGFloat.pi * 2))
        rotation.duration = 0.8
        rotation.repeatCount = 1
        rotation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)

        self.run(after: 0.2) {
            self.firstItemImageView.layer.add(rotation, forKey: "360")
        }
        self.run(after: 0.4) {
            self.secondItemImageView.layer.add(rotation, forKey: "360")
        }
        self.run(after: 0.6) {
            self.thirdItemImageView.layer.add(rotation, forKey: "360")
        }
        

    }
    
    // array and set of loaded motives
    var feedMotives: [MotiveAndUser] = []
    var exploreMotives: [MotiveAndUser] = []
    // hash table full of loaded users
    var userHashTable = HashTable<String, User>(capacity: 75)
    // store a user in the hash table - whenever it is downloaded it should be stored here to save overhead and network
    func storeUser(user: User) {
        self.userHashTable[user.uid] = user
    }
    // send a user from the hash table of users
    func retrieveUser(uid: String) -> User? {
        if let user = self.userHashTable[uid] {
            return user
        } else {
            return nil
        }
    }
    // list of motives the user is currently going to  - gotten from checking if child has snapshot everytime you load  a motive
    var userMotiveGoingSet: Set<String> = []

    
    // hash table full of loaded Motives
    var motiveHashTable = HashTable<String, Motive>(capacity: 150)
    func storeMotive(motive: Motive) {
        self.motiveHashTable[motive.id] = motive
    }
    func retrieveMotive(id: String) -> Motive? {
        if let motive = self.motiveHashTable[id] {
            return motive
        } else {
            return nil
        }
    }
    
    // the map sent a refresh request
    func mapSentRefresh() {
        sender = 0
        // redo initial loading for first 20 motives from feed and explore
        loadMotivesIntoView()
    }
    
    // feed sent a refresh request
    func feedSentRefresh() {
        sender = 1
        // get feed data
        if let currentUser = self.currentUser {
            getFeedData(currentUser: currentUser, previousQueryTime: Int64(NSDate().timeIntervalSince1970 * -1000)) { (motiveAndUsers) in
                self.feedMotives = motiveAndUsers
                // hide loading for feed
                self.feedViewDelegate?.hideLoading()
            }
        }
    }
    
    // initial loading of motives into view
    func loadMotivesIntoView() {
        mapViewDelegate?.showLoading()
        if let currentUser = self.currentUser {
            getFeedData(currentUser: currentUser, previousQueryTime: Int64(NSDate().timeIntervalSince1970 * -1000)) { (motiveAndUsers) in
                self.feedMotives = motiveAndUsers
                // hide loading for both
                self.mapViewDelegate?.hideLoading()
                self.feedViewDelegate?.hideLoading()
            }
            lastExplorePostTime = Int64(NSDate().timeIntervalSince1970 * -1000)
            getExploreData(currentUser: currentUser) { (motiveAndUsers) in
                self.exploreMotives = motiveAndUsers
                
                self.exploreViewDelegate?.hideLoading()
            }

        }
    }
    
    // get all of the initial posts of the feed
    func getFeedData(currentUser: CurrentUser, previousQueryTime: Int64, completionHandler:@escaping(_ motiveAndUsers: [MotiveAndUser])-> Void) {
        var motiveAndUsers: [MotiveAndUser] = []
        let myGroup = DispatchGroup()
        // add 2 days time
        let queryTime = previousQueryTime + (24 * 60 * 60 * 1000 * 2)
        // get thier own motives
        var following = currentUser.followingSet
        following.insert(currentUser.user.uid)
        // iterate through followers uids
        for followingUid in following {
            myGroup.enter()
            // query for posts within 2 days time
            usersPostReference.child(followingUid).queryOrderedByValue().queryEnding(atValue: queryTime).queryStarting(atValue: previousQueryTime).observeSingleEvent(of: .value, with: { (posts) in
                let innerGroup = DispatchGroup()
                for post in posts.children {
                    innerGroup.enter()
                    if let postSnapshot = post as? DataSnapshot {
                        self.getMotiveAndUser(postID: postSnapshot.key, completionHandler: { (motiveAndUser) in
                            if let motiveAndUser = motiveAndUser {
                                motiveAndUsers.append(motiveAndUser)
                            }
                            // determine if the user is going to the motive after you load it
                            self.usersGoingReference.child(currentUser.user.uid).child(postSnapshot.key).observeSingleEvent(of: .value, with: { (snapshot) in
                                if snapshot.exists() {
                                    // add to the user going set
                                    self.userMotiveGoingSet.insert(postSnapshot.key)
                                }
                                innerGroup.leave()
                            })
                        })
                    } else {
                        innerGroup.leave()
                    }

                }
                // once each post for that specific userID has been loaded
                innerGroup.notify(queue: .main) {
                    myGroup.leave()
                }
          
            })
        }
        myGroup.notify(queue: .main) {
            completionHandler(motiveAndUsers)
        }
    }
    
    var lastExplorePostTime: Int64 = 0
    var outOfExploreMotives: Bool = false
    func getExploreData(currentUser: CurrentUser, completionHandler:@escaping(_ motiveAndUsers: [MotiveAndUser])-> Void) {
        if outOfExploreMotives { return }
        var motiveAndUsers: [MotiveAndUser] = []
        // query exploreMotives reference
        exploreMotivesReference.queryOrderedByValue().queryStarting(atValue: lastExplorePostTime + 1).queryLimited(toFirst: numMotivesToLoad).observeSingleEvent(of: .value) { (snapshot) in
            if snapshot.exists() {
                var snapshotArray = [DataSnapshot]()
                // get all ids that the user is going
                for item in snapshot.children {
                    let snap = item as! DataSnapshot
                    snapshotArray.append(snap)
                }
                snapshotArray.sort(by: {( ($0.value as! Int64) < ($1.value as! Int64) )})
                self.lastExplorePostTime = snapshotArray.last?.value as! Int64
                let myGroup = DispatchGroup()
                for (_ , motiveIdSnapshot) in snapshotArray.enumerated() {
                    myGroup.enter()
                    self.getMotiveAndUser(postID: motiveIdSnapshot.key, completionHandler: { (motiveAndUser) in
                        if let motiveAndUser = motiveAndUser {
                            motiveAndUsers.append(motiveAndUser)
                        }
                        // determine if the user is going to the motive after you load it
                        self.usersGoingReference.child(currentUser.user.uid).child(motiveIdSnapshot.key).observeSingleEvent(of: .value, with: { (snapshot) in
                            if snapshot.exists() {
                                // add to the user going set
                                self.userMotiveGoingSet.insert(motiveIdSnapshot.key)
                            }
                            myGroup.leave()
                        })
                    })
                }
                myGroup.notify(queue: .main) {
                    completionHandler(motiveAndUsers)
                }
            } else {
                self.outOfExploreMotives = true
            }
        }
        
    }
    
    func exploreSentRefresh() {
        if let currentUser = self.currentUser {
            lastExplorePostTime = Int64(NSDate().timeIntervalSince1970 * -1000)
            outOfExploreMotives = false
            exploreMotives.removeAll()
            getExploreData(currentUser: currentUser) { (motiveAndUsers) in
                self.exploreMotives = motiveAndUsers
                self.exploreViewDelegate?.hideLoading()
            }
        }
    }
    
    func exploreGetMoreMotives() {
        if let currentUser = self.currentUser {
            getExploreData(currentUser: currentUser) { (motiveAndUsers) in
                self.exploreMotives = self.exploreMotives + motiveAndUsers
                self.exploreViewDelegate?.hideLoading()
            }
        }
    }
    
    
    func exploreSelectedMotive(motive: Motive) {
        self.selectedIndex = 0
    }
    
    
    func getMotiveAndUser(postID: String, completionHandler:@escaping(_ motiveAndUser: MotiveAndUser?)-> Void) {
        motivesReference.child(postID).observeSingleEvent(of: .value) { (motiveSnapshot) in
            if motiveSnapshot.exists() {
                let motive = Motive(snapshot: motiveSnapshot)
                self.motiveHashTable.updateValue(motive, forKey: motive.id)
                if let user = self.userHashTable.value(forKey: motive.creator) {
                    completionHandler(MotiveAndUser(motive: motive, user: user))
                } else {
                    self.getUser(uid: motive.creator, completionHandler: { (user) in
                        if let user = user {
                            self.userHashTable.updateValue(user, forKey: user.uid)
                            completionHandler(MotiveAndUser(motive: motive, user: user))
                        } else {
                            completionHandler(nil)
                        }
                    })
                }
                
            } else {
                completionHandler(nil)
            }
        }
    }



    
    // from feedview
    func feedSelectedMotive(motive: Motive) {
        self.selectedIndex = 0
        return
    }
    
    // from mapview
    func goToFeed() {
        self.selectedIndex = 1
    }

}

