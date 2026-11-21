import 'package:flutter/material.dart';

import '../../tokens/tokens.dart';

/// Visionneuse d'image — CDC_DESIGN §5.3.5 : zoom, galerie, chargement
/// progressif, repli en cas d'erreur. Entièrement bâti sur les widgets
/// Flutter natifs (`InteractiveViewer`, `Image.network.loadingBuilder`)
/// — aucune dépendance supplémentaire nécessaire.
class YkImageViewer extends StatelessWidget {
  const YkImageViewer({super.key, required this.imageUrls, this.initialIndex = 0});

  final List<String> imageUrls;
  final int initialIndex;

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: PageController(initialPage: initialIndex),
      itemCount: imageUrls.length,
      itemBuilder: (context, index) => InteractiveViewer(
        maxScale: 4,
        child: Center(
          child: Image.network(
            imageUrls[index],
            fit: BoxFit.contain,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              final total = progress.expectedTotalBytes;
              return Center(
                child: CircularProgressIndicator(
                  value: total != null ? progress.cumulativeBytesLoaded / total : null,
                  color: YkColors.accent(context),
                ),
              );
            },
            errorBuilder: (context, error, stack) => Icon(
              Icons.broken_image_outlined,
              size: 48,
              color: YkColors.textSecondary(context),
            ),
          ),
        ),
      ),
    );
  }
}
