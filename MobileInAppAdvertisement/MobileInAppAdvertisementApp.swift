//
//  MobileInAppAdvertisementApp.swift
//  MobileInAppAdvertisement
//
//  Created by Angelo de Voer on 03/06/2025.
//

import SwiftUI
import GoogleMobileAds

@main
struct MobileInAppAdvertisementApp: App {
    let persistenceController = PersistenceController.shared

    init() {
        // Initialize Google Mobile Ads
        GADMobileAds.sharedInstance().start(completionHandler: nil)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
