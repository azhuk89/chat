//
//  AppDelegate.swift
//  Chat
//
//  Created by Alexandr Zhuk on 4/12/16.
//  Copyright © 2016 Alexandr Zhuk. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    let APP_ID = "C989C2DA-203C-2EA9-FF03-2F777E1A1900"
    let SECRET_KEY = "7C2D984B-3B6D-14EF-FF69-F02E6D5AA200"
    let VERSION_NUM = "v1"
    
    var backendless = Backendless.sharedInstance()

    var deviceId: String?
    
    var window: UIWindow?


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        backendless.initApp(APP_ID, secret: SECRET_KEY, version: VERSION_NUM)
        backendless.messaging.registerForRemoteNotifications()
        
        let settings = UIUserNotificationSettings(forTypes: [.Alert, .Badge, .Sound], categories: nil)
        
        application.registerUserNotificationSettings(settings)
        application.registerForRemoteNotifications()
        
        return true
    }
    
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        let deviceId = backendless.messaging.registerDeviceToken(deviceToken)
        self.deviceId = deviceId
    }
    
    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
        print("unable to register for remote notifications: \(error.localizedDescription)")
    }
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
        print("did receive remote notification: \(userInfo)")
        NSNotificationCenter.defaultCenter().postNotificationName("chatWillUpdate", object: nil)
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

