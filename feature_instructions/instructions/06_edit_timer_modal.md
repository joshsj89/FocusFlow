# Feature 06: Edit Timer Modal

## Description
Same form as New Timer (Feature 05) but pre-populated with an existing `TimerProfile`'s values. Opened by long-pressing or tapping an edit icon on a timer card. On save, updates the existing Firestore document.

---

## Data Model
Same as Feature 05 (`TimerProfile`, `TimerFormInput`). The modal receives the existing `TimerProfile` as a constructor parameter.

---

## GoRouter Route
Not a route. Displayed via:
```dart
showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
  builder: (_) => BlocProvider(
    create: (_) => TimerFormCubit.fromExisting(existingProfile),
    child: EditTimerModal(profile: existingProfile),
  ),
);
```

---

## Flutter Widgets
Identical to Feature 05. The only differences:
- Title reads "Edit Timer" instead of "New Timer"
- `TimerFormCubit` is initialized with `TimerFormCubit.fromExisting(profile)` so all fields are pre-filled
- Confirm button calls `updateTimer` instead of `addTimer`

---

## Interactions
Same as Feature 05 with one addition:
- **Delete timer**: Add a `TextButton` with "Delete Timer" in red at the bottom of the modal, below Confirm. Tapping shows a simple `AlertDialog` ("Delete this timer?" Yes/No). Confirming dispatches `TimerDeleted(timerId)` to `TimerListCubit`.

---

## Bloc / State Management

### TimerFormCubit
Add a named constructor:
```dart
TimerFormCubit.fromExisting(TimerProfile profile) : super(
  TimerFormState(
    name: profile.name,
    activityType: profile.activityType,
    focusDuration: profile.focusDuration,
    breakDuration: profile.breakDuration,
    sessionsPerSit: profile.sessionsPerSit,
    isValid: true,
    status: FormStatus.idle,
  )
);

void submitEdit(String timerId)  // updates Firestore doc instead of creating
```

### TimerListCubit (shared)
```dart
void updateTimer(TimerProfile updated)
void deleteTimer(String timerId)
```

---

## Firebase Structure
```
// Update:
/users/{userId}/timers/{timerId}   ← document update (merge: false, full overwrite)

// Delete:
/users/{userId}/timers/{timerId}   ← document delete
```

---

## Error States
- Same as Feature 05
- **Delete fails**: Show `SnackBar` "Couldn't delete timer. Try again."
- If the timer being edited is the currently active timer, on delete: reset `ActiveTimerCubit` to null, pause `TimerCubit`

---

## Empty States
Not applicable — modal is only opened with an existing profile.

---

## Dependencies
```yaml
flutter_bloc: ^8.x
equatable: ^2.x
cloud_firestore: ^4.x
```

---

## Figma Frame Description
- Identical layout to New Timer modal
- Title reads "Edit Timer"
- All fields pre-populated with existing timer values
- Selected chips match the existing profile values
- "Delete Timer" `TextButton` in red below the "Confirm" button
- Drag handle bar at top of modal
