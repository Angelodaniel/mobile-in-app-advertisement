//
//  MobileInAppAdvertisementApp.swift
//  MobileInAppAdvertisement
//
//  Created by Angelo de Voer on 03/06/2025.
//

import SwiftUI
import GoogleMobileAds
import Sentry

@main
struct MobileInAppAdvertisementApp: App {
    let persistenceController = PersistenceController.shared

    init() {
        // Configure Sentry
        SentrySDK.start { options in
            options.dsn = "YOUR_SENTRY_DSN_HERE" // Replace with your actual DSN from Sentry project settings
            options.debug = true
            options.tracesSampleRate = 1.0 // 100% sampling
        }
        
        // Initialize Google Mobile Ads
        MobileAds.shared.start { status in
            print("Google Mobile Ads initialization status: \(status)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
