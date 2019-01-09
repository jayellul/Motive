//
//  FeedViewController.swift
//  wyd
//
//  Created by Jason Ellul on 2018-05-10.
//  Copyright © 2018 Jason Ellul. All rights reserved.
//

import Foundation
import UIKit
import Firebase

// delagate table tutorials
// https://www.codementor.io/brettr/two-basic-ways-to-populate-your-uitableview-du107rsyx
// https://www.weheartswift.com/firebase-101/
//
class FeedViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    static let kUsersListPath = "users"
    
    let usersReference = Database.database().reference(withPath: kUsersListPath)
    var users = [User]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        tableView.tableFooterView = UIView (frame: CGRect.zero)
        self.usersReference.queryOrdered(byChild: User.kUsernameKey).observe(.value, with: {
            snapshot in
            var items: [User] = []
            for item in snapshot.children {
                let user = User(snapshot: item as! DataSnapshot)
                //print (user)
                items.append(user)
            }
            
            self.users = items
            self.tableView.reloadData()
        })
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

extension FeedViewController: UITableViewDelegate , UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.users.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UserTableViewCell")
        let cell = tableView.dequeueReusableCell(withIdentifier: "UserTableViewCell") as! UserTableViewCell
        let user = users[indexPath.row]
        //cell.textLabel?.text = user.username
        //cell.detailTextLabel?.text = user.email
        cell.titleLabel?.text = user.username
        cell.emailLabel?.text = user.email
        // default while loading ** Fix
        cell.profileImageView.image = UIImage(named: "Images/default user icon.png")

        if let profileImageURL = user.photoURL {
            let url = URL(string: profileImageURL)
            URLSession.shared.dataTask(with: url!, completionHandler: {(data, response, error) in
                    //download hit error
                    if error != nil {
                        print(error!.localizedDescription)
                        return
                    }
                    
                    DispatchQueue.main.async() {
                        //cell.imageView?.image = UIImage(data: data!)
                        cell.profileImageView.image = UIImage(data: data!)
                    }
            }).resume()
        }
        return cell
    }

}

