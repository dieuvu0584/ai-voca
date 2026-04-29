import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app.dart';
import '../../core/ai/ai_service.dart';
import '../../core/ai/ai_settings.dart';
import '../../core/providers.dart';
import '../../core/l10n/strings.dart';

class AISettingsDetailScreen extends ConsumerStatefulWidget {
  const AISettingsDetailScreen({super.key});

  @override
  ConsumerState<AISettingsDetailScreen> createState() =>
      _AISettingsDetailScreenState();
}

class _AISettingsDetailScreenState
    extends ConsumerState<AISettingsDetailScreen> {
  final _keyController = TextEditingController();
  bool _testing = false;
  bool? _testResult;
  String? _testError;
  String _lastTestedKey = '';

  @override
  void initState() {
    super.initState();
    final settings = ref.read(aiSettingsProvider);
    if (settings.apiKey != null) {
      _keyController.text = settings.apiKey!;
    }
  }

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    final apiKey = _keyController.text.trim();
    if (apiKey.isEmpty) return;

    setState(() {
      _testing = true;
      _testResult = null;
      _testError = null;
    });

    final settings = ref.read(aiSettingsProvider);
    final model = settings.model ?? kAIModels[settings.provider]?.first;
    final service = createAIService(
      provider: settings.provider,
      apiKey: apiKey,
      model: model,
    );

    if (service != null) {
      final result = await service.testConnection();
      if (mounted) {
        setState(() {
          _testing = false;
          _testResult = result;
          if (result) {
            _lastTestedKey = apiKey;
          } else {
            _testError =
                'Provider: ${kAIProviderNames[settings.provider]}\n'
                'Model: ${model ?? "default"}\n'
                'Kiểm tra: API key, quota, và kết nối mạng.';
          }
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _testing = false;
          _testResult = false;
          _testError = 'Không tạo được service. API key rỗng?';
        });
      }
    }
  }

  Future<void> _saveUserKey() async {
    final notifier = ref.read(aiSettingsProvider.notifier);
    await notifier.setApiKey(_keyController.text.trim());
    await notifier.setMode(AIMode.userKey);
    final lang = ref.read(guiLangProvider);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr(lang, 'saved')), backgroundColor: successGreen),
      );
    }
  }

  Future<void> _useAppDefault() async {
    await ref.read(aiSettingsProvider.notifier).setMode(AIMode.appDefault);
    final lang = ref.read(guiLangProvider);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã chuyển sang AI mặc định của app'),
          backgroundColor: Color(0xFF7C3AED),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(aiSettingsProvider);
    final lang = ref.watch(guiLangProvider);
    final firebaseReady = ref.watch(firebaseReadyProvider);
    final isAppDefault = settings.mode == AIMode.appDefault;

    return Scaffold(
      appBar: AppBar(title: Text(tr(lang, 'ai_settings'))),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Section 1: AI mặc định của app ──────────────
              _SectionCard(
                selected: isAppDefault,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.auto_awesome_rounded,
                              color: Color(0xFF7C3AED), size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'AI mặc định (của app)',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 15),
                              ),
                              Text(
                                firebaseReady
                                    ? 'Dùng Claude — miễn phí, không cần API key'
                                    : 'Chưa kết nối Firebase',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: firebaseReady
                                      ? Colors.green.shade700
                                      : Colors.orange.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isAppDefault)
                          const Icon(Icons.check_circle_rounded,
                              color: Color(0xFF7C3AED)),
                      ],
                    ),
                    if (!isAppDefault) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: firebaseReady ? _useAppDefault : null,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF7C3AED)),
                            foregroundColor: const Color(0xFF7C3AED),
                          ),
                          child: const Text('Dùng AI của app'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ── Section 2: API key riêng ─────────────────────
              _SectionCard(
                selected: settings.mode == AIMode.userKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            aiProviderIcon(settings.provider),
                            color: aiProviderColor(settings.provider),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'API key của bạn',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 15),
                              ),
                              const Text(
                                'Dùng key riêng — không giới hạn lượt dùng',
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        if (settings.mode == AIMode.userKey)
                          Icon(Icons.check_circle_rounded,
                              color: aiProviderColor(settings.provider)),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Provider
                    Text(tr(lang, 'provider'),
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<AIProvider>(
                      value: settings.provider,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                      ),
                      items: AIProvider.values
                          .map((p) => DropdownMenuItem(
                                value: p,
                                child: Text(kAIProviderNames[p] ?? p.name),
                              ))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) {
                          ref.read(aiSettingsProvider.notifier).setProvider(v);
                          _keyController.clear();
                          setState(() {
                            _testResult = null;
                            _testError = null;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),

                    // API Key
                    Text(tr(lang, 'api_key'),
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _keyController,
                      decoration: InputDecoration(
                        hintText: tr(lang, 'enter_api_key'),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                      ),
                      obscureText: true,
                      onChanged: (_) {
                        if (_testResult != null) {
                          setState(() {
                            _testResult = null;
                            _testError = null;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),

                    // Model
                    Text(tr(lang, 'model'),
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: (() {
                        final m = settings.model;
                        final validModels = kAIModels[settings.provider] ?? [];
                        if (m != null && validModels.contains(m)) return m;
                        return validModels.isNotEmpty ? validModels.first : null;
                      })(),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                      ),
                      items: (kAIModels[settings.provider] ?? [])
                          .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) {
                          ref.read(aiSettingsProvider.notifier).setModel(v);
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _testing ? null : _testConnection,
                            icon: _testing
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2))
                                : const Icon(Icons.power),
                            label: Text(tr(lang, 'test_connection')),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: (_testResult == true &&
                                    _keyController.text.trim() == _lastTestedKey)
                                ? _saveUserKey
                                : null,
                            icon: const Icon(Icons.save),
                            label: Text(tr(lang, 'save')),
                            style: ElevatedButton.styleFrom(
                              disabledBackgroundColor: Colors.grey.shade200,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Test result
                    if (_testResult != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _testResult!
                              ? successGreen.withValues(alpha: 0.1)
                              : errorRed.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              _testResult! ? Icons.check_circle : Icons.error,
                              color: _testResult! ? successGreen : errorRed,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _testResult!
                                        ? tr(lang, 'connection_success')
                                        : tr(lang, 'connection_failed'),
                                    style: TextStyle(
                                      color:
                                          _testResult! ? successGreen : errorRed,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (!_testResult! && _testError != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      _testError!,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: errorRed.withValues(alpha: 0.8),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ── Section 3: Tắt AI ─────────────────────────────
              if (settings.mode != AIMode.none)
                Center(
                  child: TextButton.icon(
                    onPressed: () async {
                      await ref
                          .read(aiSettingsProvider.notifier)
                          .setMode(AIMode.none);
                    },
                    icon: const Icon(Icons.power_off_outlined,
                        color: Colors.grey),
                    label: const Text('Tắt AI',
                        style: TextStyle(color: Colors.grey)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Card wrapper với border highlight khi được chọn
class _SectionCard extends StatelessWidget {
  final bool selected;
  final Widget child;

  const _SectionCard({required this.selected, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected
              ? const Color(0xFF7C3AED).withValues(alpha: 0.6)
              : Colors.grey.shade200,
          width: selected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}
