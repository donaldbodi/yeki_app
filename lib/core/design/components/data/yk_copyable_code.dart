import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../tokens/tokens.dart';
import '../feedback/yk_toast.dart';

/// Code (USSD, numéro de dépôt…) tapable en un geste pour le copier —
/// P9.3 : sans ce composant, l'apprenant recopierait un code USSD à la
/// main, source d'erreur de frappe qui fait échouer le dépôt. Aucun
/// équivalent trouvé dans le projet (`Clipboard.setData` : zéro
/// occurrence ailleurs avant ce composant).
class YkCopyableCode extends StatelessWidget {
  const YkCopyableCode({super.key, required this.code, this.label});

  /// Le code affiché ET copié tel quel (ex. `#150*1#`, un numéro de
  /// téléphone…).
  final String code;

  /// Libellé optionnel au-dessus du code (ex. « Code USSD Orange Money »).
  final String? label;

  Future<void> _copier(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (context.mounted) YkToast.show(context, 'Copié : $code');
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${label != null ? '$label : ' : ''}$code. Toucher pour copier.',
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(YkRadius.md),
          onTap: () => _copier(context),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: YkSpacing.md, vertical: YkSpacing.sm),
            decoration: BoxDecoration(
              color: YkColors.surfaceVariant(context),
              borderRadius: BorderRadius.circular(YkRadius.md),
              border: Border.all(color: YkColors.border(context)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (label != null) ...[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          label!,
                          style: YkTypography.caption(context).copyWith(color: YkColors.textSecondary(context)),
                        ),
                        Text(
                          code,
                          style: YkTypography.h4(
                            context,
                          ).copyWith(color: YkColors.textPrimary(context), fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ] else
                  Expanded(
                    child: Text(
                      code,
                      style: YkTypography.h4(
                        context,
                      ).copyWith(color: YkColors.textPrimary(context), fontWeight: FontWeight.w700),
                    ),
                  ),
                SizedBox(width: YkSpacing.sm),
                Icon(Icons.copy_rounded, size: 20, color: YkColors.accent(context)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
