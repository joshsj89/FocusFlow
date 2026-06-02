import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String displayName;
  final String email;
  final DateTime memberSince;
  final bool appleHealthSyncEnabled;

  const UserProfile({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.memberSince,
    required this.appleHealthSyncEnabled,
  });

  factory UserProfile.fromMap(
    String uid,
    Map<String, dynamic> map, {
    DateTime? fallbackMemberSince,
  }) {
    final rawMs = map['memberSince'];
    return UserProfile(
      uid: uid,
      displayName: map['displayName'] as String? ?? '',
      email: map['email'] as String? ?? '',
      memberSince: rawMs is Timestamp
          ? rawMs.toDate()
          : (fallbackMemberSince ?? DateTime.now()),
      appleHealthSyncEnabled: map['appleHealthSyncEnabled'] as bool? ?? false,
    );
  }

  // Only writes mutable fields — uid/email/memberSince are set once at registration
  Map<String, dynamic> toMap() => {
        'displayName': displayName,
        'email': email,
        'memberSince': Timestamp.fromDate(memberSince),
        'appleHealthSyncEnabled': appleHealthSyncEnabled,
      };

  UserProfile copyWith({
    String? displayName,
    String? email,
    bool? appleHealthSyncEnabled,
  }) {
    return UserProfile(
      uid: uid,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      memberSince: memberSince,
      appleHealthSyncEnabled:
          appleHealthSyncEnabled ?? this.appleHealthSyncEnabled,
    );
  }
}
