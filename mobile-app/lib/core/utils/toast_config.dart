import 'package:flutter/material.dart';

/// Supported toast message types.
enum ToastType { success, error, warning, info }

/// Immutable config resolved from a [ToastType].
class ToastConfig {
  final ToastType type;
  final String message;
  final String? title;
  final Duration duration;

  const ToastConfig({
    required this.type,
    required this.message,
    this.title,
    this.duration = const Duration(seconds: 3),
  });

  // ── Visual tokens ──────────────────────────────────────────────

  Color get accent {
    switch (type) {
      case ToastType.success:
        return const Color(0xFF22C55E); // green-500
      case ToastType.error:
        return const Color(0xFFEF4444); // red-500
      case ToastType.warning:
        return const Color(0xFFF59E0B); // amber-500
      case ToastType.info:
        return const Color(0xFF3B82F6); // blue-500
    }
  }

  Color get accentSoft {
    switch (type) {
      case ToastType.success:
        return const Color(0xFFDCFCE7);
      case ToastType.error:
        return const Color(0xFFFEE2E2);
      case ToastType.warning:
        return const Color(0xFFFEF3C7);
      case ToastType.info:
        return const Color(0xFFDBEAFE);
    }
  }

  IconData get icon {
    switch (type) {
      case ToastType.success:
        return Icons.check_circle_rounded;
      case ToastType.error:
        return Icons.error_rounded;
      case ToastType.warning:
        return Icons.warning_rounded;
      case ToastType.info:
        return Icons.info_rounded;
    }
  }

  String get defaultTitle {
    switch (type) {
      case ToastType.success:
        return 'Success';
      case ToastType.error:
        return 'Error';
      case ToastType.warning:
        return 'Warning';
      case ToastType.info:
        return 'Info';
    }
  }
}
