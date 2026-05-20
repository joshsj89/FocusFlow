import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:focusflow/theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/animated_press.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.userChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data;
        final displayName = user?.displayName ?? 'No name set';
        final email = user?.email ?? '';
        final createdAt = user?.metadata.creationTime;
        final memberSince = createdAt != null
            ? _formatMonth(createdAt)
            : '';

        return Scaffold(
          backgroundColor: Colors.white,
          body: Column(
            children: [
              _AccountHeader(
                name: displayName,
                email: email,
                memberSince: memberSince,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: Column(
                    children: [
                      _SettingsGroup(
                        title: 'Profile',
                        items: [
                          _SettingsTile(
                            icon: Icons.person_outline,
                            title: 'Display Name',
                            subtitle: displayName,
                            onTap: () => _editDisplayName(context, user),
                          ),
                          _SettingsTile(
                            icon: Icons.mail_outline,
                            title: 'Email',
                            subtitle: email,
                            onTap: () {},
                          ),
                          _SettingsTile(
                            icon: Icons.vpn_key_outlined,
                            title: 'Password',
                            subtitle: 'Tap to change',
                            onTap: () {},
                          ),
                        ],
                      ),
                      _SettingsGroup(
                        title: 'Data',
                        items: [
                          _SettingsTile(
                            icon: Icons.download_outlined,
                            title: 'Export my data',
                            onTap: () {},
                          ),
                          _SettingsTile(
                            icon: Icons.favorite_border,
                            title: 'Apple Health Sync',
                            subtitle: 'Sync your data with Apple Health',
                            trailing: Checkbox(
                              value: false,
                              onChanged: (v) {},
                              activeColor: AppColors.purple,
                            ),
                          ),
                        ],
                      ),
                      _SettingsGroup(
                        title: 'Support',
                        items: [
                          _SettingsTile(
                            icon: Icons.feedback_outlined,
                            title: 'Send feedback',
                            onTap: () {},
                          ),
                          _SettingsTile(
                            icon: Icons.policy_outlined,
                            title: 'Privacy policy',
                            onTap: () {},
                          ),
                        ],
                      ),
                      _SettingsGroup(
                        title: 'Account Actions',
                        items: [
                          _SettingsTile(
                            icon: Icons.logout,
                            title: 'Sign out',
                            onTap: () => showDialog(
                              context: context,
                              builder: (_) => AccountDialog(
                                title: 'Sign Out',
                                message: 'Are you sure you want to sign out?',
                                onYesTap: () async {
                                  Navigator.pop(context);
                                  await FirebaseAuth.instance.signOut();
                                },
                                onNoTap: () => Navigator.pop(context),
                              ),
                            ),
                          ),
                          _SettingsTile(
                            icon: Icons.delete_outline,
                            title: 'Delete account',
                            onTap: () => showDialog(
                              context: context,
                              builder: (_) => AccountDialog(
                                title: 'Delete Account',
                                message:
                                    'Are you sure you want to delete your account? This action cannot be undone.',
                                yesColor: const Color(0xFFFFDADA),
                                onYesTap: () async {
                                  Navigator.pop(context);
                                  await user?.delete();
                                },
                                onNoTap: () => Navigator.pop(context),
                              ),
                            ),
                            color: const Color(0xFFFFDADA),
                            titleColor: const Color(0xFF7A598F),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _editDisplayName(BuildContext context, User? user) {
    final controller = TextEditingController(text: user?.displayName ?? '');
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.teal, width: 2),
        ),
        title: Text(
          'Display Name',
          style: GoogleFonts.openSans(fontWeight: FontWeight.w600),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            hintText: 'Your name',
            filled: true,
            fillColor: const Color(0xFFF7F7FB),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.teal, width: 1.5),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.openSans(color: AppColors.subtitleText)),
          ),
          TextButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                await user?.updateDisplayName(name);
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text('Save',
                style: GoogleFonts.openSans(
                    color: AppColors.teal, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  static String _formatMonth(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.year}';
  }
}

class _AccountHeader extends StatelessWidget {
  final String name, email, memberSince;
  const _AccountHeader(
      {required this.name, required this.email, required this.memberSince});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 20,
        bottom: 30,
        left: 20,
        right: 20,
      ),
      decoration: BoxDecoration(
        color: AppColors.teal.withValues(alpha: 0.4),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 35,
            backgroundColor: Color(0xFFA694BC),
            child: Icon(Icons.person, color: Colors.white, size: 40),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: GoogleFonts.openSans(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF7A598F))),
                Text(email,
                    style: GoogleFonts.openSans(
                        fontSize: 14, color: Colors.grey[600])),
                if (memberSince.isNotEmpty)
                  Text('Member since $memberSince',
                      style: GoogleFonts.openSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF7A598F))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final String title;
  final List<Widget> items;
  const _SettingsGroup({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.purple,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: Text(title,
              style: GoogleFonts.openSans(
                  color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        Container(
          decoration: BoxDecoration(
            border:
                Border.all(color: AppColors.purple.withValues(alpha: 0.3)),
            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(12)),
          ),
          child: Column(children: items),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Color? color;
  final Color? titleColor;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
    this.color,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      tileColor: color,
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: const Color(0xFFA694BC),
            borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
      title: Text(title,
          style: GoogleFonts.openSans(
              fontWeight: FontWeight.w600,
              color: titleColor ?? Colors.grey[800])),
      subtitle: subtitle != null
          ? Text(subtitle!, style: GoogleFonts.openSans(fontSize: 12))
          : null,
      trailing: trailing ?? const Icon(Icons.chevron_right, color: Colors.grey),
    );
  }
}

class AccountDialog extends StatelessWidget {
  final String title;
  final String message;
  final Color? yesColor;
  final Color? noColor;
  final VoidCallback onYesTap;
  final VoidCallback onNoTap;

  const AccountDialog({
    super.key,
    required this.title,
    required this.message,
    this.yesColor,
    this.noColor,
    required this.onYesTap,
    required this.onNoTap,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.teal, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title,
                    style: GoogleFonts.openSans(
                        fontSize: 28,
                        fontWeight: FontWeight.w400,
                        color: Colors.black87)),
                AnimatedPress(
                  onTap: () => Navigator.pop(context),
                  child: const CircleAvatar(
                    backgroundColor: Color(0xFFA694BC),
                    radius: 18,
                    child: Icon(Icons.close, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
            const Divider(color: AppColors.teal, thickness: 1),
            const SizedBox(height: 20),
            Text(message,
                style:
                    GoogleFonts.openSans(fontSize: 18, color: Colors.grey[700]),
                textAlign: TextAlign.center),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _OverlayButton(label: 'Yes', color: yesColor, onTap: onYesTap),
                _OverlayButton(label: 'No', color: noColor, onTap: onNoTap),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OverlayButton extends StatefulWidget {
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _OverlayButton(
      {required this.label, this.color, required this.onTap});

  @override
  State<_OverlayButton> createState() => _OverlayButtonState();
}

class _OverlayButtonState extends State<_OverlayButton> {
  bool _pressed = false;
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Listener(
        onPointerDown: (_) => setState(() => _pressed = true),
        onPointerUp: (_) => setState(() => _pressed = false),
        onPointerCancel: (_) => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.93 : (_hovered ? 1.04 : 1.0),
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(15),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
              decoration: BoxDecoration(
                color: widget.color ?? AppColors.teal.withValues(alpha: 0.1),
                border: Border.all(color: AppColors.teal, width: 1.5),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(widget.label,
                  style: GoogleFonts.openSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87)),
            ),
          ),
        ),
      ),
    );
  }
}
