//
//  ExtensionViewController.swift
//  RigMarketplace
//
//  Created by Jin Shan Ng on 24/04/2023.
//

import Foundation
import UIKit

extension UIViewController {
    
    /**
     Reusable display message function
     */
    func displayMessage(title: String, message: String, action: UIAlertAction?) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        //Check if action and style is specified
        if let action {
            alertController.addAction(action)
        } else {
            alertController.addAction(UIAlertAction(title: "Close", style: .default, handler: nil))
        }
        
        //add to view
        self.present(alertController, animated: true, completion: nil)
    }
    
    /**
     confirmation display message function
     @params:
     title: alert title
     message: alert message
     confirmationAction: confirmation action on success (primary action)
     altTitle: secondary action title
     */
    func displayConfirmationMessage(title: String, message: String, confirmationAction: UIAlertAction, altTitle: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: altTitle, style: .default, handler: nil))
        alertController.addAction(confirmationAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    
    /**
     resuable loading animation functions
     */
    private static var loadingViewKey: UInt8 = 0
        
    private var loadingView: LoadingView? {
        get {
            return objc_getAssociatedObject(self, &UIViewController.loadingViewKey) as? LoadingView
        }
        set {
            objc_setAssociatedObject(self, &UIViewController.loadingViewKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    func showLoadingAnimation() {
        if loadingView == nil {
            loadingView = LoadingView(frame: view.bounds)
            view.addSubview(loadingView!)
        }
        
        loadingView?.startAnimating()
    }
    
    func hideLoadingAnimation() {
        loadingView?.stopAnimating()
        loadingView?.removeFromSuperview()
    }
    
    /**
     function to convert hex string to UIColour
     */
    func hexStringToUIColor (hex:String) -> UIColor {
        var cString:String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        if (cString.hasPrefix("#")) {
            cString.remove(at: cString.startIndex)
        }

        if ((cString.count) != 6) {
            return UIColor.gray
        }

        var rgbValue:UInt64 = 0
        Scanner(string: cString).scanHexInt64(&rgbValue)

        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
    
}
