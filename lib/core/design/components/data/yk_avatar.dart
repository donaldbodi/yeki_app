import 'package:flutter/material.dart';

import '../../tokens/tokens.dart';

/// Taille de [YkAvatar] — CDC_DESIGN §5.3.4.
enum YkAvatarSize { xs, sm, md, lg, xl }

/// Avatar — CDC_DESIGN §5.3.4 : image, repli initiales, indicateur de
/// présence, tailles xs→xl, groupe empilé ([YkAvatarGroup]). Consolide
/// les 2 `YekiAvatar` concurrents trouvés dans les fichiers legacy.
class YkAvatar extends StatelessWidget {
  const YkAvatar({
    super.key,
    this.imageUrl,
    required this.fallbackText,
    this.size = YkAvatarSize.md,
    this.showPresence = false,
    this.isOnline = false,
  });

  final String? imageUrl;

  /// Utilisé pour l'initiale de repli (généralement le nom complet).
  final String fallbackText;
  final YkAvatarSize size;
  final bool showPresence;
  final bool isOnline;

  double get diameter => switch (size) {
    YkAvatarSize.xs => 24,
    YkAvatarSize.sm => 32,
    YkAvatarSize.md => 44,
    YkAvatarSize.lg => 56,
    YkAvatarSize.xl => 72,
  };

  @override
  Widget build(BuildContext context) {
    final initial = fallbackText.isNotEmpty ? fallbackText[0].toUpperCase() : '?';
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;

    final avatar = ClipOval(
      child: hasImage
          ? Image.network(
              imageUrl!,
              width: diameter,
              height: diameter,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stack) => _InitialCircle(initial: initial, diameter: diameter),
            )
          : _InitialCircle(initial: initial, diameter: diameter),
    );

    if (!showPresence) {
      return Semantics(label: fallbackText, image: true, child: avatar);
    }

    return Semantics(
      label: '$fallbackText, ${isOnline ? 'en ligne' : 'hors ligne'}',
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          avatar,
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: diameter * 0.28,
              height: diameter * 0.28,
              decoration: BoxDecoration(
                color: isOnline ? YkColors.success : YkColors.textTertiary(context),
                shape: BoxShape.circle,
                border: Border.all(color: YkColors.surface(context), width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InitialCircle extends StatelessWidget {
  const _InitialCircle({required this.initial, required this.diameter});
  final String initial;
  final double diameter;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter,
      height: diameter,
      alignment: Alignment.center,
      color: YkColors.accent(context).withValues(alpha: 0.15),
      child: Text(
        initial,
        style: TextStyle(
          color: YkColors.accent(context),
          fontWeight: FontWeight.w700,
          fontSize: diameter * 0.4,
        ),
      ),
    );
  }
}

/// Groupe d'avatars empilés — CDC §5.3.4.
class YkAvatarGroup extends StatelessWidget {
  const YkAvatarGroup({super.key, required this.avatars, this.max = 4, this.size = YkAvatarSize.sm});

  final List<YkAvatar> avatars;
  final int max;
  final YkAvatarSize size;

  @override
  Widget build(BuildContext context) {
    final shown = avatars.take(max).toList();
    final overflow = avatars.length - shown.length;
    final diameter = shown.isNotEmpty ? shown.first.diameter : 32.0;
    final overlap = diameter * 0.35;

    return SizedBox(
      height: diameter,
      width: diameter + (shown.length - 1) * (diameter - overlap) + (overflow > 0 ? diameter - overlap : 0),
      child: Stack(
        children: [
          for (var i = 0; i < shown.length; i++)
            Positioned(
              left: i * (diameter - overlap),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: YkColors.surface(context), width: 2),
                ),
                child: shown[i],
              ),
            ),
          if (overflow > 0)
            Positioned(
              left: shown.length * (diameter - overlap),
              child: Container(
                width: diameter,
                height: diameter,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: YkColors.surfaceVariant(context),
                  border: Border.all(color: YkColors.surface(context), width: 2),
                ),
                alignment: Alignment.center,
                child: Text(
                  '+$overflow',
                  style: TextStyle(color: YkColors.textSecondary(context), fontSize: diameter * 0.32),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
