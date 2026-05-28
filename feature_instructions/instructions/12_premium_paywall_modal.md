# Feature 12: Premium Paywall Modal

## Description
Modal promoting FocusFlow Premium. Shown contextually when a user attempts to access a Premium-only feature (e.g. full soundscape library, advanced analytics). Never shown on app launch. Includes a monthly/yearly plan toggle and a 7-day free trial CTA.

---

## Data Model

### PremiumPlan
```dart
enum PremiumPlan { monthly, yearly }

class PlanOption {
  final PremiumPlan plan;
  final double price;        // e.g. 1.99 or 19.99
  final String label;        // "Monthly" or "Yearly"
  final String priceLabel;   // "$1.99" or "$19.99"
  final bool isBestValue;    // true for yearly
}
```

### PurchaseStatus
```dart
enum PurchaseStatus { idle, loading, success, error }
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
    create: (_) => PaywallCubit(),
    child: PremiumPaywallModal(),
  ),
);
```

---

## Flutter Widgets
- `BottomSheet` via `showModalBottomSheet`
- `BlocBuilder<PaywallCubit, PaywallState>` wrapping the body
- `Container` pill/badge with "FocusFlow Premium" label (purple background)
- `Text` for heading "Build a focus practice that lasts"
- `Row` of two `ChoiceChip` or `ToggleButton` widgets for Monthly / Yearly plan selection
  - Yearly chip shows "Best Value" badge
- `Column` of feature bullet points (icon + text for each):
  - Full soundscape library
  - AI-suggested break activities
  - Health & Calendar sync
  - Wellness Routines
- `ElevatedButton` for "Start 7-day Free Trial" (full-width, purple)
- `TextButton` for "Maybe Later" (centered, grey)
- `IconButton` with `X` close icon top-right

---

## Interactions
- **Monthly chip**: dispatches `PlanSelected(PremiumPlan.monthly)` to `PaywallCubit`
- **Yearly chip**: dispatches `PlanSelected(PremiumPlan.yearly)` to `PaywallCubit`
- **Start Trial button**: dispatches `PurchaseInitiated(selectedPlan)` — integrates with `in_app_purchase` package
- **Maybe Later / X button**: `Navigator.of(context).pop()`
- On `PurchaseSuccess`: dismiss modal, update user's premium status in Firestore, show `SnackBar` "Welcome to Premium! 🎉"

---

## Bloc / State Management

### PaywallCubit
```dart
// State
class PaywallState {
  final PremiumPlan selectedPlan;
  final PurchaseStatus status;
  final String? errorMessage;
}

// Methods
void selectPlan(PremiumPlan plan)
void initiatePurchase()     // calls in_app_purchase, emits loading → success/error
void restorePurchases()     // for "Restore purchases" link (optional)
```

On `PurchaseSuccess`, also write to Firestore:
```dart
/users/{userId}
  - isPremium: true
  - premiumSince: Timestamp
  - premiumPlan: "monthly" | "yearly"
```

---

## Firebase Structure
```
/users/{userId}
  - isPremium: bool
  - premiumSince: Timestamp?
  - premiumPlan: String?  // "monthly" | "yearly"
```

---

## Error States
- **Purchase fails**: Show `SnackBar` "Purchase failed. Please try again." Keep modal open.
- **Purchase loading**: Replace "Start Trial" button content with `CircularProgressIndicator`. Disable both plan chips and "Maybe Later" while loading.

---

## Empty States
None.

---

## Dependencies
```yaml
flutter_bloc: ^8.x
equatable: ^2.x
in_app_purchase: ^3.x
cloud_firestore: ^4.x
```

---

## Figma Frame Description
- Modal slides up from bottom, white background, rounded top corners (radius 24)
- Drag handle bar at top
- `X` close `IconButton` top-right
- Purple pill badge "FocusFlow Premium" centered near top
- Heading "Build a focus practice that lasts" bold, centered
- Two toggle chips side by side: "Monthly $1.99" and "Yearly $19.99"
  - Yearly chip has a small "Best Value" badge in green
  - Selected chip has purple fill
- Four feature bullet rows (small checkmark icon + text):
  - Full soundscape library
  - AI-Suggested Break
  - Health & Calendar Sync
  - Wellness Routines
- "Start 7-day Free Trial" full-width purple `ElevatedButton`
- "Maybe Later" plain `TextButton` centered below in grey
