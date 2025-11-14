# ValeCRM - iOS Real Estate CRM Application

**ValeCRM** is a comprehensive iOS application designed for real estate investors and property managers. Built with **SwiftUI** and following **MVVM architecture**, it provides powerful tools for managing leads, properties, and rehab projects with full backend integration.

## 🏗️ Architecture

- **Framework**: SwiftUI
- **Architecture**: MVVM (Model-View-ViewModel)
- **Reactive Programming**: Combine
- **Authentication**: Keychain + Biometric (Face ID/Touch ID)
- **Backend**: Supabase
- **CRM Integration**: HubSpot API
- **Domain**: keystonevale.org

## 🚀 Features

### Lead Management
- Create, update, and track real estate leads
- Priority-based lead organization (Hot, Warm, Cold)
- Status tracking through the sales pipeline
- Source tracking (Web Form, Phone, SMS, etc.)
- Automatic HubSpot CRM synchronization
- Property information capture

### Portfolio Management
- Comprehensive property tracking
- Real-time portfolio valuation
- ROI calculations and cash flow analysis
- Property status management (Owned, For Sale, Rental, etc.)
- Monthly income and expense tracking
- Property type categorization

### Rehab Project Tracking
- Project budget management
- Real-time budget utilization tracking
- Project status tracking (Planning, Active, On Hold, etc.)
- Timeline management
- Cost analysis and remaining budget calculations

### Authentication & Security
- Email/password authentication via Supabase
- Biometric authentication (Face ID/Touch ID)
- Secure token storage in iOS Keychain
- Automatic token refresh
- Session management

## 📱 Screenshots

*(Add screenshots here when available)*

## 🛠️ Technical Stack

### Core Technologies
- **Swift 5.9+**
- **SwiftUI**
- **Combine Framework**
- **iOS 16.0+**

### Services & APIs
- **Supabase**: Backend database and authentication
- **HubSpot API**: CRM synchronization
- **Zoho Mail**: Email integration
- **Keychain Services**: Secure credential storage

### Architecture Components

```
crm-ios-app/
├── CRMApp.swift           # App entry point
├── Config.swift            # Configuration management
├── Models/                 # Data models
│   ├── Lead.swift
│   ├── Property.swift
│   └── RehabProject.swift
├── Services/              # Business logic & networking
│   ├── NetworkService.swift
│   ├── AuthManager.swift
│   ├── KeychainHelper.swift
│   └── HubSpotService.swift
├── ViewModels/            # MVVM view models
│   ├── LeadViewModel.swift
│   ├── PropertyViewModel.swift
│   └── RehabProjectViewModel.swift
└── Views/                 # SwiftUI views
    ├── ContentView.swift
    ├── LoginView.swift
    ├── LeadsListView.swift
    ├── Portfolio/
    │   └── PortfolioView.swift
    └── Projects/
        └── ProjectsListView.swift
```

## 📦 Installation

### Prerequisites
- macOS 13.0 or later
- Xcode 15.0 or later
- iOS 16.0+ device or simulator
- Apple Developer account (for device testing)

### Setup Steps

1. **Clone the repository**
```bash
git clone https://github.com/rudeboydamn/crm-ios-app.git
cd crm-ios-app
```

2. **Open in Xcode**
```bash
open ValeCRM.xcodeproj
```
*(Note: You'll need to create an Xcode project and add these source files)*

3. **Configure Backend**

The app is pre-configured with Supabase credentials in `Config.swift`. For production:
- Never commit real API keys to version control
- Use Xcode build configurations or `.xcconfig` files
- Store sensitive data in environment variables

4. **Build and Run**
- Select your target device/simulator
- Press `Cmd + R` to build and run

## 🔐 Security Configuration

### API Keys (Already Configured)
The following credentials are configured in `Config.swift`:

- **Supabase URL**: `https://wjdbivxcrloqyblmqqui.supabase.co`
- **Supabase Anon Key**: Configured
- **Supabase Service Key**: Configured
- **HubSpot Credentials**: Configured
- **Zoho Email**: dammy@dammyhenry.com

### Security Best Practices

⚠️ **Important**: For production release:
1. Move API keys to `.xcconfig` files (not committed to git)
2. Use environment-specific configurations
3. Enable App Transport Security (ATS)
4. Review and update Info.plist permissions

## 📊 Database Schema

### Supabase Tables Required

```sql
-- Leads table
CREATE TABLE leads (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    hubspot_id TEXT,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    email TEXT NOT NULL,
    phone TEXT,
    source TEXT NOT NULL,
    status TEXT NOT NULL,
    priority TEXT NOT NULL,
    tags TEXT[],
    property_address TEXT NOT NULL,
    property_city TEXT,
    property_state TEXT,
    property_zip TEXT,
    asking_price NUMERIC,
    offer_amount NUMERIC,
    arv NUMERIC
);

-- Properties table
CREATE TABLE properties (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    address TEXT NOT NULL,
    city TEXT NOT NULL,
    state TEXT NOT NULL,
    zip TEXT NOT NULL,
    property_type TEXT NOT NULL,
    status TEXT NOT NULL,
    purchase_price NUMERIC,
    current_value NUMERIC,
    monthly_rent NUMERIC,
    monthly_expenses NUMERIC,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Rehab Projects table
CREATE TABLE rehab_projects (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    property_id UUID REFERENCES properties(id),
    address TEXT NOT NULL,
    status TEXT NOT NULL,
    start_date TIMESTAMPTZ,
    completion_date TIMESTAMPTZ,
    total_budget NUMERIC NOT NULL,
    spent_amount NUMERIC DEFAULT 0
);
```

## 🚢 App Store Preparation

### Before Submission

1. **Create Xcode Project**
   - Create new iOS App project
   - Bundle ID: `com.keystonevale.ValeCRM`
   - Team: Select your Apple Developer team
   - Deployment target: iOS 16.0+

2. **Add Assets**
   - App Icon (1024x1024px)
   - Launch Screen
   - App Store screenshots

3. **Configure Info.plist**
```xml
<key>NSFaceIDUsageDescription</key>
<string>We use Face ID to securely authenticate you to ValeCRM</string>
<key>NSCameraUsageDescription</key>
<string>Camera access for property photos</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Photo library access for property images</string>
```

4. **Testing Checklist**
   - [ ] Test on physical device
   - [ ] Verify biometric authentication
   - [ ] Test all CRUD operations
   - [ ] Verify HubSpot sync
   - [ ] Test offline scenarios
   - [ ] Memory leak testing
   - [ ] Network error handling

5. **App Store Connect Setup**
   - Create app record
   - Configure privacy settings
   - Add app description and keywords
   - Upload screenshots
   - Submit for review

## 🧪 Testing

### Unit Tests
```bash
# Run tests in Xcode
Cmd + U
```

### Manual Testing Scenarios
1. Sign up with new account
2. Sign in with Face ID
3. Create a new lead
4. Verify HubSpot sync
5. Add property to portfolio
6. Create rehab project
7. View portfolio metrics

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is proprietary software for KeystoneVale.

## 👥 Team

- **Developer**: Dammy Henry
- **Email**: dammy@dammyhenry.com
- **Domain**: keystonevale.org

## 🔗 Links

- **GitHub**: https://github.com/rudeboydamn/crm-ios-app
- **Supabase Dashboard**: https://supabase.com/dashboard
- **HubSpot Account**: KeystoneCRM

## 📞 Support

For support, email dammy@dammyhenry.com or visit keystonevale.org

---

**Version**: 1.0.0  
**Build**: 1  
**Last Updated**: November 2025
