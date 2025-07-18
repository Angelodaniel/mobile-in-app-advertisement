//
//  ContentView.swift
//  MobileInAppAdvertisement
//
//  Created by Angelo de Voer on 03/06/2025.
//

import SwiftUI
import CoreData
import GoogleMobileAds

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
                        NavigationLink {
                            ItemDetailView(item: item)
                        } label: {
                            HStack {
                                Text(item.timestamp!, formatter: itemFormatter)
                                Spacer()
                                Button("Show Ad") {
                                    adManager.showInterstitialAd()
                                }
                                .buttonStyle(.borderedProminent)
                                .disabled(!adManager.isInterstitialAdReady)
                            }
                        }
                    }
                    .onDelete(perform: deleteItems)
                }
                
                // Banner Ad at the bottom
                BannerAdView()
                    .frame(height: 50)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Rewarded Ad") {
                        adManager.showRewardedAd()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!adManager.isRewardedAdReady)
                }
                ToolbarItem {
                    Button(action: addItem) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
            .onAppear {
                adManager.loadAds()
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
                print("Error saving item: \(nsError), \(nsError.userInfo)")
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
                print("Error deleting items: \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

struct ItemDetailView: View {
    let item: Item
    @StateObject private var adManager = AdManager()
    
    var body: some View {
        VStack {
            Text("Item Details")
                .font(.title)
            
            Text("Created: \(item.timestamp!, formatter: itemFormatter)")
                .padding()
            
            Button("Show Interstitial Ad") {
                adManager.showInterstitialAd()
            }
            .buttonStyle(.borderedProminent)
            .disabled(!adManager.isInterstitialAdReady)
            .padding()
            
            Spacer()
        }
        .onAppear {
            adManager.loadInterstitialAd()
        }
    }
}

struct BannerAdView: UIViewRepresentable {
    func makeUIView(context: Context) -> GADBannerView {
        let bannerView = GADBannerView(adSize: GADAdSizeBanner)
        bannerView.adUnitID = AdConfiguration.bannerAdUnitID
        bannerView.rootViewController = UIApplication.shared.windows.first?.rootViewController
        bannerView.load(GADRequest())
        return bannerView
    }
    
    func updateUIView(_ uiView: GADBannerView, context: Context) {}
}

class AdManager: ObservableObject {
    @Published var isInterstitialAdReady = false
    @Published var isRewardedAdReady = false
    
    private var interstitialAd: GADInterstitialAd?
    private var rewardedAd: GADRewardedAd?
    
    func loadAds() {
        loadInterstitialAd()
        loadRewardedAd()
    }
    
    func loadInterstitialAd() {
        let request = GADRequest()
        GADInterstitialAd.load(
            withAdUnitID: AdConfiguration.interstitialAdUnitID,
            request: request
        ) { [weak self] ad, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Failed to load interstitial ad: \(error.localizedDescription)")
                    self?.isInterstitialAdReady = false
                } else {
                    self?.interstitialAd = ad
                    self?.isInterstitialAdReady = true
                }
            }
        }
    }
    
    func showInterstitialAd() {
        guard let interstitialAd = interstitialAd else { return }
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            interstitialAd.present(fromRootViewController: window.rootViewController!)
        }
        
        // Load the next ad
        loadInterstitialAd()
    }
    
    func loadRewardedAd() {
        let request = GADRequest()
        GADRewardedAd.load(
            withAdUnitID: AdConfiguration.rewardedAdUnitID,
            request: request
        ) { [weak self] ad, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Failed to load rewarded ad: \(error.localizedDescription)")
                    self?.isRewardedAdReady = false
                } else {
                    self?.rewardedAd = ad
                    self?.isRewardedAdReady = true
                }
            }
        }
    }
    
    func showRewardedAd() {
        guard let rewardedAd = rewardedAd else { return }
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            rewardedAd.present(fromRootViewController: window.rootViewController!) {
                // User earned reward
                print("User earned reward!")
            }
        }
        
        // Load the next ad
        loadRewardedAd()
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
