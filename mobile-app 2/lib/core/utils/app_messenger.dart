import 'package:flutter/material.dart';
import 'toast_config.dart';
import 'toast_controller.dart';

/// Global singleton message/toast manager.
///
/// ─── API (identical to the old implementation) ───────────────────
///   AppMessenger.showSuccess('Post created!');
///   AppMessenger.showError('Failed to load.');
///   AppMessenger.showWarning('Check your connection.');
///   AppMessenger.showInfo('Request sent.');
///   AppMessenger.show(type: ToastType.success, message: '…');
///
/// ─── Setup (in main.dart) ────────────────────────────────────────
///   MaterialApp(
///     navigatorKey: AppMessenger.navigatorKey,
///     scaffoldMessengerKey: AppMessenger.messengerKey,   // kept for compat
///     …
///   )
///
/// All calls are safe to make from any isolate-aware async function,
/// providers, repositories, socket handlers — anywhere.
class AppMessenger {
  AppMessenger._();

  // ── Keys wired into MaterialApp ────────────────────────────────

  /// Must be passed to [MaterialApp.navigatorKey].
  static GlobalKey<NavigatorState> get navigatorKey =>
      AppMessengerKeys.navigatorKey;

  /// Kept for backward compatibility with legacy [showSnackBar] calls.
  static GlobalKey<ScaffoldMessengerState> get messengerKey =>
      AppMessengerKeys.messengerKey;

  // ── Primary API ────────────────────────────────────────────────

  static void showSuccess(String message, {String? title, Duration? duration}) {
    show(
      type: ToastType.success,
      message: message,
      title: title,
      duration: duration,
    );
  }

  static void showError([
    String message = 'Something went wrong. Please try again.',
    String? title,
    Duration? duration,
  ]) {
    show(
      type: ToastType.error,
      message: message,
      title: title,
      duration: duration,
    );
  }

  static void showWarning(String message, {String? title, Duration? duration}) {
    show(
      type: ToastType.warning,
      message: message,
      title: title,
      duration: duration,
    );
  }

  static void showInfo(String message, {String? title, Duration? duration}) {
    show(
      type: ToastType.info,
      message: message,
      title: title,
      duration: duration,
    );
  }

  /// Generic entry point — accepts any [ToastType].
  static void show({
    required ToastType type,
    required String message,
    String? title,
    Duration? duration,
  }) {
    ToastController.instance.enqueue(
      ToastConfig(
        type: type,
        message: message,
        title: title,
        duration: duration ?? const Duration(seconds: 3),
      ),
    );
  }

  // ── Legacy shim ────────────────────────────────────────────────
  // Kept so callers that use showSnackBar(SnackBar(…)) still compile.

  static void showSnackBar(SnackBar snackBar) {
    final state = messengerKey.currentState;
    if (state == null) return;
    state.removeCurrentSnackBar();
    state.showSnackBar(snackBar);
  }
}
