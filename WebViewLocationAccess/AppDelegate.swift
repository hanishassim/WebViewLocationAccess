//
//  AppDelegate.swift
//  WebViewLocationAccess
//
//  Created by Hanis Hassim on 01/05/2020.
//  Copyright © 2020 H. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Set rootViewController for below iOS13
        window = UIWindow()
        let viewModel = HNZLocationWebViewModel(url: "https://maps.google.com/")
        let rootViewController = HNZLocationWebViewController(viewModel: viewModel)
        let navController = UINavigationController(rootViewController: rootViewController)
        window?.rootViewController = navController
        window?.makeKeyAndVisible()
        
        return true
    }
}

