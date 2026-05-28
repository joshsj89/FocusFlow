# Feature 01: Loading Screen

## Description
Splash screen shown on cold app launch. Displays the FocusFlow logo and wordmark while the app initializes Firebase and checks auth state, then auto-navigates to the correct screen.

---

## Data Model
None. No data is fetched or displayed on this screen.

---

## GoRouter Route
```
path: '/'
name: 'splash'
Widget: SplashScreen
```
Redirect logic lives in GoRouter's `redirect` callback:
- If `FirebaseAuth.instance.currentUser == null` → redirect to `/login`
- If authenticated → redirect to `/home`

---

## Flutter Widgets
- `Scaffold` with `backgroundColor` set to app dark background color (`#0F0F1A`)
- `Center` wrapping a `Column`
- `SvgPicture.asset` or `Image.asset` for the FocusFlow logo (two overlapping circles)
- `Text` for the "FocusFlow" wordmark
- `Future.delayed` inside `initState` with 1800ms delay before GoRouter redirect

---

## Interactions
- No user interaction
- Auto-navigates after 1800ms using `context.go('/home')` or `context.go('/login')`

---

## Bloc / State Management
No Bloc needed on this screen. Use a `StatefulWidget` with `initState`:
```dart
@override
void initState() {
  super.initState();
  Future.delayed(const Duration(milliseconds: 1800), () {
    final user = FirebaseAuth.instance.currentUser;
    if (mounted) {
      context.go(user != null ? '/home' : '/login');
    }
  });
}
```

---

## Firebase Structure
No Firestore reads. Firebase Auth state is checked via `FirebaseAuth.instance.currentUser`.

---

## Error States
None. If Firebase fails to initialize, the app will not reach this screen — handle Firebase init errors in `main.dart`.

---

## Empty States
None.

---

## Dependencies
```yaml
firebase_auth: ^4.x
go_router: ^13.x
flutter_svg: ^2.x   # if logo is SVG
```

---

## Figma Frame Description
- Full-screen dark background (`#0F0F1A`)
- Centered vertically and horizontally
- FocusFlow logo: two overlapping translucent circles in teal/lavender
- "FocusFlow" wordmark in white, below logo, medium weight
- No status bar icons, no navigation chrome
- No buttons, no loading indicator
