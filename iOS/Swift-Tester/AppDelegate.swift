//
//  AppDelegate.swift
//  Swift-Tester
//
//  Created by karl on 2016-01-28.
//  Copyright © 2016 Karl Stenerud. All rights reserved.
//

import UIKit
import KSCrash

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    // helper for an alert
    func msgbox(_ msg: String) {
        let alert = UIAlertController(title: "Alert", message: msg, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
        self.window?.rootViewController?.present(alert, animated: true, completion: nil)
    }
    
    func SetupCrashReporter(){
        // email installation, email log
        //        let emailAddress = "me@my.server.com"
        //        let installation = KSCrashInstallationEmail.sharedInstance()
        //        installation?.recipients = [emailAddress]
        //        installation?.subject = "Crash Report"
        //        installation?.message = "This is a crash report"
        //        installation?.filenameFmt = "crash-report-%d.txt.gz"
        //        installation?.reportStyle = KSCrashEmailReportStyleApple
        
        // check if have access to appbuilder, by checking its ip.
        let serverName:String = "appbuilder.esri.com"
        let restUrl:String = "https://\(serverName)/uploadioslog"
        
        var numAddress:String = ""
        let host = CFHostCreateWithName(nil, serverName as CFString).takeRetainedValue()
        CFHostStartInfoResolution(host, .addresses, nil)
        var success: DarwinBoolean = false
        if let addresses = CFHostGetAddressing(host, &success)?.takeUnretainedValue() as NSArray?,
            let theAddress = addresses.firstObject as? NSData {
            var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            if getnameinfo(theAddress.bytes.assumingMemoryBound(to: sockaddr.self), socklen_t(theAddress.length),
                           &hostname, socklen_t(hostname.count), nil, 0, NI_NUMERICHOST) == 0 {
                numAddress = String(cString: hostname)
                print(numAddress)
            }
        }
        
        // standard installation, post to server
        let installation = KSCrashInstallationStandard.sharedInstance()
        installation?.url = URL(string: restUrl)
        
        // if no access to appbuilder, only capature crash log, don't post
        if numAddress == "" {
            installation?.install()
            return
        }
        
        // if have access to my server, post it
        installation?.addConditionalAlert(withTitle: "Crash Detected",
                                          message: "send crash log(s) to \(serverName)?",
            yesAnswer: "Yes",
            noAnswer: "No")
        
        installation?.install()
        
        installation?.sendAllReports { (reports, completed, error) -> Void in
            if(completed) {
                if let count = reports?.count, count > 0 {
                    print("\(count) crash report(s) sent.")
                    self.msgbox("\(count) reports sent.")
                }
            } else {
                print("failed to send reports: \(error)")
                self.msgbox("failed to send reports.")
            }
        }
        
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions:
        [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        // enable crash log capturing/posting
        SetupCrashReporter()
        
        return true
    }
    
    
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    
}

