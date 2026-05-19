// lib/views/pages/apprenants/wallet_page.dart
// ════════════════════════════════════════════════════════════════
// PORTEFEUILLE YEKI - Version unifiée CinetPay
// ════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yeki/views/pages/apprenants/paiement_page.dart';

const String _baseUrl = 'https://yeki.pythonanywhere.com/api';

const Color _primary = Color(0xFF135F74);
const Color _gold = Color(0xFFC5A059);
const Color _bg = Color(0xFFF8FAFC);
const Color _white = Color(0xFFFFFFFF);
const Color _textDark = Color(0xFF1A1C1E);
//const Color _textMedium = Color(0xFF5A5C5E);
const Color _textLight = Color(0xFF8A8C8E);
const Color _green = Color(0xFF10B981);
const Color _red = Color(0xFFEF4444);
const Color _orange = Color(0xFFF97316);

// Montants de recharge prédéfinis
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
        Uri.parse('$_baseUrl/wallet/solde/'),
        headers: {'Authorization': 'Token $token'},
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
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: _white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E4E8),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Choisir un montant',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textDark),
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
                      color: _primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _primary.withOpacity(0.2)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '$amount',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: _primary,
                          ),
                        ),
                        const Text(
                          'FCFA',
                          style: TextStyle(fontSize: 12, color: _textLight),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            const Text(
              'Paiement sécurisé via CinetPay',
              style: TextStyle(fontSize: 11, color: _textLight),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('Mon Portefeuille'),
        backgroundColor: _primary,
        foregroundColor: _white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _charger,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSoldeCard(),
                  const SizedBox(height: 24),
                  _buildRechargeButton(),
                  const SizedBox(height: 24),
                  _buildHistoriqueSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildSoldeCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D1B2A), Color(0xFF1A3A5C), _primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
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
                  color: _white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.account_balance_wallet_rounded, color: _gold, size: 22),
              ),
              const SizedBox(width: 10),
              const Text(
                'Solde disponible',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '$_solde',
            style: const TextStyle(
              color: _white,
              fontSize: 44,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Text(
            'FCFA',
            style: TextStyle(color: Colors.white54, fontSize: 14),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _statBubble('Total rechargé', '$_totalRecharge FCFA', _green),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _statBubble('Total dépensé', '$_totalDepense FCFA', _orange),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statBubble(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildRechargeButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _showRechargeSheet,
        style: ElevatedButton.styleFrom(
          backgroundColor: _gold,
          foregroundColor: _white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        icon: const Icon(Icons.add_circle_outline_rounded),
        label: const Text(
          'Recharger mon portefeuille',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildHistoriqueSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.history_rounded, color: _primary, size: 18),
            SizedBox(width: 8),
            Text(
              'Historique des transactions',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _textDark),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_transactions.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text(
                'Aucune transaction',
                style: TextStyle(color: _textLight, fontSize: 13),
              ),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: _white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8),
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _transactions.length > 10 ? 10 : _transactions.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, index) {
                final t = _transactions[index];
                final isCredit = t['type'] == 'credit';
                final montant = t['montant'] ?? 0;
                final description = t['description'] ?? '';
                final date = t['cree_le'] ?? '';

                return ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isCredit ? _green.withOpacity(0.1) : _red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isCredit ? Icons.add_rounded : Icons.remove_rounded,
                      color: isCredit ? _green : _red,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    description,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    date.substring(0, 10),
                    style: const TextStyle(fontSize: 11, color: _textLight),
                  ),
                  trailing: Text(
                    '${isCredit ? '+' : '-'}$montant FCFA',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isCredit ? _green : _red,
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}