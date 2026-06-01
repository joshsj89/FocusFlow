enum PremiumPlan { monthly, yearly }

enum PaywallStatus { idle, loading, success, error }

class PlanOption {
  final PremiumPlan plan;
  final String label;
  final String priceLabel;
  final String sublabel;
  final bool isBestValue;

  const PlanOption({
    required this.plan,
    required this.label,
    required this.priceLabel,
    required this.sublabel,
    required this.isBestValue,
  });
}

const kPlanOptions = [
  PlanOption(
    plan: PremiumPlan.monthly,
    label: 'Monthly',
    priceLabel: '\$1.99',
    sublabel: 'per month',
    isBestValue: false,
  ),
  PlanOption(
    plan: PremiumPlan.yearly,
    label: 'Yearly',
    priceLabel: '\$19.99',
    sublabel: 'per year',
    isBestValue: true,
  ),
];
