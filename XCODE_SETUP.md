# Xcode Project Setup Guide

This document explains how to create an Xcode project for ValeCRM and add all the Swift source files.

## Step 1: Create New Xcode Project

1. Open **Xcode**
2. Select **File > New > Project**
3. Choose **iOS > App**
4. Click **Next**

## Step 2: Project Configuration

Configure your project with these settings:

- **Product Name**: `ValeCRM`
- **Team**: Select your Apple Developer team
- **Organization Identifier**: `com.keystonevale` (or your own)
- **Bundle Identifier**: `com.keystonevale.ValeCRM`
- **Interface**: **SwiftUI**
- **Language**: **Swift**
- **Storage**: None (we're using Supabase)
- **Include Tests**: Yes (recommended)

Click **Next** and choose the location for your project.

## Step 3: Add Source Files

After creating the project, you'll need to add all the Swift files from this repository:

### Method 1: Drag and Drop (Recommended)

1. In **Finder**, navigate to the `crm-ios-app` folder
2. Open **Xcode** with your new project
3. In Xcode's **Project Navigator** (left sidebar), select the project root
4. Drag the following folders from Finder into Xcode:
   - `Models/`
   - `Services/`
   - `ViewModels/`
   - `Views/`
   - `Resources/`
5. Also drag these individual files:
   - `Config.swift`
   
6. In the dialog that appears:
   - ✅ Check "Copy items if needed"
   - ✅ Check "Create groups"
   - ✅ Ensure your target is selected
   - Click **Finish**

### Method 2: Add Files Manually

1. Right-click on your project in the Project Navigator
2. Select **Add Files to "ValeCRM"...**
3. Navigate to each folder and select all `.swift` files
4. Make sure to:
   - ✅ Check "Copy items if needed"
   - ✅ Select your app target
   - Click **Add**

## Step 4: Update Main App File

1. Delete the default `ValeCRMApp.swift` that Xcode created
2. Make sure `CRMApp.swift` is in your project (this is your main entry point)

## Step 5: Configure Deployment Target

1. Select your project in the Project Navigator
2. Select your app target
3. Go to the **General** tab
4. Under **Deployment Info**:
   - Set **Minimum Deployments** to `iOS 16.0`
   - Select supported device orientations (recommend Portrait only for Phase 1)

## Step 6: Add Required Frameworks

Your app uses these frameworks (they should be auto-linked):
- SwiftUI (default)
- Combine (default)
- Foundation (default)
- LocalAuthentication (for Face ID/Touch ID)
- Security (for Keychain)

If you get build errors about missing frameworks:
1. Select your target
2. Go to **Build Phases**
3. Expand **Link Binary With Libraries**
4. Click **+** and add:
   - `LocalAuthentication.framework`
   - `Security.framework`

## Step 7: Configure Info.plist

Add these keys to your `Info.plist`:

```xml
<key>NSFaceIDUsageDescription</key>
<string>ValeCRM uses Face ID to securely authenticate you and protect your data.</string>

<key>NSCameraUsageDescription</key>
<string>ValeCRM needs camera access to take photos of properties.</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>ValeCRM needs photo library access to attach property images.</string>

<key>UILaunchScreen</key>
<dict>
    <key>UIColorName</key>
    <string>LaunchScreenBackground</string>
    <key>UIImageName</key>
    <string>LaunchScreenLogo</string>
</dict>
```

## Step 8: Add App Icon

1. In **Assets.xcassets**, select **AppIcon**
2. Drag your app icon files into the appropriate slots
3. Required size: 1024x1024px for App Store

Alternatively, you can use SF Symbols as a temporary icon:
- The LoginView already uses `building.2.circle.fill` as a temporary logo

## Step 9: Configure Signing

1. Select your project in Project Navigator
2. Select your target
3. Go to **Signing & Capabilities**
4. Check **Automatically manage signing**
5. Select your **Team**
6. Xcode will generate provisioning profiles automatically

## Step 10: Build and Run

1. Select a simulator or connected device from the scheme selector
2. Press `Cmd + B` to build
3. Press `Cmd + R` to run

### Common Build Issues

**Issue**: "Cannot find 'NetworkService' in scope"
- **Fix**: Ensure all files are added to your target (check target membership in File Inspector)

**Issue**: "Missing required module"
- **Fix**: Add missing frameworks in Build Phases > Link Binary With Libraries

**Issue**: Keychain errors on simulator
- **Fix**: Reset simulator content and settings

## Step 11: Test Features

After successful build, test these features:

- [ ] App launches successfully
- [ ] Login screen appears
- [ ] Can create new account (requires Supabase setup)
- [ ] Face ID prompt works (on device)
- [ ] Navigation between tabs works
- [ ] Can create a lead
- [ ] Can add a property
- [ ] Can create a project

## Step 12: Prepare for App Store (Optional)

See the main README.md for complete App Store submission checklist.

## Troubleshooting

### Simulator vs Device Testing

**Simulator Limitations:**
- Biometric authentication won't work (you'll see an error)
- Some Keychain operations may behave differently

**Recommended**: Test on a physical device for biometric features

### Reset Clean Build

If you encounter persistent build issues:

```bash
# Clean build folder
Cmd + Shift + K

# Or from Terminal:
rm -rf ~/Library/Developer/Xcode/DerivedData
```

## Project Structure After Setup

Your Xcode project should look like this:

```
ValeCRM/
├── ValeCRM/
│   ├── CRMApp.swift
│   ├── Config.swift
│   ├── Models/
│   │   ├── Lead.swift
│   │   ├── Property.swift
│   │   └── RehabProject.swift
│   ├── Services/
│   │   ├── NetworkService.swift
│   │   ├── AuthManager.swift
│   │   ├── KeychainHelper.swift
│   │   └── HubSpotService.swift
│   ├── ViewModels/
│   │   ├── LeadViewModel.swift
│   │   ├── PropertyViewModel.swift
│   │   └── RehabProjectViewModel.swift
│   ├── Views/
│   │   ├── ContentView.swift
│   │   ├── LoginView.swift
│   │   ├── LeadsListView.swift
│   │   ├── Portfolio/
│   │   │   └── PortfolioView.swift
│   │   └── Projects/
│   │       └── ProjectsListView.swift
│   ├── Resources/
│   └── Assets.xcassets
├── ValeCRMTests/
└── ValeCRM.xcodeproj
```

## Next Steps

1. **Set up Supabase tables** (see README.md Database Schema section)
2. **Configure HubSpot OAuth** (if using HubSpot sync)
3. **Add app icons and launch screens**
4. **Test on physical device**
5. **Prepare for TestFlight distribution**

## Support

If you encounter issues:
1. Check Xcode build logs (Cmd + 9)
2. Review this guide
3. Contact: dammy@dammyhenry.com
