import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../categories/domain/category.dart';

/// A donut chart of this month's expenses grouped by category, with a legend.
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
  int _touched = -1;

  @override
  Widget build(BuildContext context) {
    final entries = widget.totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final grand = entries.fold<double>(0, (s, e) => s + e.value);
    if (entries.isEmpty || grand <= 0) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth > 420;
        final chart = AspectRatio(
          aspectRatio: 1,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 48,
              pieTouchData: PieTouchData(
                touchCallback: (event, response) {
                  setState(() {
                    _touched =
                        response?.touchedSection?.touchedSectionIndex ?? -1;
                  });
                },
              ),
              sections: [
                for (var i = 0; i < entries.length; i++)
                  _section(i, entries[i], grand),
              ],
            ),
          ),
        );

        final legend = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < entries.length; i++)
              _legendRow(context, i, entries[i], grand),
          ],
        );

        if (wide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(width: 220, child: chart),
              const SizedBox(width: 20),
              Expanded(child: legend),
            ],
          );
        }
        return Column(
          children: [
            SizedBox(height: 220, child: chart),
            const SizedBox(height: 16),
            legend,
          ],
        );
      },
    );
  }

  PieChartSectionData _section(
      int i, MapEntry<String, double> e, double grand) {
    final cat = widget.categories[e.key];
    final color = AppColors.chartFor(cat?.colorIndex ?? i);
    final pct = e.value / grand * 100;
    final touched = i == _touched;
    return PieChartSectionData(
      color: color,
      value: e.value,
      title: '${pct.toStringAsFixed(0)}%',
      radius: touched ? 62 : 54,
      titleStyle: TextStyle(
        fontSize: touched ? 14 : 12,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    );
  }

  Widget _legendRow(
      BuildContext context, int i, MapEntry<String, double> e, double grand) {
    final cat = widget.categories[e.key];
    final color = AppColors.chartFor(cat?.colorIndex ?? i);
    final name = cat?.name ?? '—';
    final pct = (e.value / grand * 100).toStringAsFixed(0);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            height: 12,
            width: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium),
          ),
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 130),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text('${Formatters.moneySmart(e.value)} · $pct%',
                  maxLines: 1,
                  softWrap: false,
                  style: Theme.of(context).textTheme.labelMedium),
            ),
          ),
        ],
      ),
    );
  }
}
