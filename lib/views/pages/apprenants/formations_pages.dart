// lib/views/pages/apprenants/formations_pages.dart
// ════════════════════════════════════════════════════════════════
// PAGE FORMATIONS — Design Premium Harmonisé
// ════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yeki/views/pages/apprenants/formations_models.dart';
import 'package:yeki/views/pages/apprenants/formation_detail_page.dart';
import 'package:yeki/widgets/yeki_app_bar.dart';

// Palette Premium Harmonisée
const Color brandPrimary = Color(0xFF135F74);
const Color brandGold = Color(0xFFC5A059);
const Color bgPremium = Color(0xFFF4F7F9);
const Color textMain = Color(0xFF0F172A);
const Color textSub = Color(0xFF64748B);
const Color _green = Color(0xFF10B981);
const Color _orange = Color(0xFFF97316);
const Color _purple = Color(0xFF8B5CF6);
const Color _borderLight = Color(0xFFE0E4E8);

Future<String?> _getToken() async =>
    (await SharedPreferences.getInstance()).getString('token');

Map<String, String> _headers(String? t) => {
  'Content-Type': 'application/json',
  if (t != null) 'Authorization': 'Token $t',
};

// ══════════════════════════════════════════════════════════════
// PAGE FORMATIONS
// ══════════════════════════════════════════════════════════════
class FormationsPage extends StatefulWidget {
  const FormationsPage({super.key});

  @override
  State<FormationsPage> createState() => _FormationsPageState();
}

class _FormationsPageState extends State<FormationsPage>
    with SingleTickerProviderStateMixin {
  bool _loading = true;
  String _error = '';
  List<DepartementItem> _tous = [];
  List<DepartementItem> _affiches = [];
  late TabController _tabCtrl;
  String _niveauApprenant = '';

  String _searchQ = '';
  String _filtreProg = 'Toutes';
  final _searchCtrl = TextEditingController();

  static const _types = ['Tout', 'Métier', 'Classique'];

  // Données pour YekiHeader
  int _unreadNotifications = 0;
  bool _isSubscribed = true;
  String _username = 'Apprenant';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _types.length, vsync: this);
    _tabCtrl.addListener(_onTabChanged);
    _loadNiveau();
    _charger();
    _loadUserData();
  }

  void _onTabChanged() {
    if (!_tabCtrl.indexIsChanging) _appliquerFiltres();
  }

  @override
  void dispose() {
    _tabCtrl.removeListener(_onTabChanged);
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;
    try {
      final response = await http.get(
        Uri.parse('$kBaseUrl/profil/me/'), 
        headers: _headers(token)
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() => _username = data['username'] ?? 'Apprenant');
      }
    } catch (_) {}
  }

  Future<void> _loadNiveau() async {
    final niveau = await NiveauService.getNiveau();
    if (niveau != null) {
      setState(() => _niveauApprenant = niveau);
    }
  }

  Future<void> _charger() async {
    setState(() { _loading = true; _error = ''; });
    final token = await _getToken();
    try {
      final res = await http.get(
        Uri.parse('$kBaseUrl/apprenant/formations/?type=all'),
        headers: _headers(token),
      );
      if (res.statusCode == 200 && mounted) {
        final List data = jsonDecode(res.body);
        setState(() {
          _tous = data.map((d) => DepartementItem.fromJson(d as Map<String, dynamic>)).toList();
          _appliquerFiltres();
        });
      } else if (mounted) {
        setState(() => _error = 'Erreur ${res.statusCode}');
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'Erreur réseau');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _appliquerFiltres() {
    final q = _searchQ.toLowerCase();
    final tab = _tabCtrl.index;

    setState(() {
      _affiches = _tous.where((d) {
        final matchType = switch (tab) {
          1 => d.estFormationMetier,
          2 => d.estFormationClassique,
          _ => true,
        };

        bool matchNiveau = true;
        if (_niveauApprenant.isNotEmpty && d.niveauxCibles.isNotEmpty) {
          matchNiveau = NiveauService.estAccessible(_niveauApprenant, d.niveauxCibles);
        }

        final matchProg = switch (_filtreProg) {
          'En cours' => d.progression > 0 && d.progression < 100,
          'Nouvelles' => d.progression == 0,
          'Terminées' => d.progression >= 100,
          _ => true,
        };

        final matchSearch = q.isEmpty ||
            d.nom.toLowerCase().contains(q) ||
            d.domaine.toLowerCase().contains(q) ||
            d.ville.toLowerCase().contains(q) ||
            d.dureeFormation.toLowerCase().contains(q);

        return matchType && matchProg && matchSearch && matchNiveau;
      }).toList();
    });
  }

  Future<void> _deconnecter() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
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
              foregroundColor: Colors.white,
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
      backgroundColor: bgPremium,
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
          _buildHeroSection(),
          _buildSearchAndFilter(),
          _buildTabs(),
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
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
              child: const Text("DÉVELOPPEMENT PROFESSIONNEL", 
                style: TextStyle(color: brandGold, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
            ),
            const SizedBox(height: 10),
            const Text("Formations", 
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5)),
            const SizedBox(height: 4),
            const Text("Développez vos compétences avec nos experts", 
              style: TextStyle(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      color: bgPremium,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _borderLight, width: 1),
              ),
              child: TextField(
                controller: _searchCtrl,
                style: const TextStyle(color: textMain, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Rechercher une formation...',
                  hintStyle: TextStyle(color: textSub.withOpacity(0.6), fontSize: 14),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Icon(Icons.search_rounded, color: brandPrimary, size: 20),
                  ),
                  suffixIcon: _searchQ.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _searchQ = '');
                            _appliquerFiltres();
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                ),
                onChanged: (v) {
                  setState(() => _searchQ = v);
                  _appliquerFiltres();
                },
              ),
            ),
          ),
          const SizedBox(width: 10),
          _FilterPopup(
            selected: _filtreProg,
            onChanged: (v) {
              setState(() => _filtreProg = v);
              _appliquerFiltres();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    final counts = [
      _tous.length,
      _tous.where((d) => d.estFormationMetier).length,
      _tous.where((d) => d.estFormationClassique).length,
    ];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TabBar(
        controller: _tabCtrl,
        labelColor: brandPrimary,
        unselectedLabelColor: textSub,
        indicatorColor: brandPrimary,
        indicatorWeight: 3,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
        tabs: List.generate(_types.length, (i) {
          return Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_types[i]),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: _tabCtrl.index == i
                        ? brandPrimary.withOpacity(0.1)
                        : _borderLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${counts[i]}',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: _tabCtrl.index == i ? brandPrimary : textSub),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: brandPrimary));
    }
    if (_error.isNotEmpty) {
      return _ErrorView(msg: _error, onRetry: _charger);
    }
    if (_affiches.isEmpty) {
      return const _EmptyView();
    }
    
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      itemCount: _affiches.length,
      itemBuilder: (ctx, i) => _FormationCard(
        dept: _affiches[i],
        onTap: () => Navigator.push(
          ctx,
          MaterialPageRoute(
            builder: (_) => FormationDetailPage(
              formationId: _affiches[i].id,
              deptPrecharge: _affiches[i],
            ),
          ),
        ).then((_) => _charger()),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// CARTE FORMATION PREMIUM
// ══════════════════════════════════════════════════════════════
class _FormationCard extends StatelessWidget {
  final DepartementItem dept;
  final VoidCallback onTap;

  const _FormationCard({required this.dept, required this.onTap});

  Color get _color {
    try {
      final hex = dept.couleur.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return dept.estFormationMetier ? _orange : brandPrimary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _color;
    final typeLabel = dept.estFormationMetier ? 'Formation Métier' : 'Formation Classique';
    final typeIcon = dept.estFormationMetier ? Icons.work_rounded : Icons.account_balance_rounded;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header avec gradient
            Stack(
              children: [
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    gradient: LinearGradient(
                      colors: [c, c.withOpacity(0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    image: dept.imageUrl != null
                        ? DecorationImage(
                            image: NetworkImage(dept.imageUrl!),
                            fit: BoxFit.cover,
                            colorFilter: ColorFilter.mode(c.withOpacity(0.4), BlendMode.darken),
                          )
                        : null,
                  ),
                  child: dept.imageUrl == null
                      ? Center(
                          child: Icon(typeIcon, size: 46, color: Colors.white.withOpacity(0.2)),
                        )
                      : null,
                ),
                Positioned(
                  top: 12, left: 12,
                  child: _GlassBadge(
                    label: typeLabel,
                    icon: typeIcon,
                    color: c,
                  ),
                ),
                Positioned(
                  top: 12, right: 12,
                  child: _StatusBadge(statut: dept.statut),
                ),
                if (dept.estCertifiante)
                  Positioned(
                    bottom: 12, right: 12,
                    child: _GoldBadge(label: "Certifiante", icon: Icons.verified_rounded),
                  ),
              ],
            ),
            // Contenu
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(dept.nom,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textMain),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  if (dept.description.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(dept.description,
                        style: TextStyle(fontSize: 12, color: textSub, height: 1.4),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ],
                  const SizedBox(height: 14),
                  // Chips d'informations
                  Wrap(
                    spacing: 8, runSpacing: 6,
                    children: [
                      if (dept.dureeFormation.isNotEmpty)
                        _PremiumChip(icon: Icons.schedule_rounded, label: dept.dureeFormation, color: brandPrimary),
                      if (dept.ville.isNotEmpty)
                        _PremiumChip(icon: Icons.location_on_rounded, label: dept.ville, color: c),
                      if (dept.modeFormation.isNotEmpty)
                        _PremiumChip(
                            icon: dept.modeFormation == 'presentiel'
                                ? Icons.location_city_rounded
                                : dept.modeFormation == 'distance'
                                    ? Icons.wifi_rounded
                                    : Icons.devices_rounded,
                            label: dept.modeFormationLabel,
                            color: _purple),
                      if (dept.domaine.isNotEmpty)
                        _PremiumChip(icon: Icons.category_rounded, label: dept.domaine, color: _orange),
                    ],
                  ),
                  if (dept.nbCours > 0) ...[
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${dept.nbCours} cours',
                            style: TextStyle(fontSize: 12, color: textSub, fontWeight: FontWeight.w500)),
                        Text('${dept.progressionMoyenne.toStringAsFixed(0)}%',
                            style: TextStyle(fontSize: 12, color: c, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: dept.progressionMoyenne / 100,
                        backgroundColor: bgPremium,
                        valueColor: AlwaysStoppedAnimation(c),
                        minHeight: 6,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: onTap,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: c,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          child: Text(
                            dept.progression > 0 ? 'Continuer' : 'Découvrir',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: dept.prix == 0 ? _green.withOpacity(0.1) : brandGold.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: dept.prix == 0 ? _green.withOpacity(0.3) : brandGold.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          dept.prix == 0 ? 'Gratuit' : '${dept.prix} F',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: dept.prix == 0 ? _green : brandGold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── COMPOSANTS PREMIUM ──
class _GlassBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const _GlassBadge({required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          color: color.withOpacity(0.85),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 10, color: Colors.white),
              const SizedBox(width: 4),
              Text(label,
                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoldBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  const _GoldBadge({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: brandGold,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: Colors.white),
          const SizedBox(width: 3),
          Text(label,
              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _PremiumChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _PremiumChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.15), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String statut;
  const _StatusBadge({required this.statut});

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (statut) {
      'TERMINÉ' => (_green, 'Terminé'),
      'EN COURS' => (brandPrimary, 'En cours'),
      _ => (textSub, 'Nouveau'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(label,
          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
    );
  }
}

class _FilterPopup extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;
  const _FilterPopup({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      initialValue: selected,
      onSelected: onChanged,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      elevation: 4,
      itemBuilder: (_) => ['Toutes', 'En cours', 'Nouvelles', 'Terminées']
          .map((s) => PopupMenuItem(
                value: s,
                child: Row(
                  children: [
                    if (s == selected) Icon(Icons.check_rounded, size: 14, color: brandPrimary),
                    if (s == selected) const SizedBox(width: 8),
                    Text(s, style: const TextStyle(fontSize: 13, color: textMain)),
                  ],
                ),
              ))
          .toList(),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _borderLight, width: 1),
        ),
        child: Icon(Icons.tune_rounded, color: brandPrimary, size: 20),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String msg;
  final VoidCallback onRetry;
  const _ErrorView({required this.msg, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off_rounded, size: 60, color: textSub),
          const SizedBox(height: 16),
          Text(msg, style: TextStyle(color: textSub)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Réessayer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: brandPrimary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.workspace_premium_outlined, size: 70, color: _borderLight),
          const SizedBox(height: 16),
          const Text('Aucune formation disponible pour votre niveau',
              style: TextStyle(color: textSub, fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text('Explorez d\'autres catégories',
              style: TextStyle(color: textSub, fontSize: 13)),
        ],
      ),
    );
  }
}