import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../app.dart';
import '../core/theme/app_theme.dart';
import '../core/providers.dart';
import '../core/premium/premium_notifier.dart';
import '../core/db/database.dart';
import '../core/ai/ai_service.dart';
import '../core/ai/ai_settings.dart';
import '../core/l10n/strings.dart';

enum _Period { day, week, month }

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen>
    with TickerProviderStateMixin {
  // ── data ──────────────────────────────────────────────
  int _studiedToday = 0;
  int _streak = 0;
  List<WordProgressData> _known = [];
  List<WordProgressData> _learning = [];
  List<WordProgressData> _newWords = [];
  List<Map<String, dynamic>> _historyData = [];
  int _dueCount = 0;
  bool _loading = true;
  _Period _period = _Period.day;

  // ── controllers ───────────────────────────────────────
  late AnimationController _barAnimCtrl;
  late Animation<double> _barAnim;

  @override
  void initState() {
    super.initState();
    _barAnimCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _barAnim =
        CurvedAnimation(parent: _barAnimCtrl, curve: Curves.easeOutCubic);
    _loadStats();
    WidgetsBinding.instance.addPostFrameCallback((_) => _triggerSync());
    WidgetsBinding.instance.addPostFrameCallback((_) => _watchAIErrors());
    WidgetsBinding.instance.addPostFrameCallback((_) => _watchStatsRefresh());
  }

  void _watchStatsRefresh() {
    ref.listenManual(statsRefreshProvider, (_, _) {
      if (mounted) _loadStats();
    });
  }

  void _watchAIErrors() {
    // Dùng ref.listen để nhận thông báo khi AI bị auto-disable
    ref.listenManual(
      aiSettingsProvider.select((s) => s.pendingNotification),
      (_, notification) {
        if (notification != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(notification)),
                ],
              ),
              backgroundColor: Colors.orange.shade700,
              duration: const Duration(seconds: 6),
              action: SnackBarAction(
                label: 'OK',
                textColor: Colors.white,
                onPressed: () {},
              ),
            ),
          );
          ref.read(aiSettingsProvider.notifier).clearNotification();
        }
      },
    );
  }

  void _triggerSync() {
    final langCode = ref.read(languageProvider).primary.code;
    final isPremium = ref.read(effectivePremiumProvider);
    // Chạy nền — khi sync xong thì reload stats để homepage cập nhật đúng số từ
    ref.read(vocabSyncProvider).syncIfNeeded(langCode, isPremium: isPremium).then((_) {
      if (mounted) _loadStats();
    });
  }

  @override
  void dispose() {
    _barAnimCtrl.dispose();
    super.dispose();
  }

  // ── data loading ──────────────────────────────────────

  Future<void> _loadStats() async {
    if (!mounted) return;
    setState(() => _loading = true);
    final langCode = ref.read(languageProvider).primary.code;
    final dao = ref.read(progressDaoProvider);

    final results = await Future.wait([
      dao.wordsStudiedToday(langCode),
      dao.getCurrentStreak(langCode),
      dao.getKnownWords(langCode),           // known + skipped
      dao.getLearningWords(langCode),
      dao.getNewWords(langCode, limit: 100),
      _loadHistory(langCode),
    ]);

    if (!mounted) return;
    setState(() {
      _studiedToday = results[0] as int;
      _streak = results[1] as int;
      _known = results[2] as List<WordProgressData>;
      _learning = results[3] as List<WordProgressData>;
      _newWords = results[4] as List<WordProgressData>;
      _historyData = results[5] as List<Map<String, dynamic>>;
      // _dueCount = từ đang cần ôn = learning + new đang active
      // Dùng _learning + _newWords (cùng data với circle) thay vì countWordsForLang
      // để tránh đếm cả 47k từ seed DB chưa đưa vào học.
      // _newWords có limit=100 → nhất quán với số hiện ở circle header.
      _dueCount = _learning.length + _newWords.length;
      _loading = false;
    });
    _barAnimCtrl.forward(from: 0);
  }

  Future<List<Map<String, dynamic>>> _loadHistory(String langCode) {
    final dao = ref.read(progressDaoProvider);
    return switch (_period) {
      _Period.day => dao.getDailyStudyHistory(langCode),
      _Period.week => dao.getWeeklyStudyHistory(langCode),
      _Period.month => dao.getMonthlyStudyHistory(langCode),
    };
  }

  Future<void> _switchPeriod(_Period p) async {
    if (_period == p) return;
    setState(() => _period = p);
    final langCode = ref.read(languageProvider).primary.code;
    final data = await _loadHistory(langCode);
    if (!mounted) return;
    setState(() => _historyData = data);
    _barAnimCtrl.forward(from: 0);
  }

  // ── build ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final langState = ref.watch(languageProvider);
    final aiSettings = ref.watch(aiSettingsProvider);
    final lang = ref.watch(guiLangProvider);
    ref.watch(appThemeProvider); // rebuild khi đổi màu theme

    ref.listen(languageProvider, (_, _) {
      _loadStats();
      _triggerSync();
    });

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 74,
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 4),
            Tooltip(
              message: tr(lang, 'lookup'),
              child: InkWell(
                onTap: () => context.push('/lookup'),
                borderRadius: BorderRadius.circular(20),
                child: const Padding(
                  padding: EdgeInsets.fromLTRB(8, 8, 3, 8),
                  child: Icon(Icons.search_rounded, size: 24),
                ),
              ),
            ),
            if (aiSettings.mode != AIMode.none)
              Tooltip(
                message: tr(lang, 'ask_ai'),
                child: InkWell(
                  onTap: () => context.push('/ai-chat'),
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(3, 8, 8, 8),
                    child: Icon(
                      aiProviderIcon(aiSettings.provider),
                      size: 24,
                      color: appColors(context).primary,
                    ),
                  ),
                ),
            ),
          ],
        ),
        title: Text(tr(lang, 'app_title')),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadStats,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildFlashcardCTA(lang),
                      _buildImportCTA(lang),
                      _buildHeader(lang, langState),
                      _buildPeriodSelector(lang),
                      _buildBarChart(lang),
                      _buildStatsRow(lang),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  // ── flashcard CTA ─────────────────────────────────────

  Widget _buildFlashcardCTA(String lang) {
    final cs = appColors(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: GestureDetector(
        onTap: () => context.push('/preview'),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.07),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.style_rounded, color: cs.primary, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr(lang, 'flashcard'),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _dueCount > 0
                          ? trArgs(lang, 'n_words_queue', {'n': '$_dueCount'})
                          : tr(lang, 'no_words_queue'),
                      style: TextStyle(
                        fontSize: 13,
                        color: _dueCount > 0 ? cs.primary : Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.play_circle_fill_rounded,
                color: _dueCount > 0 ? cs.primary : Colors.grey[300],
                size: 38,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── import CTA ────────────────────────────────────────

  Widget _buildImportCTA(String lang) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: GestureDetector(
        onTap: () => context.push('/import'),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.upload_file_rounded,
                    color: Color(0xFF3B82F6), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr(lang, 'import_vocab'),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: primaryColor,
                      ),
                    ),
                    Text(
                      tr(lang, 'import_vocab_subtitle'),
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right,
                  color: Color(0xFF3B82F6), size: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ── header card ───────────────────────────────────────

  Widget _buildHeader(String lang, dynamic langState) {
    final cs = appColors(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.primary, cs.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: cs.primary.withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 7))
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(langState.primary.flag,
                        style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 6),
                    Text(
                      langState.primary.name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                RichText(
                  text: TextSpan(children: [
                    TextSpan(
                      text: '$_studiedToday ',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          height: 1),
                    ),
                    TextSpan(
                      text: tr(lang, 'words_reviewed_today'),
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 13),
                    ),
                  ]),
                ),
                const SizedBox(height: 4),
                Text(
                  '$_dueCount ${tr(lang, 'words_in_queue')}',
                  style: const TextStyle(
                      color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '🔥 $_streak ${tr(lang, 'streak')}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3), width: 1.5),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 60,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '${_known.length}/${_known.length + _learning.length + _newWords.length}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
                SizedBox(
                  width: 60,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      tr(lang, 'memorized'),
                      style: const TextStyle(color: Colors.white70, fontSize: 9),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── period selector ───────────────────────────────────

  Widget _buildPeriodSelector(String lang) {
    final cs = appColors(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(4),
        child: Row(
          children: _Period.values.map((p) {
            final label = switch (p) {
              _Period.day => tr(lang, 'day_tab'),
              _Period.week => tr(lang, 'week_tab'),
              _Period.month => tr(lang, 'month_tab'),
            };
            final isSelected = _period == p;
            return Expanded(
              child: GestureDetector(
                onTap: () => _switchPeriod(p),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color: isSelected ? cs.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(9),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                                color: cs.primary.withValues(alpha: 0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 2))
                          ]
                        : null,
                  ),
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[500],
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ── bar chart ─────────────────────────────────────────

  Widget _buildBarChart(String lang) {
    final maxCount = _historyData.isEmpty
        ? 1
        : _historyData.map((e) => e['count'] as int).reduce(max);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tr(lang, 'study_history'),
              style: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 14),
          (_historyData.isEmpty || maxCount == 0)
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 28),
                    child: Column(
                      children: [
                        Icon(Icons.bar_chart_outlined,
                            size: 40, color: Colors.grey[300]),
                        const SizedBox(height: 8),
                        Text(tr(lang, 'no_data_yet'),
                            style: TextStyle(color: Colors.grey[400])),
                      ],
                    ),
                  ),
                )
              : AnimatedBuilder(
                  animation: _barAnim,
                  builder: (context, _) => CustomPaint(
                    size: const Size(double.infinity, 150),
                    painter: _BarChartPainter(
                      data: _historyData,
                      maxVal: maxCount.toDouble(),
                      progress: _barAnim.value,
                      period: _period,
                      barColor: appColors(context).primary,
                      wordLabel: tr(lang, 'words_short'),
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  // ── stats row ─────────────────────────────────────────

  Widget _buildStatsRow(String lang) {
    final cs = appColors(context);
    final total = _known.length + _learning.length + _newWords.length;
    final histSum = _historyData.isEmpty
        ? 0
        : _historyData.map((e) => e['count'] as int).fold(0, (a, b) => a + b);
    final avgPerDay =
        _historyData.isEmpty ? 0.0 : histSum / _historyData.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          _StatChip(
              label: tr(lang, 'streak'),
              value: '$_streak 🔥',
              color: warningOrange),
          const SizedBox(width: 8),
          _StatChip(
              label: tr(lang, 'total_words'),
              value: '$total',
              color: cs.primary),
          const SizedBox(width: 8),
          _StatChip(
              label: tr(lang, 'memorized'),
              value: '${_known.length}/$total',
              color: successGreen),
          const SizedBox(width: 8),
          _StatChip(
              label: tr(lang, 'avg_per_day'),
              value: avgPerDay.toStringAsFixed(1),
              color: cs.secondary),
        ],
      ),
    );
  }

}

// ─────────────────────────────────────────────────────────
// PAINTERS
// ─────────────────────────────────────────────────────────

class _BarChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  final double maxVal;
  final double progress;
  final _Period period;
  final Color barColor;
  final String wordLabel;

  const _BarChartPainter({
    required this.data,
    required this.maxVal,
    required this.progress,
    required this.period,
    required this.barColor,
    required this.wordLabel,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final barPaint = Paint()..style = PaintingStyle.fill;
    const bottomPad = 26.0;
    const topPad = 18.0;
    const spacing = 5.0;
    final availH = size.height - bottomPad - topPad;
    final barW =
        (size.width - spacing * (data.length - 1)) / data.length;

    for (int i = 0; i < data.length; i++) {
      final count = data[i]['count'] as int;
      final frac = maxVal > 0 ? count / maxVal : 0.0;
      final barH = frac * availH * progress;
      final x = i * (barW + spacing);
      final y = topPad + availH - barH;

      barPaint.color = barH > 0
          ? barColor
          : barColor.withValues(alpha: 0.08);

      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(x, y, barW, max(barH, 2)),
          topLeft: const Radius.circular(5),
          topRight: const Radius.circular(5),
        ),
        barPaint,
      );

      if (count > 0 && progress > 0.5) {
        _drawText(
          canvas,
          text: '$count $wordLabel',
          style: TextStyle(
              fontSize: 9,
              color: barColor,
              fontWeight: FontWeight.w700),
          x: x + barW / 2,
          y: y - 13,
          centered: true,
        );
      }

      final date = data[i]['date'] as DateTime;
      final label = switch (period) {
        _Period.day => '${date.day}/${date.month}',
        _Period.week => 'W${_isoWeek(date)}',
        _Period.month => '${_monthAbbr(date.month)}/${date.year % 100}',
      };
      _drawText(
        canvas,
        text: label,
        style: const TextStyle(fontSize: 8.5, color: Colors.grey),
        x: x + barW / 2,
        y: size.height - 16,
        centered: true,
      );
    }
  }

  void _drawText(
    Canvas canvas, {
    required String text,
    required TextStyle style,
    required double x,
    required double y,
    bool centered = false,
  }) {
    final tp = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: TextDirection.ltr)
      ..layout();
    tp.paint(canvas, Offset(centered ? x - tp.width / 2 : x, y));
  }

  int _isoWeek(DateTime d) {
    final startOfYear = DateTime(d.year, 1, 1);
    return ((d.difference(startOfYear).inDays) / 7).floor() + 1;
  }

  String _monthAbbr(int m) {
    const names = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return names[m - 1];
  }

  @override
  bool shouldRepaint(_BarChartPainter old) =>
      old.progress != progress ||
      old.data != data ||
      old.period != period;
}

// ─────────────────────────────────────────────────────────
// SMALL WIDGETS
// ─────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.w800, fontSize: 15),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(color: Colors.grey[500], fontSize: 9),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}


