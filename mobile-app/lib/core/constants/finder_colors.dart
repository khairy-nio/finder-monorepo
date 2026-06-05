import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// FinderColors — bridges legacy code to the unified design system.
/// New code should import AppColors directly.
class FinderColors {
  static const Color primaryBlue    = AppColors.primary;
  static const Color primaryBrown   = AppColors.primary;
  static const Color lightBlue      = AppColors.primaryLight;
  static const Color lightBrown     = AppColors.primaryLight;
  static const Color darkBrown      = AppColors.primaryDark;

  static const Color textPrimary    = AppColors.textPrimary;
  static const Color textSecondary  = AppColors.textSecondary;
  static const Color background     = AppColors.surface;
}
