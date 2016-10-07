//
//  Photo+CoreDataProperties.swift
//  VirtualTourist
//
//  Created by Stanley Darmawan on 5/10/2016.
//  Copyright © 2016 Stanley Darmawan. All rights reserved.
//

import Foundation
import CoreData
import 

extension Photo {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Photo> {
        return NSFetchRequest<Photo>(entityName: "Photo");
    }

    @NSManaged public var dateUpdated: NSDate?
    @NSManaged public var url: String?
    @NSManaged public var imageData: NSData?
    @NSManaged public var pin: Pin?

}
