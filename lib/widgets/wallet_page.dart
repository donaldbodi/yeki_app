// lib/views/pages/wallet/wallet_page.dart
// ═══════════════════════════════════════════════════════════════════════════
// PORTEFEUILLE YEKI — GLASSMORPHISM LIGHT EDITION
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yeki/core/theme/yeki_design_system.dart';
import 'package:yeki/core/constants/api_constants.dart';
import 'package:yeki/views/pages/apprenants/paiement_page.dart';

const List<int> _rechargeAmounts = [1000, 2000, 5000, 10000, 20000, 50000];

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  bool _loading = true;
  int _solde = 0;
  int _totalRecharge = 0;
  int _totalDepense = 0;
  List<Map<String, dynamic>> _transactions = [];

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> _charger() async {
    setState(() => _loading = true);
    final token = await _getToken();
    if (token == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(ApiConstants.walletSolde),
        headers: ApiHeaders.auth(token),
      );

      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body);
        setState(() {
          _solde = data['solde'] ?? 0;
          _totalRecharge = data['total_recharge'] ?? 0;
          _totalDepense = data['total_depense'] ?? 0;
          _transactions = List<Map<String, dynamic>>.from(data['transactions'] ?? []);
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _recharger(int montant) async {
    final success = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PaiementPage(
          type: PaiementType.rechargeWallet,
          titre: 'Recharge portefeuille',
          montant: montant,
        ),
      ),
    );

    if (success == true && mounted) {
      await _charger();
    }
  }

  void _showRechargeSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  YekiColors.white.withValues(alpha: 0.85),
                  YekiColors.white.withValues(alpha: 0.60),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border.all(
                color: YekiColors.white.withValues(alpha: 0.9),
                width: 1,
              ),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: YekiColors.textLight.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Choisir un montant',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: YekiColors.textDark),
                ),
                const SizedBox(height: 4),
                Text(
                  'Rechargez votre portefeuille Yéki',
                  style: TextStyle(fontSize: 13, color: YekiColors.textMedium),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _rechargeAmounts.map((amount) {
                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(ctx);
                        _recharger(amount);
                      },
                      child: Container(
                        width: (MediaQuery.of(context).size.width - 80) / 2,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: YekiColors.white.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: YekiColors.primary.withValues(alpha: 0.15),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              '$amount',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: YekiColors.primary,
                              ),
                            ),
                            const Text('FCFA', style: TextStyle(fontSize: 12, color: YekiColors.textMedium)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_outline_rounded, color: YekiColors.textMedium, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      'Paiement sécurisé via CinetPay',
                      style: TextStyle(fontSize: 11, color: YekiColors.textMedium),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: YekiColors.bgLight,
      body: Container(
        decoration: const BoxDecoration(
          gradient: YekiGradients.mainBackground,
        ),
        child: Stack(
          children: [
            // Sphères décoratives
            Positioned(
              top: -40,
              right: -40,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: YekiColors.primaryLight.withValues(alpha: 0.08),
                ),
              ),
            ),
            Positioned(
              bottom: -30,
              left: -30,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: YekiColors.accent.withValues(alpha: 0.06),
                ),
              ),
            ),
            SafeArea(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: YekiColors.primary))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: YekiColors.white.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: YekiColors.white.withValues(alpha: 0.8),
                                    width: 1,
                                  ),
                                ),
                                child: const Icon(Icons.account_balance_wallet_rounded, color: YekiColors.primary, size: 22),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Mon Portefeuille',
                                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: YekiColors.textDark),
                                    ),
                                    Text(
                                      'Gérez vos transactions',
                                      style: TextStyle(fontSize: 13, color: YekiColors.textMedium),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: YekiColors.white.withValues(alpha: 0.5),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: YekiColors.white.withValues(alpha: 0.8),
                                    width: 1,
                                  ),
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.refresh_rounded, color: YekiColors.textDark, size: 20),
                                  onPressed: _charger,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _buildSoldeCard(),
                          const SizedBox(height: 20),
                          _buildRechargeButton(),
                          const SizedBox(height: 24),
                          _buildHistoriqueSection(),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSoldeCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                YekiColors.primary.withValues(alpha: 0.85),
                YekiColors.primaryDark.withValues(alpha: 0.9),
                const Color(0xFF0D1B2A).withValues(alpha: 0.95),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: YekiColors.white.withValues(alpha: 0.10),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: YekiColors.primary.withValues(alpha: 0.15),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: YekiColors.white.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.account_balance_wallet_rounded, color: YekiColors.accent, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Solde disponible',
                    style: TextStyle(color: YekiColors.white, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                '$_solde',
                style: const TextStyle(
                  color: YekiColors.white,
                  fontSize: 44,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ),
              const Text('FCFA', style: TextStyle(color: YekiColors.white, fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _statBubble('Total rechargé', '$_totalRecharge FCFA', YekiColors.success),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _statBubble('Total dépensé', '$_totalDepense FCFA', YekiColors.accent),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statBubble(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: YekiColors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: YekiColors.white.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: YekiColors.white, fontSize: 10, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildRechargeButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [YekiColors.accent, YekiColors.accent.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: YekiColors.accent.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: _showRechargeSheet,
          borderRadius: BorderRadius.circular(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add_circle_outline_rounded, color: YekiColors.white, size: 20),
              const SizedBox(width: 10),
              const Text(
                'Recharger mon portefeuille',
                style: TextStyle(
                  color: YekiColors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoriqueSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: YekiColors.white.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: YekiColors.white.withValues(alpha: 0.6),
                  width: 1,
                ),
              ),
              child: const Icon(Icons.history_rounded, size: 16, color: YekiColors.textDark),
            ),
            const SizedBox(width: 10),
            const Text(
              'Historique des transactions',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: YekiColors.textDark),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_transactions.isEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: YekiColors.white.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: YekiColors.white.withValues(alpha: 0.6),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.inbox_rounded, color: YekiColors.textLight, size: 40),
                      const SizedBox(height: 8),
                      const Text(
                        'Aucune transaction',
                        style: TextStyle(fontSize: 14, color: YekiColors.textMedium),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
        else
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                decoration: BoxDecoration(
                  color: YekiColors.white.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: YekiColors.white.withValues(alpha: 0.6),
                    width: 1,
                  ),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _transactions.length > 10 ? 10 : _transactions.length,
                  separatorBuilder: (_, _) => Divider(
                    color: YekiColors.textLight.withValues(alpha: 0.1),
                    height: 1,
                  ),
                  itemBuilder: (_, index) {
                    final transaction = _transactions[index];
                    final isCredit = transaction['type'] == 'credit';
                    final montant = transaction['montant'] ?? 0;
                    final description = transaction['description'] ?? '';
                    final date = transaction['cree_le'] ?? '';

                    return ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: (isCredit ? YekiColors.success : YekiColors.error).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: (isCredit ? YekiColors.success : YekiColors.error).withValues(alpha: 0.15),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          isCredit ? Icons.add_rounded : Icons.remove_rounded,
                          color: isCredit ? YekiColors.success : YekiColors.error,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        description,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: YekiColors.textDark),
                      ),
                      subtitle: Text(
                        date.substring(0, 10),
                        style: const TextStyle(fontSize: 11, color: YekiColors.textMedium),
                      ),
                      trailing: Text(
                        '${isCredit ? '+' : '-'}$montant FCFA',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isCredit ? YekiColors.success : YekiColors.error,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
      ],
    );
  }
}