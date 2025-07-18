//
//  AdConfiguration.swift
//  MobileInAppAdvertisement
//
//  Created by Angelo de Voer on 03/06/2025.
//

import Foundation

struct AdConfiguration {
    // MARK: - Test Ad Unit IDs (Replace with your real ones for production)
    
    // App ID
    static let appID = "ca-app-pub-3940256099942544~1458002511"
    
    // Banner Ad Unit ID
    static let bannerAdUnitID = "ca-app-pub-3940256099942544/2934735716"
    
    // Interstitial Ad Unit ID
    static let interstitialAdUnitID = "ca-app-pub-3940256099942544/4411468910"
    
    // Rewarded Ad Unit ID
    static let rewardedAdUnitID = "ca-app-pub-3940256099942544/1712485313"
    
    // MARK: - Production Ad Unit IDs (Uncomment and replace with your real ones)
    
    // static let appID = "your-production-app-id"
    // static let bannerAdUnitID = "your-banner-ad-unit-id"
    // static let interstitialAdUnitID = "your-interstitial-ad-unit-id"
    // static let rewardedAdUnitID = "your-rewarded-ad-unit-id"
    
    // MARK: - Ad Loading Configuration
    
    static let maxRetryAttempts = 3
    static let retryDelay: TimeInterval = 5.0
} 