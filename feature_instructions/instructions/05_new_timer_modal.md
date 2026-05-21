# Feature 05: New Timer Modal

## Description
Bottom sheet modal for creating a new `TimerProfile`. User sets a name, activity type, focus duration, break duration, and sessions per sit. On save, the new profile is written to Firestore and added to the timer list on the homepage.

---

## Data Model

### TimerProfile (same as Feature 02)
```dart
class TimerProfile {
  final String id;
  final String userId;
  final String name;
  final String activityType; // "studying" | "coding" | "reading" | "exercise" | "research" | "other"
  final int focusDuration;   // seconds
  final int breakDuration;   // seconds
  final int sessionsPerSit;  // int, 1–8
  final String soundscapeId;
  final DateTime createdAt;
}
```

### TimerFormInput (local form state)
```dart
class TimerFormInput {
  String name;
  String activityType;
  int focusDuration;   // seconds
  int breakDuration;   // seconds
  int sessionsPerSit;
}
```

---

## GoRouter Route
Not a route. Displayed via:
```dart
showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  isDismissible: true,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
  builder: (_) => BlocProvider(
    create: (_) => TimerFormCubit(),
    child: NewTimerModal(),
  ),
);
```

---

## Flutter Widgets
- `BottomSheet` via `showModalBottomSheet`
- `DraggableScrollableSheet` if content is long enough to scroll
- `TextField` for timer name input
- `Wrap` or `Row` of `ChoiceChip` widgets for activity type selection
- `Wrap` of `ChoiceChip` widgets for focus duration selection: 15 min, 25 min, 45 min, 1 hr (maps to 900, 1500, 2700, 3600 seconds)
- `Wrap` of `ChoiceChip` widgets for break duration: 5 min, 10 min, 15 min (300, 600, 900 seconds)
- `Row` with `IconButton` `−` and `+` and a `Text` counter for sessions per sit
- `ElevatedButton` for "Confirm"
- `IconButton` with close (`X`) icon in top-right

---

## Interactions
- **Name field**: updates `TimerFormCubit` state on `onChanged`
- **Activity chip tap**: dispatches `ActivityTypeSelected(type)` — only one selectable at a time
- **Duration chip tap**: dispatches `FocusDurationSelected(seconds)` — only one selectable at a time
- **Break chip tap**: dispatches `BreakDurationSelected(seconds)`
- **Sessions `−`/`+`**: dispatches `SessionsPerSitDecremented` / `SessionsPerSitIncremented` (min 1, max 8)
- **Confirm button**: dispatches `TimerFormSubmitted` → `TimerListCubit.addTimer(profile)` → closes modal
- **X button / swipe down**: dismisses modal without saving

---

## Bloc / State Management

### TimerFormCubit
```dart
// State
class TimerFormState {
  final String name;
  final String activityType;
  final int focusDuration;
  final int breakDuration;
  final int sessionsPerSit;
  final bool isValid;         // true when name is non-empty
  final FormStatus status;    // idle | saving | saved | error
}

enum FormStatus { idle, saving, saved, error }

// Methods
void nameChanged(String value)
void activityTypeSelected(String type)
void focusDurationSelected(int seconds)
void breakDurationSelected(int seconds)
void sessionsIncremented()
void sessionsDecremented()
void submitForm()  // writes to Firestore, emits saved or error
```

### TimerListCubit (shared with Feature 02)
```dart
void addTimer(TimerProfile profile)
```

---

## Firebase Structure
```
/users/{userId}/timers/{auto-id}
  - name: String
  - activityType: String
  - focusDuration: int
  - breakDuration: int
  - sessionsPerSit: int
  - soundscapeId: String (default: "ambient_rain")
  - createdAt: Timestamp
```

---

## Error States
- **Name field empty**: "Confirm" button is disabled. Show inline hint "Give your timer a name" if user taps Confirm with empty name.
- **Firestore write fails**: Show `SnackBar` "Couldn't save timer. Try again." Keep modal open.

---

## Empty States
- **Activity type**: Default to "studying" pre-selected on open
- **Focus duration**: Default to 25 min pre-selected
- **Break duration**: Default to 5 min pre-selected
- **Sessions per sit**: Default to 4

---

## Dependencies
```yaml
flutter_bloc: ^8.x
equatable: ^2.x
cloud_firestore: ^4.x
```

---

## Figma Frame Description
- Modal slides up from bottom, white/light background, rounded top corners (radius 24)
- "New Timer" title left-aligned, `X` close `IconButton` top-right
- "Timer Name" `TextField` with placeholder text
- "Activity Type" section: horizontal scrollable row of `ChoiceChip`s (Studying, Coding, Reading, Exercise, Research)
- "Focus Duration" section: row of four `ChoiceChip`s (15m, 25m, 45m, 1hr) — one selected at a time, selected chip uses teal/purple fill
- "Break Duration" section: row of three `ChoiceChip`s (5m, 10m, 15m)
- "Sessions per sit" row: `−` icon, number display, `+` icon
- "Confirm" full-width `ElevatedButton` at bottom in purple
- Drag handle bar at top of modal
