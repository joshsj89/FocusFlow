class BreakSuggestion {
  final String id;
  final String title;
  final String description;
  final String category; // "movement" | "breathing" | "hydration" | "mindfulness"

  const BreakSuggestion({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
  });
}
