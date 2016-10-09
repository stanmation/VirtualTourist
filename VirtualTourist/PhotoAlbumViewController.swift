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
    var photoExist = false
    
    var selectedIndexes = [NSIndexPath]()
    var insertedIndexPaths:[NSIndexPath]!
    var deletedIndexPaths: [NSIndexPath]!
    var updatedIndexPaths: [NSIndexPath]!
    
    var annotationView: MKAnnotationView?
    
    @IBOutlet weak var myCollectionView: UICollectionView!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    
    @IBOutlet weak var newCollectionButton: UIButton!
    @IBOutlet weak var mapView: MKMapView!
    
    let stack = (UIApplication.sharedApplication().delegate as! AppDelegate).stack
    let client = Client.sharedInstance()
    
    // MARK: - NSFetchedResultsController
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: self.fetchRequest!, managedObjectContext: self.stack.context, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        
        return fetchedResultsController
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("viewDidLoad in PHotoAlbumVC")
        
        executeSearch()
        
        // place the Pin on the map
        let annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2D(latitude: pin!.latitude, longitude: pin!.longitude)
        mapView.addAnnotation(annotation)
        let span = MKCoordinateSpanMake(0.075, 0.075)
        let region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude), span: span)
        mapView.setRegion(region, animated: true)
        
        
        // if there's no photo yet then we upload photos
        if !photoExist {
            print("retrieve images")
            self.client.displayImageFromFlickrBySearch(annotation.coordinate.latitude, longitude: annotation.coordinate.longitude, completionHandler: { (results, errorString) in
                performUIUpdatesOnMain({ 
                    self.generatePhotos(self.pin!, imageURLs: results)

                })
            })
        }
        
    }
    
    // will change the size of each cell when the orientation changes
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        // setup flow layout
        let space: CGFloat = 5.0
        let dimension = (self.view.frame.size.width - (2 * space)) / 3.0
        flowLayout.minimumInteritemSpacing = space
        flowLayout.minimumLineSpacing = space
        flowLayout.itemSize = CGSizeMake(dimension, dimension)
        flowLayout.invalidateLayout()
    }
    
    @IBAction func newCollectionButtonPressed(sender: AnyObject) {
        newCollectionButton.enabled = false
    
        guard let photos = try? stack.context.executeFetchRequest(fetchRequest!) as! [NSManagedObject] else {
            print("An error occurred while retrieving photos for selected pin!")
            return
        }
        
        for photo in photos {
            stack.context.deleteObject(photo)
        }
                
        client.displayImageFromFlickrBySearch(pin!.latitude, longitude: pin!.longitude, completionHandler: { (results, errorString) in
            performUIUpdatesOnMain({ 
                self.generatePhotos(self.pin!, imageURLs: results)
            })
        })
    }
    
    // generate photo objects from the pin
    func generatePhotos(tempPin: Pin, imageURLs: [String]) {
        print("generatePhotos")
        
        // create pin that will be put into BackgroundContext
        let fr = NSFetchRequest(entityName: "Pin")
        let predicate = NSPredicate(format: "latitude == %lf && longitude == %lf", tempPin.latitude, tempPin.longitude)
        fr.predicate = predicate

        stack.performBackgroundBatchOperation({ (workerContext) in
            
            guard let pinsFound = try? workerContext.executeFetchRequest(fr) as! [Pin] where pinsFound.count == 1 else {
                print("Unable to locate selected pin in database!")
                return
            }
            
            let pin = pinsFound[0]
            
            for imageURL in imageURLs {
                let photo = Photo(urlString: imageURL, context: workerContext)
                photo.pin = pin
                
                print("Just created a photo: \(photo)")
                
                // generate photoData from the photo url
                
                self.client.getImage(photo.url!) { (result, error) in
                    self.generatePhotoData(photo, data: result!)
                }
            }

        })
    }
    
    // function to generate photoData from the photo url
    func generatePhotoData(photo:Photo, data: NSData) {
        print("generatePhotoData")
        stack.performBackgroundBatchOperation({ (workerContext) in
            photo.imageData = data
        })
        newCollectionButton.enabled = true
        stack.save()
    }
    
    
    // MARK: - UICollectionViewDelegate
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        
        // Get the cell
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("photoCell", forIndexPath: indexPath) as! PhotoCollectionViewCell
        
        if photo.imageData != nil {
            cell.photoImageView.image = UIImage(data: photo.imageData!)
            cell.activityIndicator.hidden = true
        } else {
            cell.photoImageView.image = UIImage(named: "noImages")
            cell.activityIndicator.hidden = false
        }
        
        return cell
    }

    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        // remove photo that's been tapped
        let photo = self.fetchedResultsController.objectAtIndexPath(indexPath) as! NSManagedObject
        stack.context.deleteObject(photo)
        stack.save()
    }

}



// MARK: - UICollectionViewDataSource

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

// MARK: - CollectionViewController (Fetches)

extension PhotoAlbumViewController {
    
    func executeSearch() {
        do {
            try fetchedResultsController.performFetch()
        } catch let e as NSError {
            print("Error while trying to perform a search: \n\(e)\n\(fetchedResultsController)")
        }
    }
}

// MARK: - NSFetchedResultsControllerDelegate

extension PhotoAlbumViewController {
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
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








