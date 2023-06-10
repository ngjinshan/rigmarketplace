//
//  ForumDetailViewController.swift
//  RigMarketplace
//
//  Created by Jin Shan Ng on 23/05/2023.
//

import UIKit
import FirebaseStorage

class ForumDetailViewController: UIViewController, DatabaseListener {
    
    var listenerType: ListenerType = .posts
    var databaseController: DatabaseProtocol?
    var task: StorageDownloadTask?
    var storage: Storage?
    var post: Post? //post from forumviewcontroller segue
    
    @IBOutlet weak var descriptionField: UILabel!
    @IBOutlet weak var deleteBtn: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var priceField: UILabel!
    @IBOutlet weak var userField: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
        storage = databaseController!.storage
        tableView.dataSource = self
        tableView.delegate = self
        
        //if post is user's, show delete button, else hide
        if databaseController?.currentUser?.uid != post!.user?.uid {
            deleteBtn.isHidden = true
        } else {
            deleteBtn.isHidden = false
        }
        
        if let post {
            userField.text = post.user?.email //set to email
            let price = databaseController?.getPostPrice(post.id!) //get all parts price
            priceField.text = "$\(price!)" //set to price
            descriptionField.text = post.postDescription //set to description
            
            //get image
            if(post.picture?.isEmpty == false) {
                task = databaseController?.getPostImage(post: post, imageView: imageView)
            }
        }
        // Do any additional setup after loading the view.
    }
    
    //delete button handler
    @IBAction func deleteButton(_ sender: Any) {
        let dangerAction = UIAlertAction(title: "Delete", style: .destructive, handler: {(alert: UIAlertAction!) in
            self.databaseController?.removePost(post: self.post!) //remove post from database
            self.navigationController?.popViewController(animated: true) //go back to previous screen
        })
        
        displayConfirmationMessage(title: "Delete", message: "Are you sure you want to delete?", confirmationAction: dangerAction, altTitle: "Cancel")
    }
        
    func onItemsChange(change: DatabaseChange, items: [Item]) {
        //do nothing
    }
    
    func onPostsChange(change: DatabaseChange, posts: [Post]) {
        //do nothing
    }
    
    func onWishlistChange(change: DatabaseChange, wishlist: [Item]) {
        //do nothing
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        databaseController?.addListener(listener: self)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        databaseController?.removeListener(listener: self)
    }

}

extension ForumDetailViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.FORUM_TABLE_CELL, for: indexPath)
        cell.textLabel?.text = post!.parts?[indexPath.row].name //set to part name
        cell.detailTextLabel?.text = "$\(post!.parts![indexPath.row].price!)" //set to part price
        
        cell.imageView?.image = nil //set image to nil while waiting for new downloadtask to be complete
        
        //get part image
        if post!.parts?[indexPath.row].picture?.isEmpty == false {
            task = databaseController?.getPartImage(part: (post!.parts?[indexPath.row])!, imageView: cell.imageView!)
        }
        
        if let task {
            task.observe(.success) { _ in 
                tableView.reloadData()
            }
        }
        

        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return post!.parts!.count
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            //delete image from storage?
            databaseController!.postParts.remove(at: indexPath.row)
            self.tableView.reloadData()
        } else if editingStyle == .insert {
            // do nothing
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch(section) {
        default: return "Parts"
        }
    }
    
}
