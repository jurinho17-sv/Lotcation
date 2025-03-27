import SwiftUI

@main
struct LotcationApp: App {
    
    // connect AppDelegate.swift
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @State private var showSplash = true
    
    init() {
        // Print available fonts for debugging (optional)
        #if DEBUG
        print("Available fonts:")
        for family in UIFont.familyNames.sorted() {
            print("Font family: \(family)")
            for name in UIFont.fontNames(forFamilyName: family) {
                print("   \(name)")
            }
        }
        #endif
    }
    
    var body: some Scene {
        WindowGroup {
            if showSplash {
                SplashScreenView(showSplash: $showSplash)
            } else {
                ContentView()
            }
        }
    }
}
