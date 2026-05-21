# Feature 10: Sign Out Confirmation Modal

## Description
Small confirmation dialog shown before signing the user out. Triggered from the Account Page. On confirm, signs out via Firebase Auth and redirects to the login screen.

---

## Data Model
None.

---

## GoRouter Route
Not a route. Displayed via:
```dart
showDialog(
  context: context,
  builder: (_) => BlocProvider.value(
    value: context.read<AccountCubit>(),
    child: SignOutDialog(),
  ),
);
```

---

## Flutter Widgets
- `AlertDialog` (not `BottomSheet` — this is a small confirmation, use `Dialog`)
- `Text` for title "Sign Out"
- `Text` for body "Are you sure you want to sign out?"
- `X` `IconButton` in top-right corner of dialog
- `Row` with two buttons: "Yes" (`ElevatedButton`) and "No" (`OutlinedButton`)

---

## Interactions
- **Yes button**: dispatches `AccountCubit.signOut()` → on `AccountSignedOut` state, `context.go('/login')`
- **No button**: `Navigator.of(context).pop()` (dismisses dialog)
- **X button**: same as No

---

## Bloc / State Management
Reuses `AccountCubit` from Feature 09. No new Cubit needed.

```dart
// BlocListener on AccountCubit in AccountScreen listens for AccountSignedOut:
BlocListener<AccountCubit, AccountState>(
  listener: (context, state) {
    if (state is AccountSignedOut) {
      context.go('/login');
    }
  },
)
```

A `CircularProgressIndicator` replaces the "Yes" button content while `isSaving` is true in `AccountLoaded` state.

---

## Firebase Structure
```
FirebaseAuth.instance.signOut()  // no Firestore writes needed
```

---

## Error States
- **Sign out fails** (rare): Show `SnackBar` on the Account Page with "Sign out failed. Try again." Dialog stays open.

---

## Empty States
None.

---

## Dependencies
```yaml
flutter_bloc: ^8.x
firebase_auth: ^4.x
go_router: ^13.x
```

---

## Figma Frame Description
- Small centered `Dialog` (not full-width)
- White/light background, rounded corners (radius 16)
- `X` close `IconButton` pinned to top-right
- "Sign Out" title bold, centered
- "Are you sure you want to sign out?" body text, centered, muted color
- Two buttons side by side: "Yes" (filled purple) and "No" (outlined or plain)
- Dialog has a drop shadow or dim overlay behind it
