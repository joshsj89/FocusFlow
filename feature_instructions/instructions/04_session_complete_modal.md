# Feature 04: Session Complete Modal

## Description
Modal sheet shown immediately after a focus session ends (`TimerCubit` emits `TimerCompleted`). Displays session stats and prompts an optional mood check-in. Saving the check-in writes a `SessionRecord` to Firestore.

---

## Data Model

### SessionRecord
```dart
class SessionRecord {
  final String id;           // Firestore document ID (auto-generated)
  final String userId;       // Firebase Auth UID
  final String timerProfileId;
  final int focusDurationSeconds;
  final int completedSessions;
  final MoodRating? mood;    // nullable — user may skip
  final DateTime completedAt;
}

enum MoodRating { great, alright, notSoWell, bad }
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
  builder: (_) => SessionCompleteModal(sessionStats: stats),
);
```
Triggered automatically when `BlocListener` detects `TimerCompleted` state.

---

## Flutter Widgets
- `BottomSheet` (via `showModalBottomSheet`)
- `Column` with padding
- `Text` for "Session Complete!" heading
- `Row` for session stats: focus time + sessions completed (two `Chip`-style containers)
- `Text` for "How are you feeling?"
- `Row` of four `GestureDetector`-wrapped mood dot widgets (colored circles with labels)
- `ElevatedButton` for "Save"
- `TextButton` for dismissing without saving (optional — modal is also dismissible by swiping)

---

## Interactions
- **Mood dot tap**: selects that mood, highlights the selected dot (local `setState` or `MoodCubit`)
- **Save button**: dispatches `SessionSaved(sessionRecord)` to `SessionCubit`, closes modal, triggers transition to `TimerOnBreak`
- **Swipe down / tap outside**: dismisses modal without saving, transitions directly to `TimerOnBreak`

---

## Bloc / State Management

### SessionCubit
```dart
// States
abstract class SessionState {}
class SessionIdle extends SessionState {}
class SessionSaving extends SessionState {}
class SessionSaved extends SessionState {}
class SessionSaveError extends SessionState { final String message; }

// Events (methods)
void saveSession(SessionRecord record)  // writes to Firestore
```

Mood selection is handled with local `StatefulWidget` state inside the modal (no Cubit needed for selection — only saving requires Cubit).

```dart
MoodRating? _selectedMood;  // local state in modal widget
```

---

## Firebase Structure
```
/users/{userId}/sessions/{sessionId}
  - timerProfileId: String
  - focusDurationSeconds: int
  - completedSessions: int
  - mood: String?  // "great" | "alright" | "notSoWell" | "bad" | null
  - completedAt: Timestamp
```

---

## Error States
- **Save fails**: Show a `SnackBar` with "Couldn't save session. Try again." Modal stays open.
- Keep the Save button enabled so user can retry.

---

## Empty States
None. Modal always has content (stats come from `TimerCompleted` state).

---

## Dependencies
```yaml
flutter_bloc: ^8.x
cloud_firestore: ^4.x
```

---

## Figma Frame Description
- Modal card slides up from bottom, white/light background, rounded top corners (radius 24)
- "Session Complete!" heading centered at top, bold
- Two stat chips side by side: "Focus Time: [X min]" and "Sessions Completed: [N]"
- "How are you feeling?" prompt in medium-weight text
- Four colored mood dots in a row with labels below each:
  - Green dot — "Great"
  - Yellow dot — "Alright"
  - Orange dot — "Not so well"
  - Red dot — "Bad"
- Selected dot has a visible ring/highlight around it
- "Save" button — full-width, purple/teal, at the bottom
- Drag handle bar at top of modal
