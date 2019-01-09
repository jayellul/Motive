//
//  Motive.swift
//  wyd
//
//  Created by Jason Ellul on 2018-06-04.
//  Copyright © 2018 Jason Ellul. All rights reserved.
//

import Foundation
import Firebase

struct Motive {

    static let kIDKey = "id"
    static let kTextKey = "text"
    static let kCreatorKey = "creator"
    // latitude before longitude
    static let kLatitudeKey = "latitude"
    static let kLongitudeKey = "longitude"
    static let kTimeKey = "time"
    static let kNumGoingKey = "numGoing"
    static let kNumCommentsKey = "nC"
    static let kIconKey = "icon"
    
    let id: String
    let text: String
    let creator: String
    let latitude: Double
    let longitude: Double
    let time: Int64
    var numGoing: Int
    var numComments: Int
    var icon: Int
    let firebaseReference: DatabaseReference?
    
    // Initializer for instantiating a new Motive in code.
    init(id: String, text: String, creator: String, latitude: Double, longitude: Double, time: Int64, numGoing: Int, numComments: Int, icon: Int) {
        self.id = id
        self.text = text
        self.creator = creator
        self.latitude = latitude
        self.longitude = longitude
        self.time = time
        self.numGoing = numGoing
        self.numComments = numComments
        self.icon = icon
        self.firebaseReference = nil
    }
    
    // Initializer for instantiating a Motive received from Firebase.
    init(snapshot: DataSnapshot) {
        let snapshotValue = snapshot.value as! [String: Any]
        self.id = snapshotValue[Motive.kIDKey] as! String
        self.text = snapshotValue[Motive.kTextKey] as! String
        self.creator = snapshotValue[Motive.kCreatorKey] as! String
        self.latitude = snapshotValue[Motive.kLatitudeKey] as! Double
        self.longitude = snapshotValue[Motive.kLongitudeKey] as! Double
        self.time = snapshotValue[Motive.kTimeKey] as! Int64
        self.numGoing = snapshotValue[Motive.kNumGoingKey] as! Int
        self.numComments = snapshotValue[Motive.kNumCommentsKey] as! Int
        self.icon = snapshotValue[Motive.kIconKey] as! Int
        self.firebaseReference = snapshot.ref
    }
    
    
}

// motive and user object - to help with async and SORTING
class MotiveAndUser: NSObject {
    var motive: Motive
    var user: User
    var index = 0
    
    init(motive: Motive, user: User) {
        self.motive = motive
        self.user = user
    }
    
}


struct Comment {
    
    static let kIDKey = "id"
    static let kTextKey = "text"
    static let kUserKey = "user"
    static let kTimeKey = "time"
    
    let id: String
    let text: String
    let creatorID: String
    let time: Int64
    let firebaseReference: DatabaseReference?
    
    // Initializer for instantiating a new motive comment in code.
    init(id: String, text: String, creatorID: String, time: Int64) {
        self.id = id
        self.text = text
        self.creatorID = creatorID
        self.time = time
        self.firebaseReference = nil
    }
    
    // Initializer for instantiating a Motive received from Firebase.
    init(snapshot: DataSnapshot) {
        let snapshotValue = snapshot.value as! [String: Any]
        self.id = snapshotValue[Comment.kIDKey] as! String
        self.text = snapshotValue[Comment.kTextKey] as! String
        self.creatorID = snapshotValue[Comment.kUserKey] as! String
        self.time = snapshotValue[Comment.kTimeKey] as! Int64
        self.firebaseReference = snapshot.ref
    }
    
    
}

class CommentAndUser: NSObject {
    var comment: Comment
    var user: User
    // optional sorting index
    var index = 0
    
    init(comment: Comment, user: User) {
        self.comment = comment
        self.user = user
    }
    
}


