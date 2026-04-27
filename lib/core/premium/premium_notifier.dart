import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'premium_service.dart';

// ── Launch Promo ─────────────────────────────────────────────
/// Cập nhật đúng ngày publish lên Google Play trước khi release
const kLaunchDate = '2026-05-01';
const kPromoDays = 90;

/// true nếu đang trong thời gian promo 90 ngày đầu
bool get isPromoActive {
  final launch = DateTime.parse(kLaunchDate);
  return DateTime.now().isBefore(launch.add(const Duration(days: kPromoDays)));
}

/// Số ngày còn lại trong promo (0 nếu đã hết)
int get promoDaysLeft {
  final end = DateTime.parse(kLaunchDate).add(const Duration(days: kPromoDays));
  return end.difference(DateTime.now()).inDays.clamp(0, kPromoDays);
}

// ── Notifier ─────────────────────────────────────────────────
class PremiumNotifier extends StateNotifier<bool> {
  PremiumNotifier() : super(false) {
    _init();
  }

  final _service = PremiumService();

  Future<void> _init() async {
    final cached = await _service.loadCached();
    if (mounted) state = cached;
    _service.onPremiumChanged = (val) {
      if (mounted) state = val;
    };
    await _service.init();
  }

  Future<void> buy() async {
    await _service.buy();
  }

  Future<void> restore() async {
    await _service.restore();
  }
}

final premiumProvider = StateNotifierProvider<PremiumNotifier, bool>(
  (_) => PremiumNotifier(),
);

/// Premium hiệu lực = đã mua HOẶC đang trong promo 90 ngày đầu.
/// Dùng provider này cho mọi feature-gating — KHÔNG dùng cho IAP/Paywall.
final effectivePremiumProvider = Provider<bool>((ref) {
  return ref.watch(premiumProvider) || isPromoActive;
});
