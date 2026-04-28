import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app.dart';
import '../../core/l10n/strings.dart';
import '../../core/providers.dart';
import '../../core/backup/backup_models.dart';

// ─────────────────────────────────────────────────────────────
// BackupScreen
// ─────────────────────────────────────────────────────────────
class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  bool _loading = false;
  String? _statusMessage;
  bool _statusIsError = false;
  DateTime? _lastBackupTime;

  @override
  void initState() {
    super.initState();
    _loadLastBackupTime();
  }

  Future<void> _loadLastBackupTime() async {
    final svc = ref.read(backupServiceProvider);
    final t = await svc.getLastBackupTime();
    if (mounted) setState(() => _lastBackupTime = t);
  }

  void _setStatus(String msg, {bool isError = false}) {
    setState(() {
      _statusMessage = msg;
      _statusIsError = isError;
    });
  }

  Future<void> _run(Future<BackupResult> Function() action) async {
    setState(() {
      _loading = true;
      _statusMessage = null;
    });
    try {
      final result = await action();
      if (!mounted) return;
      if (result.success) {
        final msg = result.wordCount != null
            ? '✓ ${result.wordCount} từ, ${result.progressCount} tiến trình'
            : '✓ Thành công';
        _setStatus(msg);
        await _loadLastBackupTime();
      } else {
        _setStatus(result.error ?? 'Lỗi không xác định', isError: true);
      }
    } catch (e) {
      if (mounted) _setStatus(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Sign In ────────────────────────────────────────────────

  Future<void> _signIn() async {
    setState(() => _loading = true);
    try {
      final authSvc = ref.read(authServiceProvider);
      final result = await authSvc.signInWithGoogle();
      if (result == null && mounted) {
        _setStatus('Đăng nhập bị huỷ', isError: true);
      }
    } catch (e) {
      if (mounted) _setStatus(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đăng xuất?'),
        content: const Text(
            'Dữ liệu local vẫn giữ nguyên. Bạn có thể đăng nhập lại bất kỳ lúc nào.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Huỷ')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Đăng xuất')),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(authServiceProvider).signOut();
    setState(() => _statusMessage = null);
  }

  // ── Build ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(guiLangProvider);
    final authState = ref.watch(authStateProvider);
    final firebaseReady = ref.watch(firebaseReadyProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(tr(lang, 'backup_sync')),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Firebase not configured warning
              if (!firebaseReady) _buildNotConfiguredBanner(),

              // Auth section
              authState.when(
                data: (user) => user != null
                    ? _buildSignedIn(user, lang)
                    : _buildSignedOut(lang, firebaseReady),
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (e, _) => _buildSignedOut(lang, firebaseReady),
              ),

              // Divider
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(),
              ),

              // Local Backup section
              _buildSectionHeader('Backup thủ công (offline)'),
              const SizedBox(height: 8),
              _buildLocalActions(lang),

              // Status message
              if (_statusMessage != null) ...[
                const SizedBox(height: 16),
                _buildStatusBanner(),
              ],

              const SizedBox(height: 32),
            ],
          ),
          if (_loading)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  // ── Sections ───────────────────────────────────────────────

  Widget _buildNotConfiguredBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: warningOrange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: warningOrange.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: warningOrange),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Cloud sync chưa cấu hình',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  'Chạy flutterfire configure để kích hoạt. '
                  'Bạn vẫn có thể dùng backup JSON local.',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignedOut(String lang, bool firebaseReady) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Đồng bộ đám mây'),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(20),
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
          child: Column(
            children: [
              const Icon(Icons.cloud_outlined, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              const Text(
                'Đăng nhập để đồng bộ dữ liệu',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                'Bảo vệ tiến trình học giữa các thiết bị',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: firebaseReady ? _signIn : null,
                  icon: Image.asset(
                    'assets/icon_source.png',
                    width: 20,
                    height: 20,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.login, size: 20),
                  ),
                  label: const Text('Đăng nhập với Google'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    elevation: 1,
                    side: const BorderSide(color: Colors.grey),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSignedIn(User user, String lang) {
    final backupSvc = ref.read(backupServiceProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Đồng bộ đám mây'),
        const SizedBox(height: 8),

        // User info card
        Container(
          padding: const EdgeInsets.all(16),
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
              CircleAvatar(
                radius: 22,
                backgroundImage: user.photoURL != null
                    ? NetworkImage(user.photoURL!)
                    : null,
                child: user.photoURL == null
                    ? Text(
                        (user.displayName ?? user.email ?? 'U')[0]
                            .toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName ?? 'User',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      user.email ?? '',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    if (_lastBackupTime != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Sao lưu lần cuối: ${_formatTime(_lastBackupTime!)}',
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      ),
                    ],
                  ],
                ),
              ),
              TextButton(
                onPressed: _signOut,
                child: const Text('Đăng xuất'),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Cloud actions
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                icon: Icons.cloud_upload_outlined,
                label: 'Sao lưu lên cloud',
                color: successGreen,
                onTap: () => _run(() => backupSvc.syncToCloud()),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionButton(
                icon: Icons.cloud_download_outlined,
                label: 'Khôi phục từ cloud',
                color: const Color(0xFF3B82F6),
                onTap: () => _confirmRestore(
                    () => backupSvc.restoreFromCloud()),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLocalActions(String lang) {
    final backupSvc = ref.read(backupServiceProvider);
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            icon: Icons.upload_file_outlined,
            label: 'Xuất file JSON',
            color: warningOrange,
            onTap: () => _run(() => backupSvc.exportToJson()),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionButton(
            icon: Icons.download_outlined,
            label: 'Nhập từ file JSON',
            color: const Color(0xFF8B5CF6),
            onTap: () => _confirmRestore(() => backupSvc.importFromJson()),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _statusIsError
            ? errorRed.withValues(alpha: 0.1)
            : successGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _statusIsError
              ? errorRed.withValues(alpha: 0.3)
              : successGreen.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _statusIsError ? Icons.error_outline : Icons.check_circle_outline,
            color: _statusIsError ? errorRed : successGreen,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _statusMessage!,
              style: TextStyle(
                color: _statusIsError ? errorRed : successGreen,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Colors.grey,
        letterSpacing: 0.8,
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────

  Future<void> _confirmRestore(
      Future<BackupResult> Function() action) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Khôi phục dữ liệu?'),
        content: const Text(
          'Dữ liệu từ backup sẽ được merge với dữ liệu hiện tại. '
          'Tiến trình học tốt hơn sẽ được giữ lại.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Huỷ'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Khôi phục'),
          ),
        ],
      ),
    );
    if (confirmed == true) _run(action);
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'vừa xong';
    if (diff.inHours < 1) return '${diff.inMinutes} phút trước';
    if (diff.inDays < 1) return '${diff.inHours} giờ trước';
    return DateFormat('dd/MM/yyyy HH:mm').format(dt);
  }
}

// ─────────────────────────────────────────────────────────────
// _ActionButton
// ─────────────────────────────────────────────────────────────
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
