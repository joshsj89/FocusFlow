import 'package:flutter/material.dart';
import 'package:focusflow/theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    bool isHealthDataSynced = false; // TODO: Implement actual health data sync status

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const _AccountHeader(
            name: 'Srinivasan',
            email: 's.rajan@email.com',
            memberSince: 'Jan 2026',
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                children: [
                  _SettingsGroup(
                    title: 'Profile',
                    items: [
                      _SettingsTile(icon: Icons.person_outline, title: 'Display Name', subtitle: 'Srinivasan', onTap: () {}),
                      _SettingsTile(icon: Icons.mail_outline, title: 'Email', subtitle: 's.rajan@email.com', onTap: () {}),
                      _SettingsTile(icon: Icons.vpn_key_outlined, title: 'Password', subtitle: 'Last changed 3 months ago', onTap: () {}),
                    ],
                  ),
                  _SettingsGroup(
                    title: 'Data',
                    items: [
                      _SettingsTile(icon: Icons.person_add_alt_1_outlined, title: 'Export my data', onTap: () {}),
                      _SettingsTile(
                        icon: Icons.vpn_key_outlined, 
                        title: 'Apple Health Sync', 
                        subtitle: 'Sync your data with Apple Health',
                        trailing: Checkbox(value: isHealthDataSynced, onChanged: (v) {}, activeColor: AppColors.purple),
                      ),
                    ],
                  ),
                  _SettingsGroup(
                    title: 'Support',
                    items: [
                      _SettingsTile(icon: Icons.person_outline, title: 'Send feedback', onTap: () {}),
                      _SettingsTile(icon: Icons.vpn_key_outlined, title: 'Privacy policy', onTap: () {}),
                    ],
                  ),
                  _SettingsGroup(
                    title: 'Account Actions',
                    items: [
                      _SettingsTile(
                        icon: Icons.person_outline,
                        title: 'Sign out',
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AccountDialog(
                                title: 'Sign Out',
                                message: 'Are you sure you want to sign out?',
                                onYesTap: () {
                                  // TODO: Logout logic
                                  Navigator.pop(context);
                                },
                                onNoTap: () => Navigator.pop(context),
                              );
                            },
                          );
                        },
                      ),
                      _SettingsTile(
                        icon: Icons.vpn_key_outlined, 
                        title: 'Delete account', 
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AccountDialog(
                                title: 'Delete Account',
                                message:
                                    'Are you sure you want to delete your account? This action cannot be undone.',
                                yesColor: const Color(0xFFFFDADA),
                                onYesTap: () {
                                  // TODO: Delete account logic
                                  Navigator.pop(context);
                                },
                                onNoTap: () => Navigator.pop(context),
                              );
                            },
                          );
                        },
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
  }
}

class _AccountHeader extends StatelessWidget {
  final String name, email, memberSince;
  const _AccountHeader({required this.name, required this.email, required this.memberSince});

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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: GoogleFonts.openSans(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF7A598F))),
              Text(email, style: GoogleFonts.openSans(fontSize: 14, color: Colors.grey[600])),
              Text('Member since $memberSince', style: GoogleFonts.openSans(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF7A598F))),
            ],
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
          child: Text(title, style: GoogleFonts.openSans(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.purple.withValues(alpha: 0.3)),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
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
        decoration: BoxDecoration(color: const Color(0xFFA694BC), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
      title: Text(title, style: GoogleFonts.openSans(fontWeight: FontWeight.w600, color: titleColor ?? Colors.grey[800])),
      subtitle: subtitle != null ? Text(subtitle!, style: GoogleFonts.openSans(fontSize: 12)) : null,
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
                Text(
                  title,
                  style: GoogleFonts.openSans(
                    fontSize: 28,
                    fontWeight: FontWeight.w400,
                    color: Colors.black87,
                  ),
                ),
                GestureDetector(
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
            Text(
              message,
              style: GoogleFonts.openSans(
                fontSize: 18,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _OverlayButton(
                  label: 'Yes',
                  color: yesColor,
                  onTap: onYesTap,
                ),
                _OverlayButton(
                  label: 'No',
                  color: noColor,
                  onTap: onNoTap,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OverlayButton extends StatelessWidget {
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _OverlayButton({required this.label, this.color, required this.onTap,});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
        decoration: BoxDecoration(
          color: color ?? AppColors.teal.withValues(alpha: 0.1),
          border: Border.all(color: AppColors.teal, width: 1.5),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Text(
          label,
          style: GoogleFonts.openSans(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }
}