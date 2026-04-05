import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// Palette Premium Harmonisée
const Color brandPrimary = Color(0xFF135F74);
const Color brandGold = Color(0xFFC5A059);
const Color textMain = Color(0xFF0F172A);
const Color textSub = Color(0xFF64748B);
const Color _borderLight = Color(0xFFE0E4E8);
const Color _bgLight = Color(0xFFF8FAFC);
const Color _white = Color(0xFFFFFFFF);
const Color _green = Color(0xFF10B981);
const Color _orange = Color(0xFFF97316);
const Color _purple = Color(0xFF8B5CF6);
const Color _red = Color(0xFFEF4444);
const Color _borderMedium = Color(0xFFD0D4D8);

const String _baseUrl = 'https://yeki.pythonanywhere.com/api';

class AdminGeneralPage extends StatefulWidget {
  const AdminGeneralPage({super.key});

  @override
  State<AdminGeneralPage> createState() => _AdminGeneralPageState();
}

class _AdminGeneralPageState extends State<AdminGeneralPage>
    with SingleTickerProviderStateMixin {
  bool _loading = true;
  Map<String, dynamic> _stats = {};
  List _parcours = [];
  List _departements = [];
  List _topEnseignants = [];
  String _nomEnseignant = '';
  late TabController _tabCtrl;

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

  Future<String?> _getToken() async {
    final p = await SharedPreferences.getInstance();
    return p.getString('token');
  }

  Future<void> _charger() async {
    setState(() => _loading = true);
    final token = await _getToken();
    if (token == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/admin-general/dashboard/'),
        headers: {'Authorization': 'Token $token'},
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _stats = data['stats'] ?? {};
          _parcours = data['parcours'] ?? [];
          _departements = data['departements'] ?? [];
          _topEnseignants = data['top_enseignants'] ?? [];
          _nomEnseignant = data['nom'] ?? '';
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
        _showError('Erreur chargement (${res.statusCode})');
      }
    } catch (_) {
      setState(() => _loading = false);
      _showError('Erreur réseau');
    }
  }

  void _creerParcours() {
    final nomCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String selectedType = 'cursus';
    bool isLoading = false;

    final List<Map<String, dynamic>> typesParcours = [
      {'code': 'cursus', 'label': 'Cursus scolaire / universitaire', 'icon': Icons.school_rounded, 'color': Colors.indigo},
      {'code': 'prepa', 'label': 'Prépa Concours', 'icon': Icons.emoji_events_rounded, 'color': brandGold},
      {'code': 'formation', 'label': 'Formations professionnelles', 'icon': Icons.work_rounded, 'color': Colors.deepOrange},
      {'code': 'autre', 'label': 'Autre', 'icon': Icons.category_rounded, 'color': Colors.grey},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Container(
          decoration: BoxDecoration(
            color: _white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sheetHandle(),
                const SizedBox(height: 20),
                const Text('Créer un parcours',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textMain)),
                const SizedBox(height: 6),
                const Text(
                  'Un enseignant administrateur pourra être nommé à la tête du parcours.',
                  style: TextStyle(fontSize: 12, color: textSub),
                ),
                const SizedBox(height: 24),
                _field(nomCtrl, 'Nom du parcours *', Icons.route, 'Ex: Licence Informatique'),
                const SizedBox(height: 16),
                _field(descCtrl, 'Description', Icons.description_outlined,
                    'Objectifs et contenu du parcours', maxLines: 3),
                const SizedBox(height: 20),
                const Text('Type de parcours *',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textMain)),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: _bgLight,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _borderLight, width: 1),
                  ),
                  child: Column(
                    children: typesParcours.map((type) {
                      return RadioListTile<String>(
                        value: type['code'],
                        groupValue: selectedType,
                        onChanged: (value) => setS(() => selectedType = value!),
                        activeColor: type['color'],
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        title: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: type['color'].withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(type['icon'], size: 18, color: type['color']),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(type['label'],
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textMain)),
                            ),
                          ],
                        ),
                        controlAffinity: ListTileControlAffinity.trailing,
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brandPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                    ),
                    onPressed: isLoading ? null : () async {
                      if (nomCtrl.text.trim().isEmpty) {
                        _showError('Le nom est obligatoire');
                        return;
                      }
                      setS(() => isLoading = true);
                      final token = await _getToken();
                      try {
                        final res = await http.post(
                          Uri.parse('$_baseUrl/parcours/creer/'),
                          headers: {
                            'Authorization': 'Token $token',
                            'Content-Type': 'application/json',
                          },
                          body: jsonEncode({
                            'nom': nomCtrl.text.trim(),
                            'description': descCtrl.text.trim(),
                            'type_parcours': selectedType,
                          }),
                        );
                        setS(() => isLoading = false);
                        if (res.statusCode == 201) {
                          if (ctx.mounted) Navigator.pop(ctx);
                          _showSuccess('Parcours créé avec succès !');
                          _charger();
                        } else {
                          final err = jsonDecode(res.body);
                          _showError(err['detail'] ?? 'Erreur ${res.statusCode}');
                        }
                      } catch (_) {
                        setS(() => isLoading = false);
                        _showError('Erreur réseau');
                      }
                    },
                    child: isLoading
                        ? const SizedBox(
                            width: 22, height: 22,
                            child: CircularProgressIndicator(color: _white, strokeWidth: 2),
                          )
                        : const Text('Créer le parcours',
                            style: TextStyle(color: _white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _changerAdmin(Map parcours) async {
    final token = await _getToken();
    if (token == null) return;

    List enseignants = [];
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/enseignants/liste/?role=admin'),
        headers: {'Authorization': 'Token $token'},
      );
      if (res.statusCode == 200) {
        enseignants = jsonDecode(res.body);
      } else {
        _showError('Impossible de charger les enseignants (${res.statusCode})');
        return;
      }
    } catch (_) {
      _showError('Erreur réseau');
      return;
    }

    if (!mounted) return;

    int? selected = parcours['enseignant_admin']?['id'] as int?;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Container(
          decoration: BoxDecoration(
            color: _white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _sheetHandle(),
              const SizedBox(height: 20),
              Text(
                parcours['enseignant_admin'] == null
                    ? 'Nommer un enseignant administrateur'
                    : 'Changer l\'enseignant administrateur',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textMain),
              ),
              const SizedBox(height: 6),
              Text(
                'Parcours : ${parcours['nom'] ?? ''}',
                style: const TextStyle(fontSize: 13, color: textSub),
              ),
              const SizedBox(height: 20),
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.4),
                child: enseignants.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Text(
                            'Aucun enseignant administrateur disponible.\n'
                            'Vérifiez qu\'il existe des comptes avec le rôle "enseignant_admin" actifs.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: textSub),
                          ),
                        ),
                      )
                    : ListView(
                        shrinkWrap: true,
                        children: enseignants.map<Widget>((e) => RadioListTile<int>(
                          value: e['id'] as int,
                          groupValue: selected,
                          activeColor: brandPrimary,
                          title: Text(e['nom'] ?? e['username'] ?? '',
                              style: const TextStyle(color: textMain)),
                          subtitle: Text(e['email'] ?? '',
                              style: const TextStyle(color: textSub)),
                          onChanged: (v) => setS(() => selected = v),
                        )).toList(),
                      ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                  ),
                  onPressed: selected == null ? null : () async {
                    if (ctx.mounted) Navigator.pop(ctx);
                    final token2 = await _getToken();
                    if (token2 == null) return;
                    try {
                      final res = await http.patch(
                        Uri.parse('$_baseUrl/parcours/${parcours['id']}/nommer-admin/'),
                        headers: {
                          'Authorization': 'Token $token2',
                          'Content-Type': 'application/json',
                        },
                        body: jsonEncode({'enseignant_admin_id': selected}),
                      );
                      if (res.statusCode == 200) {
                        _showSuccess('Enseignant administrateur mis à jour !');
                        _charger();
                      } else {
                        final err = jsonDecode(res.body);
                        _showError(err['detail'] ?? 'Erreur ${res.statusCode}');
                      }
                    } catch (_) {
                      _showError('Erreur réseau');
                    }
                  },
                  child: const Text('Confirmer',
                      style: TextStyle(color: _white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgLight,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildSliverHeader(),
          _buildSliverTabBar(),
        ],
        body: _loading
            ? const Center(child: CircularProgressIndicator(color: brandPrimary))
            : TabBarView(
                controller: _tabCtrl,
                children: [_tabParcours(), _tabDepartements(), _tabGlobal()],
              ),
      ),
      floatingActionButton: _buildPremiumFAB(),
    );
  }

  Widget _buildSliverHeader() {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      stretch: true,
      backgroundColor: brandPrimary,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground, StretchMode.fadeTitle],
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [brandPrimary, brandPrimary.withOpacity(0.85)],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: brandGold.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text("ADMINISTRATION",
                        style: TextStyle(color: brandGold, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _nomEnseignant.isEmpty ? 'Admin Général' : _nomEnseignant,
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: _white, letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildBadge('Admin Général', _white.withOpacity(0.15)),
                      const SizedBox(width: 8),
                      _buildBadge('Vue complète', brandGold.withOpacity(0.3)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      _buildMiniStat('${_stats['nb_parcours'] ?? 0}', 'Parcours'),
                      const SizedBox(width: 24),
                      _buildMiniStat('${_stats['nb_departements'] ?? 0}', 'Départements'),
                      const SizedBox(width: 24),
                      _buildMiniStat('${_stats['nb_apprenants'] ?? 0}', 'Apprenants'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: _white),
          onPressed: _charger,
        ),
      ],
    );
  }

  Widget _buildSliverTabBar() {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _StickyTabBarDelegate(
        TabBar(
          controller: _tabCtrl,
          labelColor: brandPrimary,
          unselectedLabelColor: textSub,
          indicatorColor: brandPrimary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: 'Parcours'),
            Tab(text: 'Départements'),
            Tab(text: 'Vue globale'),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumFAB() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: FloatingActionButton(
        onPressed: _creerParcours,
        backgroundColor: brandPrimary,
        elevation: 4,
        child: const Icon(Icons.add_rounded, color: _white, size: 28),
      ),
    );
  }

  Widget _buildBadge(String text, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: const TextStyle(color: _white, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildMiniStat(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            style: const TextStyle(color: _white, fontSize: 22, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }

  // ─── TAB 1 : Parcours ────────────────────────────────────────────
  Widget _tabParcours() {
    if (_parcours.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: brandPrimary.withOpacity(0.08),
                shape: BoxShape.circle,
                border: Border.all(color: brandPrimary.withOpacity(0.2), width: 1),
              ),
              child: Icon(Icons.route_outlined, size: 48, color: brandPrimary),
            ),
            const SizedBox(height: 16),
            const Text('Aucun parcours créé', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textMain)),
            const SizedBox(height: 8),
            const Text('Commencez par créer votre premier parcours', style: TextStyle(fontSize: 13, color: textSub)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _charger,
      color: brandPrimary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _parcours.length,
        itemBuilder: (_, i) => _buildParcoursCard(_parcours[i]),
      ),
    );
  }

  Widget _buildParcoursCard(Map p) {
    final nbDepts = p['nb_departements'] ?? 0;
    final nbApp = p['nb_apprenants'] ?? 0;
    final admin = p['enseignant_admin'];
    final taux = (p['taux_moyen'] as num? ?? 0).toDouble();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderLight, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: brandPrimary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: brandPrimary.withOpacity(0.2), width: 0.8),
                  ),
                  child: const Icon(Icons.route, color: brandPrimary, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p['nom'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textMain)),
                      const SizedBox(height: 4),
                      Text('$nbDepts départements · $nbApp apprenants',
                          style: const TextStyle(fontSize: 12, color: textSub)),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    admin == null ? Icons.person_add_outlined : Icons.swap_horiz,
                    color: brandPrimary,
                  ),
                  tooltip: admin == null ? 'Nommer un admin' : 'Changer l\'admin',
                  onPressed: () => _changerAdmin(p),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (admin != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: brandPrimary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: brandPrimary.withOpacity(0.15), width: 0.8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.admin_panel_settings, size: 14, color: brandPrimary),
                    const SizedBox(width: 8),
                    Text(
                      'Admin : ${admin['nom'] ?? admin['username'] ?? ''}',
                      style: const TextStyle(fontSize: 12, color: brandPrimary, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _orange.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _orange.withOpacity(0.2), width: 0.8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.warning_outlined, size: 14, color: _orange),
                    SizedBox(width: 8),
                    Text('Aucun administrateur nommé',
                        style: TextStyle(fontSize: 12, color: _orange, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: taux / 100,
                      backgroundColor: _borderLight,
                      color: brandPrimary,
                      minHeight: 6,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text('${taux.toStringAsFixed(0)}%',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: brandPrimary)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── TAB 2 : Départements ────────────────────────────────────────
  Widget _tabDepartements() {
    if (_departements.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: brandPrimary.withOpacity(0.08),
                shape: BoxShape.circle,
                border: Border.all(color: brandPrimary.withOpacity(0.2), width: 1),
              ),
              child: Icon(Icons.domain_outlined, size: 48, color: brandPrimary),
            ),
            const SizedBox(height: 16),
            const Text('Aucun département', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textMain)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _charger,
      color: brandPrimary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _departements.length,
        itemBuilder: (_, i) {
          final d = _departements[i];
          final taux = (d['taux_moyen'] as num? ?? 0).toDouble();
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _borderLight, width: 1),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: brandPrimary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: brandPrimary.withOpacity(0.2), width: 0.8),
                  ),
                  child: const Icon(Icons.domain, color: brandPrimary, size: 18),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(d['nom'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textMain)),
                      Text(
                        '${d['nb_cours'] ?? 0} cours · ${d['nb_apprenants'] ?? 0} apprenants',
                        style: const TextStyle(fontSize: 12, color: textSub),
                      ),
                    ],
                  ),
                ),
                Text('${taux.toStringAsFixed(0)}%',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: brandPrimary, fontSize: 16)),
              ],
            ),
          );
        },
      ),
    );
  }

  // ─── TAB 3 : Vue globale ─────────────────────────────────────────
  Widget _tabGlobal() {
    final cards = [
      _GS('Parcours', '${_stats['nb_parcours'] ?? 0}', Icons.route, brandPrimary),
      _GS('Départements', '${_stats['nb_departements'] ?? 0}', Icons.domain, const Color(0xFF1565C0)),
      _GS('Cours', '${_stats['nb_cours'] ?? 0}', Icons.book, _purple),
      _GS('Apprenants', '${_stats['nb_apprenants'] ?? 0}', Icons.people, brandGold),
      _GS('Enseignants', '${_stats['nb_enseignants'] ?? 0}', Icons.person_outline, _orange),
      _GS('Leçons', '${_stats['nb_lecons'] ?? 0}', Icons.play_lesson, const Color(0xFF008088)),
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: cards.map((c) => _buildGCard(c)).toList(),
          ),
          if (_topEnseignants.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Row(
              children: [
                Icon(Icons.emoji_events, color: brandGold, size: 20),
                SizedBox(width: 8),
                Text('Top enseignants',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textMain)),
              ],
            ),
            const SizedBox(height: 12),
            ..._topEnseignants.asMap().entries.map((e) {
              final i = e.key;
              final t = e.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: _white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _borderLight, width: 1),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: i == 0
                            ? brandGold
                            : i == 1
                                ? _borderMedium
                                : _orange,
                        shape: BoxShape.circle,
                      ),
                      child: Text('${i + 1}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: _white)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t['nom'] ?? '',
                              style: const TextStyle(fontWeight: FontWeight.w600, color: textMain)),
                          Text(t['role'] ?? '',
                              style: const TextStyle(fontSize: 11, color: textSub)),
                        ],
                      ),
                    ),
                    Text('${(t['score'] as num? ?? 0).toStringAsFixed(1)}/20',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: brandPrimary)),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildGCard(_GS item) {
    return Container(
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _borderLight, width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: item.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: item.color.withOpacity(0.2), width: 0.8),
            ),
            child: Icon(item.icon, color: item.color, size: 22),
          ),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.value,
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: item.color)),
              Text(item.label,
                  style: const TextStyle(fontSize: 12, color: textSub)),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────
  Widget _sheetHandle() => Center(
    child: Container(
      width: 40, height: 4,
      decoration: BoxDecoration(color: _borderLight, borderRadius: BorderRadius.circular(10)),
    ),
  );

  Widget _field(TextEditingController ctrl, String label, IconData icon, String hint,
      {int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: const TextStyle(color: textMain, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(color: textSub, fontSize: 13),
        labelStyle: const TextStyle(color: textSub, fontSize: 13),
        prefixIcon: Icon(icon, color: brandPrimary, size: 20),
        filled: true,
        fillColor: _bgLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _borderLight, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: brandPrimary, width: 1.5),
        ),
      ),
    );
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: _white)),
        backgroundColor: _red,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showSuccess(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: _white)),
        backgroundColor: _green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _GS {
  final String label, value;
  final IconData icon;
  final Color color;
  const _GS(this.label, this.value, this.icon, this.color);
}

class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  const _StickyTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: _white,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_StickyTabBarDelegate oldDelegate) => false;
}