//
//  ContentView.swift
//  MobileInAppAdvertisement
//
//  Created by Angelo de Voer on 03/06/2025.
//

import SwiftUI
import GoogleMobileAds
import Sentry

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var adManager = AdManager()
    @State private var useFailingAds = false // Toggle for failing test ads

    var body: some View {
        NavigationView {
            List {
                // Test Configuration Section
                Section(header: Text("Test Configuration")) {
                    HStack {
                        Text("Use Failing Test Ads")
                        Spacer()
                        Toggle("", isOn: $useFailingAds)
                            .onChange(of: useFailingAds) { oldValue, newValue in
                                // Reload ads when toggle changes
                                adManager.reloadAds(useFailingAds: newValue)
                            }
                    }
                }
                
                // Banner Ad Section
                Section(header: Text("Banner Ad")) {
                    BannerAdView(useFailingAds: useFailingAds)
                        .frame(height: 50)
                        .padding(.vertical, 8)
                }
                
                // Interstitial Ad Section
                Section(header: Text("Interstitial Ad")) {
                    HStack {
                        Button("Load Interstitial") {
                            adManager.loadInterstitialAd()
                        }
                        .disabled(adManager.isInterstitialAdReady)
                        
                        Spacer()
                        
                        Button("Show Interstitial") {
                            adManager.showInterstitialAd()
                        }
                        .disabled(!adManager.isInterstitialAdReady)
                    }
                }
                
                // Rewarded Ad Section
                Section(header: Text("Rewarded Ad")) {
                    HStack {
                        Button("Load Rewarded") {
                            adManager.loadRewardedAd()
                        }
                        .disabled(adManager.isRewardedAdReady)
                        
                        Spacer()
                        
                        Button("Show Rewarded") {
                            adManager.showRewardedAd()
                        }
                        .disabled(!adManager.isRewardedAdReady)
                    }
                }
            }
            .navigationTitle("Ad Performance Tracker")
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct BannerAdView: UIViewRepresentable {
    private let workingAdUnitID = "ca-app-pub-3940256099942544/2934735716" // Working test ad unit ID
    private let failingAdUnitID = "ca-app-pub-0000000000000000/0000000000" // Invalid ad unit ID that will definitely fail
    
    let useFailingAds: Bool
    
    private var currentAdUnitID: String {
        return useFailingAds ? failingAdUnitID : workingAdUnitID
    }
    
    func makeUIView(context: Context) -> BannerView {
        let bannerView = BannerView(adSize: AdSizeBanner)
        bannerView.adUnitID = currentAdUnitID
        
        // Use modern window access
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            bannerView.rootViewController = window.rootViewController
        }
        
        bannerView.delegate = context.coordinator
        
        // Start ad lifecycle transaction
        let transactionId = AdLifecycleTracker.shared.startAdLifecycle(
            adType: .banner,
            adUnitID: currentAdUnitID,
            placement: .naturalBreak
        )
        
        // Set transaction ID on coordinator
        context.coordinator.transactionId = transactionId
        
        // Start loading span
        context.coordinator.loadingSpan = AdLifecycleTracker.shared.startAdLoading(
            transactionId: transactionId,
            adType: .banner,
            adUnitID: currentAdUnitID
        )
        
        // Load the ad
        bannerView.load(Request())
        
        return bannerView
    }
    
    func updateUIView(_ uiView: BannerView, context: Context) {
        // Check if the ad unit ID has changed
        let newAdUnitID = currentAdUnitID
        if uiView.adUnitID != newAdUnitID {
            // Finish any existing transaction
            if let transactionId = context.coordinator.transactionId {
                AdLifecycleTracker.shared.finishAdLifecycle(transactionId: transactionId)
                context.coordinator.transactionId = nil
            }
            
            // Update the ad unit ID
            uiView.adUnitID = newAdUnitID
            
            // Start new ad lifecycle transaction
            let transactionId = AdLifecycleTracker.shared.startAdLifecycle(
                adType: .banner,
                adUnitID: newAdUnitID,
                placement: .naturalBreak
            )
            
            // Set transaction ID on coordinator
            context.coordinator.transactionId = transactionId
            
            // Start loading span
            context.coordinator.loadingSpan = AdLifecycleTracker.shared.startAdLoading(
                transactionId: transactionId,
                adType: .banner,
                adUnitID: newAdUnitID
            )
            
            // Load the ad with new unit ID
            uiView.load(Request())
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, BannerViewDelegate {
        let parent: BannerAdView
        var transactionId: String?
        var loadingSpan: Span?
        
        init(_ parent: BannerAdView) {
            self.parent = parent
        }
        
        func bannerViewDidReceiveAd(_ bannerView: BannerView) {
            // Finish loading span
            if let loadingSpan = loadingSpan {
                AdLifecycleTracker.shared.finishAdLoading(span: loadingSpan)
                self.loadingSpan = nil
            }
            
            // Track load success
            if let transactionId = transactionId {
                AdLifecycleTracker.shared.trackAdLoadSuccess(
                    transactionId: transactionId,
                    adType: .banner,
                    adUnitID: parent.currentAdUnitID
                )
            }
        }
        
        func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
            // Finish loading span
            if let loadingSpan = loadingSpan {
                AdLifecycleTracker.shared.finishAdLoading(span: loadingSpan)
                self.loadingSpan = nil
            }
            
            // Track load failure
            if let transactionId = transactionId {
                AdLifecycleTracker.shared.trackAdLoadFailure(
                    transactionId: transactionId,
                    adType: .banner,
                    adUnitID: parent.currentAdUnitID,
                    error: error
                )
            }
        }
        
        func bannerViewDidRecordImpression(_ bannerView: BannerView) {
            // Track impression
            if let transactionId = transactionId {
                AdLifecycleTracker.shared.trackAdImpression(
                    transactionId: transactionId,
                    adType: .banner,
                    adUnitID: parent.currentAdUnitID
                )
            }
        }
        
        func bannerViewDidRecordClick(_ bannerView: BannerView) {
            // Track click
            if let transactionId = transactionId {
                AdLifecycleTracker.shared.trackAdClick(
                    transactionId: transactionId,
                    adType: .banner,
                    adUnitID: parent.currentAdUnitID
                )
            }
        }
    }
}

class AdManager: NSObject, ObservableObject {
    @Published var isInterstitialAdReady = false
    @Published var isRewardedAdReady = false
    
    private var interstitialAd: InterstitialAd?
    private var rewardedAd: RewardedAd?
    private var interstitialTransactionId: String?
    private var rewardedTransactionId: String?
    private var interstitialLoadingSpan: Span?
    private var rewardedLoadingSpan: Span?
    private var interstitialWaitingForImpressionSpan: Span?
    private var rewardedWaitingForImpressionSpan: Span?
    private var interstitialWaitingForLoadSuccessSpan: Span?
    private var rewardedWaitingForLoadSuccessSpan: Span?
    private var interstitialDisplayTimeSpan: Span?
    private var rewardedDisplayTimeSpan: Span?
    
    // Working test ad unit IDs
    private let workingInterstitialAdUnitID = "ca-app-pub-3940256099942544/4411468910"
    private let workingRewardedAdUnitID = "ca-app-pub-3940256099942544/1712485313"
    
    // Failing test ad unit IDs (no fill)
    private let failingInterstitialAdUnitID = "ca-app-pub-0000000000000000/0000000000" // Invalid ad unit ID
    private let failingRewardedAdUnitID = "ca-app-pub-0000000000000000/0000000000" // Invalid ad unit ID
    
    private var useFailingAds = false
    private var interstitialAdUnitID: String
    private var rewardedAdUnitID: String
    
    override init() {
        self.interstitialAdUnitID = workingInterstitialAdUnitID
        self.rewardedAdUnitID = workingRewardedAdUnitID
        super.init()
        loadInterstitialAd()
        loadRewardedAd()
    }
    
    func reloadAds(useFailingAds: Bool) {
        self.useFailingAds = useFailingAds
        
        // Update ad unit IDs
        interstitialAdUnitID = useFailingAds ? failingInterstitialAdUnitID : workingInterstitialAdUnitID
        rewardedAdUnitID = useFailingAds ? failingRewardedAdUnitID : workingRewardedAdUnitID
        
        // Reset ad states
        isInterstitialAdReady = false
        isRewardedAdReady = false
        interstitialAd = nil
        rewardedAd = nil
        
        // Finish any existing transactions
        if let interstitialTransactionId = interstitialTransactionId {
            AdLifecycleTracker.shared.finishAdLifecycle(transactionId: interstitialTransactionId)
            self.interstitialTransactionId = nil
        }
        
        if let rewardedTransactionId = rewardedTransactionId {
            AdLifecycleTracker.shared.finishAdLifecycle(transactionId: rewardedTransactionId)
            self.rewardedTransactionId = nil
        }
        
        // Reload ads with new unit IDs
        loadInterstitialAd()
        loadRewardedAd()
    }
    
    func loadInterstitialAd() {
        // Start ad lifecycle transaction
        interstitialTransactionId = AdLifecycleTracker.shared.startAdLifecycle(
            adType: .interstitial,
            adUnitID: interstitialAdUnitID,
            placement: .betweenLevels
        )
        
        // Start loading span with duration
        if let transactionId = interstitialTransactionId {
            interstitialLoadingSpan = AdLifecycleTracker.shared.startAdLoading(
                transactionId: transactionId,
                adType: .interstitial,
                adUnitID: interstitialAdUnitID
            )
        }
        
        InterstitialAd.load(with: interstitialAdUnitID, request: Request()) { [weak self] ad, error in
            DispatchQueue.main.async {
                // Finish loading span
                if let loadingSpan = self?.interstitialLoadingSpan {
                    AdLifecycleTracker.shared.finishAdLoading(span: loadingSpan)
                    self?.interstitialLoadingSpan = nil
                }
                
                if let ad = ad {
                    self?.interstitialAd = ad
                    self?.isInterstitialAdReady = true
                    
                    // Track load success
                    if let transactionId = self?.interstitialTransactionId {
                        AdLifecycleTracker.shared.trackAdLoadSuccess(
                            transactionId: transactionId,
                            adType: .interstitial,
                            adUnitID: self?.interstitialAdUnitID ?? ""
                        )
                    }
                    
                    // Start waiting for impression span AFTER load success
                    if let transactionId = self?.interstitialTransactionId {
                        self?.interstitialWaitingForImpressionSpan = AdLifecycleTracker.shared.startWaitingForImpression(
                            transactionId: transactionId,
                            adType: .interstitial,
                            adUnitID: self?.interstitialAdUnitID ?? ""
                        )
                    }
                } else {
                    self?.isInterstitialAdReady = false
                    
                    // Track load failure
                    if let transactionId = self?.interstitialTransactionId, let error = error {
                        AdLifecycleTracker.shared.trackAdLoadFailure(
                            transactionId: transactionId,
                            adType: .interstitial,
                            adUnitID: self?.interstitialAdUnitID ?? "",
                            error: error
                        )
                    }
                }
            }
        }
    }
    
    func showInterstitialAd() {
        guard let ad = interstitialAd else { return }
        
        // Finish waiting for impression span when show starts (more reliable than waiting for callback)
        if let waitingSpan = interstitialWaitingForImpressionSpan {
            AdLifecycleTracker.shared.finishWaitingForImpression(span: waitingSpan)
            interstitialWaitingForImpressionSpan = nil
        }
        
        // Track show start
        if let transactionId = interstitialTransactionId {
            AdLifecycleTracker.shared.trackAdShowStart(
                transactionId: transactionId,
                adType: .interstitial,
                adUnitID: interstitialAdUnitID
            )
        }
        
        ad.fullScreenContentDelegate = self
        ad.present(from: UIApplication.shared.windows.first?.rootViewController ?? UIViewController())
    }
    
    func loadRewardedAd() {
        // Start ad lifecycle transaction
        rewardedTransactionId = AdLifecycleTracker.shared.startAdLifecycle(
            adType: .rewarded,
            adUnitID: rewardedAdUnitID,
            placement: .achievement
        )
        
        // Start loading span with duration
        if let transactionId = rewardedTransactionId {
            rewardedLoadingSpan = AdLifecycleTracker.shared.startAdLoading(
                transactionId: transactionId,
                adType: .rewarded,
                adUnitID: rewardedAdUnitID
            )
        }
        
        RewardedAd.load(with: rewardedAdUnitID, request: Request()) { [weak self] ad, error in
            DispatchQueue.main.async {
                // Finish loading span
                if let loadingSpan = self?.rewardedLoadingSpan {
                    AdLifecycleTracker.shared.finishAdLoading(span: loadingSpan)
                    self?.rewardedLoadingSpan = nil
                }
                
                if let ad = ad {
                    self?.rewardedAd = ad
                    self?.isRewardedAdReady = true
                    
                    // Track load success
                    if let transactionId = self?.rewardedTransactionId {
                        AdLifecycleTracker.shared.trackAdLoadSuccess(
                            transactionId: transactionId,
                            adType: .rewarded,
                            adUnitID: self?.rewardedAdUnitID ?? ""
                        )
                    }
                    
                    // Start waiting for impression span AFTER load success
                    if let transactionId = self?.rewardedTransactionId {
                        self?.rewardedWaitingForImpressionSpan = AdLifecycleTracker.shared.startWaitingForImpression(
                            transactionId: transactionId,
                            adType: .rewarded,
                            adUnitID: self?.rewardedAdUnitID ?? ""
                        )
                    }
                } else {
                    self?.isRewardedAdReady = false
                    
                    // Track load failure
                    if let transactionId = self?.rewardedTransactionId, let error = error {
                        AdLifecycleTracker.shared.trackAdLoadFailure(
                            transactionId: transactionId,
                            adType: .rewarded,
                            adUnitID: self?.rewardedAdUnitID ?? "",
                            error: error
                        )
                    }
                }
            }
        }
    }
    
    func showRewardedAd() {
        guard let ad = rewardedAd else { return }
        
        // Finish waiting for impression span when show starts (more reliable than waiting for callback)
        if let waitingSpan = rewardedWaitingForImpressionSpan {
            AdLifecycleTracker.shared.finishWaitingForImpression(span: waitingSpan)
            rewardedWaitingForImpressionSpan = nil
        }
        
        // Track show start
        if let transactionId = rewardedTransactionId {
            AdLifecycleTracker.shared.trackAdShowStart(
                transactionId: transactionId,
                adType: .rewarded,
                adUnitID: rewardedAdUnitID
            )
        }
        
        ad.fullScreenContentDelegate = self
        ad.present(from: UIApplication.shared.windows.first?.rootViewController ?? UIViewController()) { [weak self] in
            // Track video completion
            if let transactionId = self?.rewardedTransactionId {
                AdLifecycleTracker.shared.trackAdVideoComplete(
                    transactionId: transactionId,
                    adType: .rewarded,
                    adUnitID: self?.rewardedAdUnitID ?? ""
                )
            }
        }
    }
}

extension AdManager: FullScreenContentDelegate {
    func adDidRecordImpression(_ ad: FullScreenPresentingAd) {
        // Finish waiting for impression span
        if let waitingSpan = interstitialWaitingForImpressionSpan {
            AdLifecycleTracker.shared.finishWaitingForImpression(span: waitingSpan)
            interstitialWaitingForImpressionSpan = nil
        } else if let waitingSpan = rewardedWaitingForImpressionSpan {
            AdLifecycleTracker.shared.finishWaitingForImpression(span: waitingSpan)
            rewardedWaitingForImpressionSpan = nil
        }
        
        // Start display time span
        if let transactionId = interstitialTransactionId {
            interstitialDisplayTimeSpan = AdLifecycleTracker.shared.startAdDisplayTime(
                transactionId: transactionId,
                adType: .interstitial,
                adUnitID: interstitialAdUnitID
            )
        } else if let transactionId = rewardedTransactionId {
            rewardedDisplayTimeSpan = AdLifecycleTracker.shared.startAdDisplayTime(
                transactionId: transactionId,
                adType: .rewarded,
                adUnitID: rewardedAdUnitID
            )
        }
        
        // Track impression
        if let transactionId = interstitialTransactionId {
            AdLifecycleTracker.shared.trackAdImpression(
                transactionId: transactionId,
                adType: .interstitial,
                adUnitID: interstitialAdUnitID
            )
        } else if let transactionId = rewardedTransactionId {
            AdLifecycleTracker.shared.trackAdImpression(
                transactionId: transactionId,
                adType: .rewarded,
                adUnitID: rewardedAdUnitID
            )
        }
    }
    
    func adDidRecordClick(_ ad: FullScreenPresentingAd) {
        // Track click
        if let transactionId = interstitialTransactionId {
            AdLifecycleTracker.shared.trackAdClick(
                transactionId: transactionId,
                adType: .interstitial,
                adUnitID: interstitialAdUnitID
            )
        } else if let transactionId = rewardedTransactionId {
            AdLifecycleTracker.shared.trackAdClick(
                transactionId: transactionId,
                adType: .rewarded,
                adUnitID: rewardedAdUnitID
            )
        }
    }
    
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        // Finish waiting for impression span if it's still active
        if let waitingSpan = interstitialWaitingForImpressionSpan {
            AdLifecycleTracker.shared.finishWaitingForImpression(span: waitingSpan)
            interstitialWaitingForImpressionSpan = nil
        } else if let waitingSpan = rewardedWaitingForImpressionSpan {
            AdLifecycleTracker.shared.finishWaitingForImpression(span: waitingSpan)
            rewardedWaitingForImpressionSpan = nil
        }
        
        // Finish display time span
        if let displaySpan = interstitialDisplayTimeSpan {
            AdLifecycleTracker.shared.finishAdDisplayTime(span: displaySpan)
            interstitialDisplayTimeSpan = nil
        } else if let displaySpan = rewardedDisplayTimeSpan {
            AdLifecycleTracker.shared.finishAdDisplayTime(span: displaySpan)
            rewardedDisplayTimeSpan = nil
        }
        
        // Track dismiss
        if let transactionId = interstitialTransactionId {
            AdLifecycleTracker.shared.trackAdDismiss(
                transactionId: transactionId,
                adType: .interstitial,
                adUnitID: interstitialAdUnitID
            )
            interstitialTransactionId = nil
        } else if let transactionId = rewardedTransactionId {
            AdLifecycleTracker.shared.trackAdDismiss(
                transactionId: transactionId,
                adType: .rewarded,
                adUnitID: rewardedAdUnitID
            )
            rewardedTransactionId = nil
        }
        
        // Reload ads
        loadInterstitialAd()
        loadRewardedAd()
    }
    
    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        // Finish waiting for impression span if it's still active
        if let waitingSpan = interstitialWaitingForImpressionSpan {
            AdLifecycleTracker.shared.finishWaitingForImpression(span: waitingSpan)
            interstitialWaitingForImpressionSpan = nil
        } else if let waitingSpan = rewardedWaitingForImpressionSpan {
            AdLifecycleTracker.shared.finishWaitingForImpression(span: waitingSpan)
            rewardedWaitingForImpressionSpan = nil
        }
        
        // Track show failure
        if let transactionId = interstitialTransactionId {
            AdLifecycleTracker.shared.trackAdShowFailure(
                transactionId: transactionId,
                adType: .interstitial,
                adUnitID: interstitialAdUnitID,
                error: error
            )
        } else if let transactionId = rewardedTransactionId {
            AdLifecycleTracker.shared.trackAdShowFailure(
                transactionId: transactionId,
                adType: .rewarded,
                adUnitID: rewardedAdUnitID,
                error: error
            )
        }
    }
}
