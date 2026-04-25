import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'premium_service.dart';

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
