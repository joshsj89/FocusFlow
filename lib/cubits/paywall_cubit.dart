import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../models/plan_option.dart';

// SKU IDs — configure matching products in App Store Connect / Google Play Console
const _kMonthlySkuId = 'focusflow_premium_monthly';
const _kYearlySkuId = 'focusflow_premium_yearly';

// ── State ─────────────────────────────────────────────────────────────────────

class PaywallState extends Equatable {
  final PremiumPlan selectedPlan;
  final PaywallStatus status;
  final String? errorMessage;

  const PaywallState({
    required this.selectedPlan,
    required this.status,
    this.errorMessage,
  });

  factory PaywallState.initial() => const PaywallState(
        selectedPlan: PremiumPlan.yearly,
        status: PaywallStatus.idle,
      );

  PaywallState copyWith({
    PremiumPlan? selectedPlan,
    PaywallStatus? status,
    String? errorMessage,
  }) {
    return PaywallState(
      selectedPlan: selectedPlan ?? this.selectedPlan,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [selectedPlan, status, errorMessage];
}

// ── Cubit ─────────────────────────────────────────────────────────────────────

class PaywallCubit extends Cubit<PaywallState> {
  PaywallCubit() : super(PaywallState.initial()) {
    _purchaseSub = InAppPurchase.instance.purchaseStream.listen(
      _onPurchaseUpdate,
      onError: (_) => _emitError('Purchase failed. Please try again.'),
    );
  }

  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;

  void selectPlan(PremiumPlan plan) {
    if (state.status == PaywallStatus.loading) return;
    emit(state.copyWith(selectedPlan: plan));
  }

  Future<void> initiatePurchase() async {
    if (state.status == PaywallStatus.loading) return;
    emit(state.copyWith(status: PaywallStatus.loading));

    try {
      final available = await InAppPurchase.instance.isAvailable();
      if (!available) {
        _emitError('In-app purchases are not available on this device.');
        return;
      }

      final skuId = state.selectedPlan == PremiumPlan.yearly
          ? _kYearlySkuId
          : _kMonthlySkuId;

      final response =
          await InAppPurchase.instance.queryProductDetails({skuId});

      if (response.productDetails.isEmpty) {
        _emitError('Product not found. Please try again later.');
        return;
      }

      final param =
          PurchaseParam(productDetails: response.productDetails.first);
      await InAppPurchase.instance.buyNonConsumable(purchaseParam: param);
      // Result arrives asynchronously via _onPurchaseUpdate
    } catch (_) {
      _emitError('Purchase failed. Please try again.');
    }
  }

  Future<void> restorePurchases() async {
    emit(state.copyWith(status: PaywallStatus.loading));
    try {
      await InAppPurchase.instance.restorePurchases();
      // Restored purchases arrive via _onPurchaseUpdate
    } catch (_) {
      _emitError('Could not restore purchases. Please try again.');
    }
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          InAppPurchase.instance.completePurchase(purchase);
          _markPremium(purchase.productID).then((_) {
            if (!isClosed) emit(state.copyWith(status: PaywallStatus.success));
          });
        case PurchaseStatus.error:
          _emitError('Purchase failed. Please try again.');
        case PurchaseStatus.canceled:
          if (!isClosed) emit(state.copyWith(status: PaywallStatus.idle));
        case PurchaseStatus.pending:
          break;
      }
    }
  }

  Future<void> _markPremium(String productId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final plan = productId == _kYearlySkuId ? 'yearly' : 'monthly';
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'isPremium': true,
      'premiumSince': Timestamp.now(),
      'premiumPlan': plan,
    });
  }

  void _emitError(String message) {
    if (!isClosed) {
      emit(state.copyWith(status: PaywallStatus.error, errorMessage: message));
    }
  }

  @override
  Future<void> close() {
    _purchaseSub?.cancel();
    return super.close();
  }
}
