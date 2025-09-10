# Mobile In-App Advertisement Performance Tracker

A comprehensive SwiftUI iOS application that demonstrates advanced ad lifecycle performance tracking using Google Mobile Ads SDK and Sentry for detailed performance monitoring, error tracking, and business intelligence.

## 🎯 Use Case & Business Value

### The Problem
Mobile app developers face significant challenges when integrating in-app advertisements:

- **Revenue Loss**: Poor ad performance directly impacts revenue
- **User Experience Issues**: Slow-loading or failing ads frustrate users
- **Lack of Visibility**: Limited insights into ad performance and user behavior
- **Optimization Blind Spots**: No data to identify performance bottlenecks
- **Error Tracking Gaps**: Ad failures go unnoticed, affecting fill rates

### The Solution
This app demonstrates how to instrument comprehensive ad performance tracking that provides:

- **Complete Ad Lifecycle Visibility**: Track every stage from request to completion
- **Performance Optimization Data**: Identify slow-loading ads and optimize placement
- **Revenue Protection**: Monitor fill rates and error patterns
- **User Experience Insights**: Track display times and user interactions
- **Business Intelligence**: Battery impact, session analytics, and drop-off tracking

### Real-World Impact
With proper ad performance tracking, you can:
- **Increase Revenue**: Optimize ad placement and timing based on data
- **Improve User Experience**: Reduce ad-related performance issues
- **Reduce Churn**: Identify and fix ad-related user drop-offs
- **Scale Confidently**: Monitor performance as your user base grows

## 🔧 Implementation & Instrumentation

### Architecture Overview

The app uses a sophisticated instrumentation pattern that creates a complete performance monitoring system:

```
┌─────────────────────────────────────────────────────────────┐
│                    Sentry Performance Layer                │
├─────────────────────────────────────────────────────────────┤
│  AdLifecycleTracker.swift - Core instrumentation logic    │
│  ├── Transaction Management                               │
│  ├── Span Creation & Timing                               │
│  ├── Data Attribute Collection                            │
│  └── Error Handling & Cleanup                            │
├─────────────────────────────────────────────────────────────┤
│  ContentView.swift - UI & Ad Integration                  │
│  ├── Banner Ad Implementation                            │
│  ├── Interstitial Ad Management                          │
│  ├── Rewarded Ad Handling                                │
│  └── Error Scenario Testing                              │
├─────────────────────────────────────────────────────────────┤
│  Google Mobile Ads SDK - Ad Serving                      │
│  ├── Banner Ads                                          │
│  ├── Interstitial Ads                                    │
│  └── Rewarded Video Ads                                  │
└─────────────────────────────────────────────────────────────┘
```

### Core Instrumentation Components

#### 1. AdLifecycleTracker.swift - The Performance Engine

**Purpose**: Centralized performance tracking for all ad interactions

**Key Features**:
- **Transaction Management**: Creates and manages Sentry transactions for each ad lifecycle
- **Span Hierarchy**: Builds detailed span trees showing complete ad flow
- **Rich Metadata**: Collects comprehensive data attributes on every event
- **Battery Monitoring**: Tracks device resource consumption
- **Session Analytics**: Monitors user behavior and session continuation

**Core Methods**:
```swift
// Start a complete ad lifecycle transaction
func startAdLifecycle(adType: AdType, adUnitID: String, placement: AdPlacement) -> String

// Create detailed spans for each ad event
private func createSpan(transaction: Span, event: AdEvent, data: [String: Any]) -> Span

// Track specific ad events with timing
func trackAdLoadSuccess(transactionId: String, adType: AdType, adUnitID: String)
func trackAdImpression(transactionId: String, adType: AdType, adUnitID: String)
func trackAdDismiss(transactionId: String, adType: AdType, adUnitID: String)
```

#### 2. Sentry Integration - Performance Data Pipeline

**Configuration** (MobileInAppAdvertisementApp.swift):
```swift
SentrySDK.start { options in
    options.dsn = "YOUR_SENTRY_DSN"
    options.debug = true
    options.tracesSampleRate = 1.0 // 100% sampling for demo
    options.configureProfiling = {
        $0.sessionSampleRate = 1.0
        $0.lifecycle = .trace
    }
}
```

**Transaction Structure**:
```
ad.lifecycle - ad_lifecycle_[banner|interstitial|rewarded]
├── ad_request (40ms) [battery_level: 0.85, ad_type: banner]
├── ad_loading (2.1s) [battery_level: 0.84, duration: 2100ms]
├── ad_load_success (0.07ms) [battery_level: 0.84]
├── ad_waiting_for_impression (4.45m) [battery_level: 0.83]
├── ad_show_start (0.15ms) [battery_level: 0.83]
├── ad_impression (0.03ms) [battery_level: 0.82]
├── ad_display_time (6.23s) [battery_level: 0.80]
├── ad_click (0.05ms) [battery_level: 0.80] // if user clicks
└── ad_dismiss (0.04ms) [battery_level: 0.80]
[battery_impact_percent: 5.88%, session_duration: 1200s]
```

#### 3. Ad Type Implementations

**Banner Ads** (ContentView.swift):
- Automatic loading and display
- Continuous impression tracking
- Click interaction monitoring
- Complete lifecycle from load to dismiss

**Interstitial Ads**:
- Load → Show → Dismiss cycle
- Waiting period tracking
- Display time measurement
- User interaction monitoring

**Rewarded Ads**:
- Video completion tracking
- Reward delivery monitoring
- User engagement measurement
- Session continuation analysis

### Data Attributes & Business Intelligence

Each span includes rich metadata for comprehensive analysis:

#### Ad Performance Data
- `ad_type`: banner, interstitial, rewarded
- `ad_unit_id`: Ad unit identifier
- `ad_placement`: app_launch, between_levels, natural_break, achievement
- `session_duration_seconds`: How long the user session has been active
- `ads_in_session`: Number of ads shown in current session

#### Performance Metrics
- `battery_level`: Device battery level at each event
- `battery_impact_percent`: Percentage of battery consumed during ad operations
- `duration`: Actual timing for loading and display operations
- `timestamp`: Precise timing for each event

#### User Experience Data
- `time_to_drop_off_seconds`: How long before user leaves after seeing ad
- `user_dropped_off`: Boolean indicating if user left after ad
- `session_continued`: Whether user continued using app after ad
- `time_to_next_action_seconds`: Time until next user action

## 📊 Sentry Dashboard & Data Visualization

### Live Demo Data

**Sentry Organization**: [View Live Data](https://sentry.io/organizations/uprate/projects/mobile-in-app-advertisements/)

**Key Queries to Try**:
```sql
-- Ad lifecycle transactions
transaction:ad.lifecycle

-- Banner ad performance
transaction:ad.lifecycle AND ad_type:banner

-- Failed ad loads
span:ad_load_failure

-- Performance metrics
avg(span.duration) WHERE span.op:ad_loading
```

### Business Metrics Dashboard

#### Revenue Protection Metrics
- **Fill Rate**: `count(span:ad_load_success) / count(span:ad_request) * 100`
- **Error Rate**: `count(span:ad_load_failure) / count(span:ad_request) * 100`
- **Revenue Impact**: Track correlation between ad performance and user retention

#### User Experience Metrics
- **Click-Through Rate**: `count(span:ad_click) / count(span:ad_impression) * 100`
- **Video Completion Rate**: `count(span:ad_video_complete) / count(span:ad_show_start) * 100`
- **Display Duration**: Average time ads are shown to users
- **User Drop-off Rate**: Users who leave after seeing ads

#### Performance Optimization Metrics
- **Average Loading Time**: `avg(span.duration) WHERE span.op:ad_loading`
- **Battery Impact**: Average battery consumption per ad type
- **Session Continuation**: Users who continue after seeing ads
- **Ad Placement Effectiveness**: Performance by placement type

### Sample Performance Trace

```
ad.lifecycle - ad_lifecycle_interstitial (4.57m total)
├── ad_request (40ms) [battery_level: 0.85, placement: between_levels]
├── ad_loading (2.1s) [battery_level: 0.84, network: wifi]
├── ad_load_success (0.07ms) [battery_level: 0.84]
├── ad_waiting_for_impression (4.45m) [battery_level: 0.83]
├── ad_show_start (0.15ms) [battery_level: 0.83]
├── ad_impression (0.03ms) [battery_level: 0.82]
├── ad_display_time (6.23s) [battery_level: 0.80]
└── ad_dismiss (0.04ms) [battery_level: 0.80]
[battery_impact_percent: 5.88%, session_duration: 1200s, ads_in_session: 3]
```

## 🚀 How to Run It Yourself

### Prerequisites
- Xcode 15.0+
- iOS 18.5+
- Ruby (for Fastlane)
- Sentry account and project
- Google AdMob account (optional - uses test ad units)

### Quick Start

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd mobile-in-app-advertisement
   ```

2. **Install dependencies**
   ```bash
   bundle install
   ```

3. **Configure Sentry**
   - Get your Sentry DSN from [Sentry.io](https://sentry.io)
   - Replace the DSN in `MobileInAppAdvertisementApp.swift` (line 19)
   - Or create a `sentry.properties` file with your configuration

4. **Build and Run**
   ```bash
   # Open in Xcode
   open MobileInAppAdvertisement.xcodeproj
   
   # Or build from command line
   xcodebuild -project MobileInAppAdvertisement.xcodeproj -scheme MobileInAppAdvertisement -destination 'platform=iOS Simulator,name=iPhone 16' build
   ```

### Emerge Tools Distribution

**Download from Emerge**: [Get the App](https://emerge.tools/distribution/link/your-distribution-link)

This provides a pre-built version with:
- All dependencies included
- Sentry configuration ready
- Test ad units configured
- Performance monitoring active

### Testing Different Scenarios

#### 1. Working Ads (Default)
- App starts with Google's test ad unit IDs
- All ad types load and display successfully
- Complete lifecycle tracking visible in Sentry

#### 2. Failing Ads (Toggle)
- Use "Use Failing Test Ads" toggle
- Switches to invalid ad unit IDs
- Tests error handling and failure tracking
- Error spans visible in Sentry

#### 3. Ad Types to Test
- **Banner Ads**: Automatically load and display
- **Interstitial Ads**: Click "Load Interstitial" → "Show Interstitial"
- **Rewarded Ads**: Click "Load Rewarded" → "Show Rewarded"

### What You'll See in Sentry

1. **Transactions**: One `ad.lifecycle` transaction per ad interaction
2. **Spans**: Multiple spans per transaction showing each event
3. **Data Attributes**: Rich metadata on each span
4. **Performance Data**: Loading times, display duration, user interactions
5. **Error Tracking**: Failed ad loads and network issues
6. **Battery Impact**: Device resource consumption (returns -1 on simulator)

## 🔍 Code Deep Dive

### Key Implementation Patterns

#### 1. Transaction Lifecycle Management
```swift
// Start transaction with rich metadata
let transaction = SentrySDK.startTransaction(
    name: "ad_lifecycle_\(adType.rawValue)",
    operation: "ad.lifecycle_\(adType.rawValue)"
)

// Add comprehensive data attributes
transaction.setData(value: adType.rawValue, key: "ad_type")
transaction.setData(value: adUnitID, key: "ad_unit_id")
transaction.setData(value: placement.rawValue, key: "ad_placement")
transaction.setData(value: Date(), key: "start_time")
```

#### 2. Span Creation with Timing
```swift
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
    
    return span
}
```

#### 3. Error Handling & Cleanup
```swift
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
```

### Integration with Google Mobile Ads

#### Banner Ad Integration
```swift
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
```

#### Full-Screen Ad Integration
```swift
func adDidRecordImpression(_ ad: FullScreenPresentingAd) {
    // Start display time span
    if let transactionId = interstitialTransactionId {
        interstitialDisplayTimeSpan = AdLifecycleTracker.shared.startAdDisplayTime(
            transactionId: transactionId,
            adType: .interstitial,
            adUnitID: interstitialAdUnitID
        )
    }
    
    // Track impression
    AdLifecycleTracker.shared.trackAdImpression(
        transactionId: transactionId,
        adType: .interstitial,
        adUnitID: interstitialAdUnitID
    )
}
```

## 📈 Business Value & ROI

### Revenue Impact
- **Fill Rate Optimization**: Identify and fix ad loading issues
- **User Retention**: Reduce ad-related user drop-offs
- **Performance Optimization**: Improve ad placement timing
- **Error Prevention**: Proactive monitoring of ad failures

### User Experience Benefits
- **Performance Monitoring**: Track and optimize ad loading times
- **Battery Impact**: Monitor device resource consumption
- **Session Analytics**: Understand user behavior patterns
- **Error Recovery**: Implement better error handling

### Development Efficiency
- **Real-time Monitoring**: Immediate visibility into ad performance
- **Data-Driven Decisions**: Use metrics to guide optimization
- **Automated Testing**: Continuous performance validation
- **Scalable Architecture**: Pattern works for any ad network

## 🤝 Contributing

This is a demonstration project showcasing best practices for mobile ad performance monitoring. Feel free to:

- Fork and modify for your own ad tracking needs
- Submit issues for bugs or improvements
- Share your own instrumentation patterns
- Use as a reference for Sentry integration

## 📄 License

Copyright (c) 2025 Angelo de Voer. All rights reserved.

---

**Ready to see it in action?** [Download from Emerge](itms-services://?action=download-manifest&url=https%3A%2F%2Finstall.emergetools.com%2Finstall%3FinstallId%3Dslnk_6op2T3Fb6Y2B-no-redirect) or [View Live Sentry Data](https://sentry.io/organizations/uprate/projects/mobile-in-app-advertisements/)

**Questions?** Check out the [Sentry Documentation](https://docs.sentry.io/platforms/apple/) or open an issue in this repository.
