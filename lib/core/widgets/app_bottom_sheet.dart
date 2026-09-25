import 'dart:ui';

import 'package:flutter/material.dart';

import '../design/fin_icons.dart';
import '../design/motion.dart';
import '../design/surfaces.dart';
import '../theme/app_theme.dart';

/// The app's primary input surface. Every "enter / pick / confirm / view"
/// interaction opens one of these instead of a dialog or a new page.
///
/// • Springs up from the bottom; exits quickly.
/// • Blurs + dims whatever is behind it; tap outside to close.
/// • Drag the handle, header, or pull down from the top of scrolled content
///   to dismiss (velocity-aware).
/// • Keyboard-aware, scrolls when tall, max 92% of the screen.
/// • Opening a sheet from a sheet stacks them: the lower one recedes.
///
/// [builder] receives a [StateSetter] so sheet-local state (toggles, date
/// choices) can update without a StatefulWidget.
Future<T?> showAppSheet<T>(
  BuildContext context, {
  String? title,
  String? subtitle,
  FinGlyph? glyph,
  Color? accent,
  required Widget Function(BuildContext context, StateSetter setSheet)
      builder,
  bool dismissible = true,
  bool scrollable = true,
  EdgeInsetsGeometry padding = const EdgeInsets.fromLTRB(20, 4, 20, 24),
}) {
  AppHaptics.light();
  return Navigator.of(context, rootNavigator: true).push<T>(
    AppSheetRoute<T>(
      dismissible: dismissible,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheet) => AppSheetBody(
          title: title,
          subtitle: subtitle,
          glyph: glyph,
          accent: accent,
          scrollable: scrollable,
          padding: padding,
          showClose: dismissible,
          child: builder(context, setSheet),
        ),
      ),
    ),
  );
}

/// Route behind [showAppSheet]. Public so full-height flows (Add
/// Transaction) can use the same physics via a page wrapper.
class AppSheetRoute<T> extends PopupRoute<T> {
  AppSheetRoute({
    required this.builder,
    this.dismissible = true,
    super.settings,
  });

  final WidgetBuilder builder;
  final bool dismissible;

  @override
  Color? get barrierColor => null; // drawn by [_SheetFrame] with blur

  @override
  bool get barrierDismissible => false; // handled by [_SheetFrame]

  @override
  String? get barrierLabel => 'Dismiss';

  @override
  Duration get transitionDuration => const Duration(milliseconds: 560);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 260);

  AnimationController get sheetController => controller!;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return _SheetFrame(
      route: this,
      animation: animation,
      secondaryAnimation: secondaryAnimation,
      child: Builder(builder: builder),
    );
  }
}

class _SheetFrame extends StatefulWidget {
  const _SheetFrame({
    required this.route,
    required this.animation,
    required this.secondaryAnimation,
    required this.child,
  });

  final AppSheetRoute<dynamic> route;
  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final Widget child;

  @override
  State<_SheetFrame> createState() => _SheetFrameState();
}

class _SheetFrameState extends State<_SheetFrame> {
  final _sheetKey = GlobalKey();
  bool _dragging = false;

  AnimationController get _c => widget.route.sheetController;

  double get _height =>
      (_sheetKey.currentContext?.size?.height ?? 400).clamp(1, 4000);

  void _dragUpdate(double dy) {
    if (!widget.route.dismissible) return;
    if (!_dragging) setState(() => _dragging = true);
    _c.value = (_c.value - dy / _height).clamp(0.0, 1.0);
  }

  void _dragEnd(double velocity) {
    if (!widget.route.dismissible) return;
    setState(() => _dragging = false);
    if (velocity > 700 || _c.value < 0.6) {
      Navigator.of(context).pop();
    } else {
      _c.forward();
    }
  }

  bool _onScroll(ScrollNotification n) {
    // Pull-down past the top of scrolled content moves the sheet itself.
    if (n.metrics.axis != Axis.vertical) return false;
    if (n is OverscrollNotification &&
        n.dragDetails != null &&
        n.overscroll < 0) {
      _dragUpdate(-n.overscroll);
    } else if (n is ScrollEndNotification && _dragging) {
      _dragEnd(n.dragDetails?.primaryVelocity ?? 0);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final curved = CurvedAnimation(
      parent: widget.animation,
      curve: AppMotion.spring,
      reverseCurve: AppMotion.exit,
    );

    return AnimatedBuilder(
      animation: Listenable.merge(
        [widget.animation, widget.secondaryAnimation],
      ),
      builder: (context, _) {
        final raw = widget.animation.value;
        final t = _dragging ? raw : curved.value;
        final back = Curves.easeOut.transform(widget.secondaryAnimation.value);
        final barrier = raw.clamp(0.0, 1.0);
        return Stack(
          children: [
            // Blur + dim barrier.
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.route.dismissible
                    ? () => Navigator.of(context).maybePop()
                    : null,
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: 8 * barrier,
                    sigmaY: 8 * barrier,
                  ),
                  child: ColoredBox(
                    color: const Color(0xFF050814)
                        .withValues(alpha: 0.42 * barrier),
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: AnimatedPadding(
                duration: AppMotion.fast,
                curve: Curves.easeOut,
                padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
                child: FractionalTranslation(
                  translation: Offset(0, 1 - t),
                  child: Transform.scale(
                    scale: 1 - 0.06 * back,
                    alignment: Alignment.topCenter,
                    child: Transform.translate(
                      offset: Offset(0, -18 * back),
                      child: ConstrainedBox(
                        key: _sheetKey,
                        constraints: BoxConstraints(
                          maxWidth: 640,
                          maxHeight: (media.size.height -
                                  media.viewInsets.bottom -
                                  media.padding.top) *
                              0.94,
                        ),
                        child: GestureDetector(
                          behavior: HitTestBehavior.deferToChild,
                          onVerticalDragUpdate: (d) =>
                              _dragUpdate(d.primaryDelta ?? 0),
                          onVerticalDragEnd: (d) =>
                              _dragEnd(d.primaryVelocity ?? 0),
                          child: NotificationListener<ScrollNotification>(
                            onNotification: _onScroll,
                            child: _SheetDragScope(
                              progress: t,
                              child: widget.child,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Exposes the sheet's open-progress to its body (for content fades).
class _SheetDragScope extends InheritedWidget {
  const _SheetDragScope({required this.progress, required super.child});
  final double progress;

  static double of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<_SheetDragScope>()
          ?.progress ??
      1;

  @override
  bool updateShouldNotify(_SheetDragScope old) => old.progress != progress;
}

/// Standard sheet chrome: handle, optional 3D-icon header with close orb,
/// then the content. Use directly inside an [AppSheetRoute] for custom
/// sheets; [showAppSheet] wraps its builder in one automatically.
class AppSheetBody extends StatelessWidget {
  const AppSheetBody({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.glyph,
    this.accent,
    this.scrollable = true,
    this.showClose = true,
    this.padding = const EdgeInsets.fromLTRB(20, 4, 20, 24),
    this.footer,
  });

  final Widget child;
  final String? title;
  final String? subtitle;
  final FinGlyph? glyph;
  final Color? accent;
  final bool scrollable;
  final bool showClose;
  final EdgeInsetsGeometry padding;

  /// Pinned below the scrolling content (e.g. a primary action).
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final s = context.surfaces;
    final progress = _SheetDragScope.of(context);
    final bottomSafe = MediaQuery.of(context).padding.bottom;
    final content = Padding(padding: padding, child: child);

    return Material(
      type: MaterialType.transparency,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: s.sheet,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: s.isDark ? 0.5 : 0.18),
              blurRadius: 40,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        foregroundDecoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: GradientBoxBorder(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                s.isDark
                    ? Colors.white.withValues(alpha: 0.14)
                    : Colors.white,
                Colors.white.withValues(alpha: 0),
              ],
              stops: const [0, 0.12],
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _Handle(),
            if (title != null)
              _SheetHeader(
                title: title!,
                subtitle: subtitle,
                glyph: glyph,
                accent: accent,
                showClose: showClose,
              ),
            Flexible(
              child: Opacity(
                opacity: Curves.easeOut
                    .transform(((progress - 0.35) / 0.65).clamp(0.0, 1.0)),
                child: scrollable
                    ? SingleChildScrollView(
                        physics: const ClampingScrollPhysics(),
                        child: content,
                      )
                    : content,
              ),
            ),
            if (footer != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: footer,
              ),
            SizedBox(height: bottomSafe),
          ],
        ),
      ),
    );
  }
}

class _Handle extends StatelessWidget {
  const _Handle();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 6),
      child: Center(
        child: Container(
          width: 44,
          height: 5,
          decoration: BoxDecoration(
            color: context.semantic.muted.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({
    required this.title,
    this.subtitle,
    this.glyph,
    this.accent,
    this.showClose = true,
  });

  final String title;
  final String? subtitle;
  final FinGlyph? glyph;
  final Color? accent;
  final bool showClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 14, 14),
      child: Row(
        children: [
          if (glyph != null) ...[
            PopOnChange(
              trigger: glyph,
              child: Icon3D(glyph: glyph, color: accent, size: 42),
            ),
            const SizedBox(width: 14),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: context.semantic.muted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (showClose)
            IconOrb(
              icon: Icons.close_rounded,
              size: 38,
              tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
              onTap: () => Navigator.of(context).maybePop(),
            ),
        ],
      ),
    );
  }
}

/// A tappable option row for action/choice sheets: 3D icon, title,
/// subtitle, and a trailing check or chevron.
class SheetOption extends StatelessWidget {
  const SheetOption({
    super.key,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.glyph,
    this.icon,
    this.color,
    this.selected = false,
    this.trailing,
    this.destructive = false,
  });

  final String title;
  final String? subtitle;
  final FinGlyph? glyph;
  final IconData? icon;
  final Color? color;
  final bool selected;
  final Widget? trailing;
  final bool destructive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = destructive
        ? context.semantic.expense
        : (color ?? Theme.of(context).colorScheme.primary);
    final s = context.surfaces;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Pressable(
        onTap: onTap,
        pressedScale: 0.97,
        child: AnimatedContainer(
          duration: AppMotion.medium,
          curve: AppMotion.emphasized,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: selected
                ? accent.withValues(alpha: s.isDark ? 0.18 : 0.08)
                : s.card,
            border: Border.all(
              color: selected ? accent : context.semantic.border,
              width: selected ? 1.6 : 1,
            ),
            boxShadow: selected ? null : s.elevation(0.4),
          ),
          child: Row(
            children: [
              if (glyph != null || icon != null) ...[
                Icon3D(
                  glyph: glyph,
                  icon: icon,
                  color: destructive ? accent : color,
                  size: 40,
                  style: Icon3DStyle.soft,
                ),
                const SizedBox(width: 14),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: destructive ? accent : null,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: context.semantic.muted,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              trailing ??
                  AnimatedSwitcher(
                    duration: AppMotion.fast,
                    transitionBuilder: (c, a) =>
                        ScaleTransition(scale: a, child: c),
                    child: selected
                        ? Icon(Icons.check_circle_rounded,
                            key: const ValueKey('sel'), color: accent,)
                        : Icon(Icons.chevron_right_rounded,
                            key: const ValueKey('chev'),
                            color: context.semantic.muted,),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shows a list of [SheetOption]s and returns the chosen value.
Future<T?> showChoiceSheet<T>(
  BuildContext context, {
  required String title,
  String? subtitle,
  FinGlyph? glyph,
  required List<ChoiceOption<T>> options,
  T? selected,
}) {
  return showAppSheet<T>(
    context,
    title: title,
    subtitle: subtitle,
    glyph: glyph,
    builder: (context, _) => Column(
      children: [
        for (var i = 0; i < options.length; i++)
          Entrance(
            index: i,
            offset: 14,
            child: SheetOption(
              title: options[i].label,
              subtitle: options[i].subtitle,
              glyph: options[i].glyph,
              icon: options[i].icon,
              color: options[i].color,
              destructive: options[i].destructive,
              selected: selected != null && options[i].value == selected,
              onTap: () => Navigator.of(context).pop(options[i].value),
            ),
          ),
      ],
    ),
  );
}

/// One row in a [showChoiceSheet].
class ChoiceOption<T> {
  const ChoiceOption({
    required this.value,
    required this.label,
    this.subtitle,
    this.glyph,
    this.icon,
    this.color,
    this.destructive = false,
  });
  final T value;
  final String label;
  final String? subtitle;
  final FinGlyph? glyph;
  final IconData? icon;
  final Color? color;
  final bool destructive;
}
