import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

const _kDialogShape = RoundedRectangleBorder(
  borderRadius: BorderRadius.all(Radius.circular(20)),
  side: BorderSide(color: AppColors.teal, width: 2),
);

InputDecoration _field(String hint) => InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF7F7FB),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.teal, width: 1.5),
      ),
    );

TextStyle _cancelStyle() =>
    GoogleFonts.openSans(color: AppColors.subtitleText);

TextStyle _actionStyle() =>
    GoogleFonts.openSans(color: AppColors.teal, fontWeight: FontWeight.w600);

class EditDisplayNameDialog extends StatefulWidget {
  final User? user;
  const EditDisplayNameDialog({super.key, required this.user});

  @override
  State<EditDisplayNameDialog> createState() => _EditDisplayNameDialogState();
}

class _EditDisplayNameDialogState extends State<EditDisplayNameDialog> {
  late final TextEditingController _ctrl =
      TextEditingController(text: widget.user?.displayName ?? '');

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: _kDialogShape,
      title: Text('Display Name',
          style: GoogleFonts.openSans(fontWeight: FontWeight.w600)),
      content: TextField(
        controller: _ctrl,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        decoration: _field('Your name'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: _cancelStyle()),
        ),
        TextButton(
          onPressed: () async {
            final name = _ctrl.text.trim();
            final nav = Navigator.of(context);
            if (name.isNotEmpty) await widget.user?.updateDisplayName(name);
            if (mounted) nav.pop();
          },
          child: Text('Save', style: _actionStyle()),
        ),
      ],
    );
  }
}

class EditEmailDialog extends StatefulWidget {
  final User? user;
  const EditEmailDialog({super.key, required this.user});

  @override
  State<EditEmailDialog> createState() => _EditEmailDialogState();
}

class _EditEmailDialogState extends State<EditEmailDialog> {
  late final TextEditingController _ctrl =
      TextEditingController(text: widget.user?.email ?? '');
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: _kDialogShape,
      title: Text('Update Email',
          style: GoogleFonts.openSans(fontWeight: FontWeight.w600)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'A verification link will be sent to the new address before it takes effect. Be sure to check spam.',
            style: GoogleFonts.openSans(
                fontSize: 12, color: AppColors.subtitleText),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _ctrl,
            autofocus: true,
            keyboardType: TextInputType.emailAddress,
            decoration: _field('New email address'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!,
                style: const TextStyle(color: Colors.red, fontSize: 12)),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: _cancelStyle()),
        ),
        TextButton(
          onPressed: _saving
              ? null
              : () async {
                  final email = _ctrl.text.trim();
                  if (email.isEmpty) return;
                  setState(() {
                    _saving = true;
                    _error = null;
                  });
                  final nav = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);
                  try {
                    await widget.user?.verifyBeforeUpdateEmail(email);
                    if (mounted) {
                      nav.pop();
                      messenger.showSnackBar(
                          SnackBar(content: Text('Verification email sent to $email')));
                    }
                  } on FirebaseAuthException catch (e) {
                    setState(() {
                      _saving = false;
                      _error = e.message ?? 'Something went wrong.';
                    });
                  }
                },
          child: Text('Send verification', style: _actionStyle()),
        ),
      ],
    );
  }
}


class ChangePasswordDialog extends StatefulWidget {
  final User? user;
  const ChangePasswordDialog({super.key, required this.user});

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: _kDialogShape,
      title: Text('Change Password',
          style: GoogleFonts.openSans(fontWeight: FontWeight.w600)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
              controller: _currentCtrl,
              obscureText: true,
              decoration: _field('Current password')),
          const SizedBox(height: 10),
          TextField(
              controller: _newCtrl,
              obscureText: true,
              decoration: _field('New password')),
          const SizedBox(height: 10),
          TextField(
              controller: _confirmCtrl,
              obscureText: true,
              decoration: _field('Confirm new password')),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!,
                style: const TextStyle(color: Colors.red, fontSize: 12)),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: _cancelStyle()),
        ),
        TextButton(
          onPressed: _saving
              ? null
              : () async {
                  final current = _currentCtrl.text;
                  final newPass = _newCtrl.text;
                  final confirm = _confirmCtrl.text;
                  if (newPass != confirm) {
                    setState(() => _error = 'Passwords do not match.');
                    return;
                  }
                  if (newPass.length < 6) {
                    setState(() =>
                        _error = 'Password must be at least 6 characters.');
                    return;
                  }
                  setState(() {
                    _saving = true;
                    _error = null;
                  });
                  final nav = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);
                  try {
                    final cred = EmailAuthProvider.credential(
                        email: widget.user!.email!, password: current);
                    await widget.user!.reauthenticateWithCredential(cred);
                    await widget.user!.updatePassword(newPass);
                    if (mounted) {
                      nav.pop();
                      messenger.showSnackBar(
                          const SnackBar(content: Text('Password updated.')));
                    }
                  } on FirebaseAuthException {
                    setState(() {
                      _saving = false;
                      _error = 'Current password is incorrect.';
                    });
                  }
                },
          child: Text('Update', style: _actionStyle()),
        ),
      ],
    );
  }
}


class SendFeedbackDialog extends StatefulWidget {
  final User? user;
  const SendFeedbackDialog({super.key, required this.user});

  @override
  State<SendFeedbackDialog> createState() => _SendFeedbackDialogState();
}

class _SendFeedbackDialogState extends State<SendFeedbackDialog> {
  final _ctrl = TextEditingController();
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: _kDialogShape,
      title: Text('Send Feedback',
          style: GoogleFonts.openSans(fontWeight: FontWeight.w600)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _ctrl,
            maxLines: 4,
            autofocus: true,
            decoration: _field('Tell us what you think…'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!,
                style: const TextStyle(color: Colors.red, fontSize: 12)),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: _cancelStyle()),
        ),
        TextButton(
          onPressed: _saving
              ? null
              : () async {
                  final text = _ctrl.text.trim();
                  if (text.isEmpty) return;
                  setState(() {
                    _saving = true;
                    _error = null;
                  });
                  final nav = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);
                  try {
                    await FirebaseFirestore.instance
                        .collection('feedback')
                        .add({
                      'uid': widget.user?.uid,
                      'email': widget.user?.email,
                      'feedback': text,
                      'submitted_at': DateTime.now().toUtc().toIso8601String(),
                    });
                    if (mounted) {
                      nav.pop();
                      messenger.showSnackBar(const SnackBar(
                          content: Text('Thanks for your feedback!')));
                    }
                  } catch (_) {
                    setState(() {
                      _saving = false;
                      _error = 'Failed to send. Please try again.';
                    });
                  }
                },
          child: Text('Submit', style: _actionStyle()),
        ),
      ],
    );
  }
}

class PrivacyPolicyDialog extends StatelessWidget {
  const PrivacyPolicyDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: _kDialogShape,
      title: Text('Privacy Policy',
          style: GoogleFonts.openSans(fontWeight: FontWeight.w600)),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Text(
            'FocusFlow collects only the data necessary to provide the service: '
            'your email address for authentication, display name, and the timer '
            'configurations you create.\n\n'
            'Your data is stored securely in Google Firebase and is never sold '
            'or shared with third parties.\n\n'
            'You may export or delete your data at any time from this screen. '
            'Deleting your account permanently removes all associated data.\n\n'
            'We use no third-party analytics or advertising SDKs.\n\n'
            'For questions, contact us via the feedback form.',
            style: GoogleFonts.openSans(
                fontSize: 13, color: AppColors.subtitleText, height: 1.6),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Close', style: _actionStyle()),
        ),
      ],
    );
  }
}
