# iOS Setup Guide for Khushi Dua App

## Prerequisites
1. macOS with Xcode installed (latest version recommended)
2. CocoaPods installed (`sudo gem install cocoapods`)
3. Apple Developer Account (for running on physical devices and App Store deployment)

## Initial Setup Steps

### 1. Install CocoaPods Dependencies
```bash
cd ios
pod install
cd ..
```

### 2. Firebase Configuration (Required)
You need to download and add the `GoogleService-Info.plist` file:

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `khushidua`
3. Click on the iOS app (or add a new iOS app if not created)
4. Bundle ID: `com.khushidua.app.khushidua`
5. Download the `GoogleService-Info.plist` file
6. Place it in: `ios/Runner/GoogleService-Info.plist`

**Important:** Make sure to add this file to the Xcode project:
- Open `ios/Runner.xcworkspace` in Xcode
- Drag and drop `GoogleService-Info.plist` into the `Runner` folder
- Ensure "Copy items if needed" is checked
- Ensure it's added to the target

### 3. Push Notifications Setup (For Firebase Cloud Messaging)

If you want push notifications to work on iOS:

1. **Enable Push Notifications Capability in Xcode:**
   - Open `ios/Runner.xcworkspace` in Xcode
   - Select the `Runner` target
   - Go to "Signing & Capabilities"
   - Click "+ Capability"
   - Add "Push Notifications"

2. **Configure APNs in Firebase:**
   - In Firebase Console, go to Project Settings > Cloud Messaging
   - Upload your APNs Certificate or APNs Auth Key
   - Follow [Firebase iOS Cloud Messaging setup guide](https://firebase.google.com/docs/cloud-messaging/ios/client)

### 4. Google Mobile Ads Configuration

The app is already configured with your AdMob App ID in `Info.plist`:
- App ID: `ca-app-pub-7984236421784231~5552144030`

Make sure this matches your AdMob account configuration.

## Building and Running

### On Simulator
```bash
flutter run -d ios
```

### On Physical Device
1. Connect your iPhone via USB
2. In Xcode, select your device as the target
3. Update the signing & capabilities with your Apple Developer Team
4. Run: `flutter run -d ios`

### Build for Release
```bash
flutter build ios --release
```

## Current Configuration

- **Minimum iOS Version:** 13.0
- **Bundle Identifier:** `com.khushidua.app.khushidua`
- **Permissions Configured:**
  - Location (When In Use)
  - Location (Always - when app is in use)
  - Microphone (for future audio recording features)
  - Background Modes: Fetch, Remote Notifications

## Troubleshooting

### Pod Install Issues
If you encounter issues with `pod install`:
```bash
cd ios
rm -rf Pods Podfile.lock
pod cache clean --all
pod install --repo-update
cd ..
```

### Build Issues
1. Clean the build folder: `flutter clean`
2. Remove derived data: `rm -rf ios/Pods ios/.symlinks`
3. Reinstall pods: `cd ios && pod install && cd ..`
4. Rebuild: `flutter pub get && flutter run`

### Firebase Issues
- Ensure `GoogleService-Info.plist` is added to the Xcode project
- Verify the bundle identifier matches in Firebase Console and Xcode
- Check that Firebase iOS app is configured correctly

### Signing Issues
- Open `ios/Runner.xcworkspace` in Xcode
- Select Runner target
- Go to "Signing & Capabilities"
- Select your Team and ensure "Automatically manage signing" is enabled

