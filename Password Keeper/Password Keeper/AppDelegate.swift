//
//  AppDelegate.swift
//  Password Keeper
//
//  Created by David Fisher on 4/11/18.
//  Copyright © 2018 David Fisher. All rights reserved.
//

import UIKit
import Firebase
import GoogleSignIn

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, GIDSignInDelegate {

  var window: UIWindow?

  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
    // To give the iOS status bar light icons & text
    UIApplication.shared.statusBarStyle = .lightContent

    // Programatically initialize the first view controller.
    window = UIWindow(frame: UIScreen.main.bounds)
    FirebaseApp.configure()
    GIDSignIn.sharedInstance().clientID = FirebaseApp.app()?.options.clientID
    GIDSignIn.sharedInstance().delegate = self

    if Auth.auth().currentUser == nil {
      showLoginViewController();
    } else {
      showPasswordViewController();
    }
    window?.makeKeyAndVisible()
    return true
  }
    
    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        return GIDSignIn.sharedInstance().handle(url, sourceApplication: options[UIApplicationOpenURLOptionsKey.sourceApplication] as? String, annotation: [:])
    }
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        if let error = error {
            print("Error with Google Auth! \(error.localizedDescription)")
            return
        }
        
        print("You are now signed in with Google. \(user.profile.email)")
        // TODO: Use that to sign in with Firebase
    }

  func handleLogin() {
//    print("TODO: Implement sign in from the AppDelegate")
    showPasswordViewController()
  }

  @objc func handleLogout() {
//    try! Auth.auth().signOut()
    do {
        try Auth.auth().signOut()
    } catch {
        print("Error on sign out: \(error.localizedDescription)")
    }
    showLoginViewController()
  }

  func showLoginViewController() {
    let storyboard = UIStoryboard(name: "Main", bundle: nil)
    window!.rootViewController = storyboard.instantiateViewController(withIdentifier: "LoginViewController")
  }

  func showPasswordViewController() {
    let storyboard = UIStoryboard(name: "Main", bundle: nil)
    let passwordViewController = storyboard.instantiateViewController(withIdentifier: "PasswordViewController")
    window!.rootViewController = AppNavBar(rootViewController: passwordViewController)
  }
}


extension UIViewController {
  var appDelegate : AppDelegate {
    get {
      return UIApplication.shared.delegate as! AppDelegate
    }
  }
}
