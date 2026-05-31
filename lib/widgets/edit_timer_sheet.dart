import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/timer_form_cubit.dart';
import '../models/timer_profile.dart';
import 'add_timer_sheet.dart';

class EditTimerSheet extends StatelessWidget {
  final TimerProfile timer;

  const EditTimerSheet({super.key, required this.timer});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TimerFormCubit.fromExisting(timer),
      child: const _EditFormBody(),
    );
  }
}

class _EditFormBody extends StatelessWidget {
  const _EditFormBody();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TimerFormBody(title: 'Edit Timer', isEdit: true),
        const FormDeleteButton(),
        const SizedBox(height: 12),
      ],
    );
  }
}
