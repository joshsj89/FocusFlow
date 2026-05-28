# Feature 08: Weekly Wellness Summary Modal

## Description
Modal displaying an aggregated summary of the current week's focus sessions and mood check-ins. Read-only. Accessible from the wellness icon in the homepage AppBar.

---

## Data Model

### WeeklyWellnessSummary
```dart
class WeeklyWellnessSummary {
  final int totalSessions;
  final double totalHours;       // e.g. 4.5
  final double completionRate;   // percentage, e.g. 0.82 = 82%
  final double avgMoodScore;     // 1.0–4.0 mapped from MoodRating enum
  final DateTime weekStart;
  final DateTime weekEnd;
}
```

MoodRating → score mapping:
```dart
// great = 4, alright = 3, notSoWell = 2, bad = 1
```

---

## GoRouter Route
Not a route. Displayed via:
```dart
showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
  builder: (_) => BlocProvider.value(
    value: context.read<WellnessCubit>(),
    child: WellnessSummaryModal(),
  ),
);
```

---

## Flutter Widgets
- `BottomSheet` via `showModalBottomSheet`
- `BlocBuilder<WellnessCubit, WellnessState>` wrapping body
- `Text` for "Weekly Wellness Summary" heading
- `Row` of four `StatChip` widgets (custom widget: label + value)
  - Sessions: int
  - Hours: double (1 decimal place)
  - Completion: percentage string (e.g. "82%")
  - Mood: emoji or score (e.g. "😊" or "3.2")
- `Text` for the date range (e.g. "May 6 – May 12")
- `TextButton` or `ElevatedButton` for "Close"

---

## Interactions
- **Close button / swipe down**: dismisses modal

---

## Bloc / State Management

### WellnessCubit
```dart
// States
abstract class WellnessState {}
class WellnessLoading extends WellnessState {}
class WellnessLoaded extends WellnessState {
  final WeeklyWellnessSummary summary;
}
class WellnessError extends WellnessState { final String message; }

// Methods
void loadWeeklySummary()  // reads sessions from Firestore, computes summary client-side
```

Computation: query `/users/{userId}/sessions` where `completedAt >= weekStart && completedAt <= weekEnd`, then aggregate in the Cubit.

---

## Firebase Structure
```
// Read sessions for the current week:
/users/{userId}/sessions/
  - completedAt: Timestamp
  - mood: String?
  - focusDurationSeconds: int
  - completedSessions: int
```

---

## Error States
- **Load fails**: Show centered `CircularProgressIndicator` replaced by an error message "Couldn't load your summary" with a "Retry" link inside the modal

---

## Empty States
- **No sessions this week**: Show zeroed stats and the message "No sessions this week. Start your first timer to build your summary!"

---

## Dependencies
```yaml
flutter_bloc: ^8.x
cloud_firestore: ^4.x
```

---

## Figma Frame Description
- Modal card slides up, white/light background, rounded top corners
- "Weekly Wellness Summary" heading centered at top
- Date range subtitle below heading (e.g. "May 6 – May 12")
- Row of four stat chips:
  - Each chip: small label above, large number/value below, light colored background
  - Stats: Sessions count, Hours, Completion %, Mood score (with emoji)
- "Close" button full-width at bottom
- Drag handle bar at top
