//
//  AdLifecycleTracker.swift
//  MobileInAppAdvertisement
//
//  Created by Angelo de Voer on 03/06/2025.
//

import Foundation
import GoogleMobileAds
import Sentry

enum AdType: String {
    case banner = "banner"
    case interstitial = "interstitial"
    case rewarded = "rewarded"
}

enum AdEvent: String {
    case request = "ad_request"
    case loadStart = "ad_load_start"
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
    case loading = "ad_loading"
    case displayTime = "ad_display_time"
    case processing = "ad_processing"
}

class AdLifecycleTracker {
    static let shared = AdLifecycleTracker()
    
    private var transactions: [String: Span] = [:]
    
    private init() {}
    
    func startAdLifecycle(adType: AdType, adUnitID: String) -> String {
        let transaction = startAdTransaction(adType: adType, adUnitID: adUnitID)
        let transactionId = "\(adType.rawValue)_\(adUnitID)_\(UUID().uuidString)"
        
        // Create initial request span
        let requestSpan = createSpan(
            transaction: transaction,
            event: .request,
            data: [
                "ad_type": adType.rawValue,
                "ad_unit_id": adUnitID
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
    
    private func createSpan(transaction: Span, event: AdEvent, data: [String: Any] = [:]) -> Span {
        let span = transaction.startChild(operation: event.rawValue, description: getEventDescription(event: event, adType: data["ad_type"] as? String ?? "unknown"))
        
        // Add event data to span
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
            return "Request \(adType) ad"
        case .loadStart:
            return "Start loading \(adType) ad"
        case .loadSuccess:
            return "\(adType.capitalized) ad loaded successfully"
        case .loadFailure:
            return "\(adType.capitalized) ad failed to load"
        case .showStart:
            return "Start showing \(adType) ad"
        case .showSuccess:
            return "\(adType.capitalized) ad shown successfully"
        case .showFailure:
            return "\(adType.capitalized) ad failed to show"
        case .impression:
            return "\(adType.capitalized) ad impression recorded"
        case .click:
            return "\(adType.capitalized) ad clicked"
        case .dismiss:
            return "\(adType.capitalized) ad dismissed"
        case .exit:
            return "\(adType.capitalized) ad exited"
        case .videoStart:
            return "\(adType.capitalized) ad video started"
        case .videoComplete:
            return "\(adType.capitalized) ad video completed"
        case .reward:
            return "\(adType.capitalized) ad reward earned"
        case .loading:
            return "\(adType.capitalized) ad loading from network"
        case .displayTime:
            return "\(adType.capitalized) ad displayed to user"
        case .processing:
            return "\(adType.capitalized) ad processing time"
        }
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