// lib/views/pages/apprenants/devoirs_page.dart (version complètement dynamique et corrigée)

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yeki/widgets/yeki_app_bar.dart';
import 'package:yeki/services/offline_service.dart';
import 'package:yeki/services/sync_service.dart';
import 'composer_devoir_page.dart';
import 'resultat_devoir_page.dart';

// Palette unifiée
const Color brandPrimary = Color(0xFF135F74);
const Color brandGold = Color(0xFFC5A059);
const Color textMain = Color(0xFF0F172A);
const Color textSub = Color(0xFF64748B);
const Color borderLight = Color(0xFFE0E4E8);
const Color bgLight = Color(0xFFF8FAFC);
const Color white = Color(0xFFFFFFFF);
const Color green = Color(0xFF10B981);
const Color red = Color(0xFFEF4444);
const Color orange = Color(0xFFF97316);
const Color purple = Color(0xFF8B5CF6);

const String baseUrl = 'https://yeki.pythonanywhere.com/api';

class DevoirItem {
  final int id;
  final String titre;
  final String description;
  final String typeDevoir;
  final String matiere;
  final String niveau;
  final DateTime dateDebut;
  final DateTime dateLimite;
  final int dureeMinutes;
  final double noteSur;
  final double coefficient;
  final String? statutApprenant;
  final double? noteApprenant;
  final int tempsRestantJours;
  final bool estOuvert;
  final bool estExpire;
  final bool estPublie;
  final int nbQuestions;
  
  DevoirItem({
    required this.id,
    required this.titre,
    required this.description,
    required this.typeDevoir,
    required this.matiere,
    required this.niveau,
    required this.dateDebut,
    required this.dateLimite,
    required this.dureeMinutes,
    required this.noteSur,
    required this.coefficient,
    this.statutApprenant,
    this.noteApprenant,
    required this.tempsRestantJours,
    required this.estOuvert,
    required this.estExpire,
    required this.estPublie,
    required this.nbQuestions,
  });
  
  factory DevoirItem.fromJson(Map<String, dynamic> json) {
    return DevoirItem(
      id: json['id'] ?? 0,
      titre: json['titre'] ?? '',
      description: json['description'] ?? '',
      typeDevoir: json['type_devoir'] ?? 'cursus',
      matiere: json['matiere'] ?? '',
      niveau: json['niveau'] ?? '',
      dateDebut: DateTime.tryParse(json['date_debut'] ?? '') ?? DateTime.now(),
      dateLimite: DateTime.tryParse(json['date_limite'] ?? '') ?? DateTime.now(),
      dureeMinutes: json['duree_minutes'] ?? 60,
      noteSur: (json['note_sur'] as num?)?.toDouble() ?? 20.0,
      coefficient: (json['coefficient'] as num?)?.toDouble() ?? 1.0,
      statutApprenant: json['statut_apprenant'],
      noteApprenant: (json['note_apprenant'] as num?)?.toDouble(),
      tempsRestantJours: json['temps_restant_jours'] ?? 0,
      estOuvert: json['est_ouvert'] ?? false,
      estExpire: json['est_expire'] ?? false,
      estPublie: json['est_publie'] ?? false,
      nbQuestions: json['nb_questions'] ?? 0,
    );
  }
  
  bool get aSoumis => statutApprenant != null && statutApprenant != 'non_commence';
  bool get estCorrige => statutApprenant == 'corrige';
  bool get estEnCours => statutApprenant == 'en_cours';
  
  String get statutLabel {
    switch (statutApprenant) {
      case 'non_commence': return 'À faire';
      case 'en_cours': return 'En cours';
      case 'soumis': return 'Soumis';
      case 'corrige': return 'Corrigé';
      case 'en_retard': return 'En retard';
      default: return 'À faire';
    }
  }
  
  Color get statutColor {
    switch (statutApprenant) {
      case 'non_commence': return brandPrimary;
      case 'en_cours': return purple;
      case 'soumis': return orange;
      case 'corrige': return green;
      case 'en_retard': return red;
      default: return brandPrimary;
    }
  }
  
  Color get typeColor {
    switch (typeDevoir) {
      case 'cursus': return const Color(0xFF3B82F6);
      case 'concours': return brandGold;
      case 'formation_classique': return const Color(0xFF14B8A6);
      case 'formation_metier': return orange;
      case 'olympiade': return purple;
      default: return brandPrimary;
    }
  }
  
  String get typeLabel {
    switch (typeDevoir) {
      case 'cursus': return 'Cursus';
      case 'concours': return 'Concours';
      case 'formation_classique': return 'Formation';
      case 'formation_metier': return 'Métier';
      case 'olympiade': return 'Olympiade';
      default: return typeDevoir;
    }
  }
}

class DevoirsPage extends StatefulWidget {
  final bool estEnseignantPrincipal;
  
  const DevoirsPage({super.key, required this.estEnseignantPrincipal});

  @override
  State<DevoirsPage> createState() => _DevoirsPageState();
}

class _DevoirsPageState extends State<DevoirsPage> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  bool _loading = true;
  bool _refreshing = false;
  String _error = '';
  
  List<DevoirItem> _tous = [];
  List<DevoirItem> _affiches = [];
  
  String _typeSelectionne = 'Tous';
  String? _matiereSelectionnee;
  String? _niveauSelectionne;
  String _statutSelectionne = 'Tous';
  String _recherche = '';
  
  final TextEditingController _searchCtrl = TextEditingController();
  
  // Données pour YekiHeader
  int _unreadNotifications = 0;
  bool _isSubscribed = true;
  String _username = 'Apprenant';
  
  final List<_TypeDevoirTab> _types = [
    const _TypeDevoirTab('Tous', Icons.grid_view_rounded, brandPrimary),
    const _TypeDevoirTab('cursus', Icons.school_rounded, Color(0xFF3B82F6)),
    const _TypeDevoirTab('concours', Icons.emoji_events_rounded, brandGold),
    const _TypeDevoirTab('formation_classique', Icons.account_balance_rounded, Color(0xFF14B8A6)),
    const _TypeDevoirTab('formation_metier', Icons.work_rounded, orange),
    const _TypeDevoirTab('olympiade', Icons.military_tech_rounded, purple),
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
      ..addListener(_onTabChanged);
    
    _initOffline();
    _charger();
    _loadUserData();
    
    _searchCtrl.addListener(() {
      setState(() => _recherche = _searchCtrl.text);
      _appliquerFiltres();
    });
  }
  
  Future<void> _initOffline() async {
    await OfflineService.init();
    SyncService().startAutoSync();
  }

  void _onTabChanged() {
    if (!_tabCtrl.indexIsChanging) {
      setState(() {
        _typeSelectionne = _types[_tabCtrl.index].code;
        _appliquerFiltres();
      });
    }
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    SyncService().stopAutoSync();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;
    
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/profil/me/'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Token $token'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() => _username = data['username'] ?? 'Apprenant');
      }
    } catch (_) {}
  }

  Future<String?> _getToken() async {
    return (await SharedPreferences.getInstance()).getString('token');
  }

  Future<void> _charger({bool silent = false}) async {
    if (!silent && mounted) setState(() => _loading = true);
    
    final token = await _getToken();
    if (token == null) {
      _loadFromCache();
      if (mounted) setState(() => _loading = false);
      return;
    }
    
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/devoirs/'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Token $token'},
      );
      
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        final devoirs = data.map((d) => DevoirItem.fromJson(d as Map<String, dynamic>)).toList();
        
        setState(() {
          _tous = devoirs;
          _appliquerFiltres();
        });
        
        // Mettre en cache
        await OfflineService.cacheDevoirs('all_devoirs', data);
        OfflineService.isOnline = true;
      } else {
        _loadFromCache();
      }
    } catch (e) {
      OfflineService.isOnline = false;
      _loadFromCache();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
  
  void _loadFromCache() {
    final cached = OfflineService.getCachedDevoirs('all_devoirs');
    if (cached != null) {
      setState(() {
        _tous = cached.map((d) => DevoirItem.fromJson(d as Map<String, dynamic>)).toList();
        _appliquerFiltres();
      });
    }
  }

  void _appliquerFiltres() {
    List<DevoirItem> temp = List.from(_tous);
    
    if (_typeSelectionne != 'Tous') {
      temp = temp.where((d) => d.typeDevoir == _typeSelectionne).toList();
    }
    
    if (_matiereSelectionnee != null) {
      temp = temp.where((d) => d.matiere == _matiereSelectionnee).toList();
    }
    
    if (_niveauSelectionne != null) {
      temp = temp.where((d) => d.niveau == _niveauSelectionne).toList();
    }
    
    if (_statutSelectionne != 'Tous') {
      temp = temp.where((d) => d.statutApprenant == _statutSelectionne).toList();
    }
    
    if (_recherche.isNotEmpty) {
      temp = temp.where((d) => d.titre.toLowerCase().contains(_recherche.toLowerCase())).toList();
    }
    
    setState(() => _affiches = temp);
  }

  int get _aFaire => _tous.where((d) => d.statutApprenant == 'non_commence').length;
  int get _enRetard => _tous.where((d) => d.statutApprenant == 'en_retard').length;

  Future<void> _refresh() async {
    setState(() => _refreshing = true);
    await _charger(silent: true);
    setState(() => _refreshing = false);
  }

  Future<void> _deconnecter() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: white,
        title: const Text('Déconnexion', style: TextStyle(fontWeight: FontWeight.bold, color: textMain)),
        content: const Text('Souhaitez-vous vraiment quitter l\'application ?', style: TextStyle(color: textSub)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Annuler', style: TextStyle(color: textSub))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: white, elevation: 0),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  void _ouvrirDevoir(DevoirItem d) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ComposerDevoirPage(
          devoirId: d.id,
          titre: d.titre,
          dureeMin: d.dureeMinutes,
          noteSur: d.noteSur.toInt(),
        ),
      ),
    ).then((_) => _charger());
  }

  void _voirResultat(DevoirItem d) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ResultatDevoirPage(
          devoirId: d.id,
          titre: d.titre,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
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
          _buildStatsSection(),
          _buildTabsSection(),
          _buildFiltersSection(),
          _buildSearchBar(),
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
              child: const Text("ÉVALUATIONS", style: TextStyle(color: brandGold, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
            ),
            const SizedBox(height: 10),
            const Text("Mes Devoirs", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5)),
            const SizedBox(height: 4),
            const Text("Suivez vos progrès et réussissez vos examens", style: TextStyle(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          _buildStatCard('Total', _tous.length.toString(), Icons.assignment_rounded, brandPrimary),
          const SizedBox(width: 12),
          _buildStatCard('À faire', _aFaire.toString(), Icons.pending_rounded, const Color(0xFF3B82F6)),
          const SizedBox(width: 12),
          _buildStatCard('En retard', _enRetard.toString(), Icons.warning_rounded, red),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderLight, width: 1),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: const TextStyle(fontSize: 11, color: textSub)),
          ],
        ),
      ),
    );
  }

  Widget _buildTabsSection() {
    return Container(
      color: white,
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
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? type.color : bgLight,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: isSelected ? type.color : borderLight, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(type.icon, size: 16, color: isSelected ? white : type.color),
                    const SizedBox(width: 6),
                    Text(
                      _typeLabel(type.code),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? white : type.color,
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

  Widget _buildFiltersSection() {
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
            labelBuilder: _statutLabel,
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
                    color: red.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: red.withOpacity(0.2), width: 1),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.clear_rounded, size: 14, color: red),
                      SizedBox(width: 4),
                      Text('Effacer', style: TextStyle(fontSize: 12, color: red, fontWeight: FontWeight.w600)),
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
        color: white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderLight, width: 1),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint, style: const TextStyle(fontSize: 12, color: textSub)),
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
          color: white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderLight, width: 1),
        ),
        child: TextField(
          controller: _searchCtrl,
          style: const TextStyle(color: textMain, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Rechercher un devoir...',
            prefixIcon: Icon(Icons.search_rounded, color: brandPrimary, size: 20),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            hintStyle: const TextStyle(fontSize: 13, color: textSub),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: brandPrimary));
    }
    
    if (_error.isNotEmpty) {
      return _buildError();
    }
    
    if (_affiches.isEmpty) {
      return _buildEmpty();
    }
    
    return RefreshIndicator(
      onRefresh: _refresh,
      color: brandPrimary,
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        itemCount: _affiches.length,
        itemBuilder: (context, index) => _buildCard(_affiches[index]),
      ),
    );
  }

  Widget _buildCard(DevoirItem d) {
    final joursRestants = d.dateLimite.difference(DateTime.now()).inDays;
    final estExpire = joursRestants < 0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderLight, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(width: 5, color: d.typeColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildTypeBadge(d.typeLabel, d.typeColor),
                          _buildStatutBadge(d.statutLabel, d.statutColor),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        d.titre,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textMain),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.layers_outlined, size: 13, color: textSub),
                          const SizedBox(width: 4),
                          Text('${d.matiere} • ${d.niveau}', style: const TextStyle(color: textSub, fontSize: 12)),
                        ],
                      ),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildTimerInfo(joursRestants, estExpire),
                          _buildActionButton(d, estExpire),
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

  Widget _buildTypeBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildStatutBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800)),
    );
  }

  Widget _buildTimerInfo(int joursRestants, bool estExpire) {
    if (estExpire) {
      return const Text('Clôturé', style: TextStyle(color: textSub, fontSize: 12));
    }
    
    final color = joursRestants < 3 ? red : (joursRestants < 7 ? orange : green);
    return Row(
      children: [
        Icon(Icons.access_time_rounded, size: 13, color: color),
        const SizedBox(width: 4),
        Text('$joursRestants j', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildActionButton(DevoirItem d, bool estExpire) {
    if (d.estCorrige && d.noteApprenant != null) {
      return TextButton.icon(
        onPressed: () => _voirResultat(d),
        icon: const Icon(Icons.analytics_outlined, size: 14),
        label: Text('Note: ${d.noteApprenant!.toStringAsFixed(1)}/${d.noteSur.toStringAsFixed(0)}'),
        style: TextButton.styleFrom(foregroundColor: green, padding: const EdgeInsets.symmetric(horizontal: 8)),
      );
    }
    
    if (estExpire && !d.aSoumis) {
      return const SizedBox.shrink();
    }
    
    return ElevatedButton(
      onPressed: () => _ouvrirDevoir(d),
      style: ElevatedButton.styleFrom(
        backgroundColor: d.typeColor,
        foregroundColor: white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        minimumSize: const Size(0, 34),
      ),
      child: Text(
        d.estEnCours ? 'Continuer' : 'Commencer',
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  String _typeLabel(String code) {
    switch (code) {
      case 'Tous': return 'Tous';
      case 'cursus': return 'Cursus';
      case 'concours': return 'Concours';
      case 'formation_classique': return 'Formation';
      case 'formation_metier': return 'Métier';
      case 'olympiade': return 'Olympiade';
      default: return code;
    }
  }

  String _statutLabel(String s) {
    switch (s) {
      case 'non_commence': return 'À faire';
      case 'en_cours': return 'En cours';
      case 'soumis': return 'Soumis';
      case 'corrige': return 'Corrigé';
      case 'en_retard': return 'En retard';
      default: return s;
    }
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_turned_in_outlined, size: 70, color: borderLight),
          const SizedBox(height: 16),
          const Text('Aucun devoir', style: TextStyle(color: textSub, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text('Ajustez vos filtres pour voir plus de résultats', style: TextStyle(color: textSub, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 60, color: red),
          const SizedBox(height: 16),
          Text(_error, style: const TextStyle(color: textSub)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _charger,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Réessayer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: brandPrimary,
              foregroundColor: white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
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