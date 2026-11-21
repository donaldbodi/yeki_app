// lib/widgets/bandeau_hors_ligne.dart
//
// Bandeau fin affiché sous l'en-tête quand le téléphone n'a pas de réseau
// (comme WhatsApp) : l'app montre alors les dernières données gardées, et
// les envois partent au retour de la connexion. Rien sur le web.

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:yeki/core/design/tokens/tokens.dart';
import 'package:yeki/core/providers/connectivity_provider.dart';

class BandeauHorsLigne extends ConsumerWidget {
  const BandeauHorsLigne({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enLigne = ref.watch(connectivityProvider);
    if (kIsWeb || enLigne) return const SizedBox.shrink();
    return Semantics(
      liveRegion: true,
      child: Material(
        color: YkColors.warning.withValues(alpha: 0.14),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: YkSpacing.md, vertical: YkSpacing.xs),
          child: Row(
            children: [
              Icon(Icons.cloud_off_rounded, size: 18, color: YkColors.warning),
              SizedBox(width: YkSpacing.xs),
              Expanded(
                child: Text(
                  'Hors ligne : dernières données enregistrées. Vos envois partiront au retour du réseau.',
                  style: YkTypography.caption(context).copyWith(color: YkColors.textPrimary(context)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
