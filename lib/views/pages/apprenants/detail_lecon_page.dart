import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';

import 'package:yeki/views/pages/apprenants/lecture_lecon_page.dart';

// ─── Modèle (Inchangé) ────────────────────────────────────────────────────────
class Lecon {
  final String id;
  final String titre;
  final String duree;
  final String description;
  final bool hasPdf;
  final bool estTerminee;
  final String videoUrl;
  final int numero;

  const Lecon({
    required this.id,
    required this.titre,
    required this.duree,
    required this.description,
    this.hasPdf = false,
    this.estTerminee = false,
    this.videoUrl = '',
    required this.numero,
  });
}

// ─── Page principale ───────────────────────────────────────────────────────────
class DetailLeconPage extends StatefulWidget {
  final Lecon lecon;
  final TabController tabController;
  final List<Lecon> toutesLesLecons;

  const DetailLeconPage({
    super.key,
    required this.lecon,
    required this.tabController,
    required this.toutesLesLecons,
  });

  @override
  State<DetailLeconPage> createState() => _DetailLeconPageState();
}

class _DetailLeconPageState extends State<DetailLeconPage>
    with TickerProviderStateMixin {
  
  static const Color _mainTeal = Color(0xFF2884A0);
  static const Color _primaryDark = Color(0xFF1f5f75); 
  static const Color _bgLight = Color(0xFFF8FAFC);
  static const Color _accentOrange = Color(0xFFfb74dc);

  late Lecon _leconCourante;
  bool _isFullscreen = false;
  bool _isVideoPlaying = false;
  bool _preoccupationOpen = false;

  late AnimationController _preoccupationCtrl;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  final ScrollController _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _leconCourante = widget.lecon;

    _preoccupationCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _preoccupationCtrl.dispose();
    _pulseCtrl.dispose();
    _scrollCtrl.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  void _changerLecon(Lecon lecon) {
    setState(() {
      _leconCourante = lecon;
      _isVideoPlaying = false;
    });
    _scrollCtrl.animateTo(0, duration: const Duration(milliseconds: 500), curve: Curves.easeOut);
  }

  void _toggleFullscreen() {
    setState(() => _isFullscreen = !_isFullscreen);
    if (_isFullscreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    }
  }

  // ── LECTEUR VIDÉO FIXE ──────────────────────────────────────────────────────
  Widget _buildVideoPlayer() {
    return Container(
      height: _isFullscreen ? double.infinity : 250,
      width: double.infinity,
      color: Colors.black,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: Image.network(
              "https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=800",
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withOpacity(0.5), Colors.transparent, Colors.black.withOpacity(0.7)],
                ),
              ),
            ),
          ),
          if (!_isFullscreen)
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 15,
              child: IconButton(
                icon: const CircleAvatar(
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          GestureDetector(
            onTap: () => setState(() => _isVideoPlaying = !_isVideoPlaying),
            child: ScaleTransition(
              scale: _pulseAnim,
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: _mainTeal.withOpacity(0.9),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24, width: 2),
                ),
                child: Icon(
                  _isVideoPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 12, left: 20, right: 20,
            child: Row(
              children: [
                const Text("04:20", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                Expanded(
                  child: Container(
                    height: 4, margin: const EdgeInsets.symmetric(horizontal: 15),
                    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10)),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: 0.35,
                      child: Container(
                        decoration: BoxDecoration(
                          color: _mainTeal,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [BoxShadow(color: _mainTeal.withOpacity(0.5), blurRadius: 4)],
                        ),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: Icon(_isFullscreen ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded, color: Colors.white, size: 26),
                  onPressed: _toggleFullscreen,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isFullscreen) {
      return Scaffold(backgroundColor: Colors.black, body: _buildVideoPlayer());
    }

    return Scaffold(
      backgroundColor: _bgLight,
      body: Stack(
        children: [
          Column(
            children: [
              _buildVideoPlayer(),
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollCtrl,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(top: 24, bottom: 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // En-tête Leçon
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(color: _mainTeal.withOpacity(0.15), borderRadius: BorderRadius.circular(100)),
                              child: const Text("MODULE ACTUEL", style: TextStyle(color: _mainTeal, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                            ),
                            const SizedBox(height: 12),
                            Text(_leconCourante.titre, 
                                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: _primaryDark, height: 1.2)),
                            const SizedBox(height: 10),
                            Text(_leconCourante.description, 
                                style: TextStyle(fontSize: 15, color: _primaryDark.withOpacity(0.6), height: 1.5)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 25),
                      _buildQuickActions(),
                      const SizedBox(height: 35),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24),
                        child: Text("Programme du module", 
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _primaryDark)),
                      ),
                      const SizedBox(height: 20),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: widget.toutesLesLecons.length,
                        itemBuilder: (context, index) {
                          final item = widget.toutesLesLecons[index];
                          return _buildEnhancedLeconCard(item, item.id == _leconCourante.id);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          // Bouton Preoccupation Distrait
          Positioned(
            bottom: 30,
            right: 20,
            child: GestureDetector(
              onTap: _togglePreoccupation,
              child: Container(
                width: 50, height: 50,
                decoration: BoxDecoration(
                  color: _primaryDark.withOpacity(0.3),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white12),
                ),
                child: const Icon(Icons.help_outline_rounded, color: _primaryDark, size: 24),
              ),
            ),
          ),

          if (_preoccupationOpen) _buildPreoccupationOverlay(),
        ],
      ),
    );
  }

  // ── CARTES DE LEÇONS AMÉLIORÉES ──────────────────────────────────────────
  Widget _buildEnhancedLeconCard(Lecon lecon, bool isSelected) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white : Colors.white.withOpacity(0.4),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isSelected ? _mainTeal.withOpacity(0.3) : Colors.transparent,
          width: 1.5,
        ),
        boxShadow: isSelected ? [
          BoxShadow(
            color: _mainTeal.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ] : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _changerLecon(lecon),
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Numéro Badge
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: isSelected ? _mainTeal : _bgLight,
                    borderRadius: BorderRadius.circular(16),
                    gradient: isSelected ? LinearGradient(
                      colors: [_mainTeal, _mainTeal.withOpacity(0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ) : null,
                  ),
                  child: Center(
                    child: Text(
                      lecon.numero < 10 ? "0${lecon.numero}" : "${lecon.numero}",
                      style: TextStyle(
                        color: isSelected ? Colors.white : _mainTeal.withOpacity(0.6),
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Textes
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lecon.titre,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: isSelected ? _mainTeal : _primaryDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.access_time_rounded, size: 13, color: _primaryDark.withOpacity(0.4)),
                          const SizedBox(width: 4),
                          Text(
                            lecon.duree,
                            style: TextStyle(fontSize: 12, color: _primaryDark.withOpacity(0.4), fontWeight: FontWeight.w500),
                          ),
                          if (lecon.hasPdf) ...[
                            const SizedBox(width: 12),
                            Icon(Icons.picture_as_pdf_rounded, size: 13, color: _mainTeal.withOpacity(0.5)),
                            const SizedBox(width: 4),
                            const Text("PDF", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _mainTeal)),
                          ]
                        ],
                      ),
                    ],
                  ),
                ),

                // État / Action
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: lecon.estTerminee ? Colors.green.withOpacity(0.1) : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    lecon.estTerminee 
                      ? Icons.check_circle_rounded 
                      : (isSelected ? Icons.pause_circle_filled_rounded : Icons.play_circle_outline_rounded),
                    color: lecon.estTerminee 
                      ? Colors.green 
                      : (isSelected ? _mainTeal : _primaryDark.withOpacity(0.2)),
                    size: 26,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: _actionCard(
              "Lire le support PDF",
              Icons.menu_book_rounded,
              _mainTeal,
              () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => LectureLeconPage(
                    leconId: 1,
                    coursId: 1,
                    coursTitre: 'jj',
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _actionCard("Quiz", Icons.bolt_rounded, _accentOrange, () {}),
          ),
        ],
      ),
    );
  }

  Widget _actionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 8),
            Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  void _togglePreoccupation() {
    setState(() => _preoccupationOpen = !_preoccupationOpen);
    _preoccupationOpen ? _preoccupationCtrl.forward() : _preoccupationCtrl.reverse();
  }

  Widget _buildPreoccupationOverlay() {
    return GestureDetector(
      onTap: _togglePreoccupation,
      child: Container(
        color: Colors.black45,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Center(
            child: GestureDetector(
              onTap: () {},
              child: Container(
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white, 
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("Besoin d'aide ?", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _primaryDark)),
                    const SizedBox(height: 20),
                    TextField(
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: "Décrivez votre préoccupation...",
                        fillColor: _bgLight,
                        filled: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(child: TextButton(onPressed: _togglePreoccupation, child: const Text("Fermer"))),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _togglePreoccupation,
                            style: ElevatedButton.styleFrom(backgroundColor: _mainTeal),
                            child: const Text("Envoyer", style: TextStyle(color: Colors.white)),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}