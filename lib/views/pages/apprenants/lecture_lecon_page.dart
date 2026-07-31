// lib/views/pages/apprenants/lecture_lecon_page.dart
//
// Refondu en P11.4 (rituel P5.0) : bascule vers `YkPdfViewer` (déjà bâti
// pour cet écran précisément, voir son commentaire de tête) — remplace le
// `PDFView` fait main + filigrane statique "Yéki" par un filigrane
// DYNAMIQUE nom + identifiant (protection du contenu, CDC Backend). Le
// triple-FAB déprécié `YekiFabs` (Répétiteur/IA/Forum) cède la place à 2
// `YkFab` (IA, Forum) — le bouton Répétiteur n'y était qu'un placeholder
// "Bientôt disponible" (aucune navigation), et la maquette de cet écran
// ne prévoit pas cette action ici (elle vit dans `lecons_cours.dart` et
// `cours_detail_page.dart`, P11.3/P11.4).

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';

import 'package:yeki/core/constants/api_constants.dart';
import 'package:yeki/core/design/components/components.dart';
import 'package:yeki/core/design/tokens/tokens.dart';
import 'package:yeki/core/network/api_client.dart';
import 'package:yeki/core/router/route_names.dart';
import 'package:yeki/repositories/auth_repository.dart';
import 'package:yeki/repositories/cours_repository.dart';
import 'package:yeki/views/pages/apprenants/lecon_models.dart';
import 'package:yeki/widgets/form_preoccupation_sheet.dart';

String _urlComplete(String? chemin) {
  if (chemin == null || chemin.isEmpty) return '';
  return chemin.startsWith('http') ? chemin : '${ApiConstants.baseUrl}$chemin';
}

class LectureLeconPage extends StatefulWidget {
  final int leconId;
  final int coursId;
  final String coursTitre;
  final int coursColor;

  const LectureLeconPage({
    super.key,
    required this.leconId,
    required this.coursId,
    required this.coursTitre,
    required this.coursColor,
  });

  @override
  State<LectureLeconPage> createState() => _LectureLeconPageState();
}

class _LectureLeconPageState extends State<LectureLeconPage> {
  final _repo = CoursRepository();
  bool _loading = true;
  List<LeconItem> _lecons = [];
  int _index = 0;
  String? _watermark;

  bool _pdfLoading = true;
  String? _pdfPath;
  String? _pdfError;
  int _pdfPages = 0;
  int _pdfCurrent = 0;

  Color get _accent => Color(widget.coursColor);
  LeconItem get _lecon => _lecons[_index];

  @override
  void initState() {
    super.initState();
    _charger();
    _chargerWatermark();
  }

  @override
  void dispose() {
    // Suppression au mieux (P12.3, dispose() est synchrone) — le PDF
    // temporaire de la leçon en cours à la fermeture de l'écran ne doit
    // pas persister en clair indéfiniment dans le dossier temporaire.
    final chemin = _pdfPath;
    if (chemin != null) {
      File(chemin).delete().catchError((_) => File(chemin));
    }
    super.dispose();
  }

  Future<void> _chargerWatermark() async {
    try {
      final profil = await AuthRepository().getCurrentUser();
      final nom = '${profil.firstName} ${profil.lastName}'.trim();
      if (mounted) setState(() => _watermark = '${nom.isEmpty ? profil.username : nom} • #${profil.id}');
    } catch (_) {
      if (mounted) setState(() => _watermark = 'Yéki');
    }
  }

  Future<void> _charger() async {
    setState(() => _loading = true);
    try {
      final modules = await _repo.modules(widget.coursId);
      final lecons = modules.tousLesLecons();
      final index = lecons.indexWhere((l) => l.id == widget.leconId);
      if (mounted) {
        setState(() {
          _lecons = lecons;
          _index = index >= 0 ? index : 0;
        });
      }
      if (lecons.isNotEmpty) await _chargerPdf();
    } catch (_) {
      if (mounted) YkSnack.error(context, 'Erreur de chargement.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Supprime le PDF temporaire de la leçon précédente (P12.3) — sans ce
  /// nettoyage, `_chargerPdf()` accumulait un fichier en clair par leçon
  /// visitée dans `getTemporaryDirectory()`, jamais supprimé.
  Future<void> _supprimerPdfTemporaire() async {
    final chemin = _pdfPath;
    if (chemin == null) return;
    try {
      final fichier = File(chemin);
      if (await fichier.exists()) await fichier.delete();
    } catch (_) {}
  }

  Future<void> _chargerPdf() async {
    await _supprimerPdfTemporaire();
    if (!_lecon.hasPdf) {
      setState(() {
        _pdfLoading = false;
        _pdfPath = null;
      });
      return;
    }
    setState(() {
      _pdfLoading = true;
      _pdfError = null;
      _pdfPath = null;
      _pdfPages = 0;
      _pdfCurrent = 0;
    });
    try {
      final url = _urlComplete(_lecon.pdfUrl);
      final response = await ApiClient().downloadStream(url);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/lecon_${_lecon.id}.pdf');
      final sink = file.openWrite();
      await for (final chunk in response.data!.stream) {
        sink.add(chunk);
      }
      await sink.close();
      await _repo.marquerLecon(_lecon.id, 10);
      if (mounted) setState(() { _pdfPath = file.path; _pdfLoading = false; });
    } catch (_) {
      if (mounted) setState(() { _pdfError = 'Impossible de charger le PDF.'; _pdfLoading = false; });
    }
  }

  Future<void> _changerLecon(LeconItem lecon) async {
    final index = _lecons.indexWhere((l) => l.id == lecon.id);
    if (index == -1) return;
    setState(() => _index = index);
    await _chargerPdf();
  }

  Future<void> _marquerTerminee() async {
    if (_lecon.estTerminee) return;
    try {
      await _repo.marquerLecon(_lecon.id, 100);
      if (mounted) {
        setState(() => _lecons[_index] = _lecon.copyWith(estTerminee: true));
        YkSnack.success(context, 'Leçon marquée comme terminée !');
      }
    } catch (_) {
      if (mounted) YkSnack.error(context, 'Erreur réseau.');
    }
  }

  void _onPdfPageChanged(int page, int total) {
    setState(() { _pdfCurrent = page; _pdfPages = total; });
    if (total > 0 && page == total - 1) {
      _repo.marquerLecon(_lecon.id, 100);
    } else if (total > 0 && page >= total ~/ 2) {
      _repo.marquerLecon(_lecon.id, 50);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(backgroundColor: YkColors.background(context), body: Center(child: YkProgress(shape: YkProgressShape.circular, color: _accent)));
    }
    if (_lecons.isEmpty) {
      return Scaffold(
        backgroundColor: YkColors.background(context),
        body: YkEmptyState(
          icon: Icons.error_outline_rounded,
          title: 'Leçon introuvable',
          message: 'Cette leçon a peut-être été retirée.',
          actionLabel: 'Retour',
          onAction: () => Navigator.pop(context),
        ),
      );
    }

    final lecon = _lecon;
    final precedente = _index > 0 ? _lecons[_index - 1] : null;
    final suivante = _index < _lecons.length - 1 ? _lecons[_index + 1] : null;

    return Scaffold(
      backgroundColor: YkColors.background(context),
      appBar: AppBar(
        backgroundColor: _accent,
        foregroundColor: Colors.white,
        title: Text(lecon.titre, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: Icon(lecon.estTerminee ? Icons.check_circle_rounded : Icons.check_circle_outline_rounded),
            tooltip: 'Marquer comme terminée',
            onPressed: _marquerTerminee,
          ),
        ],
        bottom: _pdfPages > 0
            ? PreferredSize(
                preferredSize: const Size.fromHeight(4),
                child: LinearProgressIndicator(value: (_pdfCurrent + 1) / _pdfPages, minHeight: 4, backgroundColor: Colors.white24),
              )
            : null,
      ),
      body: Column(
        children: [
          Expanded(child: _buildPdfZone(context, lecon)),
          if (precedente != null || suivante != null) _buildBarreNavigation(context, precedente, suivante),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          YkFab(
            icon: Icons.psychology_rounded,
            label: 'Yéki IA',
            variant: YkFabVariant.small,
            backgroundColor: _accent,
            onPressed: () => context.pushNamed(
              AppRoute.iaChat,
              pathParameters: {'coursId': widget.coursId.toString()},
              queryParameters: {
                'coursTitre': widget.coursTitre,
                'sourceInitiale': 'lecon',
                'sourceId': lecon.id.toString(),
                'sourceTitreInit': lecon.titre,
              },
            ),
          ),
          SizedBox(height: YkSpacing.sm),
          YkFab(
            icon: Icons.forum_rounded,
            label: 'Forum',
            variant: YkFabVariant.small,
            backgroundColor: YkColors.info,
            onPressed: () => ouvrirPreoccupation(
              context: context,
              source: 'lecon',
              leconId: lecon.id,
              leconTitre: lecon.titre,
              coursId: widget.coursId,
              coursTitre: widget.coursTitre,
              coursColor: widget.coursColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPdfZone(BuildContext context, LeconItem lecon) {
    if (!lecon.hasPdf) {
      return YkEmptyState(
        icon: Icons.picture_as_pdf_outlined,
        title: 'Pas de support PDF',
        message: lecon.description.isNotEmpty ? lecon.description : 'Cette leçon ne propose pas de support PDF.',
      );
    }
    if (_pdfLoading) {
      return Center(child: YkProgress(shape: YkProgressShape.circular, color: _accent));
    }
    if (_pdfError != null || _pdfPath == null) {
      return YkEmptyState(
        icon: Icons.error_outline_rounded,
        title: 'Erreur de chargement',
        message: _pdfError ?? 'Réessayez.',
        actionLabel: 'Réessayer',
        onAction: _chargerPdf,
      );
    }
    return YkPdfViewer(
      filePath: _pdfPath!,
      watermarkText: _watermark ?? 'Yéki',
      onPageChanged: _onPdfPageChanged,
    );
  }

  Widget _buildBarreNavigation(BuildContext context, LeconItem? precedente, LeconItem? suivante) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: YkSpacing.sm, vertical: YkSpacing.xs),
      decoration: BoxDecoration(
        color: YkColors.surface(context),
        border: Border(top: BorderSide(color: YkColors.border(context))),
      ),
      child: Row(
        children: [
          Expanded(
            child: precedente == null
                ? const SizedBox.shrink()
                : TextButton.icon(
                    onPressed: () => _changerLecon(precedente),
                    icon: const Icon(Icons.chevron_left_rounded),
                    label: Text(precedente.titre, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
          ),
          Expanded(
            child: suivante == null
                ? const SizedBox.shrink()
                : TextButton(
                    onPressed: () => _changerLecon(suivante),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Flexible(child: Text(suivante.titre, maxLines: 1, overflow: TextOverflow.ellipsis)),
                        const Icon(Icons.chevron_right_rounded),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
