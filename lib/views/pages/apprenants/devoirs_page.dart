// lib/views/pages/apprenants/devoirs_page.dart
// ════════════════════════════════════════════════════════════════
// PAGE DEVOIRS GÉNÉRAUX — Design Premium Dynamique
// ════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yeki/widgets/yeki_app_bar.dart';
import 'formations_models.dart';
import 'composer_devoir_page.dart';
import 'resultat_devoir_page.dart';

// Palette Premium
const Color brandPrimary = Color(0xFF135F74);
const Color brandGold = Color(0xFFC5A059);
const Color textMain = Color(0xFF0F172A);
const Color textSub = Color(0xFF64748B);
const Color _borderLight = Color(0xFFE0E4E8);
const Color _bgLight = Color(0xFFF8FAFC);
const Color _white = Color(0xFFFFFFFF);
const Color _green = Color(0xFF10B981);
const Color _red = Color(0xFFEF4444);
const Color _orange = Color(0xFFF97316);
const Color _purple = Color(0xFF8B5CF6);

class DevoirsPage extends StatefulWidget {
  final bool estEnseignantPrincipal;
  const DevoirsPage({super.key, required this.estEnseignantPrincipal});

  @override
  State<DevoirsPage> createState() => _DevoirsPageState();
}

class _DevoirsPageState extends State<DevoirsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  bool _loading = true;
  List<Map<String, dynamic>> _tous = [];
  List<Map<String, dynamic>> _affiches = [];

  String _typeSelectionne = 'Tous';
  String? _matiereSelectionnee;
  String? _niveauSelectionne;
  String _statutSelectionne = 'Tous';
  String _recherche = '';

  // Données pour YekiHeader
  int _unreadNotifications = 0;
  bool _isSubscribed = true;
  String _username = 'Apprenant';

  final List<_TypeDevoirTab> _types = [
    _TypeDevoirTab('Tous', Icons.grid_view_rounded, brandPrimary),
    _TypeDevoirTab('cursus', Icons.school_rounded, Colors.indigo),
    _TypeDevoirTab('concours', Icons.emoji_events_rounded, brandGold),
    _TypeDevoirTab('formation_classique', Icons.account_balance_rounded, Colors.teal),
    _TypeDevoirTab('formation_metier', Icons.work_rounded, Colors.deepOrange),
    _TypeDevoirTab('olympiade', Icons.military_tech_rounded, _orange),
  ];

  final List<String> _matieres = [
    'Mathématiques', 'Physique', 'Chimie', 'SVT', 'Informatique',
    'Français', 'Anglais', 'Histoire-Géo', 'Philosophie', 'Économie', 'Autre',
  ];
  final List<String> _niveaux = [
    'Terminale', '1ère', '2nde', '3ème',
    'Licence 1', 'Licence 2', 'Licence 3', 'Master 1', 'Master 2', 'Autre',
  ];
  final List<String> _statuts = [
    'Tous', 'non_commence', 'en_cours', 'soumis', 'corrige', 'en_retard',
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _types.length, vsync: this)
      ..addListener(() {
        if (!_tabCtrl.indexIsChanging) {
          setState(() {
            _typeSelectionne = _types[_tabCtrl.index].code;
            _appliquerFiltres();
          });
        }
      });
    _charger();
    _loadUserData();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;
    try {
      final response = await http.get(
        Uri.parse('$kBaseUrl/profil/me/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() => _username = data['username'] ?? 'Apprenant');
      }
    } catch (_) {}
  }

  Future<String?> _token() async =>
      (await SharedPreferences.getInstance()).getString('token');

  Future<void> _charger() async {
    setState(() => _loading = true);
    final token = await _token();
    try {
      final res = await http.get(
        Uri.parse('$kBaseUrl/devoirs/'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Token $token',
        },
      );
      if (res.statusCode == 200) {
        _tous = (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();
        _appliquerFiltres();
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  void _appliquerFiltres() {
    List<Map<String, dynamic>> temp = List.from(_tous);
    if (_typeSelectionne != 'Tous')
      temp = temp.where((d) => d['type_devoir'] == _typeSelectionne).toList();
    if (_matiereSelectionnee != null)
      temp = temp.where((d) => d['matiere'] == _matiereSelectionnee).toList();
    if (_niveauSelectionne != null) {
      temp = temp.where((d) => d['niveau'] == _niveauSelectionne).toList();
    }
    if (_statutSelectionne != 'Tous') {
      temp = temp.where((d) => d['statut_apprenant'] == _statutSelectionne).toList();
    }
    if (_recherche.isNotEmpty)
      temp = temp.where((d) =>
          (d['titre'] as String? ?? '').toLowerCase().contains(_recherche.toLowerCase())).toList();
    setState(() => _affiches = temp);
  }

  int get _aFaire => _tous.where((d) => d['statut_apprenant'] == 'non_commence').length;
  int get _enRetard => _tous.where((d) => d['statut_apprenant'] == 'en_retard').length;

  Future<void> _deconnecter() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: _white,
        title: const Text('Déconnexion',
            style: TextStyle(fontWeight: FontWeight.bold, color: textMain)),
        content: const Text(
          'Souhaitez-vous vraiment quitter l\'application ?',
          style: TextStyle(color: textSub),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Annuler', style: TextStyle(color: textSub)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: _white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgLight,
      appBar: YekiHeader(
        unreadNotifications: _unreadNotifications,
        isSubscribed: _isSubscribed,
        userRole: 'Apprenant',
        username: _username,
        avatarUrl: null,
        onLogout: _deconnecter,
        onSettings: () {},
        onNotifications: () {},
      ),
      body: Column(
        children: [
          //_buildHeroSection(),
          _buildStatsSection(),
          _buildTabsSection(),
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  /*Widget _buildHeroSection() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [brandPrimary, brandPrimary.withOpacity(0.85)],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: brandGold.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text("ÉVALUATIONS", 
                style: TextStyle(color: brandGold, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
            ),
            const SizedBox(height: 10),
            const Text("Mes Devoirs", 
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: _white, letterSpacing: -0.5)),
            const SizedBox(height: 4),
            const Text("Suivez vos progrès et réussissez vos examens", 
              style: TextStyle(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }*/

  Widget _buildStatsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: _white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _borderLight, width: 1),
              ),
              child: Column(
                children: [
                  Text(
                    '${_tous.length}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: brandPrimary),
                  ),
                  const Text('Total', style: TextStyle(fontSize: 11, color: textSub)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: _white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _borderLight, width: 1),
              ),
              child: Column(
                children: [
                  Text(
                    '$_aFaire',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.indigo),
                  ),
                  const Text('À faire', style: TextStyle(fontSize: 11, color: textSub)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: _white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _borderLight, width: 1),
              ),
              child: Column(
                children: [
                  Text(
                    '$_enRetard',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _red),
                  ),
                  const Text('En retard', style: TextStyle(fontSize: 11, color: textSub)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabsSection() {
    return Container(
      color: _white,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SizedBox(
        height: 48,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _types.length,
          itemBuilder: (context, index) {
            final type = _types[index];
            final isSelected = _typeSelectionne == type.code;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _typeSelectionne = type.code;
                  _tabCtrl.animateTo(index);
                  _appliquerFiltres();
                });
              },
              child: Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? type.color : _bgLight,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isSelected ? type.color : _borderLight,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(type.icon, size: 16, color: isSelected ? _white : type.color),
                    const SizedBox(width: 6),
                    Text(
                      _labelType(type.code),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? _white : type.color,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: brandPrimary));
    }

    return Column(
      children: [
        _buildFiltersBar(),
        _buildSearchBar(),
        Expanded(
          child: _affiches.isEmpty
              ? const _EmptyState()
              : RefreshIndicator(
                  onRefresh: _charger,
                  color: brandPrimary,
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    itemCount: _affiches.length,
                    itemBuilder: (_, i) => _buildCard(_affiches[i]),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildFiltersBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          _buildFilterDropdown(
            value: _matiereSelectionnee,
            hint: 'Matière',
            items: _matieres,
            onChanged: (v) => setState(() {
              _matiereSelectionnee = v;
              _appliquerFiltres();
            }),
          ),
          const SizedBox(width: 8),
          _buildFilterDropdown(
            value: _niveauSelectionne,
            hint: 'Niveau',
            items: _niveaux,
            onChanged: (v) => setState(() {
              _niveauSelectionne = v;
              _appliquerFiltres();
            }),
          ),
          const SizedBox(width: 8),
          _buildFilterDropdown(
            value: _statutSelectionne == 'Tous' ? null : _statutSelectionne,
            hint: 'Statut',
            items: _statuts.where((s) => s != 'Tous').toList(),
            onChanged: (v) => setState(() {
              _statutSelectionne = v ?? 'Tous';
              _appliquerFiltres();
            }),
            labelBuilder: _labelStatut,
          ),
          if (_matiereSelectionnee != null || _niveauSelectionne != null || _statutSelectionne != 'Tous')
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: GestureDetector(
                onTap: () => setState(() {
                  _matiereSelectionnee = null;
                  _niveauSelectionne = null;
                  _statutSelectionne = 'Tous';
                  _appliquerFiltres();
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _red.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _red.withOpacity(0.2), width: 1),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.clear_rounded, size: 14, color: _red),
                      SizedBox(width: 4),
                      Text('Effacer', style: TextStyle(fontSize: 12, color: _red, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String? value,
    required String hint,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    String Function(String)? labelBuilder,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderLight, width: 1),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint, style: TextStyle(fontSize: 12, color: textSub)),
          isDense: true,
          items: items.map((s) => DropdownMenuItem(
            value: s,
            child: Text(
              labelBuilder != null ? labelBuilder(s) : s,
              style: const TextStyle(fontSize: 12, color: textMain),
            ),
          )).toList(),
          onChanged: onChanged,
          icon: Icon(Icons.keyboard_arrow_down, size: 18, color: textSub),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          color: _white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _borderLight, width: 1),
        ),
        child: TextField(
          onChanged: (v) => setState(() {
            _recherche = v;
            _appliquerFiltres();
          }),
          decoration: InputDecoration(
            hintText: 'Rechercher un devoir...',
            prefixIcon: Icon(Icons.search_rounded, color: brandPrimary, size: 20),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            hintStyle: TextStyle(fontSize: 13, color: textSub),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> d) {
    final statut = d['statut_apprenant'] as String? ?? 'non_commence';
    final estExpire = d['est_expire'] == true;
    final jours = d['temps_restant_jours'] as int? ?? 0;
    final color = _colorForType(d['type_devoir'] as String?);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderLight, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(width: 5, color: color),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildTypeBadge(label: _labelType(d['type_devoir'] ?? 'cursus'), color: color),
                          _buildStatutBadge(statut: statut),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        d['titre'] as String? ?? 'Sans titre',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textMain),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.layers_outlined, size: 13, color: textSub),
                          const SizedBox(width: 4),
                          Text(
                            '${d['matiere'] ?? ''} • ${d['niveau'] ?? ''}',
                            style: TextStyle(color: textSub, fontSize: 12),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildTimerInfo(jours: jours, expire: estExpire),
                          _buildActionButton(
                            d: d,
                            statut: statut,
                            expire: estExpire,
                            onOuvrir: () => _ouvrirDevoir(d),
                            onResultat: () => _voirResultat(d),
                            color: color,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeBadge({required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildStatutBadge({required String statut}) {
    final (label, color) = _getStatutInfo(statut);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800),
      ),
    );
  }

  Widget _buildTimerInfo({required int jours, required bool expire}) {
    if (expire) {
      return Text('Clôturé', style: TextStyle(color: textSub, fontSize: 12));
    }
    final c = jours < 3 ? _red : (jours < 7 ? _orange : _green);
    return Row(
      children: [
        Icon(Icons.access_time_rounded, size: 13, color: c),
        const SizedBox(width: 4),
        Text('$jours j', style: TextStyle(color: c, fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildActionButton({
    required Map<String, dynamic> d,
    required String statut,
    required bool expire,
    required VoidCallback onOuvrir,
    required VoidCallback onResultat,
    required Color color,
  }) {
    if (statut == 'corrige') {
      return TextButton.icon(
        onPressed: onResultat,
        icon: const Icon(Icons.analytics_outlined, size: 14),
        label: Text('Note: ${d['note_apprenant']}/${d['note_sur']}'),
        style: TextButton.styleFrom(
          foregroundColor: _green,
          padding: const EdgeInsets.symmetric(horizontal: 8),
        ),
      );
    }
    if (expire && statut != 'soumis') {
      return const SizedBox.shrink();
    }
    return ElevatedButton(
      onPressed: onOuvrir,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: _white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        minimumSize: const Size(0, 34),
      ),
      child: Text(
        statut == 'en_cours' ? 'Continuer' : 'Commencer',
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _ouvrirDevoir(Map<String, dynamic> d) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ComposerDevoirPage(
          devoirId: d['id'] as int,
          titre: d['titre'] as String? ?? '',
          dureeMin: d['duree_minutes'] as int? ?? 60,
          noteSur: d['note_sur'] as int? ?? 20,
        ),
      ),
    ).then((_) => _charger());
  }

  void _voirResultat(Map<String, dynamic> d) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ResultatDevoirPage(
          devoirId: d['id'] as int,
          titre: d['titre'] as String? ?? '',
        ),
      ),
    );
  }

  String _labelType(String code) => {
    'Tous': 'Tous',
    'cursus': 'Cursus',
    'concours': 'Concours',
    'formation_classique': 'Formation',
    'formation_metier': 'Métier',
    'olympiade': 'Olympiade',
  }[code] ?? code;

  String _labelStatut(String s) => {
    'non_commence': 'À faire',
    'en_cours': 'En cours',
    'soumis': 'Soumis',
    'corrige': 'Corrigé',
    'en_retard': 'En retard',
  }[s] ?? s;

  (String, Color) _getStatutInfo(String statut) {
    switch (statut) {
      case 'non_commence': return ('À FAIRE', brandPrimary);
      case 'en_cours': return ('EN COURS', _purple);
      case 'soumis': return ('SOUMIS', _orange);
      case 'corrige': return ('CORRIGÉ', _green);
      case 'en_retard': return ('RETARD', _red);
      default: return ('-', Colors.grey);
    }
  }

  Color _colorForType(String? type) {
    switch (type) {
      case 'cursus': return Colors.indigo;
      case 'concours': return brandGold;
      case 'formation_classique': return Colors.teal;
      case 'formation_metier': return Colors.deepOrange;
      case 'olympiade': return _orange;
      default: return brandPrimary;
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_turned_in_outlined, size: 70, color: _borderLight),
          const SizedBox(height: 16),
          const Text(
            'Aucun devoir',
            style: TextStyle(color: textSub, fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ajustez vos filtres pour voir plus de résultats',
            style: TextStyle(color: textSub, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _TypeDevoirTab {
  final String code;
  final IconData icon;
  final Color color;
  const _TypeDevoirTab(this.code, this.icon, this.color);
}