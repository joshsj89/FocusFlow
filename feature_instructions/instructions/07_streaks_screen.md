# Feature 07: Streaks Screen

## Description
Full screen showing the user's current streak count and a monthly calendar grid of days on which at least one session was completed. Badges and milestone tracking are also displayed here.

---

## Data Model

### StreakData
```dart
class StreakData {
  final int currentStreak;         // consecutive days with at least 1 session
  final int longestStreak;
  final Set<DateTime> activeDays;  // days with completed sessions (date only, no time)
}
```

### Badge
```dart
class Badge {
  final String id;
  final String title;       // e.g. "Early Bird", "Night Owl", "Week Warrior"
  final String description; // e.g. "Complete a session before 8am"
  final String iconAsset;
  final bool earned;
  final DateTime? earnedAt;
}
```

---

## GoRouter Route
```
path: '/streaks'
name: 'streaks'
Widget: StreaksScreen
parentNavigatorKey: rootNavigatorKey  // pushes over the home screen
```

---

## Flutter Widgets
- `Scaffold` with `AppBar` containing `X` close `IconButton` (uses `context.pop()`)
- `BlocBuilder<StreakCubit, StreakState>` wrapping the body
- `Text` for the large streak number
- `Text` for "days" label below the number
- Custom `CalendarGrid` widget built with `GridView.builder` (7 columns, rows = weeks in month)
  - Each day cell: `Container` with `BoxDecoration` circle — filled teal if `activeDays.contains(day)`, hollow otherwise
  - Days outside the current month: rendered with reduced opacity
- `Text` for month/year label above the grid
- `ListView` of `BadgeCard` widgets below the calendar
- `TextButton` for "Clear" (see Interactions)

---

## Interactions
- **X button / back**: `context.pop()`
- **Calendar day tap**: no action (read-only)
- **"Clear" button**: shows `AlertDialog` ("Reset your streak? This cannot be undone." Yes/No). On Yes, dispatches `StreakCleared` to `StreakCubit` — deletes streak data from Firestore

---

## Bloc / State Management

### StreakCubit
```dart
// States
abstract class StreakState {}
class StreakLoading extends StreakState {}
class StreakLoaded extends StreakState {
  final StreakData streakData;
  final List<Badge> badges;
}
class StreakError extends StreakState { final String message; }

// Methods
void loadStreaks()           // fetches from Firestore on init
void clearStreak()          // deletes streak doc, re-emits StreakLoaded with empty data
```

Streak is computed from the `sessions` subcollection — count consecutive days with at least 1 `SessionRecord`. This computation happens in the Cubit, not Firestore.

---

## Firebase Structure
```
// Read all sessions to compute streak:
/users/{userId}/sessions/
  - completedAt: Timestamp  ← used to find active days

// No separate streak document needed — computed client-side from sessions
// Badges earned are stored separately:
/users/{userId}/badges/{badgeId}
  - earned: bool
  - earnedAt: Timestamp?
```

---

## Error States
- **Load fails**: Show centered `Column` with error icon, "Couldn't load streaks", and a "Retry" `TextButton` that calls `StreakCubit.loadStreaks()`

---

## Empty States
- **No sessions yet**: Show streak count as `0`, calendar grid with all hollow dots, and a message "Complete your first session to start your streak!"

---

## Dependencies
```yaml
flutter_bloc: ^8.x
equatable: ^2.x
cloud_firestore: ^4.x
```

---

## Figma Frame Description
- Dark background (`#0F0F1A`)
- "Streaks" title centered at top, `X` close icon top-right
- Large bold number (e.g. `12`) centered, "days" label below in smaller muted text
- Monthly calendar grid below — 7 columns (Sun–Sat), current month
  - Active days: filled teal circle
  - Inactive days: hollow circle outline
  - Today: slightly different highlight (e.g. ring around the circle)
- "Clear" `TextButton` in muted grey at the bottom center
- Badges section below calendar (if space permits on screen): horizontal scroll row of badge cards
