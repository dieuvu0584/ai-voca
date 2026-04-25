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
  String _lastTestedKey = ''; // key đã test thành công

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
    // Dùng model của provider hiện tại, không dùng model cũ của provider khác
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

  Future<void> _save() async {
    final notifier = ref.read(aiSettingsProvider.notifier);
    await notifier.setApiKey(_keyController.text.trim());
    // Set mode userKey tại đây — Language 2 chỉ hiện sau khi user click Lưu
    await notifier.setMode(AIMode.userKey);
    final lang = ref.read(guiLangProvider);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(tr(lang, 'saved')), backgroundColor: successGreen),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(aiSettingsProvider);
    final lang = ref.watch(guiLangProvider);

    return Scaffold(
      appBar: AppBar(title: Text(tr(lang, 'ai_settings'))),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tr(lang, 'provider'),
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            DropdownButtonFormField<AIProvider>(
              initialValue: settings.provider,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
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
                }
              },
            ),
            const SizedBox(height: 16),

            Text(tr(lang, 'api_key'),
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _keyController,
              decoration: InputDecoration(
                hintText: tr(lang, 'enter_api_key'),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              obscureText: true,
              onChanged: (_) {
                // Reset trạng thái test khi key thay đổi
                if (_testResult != null) {
                  setState(() {
                    _testResult = null;
                    _testError = null;
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            Text(tr(lang, 'model'),
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: (() {
                final m = settings.model;
                final validModels = kAIModels[settings.provider] ?? [];
                // Nếu model hiện tại không thuộc provider này → dùng default
                if (m != null && validModels.contains(m)) return m;
                return validModels.isNotEmpty ? validModels.first : null;
              })(),
              decoration: InputDecoration(
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              items: (kAIModels[settings.provider] ?? [])
                  .map((m) =>
                      DropdownMenuItem(value: m, child: Text(m)))
                  .toList(),
              onChanged: (v) {
                if (v != null) {
                  ref.read(aiSettingsProvider.notifier).setModel(v);
                }
              },
            ),
            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _testing ? null : _testConnection,
                    icon: _testing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.power),
                    label: Text(tr(lang, 'test_connection')),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: (_testResult == true &&
                            _keyController.text.trim() == _lastTestedKey)
                        ? _save
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
                              color: _testResult! ? successGreen : errorRed,
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
      ),
    );
  }
}
