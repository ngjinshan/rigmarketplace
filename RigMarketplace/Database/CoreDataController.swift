//
//  CoreDataController.swift
//  RigMarketplace
//
//  Created by Jin Shan Ng on 24/04/2023.
//

import UIKit
import CoreData

class CoreDataController: NSObject, CDatabaseProtocol, NSFetchedResultsControllerDelegate {
    
    var listeners = MulticastDelegate<CDatabaseListener>()
    var persistentContainer: NSPersistentContainer
    var cartFetchResultsController: NSFetchedResultsController<Cart>?
    
    override init() {
        persistentContainer = NSPersistentContainer(name: "CoreDataModel")
        persistentContainer.loadPersistentStores() { (description, error) in
            if let error = error {
                fatalError("failed to laod core data \(error)")
            }
        }
        
        super.init()
    }
    
    func cleanup() {
        if persistentContainer.viewContext.hasChanges {
            do {
                try persistentContainer.viewContext.save()
            } catch {
                fatalError("failed to save changes \(error)")
            }
        }
    }
    
    /**
     function to add item to cart
     @params:
     item: item to be added into cart
     @return:
     Cart: cart object created
     */
    func addItemToCart(item: Item) -> Cart {
        //add cart
        let cart = NSEntityDescription.insertNewObject(forEntityName: "Cart", into: persistentContainer.viewContext) as! Cart
        cart.itemID = item.id
        cart.itemName = item.name
        cart.itemPrice = item.price!
        cart.itemPicture = item.picture
        return cart
    }
        
    /**
     function to delete item from cart
     @params:
     cart: Cart object to be deleted
     */
    func deleteItemFromCart(cart: Cart) {
        persistentContainer.viewContext.delete(cart)
    }
    
    //fetch cart function
    func fetchCart() -> [Cart] {
        
        if cartFetchResultsController == nil {
            let request: NSFetchRequest<Cart> = Cart.fetchRequest()
            let sortDescriptor = NSSortDescriptor(key: "itemName", ascending: true)
            request.sortDescriptors = [sortDescriptor]
            
            cartFetchResultsController = NSFetchedResultsController<Cart>(fetchRequest: request, managedObjectContext: persistentContainer.viewContext, sectionNameKeyPath: nil, cacheName: nil)
            
            cartFetchResultsController?.delegate = self
            
            do {
                try cartFetchResultsController?.performFetch()
            } catch {
                print("fetch failed: \(error)")
            }
        }
        
        if let cart = cartFetchResultsController?.fetchedObjects {
            return cart
        }
        
        return [Cart]()
    }
    

    
    func addListener(listener: CDatabaseListener) {
        listeners.addDelegate(listener)
        
        if listener.listenerType == .cart || listener.listenerType == .all {
            listener.onCartChange(change: .update, cart: fetchCart())
        }
    }
    
    func removeListener(listener: CDatabaseListener) {
        listeners.removeDelegate(listener)
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        if controller == cartFetchResultsController {
            listeners.invoke() { listener in
                if listener.listenerType == .cart {
                    listener.onCartChange(change: .update, cart: fetchCart())
                }
            }
        }
    }
}
