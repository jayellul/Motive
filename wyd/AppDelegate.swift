//
//  AppDelegate.swift
//  wyd
//
//  Created by Jason Ellul on 2018-04-12.
//  Copyright © 2018 Jason Ellul. All rights reserved.
//

import UIKit
import Firebase

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    override init () {
        FirebaseApp.configure()
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // get Maps API Key
        //GMSServices.provideAPIKey("AIzaSyCoVejouOidr8M7b2NXIKQHI5Y9g1CQBIc")
        // Override point for customization after application launch.
        //FirebaseApp.configure()
        
        // auth listener - in case they get signed out of firebase somehow
        let authListener = Auth.auth().addStateDidChangeListener { auth, user in
            
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            
            if user != nil {
                // goto home map
                /*let controller = storyboard.instantiateViewController(withIdentifier: "customTabBarController") as! CustomTabBarController
                controller.currentUser = nil
                self.window?.rootViewController = controller
                self.window?.makeKeyAndVisible()*/
            } else {
                // goto initial screen controller so user can choose to sign in or sign up
                let controller = storyboard.instantiateViewController(withIdentifier: "InitialScreenViewController") as! InitialScreenViewController
                self.window?.rootViewController = controller
                self.window?.makeKeyAndVisible()
            }
        }
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        //self.saveContext()
    }

}

