//
//  ContentView.swift
//  MobileInAppAdvertisement
//
//  Created by Angelo de Voer on 03/06/2025.
//

import SwiftUI
import CoreData
import GoogleMobileAds
import Sentry

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var adManager = AdManager()

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Item.timestamp, ascending: true)],
        animation: .default)
    private var items: FetchedResults<Item>

    var body: some View {
        NavigationView {
            VStack {
                // Banner Ad at the top
                BannerAdView()
                    .frame(height: 50)
                
                List {
                    ForEach(items) { item in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(item.timestamp!, formatter: itemFormatter)
                                    .font(.headline)
                                Text("Item \(item.timestamp!.timeIntervalSince1970)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            // Interstitial Ad Button
                            Button("Show Ad") {
                                adManager.showInterstitialAd()
                            }
                            .disabled(!adManager.isInterstitialAdReady)
                            .buttonStyle(.borderedProminent)
                            
                            // Rewarded Ad Button
                            Button("Reward") {
                                adManager.showRewardedAd()
                            }
                            .disabled(!adManager.isRewardedAdReady)
                            .buttonStyle(.bordered)
                        }
                    }
                    .onDelete(perform: deleteItems)
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        EditButton()
                    }
                    ToolbarItem {
                        Button(action: addItem) {
                            Label("Add Item", systemImage: "plus")
                        }
                    }
                }
                
                // Banner Ad at the bottom
                BannerAdView()
                    .frame(height: 50)
            }
            .navigationTitle("Ad Performance Tracker")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Sentry DSN:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("https://b72599749761ea6e64e6551475b56e21@o4508065179762768.ingest.de.sentry.io/4509434720485456")
                            .font(.caption2)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                    }
                }
            }
        }
    }

    private func addItem() {
        withAnimation {
            let newItem = Item(context: viewContext)
            newItem.timestamp = Date()

            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { items[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    private func getSentryDSN() -> String {
        // Get the DSN from the same method used in the app
        return MobileInAppAdvertisementApp.getSentryDSN()
    }
}

struct BannerAdView: UIViewRepresentable {
    private let adUnitID = "ca-app-pub-3940256099942544/2934735716" // Test ad unit ID
    
    func makeUIView(context: Context) -> BannerView {
        let bannerView = BannerView(adSize: AdSizeBanner)
        bannerView.adUnitID = adUnitID
        
        // Use modern window access
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            bannerView.rootViewController = window.rootViewController
        }
        
        bannerView.delegate = context.coordinator
        
        // Start ad lifecycle transaction
        let transactionId = AdLifecycleTracker.shared.startAdLifecycle(
            adType: .banner,
            adUnitID: adUnitID
        )
        
        // Set transaction ID on coordinator
        context.coordinator.transactionId = transactionId
        
        // Start loading span
        context.coordinator.loadingSpan = AdLifecycleTracker.shared.startAdLoading(
            transactionId: transactionId,
            adType: .banner,
            adUnitID: adUnitID
        )
        
        // Load the ad
        bannerView.load(Request())
        
        return bannerView
    }
    
    func updateUIView(_ uiView: BannerView, context: Context) {}
    
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
                    adUnitID: parent.adUnitID
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
                    adUnitID: parent.adUnitID,
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
                    adUnitID: parent.adUnitID
                )
            }
        }
        
        func bannerViewDidRecordClick(_ bannerView: BannerView) {
            // Track click
            if let transactionId = transactionId {
                AdLifecycleTracker.shared.trackAdClick(
                    transactionId: transactionId,
                    adType: .banner,
                    adUnitID: parent.adUnitID
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
    
    private let interstitialAdUnitID = "ca-app-pub-3940256099942544/4411468910" // Test ad unit ID
    private let rewardedAdUnitID = "ca-app-pub-3940256099942544/1712485313" // Test ad unit ID
    
    override init() {
        super.init()
        loadInterstitialAd()
        loadRewardedAd()
    }
    
    func loadInterstitialAd() {
        // Start ad lifecycle transaction
        interstitialTransactionId = AdLifecycleTracker.shared.startAdLifecycle(
            adType: .interstitial,
            adUnitID: interstitialAdUnitID
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
            adUnitID: rewardedAdUnitID
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

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()
