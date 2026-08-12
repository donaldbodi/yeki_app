// lib/features/download/presentation/download_page.dart
//
// Écran public « Télécharger l'application » — exigence explicite du
// CDC Backend (§10, "les applications mobile et bureau… seront
// téléchargées depuis la version web de l'application") : DEPUIS l'app
// Flutter elle-même (celle déployée sur Firebase Hosting), pas depuis le
// site marketing séparé (`landing-page.html`, backend Django, déjà
// corrigé dans un ticket antérieur).
//
// Réutilise `UpdateService.fetchVersion(platform:)` (nouveau, appelle
// `GET /latest-version/?platform=<x>` déjà existant) pour chaque
// plateforme — aucune nouvelle logique réseau. Une plateforme sans ligne
// `AppVersion` réelle en base affiche honnêtement « Bientôt disponible »
// (jamais un lien mort) : c'est le cas actuel d'iOS/Desktop, aucun
// binaire réel n'existe encore pour elles.

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:yeki/core/design/components/components.dart';
import 'package:yeki/core/design/tokens/tokens.dart';
import 'package:yeki/services/update_service.dart';

import 'download_controller.dart';

class DownloadPage extends StatefulWidget {
  const DownloadPage({super.key});

  @override
  State<DownloadPage> createState() => _DownloadPageState();
}

class _Plateforme {
  const _Plateforme(this.code, this.label, this.icon);
  final String code;
  final String label;
  final IconData icon;
}

const _plateformes = [
  _Plateforme('android', 'Android', Icons.android_rounded),
  _Plateforme('ios', 'iOS', Icons.apple_rounded),
  _Plateforme('desktop', 'Windows / macOS / Linux', Icons.desktop_windows_rounded),
];

class _DownloadPageState extends State<DownloadPage> {
  late final DownloadController _controller;

  @override
  void initState() {
    super.initState();
    _controller = DownloadController();
    _controller.charger();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _telecharger(UpdateInfo info) async {
    final uri = Uri.tryParse(info.downloadUrl);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  String _formatOctets(int octets) {
    if (octets <= 0) return '';
    const unites = ['o', 'Ko', 'Mo', 'Go'];
    var valeur = octets.toDouble();
    var i = 0;
    while (valeur >= 1024 && i < unites.length - 1) {
      valeur /= 1024;
      i++;
    }
    return '${valeur.toStringAsFixed(1)} ${unites[i]}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: YkColors.background(context),
      appBar: YkGradientAppBar(title: "Télécharger l'application", centerTitle: false),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => _controller.chargement
              ? Padding(padding: EdgeInsets.all(YkSpacing.md), child: YkSkeleton.list(itemCount: 3, itemHeight: 100))
              : ListView(
                  padding: EdgeInsets.all(YkSpacing.md),
                  children: [
                    Text(
                      'YÉKI est disponible sur plusieurs plateformes.',
                      style: YkTypography.h4(context).copyWith(color: YkColors.textPrimary(context)),
                    ),
                    SizedBox(height: YkSpacing.xs),
                    Text(
                      "Choisissez votre appareil pour télécharger la dernière version.",
                      style: YkTypography.bodyMd(context).copyWith(color: YkColors.textSecondary(context)),
                    ),
                    SizedBox(height: YkSpacing.lg),
                    for (final p in _plateformes) _buildCartePlateforme(context, p),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildCartePlateforme(BuildContext context, _Plateforme p) {
    final info = _controller.versions[p.code];
    final disponible = info != null;

    return Padding(
      padding: EdgeInsets.only(bottom: YkSpacing.sm),
      child: YkCard(
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(YkRadius.md),
              child: Container(
                width: 50,
                height: 50,
                color: YkColors.accent(context).withValues(alpha: 0.12),
                alignment: Alignment.center,
                child: Icon(p.icon, color: YkColors.accent(context), size: 26),
              ),
            ),
            SizedBox(width: YkSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.label, style: YkTypography.label(context).copyWith(color: YkColors.textPrimary(context))),
                  SizedBox(height: YkSpacing.xxs),
                  if (disponible)
                    Text(
                      '${info.versionName} · ${_formatOctets(info.fileSize)}',
                      style: YkTypography.caption(context).copyWith(color: YkColors.textSecondary(context)),
                    )
                  else
                    YkBadge(
                      variant: YkBadgeVariant.label,
                      label: 'Bientôt disponible',
                      color: YkColors.textTertiary(context),
                    ),
                ],
              ),
            ),
            if (disponible)
              YkButton(
                label: 'Télécharger',
                size: YkButtonSize.sm,
                icon: Icons.download_rounded,
                onPressed: () => _telecharger(info),
              ),
          ],
        ),
      ),
    );
  }
}
