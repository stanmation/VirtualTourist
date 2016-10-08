//
//  AppDelegate.swift
//  VirtualTourist
//
//  Created by Stanley Darmawan on 29/09/2016.
//  Copyright © 2016 Stanley Darmawan. All rights reserved.
//

import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    let stack = CoreDataStack(modelName: "VirtualTourist")!
    var testData:NSData?
    
    func preloadData() {
        // Remove previous stuff (if any)
        do {
            try stack.dropAllData()
        } catch {
            print("Error droping all objects in DB")
        }
        
        // Create notebooks
        let pin1 = Pin(latitude: -21.814859121594736, longitude: 135.98378941999991,context: stack.context)
        
        // Check out the "data" field when you print an NSManagedObject subclass.
        // It looks like a Dictionary and the values in it are called
        // _Modelled Properties_. These are the properties defined in the
        // Data Model. They reside in the SQLite DB
        print("object is \(pin1)")
        
        let urlString = "https://farm8.staticflickr.com/7341/27644554392_24522e98a4.jpg"
        let url = NSURL(string: urlString)
        let data = NSData(contentsOfURL: url!)
        testData = data
        let photo1 = Photo(urlString: urlString, context: stack.context)
        
        print("photo is \(photo1)")
        
        photo1.pin = pin1
        

    }
    
    func removePreviousStuffs() {
        // Remove previous stuff (if any)
        do {
            try stack.dropAllData()
        } catch {
            print("Error droping all objects in DB")
        }
    }


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        
        let paths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        print(paths[0])
        
//        removePreviousStuffs()
//        preloadData()
        
                stack.autoSave(60)
        
        stack.save()
        
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
        
        stack.save()

    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        
        stack.save()

    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        //self.saveContext()
    }

}

