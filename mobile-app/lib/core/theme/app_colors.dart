import 'package:flutter/material.dart';

/// Unified Design System — Color Tokens
/// Single source of truth for the entire application.
class AppColors {
  // ── Brand / Primary ────────────────────────────────────────────────────────
  static const Color primary        = Color(0xFF1A56DB);
  static const Color primaryDark    = Color(0xFF1340A8);
  static const Color primaryLight   = Color(0xFF3B7BEF);
  static const Color primaryMuted   = Color(0xFFEEF3FE);

  // ── Semantic Status ────────────────────────────────────────────────────────
  static const Color success        = Color(0xFF16A34A);
  static const Color successMuted   = Color(0xFFDCFCE7);
  static const Color error          = Color(0xFFDC2626);
  static const Color errorMuted     = Color(0xFFFEE2E2);
  static const Color warning        = Color(0xFFF59E0B);
  static const Color warningMuted   = Color(0xFFFEF3C7);
  static const Color info           = Color(0xFF0891B2);
  static const Color infoMuted      = Color(0xFFE0F2FE);

  // ── Post Type ──────────────────────────────────────────────────────────────
  static const Color lostBadge      = Color(0xFFDC2626);
  static const Color lostBadgeBg    = Color(0xFFFEE2E2);
  static const Color foundBadge     = Color(0xFF16A34A);
  static const Color foundBadgeBg   = Color(0xFFDCFCE7);

  // ── Neutral Scale ──────────────────────────────────────────────────────────
  static const Color white          = Color(0xFFFFFFFF);
  static const Color black          = Color(0xFF000000);
  static const Color neutral50      = Color(0xFFF8FAFC);
  static const Color neutral100     = Color(0xFFF1F5F9);
  static const Color neutral200     = Color(0xFFE2E8F0);
  static const Color neutral300     = Color(0xFFCBD5E1);
  static const Color neutral400     = Color(0xFF94A3B8);
  static const Color neutral500     = Color(0xFF64748B);
  static const Color neutral600     = Color(0xFF475569);
  static const Color neutral700     = Color(0xFF334155);
  static const Color neutral800     = Color(0xFF1E293B);
  static const Color neutral900     = Color(0xFF0F172A);

  // ── Surface / Background ──────────────────────────────────────────────────
  static const Color background     = Color(0xFFF8FAFC);
  static const Color surface        = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F5F9);

  // ── Text ──────────────────────────────────────────────────────────────────
  static const Color textPrimary    = Color(0xFF0F172A);
  static const Color textSecondary  = Color(0xFF475569);
  static const Color textTertiary   = Color(0xFF94A3B8);
  static const Color textDisabled   = Color(0xFFCBD5E1);
  static const Color textInverse    = Color(0xFFFFFFFF);

  // ── Border / Divider ──────────────────────────────────────────────────────
  static const Color border         = Color(0xFFE2E8F0);
  static const Color borderFocus    = Color(0xFF1A56DB);
  static const Color divider        = Color(0xFFF1F5F9);

  // ── Rewards / Gold ────────────────────────────────────────────────────────
  static const Color gold           = Color(0xFFF59E0B);
  static const Color goldMuted      = Color(0xFFFEF3C7);
  static const Color goldDark       = Color(0xFFD97706);

  // ── Shadows ───────────────────────────────────────────────────────────────
  static const Color shadowSm       = Color(0x0A0F172A);   // 4% opacity
  static const Color shadowMd       = Color(0x120F172A);   // 7% opacity
  static const Color shadowLg       = Color(0x1A0F172A);   // 10% opacity
}
