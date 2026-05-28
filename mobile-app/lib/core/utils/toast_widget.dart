import 'package:flutter/material.dart';
import 'toast_config.dart';

/// The animated toast widget rendered inside an [OverlayEntry].
///
/// Positioned: centered on screen.
/// Animation: scale (0.85 → 1.0) + fade, with subtle background scrim.
/// Auto-dismiss, tap-to-dismiss.
class ToastWidget extends StatefulWidget {
  final ToastConfig config;
  final VoidCallback onDismissed;

  const ToastWidget({
    super.key,
    required this.config,
    required this.onDismissed,
  });

  @override
  State<ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<ToastWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  bool _dismissing = false;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
      reverseDuration: const Duration(milliseconds: 250),
    );

    _fade = CurvedAnimation(
      parent: _ctrl,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );

    _scale = Tween<double>(begin: 0.90, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: Curves.easeOutQuint,
        reverseCurve: Curves.easeInQuint,
      ),
    );

    _ctrl.forward();
    Future.delayed(widget.config.duration, _startDismiss);
  }

  Future<void> _startDismiss() async {
    if (_dismissing || !mounted) return;
    _dismissing = true;
    await _ctrl.reverse();
    if (mounted) widget.onDismissed();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Tap-outside-to-dismiss scrim (very subtle, non-blocking feel)
        Positioned.fill(
          child: FadeTransition(
            opacity: Tween<double>(begin: 0, end: 0.18).animate(_fade),
            child: GestureDetector(
              onTap: _startDismiss,
              behavior: HitTestBehavior.opaque,
              child: const ColoredBox(color: Colors.black),
            ),
          ),
        ),

        // Centered card
        Center(
          child: FadeTransition(
            opacity: _fade,
            child: ScaleTransition(
              scale: _scale,
              child: GestureDetector(
                onTap: _startDismiss,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: _ToastCard(config: widget.config, onDismiss: _startDismiss),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ToastCard extends StatelessWidget {
  final ToastConfig config;
  final VoidCallback onDismiss;

  const _ToastCard({required this.config, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final accent = config.accent;
    final accentSoft = config.accentSoft;
    final resolvedTitle = config.title ?? config.defaultTitle;

    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: accent.withAlpha(40),
              blurRadius: 40,
              spreadRadius: 0,
              offset: const Offset(0, 16),
            ),
            BoxShadow(
              color: Colors.black.withAlpha(20),
              blurRadius: 20,
              spreadRadius: 0,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top accent strip (slightly thicker)
              Container(
                height: 5,
                color: accent,
              ),

              // Body
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 20, 24),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon circle (larger)
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: accentSoft,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(config.icon, color: accent, size: 30),
                      ),
                    ),

                    const SizedBox(width: 18),

                    // Text
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 3),
                          Text(
                            resolvedTitle,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: accent,
                              letterSpacing: 0.15,
                            ),
                          ),
                          if (config.message.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              config.message,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF374151),
                                height: 1.5,
                              ),
                              maxLines: 5,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Close button (better alignment)
                    GestureDetector(
                      onTap: onDismiss,
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 12, top: 4, bottom: 12, right: 4),
                        child: Icon(
                          Icons.close_rounded,
                          size: 22,
                          color: Colors.grey[400],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
