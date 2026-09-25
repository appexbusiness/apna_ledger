import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../design/motion.dart';
import '../theme/app_theme.dart';

/// Segmented code input (PIN / OTP): one hidden text field drives a row of
/// raised boxes. Filled boxes pop, the active box glows, and the row shakes
/// whenever [errorTrigger] changes.
class PinBoxes extends StatefulWidget {
  const PinBoxes({
    super.key,
    required this.controller,
    this.length = 4,
    this.obscure = true,
    this.autofocus = false,
    this.onChanged,
    this.onCompleted,
    this.errorTrigger = 0,
    this.hasError = false,
    this.accent,
  });

  final TextEditingController controller;
  final int length;
  final bool obscure;
  final bool autofocus;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onCompleted;
  final int errorTrigger;
  final bool hasError;
  final Color? accent;

  @override
  State<PinBoxes> createState() => _PinBoxesState();
}

class _PinBoxesState extends State<PinBoxes> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_rebuild);
    _focus.addListener(_rebuild);
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_rebuild);
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.controller.text;
    final accent = widget.hasError
        ? context.semantic.expense
        : (widget.accent ?? Theme.of(context).colorScheme.primary);
    final s = context.surfaces;
    final boxW = widget.length > 4 ? 42.0 : 58.0;

    return Shake(
      trigger: widget.errorTrigger,
      child: GestureDetector(
        onTap: () => _focus.requestFocus(),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // The real input, invisible but focusable.
            Opacity(
              opacity: 0,
              child: SizedBox(
                height: 1,
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focus,
                  autofocus: widget.autofocus,
                  keyboardType: TextInputType.number,
                  maxLength: widget.length,
                  showCursor: false,
                  enableInteractiveSelection: false,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(counterText: ''),
                  onChanged: (v) {
                    AppHaptics.select();
                    widget.onChanged?.call(v);
                    if (v.length == widget.length) widget.onCompleted?.call(v);
                  },
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < widget.length; i++) ...[
                  if (i > 0) const SizedBox(width: 10),
                  _Box(
                    width: boxW,
                    char: i < text.length ? text[i] : null,
                    obscure: widget.obscure,
                    active: _focus.hasFocus &&
                        (i == text.length ||
                            (i == widget.length - 1 &&
                                text.length == widget.length)),
                    accent: accent,
                    surface: s,
                    error: widget.hasError,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Box extends StatelessWidget {
  const _Box({
    required this.width,
    required this.char,
    required this.obscure,
    required this.active,
    required this.accent,
    required this.surface,
    required this.error,
  });

  final double width;
  final String? char;
  final bool obscure;
  final bool active;
  final Color accent;
  final AppSurfaces surface;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final filled = char != null;
    return AnimatedContainer(
      duration: AppMotion.medium,
      curve: AppMotion.emphasized,
      width: width,
      height: width * 1.12,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: filled || active
              ? [surface.cardHi, surface.card]
              : [surface.surface2, surface.surface2],
        ),
        border: Border.all(
          color: active || error
              ? accent
              : (filled ? accent.withValues(alpha: 0.4) : Colors.transparent),
          width: active ? 2 : 1.4,
        ),
        boxShadow: active
            ? [
                BoxShadow(
                  color: accent.withValues(alpha: 0.25),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ]
            : (filled ? surface.elevation(0.4) : null),
      ),
      alignment: Alignment.center,
      child: AnimatedSwitcher(
        duration: AppMotion.fast,
        transitionBuilder: (c, a) => ScaleTransition(
          scale: CurvedAnimation(parent: a, curve: AppMotion.bouncy),
          child: c,
        ),
        child: !filled
            ? const SizedBox.shrink()
            : obscure
                ? Container(
                    key: const ValueKey('dot'),
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                    ),
                  )
                : Text(
                    char!,
                    key: ValueKey(char),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: accent,
                    ),
                  ),
      ),
    );
  }
}
