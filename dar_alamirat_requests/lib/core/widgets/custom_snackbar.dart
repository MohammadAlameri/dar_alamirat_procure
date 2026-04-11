import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:dar_alamirat_requests/core/theme/app_theme.dart';

enum SnackBarType { success, error, info, warning }

class AppSnackBar {
  static OverlayEntry? _currentOverlayEntry;

  static void show(BuildContext context, String message, {SnackBarType type = SnackBarType.info}) {
    final overlayState = Overlay.of(context);
    
    // Remove current snackbar if any
    _currentOverlayEntry?.remove();
    _currentOverlayEntry = null;

    late OverlayEntry overlayEntry;

    Color bgColor;
    IconData icon;
    
    switch (type) {
      case SnackBarType.success:
        bgColor = const Color(0xFF10B981); // Modern success green
        icon = LucideIcons.checkCircle2;
        break;
      case SnackBarType.error:
        bgColor = const Color(0xFFEF4444); // Modern error red
        icon = LucideIcons.xCircle;
        break;
      case SnackBarType.warning:
        bgColor = const Color(0xFFF59E0B); // Modern warning orange
        icon = LucideIcons.alertTriangle;
        break;
      case SnackBarType.info:
      default:
        bgColor = const Color(0xFF3B82F6); // Modern info blue
        icon = LucideIcons.info;
        break;
    }

    overlayEntry = OverlayEntry(
      builder: (context) => _SnackBarWidget(
        message: message,
        bgColor: bgColor,
        icon: icon,
        onDismiss: () {
          if (_currentOverlayEntry == overlayEntry) {
            _currentOverlayEntry?.remove();
            _currentOverlayEntry = null;
          }
        },
      ),
    );

    _currentOverlayEntry = overlayEntry;
    overlayState.insert(overlayEntry);
  }
}

class _SnackBarWidget extends StatefulWidget {
  final String message;
  final Color bgColor;
  final IconData icon;
  final VoidCallback onDismiss;

  const _SnackBarWidget({
    required this.message,
    required this.bgColor,
    required this.icon,
    required this.onDismiss,
  });

  @override
  State<_SnackBarWidget> createState() => _SnackBarWidgetState();
}

class _SnackBarWidgetState extends State<_SnackBarWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    ));

    _controller.forward();

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _controller.reverse().then((_) => widget.onDismiss());
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _offsetAnimation,
        child: FadeTransition(
          opacity: _opacityAnimation,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: widget.bgColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: widget.bgColor.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(widget.icon, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        fontFamily: 'Cairo', // Using the theme font
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
