import 'package:flutter/material.dart';

import '../../tokens/tokens.dart';

/// Forme du squelette — CDC_DESIGN §5.3.6.
enum YkSkeletonShape { line, card, list, grid, table }

/// Indicateur de chargement en silhouette — CDC_DESIGN §5.3.6.
///
/// Remplace tout spinner plein écran (`Center(child: YekiLoader())`
/// recopié à la main dans la quasi-totalité des écrans).
class YkSkeleton extends StatelessWidget {
  const YkSkeleton.line({super.key, this.width, double height = 16})
    : shape = YkSkeletonShape.line,
      _height = height,
      itemCount = 1,
      crossAxisCount = 1,
      rows = 1,
      columns = 1;

  const YkSkeleton.card({super.key, this.width, double height = 120})
    : shape = YkSkeletonShape.card,
      _height = height,
      itemCount = 1,
      crossAxisCount = 1,
      rows = 1,
      columns = 1;

  const YkSkeleton.list({super.key, this.itemCount = 3, double itemHeight = 64})
    : shape = YkSkeletonShape.list,
      _height = itemHeight,
      width = null,
      crossAxisCount = 1,
      rows = 1,
      columns = 1;

  const YkSkeleton.grid({
    super.key,
    this.crossAxisCount = 2,
    this.itemCount = 4,
    double itemHeight = 100,
  }) : shape = YkSkeletonShape.grid,
       _height = itemHeight,
       width = null,
       rows = 1,
       columns = 1;

  const YkSkeleton.table({super.key, this.rows = 3, this.columns = 3, double rowHeight = 40})
    : shape = YkSkeletonShape.table,
      _height = rowHeight,
      width = null,
      itemCount = 1,
      crossAxisCount = 1;

  final YkSkeletonShape shape;
  final double? width;
  final double _height;
  final int itemCount;
  final int crossAxisCount;
  final int rows;
  final int columns;

  @override
  Widget build(BuildContext context) {
    switch (shape) {
      case YkSkeletonShape.line:
        return _ShimmerBox(width: width, height: _height, borderRadius: BorderRadius.circular(YkRadius.xs));
      case YkSkeletonShape.card:
        return _ShimmerBox(
          width: width,
          height: _height,
          borderRadius: BorderRadius.circular(YkRadius.md),
        );
      case YkSkeletonShape.list:
        return Column(
          children: [
            for (var i = 0; i < itemCount; i++) ...[
              _ShimmerBox(height: _height, borderRadius: BorderRadius.circular(YkRadius.md)),
              if (i < itemCount - 1) SizedBox(height: YkSpacing.sm),
            ],
          ],
        );
      case YkSkeletonShape.grid:
        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: YkSpacing.sm,
          crossAxisSpacing: YkSpacing.sm,
          childAspectRatio: 1,
          children: [
            for (var i = 0; i < itemCount; i++)
              _ShimmerBox(height: _height, borderRadius: BorderRadius.circular(YkRadius.md)),
          ],
        );
      case YkSkeletonShape.table:
        return Column(
          children: [
            for (var r = 0; r < rows; r++) ...[
              Row(
                children: [
                  for (var c = 0; c < columns; c++) ...[
                    Expanded(
                      child: _ShimmerBox(
                        height: _height,
                        borderRadius: BorderRadius.circular(YkRadius.xs),
                      ),
                    ),
                    if (c < columns - 1) SizedBox(width: YkSpacing.sm),
                  ],
                ],
              ),
              if (r < rows - 1) SizedBox(height: YkSpacing.xs),
            ],
          ],
        );
    }
  }
}

class _ShimmerBox extends StatefulWidget {
  const _ShimmerBox({this.width, required this.height, this.borderRadius});

  final double? width;
  final double height;
  final BorderRadius? borderRadius;

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );
  bool _reduced = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduced != _reduced || !_ctrl.isAnimating) {
      _reduced = reduced;
      if (reduced) {
        _ctrl.stop();
        _ctrl.value = 0.5;
      } else {
        _ctrl.repeat(reverse: true);
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = YkColors.surfaceVariant(context);
    final highlight = YkColors.border(context);
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final color = Color.lerp(base, highlight, _ctrl.value)!;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: widget.borderRadius ?? BorderRadius.circular(YkRadius.xs),
          ),
        );
      },
    );
  }
}
