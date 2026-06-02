import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../cubits/paywall_cubit.dart';
import '../models/plan_option.dart';
import '../theme/app_colors.dart';

class PremiumPaywallSheet extends StatelessWidget {
  const PremiumPaywallSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PaywallCubit(),
      child: const _PaywallBody(),
    );
  }
}

class _PaywallBody extends StatelessWidget {
  const _PaywallBody();

  @override
  Widget build(BuildContext context) {
    return BlocListener<PaywallCubit, PaywallState>(
      listenWhen: (prev, next) => prev.status != next.status,
      listener: (context, state) {
        if (state.status == PaywallStatus.success) {
          Navigator.of(context).pop();
          ScaffoldMessenger.maybeOf(context)?.showSnackBar(
            const SnackBar(content: Text('Welcome to Premium! 🎉')),
          );
        }
        if (state.status == PaywallStatus.error) {
          ScaffoldMessenger.maybeOf(context)?.showSnackBar(
            SnackBar(
              content: Text(
                  state.errorMessage ?? 'Purchase failed. Please try again.'),
            ),
          );
        }
      },
      child: BlocBuilder<PaywallCubit, PaywallState>(
        builder: (context, state) {
          final isLoading = state.status == PaywallStatus.loading;

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Drag handle
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: AppColors.cardBorder,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    // Close button row
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        icon: const Icon(Icons.close,
                            color: AppColors.subtitleText),
                        onPressed: isLoading
                            ? null
                            : () => Navigator.of(context).pop(),
                      ),
                    ),
                    // Premium badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.purple,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'FocusFlow Premium',
                        style: GoogleFonts.openSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Heading
                    Text(
                      'Build a focus practice\nthat lasts',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.openSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkNavy,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Plan selector
                    _PlanSelector(
                        selectedPlan: state.selectedPlan,
                        enabled: !isLoading),
                    const SizedBox(height: 28),
                    // Feature bullets
                    const _FeatureBullets(),
                    const SizedBox(height: 28),
                    // CTA button
                    _TrialButton(isLoading: isLoading),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed:
                          isLoading ? null : () => Navigator.of(context).pop(),
                      child: Text(
                        'Maybe Later',
                        style: GoogleFonts.openSans(
                          color: AppColors.subtitleText,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Plan selector ─────────────────────────────────────────────────────────────

class _PlanSelector extends StatelessWidget {
  final PremiumPlan selectedPlan;
  final bool enabled;

  const _PlanSelector({required this.selectedPlan, required this.enabled});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: kPlanOptions
          .map((option) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: option.plan == PremiumPlan.monthly ? 8 : 0,
                  ),
                  child: _PlanChip(
                    option: option,
                    isSelected: selectedPlan == option.plan,
                    enabled: enabled,
                    onTap: () => context
                        .read<PaywallCubit>()
                        .selectPlan(option.plan),
                  ),
                ),
              ))
          .toList(),
    );
  }
}

class _PlanChip extends StatelessWidget {
  final PlanOption option;
  final bool isSelected;
  final bool enabled;
  final VoidCallback onTap;

  const _PlanChip({
    required this.option,
    required this.isSelected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.purple : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.purple : AppColors.cardBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            if (option.isBestValue)
              Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Best Value',
                  style: GoogleFonts.openSans(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            Text(
              option.label,
              style: GoogleFonts.openSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : AppColors.darkNavy,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              option.priceLabel,
              style: GoogleFonts.openSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : AppColors.darkNavy,
              ),
            ),
            Text(
              option.sublabel,
              style: GoogleFonts.openSans(
                fontSize: 10,
                color: isSelected
                    ? Colors.white.withAlpha(200)
                    : AppColors.subtitleText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Feature bullets ───────────────────────────────────────────────────────────

const _kFeatures = [
  (Icons.library_music_rounded, 'Full soundscape library'),
  (Icons.auto_awesome_rounded, 'AI-Suggested break activities'),
  (Icons.favorite_rounded, 'Health & Calendar sync'),
  (Icons.spa_rounded, 'Wellness routines'),
];

class _FeatureBullets extends StatelessWidget {
  const _FeatureBullets();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _kFeatures
          .map((f) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.purple.withAlpha(20),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child:
                          Icon(f.$1, color: AppColors.purple, size: 18),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      f.$2,
                      style: GoogleFonts.openSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.darkNavy,
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }
}

// ── CTA button ────────────────────────────────────────────────────────────────

class _TrialButton extends StatelessWidget {
  final bool isLoading;

  const _TrialButton({required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed:
            isLoading ? null : () => context.read<PaywallCubit>().simulatePurchase(),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.purple,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.purple.withAlpha(120),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : Text(
                'Start 7-day Free Trial',
                style: GoogleFonts.openSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }
}
