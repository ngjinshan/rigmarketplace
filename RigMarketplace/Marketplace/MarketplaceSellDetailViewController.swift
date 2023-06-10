//
//  MarketplaceSellDetailViewController.swift
//  RigMarketplace
//
//  Created by Jin Shan Ng on 24/04/2023.
//

import UIKit
import FirebaseStorage

class MarketplaceSellDetailViewController: UIViewController, DatabaseListener {

    @IBOutlet weak var priceField: UITextField!
    @IBOutlet weak var descriptionField: UITextField!
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var imageField: UIImageView!
    var listenerType: ListenerType = .items
    var databaseController: DatabaseProtocol?
    var task: StorageDownloadTask?
    
    var item: Item? //item from marketplaceviewcontroller segue
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
        
        //set fields to item from segue
        if let item {
            nameField.text = item.name
            descriptionField.text = item.itemDescription
            priceField.text = "\(item.price!)"
            
            //get item image
            if(item.picture?.isEmpty == false) {
                task = databaseController?.getItemImage(item: item, imageView: self.imageField)
            }
        }
    }
    
    //save button handler
    @IBAction func saveButton(_ sender: Any) {
        
        //name cannot be empty
        guard let name = nameField.text, nameField.text?.isEmpty == false else {
            displayMessage(title: "Error", message: "Name cannot be empty", action: nil)
            return
        }
        
        //description cannot be empty
        guard let itemDescription = descriptionField.text, itemDescription.isEmpty == false else {
            displayMessage(title: "Error", message: "Description cannot be empty", action: nil)
            return
        }
        
        //price must be number and cannot be empty
        guard let price = Float(priceField.text!) else {
            displayMessage(title: "Error", message: "Price must be numbers", action: nil)
            return
        }
        
        item?.name = name
        item?.itemDescription = itemDescription
        item?.price = price
        
        showLoadingAnimation()
        
        //update item
        databaseController?.updateItem(item: item!)
        let uploadTask = databaseController?.updateItemImage(item: item!, image: imageField?.image)
        
        let action = UIAlertAction(title: "Close", style: .default, handler: {(alert: UIAlertAction!) in
            self.hideLoadingAnimation()
            self.navigationController?.popViewController(animated: true)
        })
        
        if let uploadTask {
            uploadTask.observe(.success) {
                snapshot in
                self.displayMessage(title: "You're all set!", message: "Your item has been updated", action: action)

            }
        } else {
            displayMessage(title: "You're all set!", message: "Your item has been updated", action: action)
        }
        
    }
    
    //delete button handler
    @IBAction func deleteButton(_ sender: Any) {
        let dangerAction = UIAlertAction(title: "Delete", style: .destructive, handler: {(alert: UIAlertAction!) in
            self.databaseController?.removeItem(item: self.item!) //delete item
            self.navigationController?.popViewController(animated: true)
        })
        displayConfirmationMessage(title: "Delete", message: "Are you sure you want to delete?", confirmationAction: dangerAction, altTitle: "Cancel")
    }
    
    //image picker function
    @IBAction func editImage(_ sender: Any) {
        let picker = UIImagePickerController()
        picker.allowsEditing = true
        picker.delegate = self
        present(picker, animated: true)
    }
    
    func onItemsChange(change: DatabaseChange, items: [Item]) {
        //nothing
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

    func onPostsChange(change: DatabaseChange, posts: [Post]) {
        //do nothing
    }
}

extension MarketplaceSellDetailViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let image = info[.originalImage] as! UIImage
        self.imageField.image = image
        self.dismiss(animated: true, completion: nil)
    }
}
