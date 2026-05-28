# Feature 09: Account Page

## Description
Full-screen settings page showing user profile info, data export options, support links, and account actions (sign out, delete account). Navigated to by tapping the avatar on the homepage.

---

## Data Model

### UserProfile
```dart
class UserProfile {
  final String uid;
  final String displayName;
  final String email;
  final DateTime memberSince;
  final bool appleHealthSyncEnabled;
}
```

---

## GoRouter Route
```
path: '/account'
name: 'account'
Widget: AccountScreen
parentNavigatorKey: rootNavigatorKey
```

---

## Flutter Widgets
- `Scaffold` with back arrow `AppBar` (`context.pop()` on back tap)
- `BlocBuilder<AccountCubit, AccountState>` wrapping body
- `ListView` as the main layout (scrollable)
- **Profile header section**: `CircleAvatar`, `Text` for display name, `Text` for "Member since [date]"
- `_SettingsSection` custom widget (reusable): accepts a `title` String and a list of `_SettingsTile` widgets
- `_SettingsTile` custom widget: leading `Icon`, `Text` label, optional trailing `Switch` or `Icon`
- Sections:
  - **Profile**: Display Name (navigates to edit), Email (read-only), Password (navigates to change password)
  - **Data**: Export my data (`TextButton`), Apple Health Sync (`Switch`)
  - **Support**: Send Feedback (opens email), Privacy Policy (opens `WebViewScreen`)
  - **Account Actions**: Sign out (opens Sign Out modal), Delete account (opens Delete Account modal — red text)

---

## Interactions
- **Display Name tile**: opens an `AlertDialog` with a `TextField` to edit display name, "Save" dispatches `DisplayNameUpdated(name)` to `AccountCubit`
- **Export my data tile**: dispatches `DataExportRequested` — shows a `SnackBar` "We'll email your data export within 24 hours"
- **Apple Health Sync toggle**: dispatches `AppleHealthSyncToggled(bool)` to `AccountCubit`, writes to Firestore
- **Send Feedback tile**: launches `mailto:support@focusflow.app` via `url_launcher`
- **Privacy Policy tile**: `context.push('/privacy-policy')`
- **Sign out tile**: shows Sign Out confirmation modal (Feature 10)
- **Delete account tile**: shows Delete Account confirmation modal (Feature 11)

---

## Bloc / State Management

### AccountCubit
```dart
// States
abstract class AccountState {}
class AccountLoading extends AccountState {}
class AccountLoaded extends AccountState {
  final UserProfile profile;
  final bool isSaving;
}
class AccountSignedOut extends AccountState {}
class AccountDeleted extends AccountState {}
class AccountError extends AccountState { final String message; }

// Methods
void loadProfile()
void updateDisplayName(String name)
void toggleAppleHealthSync(bool enabled)
void requestDataExport()
void signOut()          // Firebase Auth signOut, emits AccountSignedOut
void deleteAccount()    // Firebase Auth delete + Firestore delete, emits AccountDeleted
```

---

## Firebase Structure
```
/users/{userId}
  - displayName: String
  - email: String
  - memberSince: Timestamp
  - appleHealthSyncEnabled: bool

// On delete account: delete /users/{userId} and all subcollections (handled server-side via Cloud Function or client-side batch delete)
```

---

## Error States
- **Load fails**: Show `CircularProgressIndicator` then fallback message "Couldn't load profile"
- **Display name update fails**: `SnackBar` "Couldn't update name. Try again."
- **Apple Health Sync toggle fails**: Revert toggle to previous value, show `SnackBar`

---

## Empty States
Not applicable — account data always exists for an authenticated user.

---

## Dependencies
```yaml
flutter_bloc: ^8.x
cloud_firestore: ^4.x
firebase_auth: ^4.x
url_launcher: ^6.x
```

---

## Figma Frame Description
- Dark background (`#0F0F1A`)
- AppBar with back arrow and "Account" title
- Profile header: `CircleAvatar` with initial letter, display name bold, "Member since [date]" in muted text below
- Four grouped sections, each with a teal/purple label header:
  - **Profile**: Display Name, Email, Password — each a row with icon and right chevron
  - **Data**: Export my data (icon + label), Apple Health Sync (icon + label + `Switch` toggle on right)
  - **Support**: Send Feedback, Privacy Policy — each with icon and chevron
  - **Account Actions**: Sign out (normal color), Delete account (red/warning color)
- Light dividers between tiles within a section
- Teal section header labels in small uppercase
