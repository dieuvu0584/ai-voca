import 'dart:async';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

const kPremiumProductId = 'vocab_ai_premium_lifetime';
const kPremiumPrefKey = 'is_premium_v1';

class PremiumService {
  static final PremiumService _instance = PremiumService._();
  factory PremiumService() => _instance;
  PremiumService._();

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;
  Function(bool)? onPremiumChanged;

  Future<void> init() async {
    final available = await _iap.isAvailable();
    if (!available) return;
    _sub = _iap.purchaseStream.listen(_onPurchaseUpdate, onError: (_) {});
    // Khôi phục giao dịch cũ khi khởi động
    await _iap.restorePurchases();
  }

  void dispose() {
    _sub?.cancel();
  }

  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final p in purchases) {
      if (p.productID != kPremiumProductId) continue;
      if (p.status == PurchaseStatus.purchased ||
          p.status == PurchaseStatus.restored) {
        await _deliver();
      }
      if (p.pendingCompletePurchase) {
        await _iap.completePurchase(p);
      }
    }
  }

  Future<void> _deliver() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kPremiumPrefKey, true);
    onPremiumChanged?.call(true);
  }

  Future<bool> loadCached() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(kPremiumPrefKey) ?? false;
  }

  Future<void> buy() async {
    final available = await _iap.isAvailable();
    if (!available) throw Exception('store_unavailable');
    final resp = await _iap.queryProductDetails({kPremiumProductId});
    if (resp.productDetails.isEmpty) throw Exception('product_not_found');
    final param = PurchaseParam(productDetails: resp.productDetails.first);
    await _iap.buyNonConsumable(purchaseParam: param);
  }

  Future<void> restore() async {
    final available = await _iap.isAvailable();
    if (!available) throw Exception('store_unavailable');
    await _iap.restorePurchases();
  }
}
