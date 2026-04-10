import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers.dart';

class NetBadge extends ConsumerWidget {
  const NetBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(isOnlineProvider);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: isOnline
            ? const Color(0xFF27AE60).withValues(alpha: 0.15)
            : Colors.grey.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOnline ? Icons.wifi : Icons.wifi_off,
            size: 12,
            color: isOnline ? const Color(0xFF27AE60) : Colors.grey,
          ),
          const SizedBox(width: 3),
          Text(
            isOnline ? 'Online' : 'Offline',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isOnline ? const Color(0xFF27AE60) : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
