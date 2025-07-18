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
            options.dsn = "https://b72599749761ea6e64e6551475b56e21@o4508065179762768.ingest.de.sentry.io/4509434720485456"
            options.debug = true
            options.tracesSampleRate = 1.0 // 100% sampling
        }
        
        // Initialize Google Mobile Ads
        MobileAds.shared.start { status in
            print("Google Mobile Ads initialization status: \(status)")
        }
    }
    
    public static func getSentryDSN() -> String {
        print("🔍 Starting DSN lookup...")
        
        // Try to read from sentry.properties file
        // First try the app bundle (for production builds)
        if let propertiesPath = Bundle.main.path(forResource: "sentry", ofType: "properties") {
            print("📁 Found sentry.properties in app bundle: \(propertiesPath)")
            if let propertiesContent = try? String(contentsOfFile: propertiesPath, encoding: .utf8) {
                print("✅ Successfully read properties from app bundle")
                return parseSentryProperties(propertiesContent)
            } else {
                print("❌ Failed to read properties from app bundle")
            }
        } else {
            print("❌ No sentry.properties found in app bundle")
        }
        
        // Fallback: try to read from project directory (for development)
        let projectDir = ProcessInfo.processInfo.environment["PROJECT_DIR"] ?? ""
        print("📂 PROJECT_DIR environment variable: \(projectDir)")
        
        if !projectDir.isEmpty {
            let propertiesPath = projectDir + "/sentry.properties"
            print("📁 Trying project directory path: \(propertiesPath)")
            if let propertiesContent = try? String(contentsOfFile: propertiesPath, encoding: .utf8) {
                print("✅ Successfully read properties from project directory")
                return parseSentryProperties(propertiesContent)
            } else {
                print("❌ Failed to read properties from project directory")
            }
        } else {
            print("❌ PROJECT_DIR environment variable is empty")
        }
        
        // Try current working directory as last resort
        let currentDir = FileManager.default.currentDirectoryPath
        let currentDirPath = currentDir + "/sentry.properties"
        print("📁 Trying current directory: \(currentDirPath)")
        if let propertiesContent = try? String(contentsOfFile: currentDirPath, encoding: .utf8) {
            print("✅ Successfully read properties from current directory")
            return parseSentryProperties(propertiesContent)
        } else {
            print("❌ Failed to read properties from current directory")
        }
        
        print("⚠️ All attempts failed, using fallback DSN")
        // Fallback to placeholder if properties file not found or invalid
        return "YOUR_SENTRY_DSN_HERE"
    }
    
    private static func parseSentryProperties(_ content: String) -> String {
        let lines = content.components(separatedBy: .newlines)
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            if trimmedLine.hasPrefix("#") || trimmedLine.isEmpty { continue }
            
            let components = trimmedLine.components(separatedBy: "=")
            if components.count == 2 {
                let key = components[0].trimmingCharacters(in: .whitespaces)
                let value = components[1].trimmingCharacters(in: .whitespaces)
                
                // Look for direct DSN field first
                if key == "dsn" {
                    return value
                }
            }
        }
        
        // Fallback: try to construct DSN from org and project (legacy format)
        var org: String?
        var project: String?
        var url: String = "https://sentry.io"
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            if trimmedLine.hasPrefix("#") || trimmedLine.isEmpty { continue }
            
            let components = trimmedLine.components(separatedBy: "=")
            if components.count == 2 {
                let key = components[0].trimmingCharacters(in: .whitespaces)
                let value = components[1].trimmingCharacters(in: .whitespaces)
                
                switch key {
                case "org":
                    org = value
                case "project":
                    project = value
                case "url":
                    url = value
                default:
                    break
                }
            }
        }
        
        // Construct DSN if we have org and project
        if let org = org, let project = project {
            return "\(url)/\(org)/\(project)"
        }
        
        return "YOUR_SENTRY_DSN_HERE"
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
