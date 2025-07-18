# Mobile In-App Advertisement Performance Tracker

A SwiftUI iOS application that demonstrates comprehensive ad lifecycle performance tracking using Google Mobile Ads SDK and Sentry for detailed performance monitoring and error tracking.

## 🎯 What This App Does

This app serves as a demonstration of how to instrument mobile ad performance with detailed lifecycle tracking. It includes:

### Ad Types Supported
- **Banner Ads** - Displayed at the bottom of the screen
- **Interstitial Ads** - Full-screen ads that appear between app screens
- **Rewarded Ads** - Video ads that users watch to earn rewards

### Performance Tracking Features
- **Complete Ad Lifecycle Monitoring** - Track every stage of ad delivery from request to completion
- **Detailed Performance Spans** - Measure loading times, display duration, and user interaction
- **Real-time Performance Data** - View performance metrics in Sentry's performance dashboard
- **Error Tracking** - Monitor ad failures and network issues
- **User Experience Metrics** - Track how long users interact with ads
- **Battery Impact Monitoring** - Track device battery consumption during ad operations
- **Ad Placement Timing** - Monitor when ads are shown during user journey
- **Session Analytics** - Track user drop-off rates and session continuation
- **Performance Impact Metrics** - Monitor frame rate and resource usage

## 🔧 Sentry Instrumentation

The app implements comprehensive Sentry performance tracking with the following instrumentation:

### Ad Lifecycle Transactions
Each ad interaction creates a separate Sentry transaction with the following structure:

```
ad.lifecycle - ad_lifecycle_[banner|interstitial|rewarded]
├── ad_request - Request ad from network
├── ad_loading - Network loading time (with actual duration)
├── ad_load_success - Ad loaded successfully
├── ad_waiting_for_impression - Time between load and user interaction
├── ad_show_start - Start showing ad to user
├── ad_impression - Ad impression recorded
├── ad_display_time - Time ad is displayed to user
├── ad_click - User clicked on ad (if applicable)
├── ad_video_complete - Video completion (rewarded ads only)
└── ad_dismiss - Ad dismissed by user
```

### Performance Metrics Tracked
- **Loading Performance** - Network request and ad loading times
- **Display Duration** - How long ads are shown to users
- **User Interaction** - Clicks, impressions, and completion rates
- **Error Rates** - Failed ad loads and network issues
- **Waiting Times** - Time between ad load and user interaction
- **Battery Impact** - Percentage of battery consumed during ad operations
- **Ad Placement Performance** - Which placements cause user drop-off
- **Session Continuation** - Whether users continue using app after ads

### Data Attributes
Each span includes rich metadata:
- Ad type (banner, interstitial, rewarded)
- Ad unit ID
- Ad placement context (app launch, between levels, natural break, etc.)
- Timestamps for start/end events
- Error details for failures
- User interaction data
- Battery levels at each event
- Session duration and ad count
- User drop-off indicators

## 📊 Dashboard Metrics

### Core Ad Performance Metrics
- **Fill Rate** - Count of `ad_load_success` spans / total ad requests
- **Click-Through Rate (CTR)** - Count of `ad_click` spans / count of `ad_impression` spans
- **Rewarded Video Completion Rate** - Count of `ad_video_complete` spans / count of `ad_show_start` spans for rewarded ads
- **Ad Interaction Frequency** - Total ad interactions per user session

### Advanced Performance Metrics
- **Battery Impact Percent** - Average battery consumption per ad type
- **Frame Rate Impact** - Performance degradation during ad display
- **Opt-Out/Opt-In Rates** - User privacy preference tracking
- **Ad Placement Effectiveness** - Drop-off rates by placement type
- **Session Continuation Rate** - Users who continue after seeing ads

## 🚀 Setup Instructions

### Prerequisites
- Xcode 15.0+
- iOS 18.5+
- Ruby (for Fastlane)
- Sentry account and project
- Google AdMob account (optional - app uses test ad units)

### Installation

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
   ```bash
   cp sentry.properties.template sentry.properties
   ```
   
   Edit `sentry.properties` and add your Sentry configuration:
   ```properties
   org=your-organization-slug
   project=your-project-slug
   auth.token=your_auth_token_here
   ```

4. **Configure the App**
   - Open `MobileInAppAdvertisement.xcodeproj` in Xcode
   - Edit `MobileInAppAdvertisementApp.swift`
   - Replace the DSN with your actual Sentry DSN
   - Build and run the project

### Sentry DSN Configuration
Get your DSN from your Sentry project settings:
1. Go to your Sentry project
2. Navigate to Settings → Client Keys (DSN)
3. Copy the DSN string
4. Replace the DSN in the app

## 📊 What You'll See in Sentry

### Performance Dashboard
- **Ad Lifecycle Transactions** - One transaction per ad interaction
- **Detailed Spans** - Each ad event as a separate span with timing
- **Performance Trends** - Loading times, display duration, and error rates
- **User Experience Metrics** - How users interact with ads
- **Battery Impact Analysis** - Device resource consumption patterns
- **Ad Placement Performance** - Which placements work best

### Key Metrics to Monitor
- **Ad Load Success Rate** - Percentage of successful ad loads
- **Average Loading Time** - Time to load ads from network
- **Display Duration** - How long ads are shown
- **User Interaction Rate** - Clicks and completions
- **Error Distribution** - Types and frequency of ad failures
- **Battery Impact** - Average battery consumption per ad type
- **User Drop-off Rate** - Users who leave after seeing ads
- **Session Continuation** - Users who continue using the app

### Sample Performance Trace
```
ad.lifecycle - ad_lifecycle_interstitial (4.57m total)
├── ad_request (40ms) [battery_level: 0.85]
├── ad_loading (2.1s) [battery_level: 0.84]
├── ad_load_success (0.07ms) [battery_level: 0.84]
├── ad_waiting_for_impression (4.45m) [battery_level: 0.83]
├── ad_show_start (0.15ms) [battery_level: 0.83]
├── ad_impression (0.03ms) [battery_level: 0.82]
├── ad_display_time (6.23s) [battery_level: 0.80]
└── ad_dismiss (0.04ms) [battery_level: 0.80]
[battery_impact_percent: 5.88%]
```

## 🏗️ Project Structure

```
├── MobileInAppAdvertisement/
│   ├── MobileInAppAdvertisementApp.swift    # App entry point & Sentry config
│   ├── ContentView.swift                    # Main UI & ad management
│   ├── AdLifecycleTracker.swift             # Sentry performance tracking
│   └── Assets.xcassets/                     # App assets
├── fastlane/                                # Build automation
├── sentry.properties.template               # Sentry config template
└── README.md                               # This file
```

## 🔒 Security & Privacy

### Safe for Public Repositories
- ✅ Uses Google's test ad unit IDs (safe to share)
- ✅ No real ad revenue or sensitive data
- ✅ Sentry DSN is configurable (not hardcoded)
- ✅ `.gitignore` excludes sensitive configuration files

### Data Collection
- **Performance Data Only** - No personal user information
- **Ad Interaction Metrics** - Anonymous usage statistics
- **Error Tracking** - Technical error details only
- **Battery Monitoring** - Device resource usage (no personal data)
- **No User Identifiers** - Completely anonymous tracking

## 🧪 Testing

The app uses Google's test ad unit IDs, so you can:
- Test all ad types without real ad serving
- Verify Sentry instrumentation works correctly
- Debug performance tracking in real-time
- Experiment with different ad scenarios
- Test battery impact on iOS Simulator (returns -1) and real devices

## 📈 Performance Monitoring Best Practices

This app demonstrates several best practices for ad performance monitoring:

1. **Granular Instrumentation** - Track each ad lifecycle stage separately
2. **Real Duration Tracking** - Use start/finish spans for accurate timing
3. **Rich Metadata** - Include ad type, unit ID, placement, and error details
4. **User Experience Focus** - Track display time, interaction rates, and drop-off
5. **Resource Monitoring** - Track battery impact and performance degradation
6. **Placement Optimization** - Monitor which ad placements work best
7. **Session Analytics** - Track user behavior after seeing ads

## 🤝 Contributing

This is a demonstration project. Feel free to:
- Fork and modify for your own ad tracking needs
- Submit issues for bugs or improvements
- Share your own instrumentation patterns

## 📄 License

Copyright (c) 2025 Angelo de Voer. All rights reserved.

---

**Note**: This app is designed for educational and demonstration purposes. For production use, replace test ad unit IDs with your actual AdMob ad units and configure appropriate Sentry sampling rates. 