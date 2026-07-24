// lib/features/devoirs_cours/presentation/devoir_detail_page.dart
//
// Écran de composition d'un devoir (P7.4) — ENSEIGNANT UNIQUEMENT,
// route dédiée `AppRoute.devoirGererEnseignant` (jamais accessible côté
// apprenant, séparation P3.3). Multi-énoncés : un énoncé → ses
// questions → un autre énoncé → ses questions (P7.1).

import 'package:flutter/material.dart';

import 'package:yeki/core/design/components/components.dart';
import 'package:yeki/core/design/tokens/tokens.dart';
import 'package:yeki/models/devoir_models.dart';

import 'devoir_detail_controller.dart';
import 'widgets/devoir_form_sheet.dart';
import 'widgets/enonce_section.dart';
import 'widgets/question_devoir_form.dart';
import 'widgets/soumissions_sheet.dart';

class DevoirDetailPage extends StatefulWidget {
  const DevoirDetailPage({
    super.key,
    required this.devoirId,
    required this.coursId,
    required this.coursTitre,
  });

  final int devoirId;
  final int coursId;
  final String coursTitre;

  @override
  State<DevoirDetailPage> createState() => _DevoirDetailPageState();
}

class _DevoirDetailPageState extends State<DevoirDetailPage> {
  late final DevoirDetailController _controller;

  @override
  void initState() {
    super.initState();
    _controller = DevoirDetailController(devoirId: widget.devoirId, coursId: widget.coursId);
    _controller.charger();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _modifierDevoir() async {
    await YkSheet.show(
      context: context,
      title: 'Modifier le devoir',
      bodyBuilder: (ctx) => DevoirFormSheet(
        existant: _controller.devoir,
        onSubmit: ({
          required titre,
          required description,
          enonce,
          required dateDebut,
          required dateLimite,
          required dureeMinutes,
          required noteSur,
          required coefficient,
          required tentativesMax,
          required typeCorrection,
          fichierCorrection,
        }) => _controller.modifier(
          titre: titre,
          description: description,
          dateDebut: dateDebut,
          dateLimite: dateLimite,
          dureeMinutes: dureeMinutes,
          noteSur: noteSur,
          coefficient: coefficient,
          tentativesMax: tentativesMax,
          typeCorrection: typeCorrection,
          fichierCorrection: fichierCorrection,
        ),
      ),
    );
  }

  Future<void> _dupliquer() async {
    final ok = await _controller.dupliquer();
    if (!mounted) return;
    ok
        ? YkSnack.success(context, 'Devoir dupliqué (brouillon créé dans ce cours).')
        : YkSnack.error(context, 'Échec de la duplication.');
  }

  Future<void> _publier() async {
    final confirme = await YkDialog.confirm(
      context: context,
      title: 'Publier ce devoir ?',
      message:
          'Après publication, vous ne pourrez plus ajouter ni modifier de question ni d\'énoncé sur ce devoir.',
      confirmLabel: 'Publier',
    );
    if (confirme != true) return;
    final message = await _controller.publier();
    if (!mounted) return;
    if (message != null) {
      YkSnack.success(context, message.isNotEmpty ? message : 'Devoir publié.');
    } else {
      YkSnack.error(context, 'Échec de la publication.');
    }
  }

  Future<void> _ajouterEnonce() async {
    var contenu = '';
    await YkSheet.show(
      context: context,
      title: 'Nouvel énoncé',
      bodyBuilder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          YkRichEditor(
            initialHtml: '',
            onChanged: (html) => contenu = html,
            onUploadImage: (_) async =>
                throw UnsupportedError('Téléversement d\'image indisponible pour le moment.'),
            imageConstraint: const YkFileConstraint(
              allowedExtensions: ['jpg', 'jpeg', 'png'],
              maxSizeBytes: 5 * 1024 * 1024,
            ),
            label: 'Contenu du nouvel énoncé',
            showEmoji: _controller.devoir?.estManuel ?? false,
          ),
          SizedBox(height: YkSpacing.md),
          YkButton(
            label: 'Ajouter l\'énoncé',
            onPressed: () async {
              if (contenu.trim().isEmpty) {
                YkSnack.error(context, 'Le contenu est requis.');
                return;
              }
              final ok = await _controller.ajouterEnonce(contenu);
              if (!ctx.mounted) return;
              if (ok) {
                Navigator.of(ctx).pop();
              } else {
                YkSnack.error(ctx, "Échec de l'ajout de l'énoncé.");
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _editerEnonce(EnonceDevoirItem enonce) async {
    var contenu = enonce.contenu;
    await YkSheet.show(
      context: context,
      title: 'Modifier l\'énoncé',
      bodyBuilder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          YkRichEditor(
            initialHtml: contenu,
            onChanged: (html) => contenu = html,
            onUploadImage: (_) async =>
                throw UnsupportedError('Téléversement d\'image indisponible pour le moment.'),
            imageConstraint: const YkFileConstraint(
              allowedExtensions: ['jpg', 'jpeg', 'png'],
              maxSizeBytes: 5 * 1024 * 1024,
            ),
            label: 'Contenu de l\'énoncé',
            showEmoji: _controller.devoir?.estManuel ?? false,
          ),
          SizedBox(height: YkSpacing.md),
          YkButton(
            label: 'Enregistrer',
            onPressed: () async {
              final ok = await _controller.modifierEnonce(enonce.id, contenu);
              if (!ctx.mounted) return;
              if (ok) {
                Navigator.of(ctx).pop();
              } else {
                YkSnack.error(ctx, "Échec de l'enregistrement.");
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _supprimerEnonce(EnonceDevoirItem enonce) async {
    final confirme = await YkDialog.confirm(
      context: context,
      title: 'Supprimer cet énoncé ?',
      message: 'Ses questions seront supprimées avec lui. Cette action est irréversible.',
      confirmLabel: 'Supprimer',
      variant: YkDialogVariant.destructive,
    );
    if (confirme != true) return;
    final ok = await _controller.supprimerEnonce(enonce.id);
    if (!mounted) return;
    ok ? YkSnack.success(context, 'Énoncé supprimé.') : YkSnack.error(context, 'Échec de la suppression.');
  }

  Future<void> _ajouterQuestion(EnonceDevoirItem enonceItem) async {
    await YkSheet.show(
      context: context,
      title: 'Nouvelle question',
      bodyBuilder: (ctx) => QuestionDevoirForm(
        typeCorrection: _controller.devoir?.typeCorrection ?? 'auto',
        onSubmit: ({required enonce, required typeQuestion, required points, reponseAttendue, reponseExemple, choix}) =>
            _controller.ajouterQuestion(
          enonceId: enonceItem.id,
          enonce: enonce,
          typeQuestion: typeQuestion,
          points: points,
          reponseAttendue: reponseAttendue,
          reponseExemple: reponseExemple,
          choix: choix,
        ),
      ),
    );
  }

  Future<void> _editerQuestion(QuestionDevoirItem question) async {
    await YkSheet.show(
      context: context,
      title: 'Modifier la question',
      bodyBuilder: (ctx) => QuestionDevoirForm(
        existant: question,
        typeCorrection: _controller.devoir?.typeCorrection ?? 'auto',
        onSubmit: ({required enonce, required typeQuestion, required points, reponseAttendue, reponseExemple, choix}) =>
            _controller.modifierQuestion(
          questionId: question.id,
          enonce: enonce,
          points: points,
          reponseAttendue: reponseAttendue,
          reponseExemple: reponseExemple,
          choix: choix,
        ),
      ),
    );
  }

  Future<void> _supprimerQuestion(QuestionDevoirItem question) async {
    final confirme = await YkDialog.confirm(
      context: context,
      title: 'Supprimer cette question ?',
      message: 'Cette action est irréversible.',
      confirmLabel: 'Supprimer',
      variant: YkDialogVariant.destructive,
    );
    if (confirme != true) return;
    final ok = await _controller.supprimerQuestion(question.id);
    if (!mounted) return;
    ok ? YkSnack.success(context, 'Question supprimée.') : YkSnack.error(context, 'Échec de la suppression.');
  }

  Future<void> _ouvrirSoumissions() async {
    await _controller.chargerSoumissions();
    if (!mounted) return;
    await YkSheet.show(
      context: context,
      title: 'Soumissions',
      bodyBuilder: (ctx) => AnimatedBuilder(
        animation: _controller,
        builder: (ctx, _) {
          if (_controller.chargementSoumissions || _controller.soumissions == null) {
            return Padding(
              padding: EdgeInsets.all(YkSpacing.md),
              child: YkSkeleton.list(itemCount: 3, itemHeight: 72),
            );
          }
          return SoumissionsSheet(
            soumissions: _controller.soumissions!,
            noteSur: _controller.devoir?.noteSur ?? 20,
            fichierCorrectionUrl: _controller.devoir?.fichierCorrectionUrl,
            onCorriger: (soumissionId, note, commentaire) =>
                _controller.corrigerSoumission(soumissionId, note: note, commentaire: commentaire),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(animation: _controller, builder: (context, _) => _buildScaffold(context));
  }

  Widget _buildScaffold(BuildContext context) {
    final devoir = _controller.devoir;
    return Scaffold(
      backgroundColor: YkColors.background(context),
      appBar: AppBar(
        title: Text(devoir?.titre ?? 'Devoir', style: YkTypography.h4(context)),
        actions: [
          if (devoir != null) ...[
            IconButton(
              icon: const Icon(Icons.people_outline),
              tooltip: 'Soumissions',
              onPressed: _ouvrirSoumissions,
            ),
            PopupMenuButton<String>(
              itemBuilder: (_) => [
                if (_controller.peutModifier) const PopupMenuItem(value: 'modifier', child: Text('Modifier')),
                const PopupMenuItem(value: 'dupliquer', child: Text('Dupliquer')),
                if (!devoir.estPublie) const PopupMenuItem(value: 'publier', child: Text('Publier')),
              ],
              onSelected: (a) => switch (a) {
                'modifier' => _modifierDevoir(),
                'dupliquer' => _dupliquer(),
                'publier' => _publier(),
                _ => null,
              },
            ),
          ],
        ],
      ),
      body: switch (_controller.etat) {
        DevoirDetailEtat.chargement => SingleChildScrollView(
          padding: EdgeInsets.all(YkSpacing.md),
          child: YkSkeleton.list(itemCount: 4, itemHeight: 120),
        ),
        DevoirDetailEtat.erreur => YkErrorState(
          message: _controller.erreurMessage ?? 'Une erreur est survenue.',
          onRetry: _controller.charger,
        ),
        DevoirDetailEtat.pret => _buildCorps(context),
      },
    );
  }

  Widget _buildCorps(BuildContext context) {
    final devoir = _controller.devoir!;
    return RefreshIndicator(
      onRefresh: _controller.charger,
      child: ListView(
        padding: EdgeInsets.all(YkSpacing.md),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          YkCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                YkChip(
                  label: devoir.estPublie ? 'Publié' : 'Brouillon',
                  variant: YkChipVariant.assist,
                  accentColor: devoir.estPublie ? YkColors.success : YkColors.warning,
                ),
                SizedBox(height: YkSpacing.xs),
                if (devoir.description.isNotEmpty) Text(devoir.description, style: YkTypography.bodyMd(context)),
                SizedBox(height: YkSpacing.xs),
                Text(
                  '${devoir.noteSur.toStringAsFixed(0)} pt · coefficient ${devoir.coefficient.toStringAsFixed(1)}'
                  ' · ${devoir.dureeMinutes} min · correction ${devoir.estManuel ? "manuelle" : "automatique"}',
                  style: YkTypography.bodySm(context).copyWith(color: YkColors.textSecondary(context)),
                ),
              ],
            ),
          ),
          SizedBox(height: YkSpacing.md),
          for (final entry in _controller.enonces.asMap().entries)
            EnonceSection(
              enonce: entry.value,
              index: entry.key + 1,
              canEdit: true,
              peutModifier: _controller.peutModifier,
              onEditerEnonce: () => _editerEnonce(entry.value),
              onSupprimerEnonce: _controller.enonces.length > 1 ? () => _supprimerEnonce(entry.value) : null,
              onAjouterQuestion: () => _ajouterQuestion(entry.value),
              onEditerQuestion: _editerQuestion,
              onSupprimerQuestion: _supprimerQuestion,
            ),
          if (_controller.peutModifier)
            Padding(
              padding: EdgeInsets.only(top: YkSpacing.sm),
              child: YkButton(
                label: 'Ajouter un énoncé',
                icon: Icons.add,
                variant: YkButtonVariant.secondary,
                onPressed: _ajouterEnonce,
              ),
            ),
        ],
      ),
    );
  }
}
