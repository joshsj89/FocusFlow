# FocusFlow — Claude Code Context

## Project Overview
FocusFlow is a wellness-first Pomodoro app built in Flutter. It pairs focused work
intervals with mood check-ins, ambient soundscapes, and a dashboard that helps users
understand how they work best.

---

## Tech Stack
- **Framework**: Flutter / Dart
- **State management**: flutter_bloc (Cubit pattern only — no full Bloc unless specified)
- **Navigation**: GoRouter
- **Backend**: Firebase (Auth, Firestore, optionally Cloud Functions)
- **In-app purchases**: in_app_purchase (for Premium paywall)
- **Other packages**: equatable, url_launcher, flutter_svg, in_app_purchase

---

## Project Structure
```
lib/
  main.dart
  app.dart              # GoRouter setup lives here
  cubits/               # One Cubit per feature
    timer_cubit.dart
    active_timer_cubit.dart
    session_cubit.dart
    streak_cubit.dart
    wellness_cubit.dart
    account_cubit.dart
    paywall_cubit.dart
    timer_form_cubit.dart
  models/               # Dart data classes (no logic)
    timer_profile.dart
    session_record.dart
    streak_data.dart
    badge.dart
    user_profile.dart
    weekly_wellness_summary.dart
    break_suggestion.dart
  screens/              # One file per full screen
    home_screen.dart
    streaks_screen.dart
    account_screen.dart
  widgets/              # Reusable sub-widgets
    modals/             # Bottom sheets and dialogs
      session_complete_modal.dart
      new_timer_modal.dart
      edit_timer_modal.dart
      wellness_summary_modal.dart
      sign_out_dialog.dart
      delete_account_dialog.dart
      premium_paywall_modal.dart
    timer_ring.dart     # CustomPainter circular progress ring
    timer_card.dart     # Timer profile list card
    stat_chip.dart      # Reusable stat display chip
    settings_tile.dart  # Account page list tile
  constants/
    break_suggestions.dart   # Static local list of BreakSuggestion objects
    soundscapes.dart         # Static list of soundscape asset keys
    badge_definitions.dart   # Static list of all possible Badge definitions
  theme/
    app_theme.dart      # ThemeData, colors, text styles
```

---

## Coding Conventions

### Cubit Pattern
- Every Cubit has a single `State` class (or sealed class hierarchy for multiple states)
- States use `equatable` — always extend `Equatable` and override `props`
- Cubit methods are plain Dart methods (not events like full Bloc)
- Example:
```dart
class TimerCubit extends Cubit<TimerState> {
  TimerCubit() : super(TimerInitial());
  void startTimer() { ... }
}
```

### Models
- All models are immutable (`final` fields only)
- All models implement `copyWith`
- All models implement `toMap()` and `fromMap(Map)` for Firestore serialization
- Use `DateTime` for timestamps (convert from Firestore `Timestamp` in `fromMap`)

### Navigation
- Use GoRouter only — no `Navigator.push` directly
- Named routes only — always use `context.goNamed(...)` or `context.pushNamed(...)`
- Modals use `showModalBottomSheet` or `showDialog` — not GoRouter routes

### Widgets
- Prefer `StatelessWidget` — only use `StatefulWidget` for local ephemeral UI state
  (e.g. selected mood dot in Session Complete modal)
- All `BlocProvider` injections happen at the screen level or above, not inside widgets
- Reuse `StatChip`, `SettingsTile`, `TimerCard` — don't inline duplicate UI

---

## Firebase Structure
```
/users/{userId}
  - displayName: String
  - email: String
  - memberSince: Timestamp
  - appleHealthSyncEnabled: bool
  - isPremium: bool
  - premiumSince: Timestamp?
  - premiumPlan: String?   // "monthly" | "yearly"

/users/{userId}/timers/{timerId}
  - name: String
  - activityType: String   // "studying"|"coding"|"reading"|"exercise"|"research"|"other"
  - focusDuration: int     // seconds
  - breakDuration: int     // seconds
  - sessionsPerSit: int
  - soundscapeId: String
  - createdAt: Timestamp

/users/{userId}/sessions/{sessionId}
  - timerProfileId: String
  - focusDurationSeconds: int
  - completedSessions: int
  - mood: String?          // "great"|"alright"|"notSoWell"|"bad"|null
  - completedAt: Timestamp

/users/{userId}/badges/{badgeId}
  - earned: bool
  - earnedAt: Timestamp?
```

---

## GoRouter Routes
```
/                   → SplashScreen
/login              → LoginScreen
/home               → HomeScreen
/streaks            → StreaksScreen
/account            → AccountScreen
/privacy-policy     → PrivacyPolicyScreen
```
Modals are NOT routes — they use `showModalBottomSheet` or `showDialog`.

---

## Design System

### Colors (reference these by name — defined in app_theme.dart)
- Background: `#0F0F1A` (dark navy)
- Primary accent: teal/mint `#4ECDC4`
- Secondary accent: lavender `#A29BFE`
- Surface: `#1A1A2E`
- Error/warning: standard red
- Text primary: white
- Text muted: `#8888A0`

### Typography
- Headings: bold, white
- Body: regular, white
- Muted labels: regular, `#8888A0`

### Component Patterns
- Progress ring: `CustomPainter` — teal stroke draining clockwise
- Cards: `#1A1A2E` background, `BorderRadius.circular(16)`
- Buttons: `ElevatedButton` with teal or lavender fill
- Bottom sheets: `BorderRadius.vertical(top: Radius.circular(24))`
- Dialogs: `BorderRadius.circular(16)`, small/centered

---

## Feature Specs
Full feature specs (data models, Bloc states, Firebase paths, widget types, error/empty
states) live in:
```
docs/specs/
  01_loading_screen.md
  02_homepage_timer_running.md
  03_homepage_break_state.md
  04_session_complete_modal.md
  05_new_timer_modal.md
  06_edit_timer_modal.md
  07_streaks_screen.md
  08_wellness_summary_modal.md
  09_account_page.md
  10_sign_out_modal.md
  11_delete_account_modal.md
  12_premium_paywall_modal.md
```
Always read the relevant spec before generating code for a feature.

---

## Do Nots
- Do NOT use `Navigator.push` — use GoRouter only
- Do NOT use `Provider` — use `flutter_bloc` Cubits only
- Do NOT create stateful widgets for anything beyond local ephemeral UI state
- Do NOT hardcode colors inline — reference `AppTheme` constants
- Do NOT use full Bloc (events/states pattern) unless explicitly asked
- Do NOT write Firestore queries outside of Cubit files