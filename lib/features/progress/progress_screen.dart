import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app.dart';
import '../../core/providers.dart';
import '../../core/db/database.dart';

class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  int _studiedToday = 0;
  List<WordProgressData> _known = [];
  List<WordProgressData> _learning = [];
  List<WordProgressData> _newWords = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final langCode = ref.read(languageProvider).primary.code;
    final progressDao = ref.read(progressDaoProvider);

    final studiedToday = await progressDao.wordsStudiedToday(langCode);
    final known = await progressDao.getKnownWords(langCode);
    final learning = await progressDao.getLearningWords(langCode);
    final newWords = await progressDao.getNewWords(langCode, limit: 100);

    setState(() {
      _studiedToday = studiedToday;
      _known = known;
      _learning = learning;
      _newWords = newWords;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final langState = ref.watch(languageProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Tien do')),
      body: SafeArea(
        top: false,
        child: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStats,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stats cards
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.4,
                      children: [
                        _StatCard(
                          label: 'Hoc hom nay',
                          value: '$_studiedToday',
                          icon: Icons.today,
                          color: enColor,
                        ),
                        _StatCard(
                          label: 'Da nho',
                          value: '${_known.length}',
                          icon: Icons.check_circle,
                          color: successGreen,
                        ),
                        _StatCard(
                          label: 'Can on',
                          value: '${_learning.length}',
                          icon: Icons.replay,
                          color: warningOrange,
                        ),
                        _StatCard(
                          label: 'Chua hoc',
                          value: '${_newWords.length}',
                          icon: Icons.menu_book,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Per language section
                    Text(
                      '${langState.primary.flag} ${langState.primary.name}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: enColor,
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (_known.isNotEmpty) ...[
                      const Text('Da nho',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: successGreen)),
                      const SizedBox(height: 8),
                      _buildWordChips(_known, successGreen),
                      const SizedBox(height: 16),
                    ],

                    if (_learning.isNotEmpty) ...[
                      const Text('Can on',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: warningOrange)),
                      const SizedBox(height: 8),
                      _buildWordChips(_learning, warningOrange),
                      const SizedBox(height: 16),
                    ],

                    if (_newWords.isNotEmpty) ...[
                      const Text('Chua hoc',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, color: enColor)),
                      const SizedBox(height: 8),
                      _buildWordChips(_newWords, enColor),
                    ],
                  ],
                ),
              ),
            ),
      ),
    );
  }

  Widget _buildWordChips(List<WordProgressData> words, Color color) {
    final ttsService = ref.read(ttsServiceProvider);
    final ttsLang = ref.read(languageProvider).primary.ttsLang;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: words
          .map((w) => ActionChip(
                label: Text(w.word),
                onPressed: () =>
                    ttsService.speak(w.word, ttsLang: ttsLang),
                backgroundColor: color.withValues(alpha: 0.1),
                labelStyle: TextStyle(color: color),
              ))
          .toList(),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: color),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                  fontSize: 24, fontWeight: FontWeight.w800, color: color),
            ),
            Text(label,
                style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          ],
        ),
      ),
    );
  }
}
