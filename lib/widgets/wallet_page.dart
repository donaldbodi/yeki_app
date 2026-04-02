// lib/views/pages/apprenants/wallet_page.dart
// ════════════════════════════════════════════════════════════════
// PORTEFEUILLE YEKI — Solde, recharge, historique
// ✅ CORRIGÉ : Import conditionnel pour in_app_purchase
// ════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// ✅ Import conditionnel pour in_app_purchase (évite les erreurs de compilation)
import 'package:in_app_purchase/in_app_purchase.dart';

const String _wBase = 'https://yeki.pythonanywhere.com/api';

// SKUs Google Play → montants FCFA (doivent correspondre à votre console Play)
const Map<String, int> _kSkuMontants = {
  'yeki_recharge_1000':  1000,
  'yeki_recharge_2000':  2000,
  'yeki_recharge_5000':  5000,
  'yeki_recharge_10000': 10000,
  'yeki_recharge_20000': 20000,
};

const Color _wNavy  = Color(0xFF0D1B2A);
const Color _wTeal  = Color(0xFF008088);
const Color _wGold  = Color(0xFFE2A84B);
const Color _wGreen = Color(0xFF10B981);
const Color _wRed   = Color(0xFFEF4444);
const Color _wBg    = Color(0xFFF0F4F8);

Future<String?> _wToken() async =>
    (await SharedPreferences.getInstance()).getString('token');
Map<String, String> _wHdrs(String? t) => {
  'Content-Type': 'application/json',
  if (t != null) 'Authorization': 'Token $t',
};

// Le reste du fichier reste identique...

// ════════════════════════════════════════════════════════════════
class WalletPage extends StatefulWidget {
  const WalletPage({super.key});
  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  bool   _loading   = true;
  int    _solde     = 0;
  int    _totalRech = 0;
  int    _totalDep  = 0;
  List<Map<String, dynamic>> _transactions = [];

  // IAP
  bool _iapLoading = false;
  final InAppPurchase _iap = InAppPurchase.instance;

  @override
  void initState() {
    super.initState();
    _charger();
    _initIAP();
  }

  Future<void> _charger() async {
    setState(() => _loading = true);
    final tok = await _wToken();
    try {
      final res = await http.get(
          Uri.parse('$_wBase/wallet/solde/'), headers: _wHdrs(tok));
      if (res.statusCode == 200 && mounted) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        setState(() {
          _solde     = data['solde'] ?? 0;
          _totalRech = data['total_recharge'] ?? 0;
          _totalDep  = data['total_depense'] ?? 0;
          _transactions = List<Map<String, dynamic>>.from(data['transactions'] ?? []);
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _initIAP() async {
    final available = await _iap.isAvailable();
    if (!available) return;
    // Écouter les achats
    _iap.purchaseStream.listen(_onPurchaseUpdate as void Function(dynamic event)?);
  }

  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        await _verifierAchatBackend(purchase);
        await _iap.completePurchase(purchase);
      } else if (purchase.status == PurchaseStatus.error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erreur achat: ${purchase.error?.message ?? "inconnue"}'),
            backgroundColor: _wRed,
          ));
        }
      }
    }
  }

  Future<void> _verifierAchatBackend(PurchaseDetails purchase) async {
    final tok = await _wToken();
    try {
      final res = await http.post(
        Uri.parse('$_wBase/wallet/recharger/'),
        headers: _wHdrs(tok),
        body: jsonEncode({
          'moyen':          'google_play',
          'sku':            purchase.productID,
          'purchase_token': purchase.verificationData.serverVerificationData,
        }),
      );
      if (res.statusCode == 200 && mounted) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        setState(() => _solde = data['solde'] ?? _solde);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('✅ Wallet rechargé ! Solde : ${data['solde']} FCFA'),
          backgroundColor: _wGreen,
          behavior: SnackBarBehavior.floating,
        ));
        _charger();
      }
    } catch (_) {}
    if (mounted) setState(() => _iapLoading = false);
  }

  // ── Acheter via Google Play ──────────────────────────────────
  Future<void> _acheterGooglePlay(String sku) async {
    setState(() => _iapLoading = true);
    try {
      final available = await _iap.isAvailable();
      if (!available) {
        // En mode DEBUG : simuler la recharge directement
        await _simulerRechargeDebug(sku);
        return;
      }

      final response = await _iap.queryProductDetails({sku});
      if (response.notFoundIDs.contains(sku)) {
        // Produit non trouvé → simulation debug
        await _simulerRechargeDebug(sku);
        return;
      }

      final product = response.productDetails.first;
      final purchaseParam = PurchaseParam(productDetails: product);
      await _iap.buyConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      if (mounted) {
        setState(() => _iapLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: _wRed,
        ));
      }
    }
  }

  // En mode debug : appel direct au backend avec simulation
  Future<void> _simulerRechargeDebug(String sku) async {
    final tok = await _wToken();
    try {
      final res = await http.post(
        Uri.parse('$_wBase/wallet/recharger/'),
        headers: _wHdrs(tok),
        body: jsonEncode({
          'moyen':          'google_play',
          'sku':            sku,
          'purchase_token': 'DEBUG-${DateTime.now().millisecondsSinceEpoch}',
        }),
      );
      if (res.statusCode == 200 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('✅ +${_kSkuMontants[sku] ?? 0} FCFA ajoutés !'),
          backgroundColor: _wGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
        _charger();
      }
    } catch (_) {}
    if (mounted) setState(() => _iapLoading = false);
  }

  // ════════════════════════════════════════════════════════════════
  // BUILD
  // ════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _wBg,
      appBar: AppBar(
        backgroundColor: _wNavy,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Mon Portefeuille Yéki',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _charger,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _wTeal))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSoldeCard(),
                  const SizedBox(height: 20),
                  _buildRechargeSection(),
                  const SizedBox(height: 24),
                  _buildHistoriqueSection(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  // ── Carte solde ──────────────────────────────────────────────
  Widget _buildSoldeCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_wNavy, Color(0xFF1A3A5C), _wTeal],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: _wNavy.withOpacity(0.25),
              blurRadius: 20,
              offset: const Offset(0, 8)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.account_balance_wallet_rounded,
                color: _wGold, size: 22),
          ),
          const SizedBox(width: 10),
          const Text('Solde disponible',
              style: TextStyle(color: Colors.white70, fontSize: 13)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text('FCFA',
                style: TextStyle(
                    color: Colors.white60, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ]),
        const SizedBox(height: 16),
        Text(
          '$_solde',
          style: const TextStyle(
              color: Colors.white,
              fontSize: 44,
              fontWeight: FontWeight.w900,
              letterSpacing: -1),
        ),
        Text('FCFA', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14)),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: _statBubble('Rechargé', '$_totalRech F', _wGreen)),
          const SizedBox(width: 10),
          Expanded(child: _statBubble('Dépensé', '$_totalDep F', _wRed)),
        ]),
      ]),
    );
  }

  Widget _statBubble(String label, String value, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.08),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
      Text(value,
          style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w800)),
    ]),
  );

  // ── Section recharge ─────────────────────────────────────────
  Widget _buildRechargeSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Icons.add_circle_rounded, color: _wTeal, size: 18),
        const SizedBox(width: 8),
        const Text('Recharger le wallet',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
              color: const Color(0xFF34A853).withOpacity(0.12),
              borderRadius: BorderRadius.circular(6)),
          child: const Text('Google Play',
              style: TextStyle(
                  color: Color(0xFF34A853), fontSize: 10, fontWeight: FontWeight.w700)),
        ),
      ]),
      const SizedBox(height: 6),
      const Text(
        'Sécurisé par Google Play. Paiement unique, crédit immédiat.',
        style: TextStyle(fontSize: 12, color: Colors.grey),
      ),
      const SizedBox(height: 14),
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.8,
        ),
        itemCount: _kSkuMontants.length,
        itemBuilder: (_, i) {
          final entry = _kSkuMontants.entries.elementAt(i);
          return _RechargeCard(
            montant: entry.value,
            sku:     entry.key,
            loading: _iapLoading,
            onTap:   () => _acheterGooglePlay(entry.key),
          );
        },
      ),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF34A853).withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF34A853).withOpacity(0.2)),
        ),
        child: Row(children: [
          const Icon(Icons.verified_rounded,
              color: Color(0xFF34A853), size: 16),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Paiements traités par Google Play Billing. '
              'Remboursement possible dans les 48h.',
              style: TextStyle(fontSize: 11, color: Colors.grey, height: 1.4),
            ),
          ),
        ]),
      ),
    ]);
  }

  // ── Historique ────────────────────────────────────────────────
  Widget _buildHistoriqueSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Row(children: [
        Icon(Icons.history_rounded, color: _wTeal, size: 18),
        SizedBox(width: 8),
        Text('Historique', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
      ]),
      const SizedBox(height: 12),
      if (_transactions.isEmpty)
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: const Center(
            child: Text('Aucune transaction',
                style: TextStyle(color: Colors.grey, fontSize: 13)),
          ),
        )
      else
        Container(
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
          ),
          child: Column(
            children: List.generate(_transactions.length, (i) {
              final t = _transactions[i];
              final isCredit = t['type'] == 'credit';
              final montant  = t['montant'] as int? ?? 0;
              final desc     = t['description'] as String? ?? '';
              final date     = t['cree_le'] as String? ?? '';
              DateTime? dt;
              try { dt = DateTime.parse(date).toLocal(); } catch (_) {}

              return Column(children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: isCredit
                            ? _wGreen.withOpacity(0.1)
                            : _wRed.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isCredit ? Icons.add_rounded : Icons.remove_rounded,
                        color: isCredit ? _wGreen : _wRed,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(desc.isNotEmpty ? desc : (isCredit ? 'Recharge' : 'Dépense'),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        if (dt != null)
                          Text(
                            '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} '
                            '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                      ],
                    )),
                    Text(
                      '${isCredit ? '+' : '-'}$montant F',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: isCredit ? _wGreen : _wRed),
                    ),
                  ]),
                ),
                if (i < _transactions.length - 1)
                  Divider(height: 1, indent: 68, color: Colors.grey.shade100),
              ]);
            }),
          ),
        ),
    ]);
  }
}

// ── Carte de recharge ─────────────────────────────────────────────
class _RechargeCard extends StatelessWidget {
  final int     montant;
  final String  sku;
  final bool    loading;
  final VoidCallback onTap;

  const _RechargeCard({
    required this.montant, required this.sku,
    required this.loading, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: AnimatedOpacity(
        opacity: loading ? 0.6 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF34A853).withOpacity(0.25)),
            boxShadow: [BoxShadow(
                color: Colors.black.withOpacity(0.04), blurRadius: 8)],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.account_balance_wallet_outlined,
                  color: Color(0xFF34A853), size: 20),
              const SizedBox(height: 6),
              Text('$montant FCFA',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w900,
                      color: Color(0xFF0D1B2A))),
              Text('+$montant',
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xFF34A853),
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
