import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/design/design.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

/// Branded header (logo + title + subtitle) on a light surface.
class BrandHeader extends StatelessWidget {
  const BrandHeader({super.key, required this.title, this.subtitle});
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Entrance(
          scaleFrom: 0.7,
          child: BrandLogo(size: 64, halo: false),
        ),
        const SizedBox(height: 18),
        Text(title, style: text.headlineMedium),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(
            subtitle!,
            style: text.bodyMedium?.copyWith(color: context.semantic.muted),
          ),
        ],
      ],
    );
  }
}

/// Shared layout for Login / Register / Forgot: a navy vault hero with the
/// floating logo and coins, and a raised form card that overlaps it.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.children,
    this.subtitle,
    this.onBack,
    this.footer,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final List<Widget> children;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Scaffold(
      body: AmbientBackground(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  HeroPanel(
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(36),
                    ),
                    padding: EdgeInsets.fromLTRB(24, top + 14, 24, 56),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Positioned(
                          right: -4,
                          top: 18,
                          child: FloatingCoins(),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (onBack != null) ...[
                              IconOrb(
                                icon: Icons.arrow_back_rounded,
                                onDark: true,
                                onTap: onBack,
                              ),
                              const SizedBox(height: 16),
                            ] else
                              const SizedBox(height: 20),
                            Entrance(
                              scaleFrom: 0.6,
                              child: Padding(
                                padding: const EdgeInsets.only(right: 84),
                                child: Row(
                                  children: [
                                    const BrandLogo(
                                      size: 70,
                                      haloColor: AppColors.accent,
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            AppConstants.appName,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleLarge
                                                ?.copyWith(color: Colors.white),
                                          ),
                                          Text(
                                            AppConstants.slogan,
                                            style: TextStyle(
                                              color: Colors.white
                                                  .withValues(alpha: 0.7),
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          const Text(
                                            AppConstants.hashtag,
                                            style: TextStyle(
                                              color: AppColors.accentSoft,
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            Entrance(
                              index: 1,
                              child: Padding(
                                padding: const EdgeInsets.only(right: 90),
                                child: Text(
                                  title,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(color: Colors.white),
                                ),
                              ),
                            ),
                            if (subtitle != null) ...[
                              const SizedBox(height: 6),
                              Entrance(
                                index: 2,
                                child: Text(
                                  subtitle!,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  Transform.translate(
                    offset: const Offset(0, -34),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Entrance(
                        index: 2,
                        offset: 40,
                        child: Surface3D(
                          radius: 30,
                          elevation: 1.4,
                          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: children,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (footer != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                      child: footer,
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

/// "—— or ——" divider used between primary and social sign-in.
class OrDivider extends StatelessWidget {
  const OrDivider({super.key, this.label = 'or'});
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.semantic.border;
    return Row(
      children: [
        Expanded(child: Divider(color: c)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: TextStyle(
              color: context.semantic.muted,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
        Expanded(child: Divider(color: c)),
      ],
    );
  }
}
