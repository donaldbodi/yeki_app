// lib/views/pages/apprenants/formation_classique_detail_page.dart
//
// ✅ Entièrement dynamique — charge depuis l'API
// ✅ Design amélioré avec SliverAppBar hero
// ✅ Inscription avec paiement si prix > 0
// ✅ Yeki IA badge intégré
//
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'formations_models.dart';
import 'paiement_page.dart';

const Color _teal   = Color(0xFF008088);
const Color _dark   = Color(0xFF0D1B2A);
const Color _gold   = Color(0xFFE2A84B);
const Color _bg     = Color(0xFFF5F7FA);

Future<String?> _getToken() async =>
    (await SharedPreferences.getInstance()).getString('token');
Map<String, String> _headers(String? t) => {
  'Content-Type': 'application/json',
  if (t != null) 'Authorization': 'Token $t',
};

// ═══════════════════════════════════════════════════════════════
class FormationClassiqueDetailPage extends StatefulWidget {
  final int formationId;
  final FormationClassique? formation; // pré-chargé si disponible

  const FormationClassiqueDetailPage({
    super.key,
    required this.formationId,
    this.formation,
  });

  @override
  State<FormationClassiqueDetailPage> createState() =>
      _FormationClassiqueDetailPageState();
}

class _FormationClassiqueDetailPageState
    extends State<FormationClassiqueDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  bool _loading = true;
  bool _inscribing = false;
  Map<String, dynamic> _data = {};

  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _selectedNiveau = 'Tous';
  String _selectedMatiere = 'Toutes';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    if (widget.formation != null) {
      _data = {
        'id': widget.formation!.id,
        'ecole': widget.formation!.ecole,
        'parcours': widget.formation!.parcours,
        'ville': widget.formation!.ville,
        'pays': widget.formation!.pays,
        'image_url': widget.formation!.imageUrl,
        'description': widget.formation!.description,
        'type': widget.formation!.type,
        'est_publique': widget.formation!.estPublique,
        'prix': 0,
        'nb_cours': widget.formation!.nbCours,
        'nb_etudiants': widget.formation!.nbEtudiants,
        'niveaux': widget.formation!.niveaux,
        'matieres': widget.formation!.matieres,
        'cours': widget.formation!.cours.map((c) => {
          'id': c.id, 'titre': c.titre, 'matiere': c.matiere,
          'niveau': c.niveau, 'enseignant': c.enseignant,
          'nb_lecons': c.nbLecons, 'duree': c.duree, 'ordre': c.ordre,
        }).toList(),
        'est_inscrit': widget.formation!.estInscrit,
        'mon_inscription': null,
      };
      _loading = false;
    }
    _charger();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _charger() async {
    final token = await _getToken();
    try {
      final res = await http.get(
        Uri.parse('$kBaseUrl/formations/classiques/${widget.formationId}/'),
        headers: _headers(token),
      );
      if (res.statusCode == 200 && mounted) {
        setState(() {
          _data = jsonDecode(res.body);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<dynamic> get _coursFiltres {
    final cours = List<dynamic>.from(_data['cours'] ?? []);
    return cours.where((c) {
      final q = _searchQuery.toLowerCase();
      final matchSearch = q.isEmpty ||
          (c['titre'] as String? ?? '').toLowerCase().contains(q) ||
          (c['enseignant'] as String? ?? '').toLowerCase().contains(q);
      final matchNiveau = _selectedNiveau == 'Tous' || c['niveau'] == _selectedNiveau;
      final matchMatiere = _selectedMatiere == 'Toutes' || c['matiere'] == _selectedMatiere;
      return matchSearch && matchNiveau && matchMatiere;
    }).toList();
  }

  List<String> get _niveaux =>
      ['Tous', ...List<String>.from(_data['niveaux'] ?? [])];
  List<String> get _matieres =>
      ['Toutes', ...List<String>.from(_data['matieres'] ?? [])];
  bool get _estInscrit => _data['est_inscrit'] == true;
  int get _prix => _data['prix'] ?? 0;

  // ── Inscription ─────────────────────────────────────────────
  Future<void> _inscrire() async {
    if (_prix > 0) {
      final result = await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (_) => PaiementPage(
            titre: _data['ecole'] ?? '',
            montant: _prix.toDouble(),
            typePaiement: 'formation_classique',
            formationClassiqueId: widget.formationId,
          ),
        ),
      );
      if (result == null) return; // annulé
      _inscrireAvecReference(result);
    } else {
      _inscrireAvecReference(null);
    }
  }

  Future<void> _inscrireAvecReference(String? reference) async {
    setState(() => _inscribing = true);
    final token = await _getToken();
    try {
      final body = <String, dynamic>{};
      if (reference != null) body['reference_paiement'] = reference;
      final res = await http.post(
        Uri.parse('$kBaseUrl/formations/classiques/${widget.formationId}/inscrire/'),
        headers: _headers(token),
        body: jsonEncode(body),
      );
      if (!mounted) return;
      if (res.statusCode == 201) {
        final json = jsonDecode(res.body);
        final statut = json['statut'] ?? 'en_attente';
        _showSnack(
          statut == 'accepte'
              ? '✅ Inscription confirmée !'
              : '⏳ Demande envoyée, en attente de validation.',
          success: true,
        );
        setState(() {
          _data['est_inscrit'] = true;
          _data['mon_inscription'] = {'statut': statut};
        });
      } else {
        final msg = jsonDecode(res.body)['error'] ?? 'Erreur inscription';
        _showSnack(msg);
      }
    } catch (e) {
      _showSnack('Erreur réseau');
    } finally {
      if (mounted) setState(() => _inscribing = false);
    }
  }

  void _showSnack(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: success ? const Color(0xFF2E7D32) : Colors.red.shade700,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  // ─── BUILD ────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: _bg,
        body: const Center(child: CircularProgressIndicator(color: _teal)),
      );
    }

    final ecole = _data['ecole'] ?? '';
    final parcours = _data['parcours'] ?? '';
    final ville = _data['ville'] ?? '';
    final pays = _data['pays'] ?? '';
    final imageUrl = _data['image_url'] ?? '';
    final description = _data['description'] ?? '';
    final nbCours = _data['nb_cours'] ?? 0;
    final nbEtudiants = _data['nb_etudiants'] ?? 0;
    final type = _data['type'] ?? '';
    final inscription = _data['mon_inscription'];

    return Scaffold(
      backgroundColor: _bg,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          // ── SliverAppBar hero ───────────────────────────────
          SliverAppBar(
            expandedHeight: 280,
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
                          errorBuilder: (_, __, ___) => _placeholder())
                      : _placeholder(),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          _dark.withOpacity(0.9),
                        ],
                        stops: const [0.4, 1.0],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20, left: 20, right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _typeBadge(type),
                        const SizedBox(height: 8),
                        Text(ecole,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w800)),
                        if (parcours.isNotEmpty)
                          Text(parcours,
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.75),
                                  fontSize: 14)),
                        const SizedBox(height: 10),
                        Row(children: [
                          _statChip(Icons.book_rounded, '$nbCours cours'),
                          const SizedBox(width: 8),
                          _statChip(Icons.people_rounded, '$nbEtudiants étudiants'),
                          const SizedBox(width: 8),
                          _statChip(Icons.location_on_rounded, '$ville, $pays'),
                        ]),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Bandeau inscription ─────────────────────────────
          SliverToBoxAdapter(child: _buildInscriptionBand(inscription)),

          // ── TabBar ──────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabCtrl,
                labelColor: _teal,
                unselectedLabelColor: Colors.grey.shade400,
                indicatorColor: _teal,
                indicatorWeight: 3,
                labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                tabs: const [Tab(text: 'Cours'), Tab(text: 'Informations')],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabCtrl,
          children: [_buildCoursTab(), _buildInfoTab(description)],
        ),
      ),
      // ── Bouton d'inscription flottant ───────────────────────
      bottomNavigationBar: _estInscrit ? null : _buildBottomBar(),
    );
  }

  // ── Bandeau statut inscription ───────────────────────────────
  Widget _buildInscriptionBand(dynamic inscription) {
    if (!_estInscrit) return const SizedBox.shrink();
    final statut = inscription?['statut'] ?? 'accepte';
    final Color color;
    final String label;
    final IconData icon;
    if (statut == 'accepte') {
      color = const Color(0xFF2E7D32); label = 'Accès accordé'; icon = Icons.check_circle_rounded;
    } else if (statut == 'en_attente') {
      color = const Color(0xFFF57F17); label = 'En attente de validation'; icon = Icons.hourglass_empty_rounded;
    } else {
      color = Colors.red.shade700; label = 'Accès refusé'; icon = Icons.cancel_rounded;
    }
    return Container(
      color: color.withOpacity(0.08),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ── Tab Cours ───────────────────────────────────────────────
  Widget _buildCoursTab() {
    return Column(
      children: [
        // Filtres
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(children: [
            TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Rechercher un cours…',
                prefixIcon: const Icon(Icons.search, color: _teal),
                filled: true, fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                ..._niveaux.map((n) => Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(n, style: const TextStyle(fontSize: 12)),
                    selected: _selectedNiveau == n,
                    selectedColor: _teal.withOpacity(0.15),
                    labelStyle: TextStyle(
                        color: _selectedNiveau == n ? _teal : Colors.grey.shade600),
                    onSelected: (_) => setState(() => _selectedNiveau = n),
                  ),
                )),
              ]),
            ),
          ]),
        ),
        // Liste cours
        Expanded(
          child: _coursFiltres.isEmpty
              ? const Center(child: Text('Aucun cours trouvé'))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 80),
                  itemCount: _coursFiltres.length,
                  itemBuilder: (_, i) => _buildCoursCard(_coursFiltres[i]),
                ),
        ),
      ],
    );
  }

  Widget _buildCoursCard(Map<String, dynamic> c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05),
            blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: _teal.withOpacity(0.12), borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.menu_book_rounded, color: _teal, size: 22),
        ),
        title: Text(c['titre'] ?? '',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(c['matiere'] ?? '', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
            const SizedBox(height: 4),
            Row(children: [
              Icon(Icons.person_outline_rounded, size: 12, color: Colors.grey.shade400),
              const SizedBox(width: 4),
              Text(c['enseignant'] ?? '', style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
              const SizedBox(width: 12),
              Icon(Icons.play_circle_outline_rounded, size: 12, color: Colors.grey.shade400),
              const SizedBox(width: 4),
              Text('${c['nb_lecons']} leçons', style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
              const SizedBox(width: 12),
              Icon(Icons.timer_outlined, size: 12, color: Colors.grey.shade400),
              const SizedBox(width: 4),
              Text(c['duree'] ?? '', style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
            ]),
          ],
        ),
        trailing: _estInscrit
            ? const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: _teal)
            : Icon(Icons.lock_outline_rounded, size: 18, color: Colors.grey.shade300),
        onTap: _estInscrit ? () {
          // Naviguer vers le cours
        } : null,
      ),
    );
  }

  // ── Tab Infos ───────────────────────────────────────────────
  Widget _buildInfoTab(String description) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (description.isNotEmpty) ...[
            const Text('À propos',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _dark)),
            const SizedBox(height: 8),
            Text(description,
                style: TextStyle(color: Colors.grey.shade700, height: 1.6)),
            const SizedBox(height: 20),
          ],
          // Yeki IA badge
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_teal.withOpacity(0.1), _gold.withOpacity(0.1)],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _teal.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _teal, borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Yeki IA disponible',
                          style: TextStyle(fontWeight: FontWeight.w700, color: _dark)),
                      Text('Un assistant IA personnalisé vous accompagne dans cette formation.',
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

  // ── Barre de paiement/inscription ───────────────────────────
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
                Text('${_prix.toString().replaceAllMapped(
                  RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ' ')} FCFA',
                    style: const TextStyle(color: _dark, fontWeight: FontWeight.w800, fontSize: 18)),
              ],
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: ElevatedButton(
              onPressed: _inscribing ? null : _inscrire,
              style: ElevatedButton.styleFrom(
                backgroundColor: _teal,
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
      decoration: BoxDecoration(
        color: Colors.black45, borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
    ),
  );

  Widget _placeholder() => Container(
    color: _dark,
    child: const Center(child: Icon(Icons.school_rounded, color: Colors.white24, size: 60)),
  );

  Widget _typeBadge(String type) {
    final labels = {
      'grande_ecole': 'Grande École', 'universite': 'Université',
      'lycee': 'Lycée', 'centre_formation': 'Centre de formation',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _gold.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _gold.withOpacity(0.5)),
      ),
      child: Text(labels[type] ?? type,
          style: const TextStyle(color: _gold, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  Widget _statChip(IconData icon, String label) => Row(
    children: [
      Icon(icon, size: 12, color: Colors.white60),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
    ],
  );
}
