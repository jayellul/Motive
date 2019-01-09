//
//  User.swift
//  wyd
//
//  Created by Jason Ellul on 2018-05-16.
//  Copyright © 2018 Jason Ellul. All rights reserved.
//

import Foundation
import Firebase

struct User {
    
    static let kUidKey = "uid"
    static let kUsernameKey = "un"
    static let kDisplayKey = "dis"
    static let kPhotoURLKey = "pURL"
    static let kNumFollowersKey = "nFers"
    static let kNumFollowingKey = "nFing"
    // latitude before longitude
    static let kPointLatitudeKey = "pLat"
    static let kPointLongitudeKey = "pLong"
    static let kZoomLevelKey = "zl"
    
    let uid: String
    let username: String
    let display: String
    let photoURL: String
    var numFollowers: Int
    var numFollowing: Int
    // request sent - use in stead of downloading all uids for currentUser object
    var requestSent: Bool = false
    let pointLatitude: Double
    let pointLongitude: Double
    let zoomLevel: Double
    let firebaseReference: DatabaseReference?
    
    // Initializer for instantiating a User object in code.
    init(uid: String, username: String, display: String, photoURL: String, numFollowers: Int, numFollowing: Int, pointLatitude: Double, pointLongitude: Double, zoomLevel: Double) {
        self.uid = uid
        self.username = username
        self.display = display
        self.photoURL = photoURL
        self.numFollowers = numFollowers
        self.numFollowing = numFollowing
        self.pointLatitude = pointLatitude
        self.pointLongitude = pointLongitude
        self.zoomLevel = zoomLevel
        self.firebaseReference = nil
    }
    
    // Initializer for instantiating a User received from Firebase.
    init(snapshot: DataSnapshot) {
        let snapshotValue = snapshot.value as! [String: Any]
        self.uid = snapshotValue[User.kUidKey] as! String
        self.username = snapshotValue[User.kUsernameKey] as! String
        self.display = snapshotValue[User.kDisplayKey] as! String
        self.photoURL = snapshotValue[User.kPhotoURLKey] as! String
        self.numFollowers = snapshotValue[User.kNumFollowersKey] as! Int
        self.numFollowing = snapshotValue[User.kNumFollowingKey] as! Int
        self.pointLatitude = snapshotValue[User.kPointLatitudeKey] as! Double
        self.pointLongitude = snapshotValue[User.kPointLongitudeKey] as! Double
        self.zoomLevel = snapshotValue[User.kZoomLevelKey] as! Double
        self.firebaseReference = snapshot.ref
    }
    
    
}

// object - current user and thier friend requests + blocked users + friends
class CurrentUser: NSObject {
    var user: User
    // requests the user has recieved - array for ordering
    var requests: [String]
    // this is a set for instant access
    var followingSet: Set<String>
    var blockedSet: Set<String>
    // option bool is set if user is private
    var isPrivate: Bool = false
    // Initializer for instantiating a UserAndFriends object in code
    init(user: User, followingSet: Set<String>, requests: [String], blockedSet: Set<String>) {
        self.user = user
        self.followingSet = followingSet
        self.requests = requests
        self.blockedSet = blockedSet
    }
}


