import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/timer_profile.dart';
import '../services/timer_service.dart';

class ActiveTimerState extends Equatable {
  final TimerProfile? activeProfile;
  final List<TimerProfile> allProfiles;
  final bool isLoading;
  final String? errorMessage;

  const ActiveTimerState({
    this.activeProfile,
    this.allProfiles = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  ActiveTimerState copyWith({
    TimerProfile? activeProfile,
    bool clearActiveProfile = false,
    List<TimerProfile>? allProfiles,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ActiveTimerState(
      activeProfile:
          clearActiveProfile ? null : activeProfile ?? this.activeProfile,
      allProfiles: allProfiles ?? this.allProfiles,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props =>
      [activeProfile, allProfiles, isLoading, errorMessage];
}

class ActiveTimerCubit extends Cubit<ActiveTimerState> {
  ActiveTimerCubit() : super(const ActiveTimerState());

  StreamSubscription<List<TimerProfile>>? _sub;

  void loadProfiles() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    emit(state.copyWith(isLoading: true, clearError: true));

    _sub = TimerService.watchTimers(uid).listen(
      (profiles) {
        // Keep the current selection if it still exists, otherwise default to first
        final currentId = state.activeProfile?.id;
        final active = profiles.isEmpty
            ? null
            : profiles.firstWhere(
                (p) => p.id == currentId,
                orElse: () => profiles.first,
              );
        emit(state.copyWith(
          allProfiles: profiles,
          activeProfile: active,
          clearActiveProfile: profiles.isEmpty,
          isLoading: false,
          clearError: true,
        ));
      },
      onError: (_) => emit(state.copyWith(
        isLoading: false,
        errorMessage: "Couldn't load timers. Pull to refresh.",
      )),
    );
  }

  void selectTimer(String timerProfileId) {
    if (state.allProfiles.isEmpty) return;
    final profile = state.allProfiles.firstWhere(
      (p) => p.id == timerProfileId,
      orElse: () => state.allProfiles.first,
    );
    emit(state.copyWith(activeProfile: profile));
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
