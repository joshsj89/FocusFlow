# Feature 02: Homepage — Timer Running

## Description
The main screen of the app. Shows the active countdown timer, playback controls, ambient sound selector, and a scrollable list of the user's saved timer profiles. This is the screen users land on after login.

---

## Data Model

### TimerProfile
```dart
class TimerProfile {
  final String id;           // Firestore document ID
  final String userId;       // Firebase Auth UID
  final String name;         // e.g. "Coding", "Study Session"
  final String activityType; // e.g. "coding", "studying", "reading", "exercise"
  final int focusDuration;   // in seconds, e.g. 1500 (25 min)
  final int breakDuration;   // in seconds, e.g. 300 (5 min)
  final int sessionsPerSit;  // number of focus intervals before a long break
  final String soundscapeId; // references a soundscape asset key
  final DateTime createdAt;
}
```

### TimerSession (in-memory only, not persisted until complete)
```dart
class TimerSession {
  final String timerProfileId;
  int remainingSeconds;
  int completedSessions;
  TimerPhase phase; // enum: focus, shortBreak, longBreak
}

enum TimerPhase { focus, shortBreak, longBreak }
```

---

## GoRouter Route
```
path: '/home'
name: 'home'
Widget: HomeScreen
```

---

## Flutter Widgets
- `Scaffold` with custom `AppBar` (greeting text left, avatar `IconButton` right)
- `BlocBuilder<TimerCubit, TimerState>` wrapping the entire body
- `Stack` for layering the progress ring over the time display
- `CustomPaint` for the circular progress ring (use `CustomPainter`)
- `Row` for playback controls (rewind, play/pause, skip)
- `Container` styled as a pill for the ambient sound selector
- `ListView.builder` for the list of timer profile cards
- `FloatingActionButton` (teal `+` button pinned to bottom center)
- Two `IconButton`s in AppBar top-right (streaks icon, wellness icon)

---

## Interactions
- **Play button**: dispatches `TimerStarted` to `TimerCubit`
- **Pause button**: dispatches `TimerPaused`
- **Rewind button**: dispatches `TimerReset` (resets to full focus duration)
- **Timer card tap**: dispatches `ActiveTimerChanged(timerProfileId)` to `ActiveTimerCubit`
- **Ambient sound pill tap**: opens `SoundscapePickerBottomSheet` via `showModalBottomSheet`
- **`+` FAB tap**: opens `NewTimerModal` via `showModalBottomSheet`
- **Avatar tap**: `context.push('/account')`
- **Streaks icon tap**: `context.push('/streaks')`
- **Wellness icon tap**: shows `WellnessSummaryModal` via `showModalBottomSheet`

---

## Bloc / State Management

### TimerCubit
```dart
// States
abstract class TimerState {}
class TimerInitial extends TimerState {}
class TimerRunning extends TimerState {
  final int remainingSeconds;
  final int totalSeconds;
  final int completedSessions;
  final TimerPhase phase;
}
class TimerPaused extends TimerState {
  final int remainingSeconds;
  final int totalSeconds;
  final TimerPhase phase;
}
class TimerCompleted extends TimerState {
  final int completedSessions;
}
class TimerOnBreak extends TimerState {
  final int remainingSeconds;
  final int totalSeconds;
  final String nextTimerName;
}

// Events (methods on Cubit)
void startTimer()
void pauseTimer()
void resetTimer()
void skipBreak()
void tick()  // called by a dart:async Timer every 1 second
```

Use `dart:async` `Timer.periodic` inside the Cubit to call `tick()` every second.

### ActiveTimerCubit
```dart
class ActiveTimerState {
  final TimerProfile? activeProfile;
  final List<TimerProfile> allProfiles;
}

void selectTimer(String timerProfileId)
void loadProfiles()  // fetches from Firestore
```

---

## Firebase Structure
```
/users/{userId}/timers/{timerId}
  - name: String
  - activityType: String
  - focusDuration: int
  - breakDuration: int
  - sessionsPerSit: int
  - soundscapeId: String
  - createdAt: Timestamp
```

---

## Error States
- **Firestore load fails**: Show a `SnackBar` with "Couldn't load timers. Pull to refresh."
- **No active timer selected**: Disable play button, show placeholder text "Select a timer to start"

---

## Empty States
- **No timers created yet**: Replace `ListView` with a centered `Column` containing an icon, "No timers yet", and a "Create your first timer" `TextButton` that opens `NewTimerModal`

---

## Dependencies
```yaml
flutter_bloc: ^8.x
equatable: ^2.x
firebase_auth: ^4.x
cloud_firestore: ^4.x
go_router: ^13.x
```

---

## Figma Frame Description
- Dark background (`#0F0F1A`)
- Teal/mint AppBar with greeting "Good Morning, [Name]" on the left, avatar circle icon on the right, two small icons (streak flame, wellness leaf) beside avatar
- Large circular progress ring centered — teal stroke draining clockwise as time counts down, countdown time (e.g. `25:00`) displayed in white inside the ring
- Five dot indicators below the ring showing session progress (filled = completed, hollow = remaining)
- Three playback control icons in a row: rewind (◀◀), play/pause (▶/⏸), skip (▶▶)
- Pill-shaped ambient sound selector below controls — music note icon + "Ambient Rain" label, teal background
- Scrollable list of timer profile cards below — each card shows a `+` icon, timer name, rounded rectangle, light background
- Teal `+` FAB fixed at bottom center
