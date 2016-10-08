//
//  Photo+CoreDataClass.swift
//  VirtualTourist
//
//  Created by Stanley Darmawan on 5/10/2016.
//  Copyright © 2016 Stanley Darmawan. All rights reserved.
//

import Foundation
import CoreData
import UIKit


public class Photo: NSManagedObject {
    
    convenience init(urlString: String = "", context: NSManagedObjectContext) {
        
        // An EntityDescription is an object that has access to all
        // the information you provided in the Entity part of the model
        // you need it to create an instance of this class.
        if let ent = NSEntityDescription.entityForName("Photo", inManagedObjectContext: context) {
            self.init(entity: ent, insertIntoManagedObjectContext: context)
            self.dateUpdated = NSDate()
            self.url = urlString

            
        } else {
            fatalError("Unable to find Entity name!")
        }
    }

}
