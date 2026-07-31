// lib/features/paiement/presentation/wallet_page.dart
//
// Écran « Mon Portefeuille » (P9.3, rituel P5.0) — remplace
// `lib/widgets/wallet_page.dart` (glassmorphism, appels `http` bruts,
// sheet de recharge inline avec montants sans bonus). Recharge déplacée
// vers l'écran dédié `AppRoute.recharge` (`recharge_page.dart`) — même
// cible que le bouton « Recharger » de `YkWalletDebitConfirmSheet`,
// aucune mécanique dupliquée (règle 1). Voir docs/ecarts/wallet.md.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:yeki/core/design/components/components.dart';
import 'package:yeki/core/design/tokens/tokens.dart';
import 'package:yeki/core/router/route_names.dart';

import 'wallet_controller.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  late final WalletController _controller;
  static final _dateFmt = DateFormat('dd/MM/yyyy', 'fr_FR');

  @override
  void initState() {
    super.initState();
    _controller = WalletController();
    _controller.charger();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _recharger() async {
    final ok = await context.pushNamed<bool>(AppRoute.recharge);
    if (ok == true && mounted) await _controller.charger();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: YkColors.background(context),
      appBar: AppBar(
        title: const Text('Mon Portefeuille'),
        actions: [
          YkIconButton(
            icon: Icons.refresh_rounded,
            label: 'Actualiser',
            variant: YkIconButtonVariant.ghost,
            onPressed: _controller.charger,
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          if (_controller.chargement) {
            return Padding(padding: EdgeInsets.all(YkSpacing.md), child: const YkSkeleton.list(itemCount: 5));
          }
          if (_controller.enErreur) {
            return YkErrorState(
              message: 'Impossible de charger votre portefeuille.',
              cause: 'Vérifiez votre connexion internet.',
              onRetry: _controller.charger,
            );
          }
          return ListView(
            padding: EdgeInsets.all(YkSpacing.md),
            children: [
              _buildSoldeCard(context),
              SizedBox(height: YkSpacing.md),
              YkButton(
                label: 'Recharger mon portefeuille',
                icon: Icons.add_circle_outline_rounded,
                onPressed: _recharger,
              ),
              if (_controller.demandesEnAttente.isNotEmpty) ...[
                SizedBox(height: YkSpacing.lg),
                _buildDemandesEnAttente(context),
              ],
              SizedBox(height: YkSpacing.lg),
              _buildHistorique(context),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSoldeCard(BuildContext context) {
    return YkCard(
      variant: YkCardVariant.filled,
      accentColor: YkColors.accent(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_balance_wallet_rounded, color: YkColors.accent(context)),
              SizedBox(width: YkSpacing.xs),
              Text('Solde disponible', style: YkTypography.label(context).copyWith(color: YkColors.textSecondary(context))),
            ],
          ),
          SizedBox(height: YkSpacing.xs),
          Text(
            '${_controller.solde} FCFA',
            style: YkTypography.h2(context).copyWith(color: YkColors.textPrimary(context), fontWeight: FontWeight.w800),
          ),
          SizedBox(height: YkSpacing.md),
          Row(
            children: [
              Expanded(child: _statBubble(context, 'Total rechargé', '${_controller.totalRecharge} FCFA', YkColors.success)),
              SizedBox(width: YkSpacing.sm),
              Expanded(child: _statBubble(context, 'Total dépensé', '${_controller.totalDepense} FCFA', YkColors.error)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statBubble(BuildContext context, String label, String valeur, Color couleur) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: YkSpacing.sm, vertical: YkSpacing.sm),
      decoration: BoxDecoration(
        color: YkColors.surfaceVariant(context),
        borderRadius: BorderRadius.circular(YkRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: YkTypography.caption(context).copyWith(color: YkColors.textSecondary(context))),
          SizedBox(height: YkSpacing.xxs),
          Text(valeur, style: YkTypography.bodyMd(context).copyWith(color: couleur, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildDemandesEnAttente(BuildContext context) {
    return YkCard(
      variant: YkCardVariant.outlined,
      accentColor: YkColors.warning,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.hourglass_top_rounded, color: YkColors.warning, size: 18),
              SizedBox(width: YkSpacing.xs),
              Text(
                'Recharges en attente de validation',
                style: YkTypography.label(context).copyWith(color: YkColors.warning, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          SizedBox(height: YkSpacing.xs),
          for (final demande in _controller.demandesEnAttente)
            Padding(
              padding: EdgeInsets.symmetric(vertical: YkSpacing.xxs),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${demande['montant']} FCFA — ${demande['operateur'] == 'orange_money' ? 'Orange Money' : 'MTN MoMo'}',
                    style: YkTypography.bodySm(context).copyWith(color: YkColors.textPrimary(context)),
                  ),
                  YkBadge(variant: YkBadgeVariant.label, label: 'En attente', color: YkColors.warning),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHistorique(BuildContext context) {
    if (_controller.transactions.isEmpty) {
      return const YkEmptyState(
        title: 'Aucune transaction',
        message: "L'historique de votre portefeuille apparaîtra ici après votre première opération.",
        icon: Icons.receipt_long_outlined,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Historique des transactions',
          style: YkTypography.h4(context).copyWith(color: YkColors.textPrimary(context)),
        ),
        SizedBox(height: YkSpacing.sm),
        YkCard(
          variant: YkCardVariant.outlined,
          child: Column(
            children: [
              for (var i = 0; i < _controller.transactions.length; i++) ...[
                if (i > 0) Divider(height: YkSpacing.md, color: YkColors.border(context)),
                _buildTransactionLigne(context, _controller.transactions[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionLigne(BuildContext context, Map<String, dynamic> transaction) {
    final estCredit = transaction['type'] == 'credit';
    final montant = (transaction['montant'] as num?)?.toInt() ?? 0;
    final description = transaction['description'] as String? ?? '';
    final dateStr = transaction['cree_le'] as String?;
    final date = dateStr != null ? DateTime.tryParse(dateStr) : null;
    final couleur = estCredit ? YkColors.success : YkColors.error;

    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(YkSpacing.xs),
          decoration: BoxDecoration(color: couleur.withValues(alpha: 0.12), shape: BoxShape.circle),
          child: Icon(estCredit ? Icons.add_rounded : Icons.remove_rounded, color: couleur, size: 18),
        ),
        SizedBox(width: YkSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(description, style: YkTypography.bodyMd(context).copyWith(color: YkColors.textPrimary(context))),
              if (date != null)
                Text(_dateFmt.format(date), style: YkTypography.caption(context).copyWith(color: YkColors.textSecondary(context))),
            ],
          ),
        ),
        Text(
          '${estCredit ? '+' : '-'}$montant FCFA',
          style: YkTypography.bodyMd(context).copyWith(color: couleur, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
