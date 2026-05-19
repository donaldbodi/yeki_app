// lib/views/pages/apprenants/concours_pages.dart
// ════════════════════════════════════════════════════════════════
// PAGE PRÉPA CONCOURS — Design Premium Harmonisé
// ════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yeki/views/pages/apprenants/formations_models.dart';
import 'package:yeki/views/pages/apprenants/concours_detail_page.dart';
import 'package:yeki/widgets/yeki_app_bar.dart';

// Palette de Prestige - Harmonisation Royale
const Color brandPrimary = Color(0xFF135F74);
const Color brandGold = Color(0xFFC5A059);
const Color bgPremium = Color(0xFFF4F7F9);
const Color textMain = Color(0xFF0F172A);
const Color textSub = Color(0xFF64748B);
const Color _green = Color(0xFF10B981);
const Color _borderLight = Color(0xFFE0E4E8);

Future<String?> _getToken() async =>
    (await SharedPreferences.getInstance()).getString('token');

Map<String, String> _headers(String? t) => {
  'Content-Type': 'application/json',
  if (t != null) 'Authorization': 'Token $t',
};

// ══════════════════════════════════════════════════════════════
// PAGE LISTE — PRÉPA CONCOURS
// ══════════════════════════════════════════════════════════════
class ConcoursPage extends StatefulWidget {
  const ConcoursPage({super.key});

  @override
  State<ConcoursPage> createState() => _ConcoursPageState();
}

class _ConcoursPageState extends State<ConcoursPage>
    with SingleTickerProviderStateMixin {
  bool _loading = true;
  String _error = '';
  List<DepartementItem> _tous = [];
  List<DepartementItem> _affiches = [];
  String _filtre = 'Tous';
  String _searchQ = '';
  String _niveauApprenant = '';
  final _searchCtrl = TextEditingController();
  late AnimationController _animCtrl;

  static const _filtres = ['Tous', 'Gratuit', 'Payant', 'En cours'];

  // Données pour YekiHeader
  int _unreadNotifications = 0;
  bool _isSubscribed = true;
  String _username = 'Apprenant';

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _loadNiveau();
    _charger();
    _loadUserData();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
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
        Uri.parse('$kBaseUrl/apprenant/prepa-concours/'),
        headers: _headers(token),
      );
      if (res.statusCode == 200 && mounted) {
        final List data = jsonDecode(res.body);
        setState(() {
          _tous = data.map((d) => DepartementItem.fromJson(d as Map<String, dynamic>)).toList();
          _appliquerFiltre();
        });
        _animCtrl.forward(from: 0);
      } else if (mounted) {
        setState(() => _error = 'Erreur ${res.statusCode}');
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'Erreur réseau');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _appliquerFiltre() {
    final q = _searchQ.toLowerCase();
    setState(() {
      _affiches = _tous.where((d) {
        final matchSearch = q.isEmpty ||
            d.nom.toLowerCase().contains(q) ||
            d.nomConcours.toLowerCase().contains(q) ||
            d.niveauxCibles.toLowerCase().contains(q);

        final matchFiltre = switch (_filtre) {
          'Gratuit' => d.prix == 0,
          'Payant' => d.prix > 0,
          'En cours' => d.progression > 0 && d.progression < 100,
          _ => true,
        };

        bool matchNiveau = true;
        if (_niveauApprenant.isNotEmpty && d.niveauxCibles.isNotEmpty) {
          matchNiveau = NiveauService.estAccessible(_niveauApprenant, d.niveauxCibles);
        }

        return matchSearch && matchFiltre && matchNiveau;
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
          // Hero Section
          _buildHeroSection(),
          
          // Barre de recherche
          _buildSearchBar(),
          
          // Barre de filtres
          _buildPremiumFilterBar(),
          
          // Contenu principal
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
              child: const Text("EXCELLENCE ACADÉMIQUE", 
                style: TextStyle(color: brandGold, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
            ),
            const SizedBox(height: 10),
            const Text("Prépa Concours", 
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5)),
            const SizedBox(height: 4),
            const Text("Propulsez votre carrière vers les sommets.", 
              style: TextStyle(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: bgPremium,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _borderLight, width: 1),
        ),
        child: TextField(
          controller: _searchCtrl,
          onChanged: (v) { _searchQ = v; _appliquerFiltre(); },
          style: const TextStyle(color: textMain, fontSize: 15),
          decoration: InputDecoration(
            hintText: "Rechercher une école, un concours...",
            hintStyle: TextStyle(color: textSub.withOpacity(0.6), fontSize: 14),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Icon(Icons.search_rounded, color: brandPrimary, size: 22),
            ),
            suffixIcon: _searchQ.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () {
                      _searchCtrl.clear();
                      setState(() => _searchQ = '');
                      _appliquerFiltre();
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumFilterBar() {
    return Container(
      color: bgPremium,
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _filtres.length,
        itemBuilder: (context, i) {
          bool isSelected = _filtre == _filtres[i];
          return GestureDetector(
            onTap: () => setState(() { 
              _filtre = _filtres[i]; 
              _appliquerFiltre(); 
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? brandPrimary : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: isSelected ? brandPrimary : _borderLight),
              ),
              alignment: Alignment.center,
              child: Text(_filtres[i], style: TextStyle(
                color: isSelected ? Colors.white : textSub,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 13,
              )),
            ),
          );
        },
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
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      itemCount: _affiches.length,
      itemBuilder: (context, index) {
        final fade = CurvedAnimation(
          parent: _animCtrl, 
          curve: Interval(0.05 + (index * 0.06).clamp(0, 0.5), 1.0, curve: Curves.easeOut)
        );
        return FadeTransition(
          opacity: fade,
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(fade),
            child: _PremiumConcoursCard(
              dept: _affiches[index], 
              index: index, 
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DetailConcoursPage(
                    concoursId: _affiches[index].id,
                    deptPrecharge: _affiches[index],
                  ),
                ),
              ).then((_) => _charger()),
            ),
          ),
        );
      },
    );
  }
}

// --- COMPOSANT CARTE PREMIUM ---
class _PremiumConcoursCard extends StatelessWidget {
  final DepartementItem dept;
  final int index;
  final VoidCallback onTap;

  const _PremiumConcoursCard({
    required this.dept, 
    required this.index, 
    required this.onTap,
  });

  Color _parseColor() {
    try {
      final hex = dept.couleur.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return brandPrimary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color mainCol = _parseColor();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section avec Badge flottant
            Stack(
              children: [
                Container(
                  height: 140,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    gradient: LinearGradient(
                      colors: [mainCol, mainCol.withOpacity(0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    image: dept.imageUrl != null
                        ? DecorationImage(
                            image: NetworkImage(dept.imageUrl!),
                            fit: BoxFit.cover,
                            colorFilter: ColorFilter.mode(mainCol.withOpacity(0.4), BlendMode.darken),
                          )
                        : null,
                  ),
                  child: dept.imageUrl == null
                      ? Center(
                          child: Icon(Icons.emoji_events_rounded, size: 50, color: Colors.white.withOpacity(0.2)),
                        )
                      : null,
                ),
                Positioned(
                  top: 12, left: 12,
                  child: _GlassBadge(
                    label: dept.prix == 0 ? "GRATUIT" : "${dept.prix} FCFA", 
                    color: dept.prix == 0 ? _green : brandGold,
                  ),
                ),
                Positioned(
                  top: 12, right: 12,
                  child: _GlassBadge(
                    label: dept.statut == 'TERMINÉ' ? "TERMINÉ" : (dept.statut == 'EN COURS' ? "EN COURS" : "NOUVEAU"),
                    color: dept.statut == 'TERMINÉ' ? _green : (dept.statut == 'EN COURS' ? brandPrimary : textSub),
                  ),
                ),
                Positioned(
                  bottom: 12, left: 16, right: 60,
                  child: Text(
                    dept.nomConcours.isNotEmpty ? dept.nomConcours : dept.nom,
                    style: const TextStyle(
                      color: Colors.white, 
                      fontSize: 16, 
                      fontWeight: FontWeight.w900,
                      shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            // Contenu Info
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (dept.nom != dept.nomConcours && dept.nom.isNotEmpty)
                    Text(dept.nom, 
                      style: const TextStyle(color: textSub, fontWeight: FontWeight.w600, fontSize: 11, letterSpacing: 0.5)),
                  const SizedBox(height: 4),
                  if (dept.description.isNotEmpty)
                    Text(
                      dept.description, 
                      maxLines: 2, 
                      overflow: TextOverflow.ellipsis, 
                      style: TextStyle(color: textMain.withOpacity(0.7), height: 1.4, fontSize: 13)
                    ),
                  const SizedBox(height: 14),
                  // Stats Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _infoIcon(Icons.calendar_today_rounded, 
                        dept.dateExamen?.toString().substring(0,10) ?? "Date à définir"),
                      if (dept.placesDisponibles != null)
                        _infoIcon(Icons.people_outline_rounded, "${dept.placesDisponibles} Places"),
                      _infoIcon(Icons.menu_book_outlined, "${dept.nbCours} Modules"),
                    ],
                  ),
                  if (dept.progressionMoyenne > 0) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: dept.progressionMoyenne / 100, 
                              backgroundColor: bgPremium, 
                              valueColor: AlwaysStoppedAnimation(mainCol), 
                              minHeight: 6
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text("${dept.progressionMoyenne.toStringAsFixed(0)}%", 
                          style: TextStyle(color: mainCol, fontWeight: FontWeight.w800, fontSize: 12)),
                      ],
                    ),
                  ],
                  const SizedBox(height: 18),
                  // Action Button Premium
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: onTap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: mainCol,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: Text(
                        dept.progressionMoyenne > 0 ? "CONTINUER LA PRÉPA" : "DÉCOUVRIR LE PROGRAMME", 
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, letterSpacing: 0.5)
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoIcon(IconData icon, String text) {
    return Flexible(
      child: Row(
        children: [
          Icon(icon, size: 14, color: textSub),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text, 
              style: const TextStyle(color: textSub, fontSize: 11, fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _GlassBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          color: color.withOpacity(0.85),
          child: Text(label, 
            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
        ),
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
          Icon(Icons.emoji_events_outlined, size: 70, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('Aucun concours disponible pour votre niveau',
              style: TextStyle(color: textSub, fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text('Des concours seront disponibles quand vous aurez le niveau requis',
              style: TextStyle(color: textSub, fontSize: 12),
              textAlign: TextAlign.center),
        ],
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