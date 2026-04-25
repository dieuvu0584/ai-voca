import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/premium/premium_notifier.dart';
import '../../core/providers.dart';
import '../../core/l10n/strings.dart';

class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  /// Hiện paywall dạng bottom sheet
  static Future<void> show(BuildContext context, WidgetRef ref) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const PaywallScreen(),
    );
  }

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(guiLangProvider);
    final isPremium = ref.watch(premiumProvider);

    // Tự đóng sheet khi đã mua Premium
    if (isPremium) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pop();
      });
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            // Icon vương miện
            const Icon(
              Icons.workspace_premium_rounded,
              size: 48,
              color: Colors.amber,
            ),
            const SizedBox(height: 12),
            // Tiêu đề
            Text(
              tr(lang, 'premium_title'),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            // Mô tả tính năng — căn giữa
            Text(
              tr(lang, 'premium_feature_langs'),
              style: TextStyle(fontSize: 15, color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Text(
              tr(lang, 'premium_subtitle'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            // Nút nâng cấp
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading
                    ? null
                    : () async {
                        setState(() => _loading = true);
                        final messenger = ScaffoldMessenger.of(context);
                        try {
                          await ref.read(premiumProvider.notifier).buy();
                        } catch (e) {
                          if (mounted) {
                            messenger.showSnackBar(
                              SnackBar(content: Text(_localizeError(e, lang))),
                            );
                          }
                        } finally {
                          if (mounted) setState(() => _loading = false);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        tr(lang, 'premium_upgrade_btn'),
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            // Nút khôi phục
            TextButton(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                try {
                  await ref.read(premiumProvider.notifier).restore();
                  if (mounted) {
                    messenger.showSnackBar(
                      SnackBar(content: Text(tr(lang, 'premium_restore_success'))),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    messenger.showSnackBar(
                      SnackBar(content: Text(_localizeError(e, lang))),
                    );
                  }
                }
              },
              child: Text(tr(lang, 'premium_restore_btn')),
            ),
          ],
        ),
      ),
    );
  }

  /// Chuyển Exception('store_unavailable') → chuỗi đã dịch theo ngôn ngữ UI.
  /// Nếu key không tồn tại trong bảng dịch, trả về message gốc làm fallback.
  String _localizeError(Object e, String lang) {
    final raw = e.toString();
    // Exception.toString() trả về "Exception: <message>"
    final key = raw.startsWith('Exception: ')
        ? raw.substring('Exception: '.length)
        : raw;
    final translated = tr(lang, key);
    // tr() trả về key khi không tìm thấy → dùng raw làm fallback
    return translated == key ? raw : translated;
  }
}
