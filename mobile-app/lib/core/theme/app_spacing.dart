import 'package:flutter/material.dart';

/// Design System — Spacing & Shape Tokens
class AppSpacing {
  // ── Spacing Scale ─────────────────────────────────────────────────────────
  static const double xs   = 4.0;
  static const double sm   = 8.0;
  static const double md   = 12.0;
  static const double lg   = 16.0;
  static const double xl   = 20.0;
  static const double xl2  = 24.0;
  static const double xl3  = 32.0;
  static const double xl4  = 40.0;
  static const double xl5  = 48.0;
  static const double xl6  = 64.0;

  // ── Screen Padding ────────────────────────────────────────────────────────
  static const EdgeInsets screenPadding    = EdgeInsets.symmetric(horizontal: 20.0);
  static const EdgeInsets screenPaddingAll = EdgeInsets.all(20.0);
  static const EdgeInsets cardPadding      = EdgeInsets.all(16.0);
  static const EdgeInsets listItemPadding  = EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0);

  // ── Border Radii ──────────────────────────────────────────────────────────
  static const double radiusXs   = 4.0;
  static const double radiusSm   = 8.0;
  static const double radiusMd   = 12.0;
  static const double radiusLg   = 16.0;
  static const double radiusXl   = 20.0;
  static const double radiusXl2  = 24.0;
  static const double radiusFull = 100.0;

  static const BorderRadius brXs   = BorderRadius.all(Radius.circular(radiusXs));
  static const BorderRadius brSm   = BorderRadius.all(Radius.circular(radiusSm));
  static const BorderRadius brMd   = BorderRadius.all(Radius.circular(radiusMd));
  static const BorderRadius brLg   = BorderRadius.all(Radius.circular(radiusLg));
  static const BorderRadius brXl   = BorderRadius.all(Radius.circular(radiusXl));
  static const BorderRadius brFull = BorderRadius.all(Radius.circular(radiusFull));
}

/// Design System — Shadow Tokens
class AppShadows {
  static const List<BoxShadow> sm = [
    BoxShadow(
      color: Color(0x080F172A),
      blurRadius: 4,
      offset: Offset(0, 1),
    ),
  ];

  static const List<BoxShadow> md = [
    BoxShadow(
      color: Color(0x0C0F172A),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
    BoxShadow(
      color: Color(0x060F172A),
      blurRadius: 4,
      offset: Offset(0, 1),
    ),
  ];

  static const List<BoxShadow> lg = [
    BoxShadow(
      color: Color(0x120F172A),
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
    BoxShadow(
      color: Color(0x080F172A),
      blurRadius: 6,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> nav = [
    BoxShadow(
      color: Color(0x140F172A),
      blurRadius: 20,
      offset: Offset(0, -4),
    ),
  ];
}
