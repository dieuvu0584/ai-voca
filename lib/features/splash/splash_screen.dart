import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/l10n/strings.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _iconFade;
  late Animation<double> _iconScale;
  late Animation<double> _textFade;
  late Animation<double> _sloganFade;
  late Animation<Offset> _sloganSlide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // Icon: fade in + scale up song song (to dần & rõ dần) trong 700ms đầu
    _iconFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
    );
    _iconScale = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
      ),
    );

    // App name xuất hiện sau icon
    _textFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.35, 0.65, curve: Curves.easeOut),
    );

    // Slogan xuất hiện cuối
    _sloganFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.55, 0.9, curve: Curves.easeOut),
    );
    _sloganSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.55, 0.9, curve: Curves.easeOut),
    ));

    _ctrl.forward();

    // Chuyển sang homepage sau 3.5 giây
    Future.delayed(const Duration(milliseconds: 3500), () {
      if (mounted) context.go('/home');
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(guiLangProvider);
    final cs = appColors(context);
    final slogan = tr(lang, 'splash_slogan');

    // Tách phần quote và tên tác giả
    final parts = slogan.split('— ');
    final quote = parts[0].trim();
    final author = parts.length > 1 ? '— ${parts[1].trim()}' : '';

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ── Icon + App name — đúng giữa màn hình như native splash ──
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon: scale up + fade in song song
                ScaleTransition(
                  scale: _iconScale,
                  child: FadeTransition(
                    opacity: _iconFade,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Image.asset(
                        'assets/icon_source.png',
                        width: 108,
                        height: 108,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // App name ngay dưới icon
                FadeTransition(
                  opacity: _textFade,
                  child: Text(
                    tr(lang, 'app_title'),
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: cs.primary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Slogan — cố định ở cuối màn hình ──
          Positioned(
            bottom: 64,
            left: 40,
            right: 40,
            child: SlideTransition(
              position: _sloganSlide,
              child: FadeTransition(
                opacity: _sloganFade,
                child: Column(
                  children: [
                    Text(
                      quote,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey[600],
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      author,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: cs.primary.withValues(alpha: 0.7),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
