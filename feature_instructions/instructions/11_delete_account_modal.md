# Feature 11: Delete Account Confirmation Modal

## Description
Confirmation dialog shown before permanently deleting the user's account. More serious than sign out — uses stronger warning language. On confirm, deletes the Firebase Auth account and Firestore user data, then redirects to onboarding/login.

---

## Data Model
None.

---

## GoRouter Route
Not a route. Displayed via:
```dart
showDialog(
  context: context,
  barrierDismissible: false,  // force explicit Yes/No choice
  builder: (_) => BlocProvider.value(
    value: context.read<AccountCubit>(),
    child: DeleteAccountDialog(),
  ),
);
```
Note: `barrierDismissible: false` — user must explicitly tap Yes or No.

---

## Flutter Widgets
- `AlertDialog`
- `Text` for title "Delete Account"
- `Text` for body "Are you sure? This will permanently delete your account and all your data. This cannot be undone."
- `X` `IconButton` top-right (acts as "No")
- `Row` with two buttons:
  - "Yes, Delete" (`ElevatedButton` with red/warning background)
  - "No" (`OutlinedButton`)

---

## Interactions
- **Yes, Delete button**:
  1. Dispatches `AccountCubit.deleteAccount()`
  2. Shows `CircularProgressIndicator` in button while deleting
  3. On `AccountDeleted` state: `context.go('/login')`
- **No button / X button**: `Navigator.of(context).pop()`

---

## Bloc / State Management
Reuses `AccountCubit` from Feature 09.

```dart
// deleteAccount() method on AccountCubit:
Future<void> deleteAccount() async {
  emit(AccountLoaded(profile: state.profile, isSaving: true));
  try {
    // 1. Delete Firestore subcollections: sessions, timers, badges
    // 2. Delete Firestore user document: /users/{uid}
    // 3. Delete Firebase Auth account: user.delete()
    emit(AccountDeleted());
  } catch (e) {
    emit(AccountError(message: 'Could not delete account. Please try again.'));
  }
}
```

Important: Firebase Auth `user.delete()` may require re-authentication if the session is old. Handle `FirebaseAuthException` with code `requires-recent-login` by prompting user to re-enter password before deleting.

---

## Firebase Structure
```
// Delete in order:
1. /users/{userId}/sessions/    (batch delete all documents)
2. /users/{userId}/timers/      (batch delete all documents)
3. /users/{userId}/badges/      (batch delete all documents)
4. /users/{userId}              (delete user document)
5. FirebaseAuth.instance.currentUser!.delete()
```

---

## Error States
- **Delete fails (general)**: `SnackBar` on Account Page "Couldn't delete account. Please try again."
- **Requires re-authentication**: Show a second `AlertDialog` asking user to re-enter their password, then retry deletion.

---

## Empty States
None.

---

## Dependencies
```yaml
flutter_bloc: ^8.x
firebase_auth: ^4.x
cloud_firestore: ^4.x
go_router: ^13.x
```

---

## Figma Frame Description
- Same size and layout as Sign Out dialog (Feature 10)
- White/light background, rounded corners (radius 16)
- `X` close `IconButton` top-right
- "Delete Account" title bold, centered
- Body text: "Are you sure you want to delete your account?" in muted color, centered
- Two buttons: "Yes" (filled red/warning — visually distinct from the Sign Out "Yes") and "No" (outlined)
- `barrierDismissible: false` — tapping outside does nothing
