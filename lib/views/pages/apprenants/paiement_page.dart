// lib/views/pages/apprenants/paiement_page.dart
//
// ✅ Connexion API — initie et confirme le paiement
// ✅ MTN Mobile Money & Orange Money (Cameroun)
// ✅ Carte bancaire
// ✅ Retourne la référence de paiement au parent
// ✅ Design premium responsive
//
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'formations_models.dart';

// ══════════════════════════════════════════════════════════════
// STRATÉGIE PAIEMENT PLAY STORE (Android)
// ══════════════════════════════════════════════════════════════
// Les règles Google Play imposent que les paiements pour contenu
// numérique (abonnements) passent par Google Play Billing.
//
// PLAN D'INTÉGRATION :
//  • abonnement_mensuel / abonnement_annuel
//      → Google Play Subscription (in_app_purchase)
//      → SKUs : 'yeki_mensuel', 'yeki_annuel'
//      → Après achat Google → POST /api/paiements/verifier-iap/
//        { "token": purchaseToken, "sku": sku, "platform": "android" }
//        Le backend vérifie via Google Play Developer API
//
//  • olympiade & acces_departement
//      → Mobile Money direct (MTN/Orange) — acceptable car
//        ce sont des paiements opérateur local, pas in-app Google
//
// ⚠️  Activer _doitUtiliserIAP() avant soumission Play Store.
// ══════════════════════════════════════════════════════════════

/// Retourne true si ce type de paiement doit passer par Google Play IAP.
/// À activer quand le package in_app_purchase est intégré.
bool _doitUtiliserIAP(String typePaiement) {
  // ignore: dead_code
  const bool iapActif = false; // mettre à true après intégration IAP
  if (!iapActif) return false;
  return Platform.isAndroid &&
      (typePaiement == 'abonnement_mensuel' ||
       typePaiement == 'abonnement_annuel');
}

const Color _blue     = Color(0xFF2884A0);
const Color _darkBlue = Color(0xFF0D1B2A);
const Color _accent   = Color(0xFFFFB74D);
const Color _bgColor  = Color(0xFFF4F9FB);

Future<String?> _getToken() async =>
    (await SharedPreferences.getInstance()).getString('token');
Map<String, String> _headersJson(String? t) => {
  'Content-Type': 'application/json',
  if (t != null) 'Authorization': 'Token $t',
};

// ═══════════════════════════════════════════════════════════════
class PaiementPage extends StatefulWidget {
  final String titre;
  final double montant;
  final String typePaiement; // abonnement_mensuel|annuel|prepa_concours|formation_classique|formation_metier|olympiade
  final int? concoursId;
  final int? formationClassiqueId;
  final int? formationMetierId;
  final int? olympiadeId;

  const PaiementPage({
    super.key,
    required this.titre,
    required this.montant,
    required this.typePaiement,
    this.concoursId,
    this.formationClassiqueId,
    this.formationMetierId,
    this.olympiadeId,
  });

  @override
  State<PaiementPage> createState() => _PaiementPageState();
}

class _PaiementPageState extends State<PaiementPage> {
  final _formKey = GlobalKey<FormState>();
  String _moyen = 'mtn_momo';
  final _numeroCtrl = TextEditingController();
  final _nomCarteCtrl = TextEditingController();
  final _numCarteCtrl = TextEditingController();
  final _dateCarteCtrl = TextEditingController();
  final _cvvCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _numeroCtrl.dispose();
    _nomCarteCtrl.dispose();
    _numCarteCtrl.dispose();
    _dateCarteCtrl.dispose();
    _cvvCtrl.dispose();
    super.dispose();
  }

  Future<void> _payer() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final token = await _getToken();
    final body = <String, dynamic>{
      'type_paiement': widget.typePaiement,
      'moyen': _moyen,
      'numero': _numeroCtrl.text.trim(),
    };
    if (widget.concoursId != null) body['concours_id'] = widget.concoursId;
    if (widget.formationClassiqueId != null) body['formation_classique_id'] = widget.formationClassiqueId;
    if (widget.formationMetierId != null) body['formation_metier_id'] = widget.formationMetierId;
    if (widget.olympiadeId != null) body['olympiade_id'] = widget.olympiadeId;

    try {
      final res = await http.post(
        Uri.parse('$kBaseUrl/paiements/initier/'),
        headers: _headersJson(token),
        body: jsonEncode(body),
      );

      if (!mounted) return;

      if (res.statusCode == 200 || res.statusCode == 201) {
        final json = jsonDecode(res.body);
        final reference = json['reference'] as String;
        final statut = json['statut'] as String;

        if (statut == 'succes') {
          // Retourner la référence à la page appelante
          Navigator.pop(context, reference);
        } else {
          _showSnack('Paiement en attente de confirmation.');
        }
      } else {
        final body = jsonDecode(res.body);
        final err = body['detail'] ?? body['error'] ?? 'Erreur lors du paiement';
        _showSnack(err);
      }
    } catch (e) {
      _showSnack('Erreur réseau : vérifiez votre connexion');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSnack(String msg, {bool success = false}) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: success ? const Color(0xFF2E7D32) : Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));

  String _formatMontant(double m) {
    final s = m.toStringAsFixed(0);
    return s.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ' ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        title: const Text('Paiement sécurisé'),
        backgroundColor: _blue,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Récapitulatif ──────────────────────────────
              _buildRecap(),
              const SizedBox(height: 24),

              // ── Choisir le moyen ───────────────────────────
              const Text('Méthode de paiement',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 16, color: _darkBlue)),
              const SizedBox(height: 12),
              _buildMethodeSelector(),
              const SizedBox(height: 24),

              // ── Formulaire selon moyen ─────────────────────
              if (_moyen == 'mtn_momo' || _moyen == 'orange_om')
                _buildMobileForm()
              else
                _buildCarteForm(),

              const SizedBox(height: 32),

              // ── Bouton payer ───────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _payer,
                  icon: _loading
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.lock_rounded, size: 18),
                  label: Text(
                    _loading
                        ? 'Traitement en cours…'
                        : 'Payer ${_formatMontant(widget.montant)} FCFA',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                ),
              ),

              const SizedBox(height: 16),
              // ── Sécurité ────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.security_rounded, size: 14, color: Colors.grey.shade400),
                  const SizedBox(width: 6),
                  Text('Paiement 100% sécurisé',
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Récapitulatif ────────────────────────────────────────────
  Widget _buildRecap() {
    final typeLabels = {
      'abonnement_mensuel': 'Abonnement mensuel Premium',
      'abonnement_annuel': 'Abonnement annuel Premium',
      'prepa_concours': 'Prépa Concours',
      'formation_classique': 'Formation Classique',
      'formation_metier': 'Formation Métier',
      'olympiade': 'Olympiade',
    };

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _blue.withOpacity(0.1), borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.receipt_long_rounded, color: _blue, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      typeLabels[widget.typePaiement] ?? widget.typePaiement,
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                    ),
                    Text(
                      widget.titre,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15, color: _darkBlue),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Montant total',
                  style: TextStyle(color: Colors.grey, fontSize: 14)),
              Text(
                '${_formatMontant(widget.montant)} FCFA',
                style: const TextStyle(
                    color: _blue, fontWeight: FontWeight.w800, fontSize: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Sélecteur méthode ────────────────────────────────────────
  Widget _buildMethodeSelector() {
    final methodes = [
      ('mtn_momo', 'MTN Mobile Money', 'assets/mtn.png', const Color(0xFFFFCC00)),
      ('orange_om', 'Orange Money', 'assets/orange.png', const Color(0xFFFF6600)),
      ('carte', 'Carte bancaire', null, _blue),
    ];

    return Row(
      children: methodes.map((m) {
        final selected = _moyen == m.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _moyen = m.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(right: m.$1 == 'carte' ? 0 : 8),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
              decoration: BoxDecoration(
                color: selected ? m.$4.withOpacity(0.1) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected ? m.$4 : Colors.grey.shade200,
                  width: selected ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    m.$1 == 'carte'
                        ? Icons.credit_card_rounded
                        : Icons.phone_android_rounded,
                    color: selected ? m.$4 : Colors.grey.shade400,
                    size: 22,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    m.$2.replaceFirst(' ', '\n'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: selected ? m.$4 : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Formulaire Mobile Money ──────────────────────────────────
  Widget _buildMobileForm() {
    final isMtn = _moyen == 'mtn_momo';
    final color = isMtn ? const Color(0xFFFFCC00) : const Color(0xFFFF6600);
    final label = isMtn ? 'Numéro MTN (ex: 6XXXXXXXX)' : 'Numéro Orange (ex: 6XXXXXXXX)';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.phone_android_rounded, color: color),
            const SizedBox(width: 8),
            Text(isMtn ? 'MTN Mobile Money' : 'Orange Money',
                style: TextStyle(
                    fontWeight: FontWeight.w700, color: color, fontSize: 15)),
          ]),
          const SizedBox(height: 16),
          TextFormField(
            controller: _numeroCtrl,
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(9)],
            decoration: InputDecoration(
              labelText: label,
              prefixText: '+237 ',
              prefixStyle: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: color, width: 2),
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Entrez votre numéro';
              if (v.length < 9) return 'Numéro incomplet';
              return null;
            },
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 16, color: color),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Une notification de confirmation sera envoyée sur votre téléphone.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Formulaire Carte ─────────────────────────────────────────
  Widget _buildCarteForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.credit_card_rounded, color: _blue),
            SizedBox(width: 8),
            Text('Carte bancaire',
                style: TextStyle(fontWeight: FontWeight.w700, color: _blue, fontSize: 15)),
          ]),
          const SizedBox(height: 16),
          TextFormField(
            controller: _nomCarteCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: 'Nom sur la carte',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            validator: (v) => v == null || v.isEmpty ? 'Champ obligatoire' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _numCarteCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(16),
              _CardNumberFormatter(),
            ],
            decoration: InputDecoration(
              labelText: 'Numéro de carte',
              hintText: 'XXXX XXXX XXXX XXXX',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            validator: (v) {
              final digits = v?.replaceAll(' ', '') ?? '';
              if (digits.length < 16) return 'Numéro invalide';
              return null;
            },
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: TextFormField(
                controller: _dateCarteCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                  _ExpiryFormatter(),
                ],
                decoration: InputDecoration(
                  labelText: 'MM/AA',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) => v == null || v.length < 5 ? 'Date invalide' : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _cvvCtrl,
                keyboardType: TextInputType.number,
                obscureText: true,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(3),
                ],
                decoration: InputDecoration(
                  labelText: 'CVV',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) => v == null || v.length < 3 ? 'CVV invalide' : null,
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

// ── Page confirmation ────────────────────────────────────────────
class ConfirmationPaiementPage extends StatefulWidget {
  final String reference;
  final String titre;
  final double montant;
  final String moyen;

  const ConfirmationPaiementPage({
    super.key,
    required this.reference,
    required this.titre,
    required this.montant,
    required this.moyen,
  });

  @override
  State<ConfirmationPaiementPage> createState() => _ConfirmationPaiementPageState();
}

class _ConfirmationPaiementPageState extends State<ConfirmationPaiementPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _scaleAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.elasticOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _scaleAnim,
                child: Container(
                  width: 100, height: 100,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2E7D32), shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 52),
                ),
              ),
              const SizedBox(height: 28),
              const Text('Paiement réussi !',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: _darkBlue)),
              const SizedBox(height: 8),
              Text('Merci pour votre paiement',
                  style: TextStyle(color: Colors.grey.shade500)),
              const SizedBox(height: 32),
              _infoCard(),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Retour à l\'accueil',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoCard() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 12, offset: const Offset(0, 4))],
    ),
    child: Column(
      children: [
        _row('Service', widget.titre),
        const Divider(height: 20),
        _row('Montant', '${widget.montant.toStringAsFixed(0)} FCFA'),
        const Divider(height: 20),
        _row('Méthode', _moyenLabel(widget.moyen)),
        const Divider(height: 20),
        _row('Référence', widget.reference),
      ],
    ),
  );

  Widget _row(String label, String value) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
      Flexible(
        child: Text(value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.w600, color: _darkBlue, fontSize: 13)),
      ),
    ],
  );

  String _moyenLabel(String m) {
    switch (m) {
      case 'mtn_momo': return 'MTN Mobile Money';
      case 'orange_om': return 'Orange Money';
      default: return 'Carte bancaire';
    }
  }
}

// ── Historique paiements ─────────────────────────────────────────
class HistoriquePaiementPage extends StatefulWidget {
  const HistoriquePaiementPage({super.key});

  @override
  State<HistoriquePaiementPage> createState() => _HistoriquePaiementPageState();
}

class _HistoriquePaiementPageState extends State<HistoriquePaiementPage> {
  bool _loading = true;
  List<dynamic> _paiements = [];

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    final token = await _getToken();
    try {
      final res = await http.get(
        Uri.parse('$kBaseUrl/paiements/historique/'),
        headers: _headersJson(token),
      );
      if (res.statusCode == 200 && mounted) {
        setState(() {
          _paiements = jsonDecode(res.body);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        title: const Text('Historique des paiements'),
        backgroundColor: _blue,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _blue))
          : _paiements.isEmpty
              ? const Center(child: Text('Aucun paiement effectué'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _paiements.length,
                  itemBuilder: (_, i) {
                    final p = _paiements[i];
                    final statut = p['statut'] ?? '';
                    final montant = p['montant'] ?? 0;
                    final date = p['date'] ?? '';
                    Color statusColor;
                    IconData statusIcon;
                    switch (statut) {
                      case 'succes':
                        statusColor = const Color(0xFF2E7D32);
                        statusIcon = Icons.check_circle_rounded;
                      case 'echec':
                        statusColor = Colors.red.shade700;
                        statusIcon = Icons.cancel_rounded;
                      default:
                        statusColor = const Color(0xFFF57F17);
                        statusIcon = Icons.hourglass_top_rounded;
                    }
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8, offset: const Offset(0, 2))],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(statusIcon, color: statusColor, size: 20),
                        ),
                        title: Text(p['type'] ?? '',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 2),
                            Text('Réf : ${p['reference'] ?? ''}',
                                style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
                            Text(date.length > 10 ? date.substring(0, 10) : date,
                                style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
                          ],
                        ),
                        trailing: Text(
                          '$montant FCFA',
                          style: TextStyle(
                              color: statusColor, fontWeight: FontWeight.w800, fontSize: 14),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

// ── Formatters ───────────────────────────────────────────────────
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue old, TextEditingValue newVal) {
    final digits = newVal.text.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    final str = buffer.toString();
    return newVal.copyWith(
      text: str,
      selection: TextSelection.collapsed(offset: str.length),
    );
  }
}

class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue old, TextEditingValue newVal) {
    final digits = newVal.text.replaceAll('/', '');
    String str = digits;
    if (digits.length >= 2) str = '${digits.substring(0, 2)}/${digits.substring(2)}';
    return newVal.copyWith(
      text: str,
      selection: TextSelection.collapsed(offset: str.length),
    );
  }
}
