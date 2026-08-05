import 'package:flutter/material.dart';

import '../../tokens/tokens.dart';

class YkLessonFeedItem {
  const YkLessonFeedItem({
    required this.id,
    required this.player,
    this.isLiked = false,
    this.isFavorite = false,
  });

  final String id;

  /// Le contenu de la « page » (vidéo, PDF, texte riche…) — fourni par
  /// l'appelant, ce composant ne sait rien du type de média.
  final Widget player;
  final bool isLiked;
  final bool isFavorite;
}

/// Flux vertical immersif « style TikTok à la Yéki » — CDC_DESIGN §5.3.5,
/// pour `detail_lecon_page.dart` (aujourd'hui une page scrollable
/// classique, sans rapport — composant entièrement nouveau, écran non
/// migré dans ce ticket).
///
/// Toutes les actions sont des callbacks : ce composant ne fait aucun
/// appel réseau (like/favori/téléchargement/partage restent la
/// responsabilité de l'écran appelant).
class YkLessonFeed extends StatefulWidget {
  const YkLessonFeed({
    super.key,
    required this.items,
    required this.onLike,
    required this.onFavorite,
    required this.onPreoccupation,
    required this.onShare,
    required this.onDownload,
    this.onSupplements,
    this.onPageChanged,
    this.initialIndex = 0,
  });

  final List<YkLessonFeedItem> items;
  final ValueChanged<String> onLike;
  final ValueChanged<String> onFavorite;
  final ValueChanged<String> onPreoccupation;
  final ValueChanged<String> onShare;
  final ValueChanged<String> onDownload;
  final ValueChanged<String>? onSupplements;
  final ValueChanged<int>? onPageChanged;

  /// Page affichée à l'ouverture — l'appelant connaît déjà la leçon
  /// exacte demandée (ex. clic sur une leçon précise dans le sommaire du
  /// cours) ; `0` par défaut (comportement inchangé pour tout appelant
  /// qui n'a pas de leçon précise à cibler).
  final int initialIndex;

  @override
  State<YkLessonFeed> createState() => _YkLessonFeedState();
}

class _YkLessonFeedState extends State<YkLessonFeed> {
  late final PageController _controller = PageController(initialPage: widget.initialIndex);
  late int _index = widget.initialIndex;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final current = widget.items[_index];

    return Stack(
      children: [
        PageView.builder(
          controller: _controller,
          scrollDirection: Axis.vertical,
          itemCount: widget.items.length,
          onPageChanged: (i) {
            setState(() => _index = i);
            widget.onPageChanged?.call(i);
          },
          itemBuilder: (context, i) => widget.items[i].player,
        ),
        Positioned(
          top: YkSpacing.sm,
          left: YkSpacing.md,
          right: YkSpacing.md,
          child: Row(
            children: [
              for (var i = 0; i < widget.items.length; i++)
                Expanded(
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 2),
                    height: 3,
                    decoration: BoxDecoration(
                      color: i <= _index ? YkColors.accent(context) : Colors.white.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(YkRadius.full),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Positioned(
          right: YkSpacing.sm,
          bottom: YkSpacing.xl,
          child: Column(
            children: [
              _FeedAction(
                icon: current.isLiked ? Icons.favorite : Icons.favorite_border,
                label: 'Aimer',
                onTap: () => widget.onLike(current.id),
              ),
              _FeedAction(
                icon: current.isFavorite ? Icons.bookmark : Icons.bookmark_border,
                label: 'Favori',
                onTap: () => widget.onFavorite(current.id),
              ),
              _FeedAction(
                icon: Icons.help_outline,
                label: 'Préoccupation',
                onTap: () => widget.onPreoccupation(current.id),
              ),
              _FeedAction(
                icon: Icons.share_outlined,
                label: 'Partager',
                onTap: () => widget.onShare(current.id),
              ),
              _FeedAction(
                icon: Icons.download_outlined,
                label: 'Télécharger',
                onTap: () => widget.onDownload(current.id),
              ),
              if (widget.onSupplements != null)
                _FeedAction(
                  icon: Icons.library_add_outlined,
                  label: 'Suppléments',
                  onTap: () => widget.onSupplements!(current.id),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FeedAction extends StatelessWidget {
  const _FeedAction({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(YkSpacing.xs),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 28, shadows: const [Shadow(blurRadius: 4, color: Colors.black54)]),
              Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, shadows: [Shadow(blurRadius: 4, color: Colors.black54)])),
            ],
          ),
        ),
      ),
    );
  }
}
