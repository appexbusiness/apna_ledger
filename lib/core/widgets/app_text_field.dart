import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../design/motion.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Premium text field: floating label, animated focus glow, and inline
/// validation — a green tick slides in once a validated field becomes valid,
/// and the field shakes when an external [errorText] appears.
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.controller,
    this.label,
    this.hint,
    this.prefix,
    this.suffix,
    this.keyboardType,
    this.obscure = false,
    this.validator,
    this.maxLength,
    this.prefixText,
    this.onChanged,
    this.inputFormatters,
    this.enabled = true,
    this.errorText,
    this.icon,
    this.autofocus = false,
    this.textCapitalization = TextCapitalization.none,
    this.maxLines = 1,
    this.minLines,
    this.textInputAction,
    this.onSubmitted,
    this.accent,
  });

  final TextEditingController controller;
  final String? label;
  final String? hint;
  final Widget? prefix;
  final Widget? suffix;
  final String? prefixText;
  final TextInputType? keyboardType;
  final bool obscure;
  final String? Function(String?)? validator;
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  final List<TextInputFormatter>? inputFormatters;
  final bool enabled;

  /// External error message (e.g. from an async check) shown below the
  /// field, independent of [validator]/[Form] validation.
  final String? errorText;

  /// Leading icon (used when no [prefix] widget is given).
  final IconData? icon;
  final bool autofocus;
  final TextCapitalization textCapitalization;
  final int? maxLines;
  final int? minLines;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  /// Focus colour (defaults to the theme primary).
  final Color? accent;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  final _focus = FocusNode();
  bool _focused = false;
  bool _touched = false;
  int _shake = 0;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (!mounted) return;
      setState(() {
        _focused = _focus.hasFocus;
        if (!_focus.hasFocus && widget.controller.text.isNotEmpty) {
          _touched = true;
        }
      });
    });
    widget.controller.addListener(_onText);
  }

  @override
  void didUpdateWidget(covariant AppTextField old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_onText);
      widget.controller.addListener(_onText);
    }
    if (widget.errorText != null && widget.errorText != old.errorText) {
      _shake++;
    }
  }

  void _onText() {
    if (mounted && widget.validator != null) setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onText);
    _focus.dispose();
    super.dispose();
  }

  bool get _valid {
    if (widget.validator == null || widget.errorText != null) return false;
    final text = widget.controller.text;
    if (text.isEmpty) return false;
    return (_touched || text.length > 2) && widget.validator!(text) == null;
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.accent ?? Theme.of(context).colorScheme.primary;
    final s = context.surfaces;
    final semantic = context.semantic;
    final valid = _valid;

    Widget? suffix = widget.suffix;
    if (suffix == null && widget.validator != null) {
      suffix = AnimatedSwitcher(
        duration: AppMotion.medium,
        transitionBuilder: (c, a) => ScaleTransition(
          scale: CurvedAnimation(parent: a, curve: AppMotion.bouncy),
          child: c,
        ),
        child: valid
            ? Padding(
                key: const ValueKey('ok'),
                padding: const EdgeInsets.only(right: 12),
                child: Icon(
                  Icons.check_circle_rounded,
                  color: semantic.income,
                  size: 22,
                ),
              )
            : const SizedBox(key: ValueKey('none'), width: 0),
      );
    }

    final field = AnimatedContainer(
      duration: AppMotion.medium,
      curve: AppMotion.emphasized,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        boxShadow: _focused
            ? [
                BoxShadow(
                  color: accent.withValues(alpha: s.isDark ? 0.28 : 0.18),
                  blurRadius: 18,
                  spreadRadius: -2,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(primary: accent),
          inputDecorationTheme: Theme.of(context).inputDecorationTheme.copyWith(
                fillColor: _focused ? s.card : s.surface2,
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  borderSide: BorderSide(color: accent, width: 1.8),
                ),
                floatingLabelStyle: TextStyle(
                  color: accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
        ),
        child: TextFormField(
          controller: widget.controller,
          focusNode: _focus,
          keyboardType: widget.keyboardType,
          obscureText: widget.obscure,
          validator: widget.validator,
          maxLength: widget.maxLength,
          onChanged: widget.onChanged,
          inputFormatters: widget.inputFormatters,
          enabled: widget.enabled,
          autofocus: widget.autofocus,
          textCapitalization: widget.textCapitalization,
          maxLines: widget.obscure ? 1 : widget.maxLines,
          minLines: widget.minLines,
          textInputAction: widget.textInputAction,
          onFieldSubmitted: widget.onSubmitted,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15.5),
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: widget.hint,
            counterText: '',
            prefixIcon: widget.prefix ??
                (widget.icon == null
                    ? null
                    : AnimatedContainer(
                        duration: AppMotion.fast,
                        margin: const EdgeInsets.only(left: 12, right: 8),
                        child: Icon(
                          widget.icon,
                          size: 20,
                          color: _focused ? accent : semantic.muted,
                        ),
                      )),
            prefixIconConstraints:
                const BoxConstraints(minWidth: 44, minHeight: 44),
            prefixText: widget.prefixText,
            prefixStyle: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w700,
              fontSize: 15.5,
            ),
            suffixIcon: suffix,
            errorText: widget.errorText,
            errorMaxLines: 2,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              borderSide: BorderSide(
                color: valid
                    ? AppColors.income.withValues(alpha: 0.5)
                    : Colors.transparent,
                width: 1.2,
              ),
            ),
          ),
        ),
      ),
    );

    return Shake(trigger: _shake, child: field);
  }
}

/// A tappable, read-only field used for pickers (date, category, state):
/// floating-label look, leading icon, value, trailing chevron.
class AppPickerField extends StatelessWidget {
  const AppPickerField({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
    this.icon = Icons.expand_more_rounded,
    this.leading,
    this.accent,
    this.placeholder = '—',
  });

  final String label;
  final String? value;
  final VoidCallback onTap;
  final IconData icon;
  final Widget? leading;
  final Color? accent;
  final String placeholder;

  @override
  Widget build(BuildContext context) {
    final s = context.surfaces;
    final hasValue = value != null && value!.isNotEmpty;
    return Pressable(
      onTap: onTap,
      pressedScale: 0.98,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
        constraints: const BoxConstraints(minHeight: 60),
        decoration: BoxDecoration(
          color: s.surface2,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        ),
        child: Row(
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 12)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: context.semantic.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  AnimatedSwitcher(
                    duration: AppMotion.fast,
                    transitionBuilder: (c, a) => FadeTransition(
                      opacity: a,
                      child: SlideTransition(
                        position: Tween(
                          begin: const Offset(0, 0.3),
                          end: Offset.zero,
                        ).animate(a),
                        child: c,
                      ),
                    ),
                    child: Text(
                      hasValue ? value! : placeholder,
                      key: ValueKey(value),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: hasValue ? null : context.semantic.muted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Icon(icon, color: accent ?? context.semantic.muted, size: 22),
          ],
        ),
      ),
    );
  }
}
