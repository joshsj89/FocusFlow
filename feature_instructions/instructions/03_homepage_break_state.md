# Feature 03: Homepage — Break State

## Description
Homepage variant rendered when `TimerCubit` emits `TimerOnBreak`. Replaces the standard timer UI with a break countdown, a wellness suggestion card, and an upcoming session card. All other homepage chrome remains the same.

---

## Data Model

### BreakSuggestion
```dart
class BreakSuggestion {
  final String id;
  final String title;       // e.g. "Stretch Your Shoulders"
  final String description; // e.g. "Roll your shoulders back 10 times"
  final String category;    // e.g. "movement", "breathing", "hydration"
}
```
Break suggestions are a static local list (no Firestore read needed). Define them as constants in a `break_suggestions.dart` file.

---

## GoRouter Route
Same as Feature 02 (`/home`). This is a UI state variant, not a separate route. The `BlocBuilder` on `HomeScreen` renders this layout when state is `TimerOnBreak`.

---

## Flutter Widgets
- `BlocBuilder<TimerCubit, TimerState>` — renders `BreakView` when state is `TimerOnBreak`
- `Container` with teal background for the "Take A Break" banner replacing the AppBar greeting
- `CustomPaint` for the break countdown ring (same `CustomPainter` as Feature 02, muted/lighter stroke color)
- `Card` for the break suggestion (icon + title + description)
- `Card` for the upcoming session (clock icon + timer name + duration)
- `TextButton` for "Skip Break" at the bottom center

---

## Interactions
- **Skip Break button**: dispatches `TimerBreakSkipped` to `TimerCubit`, transitions back to `TimerRunning`
- **Upcoming session card**: read-only, no tap action
- **Break suggestion card**: read-only, no tap action
- All AppBar interactions remain the same as Feature 02

---

## Bloc / State Management
Reuses `TimerCubit` from Feature 02. No additional Cubit needed.

```dart
// Break is triggered when TimerCubit emits TimerCompleted, 
// then auto-transitions to TimerOnBreak after 300ms
class TimerOnBreak extends TimerState {
  final int remainingSeconds;  // break countdown
  final int totalSeconds;      // total break duration
  final String nextTimerName;  // name of the next focus session
  final int nextTimerDuration; // in seconds
}

// New event on TimerCubit:
void skipBreak()  // transitions state back to TimerRunning for the next session
```

Break suggestion is selected randomly from the local `BreakSuggestion` list when `TimerOnBreak` state is first emitted.

---

## Firebase Structure
No Firestore reads for this screen. Break suggestions are local constants.

---

## Error States
None specific to this screen. Inherits error states from Feature 02.

---

## Empty States
None. A break suggestion is always shown (selected from local constants).

---

## Dependencies
```yaml
flutter_bloc: ^8.x
equatable: ^2.x
```

---

## Figma Frame Description
- Dark background (`#0F0F1A`)
- Top banner replaced with a solid teal bar containing "Take A Break" centered in white text
- Circular countdown ring in center — muted/lighter teal stroke, break time (e.g. `4:00`) inside in white
- No playback controls row
- Two cards stacked below the ring:
  1. Break suggestion card — white background, rounded corners, suggestion title (e.g. "Stretch Your Shoulders"), short description below
  2. Upcoming session card — darker background, clock icon on left, "Coding 25 Minutes" text
- "Skip Break" as a plain `TextButton` in light grey, centered at the bottom
