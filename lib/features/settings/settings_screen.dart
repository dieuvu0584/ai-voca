import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app.dart';
import '../../core/ai/ai_service.dart';
import '../../core/ai/ai_settings.dart';
import '../../core/l10n/strings.dart';
import '../../core/premium/premium_notifier.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../data/languages.dart';
import '../../features/premium/paywall_screen.dart';
import '../../widgets/lang_picker_sheet.dart';
import 'ai_settings_screen.dart';
import 'notification_settings.dart';

// ─────────────────────────────────────────────────────────────
// GUI languages được hỗ trợ trong picker
// ─────────────────────────────────────────────────────────────
const _kGuiLangCodes = [
  'vi-VN', 'en-US', 'ko-KR', 'ja-JP', 'zh-CN',
  'zh-TW', 'fr-FR', 'de-DE', 'es-ES', 'it-IT',
  'pt-BR', 'ru-RU', 'th-TH', 'ar-SA', 'hi-IN',
  'id-ID', 'nl-NL', 'tr-TR', 'ms-MY',
];

final _kGuiLangs = _kGuiLangCodes.map((c) => findLanguage(c)).toList();

// ─────────────────────────────────────────────────────────────
// SettingsScreen
// ─────────────────────────────────────────────────────────────
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  int _autoRunSeconds = 5;
  bool _autoRunTTS = true;
  int _sessionWordCount = 50;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _autoRunSeconds = prefs.getInt('auto_run_seconds') ?? 5;
      _autoRunTTS = prefs.getBool('auto_run_tts') ?? true;
      _sessionWordCount = prefs.getInt('session_word_count') ?? 50;
    });
  }

  // ── Build ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(guiLangProvider);
    final isPremium = ref.watch(effectivePremiumProvider);
    final aiSettings = ref.watch(aiSettingsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(tr(lang, 'settings'))),
      body: SafeArea(
        top: false,
        child: ListView(
          children: [
            // 1. Premium Banner
            _buildPremiumBanner(lang, isPremium),

            const Divider(height: 1),

            // 2. GUI Language
            _buildGuiLangPicker(lang),

            const SizedBox(height: 8),
            const Divider(height: 1),

            // 3. Theme Picker
            _buildThemePicker(lang),

            const Divider(height: 1),

            // 4. AI Mode
            _buildSectionHeader(context, tr(lang, 'ai_assistant')),
            _buildAIModeCards(lang, aiSettings),

            const Divider(height: 1),

            // 5. Language Settings
            _buildSectionHeader(context, tr(lang, 'study_language')),
            _buildLanguage1Picker(lang),
            if (aiSettings.mode != AIMode.none) ...[
              const SizedBox(height: 8),
              _buildLanguage2Picker(lang),
            ],

            const SizedBox(height: 8),
            const Divider(height: 1),

            // 6. Kho từ vựng
            _buildSectionHeader(context, tr(lang, 'vocab_library')),
            _VocabLibrarySection(lang: lang),

            const Divider(height: 1),

            // 7. Tự động chạy từ vựng
            _buildSectionHeader(context, tr(lang, 'auto_run_vocab')),
            _buildAutoRunSection(lang),

            const Divider(height: 1),

            // 8. Notifications
            _buildSectionHeader(context, tr(lang, 'notifications')),
            ListTile(
              leading: const Icon(Icons.notifications_outlined),
              title: Text(tr(lang, 'study_reminder')),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const NotificationSettingsScreen()),
              ),
            ),

            const Divider(height: 1),

            // 9. About
            _buildSectionHeader(context, tr(lang, 'about')),
            _buildAboutSection(lang),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ── Section 1: Premium Banner ──────────────────────────────

  Widget _buildPremiumBanner(String lang, bool isPremium) {
    // Đã mua Premium thật
    if (ref.read(premiumProvider)) {
      return ListTile(
        leading: const Icon(Icons.workspace_premium_rounded,
            color: Colors.amber, size: 28),
        title: Text(tr(lang, 'premium_active'),
            style: const TextStyle(fontWeight: FontWeight.w600)),
        tileColor: Colors.amber.withValues(alpha: 0.07),
      );
    }

    // Đang trong promo 90 ngày
    if (isPromoActive) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF10B981), Color(0xFF059669)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF10B981).withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.celebration_rounded,
                color: Colors.white, size: 32),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr(lang, 'promo_banner_title'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tr(lang, 'promo_banner_days')
                        .replaceAll('{days}', '$promoDaysLeft'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: () => PaywallScreen.show(context, ref),
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFF59E0B), Color(0xFFEA580C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.workspace_premium_rounded,
                color: Colors.white, size: 32),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr(lang, 'premium_title'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tr(lang, 'premium_subtitle'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                tr(lang, 'premium_upgrade_btn'),
                style: const TextStyle(
                  color: Color(0xFFEA580C),
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Section 2: GUI Language Picker ────────────────────────

  Widget _buildGuiLangPicker(String lang) {
    final cs = appColors(context);
    final current = _kGuiLangs.firstWhere(
      (e) => e.code == lang,
      orElse: () => _kGuiLangs.first,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, tr(lang, 'gui_language')),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _showGuiLangSheet(lang),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Text(current.flag, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 12),
                  Text(
                    current.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.arrow_drop_down, color: cs.primary),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showGuiLangSheet(String currentLang) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _GuiLangPickerSheet(
        currentLang: currentLang,
        onSelect: (code) {
          ref.read(guiLangProvider.notifier).setLang(code);
        },
      ),
    );
  }

  // ── Section 3: Theme Picker ────────────────────────────────

  Widget _buildThemePicker(String lang) {
    final currentThemeId = ref.watch(appThemeProvider);
    final cs = appColors(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr(lang, 'theme').toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: kAppThemes.map((preset) {
              final isSelected = currentThemeId == preset.id;

              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    ref
                        .read(appThemeProvider.notifier)
                        .setTheme(preset.id);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: preset.swatch,
                                shape: BoxShape.circle,
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: preset.swatch
                                              .withValues(alpha: 0.5),
                                          blurRadius: 8,
                                          spreadRadius: 1,
                                        ),
                                      ]
                                    : null,
                                border: isSelected
                                    ? Border.all(
                                        color: cs.primary,
                                        width: 2.5,
                                      )
                                    : null,
                              ),
                            ),
                            if (isSelected)
                              const Icon(Icons.check,
                                  color: Colors.white, size: 16),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── Section 4: Definition Language Picker ─────────────────

  // ── Language 1 & 2 pickers ────────────────────────────────

  Widget _buildLanguage1Picker(String lang) {
    final primary = ref.watch(languageProvider).primary;
    final cs = appColors(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          builder: (_) => const LangPickerSheet(isPrimary: true),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2))
            ],
          ),
          child: Row(
            children: [
              Text(primary.flag, style: const TextStyle(fontSize: 26)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tr(lang, 'language_1_label'),
                        style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                    const SizedBox(height: 2),
                    Text(primary.name,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: cs.primary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguage2Picker(String lang) {
    final langState = ref.watch(languageProvider);
    final secondary = langState.secondary;
    final cs = appColors(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showLanguage2Sheet(lang),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2))
            ],
          ),
          child: Row(
            children: [
              secondary != null
                  ? Text(secondary.flag, style: const TextStyle(fontSize: 26))
                  : Icon(Icons.add_circle_outline,
                      size: 26, color: Colors.grey[400]),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tr(lang, 'language_2_label'),
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey[500])),
                    const SizedBox(height: 2),
                    Text(
                      secondary?.name ?? tr(lang, 'add_secondary_lang'),
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: secondary == null ? Colors.grey[400] : null),
                    ),
                  ],
                ),
              ),
              if (secondary != null) ...[
                GestureDetector(
                  onTap: () => _clearLanguage2(),
                  child: Icon(Icons.close, size: 18, color: Colors.grey[400]),
                ),
                const SizedBox(width: 8),
              ],
              Icon(Icons.chevron_right, color: cs.secondary),
            ],
          ),
        ),
      ),
    );
  }

  void _showLanguage2Sheet(String lang) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const LangPickerSheet(isPrimary: false),
    ).then((_) {
      // Sync defLang theo secondary language vừa chọn
      final secondary = ref.read(languageProvider).secondary;
      if (secondary != null) {
        ref.read(defLangPrimaryProvider.notifier).setLang(secondary.code);
      }
    });
  }

  void _clearLanguage2() {
    ref.read(languageProvider.notifier).setSecondary(null);
    ref.read(defLangPrimaryProvider.notifier).setLang('en-US');
  }


  // ── Section 6: AI Mode Cards ───────────────────────────────

  Widget _buildAIModeCards(String lang, AISettings aiSettings) {
    final cs = appColors(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // None / Offline
          _AIModeCard(
            title: tr(lang, 'ai_none'),
            subtitle: tr(lang, 'ai_none_sub'),
            badge: tr(lang, 'offline'),
            badgeColor: Colors.grey,
            isSelected: aiSettings.mode == AIMode.none,
            onTap: () =>
                ref.read(aiSettingsProvider.notifier).setMode(AIMode.none),
          ),
          const SizedBox(height: 8),

          // User API Key — luôn luôn miễn phí
          _AIModeCard(
            title: tr(lang, 'ai_user_key'),
            subtitle: tr(lang, 'ai_user_key_sub'),
            isSelected: aiSettings.mode == AIMode.userKey,
            onTap: () {
              // KHÔNG set mode ở đây — chỉ set sau khi user click Lưu trong màn hình Trợ lý AI
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const AISettingsDetailScreen()),
              );
            },
            trailing: aiSettings.mode == AIMode.userKey
                ? IconButton(
                    icon: Icon(Icons.settings, size: 20, color: cs.primary),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AISettingsDetailScreen()),
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ── Section 7: Tự động chạy từ vựng ────────────────────────

  Widget _buildAutoRunSection(String lang) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.format_list_numbered_rounded),
          title: Text(tr(lang, 'session_word_count')),
          trailing: DropdownButton<int>(
            value: _sessionWordCount,
            underline: const SizedBox(),
            items: [10, 20, 30, 50, 75, 100]
                .map((s) => DropdownMenuItem(
                    value: s, child: Text('$s ${tr(lang, 'words_unit')}')))
                .toList(),
            onChanged: (v) async {
              if (v == null) return;
              final prefs = await SharedPreferences.getInstance();
              await prefs.setInt('session_word_count', v);
              if (!mounted) return;
              setState(() => _sessionWordCount = v);
            },
          ),
        ),
        SwitchListTile(
          secondary: const Icon(Icons.volume_up_outlined),
          title: Text(tr(lang, 'auto_run_tts')),
          value: _autoRunTTS,
          onChanged: (v) async {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('auto_run_tts', v);
            if (!mounted) return;
            setState(() => _autoRunTTS = v);
          },
        ),
        ListTile(
          leading: const Icon(Icons.timer_outlined),
          title: Text(tr(lang, 'auto_run_delay')),
          trailing: DropdownButton<int>(
            value: _autoRunSeconds,
            underline: const SizedBox(),
            items: [3, 5, 8, 10, 15]
                .map((s) => DropdownMenuItem(
                    value: s, child: Text('$s ${tr(lang, 'seconds')}')))
                .toList(),
            onChanged: (v) async {
              if (v == null) return;
              final prefs = await SharedPreferences.getInstance();
              await prefs.setInt('auto_run_seconds', v);
              if (!mounted) return;
              setState(() => _autoRunSeconds = v);
            },
          ),
        ),
      ],
    );
  }

  // ── Section 9: About ──────────────────────────────────────

  Widget _buildAboutSection(String lang) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: Text(tr(lang, 'version')),
          trailing: const Text(
            '1.0.0',
            style: TextStyle(color: Colors.grey),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.code_rounded),
          title: Text(tr(lang, 'developed_by')),
          trailing: const Text(
            'SMA',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }


  // ── Helpers ────────────────────────────────────────────────

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.grey,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// _VocabLibrarySection — StatefulWidget riêng
// ─────────────────────────────────────────────────────────────
class _VocabLibrarySection extends ConsumerStatefulWidget {
  final String lang;
  const _VocabLibrarySection({required this.lang});

  @override
  ConsumerState<_VocabLibrarySection> createState() =>
      _VocabLibrarySectionState();
}

class _VocabLibrarySectionState extends ConsumerState<_VocabLibrarySection> {
  bool _autoFetch = true;
  int _wordCount = 0;  // tổng từ trong DB
  int _studiedCount = 0; // từ đã học (status != 'new')

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final langCode = ref.read(languageProvider).primary.code;
    final wordDao = ref.read(wordDaoProvider);

    final count = await wordDao.countWordsForLang(langCode);
    final studiedCount = await ref.read(progressDaoProvider).countStudiedWords(langCode);
    if (!mounted) return;
    setState(() {
      _autoFetch = prefs.getBool('vocab_auto_fetch') ?? true;
      _wordCount = count;
      _studiedCount = studiedCount; // đếm trực tiếp từ progress table, tránh lỗi từ không có record
    });
  }

  Future<void> _showResetProgressDialog() async {
    final lang = widget.lang;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr(lang, 'confirm_title')),
        content: Text(tr(lang, 'reset_progress_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr(lang, 'cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: errorRed),
            child: Text(tr(lang, 'reset_progress')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final langCode = ref.read(languageProvider).primary.code;
    await ref.read(progressDaoProvider).resetAllProgress(langCode);

    // Reset vocab offset để fetch lại từ đầu
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('vocab_offset_$langCode');

    if (!mounted) return;
    // Trigger reload stats trên homepage
    ref.read(statsRefreshProvider.notifier).update((s) => s + 1);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(tr(lang, 'reset_progress_done'))),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.lang;
    // Reload stats khi primary language thay đổi
    ref.listen(languageProvider, (prev, next) {
      if (prev?.primary.code != next.primary.code) _load();
    });
    final cs = appColors(context);
    // Tỷ lệ đã học / tổng từ trong kho
    final progress = _wordCount > 0
        ? (_studiedCount / _wordCount).clamp(0.0, 1.0)
        : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hàng hiển thị: [icon] N từ    [đã học / tổng]
          Row(
            children: [
              Icon(Icons.library_books_rounded, size: 20, color: cs.primary),
              const SizedBox(width: 8),
              Text(
                '$_wordCount ${tr(lang, 'words_short')}',
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 16),
              ),
              const Spacer(),
              _StatBadge(
                label: '$_studiedCount / $_wordCount',
                color: cs.primary,
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Thanh tiến trình học
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: cs.primary.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
            ),
          ),
          const SizedBox(height: 12),


          // Auto-fetch switch
          SwitchListTile(
            title: Text(tr(lang, 'auto_fetch')),
            value: _autoFetch,
            contentPadding: EdgeInsets.zero,
            onChanged: (v) async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('vocab_auto_fetch', v);
              if (!mounted) return;
              setState(() => _autoFetch = v);
            },
          ),

          // Nút học lại từ đầu (reset progress)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _showResetProgressDialog,
              icon: const Icon(Icons.restart_alt_rounded),
              label: Text(tr(lang, 'reset_progress')),
            ),
          ),
          const SizedBox(height: 8),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// _AIModeCard
// ─────────────────────────────────────────────────────────────
class _AIModeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? badge;
  final Color badgeColor;
  final bool isSelected;
  final VoidCallback onTap;
  final Widget? trailing;

  const _AIModeCard({
    required this.title,
    required this.subtitle,
    this.badge,
    this.badgeColor = Colors.grey,
    required this.isSelected,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final cs = appColors(context);

    return Card(
      elevation: isSelected ? 2 : 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? cs.primary : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(
                isSelected
                    ? Icons.radio_button_on
                    : Icons.radio_button_off,
                color: isSelected ? cs.primary : Colors.grey,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style:
                            const TextStyle(fontWeight: FontWeight.w600)),
                    Text(subtitle,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
              ),
              if (trailing != null) ...[
                trailing!,
                const SizedBox(width: 4),
              ],
              if (badge != null)
                _StatBadge(label: badge!, color: badgeColor),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// _StatBadge — nhỏ gọn với background màu nhạt
// ─────────────────────────────────────────────────────────────
class _StatBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// _GuiLangPickerSheet — bottom sheet chọn ngôn ngữ giao diện
// ─────────────────────────────────────────────────────────────
class _GuiLangPickerSheet extends StatefulWidget {
  final String currentLang;
  final ValueChanged<String> onSelect;

  const _GuiLangPickerSheet({
    required this.currentLang,
    required this.onSelect,
  });

  @override
  State<_GuiLangPickerSheet> createState() => _GuiLangPickerSheetState();
}

class _GuiLangPickerSheetState extends State<_GuiLangPickerSheet> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final cs = appColors(context);
    final filtered = _kGuiLangs.where((e) {
      final q = _search.toLowerCase();
      return e.name.toLowerCase().contains(q) ||
          e.native.toLowerCase().contains(q) ||
          e.code.toLowerCase().contains(q);
    }).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.85,
      minChildSize: 0.35,
      expand: false,
      builder: (_, scrollController) => Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: tr(widget.currentLang, 'search_language'),
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              itemCount: filtered.length,
              itemBuilder: (_, i) {
                final l = filtered[i];
                final isSelected = l.code == widget.currentLang;

                return ListTile(
                  leading: Text(l.flag, style: const TextStyle(fontSize: 28)),
                  title: Text(
                    l.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isSelected ? cs.primary : null,
                    ),
                  ),
                  subtitle: Text(l.native),
                  trailing: isSelected
                      ? Icon(Icons.check_circle, color: cs.primary)
                      : null,
                  onTap: () {
                    widget.onSelect(l.code);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

