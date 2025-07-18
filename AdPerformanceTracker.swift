//
//  AdPerformanceTracker.swift
//  MobileInAppAdvertisement
//
//  Created by Angelo de Voer on 03/06/2025.
//

import Foundation
import Sentry
import GoogleMobileAds

class AdPerformanceTracker: ObservableObject {
    static let shared = AdPerformanceTracker()
    
    // MARK: - Performance Metrics
    @Published var adMetrics = AdMetrics()
    
    // MARK: - Session Tracking
    private var sessionStartTime: Date = Date()
    private var adRequestStartTimes: [String: Date] = [:]
    private var adImpressionTimes: [String: Date] = [:]
    
    // MARK: - Configuration
    private let maxAdFrequencyPerSession = 3
    private let maxAdFrequencyPerMinute = 1
    
    private init() {
        setupSentryPerformanceMonitoring()
    }
    
    // MARK: - Sentry Performance Setup
    private func setupSentryPerformanceMonitoring() {
        // Create custom performance monitoring
        SentrySDK.configureScope { scope in
            scope.setTag(value: "ad_performance_tracker", key: "component")
        }
    }
    
    // MARK: - Ad Request Tracking
    func trackAdRequest(adType: AdType, adUnitID: String) {
        let requestID = UUID().uuidString
        adRequestStartTimes[requestID] = Date()
        
        // Track ad request count
        adMetrics.adRequestCount += 1
        
        // Create Sentry transaction for ad request
        let transaction = SentrySDK.startTransaction(
            name: "Ad Request - \(adType.rawValue)",
            operation: "ad.request"
        )
        
        transaction.setTag(value: adType.rawValue, key: "ad_type")
        transaction.setTag(value: adUnitID, key: "ad_unit_id")
        transaction.setTag(value: requestID, key: "request_id")
        
        // Store transaction for later completion
        adRequestStartTimes[requestID] = Date()
        
        // Track app performance impact
        trackAppPerformanceImpact(adType: adType, operation: "request")
        
        print("📊 Ad Request Tracked: \(adType.rawValue) - \(adUnitID)")
    }
    
    // MARK: - Ad Load Success Tracking
    func trackAdLoadSuccess(adType: AdType, adUnitID: String, requestID: String? = nil) {
        let loadTime = calculateAdLatency(requestID: requestID)
        
        // Update metrics
        adMetrics.adLoadSuccessCount += 1
        adMetrics.adLatency.append(loadTime)
        
        // Complete Sentry transaction
        if let requestID = requestID,
           let startTime = adRequestStartTimes[requestID] {
            let transaction = SentrySDK.startTransaction(
                name: "Ad Load Success - \(adType.rawValue)",
                operation: "ad.load_success"
            )
            
            transaction.setTag(value: adType.rawValue, key: "ad_type")
            transaction.setTag(value: adUnitID, key: "ad_unit_id")
            transaction.setTag(value: String(format: "%.2f", loadTime), key: "load_time_seconds")
            transaction.finish()
            
            adRequestStartTimes.removeValue(forKey: requestID)
        }
        
        // Track fill rate
        updateFillRate()
        
        print("✅ Ad Load Success: \(adType.rawValue) - Load Time: \(String(format: "%.2f", loadTime))s")
    }
    
    // MARK: - Ad Load Failure Tracking
    func trackAdLoadFailure(adType: AdType, adUnitID: String, error: Error, requestID: String? = nil) {
        let loadTime = calculateAdLatency(requestID: requestID)
        
        // Update metrics
        adMetrics.adLoadFailureCount += 1
        adMetrics.adLatency.append(loadTime)
        
        // Create Sentry error event
        let event = Event(error: error)
        event.setTag(value: adType.rawValue, key: "ad_type")
        event.setTag(value: adUnitID, key: "ad_unit_id")
        event.setTag(value: String(format: "%.2f", loadTime), key: "load_time_seconds")
        event.setTag(value: "ad_load_failure", key: "error_type")
        
        SentrySDK.capture(event: event)
        
        // Track app performance impact
        trackAppPerformanceImpact(adType: adType, operation: "load_failure")
        
        print("❌ Ad Load Failure: \(adType.rawValue) - Error: \(error.localizedDescription)")
    }
    
    // MARK: - Ad Impression Tracking
    func trackAdImpression(adType: AdType, adUnitID: String) {
        let impressionID = UUID().uuidString
        adImpressionTimes[impressionID] = Date()
        
        // Update metrics
        adMetrics.impressionCount += 1
        adMetrics.adFrequencyPerSession += 1
        
        // Check ad frequency limits
        checkAdFrequencyLimits()
        
        // Create Sentry transaction for impression
        let transaction = SentrySDK.startTransaction(
            name: "Ad Impression - \(adType.rawValue)",
            operation: "ad.impression"
        )
        
        transaction.setTag(value: adType.rawValue, key: "ad_type")
        transaction.setTag(value: adUnitID, key: "ad_unit_id")
        transaction.setTag(value: impressionID, key: "impression_id")
        transaction.setTag(value: String(adMetrics.impressionCount), key: "total_impressions")
        
        // Track app performance impact
        trackAppPerformanceImpact(adType: adType, operation: "impression")
        
        print("👁️ Ad Impression: \(adType.rawValue) - Total: \(adMetrics.impressionCount)")
    }
    
    // MARK: - Ad Click Tracking
    func trackAdClick(adType: AdType, adUnitID: String) {
        // Update metrics
        adMetrics.clickCount += 1
        
        // Calculate CTR
        let ctr = adMetrics.impressionCount > 0 ? (Double(adMetrics.clickCount) / Double(adMetrics.impressionCount)) * 100 : 0
        adMetrics.clickThroughRate = ctr
        
        // Create Sentry event
        let event = Event()
        event.message = SentryMessage(formatted: "Ad Click - \(adType.rawValue)")
        event.setTag(value: adType.rawValue, key: "ad_type")
        event.setTag(value: adUnitID, key: "ad_unit_id")
        event.setTag(value: String(format: "%.2f", ctr), key: "ctr_percentage")
        
        SentrySDK.capture(event: event)
        
        print("🖱️ Ad Click: \(adType.rawValue) - CTR: \(String(format: "%.2f", ctr))%")
    }
    
    // MARK: - Rewarded Video Completion Tracking
    func trackRewardedVideoCompletion(adUnitID: String, rewardAmount: Int, rewardType: String) {
        // Update metrics
        adMetrics.rewardedVideoCompletions += 1
        
        // Calculate completion rate
        let completionRate = adMetrics.impressionCount > 0 ? 
            (Double(adMetrics.rewardedVideoCompletions) / Double(adMetrics.impressionCount)) * 100 : 0
        adMetrics.rewardedVideoCompletionRate = completionRate
        
        // Create Sentry event
        let event = Event()
        event.message = SentryMessage(formatted: "Rewarded Video Completion")
        event.setTag(value: adUnitID, key: "ad_unit_id")
        event.setTag(value: String(rewardAmount), key: "reward_amount")
        event.setTag(value: rewardType, key: "reward_type")
        event.setTag(value: String(format: "%.2f", completionRate), key: "completion_rate_percentage")
        
        SentrySDK.capture(event: event)
        
        print("🎁 Rewarded Video Completion: \(rewardAmount) \(rewardType) - Rate: \(String(format: "%.2f", completionRate))%")
    }
    
    // MARK: - App Performance Impact Tracking
    func trackAppPerformanceImpact(adType: AdType, operation: String) {
        // Track memory usage
        let memoryUsage = getMemoryUsage()
        
        // Track battery impact (simulated)
        let batteryImpact = simulateBatteryImpact(adType: adType, operation: operation)
        
        // Create Sentry event for performance impact
        let event = Event()
        event.message = SentryMessage(formatted: "App Performance Impact - \(adType.rawValue)")
        event.setTag(value: adType.rawValue, key: "ad_type")
        event.setTag(value: operation, key: "operation")
        event.setTag(value: String(format: "%.2f", memoryUsage), key: "memory_usage_mb")
        event.setTag(value: String(format: "%.2f", batteryImpact), key: "battery_impact_percent")
        
        SentrySDK.capture(event: event)
    }
    
    // MARK: - Session Tracking
    func startSession() {
        sessionStartTime = Date()
        adMetrics = AdMetrics() // Reset metrics for new session
        
        // Create Sentry transaction for session
        let transaction = SentrySDK.startTransaction(
            name: "Ad Session",
            operation: "session"
        )
        
        transaction.setTag(value: sessionStartTime.timeIntervalSince1970.description, key: "session_start")
        
        print("🚀 Ad Session Started")
    }
    
    func endSession() {
        let sessionDuration = Date().timeIntervalSince(sessionStartTime)
        
        // Create final session report
        let event = Event()
        event.message = SentryMessage(formatted: "Ad Session Summary")
        event.setTag(value: String(format: "%.2f", sessionDuration), key: "session_duration_seconds")
        event.setTag(value: String(adMetrics.impressionCount), key: "total_impressions")
        event.setTag(value: String(adMetrics.clickCount), key: "total_clicks")
        event.setTag(value: String(format: "%.2f", adMetrics.clickThroughRate), key: "final_ctr_percentage")
        event.setTag(value: String(format: "%.2f", adMetrics.fillRate), key: "final_fill_rate_percentage")
        event.setTag(value: String(format: "%.2f", adMetrics.averageAdLatency), key: "average_latency_seconds")
        
        SentrySDK.capture(event: event)
        
        print("🏁 Ad Session Ended - Duration: \(String(format: "%.2f", sessionDuration))s")
    }
    
    // MARK: - Helper Methods
    private func calculateAdLatency(requestID: String?) -> TimeInterval {
        guard let requestID = requestID,
              let startTime = adRequestStartTimes[requestID] else {
            return 0.0
        }
        return Date().timeIntervalSince(startTime)
    }
    
    private func updateFillRate() {
        let totalRequests = adMetrics.adRequestCount
        let totalServed = adMetrics.adLoadSuccessCount
        
        if totalRequests > 0 {
            adMetrics.fillRate = (Double(totalServed) / Double(totalRequests)) * 100
        }
    }
    
    private func checkAdFrequencyLimits() {
        let currentFrequency = adMetrics.adFrequencyPerSession
        
        if currentFrequency > maxAdFrequencyPerSession {
            // Create Sentry event for excessive ad frequency
            let event = Event()
            event.message = SentryMessage(formatted: "Excessive Ad Frequency Detected")
            event.setTag(value: String(currentFrequency), key: "current_frequency")
            event.setTag(value: String(maxAdFrequencyPerSession), key: "max_frequency")
            event.level = .warning
            
            SentrySDK.capture(event: event)
        }
    }
    
    private func getMemoryUsage() -> Double {
        // Simulate memory usage tracking
        return Double.random(in: 50...200)
    }
    
    private func simulateBatteryImpact(adType: AdType, operation: String) -> Double {
        // Simulate battery impact based on ad type and operation
        switch adType {
        case .banner:
            return Double.random(in: 0.1...0.5)
        case .interstitial:
            return Double.random(in: 0.5...1.0)
        case .rewarded:
            return Double.random(in: 1.0...2.0)
        }
    }
}

// MARK: - Data Models
struct AdMetrics {
    // Ad Delivery Metrics
    var impressionCount: Int = 0
    var adRequestCount: Int = 0
    var adLoadSuccessCount: Int = 0
    var adLoadFailureCount: Int = 0
    var adLatency: [TimeInterval] = []
    var fillRate: Double = 0.0
    
    // Ad Interaction Metrics
    var clickCount: Int = 0
    var clickThroughRate: Double = 0.0
    var rewardedVideoCompletions: Int = 0
    var rewardedVideoCompletionRate: Double = 0.0
    var adFrequencyPerSession: Int = 0
    
    // Computed Properties
    var averageAdLatency: Double {
        guard !adLatency.isEmpty else { return 0.0 }
        return adLatency.reduce(0, +) / Double(adLatency.count)
    }
    
    var totalAdRequests: Int {
        return adLoadSuccessCount + adLoadFailureCount
    }
}

enum AdType: String, CaseIterable {
    case banner = "Banner"
    case interstitial = "Interstitial"
    case rewarded = "Rewarded"
} 