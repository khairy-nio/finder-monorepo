import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Context-aware color tokens that adapt to light / dark theme.
/// Usage: context.colors.surface, context.colors.textPrimary, etc.
extension DynamicColorsX on BuildContext {
  DynamicColors get colors => DynamicColors(Theme.of(this).brightness == Brightness.dark);
}

class DynamicColors {
  final bool _dark;
  const DynamicColors(this._dark);

  // ── Surfaces ──────────────────────────────────────────────────────────────
  Color get background     => _dark ? const Color(0xFF0F172A) : AppColors.background;
  Color get surface        => _dark ? const Color(0xFF1E293B) : AppColors.surface;
  Color get surfaceVariant => _dark ? const Color(0xFF334155) : AppColors.surfaceVariant;

  // ── Text ──────────────────────────────────────────────────────────────────
  Color get textPrimary    => _dark ? const Color(0xFFF1F5F9) : AppColors.textPrimary;
  Color get textSecondary  => _dark ? const Color(0xFF94A3B8) : AppColors.textSecondary;
  Color get textTertiary   => _dark ? const Color(0xFF64748B) : AppColors.textTertiary;
  Color get textInverse    => _dark ? AppColors.textPrimary   : AppColors.white;

  // ── Neutral scale (adapted) ───────────────────────────────────────────────
  Color get neutral50      => _dark ? const Color(0xFF1E293B) : AppColors.neutral50;
  Color get neutral100     => _dark ? const Color(0xFF334155) : AppColors.neutral100;
  Color get neutral200     => _dark ? const Color(0xFF475569) : AppColors.neutral200;
  Color get neutral300     => _dark ? const Color(0xFF64748B) : AppColors.neutral300;
  Color get neutral400     => _dark ? const Color(0xFF94A3B8) : AppColors.neutral400;

  // ── Borders / Dividers ────────────────────────────────────────────────────
  Color get border         => _dark ? const Color(0xFF334155) : AppColors.border;
  Color get divider        => _dark ? const Color(0xFF1E293B) : AppColors.divider;

  // ── Primary ───────────────────────────────────────────────────────────────
  Color get primary        => _dark ? AppColors.primaryLight  : AppColors.primary;
  Color get primaryMuted   => _dark ? const Color(0xFF1A2E52) : AppColors.primaryMuted;

  // ── Semantic (same in both themes) ────────────────────────────────────────
  Color get success        => AppColors.success;
  Color get successMuted   => _dark ? const Color(0xFF14532D) : AppColors.successMuted;
  Color get error          => AppColors.error;
  Color get errorMuted     => _dark ? const Color(0xFF450A0A) : AppColors.errorMuted;
  Color get warning        => AppColors.warning;
  Color get warningMuted   => _dark ? const Color(0xFF451A03) : AppColors.warningMuted;

  // ── Post type badges ──────────────────────────────────────────────────────
  Color get lostBadge      => AppColors.lostBadge;
  Color get lostBadgeBg    => _dark ? const Color(0xFF450A0A) : AppColors.lostBadgeBg;
  Color get foundBadge     => AppColors.foundBadge;
  Color get foundBadgeBg   => _dark ? const Color(0xFF14532D) : AppColors.foundBadgeBg;

  // ── Chat bubbles ──────────────────────────────────────────────────────────
  Color get bubbleReceived     => _dark ? const Color(0xFF334155) : AppColors.surface;
  Color get bubbleReceivedText => textPrimary;

  // ── Gold ─────────────────────────────────────────────────────────────────
  Color get gold     => AppColors.gold;
  Color get goldMuted => _dark ? const Color(0xFF451A03) : AppColors.goldMuted;
  Color get goldDark  => AppColors.goldDark;

  // ── Constant ─────────────────────────────────────────────────────────────
  Color get white => AppColors.white;
}
