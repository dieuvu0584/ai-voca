import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app.dart';
import '../../core/providers.dart';
import '../../core/db/database.dart';
import '../../core/l10n/strings.dart';
import '../../core/theme/app_theme.dart';

enum _Period { day, week, month }

class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen>
    with TickerProviderStateMixin {
  // ── data ──────────────────────────────────────────────
  int _studiedToday = 0;
  int _streak = 0;
  List<WordProgressData> _known = [];
  List<WordProgressData> _learning = [];
  List<WordProgressData> _newWords = [];
  List<Map<String, dynamic>> _historyData = [];
  bool _loading = true;
  _Period _period = _Period.day;

  // ── controllers ───────────────────────────────────────
  late AnimationController _barAnimCtrl;
  late Animation<double> _barAnim;
  late TabController _wordTabCtrl;

  @override
  void initState() {
    super.initState();
    _barAnimCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _barAnim =
        CurvedAnimation(parent: _barAnimCtrl, curve: Curves.easeOutCubic);
    _wordTabCtrl = TabController(length: 3, vsync: this);
    _loadStats();
  }

  @override
  void dispose() {
    _barAnimCtrl.dispose();
    _wordTabCtrl.dispose();
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
      dao.getKnownWords(langCode),
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
    final lang = ref.watch(guiLangProvider);

    return Scaffold(
      appBar: AppBar(title: Text(tr(lang, 'progress'))),
      body: SafeArea(
        top: false,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadStats,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(lang, langState),
                      _buildPeriodSelector(lang),
                      _buildBarChart(lang),
                      _buildStatsRow(lang),
                      _buildDonutSection(lang),
                      _buildWordListSection(lang),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  // ── header card ───────────────────────────────────────

  Widget _buildHeader(String lang, dynamic langState) {
    final cs = appColors(context);
    return Container(
      margin: const EdgeInsets.all(16),
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
                // Language badge
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
                // Studied today
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
                      text: tr(lang, 'studied_today').toLowerCase(),
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 13),
                    ),
                  ]),
                ),
                const SizedBox(height: 8),
                // Streak
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
          // Accuracy circle
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
                Text(
                  '${_known.length}/${_known.length + _learning.length + _newWords.length}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900),
                ),
                Text(
                  tr(lang, 'memorized'),
                  style:
                      const TextStyle(color: Colors.white70, fontSize: 9),
                  textAlign: TextAlign.center,
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
      padding: const EdgeInsets.symmetric(horizontal: 16),
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
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.normal,
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
    final cs = appColors(context);
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
                      barColor: cs.primary,
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
    final total =
        _known.length + _learning.length + _newWords.length;
    final histSum = _historyData.isEmpty
        ? 0
        : _historyData
            .map((e) => e['count'] as int)
            .fold(0, (a, b) => a + b);
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
              value: '${_known.length}/${_known.length + _learning.length + _newWords.length}',
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

  // ── donut chart ───────────────────────────────────────

  Widget _buildDonutSection(String lang) {
    final total =
        (_known.length + _learning.length + _newWords.length).toDouble();
    if (total == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: Colors.grey.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 110,
              height: 110,
              child: CustomPaint(
                painter: _DonutChartPainter(
                  known: _known.length.toDouble(),
                  learning: _learning.length.toDouble(),
                  newCount: _newWords.length.toDouble(),
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr(lang, 'word_distribution'),
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  const SizedBox(height: 14),
                  _LegendItem(
                      color: successGreen,
                      label:
                          '${tr(lang, 'memorized')}: ${_known.length}'),
                  const SizedBox(height: 8),
                  _LegendItem(
                      color: warningOrange,
                      label:
                          '${tr(lang, 'need_review')}: ${_learning.length}'),
                  const SizedBox(height: 8),
                  _LegendItem(
                      color: Colors.grey[400]!,
                      label:
                          '${tr(lang, 'not_studied')}: ${_newWords.length}'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── word list tabs ────────────────────────────────────

  Widget _buildWordListSection(String lang) {
    final cs = appColors(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TabBar(
            controller: _wordTabCtrl,
            labelColor: cs.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: cs.primary,
            labelStyle: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600),
            tabs: [
              Tab(
                  text:
                      '${tr(lang, 'memorized')} (${_known.length})'),
              Tab(
                  text:
                      '${tr(lang, 'need_review')} (${_learning.length})'),
              Tab(
                  text:
                      '${tr(lang, 'not_studied')} (${_newWords.length})'),
            ],
          ),
          SizedBox(
            height: 130,
            child: TabBarView(
              controller: _wordTabCtrl,
              children: [
                _buildWordChips(_known, successGreen),
                _buildWordChips(_learning, warningOrange),
                _buildWordChips(_newWords, Colors.grey),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWordChips(List<WordProgressData> words, Color color) {
    final ttsService = ref.read(ttsServiceProvider);
    final ttsLang = ref.read(languageProvider).primary.ttsLang;

    if (words.isEmpty) {
      return Center(
          child: Text('—', style: TextStyle(color: Colors.grey[400])));
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: words
            .take(60)
            .map((w) => ActionChip(
                  label: Text(w.word,
                      style: const TextStyle(fontSize: 12)),
                  onPressed: () =>
                      ttsService.speak(w.word, ttsLang: ttsLang),
                  backgroundColor: color.withValues(alpha: 0.1),
                  labelStyle: TextStyle(color: color),
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  materialTapTargetSize:
                      MaterialTapTargetSize.shrinkWrap,
                ))
            .toList(),
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

      // Bar gradient feel — lighter top
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

      // Count on top of bar
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

      // Date label below
      final date = data[i]['date'] as DateTime;
      final label = switch (period) {
        _Period.day => '${date.day}/${date.month}',
        _Period.week => 'W${_isoWeek(date)}',
        _Period.month =>
          '${_monthAbbr(date.month)}/${date.year % 100}',
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
    tp.paint(
        canvas, Offset(centered ? x - tp.width / 2 : x, y));
  }

  int _isoWeek(DateTime d) {
    final startOfYear = DateTime(d.year, 1, 1);
    return ((d.difference(startOfYear).inDays) / 7).floor() + 1;
  }

  String _monthAbbr(int m) {
    const names = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return names[m - 1];
  }

  @override
  bool shouldRepaint(_BarChartPainter old) =>
      old.progress != progress ||
      old.data != data ||
      old.period != period;
}

class _DonutChartPainter extends CustomPainter {
  final double known;
  final double learning;
  final double newCount;

  const _DonutChartPainter({
    required this.known,
    required this.learning,
    required this.newCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final total = known + learning + newCount;
    if (total == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const stroke = 24.0;
    final rect =
        Rect.fromCircle(center: center, radius: radius - stroke / 2);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;

    double start = -pi / 2;
    void arc(double val, Color color) {
      if (val <= 0) return;
      final sweep = 2 * pi * val / total;
      paint.color = color;
      canvas.drawArc(rect, start, sweep - 0.03, false, paint);
      start += sweep;
    }

    arc(known, successGreen);
    arc(learning, warningOrange);
    arc(newCount, Colors.grey[300]!);

    // Center total
    final tp = TextPainter(
      text: TextSpan(
        text: '${total.toInt()}',
        style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Colors.black87),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas,
        center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(_DonutChartPainter old) =>
      old.known != known ||
      old.learning != learning ||
      old.newCount != newCount;
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
        padding:
            const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: color.withValues(alpha: 0.2), width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 15),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style:
                  TextStyle(color: Colors.grey[500], fontSize: 9),
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

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration:
              BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label,
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}
