//
//  ForumAddPartViewController.swift
//  RigMarketplace
//
//  Created by Jin Shan Ng on 16/05/2023.
//

import UIKit
import FirebaseStorage

class ForumAddPartViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var priceField: UITextField!
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var segmentControl: UISegmentedControl!
    
    var databaseController: DatabaseProtocol?
    var task: StorageDownloadTask?
    var storage: Storage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
        storage = databaseController!.storage
        
    }
    
    @IBAction func addImage(_ sender: Any) {
        let picker = UIImagePickerController()
        picker.allowsEditing = true
        picker.delegate = self
        
        let actionSheet = UIAlertController(title: "Add Photo", message: "Choose a source", preferredStyle: .actionSheet)
        
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let cameraAction = UIAlertAction(title: "Camera", style: .default) { _ in
                picker.sourceType = .camera
                self.present(picker, animated: true, completion: nil)
            }
            
            actionSheet.addAction(cameraAction)
        }
        
        let galleryAction = UIAlertAction(title: "Gallery", style: .default) { _ in
            picker.sourceType = .photoLibrary
            self.present(picker, animated: true, completion: nil)
        }
        
        actionSheet.addAction(galleryAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        actionSheet.addAction(cancelAction)
        
        present(actionSheet, animated: true, completion: nil)
    }
    
    @IBAction func addPart(_ sender: Any) {
        let postpart = PostPart()
        postpart.id = UUID() //random uuid
        
        //name cannot be empty
        guard let partName = nameField.text, partName.isEmpty == false else {
            displayMessage(title: "Error", message: "Name cannot be empty", action: nil)
            return
        }
        
        //price cannot be empty
        guard let partPrice = Float(priceField.text!) else {
            displayMessage(title: "Error", message: "Price cannot be empty or must be number", action: nil)
            return
        }
        
        postpart.name = partName
        postpart.price = partPrice
        postpart.category = segmentControl.selectedSegmentIndex
        
        showLoadingAnimation()
        
        //upload image
        let uploadTask = databaseController?.updatePartImage(part: postpart, image: imageView.image)
        
        let action = UIAlertAction(title: "Close", style: .default, handler: {(alert: UIAlertAction!) in
            self.hideLoadingAnimation()
            self.databaseController?.postParts.append(postpart)
            self.navigationController?.popViewController(animated: true)
        })
        
        if let uploadTask {
            uploadTask.observe(.success) {
                snapshot in
                postpart.picture = "exists"
                self.displayMessage(title: "You're all set!", message: "Post part has been added", action: action)
            }
        } else {
            displayMessage(title: "You're all set!", message: "Post part has been added", action: action)

        }
    }
    
    @IBAction func segmentControlChanged(_ sender: Any) {
    }

}

extension ForumAddPartViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let image = info[.originalImage] as! UIImage
        self.imageView.image = image
        self.dismiss(animated: true, completion: nil)
    }
}
