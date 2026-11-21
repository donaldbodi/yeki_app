import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

import '../../tokens/tokens.dart';
import '../actions/yk_icon_button.dart';

/// Lecteur PDF — CDC_DESIGN §5.3.5 : pagination, favoris, reprise,
/// **filigrane** identifiant l'apprenant (nom + identifiant — voir CDC
/// Backend, protection du contenu).
///
/// Bâti sur `flutter_pdfview` (déjà utilisé par `lecture_lecon_page
/// .dart`, qui a déjà un filigrane texte statique "Yéki" — généralisé
/// ici avec un texte dynamique, jamais en dur). `syncfusion_flutter_pdfviewer`
/// est également en dépendance mais inutilisé nulle part — redondance
/// signalée (P4.7), pas retirée.
///
/// **Limite assumée** : `flutter_pdfview` est un widget de plateforme
/// natif sans accès à la couche texte — pas de recherche plein texte
/// possible avec ce paquet (contrairement à la « recherche » listée par
/// le CDC). Le zoom est celui du rendu natif (pincer), pas ajouté ici.
class YkPdfViewer extends StatefulWidget {
  const YkPdfViewer({
    super.key,
    required this.filePath,
    required this.watermarkText,
    this.initialPage = 0,
    this.bookmarkedPages = const {},
    this.onToggleBookmark,
    this.onPageChanged,
  });

  /// Chemin local du fichier déjà téléchargé — ce composant ne
  /// télécharge rien lui-même (cohérent avec `YkFileUpload`/`YkForm` :
  /// il reçoit des données prêtes, pas un réseau à gérer).
  final String filePath;

  /// Construit par l'appelant (ex. `'${nom} • #${matricule}'`) — jamais
  /// une valeur figée dans le composant.
  final String watermarkText;
  final int initialPage;
  final Set<int> bookmarkedPages;
  final ValueChanged<int>? onToggleBookmark;
  final void Function(int page, int total)? onPageChanged;

  @override
  State<YkPdfViewer> createState() => _YkPdfViewerState();
}

class _YkPdfViewerState extends State<YkPdfViewer> {
  int _pages = 0;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
  }

  @override
  Widget build(BuildContext context) {
    final bookmarked = widget.bookmarkedPages.contains(_currentPage);

    return Stack(
      children: [
        PDFView(
          filePath: widget.filePath,
          defaultPage: widget.initialPage,
          onRender: (pages) => setState(() => _pages = pages ?? 0),
          onPageChanged: (page, total) {
            setState(() => _currentPage = page ?? 0);
            widget.onPageChanged?.call(page ?? 0, total ?? _pages);
          },
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _YkWatermarkPainter(
                text: widget.watermarkText,
                color: YkColors.textPrimary(context).withValues(alpha: 0.08),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: YkSpacing.sm,
          left: YkSpacing.sm,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: YkSpacing.sm, vertical: YkSpacing.xxs),
            decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(YkRadius.full)),
            child: Text(
              '${_currentPage + 1} / $_pages',
              style: YkTypography.caption(context).copyWith(color: Colors.white),
            ),
          ),
        ),
        if (widget.onToggleBookmark != null)
          Positioned(
            bottom: YkSpacing.sm,
            right: YkSpacing.sm,
            child: YkIconButton(
              icon: bookmarked ? Icons.bookmark : Icons.bookmark_border,
              label: bookmarked ? 'Retirer des favoris' : 'Ajouter aux favoris',
              variant: YkIconButtonVariant.filled,
              onPressed: () => widget.onToggleBookmark!(_currentPage),
            ),
          ),
      ],
    );
  }
}

class _YkWatermarkPainter extends CustomPainter {
  const _YkWatermarkPainter({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w600)),
      textDirection: TextDirection.ltr,
    )..layout();

    const stepY = 140.0;
    const stepX = 220.0;
    for (double y = -size.height; y < size.height * 2; y += stepY) {
      for (double x = -size.width; x < size.width * 2; x += stepX) {
        canvas.save();
        canvas.translate(x, y);
        canvas.rotate(-0.5);
        textPainter.paint(canvas, Offset.zero);
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant _YkWatermarkPainter oldDelegate) =>
      oldDelegate.text != text || oldDelegate.color != color;
}
