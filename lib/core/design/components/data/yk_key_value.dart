import 'package:flutter/material.dart';

import '../../tokens/tokens.dart';

/// Ligne libellé/valeur — CDC_DESIGN §5.3.4. Élément atomique de toutes
/// les pages de détail.
class YkKeyValue extends StatelessWidget {
  const YkKeyValue({super.key, required this.label, required this.value, this.icon});

  final String label;
  final String value;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: YkSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: YkColors.textSecondary(context)),
            SizedBox(width: YkSpacing.xs),
          ],
          Expanded(
            child: Text(
              label,
              style: YkTypography.bodyMd(context).copyWith(color: YkColors.textSecondary(context)),
            ),
          ),
          SizedBox(width: YkSpacing.sm),
          Text(
            value,
            textAlign: TextAlign.right,
            style: YkTypography.bodyMd(
              context,
            ).copyWith(color: YkColors.textPrimary(context), fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
