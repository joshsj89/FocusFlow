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

  factory TimerModel.fromMap(Map<String, dynamic> map) {
    return TimerModel(
      id: map['id'] as String,
      name: map['name'] as String,
      durationMins: map['durationMins'] as int,
      sessions: map['sessions'] as int,
      createdAt: DateTime.parse(map['createdAt'] as String).toLocal(),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'durationMins': durationMins,
        'sessions': sessions,
        'createdAt': createdAt.toUtc().toIso8601String(),
      };

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
