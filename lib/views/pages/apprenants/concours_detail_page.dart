import 'package:flutter/material.dart';

class DetailConcoursPage extends StatefulWidget {
  final String nomConcours;
  final String description;
  final String image;
  final double prix;
  final List<Map<String, String>> modules;

  const DetailConcoursPage({
    super.key,
    required this.nomConcours,
    required this.description,
    required this.prix,
    required this.modules,
    required this.image,
  });

  @override
  State<DetailConcoursPage> createState() => _DetailConcoursPageState();
}

class _DetailConcoursPageState extends State<DetailConcoursPage> {
  // Palette harmonisée avec ConcoursPage
  final Color primaryTeal = const Color(0xFF008088);
  final Color darkBlue = const Color(0xFF1A1C1E);
  final Color goldAccent = const Color(0xFFD4AF37);
  final Color scaffoldBg = const Color(0xFFF8FAFB);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldBg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // --- HEADER AVEC IMAGE ET TITRE ---
          SliverAppBar(
            expandedHeight: 340,
            pinned: true,
            stretch: true,
            backgroundColor: darkBlue,
            leading: _buildBackButton(),
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(widget.image, fit: BoxFit.cover),
                  _buildGradientOverlay(),
                  _buildHeaderContent(),
                ],
              ),
            ),
          ),

          // --- CONTENU PRINCIPAL ---
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildUrgencyBanner(),
                  const SizedBox(height: 32),
                  
                  _buildSectionHeader("À propos du concours"),
                  const SizedBox(height: 12),
                  Text(
                    widget.description,
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 15, height: 1.6),
                  ),
                  
                  const SizedBox(height: 32),
                  _buildStatisticsRow(),
                  
                  const SizedBox(height: 40),
                  _buildSectionHeader("Programme de formation"),
                  const SizedBox(height: 16),
                  
                  // Liste des modules
                  ...widget.modules.map((m) => _buildModuleTile(m)).toList(),
                  
                  const SizedBox(height: 120), // Espace pour le bouton du bas
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: _buildBottomAction(),
    );
  }

  // --- COMPOSANTS DE DESIGN ---

  Widget _buildBackButton() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: CircleAvatar(
        backgroundColor: Colors.black.withOpacity(0.3),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }

  Widget _buildGradientOverlay() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.1),
            Colors.transparent,
            darkBlue.withOpacity(0.95),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderContent() {
    return Positioned(
      bottom: 40,
      left: 24,
      right: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: goldAccent, borderRadius: BorderRadius.circular(8)),
            child: const Text("OFFRE ÉLITE 2026", 
              style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
          ),
          const SizedBox(height: 12),
          Text(widget.nomConcours, 
            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
        ],
      ),
    );
  }

  Widget _buildUrgencyBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.redAccent.withOpacity(0.1)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.timer_outlined, color: Colors.redAccent, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Temps restant", style: TextStyle(fontSize: 12, color: Colors.grey)),
                Text("12 Jours : 08 Heures", 
                  style: TextStyle(color: darkBlue, fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ),
          Text("CLÔTURE BIENTÔT", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(width: 4, height: 20, decoration: BoxDecoration(color: primaryTeal, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 12),
        Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkBlue)),
      ],
    );
  }

  Widget _buildStatisticsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _statCard(Icons.groups_outlined, "1.2k", "Inscrits"),
        _statCard(Icons.verified_outlined, "94%", "Réussite"),
        _statCard(Icons.menu_book_outlined, widget.modules.length.toString(), "Modules"),
      ],
    );
  }

  Widget _statCard(IconData icon, String value, String label) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Icon(icon, color: primaryTeal, size: 22),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: darkBlue, fontSize: 16)),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildModuleTile(dynamic module) {
    final map = module as Map<String, dynamic>;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            height: 44, width: 44,
            decoration: BoxDecoration(color: primaryTeal.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.play_arrow_rounded, color: primaryTeal),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text((map['titre'] ?? "").toString(), style: TextStyle(fontWeight: FontWeight.bold, color: darkBlue)),
                Text((map['description'] ?? "Accès premium requis").toString(), 
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              ],
            ),
          ),
          Icon(Icons.lock_outline_rounded, size: 18, color: Colors.grey.shade400),
        ],
      ),
    );
  }

  Widget _buildBottomAction() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))],
      ),
      child: Row(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Accès complet", style: TextStyle(color: Colors.grey, fontSize: 12)),
              Text("${widget.prix.toInt()} FCFA", 
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: primaryTeal)),
            ],
          ),
          const SizedBox(width: 24),
          Expanded(
            child: ElevatedButton(
              onPressed: () {}, // Vers paiement
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryTeal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: const Text("DÉBLOQUER L'ACCÈS", 
                style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
            ),
          ),
        ],
      ),
    );
  }
}