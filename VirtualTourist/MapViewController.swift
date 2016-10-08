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
    
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var mapView: MKMapView!
    
    var inEditingMode = false
    
    var annotationView: MKAnnotationView?
    
    let stack = (UIApplication.sharedApplication().delegate as! AppDelegate).stack

    var fetchedResultsController: NSFetchedResultsController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // set up gesture for the map
        let addPin = UILongPressGestureRecognizer(target: self, action: #selector(addPin(_:)))
        mapView.addGestureRecognizer(addPin)

        // Create a fetchrequest
        let fr = NSFetchRequest(entityName: "Pin")
        fr.sortDescriptors = []

        // Create the FetchedResultsController
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fr, managedObjectContext: stack.context, sectionNameKeyPath: nil, cacheName: nil)
        
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
                mapView.addAnnotation(annotation)

            }
        }
        
    }
    
    
    @IBAction func editButtonTapped(sender: UIButton) {
        if editButton.currentTitle == "Edit" {
            // set to editingMode
            editButton.setTitle("Done", forState: .Normal)
            inEditingMode = true
        } else if editButton.currentTitle == "Done" {
            // finish editingMode
            editButton.setTitle("Edit", forState: .Normal)
            inEditingMode = false
        }
    }
    
    
    // add pin to the mapView
    func addPin(sender: UILongPressGestureRecognizer!) {
        if sender.state == UIGestureRecognizerState.Began {
            
            // make annotation our of the touch
            let touchPoint = sender.locationInView(mapView)
            let newCoordinate = mapView.convertPoint(touchPoint, toCoordinateFromView: mapView)
            let annotation = MKPointAnnotation()
            annotation.coordinate = newCoordinate
            mapView.addAnnotation(annotation)
            
            var pin: Pin?
            
            stack.performBackgroundBatchOperation({ (workerContext) in
                pin = Pin(latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude, context: workerContext)
                print("Just created a pin: \(pin)")
            })
            
            stack.save()
            
        }
    }

    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        print("perform segue")
        if segue.identifier == "showAlbum" {
            if segue.destinationViewController is PhotoAlbumViewController {
                
                navigationItem.backBarButtonItem = UIBarButtonItem(title: "OK", style: UIBarButtonItemStyle.Plain, target: nil, action: nil)
                
                let pin = sender as! Pin
                print("pin is \(pin) ")

                let fr = NSFetchRequest(entityName: "Photo")
                let predicate = NSPredicate(format: "pin == %@", pin)
                fr.predicate = predicate
                fr.sortDescriptors = [NSSortDescriptor(key: "dateUpdated", ascending: true)]
                
                let controller = segue.destinationViewController as! PhotoAlbumViewController
                controller.fetchRequest = fr
                controller.pin = pin
                
                
                // check if photo exists in maincontext, then we set photoExist = true if there is
                guard let photos = try? stack.context.executeFetchRequest(fr) as! [Photo] else {
                    print("An error occurred while retrieving photos for selected pin!")
                    return
                }
                
                if photos != [] {
                    controller.photoExist = true
                }
            }
        }
    }
    
    
    // MARK: Delegate methods
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        
        mapView.deselectAnnotation(view.annotation , animated: false)
        
        let pinLat = view.annotation!.coordinate.latitude
        let pinLon = view.annotation!.coordinate.longitude
        
        let fr = NSFetchRequest(entityName: "Pin")
        let predicate = NSPredicate(format: "latitude == %lf && longitude == %lf", pinLat, pinLon)
        fr.predicate = predicate
        
        if inEditingMode {
            guard let pinsFound =
                try? stack.context.executeFetchRequest(fr) as! [Pin] where pinsFound.count == 1 else {
                    print("Unable to locate selected pin ManangedObject in database!")
                    return
            }
            
            let pin = pinsFound[0] as NSManagedObject
            
            mapView.removeAnnotation(view.annotation!)
            stack.context.deleteObject(pin)
            
        } else {
            guard let pinsFound =
                try? stack.context.executeFetchRequest(fr) as! [Pin] where pinsFound.count == 1 else {
                    
                    print("Unable to locate selected pin in database!")
                    return
            }
            performSegueWithIdentifier("showAlbum", sender: pinsFound[0])
        }
        

    }

}

