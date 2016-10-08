//
//  Pin+CoreDataProperties.swift
//  VirtualTourist
//
//  Created by Stanley Darmawan on 30/09/2016.
//  Copyright © 2016 Stanley Darmawan. All rights reserved.
//

import Foundation
import CoreData

extension Pin {

    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var photos: NSSet?
}


