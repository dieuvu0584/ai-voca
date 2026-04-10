import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app.dart';
import '../../core/ai/ai_service.dart';
import '../../core/ai/ai_settings.dart';

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
    setState(() {
      _testing = true;
      _testResult = null;
    });

    final settings = ref.read(aiSettingsProvider);
    final service = createAIService(
      provider: settings.provider,
      apiKey: _keyController.text.trim(),
      model: settings.model,
    );

    if (service != null) {
      final result = await service.testConnection();
      if (mounted) {
        setState(() {
          _testing = false;
          _testResult = result;
        });
      }
    } else {
      setState(() {
        _testing = false;
        _testResult = false;
      });
    }
  }

  Future<void> _save() async {
    final notifier = ref.read(aiSettingsProvider.notifier);
    await notifier.setApiKey(_keyController.text.trim());

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Da luu!'), backgroundColor: successGreen),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(aiSettingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Cai dat AI')),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Provider',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            DropdownButtonFormField<AIProvider>(
              value: settings.provider,
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

            const Text('API Key',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _keyController,
              decoration: InputDecoration(
                hintText: 'Nhap API key...',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),

            const Text('Model',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: settings.model ??
                  (kAIModels[settings.provider]?.first),
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
                    label: const Text('Test ket noi'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.save),
                    label: const Text('Luu'),
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
                  children: [
                    Icon(
                      _testResult! ? Icons.check_circle : Icons.error,
                      color: _testResult! ? successGreen : errorRed,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _testResult!
                          ? 'Ket noi thanh cong!'
                          : 'Ket noi that bai. Kiem tra lai API key.',
                      style: TextStyle(
                        color: _testResult! ? successGreen : errorRed,
                        fontWeight: FontWeight.w500,
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
