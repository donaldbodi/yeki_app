import 'package:flutter/material.dart';

import '../../tokens/tokens.dart';
import '../containers/yk_card.dart';

/// Carte de statistique — CDC_DESIGN §5.3.4 : valeur, libellé,
/// variation, icône, mini-graphique. Remplace les dizaines de cartes de
/// statistiques dupliquées dans les 5 dashboards (écrans non migrés ici).
class YkStatCard extends StatelessWidget {
  const YkStatCard({
    super.key,
    required this.value,
    required this.label,
    this.icon,
    this.trendLabel,
    this.trendPositive,
    this.sparkline,
  });

  final String value;
  final String label;
  final IconData? icon;

  /// Ex. « +12 % ».
  final String? trendLabel;
  final bool? trendPositive;
  final Widget? sparkline;

  @override
  Widget build(BuildContext context) {
    return YkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (icon != null)
                Container(
                  padding: EdgeInsets.all(YkSpacing.xs),
                  decoration: BoxDecoration(
                    color: YkColors.accent(context).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(YkRadius.sm),
                  ),
                  child: Icon(icon, color: YkColors.accent(context), size: 20),
                ),
              const Spacer(),
              if (trendLabel != null)
                Row(
                  children: [
                    Icon(
                      (trendPositive ?? true) ? Icons.arrow_upward : Icons.arrow_downward,
                      size: 14,
                      color: (trendPositive ?? true) ? YkColors.success : YkColors.error,
                    ),
                    Text(
                      trendLabel!,
                      style: YkTypography.caption(
                        context,
                      ).copyWith(color: (trendPositive ?? true) ? YkColors.success : YkColors.error),
                    ),
                  ],
                ),
            ],
          ),
          SizedBox(height: YkSpacing.sm),
          Text(
            value,
            style: YkTypography.h2(context).copyWith(color: YkColors.textPrimary(context)),
          ),
          Text(
            label,
            style: YkTypography.bodySm(context).copyWith(color: YkColors.textSecondary(context)),
          ),
          if (sparkline != null) ...[SizedBox(height: YkSpacing.sm), sparkline!],
        ],
      ),
    );
  }
}
