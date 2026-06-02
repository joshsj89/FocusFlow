import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/timer_profile.dart';
import '../services/timer_service.dart';

enum FormStatus { idle, saving, saved, error }

// ── State ─────────────────────────────────────────────────────────────────────

class TimerFormState extends Equatable {
  final String name;
  final String activityType;
  final int focusDuration;  // seconds
  final int breakDuration;  // seconds
  final int sessionsPerSit;
  final bool isValid;
  final bool showNameError; // true once name has been touched and left empty
  final FormStatus status;
  final String? errorMessage;

  const TimerFormState({
    required this.name,
    required this.activityType,
    required this.focusDuration,
    required this.breakDuration,
    required this.sessionsPerSit,
    required this.isValid,
    this.showNameError = false,
    required this.status,
    this.errorMessage,
  });

  factory TimerFormState.initial() => const TimerFormState(
        name: '',
        activityType: 'studying',
        focusDuration: 1500, // 25 min
        breakDuration: 300,  // 5 min
        sessionsPerSit: 4,
        isValid: false,
        status: FormStatus.idle,
      );

  TimerFormState copyWith({
    String? name,
    String? activityType,
    int? focusDuration,
    int? breakDuration,
    int? sessionsPerSit,
    bool? isValid,
    bool? showNameError,
    FormStatus? status,
    String? errorMessage,
  }) {
    return TimerFormState(
      name: name ?? this.name,
      activityType: activityType ?? this.activityType,
      focusDuration: focusDuration ?? this.focusDuration,
      breakDuration: breakDuration ?? this.breakDuration,
      sessionsPerSit: sessionsPerSit ?? this.sessionsPerSit,
      isValid: isValid ?? this.isValid,
      showNameError: showNameError ?? this.showNameError,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        name, activityType, focusDuration, breakDuration,
        sessionsPerSit, isValid, showNameError, status, errorMessage,
      ];
}

// ── Cubit ─────────────────────────────────────────────────────────────────────

class TimerFormCubit extends Cubit<TimerFormState> {
  TimerFormCubit() : super(TimerFormState.initial());

  TimerFormCubit.fromExisting(TimerProfile profile)
      : _originalProfile = profile,
        super(TimerFormState(
          name: profile.name,
          activityType: profile.activityType,
          focusDuration: profile.focusDuration,
          breakDuration: profile.breakDuration,
          sessionsPerSit: profile.sessionsPerSit,
          isValid: true,
          status: FormStatus.idle,
        ));

  TimerProfile? _originalProfile;

  void nameChanged(String value) => emit(state.copyWith(
        name: value,
        isValid: value.trim().isNotEmpty,
        // Show error only after the user has interacted and left the field empty
        showNameError: state.name.isNotEmpty && value.trim().isEmpty,
      ));

  void activityTypeSelected(String type) =>
      emit(state.copyWith(activityType: type));

  void focusDurationSelected(int seconds) =>
      emit(state.copyWith(focusDuration: seconds));

  void breakDurationSelected(int seconds) =>
      emit(state.copyWith(breakDuration: seconds));

  void sessionsIncremented() => emit(state.copyWith(
        sessionsPerSit: (state.sessionsPerSit + 1).clamp(1, 8),
      ));

  void sessionsDecremented() => emit(state.copyWith(
        sessionsPerSit: (state.sessionsPerSit - 1).clamp(1, 8),
      ));

  Future<void> submitNew() async {
    if (!state.isValid) return;
    emit(state.copyWith(status: FormStatus.saving));
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception('Not authenticated');
      await TimerService.addTimer(
        uid,
        name: state.name.trim(),
        activityType: state.activityType,
        focusDuration: state.focusDuration,
        breakDuration: state.breakDuration,
        sessionsPerSit: state.sessionsPerSit,
      );
      emit(state.copyWith(status: FormStatus.saved));
    } catch (_) {
      emit(state.copyWith(
        status: FormStatus.error,
        errorMessage: "Couldn't save timer. Try again.",
      ));
    }
  }

  Future<void> submitEdit() async {
    if (!state.isValid || _originalProfile == null) return;
    emit(state.copyWith(status: FormStatus.saving));
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception('Not authenticated');
      final updated = _originalProfile!.copyWith(
        name: state.name.trim(),
        activityType: state.activityType,
        focusDuration: state.focusDuration,
        breakDuration: state.breakDuration,
        sessionsPerSit: state.sessionsPerSit,
      );
      await TimerService.updateTimer(uid, updated);
      emit(state.copyWith(status: FormStatus.saved));
    } catch (_) {
      emit(state.copyWith(
        status: FormStatus.error,
        errorMessage: "Couldn't save timer. Try again.",
      ));
    }
  }

  Future<void> deleteTimer() async {
    if (_originalProfile == null) return;
    emit(state.copyWith(status: FormStatus.saving));
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception('Not authenticated');
      await TimerService.deleteTimer(uid, _originalProfile!.id);
      emit(state.copyWith(status: FormStatus.saved));
    } catch (_) {
      emit(state.copyWith(
        status: FormStatus.error,
        errorMessage: "Couldn't delete timer. Try again.",
      ));
    }
  }
}
