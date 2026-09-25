import 'package:flutter/material.dart';

/// Primary filled button with a built-in loading state, press animation, and a
/// short debounce so rapid double-taps never fire the action twice.
class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
    this.debounce = const Duration(milliseconds: 700),
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;
  final Duration debounce;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _locked = false;

  void _handleTap() {
    if (_locked || widget.onPressed == null) return;
    setState(() => _locked = true);
    widget.onPressed!.call();
    Future.delayed(widget.debounce, () {
      if (mounted) setState(() => _locked = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final disabled = widget.loading || _locked || widget.onPressed == null;
    return FilledButton(
      onPressed: disabled ? null : _handleTap,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: widget.loading
            ? const SizedBox(
                key: ValueKey('loading'),
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: Colors.white,
                ),
              )
            : Row(
                key: const ValueKey('label'),
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.icon != null) ...[
                    Icon(widget.icon, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(widget.label),
                ],
              ),
      ),
    );
  }
}
