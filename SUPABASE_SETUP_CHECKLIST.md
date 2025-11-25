# Supabase Integration Setup Checklist

## 🎯 Quick Start Guide

Follow these steps to complete the Supabase integration in Xcode:

## Step 1: Add Supabase Swift Package

1. Open `ValeCRM.xcodeproj` in Xcode
2. Navigate to **File** → **Add Package Dependencies...**
3. In the search bar, enter: `https://github.com/supabase/supabase-swift`
4. Select version **2.0.0** or later
5. Click **Add Package**
6. Select the following products to add:
   - ✅ Supabase
   - ✅ Auth
   - ✅ PostgREST
   - ✅ Realtime
   - ✅ Storage
   - ✅ Functions
7. Click **Add Package**

## Step 2: Verify Configuration

### Check xcconfig files

✅ **ConfigSecrets.xcconfig** should contain:
```
SUPABASE_URL = https://wjdbivxcrloqyblmqqui.supabase.co
SUPABASE_ANON_KEY = eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

✅ **Info.plist** should have:
```xml
<key>SupabaseURL</key>
<string>$(SUPABASE_URL)</string>
<key>SupabaseAnonKey</key>
<string>$(SUPABASE_ANON_KEY)</string>
```

## Step 3: Build Project

1. Clean Build Folder: **Cmd + Shift + K**
2. Build Project: **Cmd + B**
3. Resolve any import errors

## Step 4: Verify File Structure

Ensure these new files exist:

### Core Services
- [x] `ValeCRM/Services/SupabaseManager.swift`
- [x] `ValeCRM/Services/SupabaseError.swift`
- [x] `ValeCRM/Services/RealtimeManager.swift`

### Database Services
- [x] `ValeCRM/Services/Database/DatabaseService.swift`
- [x] `ValeCRM/Services/Database/LeadDatabaseService.swift`
- [x] `ValeCRM/Services/Database/PropertyDatabaseService.swift`
- [x] `ValeCRM/Services/Database/ProjectDatabaseService.swift`
- [x] `ValeCRM/Services/Database/ClientDatabaseService.swift`
- [x] `ValeCRM/Services/Database/TaskDatabaseService.swift`
- [x] `ValeCRM/Services/Database/CommunicationDatabaseService.swift`
- [x] `ValeCRM/Services/Database/DocumentDatabaseService.swift`

### Updated Files
- [x] `ValeCRM/Services/AuthManager.swift` - Now uses Supabase
- [x] `ValeCRM/ViewModels/LeadViewModel.swift` - Now uses Supabase + Realtime
- [x] `ValeCRM/Views/LoginView.swift` - Updated for email authentication
- [x] `ValeCRM/Views/SignUpView.swift` - NEW signup view

### Configuration
- [x] `ValeCRM/Config.swift` - Added Supabase config
- [x] `ValeCRM/ConfigSecrets.xcconfig` - Added SUPABASE_URL and SUPABASE_ANON_KEY
- [x] `ValeCRM/Info.plist` - Added Supabase keys

## Step 5: Update Remaining ViewModels

Apply the same pattern from `LeadViewModel` to other ViewModels:

### ViewModels to Update:
- [ ] `PropertyViewModel.swift`
- [ ] `RehabProjectViewModel.swift`
- [ ] `ClientViewModel.swift`
- [ ] `TaskViewModel.swift`
- [ ] `CommunicationViewModel.swift`
- [ ] `DashboardViewModel.swift`
- [ ] `PortfolioViewModel.swift`

### Migration Pattern:
```swift
// OLD - NetworkService
private let networkService: NetworkService

networkService.fetchData()
    .sink(...)
    .store(in: &cancellables)

// NEW - Supabase
private let databaseService = [Entity]DatabaseService.shared
private let realtimeManager = RealtimeManager.shared

Task {
    let data = try await databaseService.fetchAll()
    await MainActor.run {
        self.data = data
    }
}
```

## Step 6: Update App Initialization

Update `CRMApp.swift` to remove NetworkService dependency:

```swift
@main
struct ValeCRMApp: App {
    @StateObject private var authManager = AuthManager()
    
    var body: some Scene {
        WindowGroup {
            if authManager.isAuthenticated {
                ContentView()
                    .environmentObject(authManager)
            } else {
                LoginView()
                    .environmentObject(authManager)
            }
        }
    }
}
```

## Step 7: Test Authentication

1. **Sign Up**:
   - Launch app
   - Tap "Sign Up"
   - Enter email, password, name, username
   - Create account

2. **Sign In**:
   - Enter credentials
   - Verify successful login
   - Check user profile loads

3. **Sign Out**:
   - Test sign out
   - Verify session cleared

4. **Session Persistence**:
   - Sign in
   - Close app
   - Reopen app
   - Should remain signed in

## Step 8: Test Database Operations

1. **Create**:
   - Add new lead
   - Verify appears in list
   - Check Supabase dashboard

2. **Read**:
   - Fetch all leads
   - Search leads
   - Filter by status

3. **Update**:
   - Edit lead
   - Save changes
   - Verify updated

4. **Delete**:
   - Delete lead
   - Verify removed
   - Check Supabase dashboard

## Step 9: Test Real-time Sync

1. Open app on simulator
2. Open Supabase dashboard
3. **Insert** record in dashboard → should appear in app
4. **Update** record in dashboard → should update in app
5. **Delete** record in dashboard → should remove from app

OR

1. Open app on two simulators
2. Create lead in simulator 1 → should appear in simulator 2
3. Update lead in simulator 2 → should update in simulator 1

## Step 10: Verify Supabase Dashboard

### Check Database Tables
Go to Supabase Dashboard → Table Editor

Required tables:
- [x] `users`
- [x] `leads`
- [x] `properties`
- [x] `projects`
- [x] `clients`
- [x] `tasks`
- [x] `communications`
- [x] `documents`

### Enable Realtime

For each table:
1. Go to Database → Replication
2. Enable replication for tables:
   - `leads`
   - `properties`
   - `projects`
   - `clients`
   - `tasks`
   - `communications`
   - `documents`

### Row Level Security (RLS)

Ensure RLS policies are enabled:
1. Go to Authentication → Policies
2. For each table, create policies:
   ```sql
   -- Allow authenticated users to read all
   CREATE POLICY "Users can view all records"
   ON [table_name]
   FOR SELECT
   TO authenticated
   USING (true);

   -- Allow authenticated users to insert
   CREATE POLICY "Users can insert records"
   ON [table_name]
   FOR INSERT
   TO authenticated
   WITH CHECK (true);

   -- Allow authenticated users to update
   CREATE POLICY "Users can update records"
   ON [table_name]
   FOR UPDATE
   TO authenticated
   USING (true)
   WITH CHECK (true);

   -- Allow authenticated users to delete
   CREATE POLICY "Users can delete records"
   ON [table_name]
   FOR DELETE
   TO authenticated
   USING (true);
   ```

## 🎉 Completion Checklist

- [ ] Supabase Swift package added
- [ ] Project builds without errors
- [ ] All new service files present
- [ ] Configuration verified
- [ ] AuthManager using Supabase
- [ ] LeadViewModel updated
- [ ] Other ViewModels updated
- [ ] Login/SignUp views working
- [ ] Authentication tested
- [ ] Database CRUD tested
- [ ] Real-time sync tested
- [ ] Supabase tables configured
- [ ] RLS policies enabled
- [ ] Realtime replication enabled

## 🐛 Troubleshooting

### Build Errors

**Error**: `No such module 'Supabase'`
- **Fix**: Add Supabase package in Xcode → File → Add Package Dependencies

**Error**: `Missing configuration value for key: SupabaseURL`
- **Fix**: Verify ConfigSecrets.xcconfig has SUPABASE_URL defined

### Runtime Errors

**Error**: Authentication fails
- **Fix**: Check SUPABASE_ANON_KEY is correct
- **Fix**: Verify Supabase project is active

**Error**: Real-time not updating
- **Fix**: Enable replication in Supabase Dashboard
- **Fix**: Check RLS policies allow read access

**Error**: Database queries fail
- **Fix**: Verify RLS policies
- **Fix**: Check user is authenticated
- **Fix**: Verify table names match exactly

## 📚 Resources

- 📖 [Integration Guide](./SUPABASE_INTEGRATION_GUIDE.md)
- 🌐 [Supabase Swift Docs](https://supabase.com/docs/reference/swift)
- 🔐 [Authentication Guide](https://supabase.com/docs/guides/auth)
- ⚡ [Realtime Guide](https://supabase.com/docs/guides/realtime)

## ✅ Status

**Phase 1-2**: ✅ Setup & Authentication Complete
**Phase 3-4**: ✅ Database Operations Complete
**Phase 5**: ✅ Real-time Sync Complete
**Phase 6**: ✅ UI Integration Complete (LeadViewModel, LoginView, SignUpView)
**Phase 7-8**: ✅ Error Handling & Polish Complete

**Next**: Update remaining ViewModels and test end-to-end

---

**Ready to proceed?** Start with Step 1 above! 🚀
