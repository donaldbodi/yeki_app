import 'package:flutter/material.dart';

import '../../tokens/tokens.dart';

class YkTimelineEntry {
  const YkTimelineEntry({required this.title, this.subtitle, this.time, this.icon, this.color});
  final String title;
  final String? subtitle;
  final String? time;
  final IconData? icon;
  final Color? color;
}

/// Chronologie — CDC_DESIGN §5.3.4 : historique d'activité, étapes d'une
/// transaction. Candidat de remplacement visuel pour
/// `historique_page.dart` (864 lignes, 34 couleurs en dur) — écran non
/// migré dans ce ticket.
class YkTimeline extends StatelessWidget {
  const YkTimeline({super.key, required this.entries});

  final List<YkTimelineEntry> entries;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < entries.length; i++)
          _TimelineRow(entry: entries[i], isLast: i == entries.length - 1),
      ],
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.entry, required this.isLast});

  final YkTimelineEntry entry;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final color = entry.color ?? YkColors.accent(context);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
                child: Icon(entry.icon ?? Icons.circle, size: 16, color: color),
              ),
              if (!isLast) Expanded(child: Container(width: 2, color: YkColors.border(context))),
            ],
          ),
          SizedBox(width: YkSpacing.sm),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: YkSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          entry.title,
                          style: YkTypography.bodyMd(context).copyWith(color: YkColors.textPrimary(context)),
                        ),
                      ),
                      if (entry.time != null)
                        Text(
                          entry.time!,
                          style: YkTypography.caption(context).copyWith(color: YkColors.textSecondary(context)),
                        ),
                    ],
                  ),
                  if (entry.subtitle != null)
                    Text(
                      entry.subtitle!,
                      style: YkTypography.bodySm(context).copyWith(color: YkColors.textSecondary(context)),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
