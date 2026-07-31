// lib/features/paiement/presentation/paiement_page.dart
//
// Écran de paiement unifié (P9.3, rituel P5.0) — remplace
// `lib/views/pages/apprenants/paiement_page.dart` (860 lignes, CinetPay
// uniquement, 4 prix en dur, appels `http` bruts). `YkPaywall` pour la
// sélection de l'offre (accès département : mensuel/annuel + présentiel
// en complément séparé, jamais un prérequis) puis
// `YkManualPaymentFlow(sens: paiement)`. CinetPay reste disponible en
// option quand `ParametreSysteme['mode_paiement']` l'autorise (`cinetpay`
// ou `les_deux`) — mécanique de webview non réécrite (règle 1), migrée
// sur `PaiementRepository.initierCinetpay`. Voir docs/ecarts/wallet.md.
//
// Contrat de route préservé (`app_router.dart`, `AppPath.paiement`) : les
// mêmes 9 query params existants (type/titre/montant/departementId/
// olympiadeId/montantPresentiel/isCursus/isHybride/isFormation) sont
// conservés, 3 nouveaux params OPTIONNELS ajoutés (montantAnnuel/badge/
// ancienPrixMensuel) pour livrer « les 4 prix »/« ancien prix barré »/
// « économie réalisée » sans jamais calculer de remise figée (règle 3) —
// aucun appelant réel n'existe encore pour ces types (accesDepartement/
// olympiade/abonnement*, confirmé par grep exhaustif), seule la recharge
// depuis `wallet_page.dart` empruntait cette route ; elle utilise
// désormais `AppRoute.recharge` dédié.

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'package:yeki/core/design/components/components.dart';
import 'package:yeki/core/design/tokens/tokens.dart';
import 'package:yeki/core/network/api_exception.dart';
import 'package:yeki/services/facture_service.dart';

import 'paiement_controller.dart';

enum PaiementType { rechargeWallet, accesDepartement, olympiade, abonnementMensuel, abonnementAnnuel }

class PaiementPage extends StatefulWidget {
  const PaiementPage({
    super.key,
    required this.type,
    this.departementId,
    this.olympiadeId,
    required this.titre,
    required this.montant,
    this.montantPresentiel,
    this.isCursus = false,
    this.isHybride = false,
    this.isFormation = false,
    this.montantAnnuel,
    this.badge,
    this.ancienPrixMensuel,
  });

  final PaiementType type;
  final int? departementId;
  final int? olympiadeId;
  final String titre;
  final int montant;
  final int? montantPresentiel;
  final bool isCursus;
  final bool isHybride;
  final bool isFormation;

  /// Prix annuel réel (`Departement.prix_annuel`) — `null` si non fourni
  /// par l'appelant, auquel cas aucune offre annuelle n'est proposée
  /// (jamais de ratio de remise calculé côté client, règle 3).
  final int? montantAnnuel;

  /// `Departement.label_catalogue()` — "Promotion" | "Offre gratuite" | null.
  final String? badge;

  /// Ancien prix mensuel avant baisse, barré — affiché seulement si
  /// [badge] == "Promotion".
  final int? ancienPrixMensuel;

  @override
  State<PaiementPage> createState() => _PaiementPageState();
}

class _PaiementPageState extends State<PaiementPage> {
  late final PaiementController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PaiementController();
    _controller.charger();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _afficherPaywall => widget.type == PaiementType.accesDepartement;

  bool get _presentielDisponible => (widget.montantPresentiel ?? 0) > 0;

  int get _montantBase =>
      _afficherPaywall && _controller.periodicite == 'annuel' && widget.montantAnnuel != null
      ? widget.montantAnnuel!
      : widget.montant;

  int get _montantFinal => _montantBase + (_controller.inclurePresentiel ? (widget.montantPresentiel ?? 0) : 0);

  String get _categorie {
    switch (widget.type) {
      case PaiementType.rechargeWallet:
        return 'recharge';
      case PaiementType.accesDepartement:
        return 'formation';
      case PaiementType.olympiade:
        return 'olympiade';
      case PaiementType.abonnementMensuel:
      case PaiementType.abonnementAnnuel:
        return 'abonnement';
    }
  }

  String get _typePaiementCinetpay {
    switch (widget.type) {
      case PaiementType.rechargeWallet:
        return 'wallet_recharge';
      case PaiementType.accesDepartement:
        return 'acces_departement';
      case PaiementType.olympiade:
        return 'olympiade';
      case PaiementType.abonnementMensuel:
        return 'abonnement_mensuel';
      case PaiementType.abonnementAnnuel:
        return 'abonnement_annuel';
    }
  }

  Map<String, dynamic> _enrichirPayload(Map<String, dynamic> payload) {
    final data = <String, dynamic>{...payload, 'categorie': _categorie};
    if (widget.type == PaiementType.olympiade && widget.olympiadeId != null) {
      data['objet_id'] = widget.olympiadeId;
    }
    if (widget.type == PaiementType.accesDepartement) {
      if (widget.departementId != null) data['departement_id'] = widget.departementId;
      data['type_abonnement'] = _controller.periodicite;
    }
    if (widget.type == PaiementType.abonnementMensuel) data['type_abonnement'] = 'mensuel';
    if (widget.type == PaiementType.abonnementAnnuel) data['type_abonnement'] = 'annuel';
    return data;
  }

  Future<void> _lancerFluxManuel({String? periodiciteChoisie}) async {
    if (periodiciteChoisie != null) _controller.choisirPeriodicite(periodiciteChoisie);
    final params = _controller.parametres;
    if (params == null) return;

    final ok = await YkManualPaymentFlow.show(
      context,
      sens: widget.type == PaiementType.rechargeWallet ? YkPaiementSens.recharge : YkPaiementSens.paiement,
      montant: _montantFinal,
      titre: widget.titre,
      dureeAcces: _afficherPaywall ? (_controller.periodicite == 'annuel' ? '1 an' : '1 mois') : null,
      ussdOrange: params.ussdOrangeMoney,
      ussdMtn: params.ussdMtnMomo,
      numeroDepotOrange: params.numeroDepotOrange,
      numeroDepotMtn: params.numeroDepotMtn,
      nomAfficheDepot: params.nomAfficheDepot,
      whatsappServiceClient: params.whatsappServiceClient,
      delaiValidationMinutes: params.delaiValidationPaiementMinutes,
      onSoumettre: (payload) => _controller.soumettreManuel(_enrichirPayload(payload)),
      onVerifierStatut: _controller.verifierStatut,
    );
    if (ok && mounted) Navigator.of(context).pop(true);
  }

  Future<void> _lancerCinetPay() async {
    try {
      final data = await _controller.initierCinetpay({
        'type_paiement': _typePaiementCinetpay,
        'montant': _montantFinal,
        'payment_method': 'mtn_momo',
        if (widget.departementId != null) 'departement_id': widget.departementId,
        if (widget.olympiadeId != null) 'olympiade_id': widget.olympiadeId,
      });
      final paymentUrl = data['payment_url'] as String?;
      final reference = data['reference'] as String?;
      if (paymentUrl == null || reference == null || !mounted) return;

      final success = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => _CinetPayWebView(paymentUrl: paymentUrl, titre: widget.titre)),
      );

      if (success == true && mounted) {
        if (_presentielDisponible && _controller.inclurePresentiel) {
          await _genererFacturePresentiel(reference, immediat: true);
        }
        if (!mounted) return;
        YkSnack.success(context, 'Paiement réussi !');
        Navigator.of(context).pop(true);
      }
    } on ApiException catch (e) {
      if (mounted) YkSnack.error(context, e.message);
    }
  }

  Future<void> _genererFacturePresentiel(String reference, {bool immediat = false}) async {
    try {
      final facture = await FactureService.genererFacture(
        reference: reference,
        clientNom: 'Apprenant Yéki',
        clientEmail: '',
        description: '${widget.titre} — supplément présentiel',
        montantLigne: 0,
        montantPresentiel: widget.montantPresentiel ?? 0,
        montantTotal: widget.montantPresentiel ?? 0,
        date: DateTime.now(),
        departementNom: widget.titre,
        moyenPaiement: immediat ? 'CinetPay' : 'Mobile Money (Orange/MTN)',
      );
      await FactureService.imprimerFacture(facture);
    } catch (_) {
      // Génération de facture non bloquante — le paiement lui-même a
      // déjà réussi, une facture manquée ne doit pas remonter en erreur.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: YkColors.background(context),
      appBar: AppBar(title: const Text('Paiement')),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          if (_controller.chargementParametres) {
            return Padding(padding: EdgeInsets.all(YkSpacing.md), child: const YkSkeleton.list(itemCount: 4));
          }
          if (_controller.enErreur || _controller.parametres == null) {
            return YkErrorState(
              message: 'Impossible de charger les informations de paiement.',
              cause: 'Vérifiez votre connexion internet.',
              onRetry: _controller.charger,
            );
          }
          final params = _controller.parametres!;
          return ListView(
            padding: EdgeInsets.all(YkSpacing.md),
            children: [
              if (_afficherPaywall) _buildPaywall(context) else _buildRecapSimple(context),
              if (params.cinetpayDisponible) ...[
                SizedBox(height: YkSpacing.lg),
                YkButton(
                  label: 'Payer par carte / CinetPay',
                  variant: YkButtonVariant.tertiary,
                  onPressed: _lancerCinetPay,
                ),
              ],
              if (widget.type == PaiementType.accesDepartement && _presentielDisponible) ...[
                SizedBox(height: YkSpacing.lg),
                _buildFactureSection(context),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildPaywall(BuildContext context) {
    return YkPaywall(
      title: widget.isFormation ? 'Accès à la formation' : 'Accès au département',
      description: widget.titre,
      features: const [],
      presentielLabel: _presentielDisponible ? 'Supplément présentiel' : null,
      presentielDescription: _presentielDisponible
          ? (_controller.inclurePresentiel
                ? 'Inclus — ${widget.montantPresentiel} FCFA ajoutés (optionnel, touchez pour retirer)'
                : 'Optionnel — sessions en salle (+${widget.montantPresentiel} FCFA)')
          : null,
      onSelectPresentiel: _presentielDisponible ? _controller.togglePresentiel : null,
      plans: [
        YkPaywallPlan(
          label: 'Mensuel',
          priceLabel: '${widget.montant} FCFA/mois',
          badge: widget.badge,
          ancienPrixLabel: widget.badge == 'Promotion' && widget.ancienPrixMensuel != null
              ? '${widget.ancienPrixMensuel} FCFA'
              : null,
          onSelect: () => _lancerFluxManuel(periodiciteChoisie: 'mensuel'),
        ),
        if (widget.montantAnnuel != null && widget.montantAnnuel! > 0)
          YkPaywallPlan(
            label: 'Annuel',
            priceLabel: '${widget.montantAnnuel} FCFA/an',
            economieLabel: widget.montant * 12 > widget.montantAnnuel!
                ? 'Économisez ${widget.montant * 12 - widget.montantAnnuel!} FCFA vs mensuel'
                : null,
            onSelect: () => _lancerFluxManuel(periodiciteChoisie: 'annuel'),
          ),
      ],
    );
  }

  Widget _buildRecapSimple(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        YkCard(
          variant: YkCardVariant.filled,
          accentColor: YkColors.accent(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.titre, style: YkTypography.h4(context).copyWith(color: YkColors.textPrimary(context))),
              SizedBox(height: YkSpacing.xs),
              Text(
                '$_montantFinal FCFA',
                style: YkTypography.h2(context).copyWith(color: YkColors.accent(context), fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
        if (_presentielDisponible) ...[
          SizedBox(height: YkSpacing.sm),
          YkCard(
            variant: YkCardVariant.outlined,
            onTap: _controller.togglePresentiel,
            child: Row(
              children: [
                Icon(
                  _controller.inclurePresentiel ? Icons.check_circle : Icons.circle_outlined,
                  color: _controller.inclurePresentiel ? YkColors.accent(context) : YkColors.textTertiary(context),
                ),
                SizedBox(width: YkSpacing.sm),
                Expanded(
                  child: Text(
                    'Supplément présentiel (optionnel) — +${widget.montantPresentiel} FCFA',
                    style: YkTypography.bodyMd(context).copyWith(color: YkColors.textPrimary(context)),
                  ),
                ),
              ],
            ),
          ),
        ],
        SizedBox(height: YkSpacing.lg),
        YkButton(label: 'Payer $_montantFinal FCFA', onPressed: () => _lancerFluxManuel()),
      ],
    );
  }

  Widget _buildFactureSection(BuildContext context) {
    final demande = _controller.demandeFormationValidee;
    return YkCard(
      variant: YkCardVariant.outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Facture présentiel',
            style: YkTypography.label(context).copyWith(color: YkColors.textPrimary(context), fontWeight: FontWeight.w700),
          ),
          SizedBox(height: YkSpacing.xs),
          Text(
            demande != null
                ? 'Votre paiement a été validé — la facture ne contient que le supplément présentiel.'
                : "Disponible une fois votre paiement manuel validé par le Service Client.",
            style: YkTypography.bodySm(context).copyWith(color: YkColors.textSecondary(context)),
          ),
          SizedBox(height: YkSpacing.sm),
          YkButton(
            label: demande != null ? 'Télécharger la facture' : 'Vérifier le statut',
            variant: YkButtonVariant.secondary,
            isLoading: _controller.verificationEnCours,
            onPressed: demande != null
                ? () => _genererFacturePresentiel('YEKI-${demande.id}')
                : _controller.rafraichirDemandeFormation,
          ),
        ],
      ),
    );
  }
}

/// WebView CinetPay — mécanique héritée de l'ancien
/// `lib/views/pages/apprenants/paiement_page.dart` (détection d'URL de
/// retour), non réécrite (règle 1) ; seuls l'habillage (Yk*) et l'appel
/// réseau (`PaiementRepository.initierCinetpay`, dans la page appelante)
/// ont changé.
class _CinetPayWebView extends StatefulWidget {
  const _CinetPayWebView({required this.paymentUrl, required this.titre});

  final String paymentUrl;
  final String titre;

  @override
  State<_CinetPayWebView> createState() => _CinetPayWebViewState();
}

class _CinetPayWebViewState extends State<_CinetPayWebView> {
  late final WebViewController _webController;

  /// `ValueNotifier` plutôt que `setState` (interdit sous `lib/features/`,
  /// règle 7).
  final ValueNotifier<bool> _chargement = ValueNotifier(true);
  bool _paiementDetecte = false;

  @override
  void initState() {
    super.initState();
    _webController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            _chargement.value = true;
            _detecterRetour(url);
          },
          onPageFinished: (url) {
            _chargement.value = false;
            _detecterRetour(url);
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  @override
  void dispose() {
    _chargement.dispose();
    super.dispose();
  }

  void _detecterRetour(String url) {
    if (_paiementDetecte) return;
    if (url.contains('payment-result') || url.contains('success') || url.contains('cinetpay.com/success')) {
      _paiementDetecte = true;
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) Navigator.of(context).pop(true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: YkColors.background(context),
      appBar: AppBar(title: Text('Paiement — ${widget.titre}')),
      body: Stack(
        children: [
          WebViewWidget(controller: _webController),
          ValueListenableBuilder<bool>(
            valueListenable: _chargement,
            builder: (context, chargement, _) =>
                chargement ? const Center(child: CircularProgressIndicator()) : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
