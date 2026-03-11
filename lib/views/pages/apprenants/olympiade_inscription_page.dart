import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const String _baseR = 'https://yekiapp.pythonanywhere.com/api';

class OlympiadeInscriptionPage extends StatefulWidget {
  final int      olympiadeId;
  final String   titre;
  final String   reglement;
  final String   prixDesc;
  final DateTime datDebut;
  final DateTime datFin;

  const OlympiadeInscriptionPage({
    super.key,
    required this.olympiadeId,
    required this.titre,
    required this.reglement,
    required this.prixDesc,
    required this.datDebut,
    required this.datFin,
  });

  @override
  State<OlympiadeInscriptionPage> createState() =>
      _OlympiadeInscriptionPageState();
}

class _OlympiadeInscriptionPageState
    extends State<OlympiadeInscriptionPage> {
  static const _cOlymp   = Color(0xFF7B2FBE);
  static const _cGold    = Color(0xFFE2A84B);
  static const _cPrimary = Color(0xFF0D1B2A);

  bool _accepte = false;
  bool _loading = false;

  Future<String?> _token() async {
    final p = await SharedPreferences.getInstance();
    return p.getString('token');
  }

  Future<void> _inscrire() async {
    if (!_accepte) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Vous devez accepter le règlement.'),
        backgroundColor: Colors.orange,
      ));
      return;
    }

    setState(() => _loading = true);
    final token = await _token();
    final res = await http.post(
      Uri.parse('$_baseR/olympiades/${widget.olympiadeId}/inscrire/'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Token $token',
      },
      body: jsonEncode({'accepte_reglement': true}),
    );

    setState(() => _loading = false);

    if (res.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Inscription confirmée ! Bonne chance.'),
        backgroundColor: _cOlymp,
        behavior: SnackBarBehavior.floating,
      ));
      if (mounted) Navigator.pop(context, true);
    } else if (res.statusCode == 409) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Vous êtes déjà inscrit à cette olympiade.'),
        backgroundColor: Colors.orange,
      ));
      if (mounted) Navigator.pop(context, true);
    } else {
      final msg = jsonDecode(res.body)['detail'] ?? 'Erreur.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg), backgroundColor: Colors.red,
      ));
    }
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} '
      '${d.hour.toString().padLeft(2, '0')}h${d.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Hero header
          SliverAppBar(
            expandedHeight: 210,
            pinned: true,
            backgroundColor: _cOlymp,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded,
                  color: Colors.white, size: 18),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF4A0080), Color(0xFF7B2FBE)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.emoji_events_rounded,
                          color: _cGold, size: 40),
                    ),
                    const SizedBox(height: 12),
                    Text('OLYMPIADE', style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 10, fontWeight: FontWeight.w700,
                      letterSpacing: 2.5,
                    )),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(widget.titre, style: const TextStyle(
                        color: Colors.white, fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ), textAlign: TextAlign.center,
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Calendrier
                _section('Calendrier', Icons.calendar_month_rounded, [
                  _dateRow('Début compétition', widget.datDebut),
                  _dateRow('Fin compétition', widget.datFin),
                ]),
                const SizedBox(height: 16),

                // Prix
                if (widget.prixDesc.isNotEmpty) ...[
                  _section('Récompenses', Icons.stars_rounded, [
                    Text(widget.prixDesc, style: const TextStyle(
                        fontSize: 13.5, height: 1.6, color: _cPrimary)),
                  ]),
                  const SizedBox(height: 16),
                ],

                // Règlement
                if (widget.reglement.isNotEmpty) ...[
                  _section('Règlement', Icons.gavel_rounded, [
                    Text(widget.reglement, style: TextStyle(
                        fontSize: 13.5, height: 1.6,
                        color: Colors.grey.shade700)),
                  ]),
                  const SizedBox(height: 16),
                ],

                // Anti-triche
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Icon(Icons.security_rounded,
                            color: Colors.orange, size: 17),
                        const SizedBox(width: 8),
                        const Text('Règles anti-triche',
                            style: TextStyle(fontWeight: FontWeight.w800,
                                fontSize: 14, color: Colors.orange)),
                      ]),
                      const SizedBox(height: 8),
                      ...[
                        'Minuteur strict — soumission automatique à expiration',
                        'Questions mélangées (ordre différent par participant)',
                        'Navigation question par question sans retour arrière',
                        'Toute sortie de l\'application est détectée et pénalisée',
                        'IP et heure de soumission enregistrées',
                      ].map((t) => Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Row(children: [
                          const Icon(Icons.circle, size: 4,
                              color: Colors.orange),
                          const SizedBox(width: 8),
                          Expanded(child: Text(t, style: TextStyle(
                              fontSize: 12, color: Colors.orange.shade800))),
                        ]),
                      )),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Checkbox règlement
                GestureDetector(
                  onTap: () => setState(() => _accepte = !_accepte),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _accepte
                          ? const Color(0xFFF3E8FF)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _accepte ? _cOlymp : Colors.grey.shade200,
                        width: 1.5,
                      ),
                    ),
                    child: Row(children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 22, height: 22,
                        decoration: BoxDecoration(
                          color: _accepte ? _cOlymp : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: _accepte ? _cOlymp : Colors.grey.shade300,
                            width: 2,
                          ),
                        ),
                        child: _accepte
                            ? const Icon(Icons.check_rounded,
                                color: Colors.white, size: 14)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'J\'ai lu et j\'accepte le règlement de cette olympiade ainsi que les règles anti-triche',
                          style: TextStyle(fontSize: 13,
                              fontWeight: FontWeight.w600, color: _cPrimary),
                        ),
                      ),
                    ]),
                  ),
                ),
                const SizedBox(height: 20),

                // Bouton inscription
                GestureDetector(
                  onTap: _loading ? null : _inscrire,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: _accepte ? _cOlymp : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: _accepte
                          ? [BoxShadow(
                              color: _cOlymp.withOpacity(0.35),
                              blurRadius: 16, offset: const Offset(0, 6))]
                          : [],
                    ),
                    child: _loading
                        ? const Center(child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.emoji_events_rounded,
                                  color: _accepte ? _cGold : Colors.white54,
                                  size: 20),
                              const SizedBox(width: 10),
                              Text('Confirmer mon inscription',
                                  style: TextStyle(
                                    color: _accepte
                                        ? Colors.white
                                        : Colors.white54,
                                    fontWeight: FontWeight.w800, fontSize: 15,
                                  )),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String titre, IconData icon, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.04), blurRadius: 10)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 16, color: _cOlymp),
          const SizedBox(width: 8),
          Text(titre, style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w800, color: _cPrimary)),
        ]),
        const SizedBox(height: 12),
        ...children,
      ]),
    );
  }

  Widget _dateRow(String label, DateTime date) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Text(label, style: TextStyle(fontSize: 13,
            color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFF3E8FF),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(_fmt(date), style: const TextStyle(
              fontSize: 11.5, color: _cOlymp, fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }
}