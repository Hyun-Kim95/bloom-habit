import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../errors/error_logger.dart';
import 'monetization_platform.dart';
import 'monetization_product_ids.dart';

const _kAdFreePrefsKey = 'monetization_ad_free_v1';

enum MonetizationSnack {
  none,
  removeAdsThanks,
  donationThanks,
  restoreRequested,
  productsMissing,
  purchaseError,
}

@immutable
class MonetizationState {
  const MonetizationState({
    this.adFree = false,
    this.storeAvailable = false,
    this.productsLoading = false,
    this.productsById = const {},
    this.purchasePending = false,
    this.snack = MonetizationSnack.none,
    this.snackDetail,
  });

  final bool adFree;
  final bool storeAvailable;
  final bool productsLoading;
  final Map<String, ProductDetails> productsById;
  final bool purchasePending;
  final MonetizationSnack snack;
  final String? snackDetail;

  ProductDetails? product(String id) => productsById[id];

  MonetizationState copyWith({
    bool? adFree,
    bool? storeAvailable,
    bool? productsLoading,
    Map<String, ProductDetails>? productsById,
    bool? purchasePending,
    MonetizationSnack? snack,
    String? snackDetail,
    bool clearSnack = false,
  }) {
    return MonetizationState(
      adFree: adFree ?? this.adFree,
      storeAvailable: storeAvailable ?? this.storeAvailable,
      productsLoading: productsLoading ?? this.productsLoading,
      productsById: productsById ?? this.productsById,
      purchasePending: purchasePending ?? this.purchasePending,
      snack: clearSnack ? MonetizationSnack.none : (snack ?? this.snack),
      snackDetail: clearSnack ? null : (snackDetail ?? this.snackDetail),
    );
  }
}

class MonetizationNotifier extends Notifier<MonetizationState> {
  InAppPurchase? _iap;
  StreamSubscription<List<PurchaseDetails>>? _sub;
  bool _bootstrapStarted = false;

  @override
  MonetizationState build() {
    ref.onDispose(() async {
      await _sub?.cancel();
    });
    return const MonetizationState();
  }

  Future<void> bootstrap() async {
    if (_bootstrapStarted) return;
    _bootstrapStarted = true;

    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getBool(_kAdFreePrefsKey) ?? false;
    state = state.copyWith(adFree: cached);

    if (!monetizationSupported) {
      return;
    }

    try {
      await MobileAds.instance.initialize();
    } catch (_) {}

    final iap = InAppPurchase.instance;
    _iap = iap;
    final available = await iap.isAvailable();
    state = state.copyWith(storeAvailable: available);
    if (!available) {
      return;
    }

    _sub = iap.purchaseStream.listen(
      _onPurchases,
      onError: (Object e, st) {
        ErrorLogger.logError('MonetizationNotifier.purchaseStream', e, st);
        state = state.copyWith(
          purchasePending: false,
          snack: MonetizationSnack.purchaseError,
          snackDetail: null,
        );
      },
    );

    await _reloadProducts(silent: true);
    try {
      await iap.restorePurchases();
    } catch (_) {}
  }

  void clearSnack() {
    state = state.copyWith(clearSnack: true);
  }

  Future<void> refreshProducts() => _reloadProducts(silent: false);

  Future<void> requestRestore() async {
    if (_iap == null || !state.storeAvailable) {
      state = state.copyWith(
        snack: MonetizationSnack.purchaseError,
        snackDetail: null,
      );
      return;
    }
    try {
      await _iap!.restorePurchases();
      state = state.copyWith(snack: MonetizationSnack.restoreRequested);
    } catch (e, st) {
      ErrorLogger.logError('MonetizationNotifier.requestRestore', e, st);
      state = state.copyWith(
        snack: MonetizationSnack.purchaseError,
        snackDetail: null,
      );
    }
  }

  Future<void> buyRemoveAds() async {
    final details = state.product(MonetizationProductIds.removeAds);
    if (_iap == null || !state.storeAvailable || details == null) {
      state = state.copyWith(snack: MonetizationSnack.productsMissing);
      return;
    }
    state = state.copyWith(purchasePending: true);
    try {
      await _iap!.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: details),
      );
    } catch (e, st) {
      ErrorLogger.logError('MonetizationNotifier.buyRemoveAds', e, st);
      state = state.copyWith(
        purchasePending: false,
        snack: MonetizationSnack.purchaseError,
        snackDetail: null,
      );
    }
  }

  Future<void> buyDonation(String productId) async {
    final details = state.product(productId);
    if (_iap == null || !state.storeAvailable || details == null) {
      state = state.copyWith(snack: MonetizationSnack.productsMissing);
      return;
    }
    state = state.copyWith(purchasePending: true);
    try {
      await _iap!.buyConsumable(
        purchaseParam: PurchaseParam(productDetails: details),
      );
    } catch (e, st) {
      ErrorLogger.logError('MonetizationNotifier.buyDonation', e, st);
      state = state.copyWith(
        purchasePending: false,
        snack: MonetizationSnack.purchaseError,
        snackDetail: null,
      );
    }
  }

  Future<void> _reloadProducts({required bool silent}) async {
    if (_iap == null || !state.storeAvailable) return;
    state = state.copyWith(productsLoading: true);
    try {
      final response =
          await _iap!.queryProductDetails(MonetizationProductIds.all);
      if (response.error != null) {
        state = state.copyWith(productsLoading: false);
        if (!silent) {
          ErrorLogger.logError(
            'MonetizationNotifier.queryProductDetails',
            response.error ?? 'unknown',
          );
          state = state.copyWith(
            snack: MonetizationSnack.purchaseError,
            snackDetail: null,
          );
        }
        return;
      }
      final map = {for (final p in response.productDetails) p.id: p};
      state = state.copyWith(productsLoading: false, productsById: map);
    } catch (e) {
      state = state.copyWith(productsLoading: false);
      if (!silent) {
        ErrorLogger.logError('MonetizationNotifier._reloadProducts', e);
        state = state.copyWith(
          snack: MonetizationSnack.purchaseError,
          snackDetail: null,
        );
      }
    }
  }

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.pending) {
        state = state.copyWith(purchasePending: true);
        continue;
      }
      if (purchase.status == PurchaseStatus.error) {
        ErrorLogger.logError(
          'MonetizationNotifier.purchaseError',
          purchase.error ?? 'unknown',
        );
        state = state.copyWith(
          purchasePending: false,
          snack: MonetizationSnack.purchaseError,
          snackDetail: null,
        );
        if (purchase.pendingCompletePurchase) {
          await _iap?.completePurchase(purchase);
        }
        continue;
      }
      if (purchase.status == PurchaseStatus.canceled) {
        state = state.copyWith(purchasePending: false);
        if (purchase.pendingCompletePurchase) {
          await _iap?.completePurchase(purchase);
        }
        continue;
      }
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        await _applyPurchase(purchase);
        if (purchase.pendingCompletePurchase) {
          await _iap?.completePurchase(purchase);
        }
      }
    }
  }

  Future<void> _applyPurchase(PurchaseDetails purchase) async {
    final id = purchase.productID;
    if (id == MonetizationProductIds.removeAds) {
      await _setAdFree(true);
      state = state.copyWith(purchasePending: false);
      if (purchase.status == PurchaseStatus.purchased) {
        state = state.copyWith(snack: MonetizationSnack.removeAdsThanks);
      }
      return;
    }
    if (MonetizationProductIds.isDonation(id)) {
      state = state.copyWith(
        purchasePending: false,
        snack: MonetizationSnack.donationThanks,
      );
      return;
    }
    state = state.copyWith(purchasePending: false);
  }

  Future<void> _setAdFree(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kAdFreePrefsKey, value);
    state = state.copyWith(adFree: value);
  }
}

final monetizationProvider =
    NotifierProvider<MonetizationNotifier, MonetizationState>(
  MonetizationNotifier.new,
);
