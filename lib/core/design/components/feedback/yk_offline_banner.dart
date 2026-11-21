import 'package:flutter/material.dart';

import '../../tokens/tokens.dart';

/// Bandeau hors-ligne persistant — CDC_DESIGN §5.3.6. L'état (hors
/// ligne ou non, file de synchronisation) est fourni par l'appelant —
/// ce composant ne lit jamais `OfflineService` directement.
class YkOfflineBanner extends StatelessWidget {
  const YkOfflineBanner({super.key, required this.isOffline, this.pendingSyncCount = 0});

  final bool isOffline;
  final int pendingSyncCount;

  @override
  Widget build(BuildContext context) {
    if (!isOffline) return const SizedBox.shrink();

    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: YkSpacing.md, vertical: YkSpacing.xs),
        color: YkColors.warning,
        child: Row(
          children: [
            const Icon(Icons.wifi_off, size: 16, color: Colors.white),
            SizedBox(width: YkSpacing.xs),
            Expanded(
              child: Text(
                pendingSyncCount > 0
                    ? 'Hors ligne — $pendingSyncCount en attente de synchronisation'
                    : 'Hors ligne',
                style: YkTypography.caption(context).copyWith(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
