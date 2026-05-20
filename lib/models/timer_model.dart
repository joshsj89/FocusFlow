import 'package:cloud_firestore/cloud_firestore.dart' show DocumentSnapshot;

class TimerModel {
  final String id;
  final String name;
  final int durationMins;
  final int sessions;
  final DateTime createdAt;

  const TimerModel({
    required this.id,
    required this.name,
    required this.durationMins,
    required this.sessions,
    required this.createdAt,
  });

  factory TimerModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return TimerModel(
      id: doc.id,
      name: data['name'] as String,
      durationMins: data['durationMins'] as int,
      sessions: data['sessions'] as int,
      createdAt: DateTime.parse(data['createdAt'] as String).toLocal(),
    );
  }

  TimerModel copyWith({String? name, int? durationMins, int? sessions}) {
    return TimerModel(
      id: id,
      name: name ?? this.name,
      durationMins: durationMins ?? this.durationMins,
      sessions: sessions ?? this.sessions,
      createdAt: createdAt,
    );
  }
}
