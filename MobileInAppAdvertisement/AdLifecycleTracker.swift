//
//  AdLifecycleTracker.swift
//  MobileInAppAdvertisement
//
//  Created by Angelo de Voer on 03/06/2025.
//

import Foundation
import GoogleMobileAds
import Sentry
import UIKit // Added for UIDevice

enum AdType: String {
    case banner = "banner"
    case interstitial = "interstitial"
    case rewarded = "rewarded"
}

enum AdPlacement: String {
    case appLaunch = "app_launch"
    case betweenLevels = "between_levels"
    case naturalBreak = "natural_break"
    case achievement = "achievement"
    case sessionEnd = "session_end"
    case custom = "custom"
}

enum AdEvent: String {
    case request = "ad_request"
    case loadStart = "ad_load_start"
    case loading = "ad_loading"
    case loadSuccess = "ad_load_success"
    case loadFailure = "ad_load_failure"
    case showStart = "ad_show_start"
    case showSuccess = "ad_show_success"
    case showFailure = "ad_show_failure"
    case impression = "ad_impression"
    case click = "ad_click"
    case dismiss = "ad_dismiss"
    case exit = "ad_exit"
    case videoStart = "ad_video_start"
    case videoComplete = "ad_video_complete"
    case reward = "ad_reward"
    case waitingForImpression = "ad_waiting_for_impression"
    case waitingForLoadSuccess = "ad_waiting_for_load_success"
    case displayTime = "ad_display_time"
    case processing = "ad_processing"
}

class AdLifecycleTracker {
    static let shared = AdLifecycleTracker()
    
    private var transactions: [String: Span] = [:]
    private var sessionStartTime: Date = Date()
    private var adsInSession: Int = 0
    
    private init() {
        // Enable battery monitoring
        UIDevice.current.isBatteryMonitoringEnabled = true
    }
    
    func startAdLifecycle(adType: AdType, adUnitID: String, placement: AdPlacement) -> String {
        let transactionId = UUID().uuidString
        
        // Get battery level at start
        let startBatteryLevel = UIDevice.current.batteryLevel
        
        // Calculate session context
        let sessionDuration = Date().timeIntervalSince(sessionStartTime)
        adsInSession += 1
        
        let transaction = SentrySDK.startTransaction(
            name: "ad_lifecycle_\(adType.rawValue)",
            operation: "ad_lifecycle_\(adType.rawValue)"
        )
        
        // Store start battery level and ad info
        transaction.setData(value: startBatteryLevel, key: "start_battery_level")
        transaction.setData(value: adType.rawValue, key: "ad_type")
        transaction.setData(value: adUnitID, key: "ad_unit_id")
        transaction.setData(value: placement.rawValue, key: "ad_placement")
        transaction.setData(value: Date(), key: "start_time")
        
        // Add session context
        transaction.setData(value: sessionDuration, key: "session_duration_seconds")
        transaction.setData(value: adsInSession, key: "ads_in_session")
        transaction.setData(value: sessionStartTime, key: "session_start_time")
        
        // Create initial request span
        let requestSpan = createSpan(
            transaction: transaction,
            event: .request,
            data: [
                "ad_type": adType.rawValue,
                "ad_unit_id": adUnitID,
                "ad_placement": placement.rawValue,
                "session_duration_seconds": sessionDuration,
                "ads_in_session": adsInSession
            ]
        )
        requestSpan.finish()
        
        transactions[transactionId] = transaction
        return transactionId
    }
    
    private func startAdTransaction(adType: AdType, adUnitID: String) -> Span {
        let transactionName = "ad_lifecycle_\(adType.rawValue)"
        
        let transaction = SentrySDK.startTransaction(
            name: transactionName,
            operation: "ad.lifecycle"
        )
        
        // Add ad metadata to transaction
        transaction.setData(value: adType.rawValue, key: "ad_type")
        transaction.setData(value: adUnitID, key: "ad_unit_id")
        transaction.setData(value: Date(), key: "start_time")
        
        return transaction
    }
    
    private func createSpan(transaction: Span, event: AdEvent, data: [String: Any]) -> Span {
        let span = transaction.startChild(
            operation: "ad_\(event.rawValue)",
            description: getEventDescription(event: event, adType: data["ad_type"] as? String ?? "unknown")
        )
        
        // Add battery level to each span
        let currentBatteryLevel = UIDevice.current.batteryLevel
        span.setData(value: currentBatteryLevel, key: "battery_level")
        
        // Add event-specific data
        for (key, value) in data {
            span.setData(value: value, key: key)
        }
        
        // Add event-specific data for better visibility
        span.setData(value: event.rawValue, key: "event_type")
        span.setData(value: getEventDescription(event: event, adType: data["ad_type"] as? String ?? "unknown"), key: "event_description")
        span.setData(value: Date(), key: "timestamp")
        
        return span
    }
    
    private func getEventDescription(event: AdEvent, adType: String) -> String {
        switch event {
        case .request:
            return "\(adType.capitalized) ad request"
        case .loadStart:
            return "\(adType.capitalized) ad load start"
        case .loading:
            return "\(adType.capitalized) ad loading"
        case .loadSuccess:
            return "\(adType.capitalized) ad load success"
        case .loadFailure:
            return "\(adType.capitalized) ad load failure"
        case .showStart:
            return "\(adType.capitalized) ad show start"
        case .showSuccess:
            return "\(adType.capitalized) ad show success"
        case .showFailure:
            return "\(adType.capitalized) ad show failure"
        case .impression:
            return "\(adType.capitalized) ad impression"
        case .click:
            return "\(adType.capitalized) ad click"
        case .dismiss:
            return "\(adType.capitalized) ad dismiss"
        case .exit:
            return "\(adType.capitalized) ad exit"
        case .videoStart:
            return "\(adType.capitalized) ad video start"
        case .videoComplete:
            return "\(adType.capitalized) ad video complete"
        case .reward:
            return "\(adType.capitalized) ad reward"
        case .waitingForImpression:
            return "\(adType.capitalized) ad waiting for impression"
        case .waitingForLoadSuccess:
            return "\(adType.capitalized) ad waiting for load success"
        case .displayTime:
            return "\(adType.capitalized) ad display time"
        case .processing:
            return "\(adType.capitalized) ad processing"
        }
    }
    
    func finishAdLifecycle(transactionId: String) {
        guard let transaction = transactions[transactionId] else { return }
        
        // Get battery level at finish
        let endBatteryLevel = UIDevice.current.batteryLevel
        
        // Calculate battery impact percentage
        let startBatteryLevel = transaction.data["start_battery_level"] as? Float ?? 0.0
        let batteryImpactPercent = startBatteryLevel > 0 ? ((startBatteryLevel - endBatteryLevel) / startBatteryLevel) * 100.0 : 0.0
        
        // Calculate session continuation
        let sessionDuration = Date().timeIntervalSince(sessionStartTime)
        let adsInSession = transaction.data["ads_in_session"] as? Int ?? 0
        
        // Add battery impact data to transaction
        transaction.setData(value: endBatteryLevel, key: "end_battery_level")
        transaction.setData(value: batteryImpactPercent, key: "battery_impact_percent")
        transaction.setData(value: Date(), key: "end_time")
        
        // Add placement performance data
        transaction.setData(value: sessionDuration, key: "total_session_duration_seconds")
        transaction.setData(value: adsInSession, key: "total_ads_in_session")
        
        transaction.finish()
        transactions.removeValue(forKey: transactionId)
    }
    
    func trackUserDropOff(transactionId: String, timeAfterAd: TimeInterval) {
        guard let transaction = transactions[transactionId] else { return }
        
        // Track user drop-off timing
        transaction.setData(value: timeAfterAd, key: "time_to_drop_off_seconds")
        transaction.setData(value: true, key: "user_dropped_off")
        
        // Create drop-off span
        let dropOffSpan = createSpan(
            transaction: transaction,
            event: .exit,
            data: [
                "time_after_ad_seconds": timeAfterAd,
                "drop_off_reason": "user_exit"
            ]
        )
        dropOffSpan.finish()
    }
    
    func trackSessionContinuation(transactionId: String, timeAfterAd: TimeInterval) {
        guard let transaction = transactions[transactionId] else { return }
        
        // Track session continuation
        transaction.setData(value: timeAfterAd, key: "time_to_next_action_seconds")
        transaction.setData(value: false, key: "user_dropped_off")
        
        // Create continuation span
        let continuationSpan = createSpan(
            transaction: transaction,
            event: .processing,
            data: [
                "time_after_ad_seconds": timeAfterAd,
                "session_continued": true
            ]
        )
        continuationSpan.finish()
    }
    
    func resetSession() {
        sessionStartTime = Date()
        adsInSession = 0
    }
    
    func trackAdLoadStart(transactionId: String, adType: AdType, adUnitID: String) {
        guard let transaction = transactions[transactionId] else { return }
        
        let span = createSpan(
            transaction: transaction,
            event: .loadStart,
            data: [
                "ad_type": adType.rawValue,
                "ad_unit_id": adUnitID
            ]
        )
        span.finish()
    }
    
    func startAdLoading(transactionId: String, adType: AdType, adUnitID: String) -> Span? {
        guard let transaction = transactions[transactionId] else { return nil }
        
        let span = createSpan(
            transaction: transaction,
            event: .loading,
            data: [
                "ad_type": adType.rawValue,
                "ad_unit_id": adUnitID
            ]
        )
        
        return span
    }
    
    func finishAdLoading(span: Span) {
        span.finish()
    }
    
    func trackAdLoadSuccess(transactionId: String, adType: AdType, adUnitID: String) {
        guard let transaction = transactions[transactionId] else { return }
        
        let span = createSpan(
            transaction: transaction,
            event: .loadSuccess,
            data: [
                "ad_type": adType.rawValue,
                "ad_unit_id": adUnitID
            ]
        )
        span.finish()
        
        // For banner ads, finish transaction after load success since they don't have show/dismiss events
        if adType == .banner {
            transaction.finish()
            transactions.removeValue(forKey: transactionId)
        }
    }
    
    func trackAdLoadFailure(transactionId: String, adType: AdType, adUnitID: String, error: Error) {
        guard let transaction = transactions[transactionId] else { return }
        
        let span = createSpan(
            transaction: transaction,
            event: .loadFailure,
            data: [
                "ad_type": adType.rawValue,
                "ad_unit_id": adUnitID,
                "error": error.localizedDescription
            ]
        )
        span.finish()
        
        // Finish transaction on load failure
        transaction.finish()
        transactions.removeValue(forKey: transactionId)
    }
    
    func trackAdShowStart(transactionId: String, adType: AdType, adUnitID: String) {
        guard let transaction = transactions[transactionId] else { return }
        
        let span = createSpan(
            transaction: transaction,
            event: .showStart,
            data: [
                "ad_type": adType.rawValue,
                "ad_unit_id": adUnitID
            ]
        )
        span.finish()
    }
    
    func trackAdShowSuccess(transactionId: String, adType: AdType, adUnitID: String) {
        guard let transaction = transactions[transactionId] else { return }
        
        let span = createSpan(
            transaction: transaction,
            event: .showSuccess,
            data: [
                "ad_type": adType.rawValue,
                "ad_unit_id": adUnitID
            ]
        )
        span.finish()
        
        // For interstitial ads, finish transaction after show success
        if adType == .interstitial {
            transaction.finish()
            transactions.removeValue(forKey: transactionId)
        }
    }
    
    func trackAdShowFailure(transactionId: String, adType: AdType, adUnitID: String, error: Error) {
        guard let transaction = transactions[transactionId] else { return }
        
        let span = createSpan(
            transaction: transaction,
            event: .showFailure,
            data: [
                "ad_type": adType.rawValue,
                "ad_unit_id": adUnitID,
                "error": error.localizedDescription
            ]
        )
        span.finish()
        
        // Finish transaction on show failure
        transaction.finish()
        transactions.removeValue(forKey: transactionId)
    }
    
    func trackAdImpression(transactionId: String, adType: AdType, adUnitID: String) {
        guard let transaction = transactions[transactionId] else { return }
        
        let span = createSpan(
            transaction: transaction,
            event: .impression,
            data: [
                "ad_type": adType.rawValue,
                "ad_unit_id": adUnitID
            ]
        )
        span.finish()
    }
    
    func trackAdClick(transactionId: String, adType: AdType, adUnitID: String) {
        guard let transaction = transactions[transactionId] else { return }
        
        let span = createSpan(
            transaction: transaction,
            event: .click,
            data: [
                "ad_type": adType.rawValue,
                "ad_unit_id": adUnitID
            ]
        )
        span.finish()
    }
    
    func trackAdDismiss(transactionId: String, adType: AdType, adUnitID: String) {
        guard let transaction = transactions[transactionId] else { return }
        
        let span = createSpan(
            transaction: transaction,
            event: .dismiss,
            data: [
                "ad_type": adType.rawValue,
                "ad_unit_id": adUnitID
            ]
        )
        span.finish()
        
        // Finish transaction on dismiss
        transaction.finish()
        transactions.removeValue(forKey: transactionId)
    }
    
    func trackAdExit(transactionId: String, adType: AdType, adUnitID: String) {
        guard let transaction = transactions[transactionId] else { return }
        
        let span = createSpan(
            transaction: transaction,
            event: .exit,
            data: [
                "ad_type": adType.rawValue,
                "ad_unit_id": adUnitID
            ]
        )
        span.finish()
    }
    
    func trackAdVideoStart(transactionId: String, adType: AdType, adUnitID: String) {
        guard let transaction = transactions[transactionId] else { return }
        
        let span = createSpan(
            transaction: transaction,
            event: .videoStart,
            data: [
                "ad_type": adType.rawValue,
                "ad_unit_id": adUnitID
            ]
        )
        span.finish()
    }
    
    func trackAdVideoComplete(transactionId: String, adType: AdType, adUnitID: String) {
        guard let transaction = transactions[transactionId] else { return }
        
        let span = createSpan(
            transaction: transaction,
            event: .videoComplete,
            data: [
                "ad_type": adType.rawValue,
                "ad_unit_id": adUnitID
            ]
        )
        span.finish()
        
        // For rewarded ads, finish transaction after video completion
        if adType == .rewarded {
            transaction.finish()
            transactions.removeValue(forKey: transactionId)
        }
    }
    
    func trackAdReward(transactionId: String, adType: AdType, adUnitID: String, rewardAmount: Int, rewardType: String) {
        guard let transaction = transactions[transactionId] else { return }
        
        let span = createSpan(
            transaction: transaction,
            event: .reward,
            data: [
                "ad_type": adType.rawValue,
                "ad_unit_id": adUnitID,
                "reward_amount": rewardAmount,
                "reward_type": rewardType
            ]
        )
        span.finish()
    }
    
    // MARK: - Waiting Period Tracking
    
    func startWaitingForImpression(transactionId: String, adType: AdType, adUnitID: String) -> Span {
        guard let transaction = transactions[transactionId] else { 
            return SentrySDK.startTransaction(name: "fallback", operation: "fallback")
        }
        
        let span = transaction.startChild(
            operation: "ad_waiting_for_impression", 
            description: "\(adType.rawValue.capitalized) ad waiting for impression"
        )
        
        span.setData(value: adType.rawValue, key: "ad_type")
        span.setData(value: adUnitID, key: "ad_unit_id")
        span.setData(value: Date(), key: "start_time")
        
        // Set a shorter timeout to finish the span if impression doesn't come within 10 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
            if span.isFinished == false {
                span.setData(value: "timeout", key: "finish_reason")
                span.setData(value: Date(), key: "end_time")
                span.finish()
            }
        }
        
        return span
    }
    
    func finishWaitingForImpression(span: Span) {
        if span.isFinished == false {
            span.setData(value: "impression_received", key: "finish_reason")
            span.setData(value: Date(), key: "end_time")
            span.finish()
        }
    }
    
    func startWaitingForLoadSuccess(transactionId: String, adType: AdType, adUnitID: String) -> Span {
        guard let transaction = transactions[transactionId] else { 
            return SentrySDK.startTransaction(name: "fallback", operation: "fallback")
        }
        
        let span = transaction.startChild(
            operation: "ad_waiting_for_load_success", 
            description: "\(adType.rawValue.capitalized) ad waiting for load success"
        )
        
        span.setData(value: adType.rawValue, key: "ad_type")
        span.setData(value: adUnitID, key: "ad_unit_id")
        span.setData(value: Date(), key: "start_time")
        
        return span
    }
    
    func finishWaitingForLoadSuccess(span: Span) {
        span.setData(value: Date(), key: "end_time")
        span.finish()
    }
    
    func startAdDisplayTime(transactionId: String, adType: AdType, adUnitID: String) -> Span {
        guard let transaction = transactions[transactionId] else { 
            return SentrySDK.startTransaction(name: "fallback", operation: "fallback")
        }
        
        let span = transaction.startChild(
            operation: "ad_display_time", 
            description: "\(adType.rawValue.capitalized) ad displayed to user"
        )
        
        span.setData(value: adType.rawValue, key: "ad_type")
        span.setData(value: adUnitID, key: "ad_unit_id")
        span.setData(value: Date(), key: "start_time")
        
        return span
    }
    
    func finishAdDisplayTime(span: Span) {
        span.setData(value: Date(), key: "end_time")
        span.finish()
    }
    
    func trackAdLoading(transactionId: String, adType: AdType, adUnitID: String) {
        guard let transaction = transactions[transactionId] else { return }
        
        let span = createSpan(
            transaction: transaction,
            event: .loading,
            data: [
                "ad_type": adType.rawValue,
                "ad_unit_id": adUnitID
            ]
        )
        span.finish()
    }
    
    func trackAdDisplayTime(transactionId: String, adType: AdType, adUnitID: String) {
        guard let transaction = transactions[transactionId] else { return }
        
        let span = createSpan(
            transaction: transaction,
            event: .displayTime,
            data: [
                "ad_type": adType.rawValue,
                "ad_unit_id": adUnitID
            ]
        )
        span.finish()
    }
    
    func trackAdProcessing(transactionId: String, adType: AdType, adUnitID: String) {
        guard let transaction = transactions[transactionId] else { return }
        
        let span = createSpan(
            transaction: transaction,
            event: .processing,
            data: [
                "ad_type": adType.rawValue,
                "ad_unit_id": adUnitID
            ]
        )
        span.finish()
    }
} 