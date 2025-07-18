# Mobile In-App Advertisement

A SwiftUI iOS application for displaying in-app advertisements with Sentry integration for error monitoring.

## Setup

### Prerequisites
- Xcode 15.0+
- iOS 18.5+
- Ruby (for Fastlane)

### Installation

1. Clone the repository
2. Install dependencies:
   ```bash
   bundle install
   ```

### Sentry Configuration

1. Copy the Sentry properties template:
   ```bash
   cp sentry.properties.template sentry.properties
   ```

2. Edit `sentry.properties` and add your Sentry auth token:
   ```properties
   auth.token=your_auth_token_here
   ```

3. Set the environment variable for the build script:
   ```bash
   export SENTRY_AUTH_TOKEN=your_auth_token_here
   ```

### Building

Open `MobileInAppAdvertisement.xcodeproj` in Xcode and build the project.

## Project Structure

```
├── MobileInAppAdvertisement/          # Main app source code
├── MobileInAppAdvertisementTests/     # Unit tests
├── MobileInAppAdvertisementUITests/   # UI tests
├── fastlane/                          # Fastlane configuration
├── sentry.properties.template         # Sentry config template
└── README.md                          # This file
```

## Features

- SwiftUI interface
- Core Data persistence
- Sentry error monitoring
- Fastlane automation

## License

Copyright (c) 2025 Angelo de Voer. All rights reserved. 