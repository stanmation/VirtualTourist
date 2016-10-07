//
//  MapViewController.swift
//  VirtualTourist
//
//  Created by Stanley Darmawan on 29/09/2016.
//  Copyright © 2016 Stanley Darmawan. All rights reserved.
//

import UIKit
import MapKit
import CoreData


class MapViewController: UIViewController, NSFetchedResultsControllerDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    
    var annotations = [MKPointAnnotation]()
    var annotationView: MKAnnotationView?
    
    let delegate = UIApplication.sharedApplication().delegate as! AppDelegate
    var stack: CoreDataStack?

    
    var fetchedResultsController: NSFetchedResultsController?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // set up gesture for the map
        let addPin = UILongPressGestureRecognizer(target: self, action: #selector(addPin(_:)))
        mapView.addGestureRecognizer(addPin)
        
        // Get the stack
        stack = delegate.stack
        
        // Create a fetchrequest
        let fr = NSFetchRequest(entityName: "Pin")
        fr.sortDescriptors = []

        // Create the FetchedResultsController
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fr, managedObjectContext: stack!.context, sectionNameKeyPath: nil, cacheName: nil)
        
        do {
            try fetchedResultsController!.performFetch()
        } catch let e as NSError {
            print("Error while trying to perform a search: \n\(e)\n\(fetchedResultsController)")
        }
        
        fetchedResultsController?.delegate = self
        
        if fetchedResultsController!.fetchedObjects != nil {
            for object in fetchedResultsController!.fetchedObjects! {
                let pin = object as! Pin
                let annotation = MKPointAnnotation()
                annotation.coordinate = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
                annotations.append(annotation)
            }
            mapView.addAnnotations(annotations)
        }
        

    }
    
    func addPin(sender: UILongPressGestureRecognizer!) {
        if sender.state == UIGestureRecognizerState.Began {
            
            // make annotation our of the touch
            let touchPoint = sender.locationInView(mapView)
            let newCoordinate = mapView.convertPoint(touchPoint, toCoordinateFromView: mapView)
            let annotation = MKPointAnnotation()
            annotation.coordinate = newCoordinate
            self.annotations.append(annotation)
            mapView.addAnnotations(annotations)
            
            var pin: Pin?
            
            stack?.performBackgroundBatchOperation({ (workerContext) in
                pin = Pin(latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude, context: workerContext)
                print("Just created a pin: \(pin)")
            })

            Client.sharedInstance().displayImageFromFlickrBySearch(annotation, completionHandler: { (results, errorString) in
                performUIUpdatesOnMain{
                    self.generatePhotos(pin!, imageURLs: results)
                }
            })
                
        }
    }
    
    
    // generate photo objects from the pin
    func generatePhotos(pin: Pin, imageURLs: [String]) {

        stack?.performBackgroundBatchOperation({ (workerContext) in
            for imageURL in imageURLs {
                let photo = Photo(urlString: imageURL, context: workerContext)
                photo.pin = pin
  
                print("Just created a photo: \(photo)")
                
                Client.sharedInstance().getImage(photo.url) { (result, error) in
                    self.generatePhotoData(photo.url!, data: result)
                }
            }
            print("==== finished background operation ====")
        })
        

    }
    // generate photoData from the photo url
    func generatePhotoData(urlString: String, data: NSData) {
        stack?.performBackgroundBatchOperation({ (workerContext) in
            
            let fr = NSFetchRequest(entityName: "Photo")
            let predicate = NSPredicate(format: "url == %@", urlString)
            fr.predicate = predicate
            fr.sortDescriptors = [NSSortDescriptor(key: "dateUpdated", ascending: true)]
            
            guard let photos = try? workerContext.executeFetchRequest(fr) as! [Photo] else {
                return
            }
            
            let photo = photos[0]
            photo.imageData = data
            
        })
        
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        print("perform segue")
        if segue.identifier == "showAlbum" {
            if segue.destinationViewController is PhotoAlbumViewController {
                
                let pin = sender as! Pin
                print("pin is \(pin) ")

                let fr = NSFetchRequest(entityName: "Photo")
                let predicate = NSPredicate(format: "pin == %@", pin)
                fr.predicate = predicate
                fr.sortDescriptors = [NSSortDescriptor(key: "dateUpdated", ascending: true)]

                guard let photos = try? stack?.context.executeFetchRequest(fr) as! [Photo] else {
                    print("An error occurred while retrieving photos for selected pin!")
                    return
                }
                
                print("put photos1: \(photos)")
                
                let controller = segue.destinationViewController as! PhotoAlbumViewController
                controller.fetchRequest = fr
                controller.pin = pin
            }

        }
    }
    
    
    // MARK: Delegate methods
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        print("did select annotation")
        
        stack?.save()
        
        mapView.deselectAnnotation(view.annotation , animated: false)
        
        let pinLat = view.annotation!.coordinate.latitude
        let pinLon = view.annotation!.coordinate.longitude
        
        let fr = NSFetchRequest(entityName: "Pin")
        let predicate = NSPredicate(format: "latitude == %lf && longitude == %lf", pinLat, pinLon)
        fr.predicate = predicate
        
        guard let pinsFound =
            try? stack!.context.executeFetchRequest(fr) as! [Pin] where pinsFound.count == 1 else {
                
                print("Unable to locate selected pin in database!")
                return
        }
        
        performSegueWithIdentifier("showAlbum", sender: pinsFound[0])

    }
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        print("change content")
    }
    

}

