import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Design-system text input — clean, minimal, accessible.
class CustomTextField extends StatefulWidget {
  final String label;
  final String hint;
  final TextEditingController? controller;
  final bool isPassword;
  final TextInputType? keyboardType;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final int maxLines;
  final int? maxLength;
  final bool readOnly;
  final VoidCallback? onTap;
  final TextCapitalization textCapitalization;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final void Function(String)? onFieldSubmitted;

  const CustomTextField({
    super.key,
    required this.label,
    required this.hint,
    this.controller,
    this.isPassword = false,
    this.keyboardType,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.onChanged,
    this.maxLines = 1,
    this.maxLength,
    this.readOnly = false,
    this.onTap,
    this.textCapitalization = TextCapitalization.none,
    this.focusNode,
    this.textInputAction,
    this.onFieldSubmitted,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Text(
          widget.label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
            height: 1.0,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        // Input
        TextFormField(
            controller: widget.controller,
            obscureText: widget.isPassword && _obscureText,
            keyboardType: widget.keyboardType,
            validator: widget.validator,
            onChanged: widget.onChanged,
            maxLines: widget.isPassword ? 1 : widget.maxLines,
            maxLength: widget.maxLength,
            readOnly: widget.readOnly,
            onTap: widget.onTap,
            textCapitalization: widget.textCapitalization,
            focusNode: widget.focusNode,
            textInputAction: widget.textInputAction,
            onFieldSubmitted: widget.onFieldSubmitted,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: Theme.of(context).colorScheme.onSurface,
              height: 1.4,
            ),
            decoration: InputDecoration(
              hintText: widget.hint,
              counterText: '',
              hintStyle: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 15,
                fontWeight: FontWeight.w400,
              ),
              filled: true,
              fillColor: widget.readOnly
                  ? Theme.of(context).colorScheme.surfaceContainerHighest
                  : Theme.of(context).scaffoldBackgroundColor,
              prefixIcon: widget.prefixIcon != null
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: IconTheme(
                        data: IconThemeData(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                        child: widget.prefixIcon!,
                      ),
                    )
                  : null,
              prefixIconConstraints:
                  const BoxConstraints(minWidth: 0, minHeight: 0),
              suffixIcon: _buildSuffix(context),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: widget.maxLines > 1 ? 14 : 0,
              ),
              constraints: BoxConstraints(
                minHeight: widget.maxLines > 1 ? 0 : 52,
              ),
              border: OutlineInputBorder(
                borderRadius: AppSpacing.brMd,
                borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.outline, width: 1.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppSpacing.brMd,
                borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.outline, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: AppSpacing.brMd,
                borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: AppSpacing.brMd,
                borderSide: const BorderSide(
                    color: AppColors.error, width: 1.5),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: AppSpacing.brMd,
                borderSide:
                    const BorderSide(color: AppColors.error, width: 2),
              ),
              errorStyle: const TextStyle(
                fontSize: 12,
                color: AppColors.error,
                height: 1.4,
              ),
            ),
          ),
      ],
    );
  }

  Widget? _buildSuffix(BuildContext context) {
    if (widget.isPassword) {
      return IconButton(
        icon: Icon(
          _obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          size: 20,
        ),
        onPressed: () => setState(() => _obscureText = !_obscureText),
        padding: const EdgeInsets.only(right: 4),
        splashRadius: 20,
      );
    }
    if (widget.suffixIcon != null) {
      return Padding(
        padding: const EdgeInsets.only(right: 4),
        child: widget.suffixIcon,
      );
    }
    return null;
  }
}
