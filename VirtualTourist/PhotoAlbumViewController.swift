//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Stanley Darmawan on 29/09/2016.
//  Copyright © 2016 Stanley Darmawan. All rights reserved.
//

import UIKit
import CoreData
import MapKit



class PhotoAlbumViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, MKMapViewDelegate, NSFetchedResultsControllerDelegate {
    
    var pin: Pin?
    var fetchRequest: NSFetchRequest?
    
    var selectedIndexes = [NSIndexPath]()
    var insertedIndexPaths:[NSIndexPath]!
    var deletedIndexPaths: [NSIndexPath]!
    var updatedIndexPaths: [NSIndexPath]!
    
    @IBOutlet weak var myCollectionView: UICollectionView!
    @IBOutlet weak var newCollectionButton: UIToolbar!
    
    let delegate = UIApplication.sharedApplication().delegate as! AppDelegate
    var stack: CoreDataStack?
    
    // MARK: - NSFetchedResultsController
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let delegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let stack = delegate.stack
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: self.fetchRequest!, managedObjectContext: stack.context, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        
        return fetchedResultsController
    }()
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        executeSearch()
        
    }
    
    override func viewWillDisappear(animated: Bool) {
        
        let delegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let stack = delegate.stack
        stack.save()
    }
    
    
    @IBAction func newCollectionButtonPressed(sender: AnyObject) {
        
        
    }
    
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        
        // Get the cell
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("photoCell", forIndexPath: indexPath) as! PhotoCollectionViewCell
        
        
        if photo.imageData != nil {
            cell.photoImageView.image = UIImage(data: photo.imageData!)

        } else {
            cell.photoImageView.image = UIImage(named: "test")
        }
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        let stack = delegate.stack
        let photo = self.fetchedResultsController.objectAtIndexPath(indexPath) as! NSManagedObject
        
        stack.context.deleteObject(photo)

    }

}



// MARK: - CoreDataCollectionViewController (UITableViewDataSource)

extension PhotoAlbumViewController {
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        print("number of sections: \(fetchedResultsController.sections?.count)")
        return fetchedResultsController.sections?.count ?? 0
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sectionInfo = fetchedResultsController.sections![section]
        
        print("number Of Cells: \(sectionInfo.numberOfObjects)")
        return sectionInfo.numberOfObjects
    }
    
    
}

// MARK: - CoreDataCollectionViewController (Fetches)

extension PhotoAlbumViewController {
    
    func executeSearch() {
        do {
            try fetchedResultsController.performFetch()
        } catch let e as NSError {
            print("Error while trying to perform a search: \n\(e)\n\(fetchedResultsController)")
        }
    }
}

// MARK: - CoreDataCollectionViewController: NSFetchedResultsControllerDelegate

extension PhotoAlbumViewController {
    
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        print("controllerWillChangeContent")
        
        insertedIndexPaths = [NSIndexPath]()
        deletedIndexPaths = [NSIndexPath]()
        updatedIndexPaths = [NSIndexPath]()
    }

    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject,atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType,newIndexPath: NSIndexPath?) {
        print("controller didChangeObject atIndexPath")
        
        switch type{
            case .Insert:
                print("Insert an item.")
                print("indexPath: \(indexPath) newIndexPath: \(newIndexPath)")
                insertedIndexPaths.append(newIndexPath!)
                break
            case .Delete:
                print("Delete an item.")
                deletedIndexPaths.append(indexPath!)
                break
            case .Update:
                print("Update an item.")
                updatedIndexPaths.append(indexPath!)
                break
            case .Move:
                print("Move an item. We don't expect to see this in this app.")
                break
        }
        

    }

    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        print("controllerDidChangeContent. changes.count: \(insertedIndexPaths.count + deletedIndexPaths.count)")
        
        myCollectionView.performBatchUpdates({() -> Void in
            
            for indexPath in self.insertedIndexPaths {
                self.myCollectionView.insertItemsAtIndexPaths([indexPath])
            }
            
            for indexPath in self.deletedIndexPaths {
                self.myCollectionView.deleteItemsAtIndexPaths([indexPath])
            }
            
            for indexPath in self.updatedIndexPaths {
                self.myCollectionView.reloadItemsAtIndexPaths([indexPath])
            }
            
            }) { (Bool) in
                self.myCollectionView.reloadData()

            }
    }
    

    
    
    
}








