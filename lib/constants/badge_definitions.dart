// Static badge definitions — id must match the Firestore document ID in /users/{uid}/badges/
// Each entry is merged with Firestore earned/earnedAt data in StreakCubit.
const List<Map<String, dynamic>> kBadgeDefinitions = [
  {
    'id': 'first_session',
    'title': 'First Step',
    'description': 'Complete your very first focus session',
    'iconAsset': 'assets/badges/first_step.png',
  },
  {
    'id': 'week_warrior',
    'title': 'Week Warrior',
    'description': 'Maintain a 7-day streak',
    'iconAsset': 'assets/badges/week_warrior.png',
  },
  {
    'id': 'early_bird',
    'title': 'Early Bird',
    'description': 'Complete a session before 8 AM',
    'iconAsset': 'assets/badges/early_bird.png',
  },
  {
    'id': 'night_owl',
    'title': 'Night Owl',
    'description': 'Complete a session after 10 PM',
    'iconAsset': 'assets/badges/night_owl.png',
  },
];
