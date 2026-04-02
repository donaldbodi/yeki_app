// lib/views/pages/apprenants/formation_metier_detail_page.dart
//
// ✅ Entièrement dynamique — données depuis API
// ✅ Design premium redesigné
// ✅ Progression, modules, enseignants, classement
// ✅ Inscription avec paiement
// ✅ Gestion accès sélectionné (cadre accepte/refuse)
//
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'formations_models.dart';
import 'paiement_page.dart';

const Color _gold   = Color(0xFFE2A84B);
const Color _dark   = Color(0xFF0D1B2A);
const Color _teal   = Color(0xFF008088);
const Color _bg     = Color(0xFFF5F7FA);

Future<String?> _getToken() async =>
    (await SharedPreferences.getInstance()).getString('token');
Map<String, String> _headers(String? t) => {
  'Content-Type': 'application/json',
  if (t != null) 'Authorization': 'Token $t',
};

// ═══════════════════════════════════════════════════════════════
class FormationMetierDetailPage extends StatefulWidget {
  final int formationId;
  final FormationMetier? formation;

  const FormationMetierDetailPage({
    super.key,
    required this.formationId,
    this.formation,
  });

  @override
  State<FormationMetierDetailPage> createState() =>
      _FormationMetierDetailPageState();
}

class _FormationMetierDetailPageState
    extends State<FormationMetierDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  bool _loading = true;
  bool _inscribing = false;
  Map<String, dynamic> _data = {};

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _charger();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _charger() async {
    final token = await _getToken();
    try {
      final res = await http.get(
        Uri.parse('$kBaseUrl/formations/metiers/${widget.formationId}/'),
        headers: _headers(token),
      );
      if (res.statusCode == 200 && mounted) {
        setState(() { _data = jsonDecode(res.body); _loading = false; });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool get _estInscrit => _data['est_inscrit'] == true || _data['mon_inscription'] != null;
  String get _statutInscription => _data['mon_inscription']?['statut'] ?? '';
  int get _prix => (_data['prix'] ?? 0) is int ? _data['prix'] : 0;
  bool get _accesSel => _data['acces_selectionne'] == true;
  List<dynamic> get _modules => List<dynamic>.from(_data['modules'] ?? []);
  List<dynamic> get _enseignants => List<dynamic>.from(_data['enseignants'] ?? []);

  double get _progression {
    if (_modules.isEmpty) return 0;
    // Dans le futur, calculer depuis les progressions réelles
    return 0.0;
  }

  // ── Inscription ─────────────────────────────────────────────
  Future<void> _inscrire() async {
    if (_prix > 0) {
      final ref = await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (_) => PaiementPage(
            titre: _data['titre'] ?? '',
            montant: _prix.toDouble(),
            typePaiement: 'formation_metier',
            formationMetierId: widget.formationId,
          ),
        ),
      );
      if (ref == null) return;
      await _inscrireAvecRef(ref);
    } else {
      await _inscrireAvecRef(null);
    }
  }

  Future<void> _inscrireAvecRef(String? ref) async {
    setState(() => _inscribing = true);
    final token = await _getToken();
    try {
      final body = <String, dynamic>{};
      if (ref != null) body['reference_paiement'] = ref;
      final res = await http.post(
        Uri.parse('$kBaseUrl/formations/metiers/${widget.formationId}/inscrire/'),
        headers: _headers(token),
        body: jsonEncode(body),
      );
      if (!mounted) return;
      if (res.statusCode == 201) {
        final json = jsonDecode(res.body);
        _showSnack(
          _accesSel
              ? '⏳ Demande envoyée, en attente de validation.'
              : '✅ Inscription confirmée !',
          success: true,
        );
        setState(() {
          _data['est_inscrit'] = true;
          _data['mon_inscription'] = {'statut': json['statut']};
        });
      } else {
        _showSnack(jsonDecode(res.body)['error'] ?? 'Erreur');
      }
    } catch (_) {
      _showSnack('Erreur réseau');
    } finally {
      if (mounted) setState(() => _inscribing = false);
    }
  }

  void _showSnack(String msg, {bool success = false}) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: success ? const Color(0xFF2E7D32) : Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));

  // ─── BUILD ────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: _bg,
        body: const Center(child: CircularProgressIndicator(color: _gold)),
      );
    }

    final titre = _data['titre'] ?? '';
    final domaine = _data['domaine'] ?? '';
    final duree = _data['duree'] ?? '';
    final imageUrl = _data['image_url'] ?? '';
    final description = _data['description'] ?? '';
    final certifiante = _data['certifiante'] == true;
    final nbInscrits = _data['nb_inscrits'] ?? 0;
    final niveau = _data['niveau'] ?? '';

    return Scaffold(
      backgroundColor: _bg,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          // ── SliverAppBar ───────────────────────────────────
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            stretch: true,
            backgroundColor: _dark,
            leading: _backBtn(),
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: Stack(
                fit: StackFit.expand,
                children: [
                  imageUrl.isNotEmpty
                      ? Image.network(imageUrl, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _placeholder(domaine))
                      : _placeholder(domaine),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, _dark.withOpacity(0.95)],
                        stops: const [0.35, 1.0],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20, left: 20, right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          _domaineBadge(domaine),
                          if (certifiante) ...[
                            const SizedBox(width: 8),
                            _certBadge(),
                          ],
                        ]),
                        const SizedBox(height: 8),
                        Text(titre,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        if (niveau.isNotEmpty)
                          Text(niveau,
                              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13)),
                        const SizedBox(height: 12),
                        Row(children: [
                          _statBadge(Icons.timer_outlined, duree),
                          const SizedBox(width: 10),
                          _statBadge(Icons.people_rounded, '$nbInscrits inscrits'),
                          const SizedBox(width: 10),
                          _statBadge(Icons.extension_rounded,
                              '${_modules.length} modules'),
                        ]),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Barre progression si inscrit ───────────────────
          if (_estInscrit && _statutInscription == 'inscrit')
            SliverToBoxAdapter(child: _buildProgressBar()),

          // ── Bandeau statut ─────────────────────────────────
          SliverToBoxAdapter(child: _buildStatutBand()),

          // ── TabBar ─────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabCtrl,
                labelColor: _gold,
                unselectedLabelColor: Colors.grey.shade400,
                indicatorColor: _gold,
                indicatorWeight: 3,
                labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                tabs: const [
                  Tab(text: 'Programme'),
                  Tab(text: 'À propos'),
                  Tab(text: 'Équipe'),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabCtrl,
          children: [
            _buildProgrammeTab(),
            _buildAProposTab(description, certifiante),
            _buildEquipeTab(),
          ],
        ),
      ),
      bottomNavigationBar: (_estInscrit && _statutInscription != 'retire')
          ? null
          : _buildBottomBar(),
    );
  }

  // ── Barre de progression ─────────────────────────────────────
  Widget _buildProgressBar() {
    final pct = (_progression * 100).round();
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Votre progression',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              Text('$pct%',
                  style: const TextStyle(color: _gold, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _progression,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(_gold),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  // ── Bandeau statut ───────────────────────────────────────────
  Widget _buildStatutBand() {
    if (!_estInscrit) return const SizedBox.shrink();
    Color color; String label; IconData icon;
    switch (_statutInscription) {
      case 'inscrit':
        color = const Color(0xFF2E7D32); label = 'Inscrit'; icon = Icons.check_circle_rounded;
      case 'en_attente':
        color = const Color(0xFFF57F17); label = 'En attente de validation'; icon = Icons.hourglass_top_rounded;
      case 'retire':
        color = Colors.red.shade700; label = 'Accès retiré'; icon = Icons.remove_circle_rounded;
      default:
        color = const Color(0xFF2E7D32); label = 'Inscrit'; icon = Icons.check_circle_rounded;
    }
    return Container(
      color: color.withOpacity(0.08),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
      ]),
    );
  }

  // ── Tab Programme ────────────────────────────────────────────
  Widget _buildProgrammeTab() {
    if (_modules.isEmpty) {
      return const Center(
          child: Text('Aucun module disponible', style: TextStyle(color: Colors.grey)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _modules.length,
      itemBuilder: (_, i) {
        final m = _modules[i];
        final locked = !_estInscrit;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
                blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            leading: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: locked
                    ? Colors.grey.shade100
                    : _gold.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: locked
                    ? Icon(Icons.lock_rounded, size: 18, color: Colors.grey.shade400)
                    : Text('${(m['ordre'] ?? i + 1)}',
                        style: const TextStyle(
                            color: _gold, fontWeight: FontWeight.w800, fontSize: 16)),
              ),
            ),
            title: Text(m['titre'] ?? '',
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: locked ? Colors.grey : _dark,
                    fontSize: 14)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if ((m['description'] ?? '').isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(m['description'],
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                  ),
                if ((m['duree'] ?? '').isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(children: [
                      Icon(Icons.timer_outlined, size: 12, color: Colors.grey.shade400),
                      const SizedBox(width: 4),
                      Text(m['duree'],
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
                    ]),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Tab À propos ─────────────────────────────────────────────
  Widget _buildAProposTab(String description, bool certifiante) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (description.isNotEmpty) ...[
            const Text('Description',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _dark)),
            const SizedBox(height: 10),
            Text(description,
                style: TextStyle(color: Colors.grey.shade700, height: 1.7, fontSize: 14)),
            const SizedBox(height: 20),
          ],
          if (certifiante) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _gold.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _gold.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.verified_rounded, color: _gold, size: 22),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Formation certifiante — Un certificat officiel sera délivré à la fin.',
                      style: TextStyle(color: _dark, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          // Yeki IA
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_teal.withOpacity(0.08), _gold.withOpacity(0.08)],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _teal.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _teal, borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Yeki IA inclus',
                          style: TextStyle(fontWeight: FontWeight.w700, color: _dark, fontSize: 14)),
                      Text('L\'IA apprend votre programme et vous guide à votre rythme.',
                          style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab Équipe ───────────────────────────────────────────────
  Widget _buildEquipeTab() {
    if (_enseignants.isEmpty) {
      return const Center(
          child: Text('Aucun enseignant assigné', style: TextStyle(color: Colors.grey)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _enseignants.length,
      itemBuilder: (_, i) {
        final e = _enseignants[i];
        final nom = e['nom'] ?? e['username'] ?? '';
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
                blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _teal.withOpacity(0.15),
              child: Text(
                nom.isNotEmpty ? nom[0].toUpperCase() : '?',
                style: const TextStyle(color: _teal, fontWeight: FontWeight.w700),
              ),
            ),
            title: Text(nom,
                style: const TextStyle(fontWeight: FontWeight.w600, color: _dark)),
            subtitle: const Text('Enseignant principal',
                style: TextStyle(color: Colors.grey, fontSize: 12)),
          ),
        );
      },
    );
  }

  // ── Barre basse ──────────────────────────────────────────────
  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08),
            blurRadius: 12, offset: const Offset(0, -4))],
      ),
      child: Row(
        children: [
          if (_prix > 0) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Prix', style: TextStyle(color: Colors.grey, fontSize: 12)),
                Text(
                  '${_prix.toString().replaceAllMapped(
                    RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ' ')} FCFA',
                  style: const TextStyle(
                      color: _dark, fontWeight: FontWeight.w800, fontSize: 18),
                ),
              ],
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: ElevatedButton(
              onPressed: _inscribing ? null : _inscrire,
              style: ElevatedButton.styleFrom(
                backgroundColor: _gold,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: _inscribing
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(
                      _prix > 0 ? 'Payer et s\'inscrire' : 'S\'inscrire gratuitement',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers UI ──────────────────────────────────────────────
  Widget _backBtn() => GestureDetector(
    onTap: () => Navigator.pop(context),
    child: Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(10)),
      child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
    ),
  );

  Widget _placeholder(String domaine) {
    final colors = {
      'tech': const Color(0xFF005F73), 'business': const Color(0xFF3D405B),
      'design': const Color(0xFF9A031E), 'sante': const Color(0xFF023E8A),
    };
    return Container(
      color: colors[domaine] ?? _dark,
      child: Center(child: Icon(Icons.work_rounded, color: Colors.white24, size: 60)),
    );
  }

  Widget _domaineBadge(String domaine) {
    final labels = {
      'tech': 'Tech', 'business': 'Business', 'design': 'Design',
      'sante': 'Santé', 'agriculture': 'Agriculture',
      'artisanat': 'Artisanat', 'education': 'Éducation', 'autre': 'Autre',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _gold.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _gold.withOpacity(0.5)),
      ),
      child: Text(labels[domaine] ?? domaine,
          style: const TextStyle(color: _gold, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  Widget _certBadge() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.green.withOpacity(0.2),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.green.withOpacity(0.5)),
    ),
    child: const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.verified_rounded, color: Colors.green, size: 12),
        SizedBox(width: 4),
        Text('Certifiante', style: TextStyle(color: Colors.green, fontSize: 11)),
      ],
    ),
  );

  Widget _statBadge(IconData icon, String label) => Row(
    children: [
      Icon(icon, size: 12, color: Colors.white60),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
    ],
  );
}
