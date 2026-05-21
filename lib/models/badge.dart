import 'package:cloud_firestore/cloud_firestore.dart';

class Badge {
  final String id;
  final String title;
  final String description;
  final String iconAsset;
  final bool earned;
  final DateTime? earnedAt;

  const Badge({
    required this.id,
    required this.title,
    required this.description,
    required this.iconAsset,
    required this.earned,
    this.earnedAt,
  });

  // Assembles a Badge from a static definition merged with Firestore doc data.
  // [definition] is the static entry from badge_definitions.dart.
  // [docData] is the Firestore document (may be null if not yet written).
  factory Badge.fromDefinition(
    Map<String, dynamic> definition,
    Map<String, dynamic>? docData,
  ) {
    final rawEarnedAt = docData?['earnedAt'];
    return Badge(
      id: definition['id'] as String,
      title: definition['title'] as String,
      description: definition['description'] as String,
      iconAsset: definition['iconAsset'] as String,
      earned: docData?['earned'] as bool? ?? false,
      earnedAt: rawEarnedAt is Timestamp ? rawEarnedAt.toDate() : null,
    );
  }

  // Writes only the mutable Firestore fields — static fields live in badge_definitions.dart
  Map<String, dynamic> toMap() => {
        'earned': earned,
        'earnedAt': earnedAt != null ? Timestamp.fromDate(earnedAt!) : null,
      };

  Badge copyWith({bool? earned, DateTime? earnedAt}) {
    return Badge(
      id: id,
      title: title,
      description: description,
      iconAsset: iconAsset,
      earned: earned ?? this.earned,
      earnedAt: earnedAt ?? this.earnedAt,
    );
  }
}
