// lib/views/pages/apprenants/olympiades_page.dart
// ════════════════════════════════════════════════════════════════
// PAGE OLYMPIADES — Design Premium Dynamique
// ════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yeki/widgets/yeki_app_bar.dart';
import 'package:yeki/views/pages/apprenants/classement_olympiade.dart';
import 'package:yeki/views/pages/apprenants/composer_devoir_page.dart';
import 'package:yeki/views/pages/apprenants/sheet_inscription.dart';

// Palette Premium Harmonisée
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

const String _baseO = 'https://yeki.pythonanywhere.com/api';

class _OlympiadeItem {
  final int id, devoirId, dureeMinutes;
  final String titre, matiere, niveau, phase;
  final String reglement, prixDescription, statutApprenant;
  final DateTime datFinInscription, datDebutCompetition, datFinCompetition;
  final bool estInscrit, afficherClassement;
  final double? note, noteMax;
  final int? rang;

  const _OlympiadeItem({
    required this.id,
    required this.devoirId,
    required this.titre,
    required this.matiere,
    required this.niveau,
    required this.phase,
    required this.datFinInscription,
    required this.datDebutCompetition,
    required this.datFinCompetition,
    required this.reglement,
    required this.prixDescription,
    required this.estInscrit,
    required this.statutApprenant,
    this.note,
    this.noteMax,
    this.rang,
    required this.dureeMinutes,
    required this.afficherClassement,
  });

  factory _OlympiadeItem.fromJson(Map<String, dynamic> j) {
    DateTime _d(String? s) {
      if (s == null || s.isEmpty) return DateTime.now().add(const Duration(days: 30));
      try {
        return DateTime.parse(s).toLocal();
      } catch (_) {
        return DateTime.now();
      }
    }
    final statut = j['statut'] as String? ?? 'inscription';
    final phase = switch (statut) {
      'inscription' => 'inscription',
      'en_cours' => 'competition',
      'terminee' => 'terminee',
      _ => 'attente',
    };
    return _OlympiadeItem(
      id: j['id'] ?? 0,
      devoirId: j['devoir_id'] ?? 0,
      titre: j['titre'] ?? '',
      matiere: j['matiere'] ?? '',
      niveau: j['niveau'] ?? '',
      phase: phase,
      datFinInscription: _d(j['date_cloture_inscription']),
      datDebutCompetition: _d(j['date_debut_olympiade']),
      datFinCompetition: _d(j['date_fin_olympiade']),
      reglement: j['description'] ?? '',
      prixDescription: '${j['prix_1er'] ?? ''} / ${j['prix_2eme'] ?? ''} / ${j['prix_3eme'] ?? ''}',
      estInscrit: j['est_inscrit'] ?? false,
      statutApprenant: (j['inscription']?['statut'] as String?) ?? 'non_commence',
      note: j['inscription']?['note'] != null ? (j['inscription']['note'] as num).toDouble() : null,
      noteMax: (j['note_sur'] as num? ?? 20).toDouble(),
      rang: j['inscription']?['classement'] as int?,
      dureeMinutes: j['duree_minutes'] ?? 120,
      afficherClassement: j['statut'] == 'terminee',
    );
  }
}

// ════════════════════════════════════════════════════════════════
class OlympiadesPage extends StatefulWidget {
  const OlympiadesPage({super.key});
  @override
  State<OlympiadesPage> createState() => _OlympiadesPageState();
}

class _OlympiadesPageState extends State<OlympiadesPage>
    with SingleTickerProviderStateMixin {
  bool _loading = true;
  String _error = '';
  List<_OlympiadeItem> _tous = [];
  List<_OlympiadeItem> _affich = [];
  String _niveau = '';
  String _phaseFiltre = 'tous';
  late AnimationController _animCtrl;

  // Données pour YekiHeader
  int _unreadNotifications = 0;
  bool _isSubscribed = true;
  String _username = 'Apprenant';

  final List<(String, String, Color)> _phases = [
    ('tous', 'Toutes', brandPrimary),
    ('inscription', 'Inscriptions', _green),
    ('competition', 'En cours', _purple),
    ('terminee', 'Terminées', brandGold),
  ];

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _charger();
    _loadUserData();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;
    try {
      final response = await http.get(
        Uri.parse('$_baseO/profil/me/'),
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

  Future<void> _charger() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    final prefs = await SharedPreferences.getInstance();
    final tok = prefs.getString('token');
    final headers = {
      'Content-Type': 'application/json',
      if (tok != null) 'Authorization': 'Token $tok',
    };

    try {
      final rP = await http.get(Uri.parse('$_baseO/profil/me/'), headers: headers);
      if (rP.statusCode == 200) {
        _niveau = (jsonDecode(rP.body) as Map)['niveau']?.toString() ?? '';
      }
    } catch (_) {}

    try {
      final params = <String, String>{};
      if (_niveau.isNotEmpty) params['niveau'] = _niveau;

      final res = await http.get(
        Uri.parse('$_baseO/olympiades/pour-moi/')
            .replace(queryParameters: params.isNotEmpty ? params : null),
        headers: headers,
      );

      if (res.statusCode == 200 && mounted) {
        final data = (jsonDecode(res.body) as List)
            .map((j) => _OlympiadeItem.fromJson(j as Map<String, dynamic>))
            .toList();
        setState(() {
          _tous = data;
        });
        _appliquerFiltre();
        _animCtrl.forward(from: 0);
      } else if (mounted) {
        setState(() => _error = 'Erreur ${res.statusCode}');
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Erreur réseau: $e');
    }

    if (mounted) setState(() => _loading = false);
  }

  void _appliquerFiltre() {
    setState(() {
      _affich = _phaseFiltre == 'tous'
          ? _tous
          : _tous.where((o) => o.phase == _phaseFiltre).toList();
    });
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
          _buildHeroSection(),
          _buildFilters(),
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
            const Text("Olympiades",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: _white, letterSpacing: -0.5)),
            const SizedBox(height: 4),
            Text(
              _niveau.isNotEmpty ? "Niveau : $_niveau" : "Défiez les meilleurs",
              style: const TextStyle(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      color: _white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _phases.map((p) {
                  final sel = _phaseFiltre == p.$1;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _phaseFiltre = p.$1);
                      _appliquerFiltre();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: sel ? p.$3 : _bgLight,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: sel ? p.$3 : _borderLight, width: 1),
                      ),
                      child: Text(
                        p.$2,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: sel ? _white : p.$3,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _bgLight,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _borderLight),
            ),
            child: Text(
              '${_affich.length}',
              style: const TextStyle(fontSize: 12, color: textSub, fontWeight: FontWeight.w600),
            ),
          ),
        ],
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
    if (_affich.isEmpty) {
      return _buildEmpty();
    }

    return RefreshIndicator(
      color: brandPrimary,
      onRefresh: _charger,
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
        itemCount: _affich.length,
        itemBuilder: (_, i) => _buildCard(_affich[i], i),
      ),
    );
  }

  Widget _buildCard(_OlympiadeItem o, int index) {
    final (phaseLabel, phaseColor) = _phaseInfo(o.phase);
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm');

    final delay = (index * 0.06).clamp(0.0, 1.0);
    final anim = CurvedAnimation(
      parent: _animCtrl,
      curve: Interval(delay, 1.0, curve: Curves.easeOutCubic),
    );

    return FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(anim),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: _white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _borderLight, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec gradient
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [phaseColor, phaseColor.withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.military_tech_rounded, color: _white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            o.titre,
                            style: const TextStyle(color: _white, fontSize: 16, fontWeight: FontWeight.w800),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                o.matiere,
                                style: const TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                              if (o.niveau.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _white.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    o.niveau,
                                    style: const TextStyle(color: _white, fontSize: 10, fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    _buildPhaseBadge(phaseLabel, phaseColor),
                  ],
                ),
              ),
              // Contenu
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDateRow(Icons.how_to_reg_rounded, 'Inscriptions jusqu\'au',
                        dateFmt.format(o.datFinInscription), _green),
                    const SizedBox(height: 8),
                    _buildDateRow(Icons.play_circle_rounded, 'Début',
                        dateFmt.format(o.datDebutCompetition), brandPrimary),
                    const SizedBox(height: 8),
                    _buildDateRow(Icons.stop_circle_rounded, 'Fin',
                        dateFmt.format(o.datFinCompetition), _red),
                    // Résultat
                    if (o.note != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: brandGold.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: brandGold.withOpacity(0.2), width: 1),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.emoji_events_rounded, color: brandGold, size: 20),
                            const SizedBox(width: 10),
                            Text(
                              'Note : ${o.note!.toStringAsFixed(1)}/${o.noteMax?.toStringAsFixed(0)}',
                              style: const TextStyle(fontWeight: FontWeight.w800, color: textMain, fontSize: 15),
                            ),
                            if (o.rang != null) ...[
                              const Spacer(),
                              Text(
                                'Rang #${o.rang}',
                                style: const TextStyle(fontWeight: FontWeight.w700, color: brandGold),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    _buildActions(o),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActions(_OlympiadeItem o) {
    if (o.phase == 'terminee' && o.afficherClassement) {
      return SizedBox(
        width: double.infinity,
        child: _buildButton(
          label: 'Voir le classement',
          icon: Icons.leaderboard_rounded,
          color: brandGold,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ClassementOlympiadePage(olympiadeId: o.id, titre: o.titre),
            ),
          ),
        ),
      );
    }
    if (o.phase == 'competition' && o.estInscrit) {
      return SizedBox(
        width: double.infinity,
        child: _buildButton(
          label: 'Commencer la compétition',
          icon: Icons.play_arrow_rounded,
          color: _purple,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ComposerDevoirPage(
                devoirId: o.devoirId,
                titre: o.titre,
                dureeMin: o.dureeMinutes,
                noteSur: (o.noteMax ?? 20).toInt(),
              ),
            ),
          ),
        ),
      );
    }
    if (o.phase == 'inscription' && !o.estInscrit) {
      return SizedBox(
        width: double.infinity,
        child: _buildButton(
          label: "S'inscrire",
          icon: Icons.how_to_reg_rounded,
          color: _green,
          onTap: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => InscriptionSheet(olympiadeId: o.id, titre: o.titre, onSuccess: _charger),
          ),
        ),
      );
    }
    if (o.phase == 'inscription' && o.estInscrit) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _green.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _green.withOpacity(0.2), width: 1),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_rounded, color: _green, size: 16),
            SizedBox(width: 8),
            Text(
              'Inscrit — En attente du début',
              style: TextStyle(color: _green, fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [color, color.withOpacity(0.8)]),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: _white, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(color: _white, fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 12, color: color),
        ),
        const SizedBox(width: 8),
        Text('$label : ', style: const TextStyle(fontSize: 12, color: textSub)),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textMain),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildPhaseBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _white.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: _white),
      ),
    );
  }

  (String, Color) _phaseInfo(String phase) => switch (phase) {
    'inscription' => ('Inscriptions', _green),
    'competition' => ('En cours', _purple),
    'terminee' => ('Terminée', brandGold),
    _ => ('En attente', Colors.grey),
  };

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: brandGold.withOpacity(0.08),
              shape: BoxShape.circle,
              border: Border.all(color: brandGold.withOpacity(0.2), width: 1),
            ),
            child: const Icon(Icons.military_tech_outlined, size: 48, color: brandGold),
          ),
          const SizedBox(height: 16),
          const Text(
            'Aucune olympiade',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textMain),
          ),
          const SizedBox(height: 8),
          Text(
            _niveau.isNotEmpty ? 'Pas d\'olympiade pour le niveau $_niveau' : 'Revenez bientôt !',
            style: const TextStyle(fontSize: 13, color: textSub),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 56, color: _red),
          const SizedBox(height: 12),
          Text(_error, style: const TextStyle(color: textSub), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _charger,
            style: ElevatedButton.styleFrom(
              backgroundColor: brandPrimary,
              foregroundColor: _white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
}