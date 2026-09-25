import 'package:flutter/material.dart';

import '../../../../core/design/design.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/icon_utils.dart';
import '../../../categories/domain/category.dart';

/// A 3D donut of expenses grouped by category, with an interactive legend.
/// Tap a slice to lift it and see its amount in the centre.
class CategoryPie extends StatefulWidget {
  const CategoryPie({
    super.key,
    required this.totals,
    required this.categories,
  });

  /// categoryId -> total expense amount.
  final Map<String, double> totals;

  /// categoryId -> Category (for name + colour).
  final Map<String, Category> categories;

  @override
  State<CategoryPie> createState() => _CategoryPieState();
}

class _CategoryPieState extends State<CategoryPie> {
  int _selected = -1;

  @override
  Widget build(BuildContext context) {
    final entries = widget.totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final grand = entries.fold<double>(0, (s, e) => s + e.value);
    if (entries.isEmpty || grand <= 0) return const SizedBox.shrink();

    final data = [
      for (var i = 0; i < entries.length; i++)
        ChartDatum(
          id: entries[i].key,
          label: widget.categories[entries[i].key]?.name ?? '—',
          value: entries[i].value,
          color: AppColors.chartFor(
            widget.categories[entries[i].key]?.colorIndex ?? i,
          ),
        ),
    ];

    final donut = Donut3D(
      key: ValueKey(Object.hashAll(data.map((d) => '${d.id}${d.value}'))),
      data: data,
      size: 220,
      onSelect: (i) => setState(() => _selected = i),
      center: (sel) {
        final d = sel >= 0 ? data[sel] : null;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              d?.label ?? '100%',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: context.semantic.muted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                Formatters.moneySmart(d?.value ?? grand),
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: d?.color,
                ),
              ),
            ),
          ],
        );
      },
    );

    final legend = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < data.length; i++)
          Entrance(
            index: i,
            offset: 8,
            child: _legendRow(context, i, data[i], grand),
          ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 460) {
          return Row(
            children: [
              donut,
              const SizedBox(width: 18),
              Expanded(child: legend),
            ],
          );
        }
        return Column(
          children: [
            Center(child: donut),
            const SizedBox(height: 14),
            legend,
          ],
        );
      },
    );
  }

  Widget _legendRow(
    BuildContext context,
    int i,
    ChartDatum d,
    double grand,
  ) {
    final cat = widget.categories[d.id];
    final pct = d.value / grand;
    final sel = i == _selected;
    return AnimatedContainer(
      duration: AppMotion.medium,
      curve: AppMotion.emphasized,
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: sel ? d.color.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon3D(
            icon: cat == null
                ? Icons.category_rounded
                : iconFromCode(cat.iconCode),
            color: d.color,
            size: 30,
            style: Icon3DStyle.soft,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        d.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: sel ? FontWeight.w800 : FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Text(
                      '${Formatters.moneySmart(d.value)} · ${(pct * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        color: sel ? d.color : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                GlowBar(value: pct, color: d.color, height: 5),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
