//
//  FoodLoopApp.swift
//  FoodLoop
//
//  Created by 李宗儒 on 2025/6/14.
//

import SwiftUI
import FirebaseCore
import GoogleSignIn

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
    // Google Sign-In 需要處理 open url
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }
}

@main
struct FoodLoopApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @AppStorage("isSignedIn") var isSignedIn: Bool = false
    @StateObject var foodRepo = FoodRepository()
    @StateObject var userProfile = UserProfileModel()

    var body: some Scene {
        WindowGroup {
            if isSignedIn {
                ContentView()
                    .environmentObject(foodRepo)
                    .environmentObject(userProfile)
            } else {
                LoginView()
                    .environmentObject(userProfile)
            }
        }
    }
}
