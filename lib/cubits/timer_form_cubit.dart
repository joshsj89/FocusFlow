import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/timer_profile.dart';
import '../services/timer_service.dart';

enum FormStatus { idle, saving, saved, error }

// Preset sets — used to detect whether an existing profile uses custom values
const kFocusDurationPresets = {900, 1500, 2700, 3600};
const kBreakDurationPresets = {300, 600, 900}; // 5, 10, 15 min
const kActivityTypePresets = {
  'studying', 'coding', 'reading', 'exercise', 'research'
};

// ── State ─────────────────────────────────────────────────────────────────────

class TimerFormState extends Equatable {
  final String name;
  final String activityType;   // preset id OR the custom name when activityIsCustom
  final bool activityIsCustom; // true when "Other" chip is selected
  final int focusDuration;          // seconds
  final bool focusDurationIsCustom; // true when not a preset chip
  final int breakDuration;          // seconds
  final bool breakDurationIsCustom; // true when not a preset chip
  final int sessionsPerSit;
  final bool showNameError;
  final FormStatus status;
  final String? errorMessage;

  const TimerFormState({
    required this.name,
    required this.activityType,
    this.activityIsCustom = false,
    required this.focusDuration,
    this.focusDurationIsCustom = false,
    required this.breakDuration,
    this.breakDurationIsCustom = false,
    required this.sessionsPerSit,
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
        status: FormStatus.idle,
      );

  // Computed — always consistent, no manual tracking needed
  bool get isValid {
    if (name.trim().isEmpty) return false;
    if (focusDuration <= 0) return false;
    if (breakDuration <= 0) return false;
    if (activityIsCustom && activityType.trim().isEmpty) return false;
    return true;
  }

  TimerFormState copyWith({
    String? name,
    String? activityType,
    bool? activityIsCustom,
    int? focusDuration,
    bool? focusDurationIsCustom,
    int? breakDuration,
    bool? breakDurationIsCustom,
    int? sessionsPerSit,
    bool? showNameError,
    FormStatus? status,
    String? errorMessage,
  }) {
    return TimerFormState(
      name: name ?? this.name,
      activityType: activityType ?? this.activityType,
      activityIsCustom: activityIsCustom ?? this.activityIsCustom,
      focusDuration: focusDuration ?? this.focusDuration,
      focusDurationIsCustom:
          focusDurationIsCustom ?? this.focusDurationIsCustom,
      breakDuration: breakDuration ?? this.breakDuration,
      breakDurationIsCustom:
          breakDurationIsCustom ?? this.breakDurationIsCustom,
      sessionsPerSit: sessionsPerSit ?? this.sessionsPerSit,
      showNameError: showNameError ?? this.showNameError,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        name, activityType, activityIsCustom, focusDuration,
        focusDurationIsCustom, breakDuration, breakDurationIsCustom,
        sessionsPerSit, showNameError, status, errorMessage,
      ];
}

// ── Cubit ─────────────────────────────────────────────────────────────────────

class TimerFormCubit extends Cubit<TimerFormState> {
  TimerFormCubit() : super(TimerFormState.initial());

  TimerFormCubit.fromExisting(TimerProfile profile)
      : _originalProfile = profile,
        super(TimerFormState(
          name: profile.name,
          // If the stored activity isn't a preset, it's a custom name
          activityType: profile.activityType,
          activityIsCustom:
              !kActivityTypePresets.contains(profile.activityType),
          focusDuration: profile.focusDuration,
          focusDurationIsCustom:
              !kFocusDurationPresets.contains(profile.focusDuration),
          breakDuration: profile.breakDuration,
          breakDurationIsCustom:
              !kBreakDurationPresets.contains(profile.breakDuration),
          sessionsPerSit: profile.sessionsPerSit,
          status: FormStatus.idle,
        ));

  TimerProfile? _originalProfile;

  // ── Name ────────────────────────────────────────────────────────────────────

  void nameChanged(String value) => emit(state.copyWith(
        name: value,
        showNameError: state.name.isNotEmpty && value.trim().isEmpty,
      ));

  // ── Activity type ────────────────────────────────────────────────────────────

  void activityTypeSelected(String type) {
    if (type == 'other') {
      // Switch to custom mode — clear any previous custom name
      emit(state.copyWith(activityIsCustom: true, activityType: ''));
    } else {
      emit(state.copyWith(activityIsCustom: false, activityType: type));
    }
  }

  void customActivityNameChanged(String name) {
    // Only callable when activityIsCustom is true
    emit(state.copyWith(activityType: name));
  }

  // ── Focus duration ───────────────────────────────────────────────────────────

  void focusDurationSelected(int seconds) => emit(state.copyWith(
        focusDuration: seconds,
        focusDurationIsCustom: false,
      ));

  void customFocusDurationSet(int hours, int minutes) {
    final seconds = (hours * 3600) + (minutes * 60);
    emit(state.copyWith(
      focusDuration: seconds,
      focusDurationIsCustom: true,
    ));
  }

  void focusDurationCustomActivated() => emit(state.copyWith(
        focusDurationIsCustom: true,
        // Keep current focusDuration so the h/m fields pre-fill
      ));

  // ── Break duration ───────────────────────────────────────────────────────────

  void breakDurationSelected(int seconds) => emit(state.copyWith(
        breakDuration: seconds,
        breakDurationIsCustom: false,
      ));

  void customBreakDurationSet(int hours, int minutes) {
    final seconds = (hours * 3600) + (minutes * 60);
    emit(state.copyWith(
      breakDuration: seconds,
      breakDurationIsCustom: true,
    ));
  }

  void breakDurationCustomActivated() =>
      emit(state.copyWith(breakDurationIsCustom: true));

  // ── Sessions ─────────────────────────────────────────────────────────────────

  void sessionsIncremented() => emit(state.copyWith(
        sessionsPerSit: (state.sessionsPerSit + 1).clamp(1, 8),
      ));

  void sessionsDecremented() => emit(state.copyWith(
        sessionsPerSit: (state.sessionsPerSit - 1).clamp(1, 8),
      ));

  // ── Submit ───────────────────────────────────────────────────────────────────

  Future<void> submitNew() async {
    if (!state.isValid) return;
    emit(state.copyWith(status: FormStatus.saving));
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception('Not authenticated');
      await TimerService.addTimer(
        uid,
        name: state.name.trim(),
        activityType: state.activityType.trim(),
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
        activityType: state.activityType.trim(),
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
