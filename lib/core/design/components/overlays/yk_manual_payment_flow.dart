import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:yeki/core/network/api_exception.dart';

import '../../tokens/tokens.dart';
import '../actions/yk_button.dart';
import '../actions/yk_segmented.dart';
import '../containers/yk_card.dart';
import '../containers/yk_sheet.dart';
import '../data/yk_badge.dart';
import '../data/yk_copyable_code.dart';
import '../data/yk_step_indicator.dart';
import '../feedback/yk_snack.dart';
import '../inputs/yk_text_field.dart';

/// Sens de l'opération — un seul assistant pour les trois usages
/// (règle 1 : trois écrans faits à la main pour la même mécanique
/// USSD/Mobile Money seraient la répétition exacte de l'erreur qu'on
/// corrige avec ce ticket).
enum YkPaiementSens { paiement, recharge, retrait }

/// Assistant de paiement manuel Orange Money / MTN MoMo — CDC §7.7.
///
/// Paramétré par [YkPaiementSens] : `paiement`/`recharge` sont un DÉPÔT de
/// l'apprenant vers Yéki (4 étapes, avec instructions USSD) ; `retrait`
/// est un ENVOI de Yéki vers un cadre (3 étapes — aucun code USSD à
/// composer côté cadre, l'étape "Instructions" n'a pas de sens ici).
///
/// Sans dépendance à un repository ou à `go_router` (convention déjà
/// actée pour tous les composants `overlays/`, voir
/// `YkWalletDebitConfirmSheet`) : [onSoumettre]/[onVerifierStatut] sont
/// fournis par l'écran appelant, qui choisit lui-même le bon endpoint
/// (`PaiementRepository.soumettreManuel`/`demanderRetrait`).
class YkManualPaymentFlow {
  YkManualPaymentFlow._();

  /// Renvoie `true` si la demande a été soumise avec succès (elle reste
  /// `en_attente` de validation par le Service Client — ce n'est jamais
  /// un paiement confirmé instantanément), `false` si l'utilisateur a
  /// fermé l'assistant avant soumission.
  static Future<bool> show(
    BuildContext context, {
    required YkPaiementSens sens,
    required int montant,
    required String titre,
    String? dureeAcces,
    required String ussdOrange,
    required String ussdMtn,
    required String numeroDepotOrange,
    required String numeroDepotMtn,
    required String nomAfficheDepot,
    required String whatsappServiceClient,
    required int delaiValidationMinutes,
    required Future<Map<String, dynamic>> Function(Map<String, dynamic> payload) onSoumettre,
    Future<String> Function(int demandeId)? onVerifierStatut,
  }) async {
    final resultat = await YkSheet.show<bool>(
      context: context,
      title: _titrePourSens(sens),
      bodyBuilder: (ctx) => _YkManualPaymentFlowBody(
        sens: sens,
        montant: montant,
        titre: titre,
        dureeAcces: dureeAcces,
        ussdOrange: ussdOrange,
        ussdMtn: ussdMtn,
        numeroDepotOrange: numeroDepotOrange,
        numeroDepotMtn: numeroDepotMtn,
        nomAfficheDepot: nomAfficheDepot,
        whatsappServiceClient: whatsappServiceClient,
        delaiValidationMinutes: delaiValidationMinutes,
        onSoumettre: onSoumettre,
        onVerifierStatut: onVerifierStatut,
      ),
    );
    return resultat ?? false;
  }

  static String _titrePourSens(YkPaiementSens sens) {
    switch (sens) {
      case YkPaiementSens.paiement:
        return 'Paiement manuel';
      case YkPaiementSens.recharge:
        return 'Recharge du portefeuille';
      case YkPaiementSens.retrait:
        return 'Demande de retrait';
    }
  }
}

class _YkManualPaymentFlowBody extends StatefulWidget {
  const _YkManualPaymentFlowBody({
    required this.sens,
    required this.montant,
    required this.titre,
    required this.dureeAcces,
    required this.ussdOrange,
    required this.ussdMtn,
    required this.numeroDepotOrange,
    required this.numeroDepotMtn,
    required this.nomAfficheDepot,
    required this.whatsappServiceClient,
    required this.delaiValidationMinutes,
    required this.onSoumettre,
    required this.onVerifierStatut,
  });

  final YkPaiementSens sens;
  final int montant;
  final String titre;
  final String? dureeAcces;
  final String ussdOrange;
  final String ussdMtn;
  final String numeroDepotOrange;
  final String numeroDepotMtn;
  final String nomAfficheDepot;
  final String whatsappServiceClient;
  final int delaiValidationMinutes;
  final Future<Map<String, dynamic>> Function(Map<String, dynamic> payload) onSoumettre;
  final Future<String> Function(int demandeId)? onVerifierStatut;

  @override
  State<_YkManualPaymentFlowBody> createState() => _YkManualPaymentFlowBodyState();
}

class _YkManualPaymentFlowBodyState extends State<_YkManualPaymentFlowBody> {
  int _currentStep = 0;
  String _operateur = 'orange_money';
  late final TextEditingController _idTransactionCtrl;
  late final TextEditingController _montantCtrl;
  final TextEditingController _numeroCtrl = TextEditingController();
  String? _erreurSaisie;
  String? _erreurNumero;
  bool _soumissionEnCours = false;
  Map<String, dynamic>? _resultat;
  String? _statutActuel;
  Timer? _pollTimer;

  bool get _estRetrait => widget.sens == YkPaiementSens.retrait;

  List<String> get _labels =>
      _estRetrait ? const ['Récapitulatif', 'Saisie', 'Confirmation'] : const ['Récapitulatif', 'Instructions', 'Saisie', 'Confirmation'];

  @override
  void initState() {
    super.initState();
    _idTransactionCtrl = TextEditingController();
    _montantCtrl = TextEditingController(text: '${widget.montant}');
  }

  @override
  void dispose() {
    _idTransactionCtrl.dispose();
    _montantCtrl.dispose();
    _numeroCtrl.dispose();
    _pollTimer?.cancel();
    super.dispose();
  }

  void _suivant() => setState(() => _currentStep += 1);

  void _precedent() => setState(() => _currentStep -= 1);

  Future<void> _soumettre() async {
    if (!_estRetrait && _idTransactionCtrl.text.trim().length < 4) {
      setState(() => _erreurSaisie = "L'identifiant de transaction semble trop court.");
      return;
    }
    // Rectification (demande explicite) : le numéro n'est plus optionnel,
    // même règle que pour le retrait — erreur dédiée (champ distinct de
    // l'identifiant de transaction).
    if (_numeroCtrl.text.trim().isEmpty) {
      setState(() => _erreurNumero = _estRetrait ? 'Le numéro de destination est obligatoire.' : 'Votre numéro est obligatoire.');
      return;
    }

    setState(() {
      _soumissionEnCours = true;
      _erreurSaisie = null;
      _erreurNumero = null;
    });

    final payload = _estRetrait
        ? <String, dynamic>{
            'operateur': _operateur,
            'montant_brut': widget.montant,
            'numero_destination': _numeroCtrl.text.trim(),
          }
        : <String, dynamic>{
            'operateur': _operateur,
            'id_transaction': _idTransactionCtrl.text.trim(),
            'montant': int.tryParse(_montantCtrl.text.trim()) ?? widget.montant,
            if (_numeroCtrl.text.trim().isNotEmpty) 'numero_emetteur': _numeroCtrl.text.trim(),
          };

    try {
      final resultat = await widget.onSoumettre(payload);
      if (!mounted) return;
      setState(() {
        _soumissionEnCours = false;
        _resultat = resultat;
        _currentStep += 1;
      });
      _demarrerSuiviStatut();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _soumissionEnCours = false);
      YkSnack.error(context, e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _soumissionEnCours = false);
      YkSnack.error(context, 'Une erreur est survenue. Réessayez.');
    }
  }

  void _demarrerSuiviStatut() {
    final demandeId = _resultat?['id'];
    if (widget.onVerifierStatut == null || demandeId is! int) return;
    setState(() => _statutActuel = 'en_attente');
    _pollTimer = Timer.periodic(const Duration(seconds: 15), (timer) async {
      final statut = await widget.onVerifierStatut!(demandeId);
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _statutActuel = statut);
      if (statut != 'en_attente') timer.cancel();
    });
  }

  Future<void> _ouvrirWhatsApp() async {
    final numero = widget.whatsappServiceClient.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse('https://wa.me/$numero');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      YkSnack.error(context, "Impossible d'ouvrir WhatsApp.");
    }
  }

  /// Insère le vrai montant dans le modèle USSD configuré par l'admin
  /// (`ParametreSysteme.ussd_orange_money`/`ussd_mtn_momo`, ex.
  /// `#150*1*1*656566253*{montant}#`) — jamais un numéro/format codé en
  /// dur ici (règle 3), seul l'espace réservé `{montant}` est substitué.
  /// Si l'admin n'a pas encore inclus `{montant}` dans son modèle (valeur
  /// historique), le code est utilisé tel quel plutôt que de planter.
  String _composerUssd(String modele) {
    if (!modele.contains('{montant}')) return modele;
    return modele.replaceAll('{montant}', widget.montant.toString());
  }

  Future<void> _composerAppel(String ussd) async {
    final uri = Uri.parse('tel:$ussd');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (mounted) {
      YkSnack.error(context, "Impossible d'ouvrir l'interface d'appel.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final labels = _labels;
    final enConfirmation = _currentStep == labels.length - 1 && _resultat != null;

    return Padding(
      padding: EdgeInsets.all(YkSpacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          YkStepIndicator(labels: labels, currentIndex: _currentStep),
          SizedBox(height: YkSpacing.lg),
          // Bug corrigé : un `IndexedStack` garde TOUTES les étapes montées
          // et se dimensionne sur la plus haute d'entre elles ("Instructions",
          // la plus longue) — à l'étape 1 ("Récapitulatif", bien plus
          // courte), le bouton "Suivant" se retrouvait poussé sous une
          // zone vide, hors champ sans faire défiler. Un simple
          // remplacement du widget courant laisse chaque étape prendre sa
          // propre hauteur naturelle (l'état vit déjà dans ce `State`, pas
          // dans les widgets d'étape eux-mêmes — rien à préserver en
          // gardant les autres étapes montées).
          _buildEtapes(context, labels)[_currentStep],
          if (!enConfirmation) ...[SizedBox(height: YkSpacing.lg), _buildNavigation(context, labels)],
        ],
      ),
    );
  }

  List<Widget> _buildEtapes(BuildContext context, List<String> labels) {
    if (_estRetrait) {
      return [_buildRecapitulatif(context), _buildSaisie(context), _buildConfirmation(context)];
    }
    return [
      _buildRecapitulatif(context),
      _buildInstructions(context),
      _buildSaisie(context),
      _buildConfirmation(context),
    ];
  }

  Widget _buildNavigation(BuildContext context, List<String> labels) {
    final dernierePageAvantConfirmation = _currentStep == labels.length - 2;
    return Row(
      children: [
        if (_currentStep > 0)
          Expanded(
            child: YkButton(
              label: 'Précédent',
              variant: YkButtonVariant.secondary,
              onPressed: _soumissionEnCours ? null : _precedent,
            ),
          ),
        if (_currentStep > 0) SizedBox(width: YkSpacing.sm),
        Expanded(
          child: YkButton(
            label: dernierePageAvantConfirmation ? 'Envoyer' : 'Suivant',
            isLoading: _soumissionEnCours,
            onPressed: _soumissionEnCours ? null : (dernierePageAvantConfirmation ? _soumettre : _suivant),
          ),
        ),
      ],
    );
  }

  Widget _buildRecapitulatif(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        YkCard(
          variant: YkCardVariant.filled,
          child: Column(
            children: [
              _ligne(context, widget.titre, '${widget.montant} FCFA', accent: true),
              if (widget.dureeAcces != null) ...[
                SizedBox(height: YkSpacing.xs),
                _ligne(context, "Durée d'accès", widget.dureeAcces!),
              ],
            ],
          ),
        ),
        SizedBox(height: YkSpacing.md),
        Text(
          _estRetrait
              ? 'Ce montant sera débité de votre portefeuille Yéki et transféré vers le numéro Mobile Money '
                  'que vous indiquerez à l\'étape suivante.'
              : 'Vous allez régler ce montant par Mobile Money — les instructions détaillées suivent.',
          style: YkTypography.bodyMd(context).copyWith(color: YkColors.textSecondary(context)),
        ),
      ],
    );
  }

  Widget _buildInstructions(BuildContext context) {
    final estOrange = _operateur == 'orange_money';
    final ussdModele = estOrange ? widget.ussdOrange : widget.ussdMtn;
    final ussd = _composerUssd(ussdModele);
    final etapes = [
      'Touchez le code USSD ci-dessus (ou copiez-le puis composez-le dans votre interface d\'appel).',
      'Envoyez et notez l\'identifiant de transaction reçu par SMS — vous en aurez besoin à l\'étape suivante.',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        YkSegmented<String>(
          segments: const [
            YkSegment(value: 'orange_money', label: 'Orange Money'),
            YkSegment(value: 'mtn_momo', label: 'MTN MoMo'),
          ],
          selected: _operateur,
          onChanged: (v) => setState(() => _operateur = v),
        ),
        SizedBox(height: YkSpacing.md),
        // Le numéro de dépôt est déjà inclus dans le code USSD lui-même
        // (modèle admin, ex. `#150*1*1*656566253*{montant}#`) — plus de
        // champ séparé, redondant avec ce que le clic/appel compose déjà.
        YkCopyableCode(label: 'Code USSD', code: ussd, onCall: () => _composerAppel(ussd)),
        SizedBox(height: YkSpacing.md),
        YkCard(
          variant: YkCardVariant.filled,
          accentColor: YkColors.warning,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_rounded, color: YkColors.warning, size: 18),
                  SizedBox(width: YkSpacing.xs),
                  Expanded(
                    child: Text(
                      "Nom qui s'affichera lors du dépôt",
                      style: YkTypography.label(context).copyWith(color: YkColors.warning, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              SizedBox(height: YkSpacing.xxs),
              Text(
                widget.nomAfficheDepot,
                style: YkTypography.h4(context).copyWith(color: YkColors.textPrimary(context)),
              ),
              SizedBox(height: YkSpacing.xxs),
              Text(
                "Vérifiez ce nom avant d'envoyer — en cas de doute, contactez le Service Client.",
                style: YkTypography.bodySm(context).copyWith(color: YkColors.textSecondary(context)),
              ),
            ],
          ),
        ),
        SizedBox(height: YkSpacing.md),
        for (var i = 0; i < etapes.length; i++)
          Padding(
            padding: EdgeInsets.only(bottom: YkSpacing.xs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${i + 1}.', style: YkTypography.bodyMd(context).copyWith(fontWeight: FontWeight.w700)),
                SizedBox(width: YkSpacing.xs),
                Expanded(
                  child: Text(
                    etapes[i],
                    style: YkTypography.bodyMd(context).copyWith(color: YkColors.textPrimary(context)),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSaisie(BuildContext context) {
    if (_estRetrait) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          YkSegmented<String>(
            segments: const [
              YkSegment(value: 'orange_money', label: 'Orange Money'),
              YkSegment(value: 'mtn_momo', label: 'MTN MoMo'),
            ],
            selected: _operateur,
            onChanged: (v) => setState(() => _operateur = v),
          ),
          SizedBox(height: YkSpacing.md),
          YkTextField(
            controller: _numeroCtrl,
            label: 'Numéro de destination',
            hint: 'Ex. 690000000',
            type: YkTextFieldType.number,
            required: true,
            errorText: _erreurNumero,
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        YkTextField(
          controller: _idTransactionCtrl,
          label: 'Identifiant de transaction',
          hint: 'Reçu par SMS après le dépôt',
          required: true,
          errorText: _erreurSaisie,
        ),
        SizedBox(height: YkSpacing.md),
        YkTextField(
          controller: _montantCtrl,
          label: 'Montant envoyé',
          type: YkTextFieldType.number,
          required: true,
        ),
        SizedBox(height: YkSpacing.md),
        YkTextField(
          controller: _numeroCtrl,
          label: 'Votre numéro',
          type: YkTextFieldType.number,
          required: true,
          errorText: _erreurNumero,
        ),
      ],
    );
  }

  Widget _buildConfirmation(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.check_circle, color: YkColors.success, size: 28),
            SizedBox(width: YkSpacing.sm),
            Expanded(
              child: Text(
                _estRetrait ? 'Demande de retrait envoyée' : 'Demande envoyée',
                style: YkTypography.h4(context).copyWith(color: YkColors.textPrimary(context)),
              ),
            ),
          ],
        ),
        SizedBox(height: YkSpacing.sm),
        Text(
          'Elle sera ${_estRetrait ? 'traitée' : 'validée'} au plus tard dans ${widget.delaiValidationMinutes} '
          'minutes par notre Service Client.',
          style: YkTypography.bodyMd(context).copyWith(color: YkColors.textSecondary(context)),
        ),
        if (_estRetrait && _resultat?['montant_net'] != null) ...[
          SizedBox(height: YkSpacing.sm),
          _ligne(context, 'Frais opérateur', '${_resultat!['frais_operateur'] ?? 0} FCFA'),
          SizedBox(height: YkSpacing.xxs),
          _ligne(context, 'Montant net à recevoir', '${_resultat!['montant_net']} FCFA', accent: true),
        ],
        if (_statutActuel != null) ...[SizedBox(height: YkSpacing.md), _buildStatutBadge(context, _statutActuel!)],
        SizedBox(height: YkSpacing.lg),
        YkButton(
          label: 'Contacter le Service Client',
          variant: YkButtonVariant.secondary,
          icon: Icons.chat_rounded,
          onPressed: _ouvrirWhatsApp,
        ),
        SizedBox(height: YkSpacing.sm),
        YkButton(label: 'Terminer', onPressed: () => Navigator.of(context).pop(true)),
      ],
    );
  }

  Widget _buildStatutBadge(BuildContext context, String statut) {
    final (couleur, texte) = switch (statut) {
      'validee' => (YkColors.success, 'Validée ✓'),
      'refusee' => (YkColors.error, 'Refusée'),
      _ => (YkColors.warning, 'En attente de validation…'),
    };
    return YkBadge(variant: YkBadgeVariant.label, label: texte, color: couleur);
  }

  Widget _ligne(BuildContext context, String label, String valeur, {bool accent = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(label, style: YkTypography.label(context).copyWith(color: YkColors.textSecondary(context))),
        ),
        Text(
          valeur,
          style: accent
              ? YkTypography.h4(context).copyWith(color: YkColors.accent(context))
              : YkTypography.bodyMd(context).copyWith(color: YkColors.textPrimary(context)),
        ),
      ],
    );
  }
}
