import 'dart:async';
import 'package:flutter/material.dart';
import 'toast_config.dart';
import 'toast_widget.dart';

/// Internal overlay controller — one instance per app.
///
/// Manages a queue of [ToastConfig] items and ensures only ONE toast
/// is visible at a time. Each toast slides up, holds, then slides out.
class ToastController {
  ToastController._();
  static final ToastController instance = ToastController._();

  bool _isShowing = false;
  final List<ToastConfig> _queue = [];

  void enqueue(ToastConfig config) {
    _queue.add(config);
    _processQueue();
  }

  void _processQueue() {
    if (_isShowing || _queue.isEmpty) return;
    _show(_queue.removeAt(0));
  }

  void _show(ToastConfig config) {
    final overlay = _overlayState;
    if (overlay == null) return;
    _isShowing = true;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => ToastWidget(
        config: config,
        onDismissed: () => _dismiss(entry),
      ),
    );

    overlay.insert(entry);
  }

  void _dismiss(OverlayEntry entry) {
    if (!entry.mounted) return;
    entry.remove();
    _isShowing = false;
    Future.delayed(const Duration(milliseconds: 120), _processQueue);
  }

  OverlayState? get _overlayState {
    try {
      return AppMessengerKeys.navigatorKey.currentState?.overlay;
    } catch (_) {
      return null;
    }
  }
}

/// Holds the navigator key that must be wired to [MaterialApp].
class AppMessengerKeys {
  AppMessengerKeys._();
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
  // Legacy ScaffoldMessenger key kept for backward compat with showSnackBar calls
  static final GlobalKey<ScaffoldMessengerState> messengerKey =
      GlobalKey<ScaffoldMessengerState>();
}
