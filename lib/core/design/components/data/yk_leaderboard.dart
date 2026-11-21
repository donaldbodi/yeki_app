import 'package:flutter/material.dart';

import '../../tokens/tokens.dart';
import 'yk_avatar.dart';

class YkLeaderboardEntry {
  const YkLeaderboardEntry({
    required this.rank,
    required this.name,
    required this.points,
    this.avatarUrl,
    this.delta,
    this.isCurrentUser = false,
  });

  final int rank;
  final String name;
  final int points;
  final String? avatarUrl;

  /// Variation de rang depuis la dernière période (positif = progrès).
  final int? delta;
  final bool isCurrentUser;
}

/// Classement — CDC_DESIGN §5.3.4 : rang, delta, avatar, points, mise en
/// avant de l'utilisateur courant, podium des 3 premiers. Les 2 pages de
/// classement actuelles (`classement_departement_page.dart`,
/// `classement_olympiade.dart`) n'ont pas de podium graphique — nouveauté
/// visuelle, écrans non migrés dans ce ticket.
class YkLeaderboard extends StatelessWidget {
  const YkLeaderboard({super.key, required this.entries, this.showPodium = true});

  final List<YkLeaderboardEntry> entries;
  final bool showPodium;

  @override
  Widget build(BuildContext context) {
    final hasPodium = showPodium && entries.length >= 3;
    final podium = hasPodium ? entries.take(3).toList() : const <YkLeaderboardEntry>[];
    final rest = hasPodium ? entries.skip(3).toList() : entries;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasPodium) ...[_Podium(top3: podium), SizedBox(height: YkSpacing.md)],
        for (final entry in rest) _LeaderboardTile(entry: entry),
      ],
    );
  }
}

class _Podium extends StatelessWidget {
  const _Podium({required this.top3});
  final List<YkLeaderboardEntry> top3;

  static const _medalColors = [Color(0xFFFFD700), Color(0xFFC0C0C0), Color(0xFFCD7F32)];

  @override
  Widget build(BuildContext context) {
    // Ordre visuel : 2e, 1er, 3e — le 1er au centre, plus haut.
    const order = [1, 0, 2];
    const heights = [88.0, 112.0, 72.0];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final i in order) ...[
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                YkAvatar(imageUrl: top3[i].avatarUrl, fallbackText: top3[i].name, size: YkAvatarSize.lg),
                SizedBox(height: YkSpacing.xs),
                Text(
                  top3[i].name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: YkTypography.bodySm(context).copyWith(color: YkColors.textPrimary(context)),
                ),
                Text(
                  '${top3[i].points} pts',
                  style: YkTypography.caption(context).copyWith(color: YkColors.textSecondary(context)),
                ),
                SizedBox(height: YkSpacing.xs),
                Container(
                  height: heights[order.indexOf(i)],
                  decoration: BoxDecoration(
                    color: _medalColors[i].withValues(alpha: 0.25),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(YkRadius.sm)),
                  ),
                  alignment: Alignment.topCenter,
                  padding: EdgeInsets.only(top: YkSpacing.xs),
                  child: Icon(Icons.emoji_events, color: _medalColors[i]),
                ),
              ],
            ),
          ),
          if (i != order.last) SizedBox(width: YkSpacing.xs),
        ],
      ],
    );
  }
}

class _LeaderboardTile extends StatelessWidget {
  const _LeaderboardTile({required this.entry});
  final YkLeaderboardEntry entry;

  @override
  Widget build(BuildContext context) {
    final highlight = entry.isCurrentUser;
    return Container(
      margin: EdgeInsets.only(bottom: YkSpacing.xs),
      padding: EdgeInsets.symmetric(horizontal: YkSpacing.sm, vertical: YkSpacing.xs),
      decoration: BoxDecoration(
        color: highlight ? YkColors.accent(context).withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(YkRadius.sm),
        border: highlight ? Border.all(color: YkColors.accent(context)) : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '${entry.rank}',
              style: YkTypography.label(context).copyWith(color: YkColors.textSecondary(context)),
            ),
          ),
          YkAvatar(imageUrl: entry.avatarUrl, fallbackText: entry.name, size: YkAvatarSize.sm),
          SizedBox(width: YkSpacing.sm),
          Expanded(
            child: Text(
              entry.name,
              overflow: TextOverflow.ellipsis,
              style: YkTypography.bodyMd(context).copyWith(color: YkColors.textPrimary(context)),
            ),
          ),
          if (entry.delta != null && entry.delta != 0)
            Icon(
              entry.delta! > 0 ? Icons.arrow_upward : Icons.arrow_downward,
              size: 14,
              color: entry.delta! > 0 ? YkColors.success : YkColors.error,
            ),
          SizedBox(width: YkSpacing.xs),
          Text(
            '${entry.points} pts',
            style: YkTypography.label(context).copyWith(color: YkColors.textPrimary(context)),
          ),
        ],
      ),
    );
  }
}
