import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

const String _baseO = 'https://yeki.pythonanywhere.com/api';

// ─── Palette ────────────────────────────────────────────────────
const Color _olymp  = Color(0xFF7B2FBE);
const Color _gold   = Color(0xFFE2A84B);
//const Color _accent = Color(0xFFFF7F77);
const Color _dark   = Color(0xFF1A1C1E);
//const Color _bg     = Color(0xFFF5F7FA);

// ═══════════════════════════════════════════════════════════════
// Sheet inscription en bas de page
// ═══════════════════════════════════════════════════════════════
class InscriptionSheet extends StatefulWidget {
  final int      olympiadeId;
  final String   titre;
  final String   reglement;
  final String   prixDesc;
  final DateTime? datDebut;
  final DateTime? datFin;
  final VoidCallback onSuccess;

  const InscriptionSheet({super.key,
    required this.olympiadeId,
    required this.titre,
    this.reglement = '',
    this.prixDesc  = '',
    this.datDebut,
    this.datFin,
    required this.onSuccess,
  });

  @override
  State<InscriptionSheet> createState() => _InscriptionSheetState();
}

class _InscriptionSheetState extends State<InscriptionSheet> {
  bool _accepte = false;
  bool _loading = false;

  Future<String?> _token() async {
    final p = await SharedPreferences.getInstance();
    return p.getString('token');
  }

  Future<void> _inscrire() async {
    if (!_accepte) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Acceptez d\'abord le règlement.'),
        backgroundColor: Colors.orange,
      ));
      return;
    }
    setState(() => _loading = true);
    final token = await _token();
    final res = await http.post(
      Uri.parse('$_baseO/olympiades/${widget.olympiadeId}/inscrire/'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Token $token',
      },
      body: jsonEncode({'accepte_reglement': true}),
    );
    setState(() => _loading = false);

    if (res.statusCode == 201 || res.statusCode == 409) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res.statusCode == 201
            ? 'Inscription confirmée ! Bonne chance.'
            : 'Déjà inscrit.'),
        backgroundColor: _olymp,
      ));
      widget.onSuccess();
      if (mounted) Navigator.pop(context);
    } else {
      final msg = jsonDecode(res.body)['detail'] ?? 'Erreur.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy à HH:mm');
    return Container(
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Handle
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Header
          Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF3E8FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.military_tech_rounded,
                  color: _olymp, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.titre, style: const TextStyle(
                    fontWeight: FontWeight.w900, fontSize: 16, color: _dark,
                  )),
                  const Text('Inscription olympiade',
                      style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 20),

          // Dates

        if (widget.datDebut != null)
          _infoRow(Icons.play_circle_outline_rounded,
              'Début compétition', fmt.format(widget.datDebut!)),  // null check + unwrap !
        if (widget.datFin != null)
          _infoRow(Icons.stop_circle_outlined,
              'Fin compétition', fmt.format(widget.datFin!)), 

          // Prix
          if (widget.prixDesc.isNotEmpty) ...[
            const SizedBox(height: 16),
            _sectionTitle('Récompenses', Icons.stars_rounded),
            const SizedBox(height: 8),
            Text(widget.prixDesc, style: TextStyle(
                fontSize: 13.5, color: Colors.grey.shade700, height: 1.5)),
          ],

          // Règlement
          if (widget.reglement.isNotEmpty) ...[
            const SizedBox(height: 16),
            _sectionTitle('Règlement', Icons.gavel_rounded),
            const SizedBox(height: 8),
            Text(widget.reglement, style: TextStyle(
                fontSize: 13, color: Colors.grey.shade600, height: 1.5)),
          ],

          // Anti-triche
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.security_rounded,
                      color: Colors.orange, size: 16),
                  const SizedBox(width: 8),
                  const Text('Règles anti-triche', style: TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 13,
                    color: Colors.orange,
                  )),
                ]),
                const SizedBox(height: 8),
                ...[
                  'Minuteur strict — soumission automatique à expiration',
                  'Questions mélangées aléatoirement',
                  'Navigation question par question sans retour arrière',
                  'Toute sortie de l\'app est détectée et pénalisée',
                ].map((t) => Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(children: [
                    const Icon(Icons.circle, size: 4, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(child: Text(t, style: TextStyle(
                        fontSize: 12, color: Colors.orange.shade800))),
                  ]),
                )),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Checkbox
          GestureDetector(
            onTap: () => setState(() => _accepte = !_accepte),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _accepte ? const Color(0xFFF3E8FF) : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _accepte ? _olymp : Colors.grey.shade200,
                  width: 1.5,
                ),
              ),
              child: Row(children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 22, height: 22,
                  decoration: BoxDecoration(
                    color: _accepte ? _olymp : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: _accepte ? _olymp : Colors.grey.shade300,
                        width: 2),
                  ),
                  child: _accepte
                      ? const Icon(Icons.check_rounded,
                          color: Colors.white, size: 14)
                      : null,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'J\'ai lu et j\'accepte le règlement et les règles anti-triche',
                    style: TextStyle(fontSize: 13,
                        fontWeight: FontWeight.w600, color: _dark),
                  ),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 20),

          // Bouton confirmer
          GestureDetector(
            onTap: _loading ? null : _inscrire,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                color: _accepte ? _olymp : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(16),
                boxShadow: _accepte
                    ? [BoxShadow(
                        color: _olymp.withOpacity(0.35),
                        blurRadius: 14, offset: const Offset(0, 6))]
                    : [],
              ),
              child: _loading
                  ? const Center(child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
                  : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.military_tech_rounded,
                          color: _accepte ? _gold : Colors.white54,
                          size: 20),
                      const SizedBox(width: 10),
                      Text('Confirmer mon inscription',
                          style: TextStyle(
                            color: _accepte ? Colors.white : Colors.white54,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          )),
                    ]),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String val) {
    return Row(children: [
      Icon(icon, size: 15, color: _olymp),
      const SizedBox(width: 8),
      Text('$label : ', style: TextStyle(
          fontSize: 12, color: Colors.grey.shade500,
          fontWeight: FontWeight.w600)),
      Text(val, style: const TextStyle(
          fontSize: 12.5, color: _dark, fontWeight: FontWeight.w700)),
    ]);
  }

  Widget _sectionTitle(String label, IconData icon) {
    return Row(children: [
      Icon(icon, size: 15, color: _olymp),
      const SizedBox(width: 8),
      Text(label, style: const TextStyle(
          fontSize: 13, fontWeight: FontWeight.w800, color: _dark)),
    ]);
  }
}
