import 'package:flutter/material.dart';

import 'package:yeki/core/network/api_exception.dart';

import '../../tokens/tokens.dart';
import '../actions/yk_button.dart';
import '../containers/yk_card.dart';
import '../containers/yk_sheet.dart';
import '../feedback/yk_skeleton.dart';
import '../feedback/yk_snack.dart';

/// Débit du portefeuille Yéki DÉJÀ approvisionné — PAS une passerelle
/// externe (ex. participation à une olympiade, 100 FCFA par défaut,
/// `PayerParticipationOlympiadeView` côté backend). Encapsule un
/// comportement jusqu'ici écrit à la main, écran par écran
/// (`olympiade_inscription_page.dart` avant P8.3) : solde affiché,
/// confirmation, puis un traitement dédié du solde insuffisant (lien
/// direct vers la recharge) plutôt qu'un message d'erreur générique.
///
/// Renommé depuis `YkManualPaymentFlow` (P9.3) : ce nom désigne
/// désormais le VRAI flux de paiement manuel USSD/Mobile Money à 4
/// étapes (`yk_manual_payment_flow.dart`) — ce composant-ci ne fait que
/// confirmer un débit de solde déjà présent, un besoin bien plus étroit
/// qui ne devait pas porter le même nom (règle 1 : pas de collision).
///
/// Composant volontairement SANS dépendance à un repository ou à
/// `go_router` (aucun autre composant `Yk*` n'en a — la couche design
/// system reste présentation pure) : [chargerSolde]/[onPayer]/
/// [onRecharger] sont fournis par l'écran appelant.
class YkWalletDebitConfirmSheet {
  YkWalletDebitConfirmSheet._();

  /// Renvoie `true` si le paiement a réussi, `false` sinon (annulé ou
  /// fermé après un solde insuffisant).
  static Future<bool> show(
    BuildContext context, {
    required int montant,
    required String description,
    required Future<int> Function() chargerSolde,
    required Future<void> Function() onPayer,
    required VoidCallback onRecharger,
  }) async {
    final resultat = await YkSheet.show<bool>(
      context: context,
      title: 'Confirmer le paiement',
      bodyBuilder: (ctx) => _YkPaymentFlowBody(
        montant: montant,
        description: description,
        chargerSolde: chargerSolde,
        onPayer: onPayer,
        onRecharger: onRecharger,
      ),
    );
    return resultat ?? false;
  }
}

class _YkPaymentFlowBody extends StatefulWidget {
  const _YkPaymentFlowBody({
    required this.montant,
    required this.description,
    required this.chargerSolde,
    required this.onPayer,
    required this.onRecharger,
  });

  final int montant;
  final String description;
  final Future<int> Function() chargerSolde;
  final Future<void> Function() onPayer;
  final VoidCallback onRecharger;

  @override
  State<_YkPaymentFlowBody> createState() => _YkPaymentFlowBodyState();
}

class _YkPaymentFlowBodyState extends State<_YkPaymentFlowBody> {
  bool _chargementSolde = true;
  bool _paiementEnCours = false;
  int? _solde;
  ApiException? _erreurSoldeInsuffisant;

  @override
  void initState() {
    super.initState();
    _chargerSolde();
  }

  Future<void> _chargerSolde() async {
    try {
      final solde = await widget.chargerSolde();
      if (!mounted) return;
      setState(() {
        _solde = solde;
        _chargementSolde = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _chargementSolde = false);
    }
  }

  Future<void> _payer() async {
    setState(() {
      _paiementEnCours = true;
      _erreurSoldeInsuffisant = null;
    });
    try {
      await widget.onPayer();
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.isInsufficientBalance) {
        setState(() {
          _erreurSoldeInsuffisant = e;
          _paiementEnCours = false;
        });
      } else {
        setState(() => _paiementEnCours = false);
        YkSnack.error(context, e.message);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _paiementEnCours = false);
      YkSnack.error(context, 'Une erreur est survenue. Réessayez.');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_erreurSoldeInsuffisant != null) {
      return _buildSoldeInsuffisant(context, _erreurSoldeInsuffisant!);
    }

    return Padding(
      padding: EdgeInsets.all(YkSpacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.description,
            style: YkTypography.bodyMd(context).copyWith(color: YkColors.textPrimary(context)),
          ),
          SizedBox(height: YkSpacing.md),
          YkCard(
            variant: YkCardVariant.filled,
            child: Column(
              children: [
                _ligne(context, 'Montant', '${widget.montant} FCFA', accent: true),
                SizedBox(height: YkSpacing.xs),
                _chargementSolde
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Solde actuel',
                            style: YkTypography.label(context).copyWith(color: YkColors.textSecondary(context)),
                          ),
                          const YkSkeleton.line(width: 70, height: 16),
                        ],
                      )
                    : _ligne(context, 'Solde actuel', '${_solde ?? 0} FCFA'),
              ],
            ),
          ),
          SizedBox(height: YkSpacing.lg),
          YkButton(
            label: 'Payer et confirmer',
            isLoading: _paiementEnCours,
            onPressed: _paiementEnCours ? null : _payer,
          ),
        ],
      ),
    );
  }

  Widget _ligne(BuildContext context, String label, String valeur, {bool accent = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: YkTypography.label(context).copyWith(color: YkColors.textSecondary(context))),
        Text(
          valeur,
          style: accent
              ? YkTypography.h4(context).copyWith(color: YkColors.accent(context))
              : YkTypography.bodyMd(context).copyWith(color: YkColors.textPrimary(context)),
        ),
      ],
    );
  }

  Widget _buildSoldeInsuffisant(BuildContext context, ApiException e) {
    return Padding(
      padding: EdgeInsets.all(YkSpacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.account_balance_wallet_outlined, color: YkColors.warning),
              SizedBox(width: YkSpacing.sm),
              Expanded(
                child: Text(
                  'Solde insuffisant',
                  style: YkTypography.h4(context).copyWith(color: YkColors.textPrimary(context)),
                ),
              ),
            ],
          ),
          SizedBox(height: YkSpacing.sm),
          Text(
            e.soldeActuel != null && e.montantRequis != null
                ? 'Solde actuel : ${e.soldeActuel} FCFA — montant requis : ${e.montantRequis} FCFA.'
                : e.message,
            style: YkTypography.bodyMd(context).copyWith(color: YkColors.textSecondary(context)),
          ),
          SizedBox(height: YkSpacing.lg),
          YkButton(
            label: 'Recharger mon portefeuille',
            onPressed: () {
              Navigator.of(context).pop(false);
              widget.onRecharger();
            },
          ),
        ],
      ),
    );
  }
}
