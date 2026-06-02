import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import '../models/user_profile.dart';
import '../services/notification_service.dart';

// ── States ────────────────────────────────────────────────────────────────────

abstract class AccountState extends Equatable {
  const AccountState();
  @override
  List<Object?> get props => [];
}

class AccountLoading extends AccountState {
  const AccountLoading();
}

class AccountLoaded extends AccountState {
  final UserProfile profile;
  final bool isSaving;

  const AccountLoaded({required this.profile, this.isSaving = false});

  AccountLoaded copyWith({UserProfile? profile, bool? isSaving}) {
    return AccountLoaded(
      profile: profile ?? this.profile,
      isSaving: isSaving ?? this.isSaving,
    );
  }

  @override
  List<Object?> get props => [profile, isSaving];
}

class AccountSignedOut extends AccountState {
  const AccountSignedOut();
}

class AccountDeleted extends AccountState {
  const AccountDeleted();
}

class AccountError extends AccountState {
  final String message;
  const AccountError(this.message);
  @override
  List<Object?> get props => [message];
}

class AccountDataExported extends AccountState {
  final bool copiedToClipboard; // true on web, false on mobile (share sheet used)
  const AccountDataExported({required this.copiedToClipboard});
  @override
  List<Object?> get props => [copiedToClipboard];
}


class AccountCubit extends Cubit<AccountState> {
  AccountCubit() : super(const AccountLoading());

  static CollectionReference<Map<String, dynamic>> get _users =>
      FirebaseFirestore.instance.collection('users');

  Future<void> loadProfile() async {
    emit(const AccountLoading());
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        emit(const AccountSignedOut());
        return;
      }
      final doc = await _users.doc(user.uid).get();
      final data = doc.data();
      if (data == null) {
        // First login create the user document
        final newProfile = UserProfile(
          uid: user.uid,
          displayName: user.displayName ?? '',
          email: user.email ?? '',
          memberSince: DateTime.now(),
          appleHealthSyncEnabled: false,
        );

        await _users
            .doc(user.uid)
            .set(newProfile.toMap(), SetOptions(merge: true));
        emit(AccountLoaded(profile: newProfile));
      } else {
        emit(AccountLoaded(profile: UserProfile.fromMap(user.uid, data)));
      }
    } catch (e, stack) {
      debugPrint('AccountCubit.loadProfile error: $e\n$stack');
      emit(const AccountError("Couldn't load profile"));
    }
  }

  Future<void> updateDisplayName(String name) async {
    final current = _loaded;
    if (current == null) return;
    emit(current.copyWith(isSaving: true));
    try {
      await Future.wait([
        FirebaseAuth.instance.currentUser!.updateDisplayName(name),
        _users.doc(current.profile.uid).update({'displayName': name}),
      ]);
      emit(current.copyWith(
        profile: current.profile.copyWith(displayName: name),
        isSaving: false,
      ));
    } catch (_) {
      emit(current.copyWith(isSaving: false));
      rethrow;
    }
  }

  Future<void> toggleAppleHealthSync(bool enabled) async {
    final current = _loaded;
    if (current == null) return;
    emit(current.copyWith(
        profile: current.profile.copyWith(appleHealthSyncEnabled: enabled)));
    try {
      await _users
          .doc(current.profile.uid)
          .update({'appleHealthSyncEnabled': enabled});
    } catch (_) {
      // Revert on failure
      emit(current.copyWith(
          profile: current.profile
              .copyWith(appleHealthSyncEnabled: !enabled)));
      rethrow;
    }
  }

  Future<void> requestDataExport() async {
    final current = _loaded;
    if (current == null) return;
    emit(current.copyWith(isSaving: true));
    try {
      final uid = current.profile.uid;
      final results = await Future.wait([
        _users.doc(uid).collection('timers').get(),
        _users.doc(uid).collection('sessions').get(),
      ]);

      final export = {
        'profile': {
          'displayName': current.profile.displayName,
          'email': current.profile.email,
          'memberSince': current.profile.memberSince.toIso8601String(),
          'appleHealthSyncEnabled': current.profile.appleHealthSyncEnabled,
        },
        'timers': results[0].docs.map((d) => _sanitize({...d.data(), 'id': d.id})).toList(),
        'sessions': results[1].docs.map((d) => _sanitize({...d.data(), 'id': d.id})).toList(),
      };

      final json = const JsonEncoder.withIndent('  ').convert(export);

      if (kIsWeb) {
        await Clipboard.setData(ClipboardData(text: json));
        emit(const AccountDataExported(copiedToClipboard: true));
      } else {
        await Share.share(json, subject: 'FocusFlow Data Export');
        emit(const AccountDataExported(copiedToClipboard: false));
      }
      // Reload profile so the screen returns to AccountLoaded
      await loadProfile();
    } catch (_) {
      emit(current.copyWith(isSaving: false));
    }
  }

  // Converts Firestore Timestamps to ISO strings so they survive JSON encoding
  static dynamic _sanitize(dynamic value) {
    if (value is Timestamp) return value.toDate().toIso8601String();
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), _sanitize(v)));
    }
    if (value is List) return value.map(_sanitize).toList();
    return value;
  }

  Future<void> signOut() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await NotificationService.clearTokenForUser(uid);
    }
    await FirebaseAuth.instance.signOut();
    emit(const AccountSignedOut());
  }

  Future<void> deleteAccount() async {
    final current = _loaded;
    if (current == null) return;
    emit(current.copyWith(isSaving: true));
    try {
      final uid = current.profile.uid;
      // Stop this device from receiving notifications for the deleted account
      await NotificationService.clearTokenForUser(uid);
      // Delete subcollections then the user document
      await _deleteSubcollection(uid, 'timers');
      await _deleteSubcollection(uid, 'sessions');
      await _deleteSubcollection(uid, 'badges');
      await _users.doc(uid).delete();
      await FirebaseAuth.instance.currentUser!.delete();
      emit(const AccountDeleted());
    } catch (_) {
      emit(const AccountError("Couldn't delete account. Try again."));
    }
  }

  Future<void> _deleteSubcollection(String uid, String name) async {
    const batchSize = 100;
    var query = _users.doc(uid).collection(name).limit(batchSize);
    while (true) {
      final snap = await query.get();
      if (snap.docs.isEmpty) break;
      final batch = FirebaseFirestore.instance.batch();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      if (snap.docs.length < batchSize) break;
    }
  }

  AccountLoaded? get _loaded =>
      state is AccountLoaded ? state as AccountLoaded : null;
}
