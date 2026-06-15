// lib/widgets/yeki_app_bar.dart
// ═══════════════════════════════════════════════════════════════
//  YEKI HEADER — Header Épuré Style Réseau Social Universel
// ═══════════════════════════════════════════════════════════════
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// Palette Graphique Spécifiée
const Color brandPrimary = Color(0xFF249DD3);    // Teal Éclatant
const Color brandAnchor = Color(0xFF2884a0);     //0xFF135F74 Bleu Profond Structurel
const Color actionOrange = Color(0xFFFF6B00);    // Gamification & Streaks
const Color textDark = Color(0xFF1E293B);        // Gris Ardoise Sombre

class YekiHeader extends StatefulWidget implements PreferredSizeWidget {
  final int unreadNotifications;
  final bool isSubscribed;
  final String username;
  final String userRole;
  final String? avatarUrl;
  final VoidCallback onLogout;
  final VoidCallback onSettings;
  final VoidCallback onNotifications;
  final VoidCallback? onWallet;

  const YekiHeader({
    super.key,
    required this.unreadNotifications,
    required this.isSubscribed,
    required this.username,
    required this.userRole,
    this.avatarUrl,
    required this.onLogout,
    required this.onSettings,
    required this.onNotifications,
    this.onWallet,
  });

  @override
  Size get preferredSize => const Size.fromHeight(65);

  @override
  State<YekiHeader> createState() => _YekiHeaderState();
}

class _YekiHeaderState extends State<YekiHeader> {
  int _solde = 0;
  bool _loadingSolde = true;

  @override
  void initState() {
    super.initState();
    _loadSolde();
  }

  Future<void> _loadSolde() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;
    try {
      final response = await http.get(
        Uri.parse('https://yeki.pythonanywhere.com/api/wallet/solde/'),
        headers: {'Authorization': 'Token $token'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _solde = data['solde'] ?? 0;
            _loadingSolde = false;
          });
        }
      } else {
        if (mounted) setState(() => _loadingSolde = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loadingSolde = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final double screenWidth = MediaQuery.of(context).size.width;
    
    // Contrainte Responsive pour alignement central sur grands écrans
    final double horizontalPadding = screenWidth > 800 ? (screenWidth - 760) / 2 : 16.0;

    return Container(
      padding: EdgeInsets.only(top: statusBarHeight, left: horizontalPadding, right: horizontalPadding),
      decoration: const BoxDecoration(
        color: Colors.transparent, // Fusion organique avec le fond
        border: Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1.0),
        ),
      ),
      child: Container(
        height: widget.preferredSize.height,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          children: [
            // ── Logo Réseau Universel ─────────────────────────
            Text(
              'Yéki',
              style: TextStyle(
                fontSize: screenWidth > 600 ? 30 : 26,
                fontWeight: FontWeight.w900,
                color: brandPrimary,
                letterSpacing: -0.8,
              ),
            ),
            const Spacer(),
            // ── Compteurs de Motivation Format Capsule ────────
            GestureDetector(
              onTap: widget.onWallet ?? () => Navigator.pushNamed(context, '/wallet'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.account_balance_wallet_rounded, size: 15, color: Color(0xFFE2A84B)),
                    const SizedBox(width: 5),
                    if (_loadingSolde)
                      const SizedBox(
                        width: 30,
                        height: 2, // Contrôle directement l'espace vertical alloué au loader
                        child: LinearProgressIndicator(
                          minHeight: 2, // Paramètre officiel pour l'épaisseur de la ligne
                          color: brandAnchor, 
                          backgroundColor: Colors.transparent,
                        ),
                      )
                    else
                      Text(
                        '$_solde F',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: textDark),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Streak Feu Instagram Modifié
            _CapsuleStat(icon: Icons.local_fire_department_rounded, value: '5', color: actionOrange),
            const SizedBox(width: 8),
            // Notifications Claires
            _NotifBell(count: widget.unreadNotifications, onTap: widget.onNotifications),
            const SizedBox(width: 10),
            // ── Profil & Menu Popover ─────────────────────────
            _HeaderProfileMenu(
              username: widget.username,
              avatarUrl: widget.avatarUrl,
              onSettings: widget.onSettings,
              onWallet: widget.onWallet ?? () => Navigator.pushNamed(context, '/wallet'),
              onLogout: widget.onLogout,
            ),
          ],
        ),
      ),
    );
  }
}

class _CapsuleStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;
  const _CapsuleStat({required this.icon, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: textDark)),
        ],
      ),
    );
  }
}

class _NotifBell extends StatelessWidget {
  final int count;
  final VoidCallback onTap;
  const _NotifBell({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(Icons.notifications_none_rounded, color: textDark, size: 22),
            if (count > 0)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: actionOrange, shape: BoxShape.circle),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _HeaderProfileMenu extends StatelessWidget {
  final String username;
  final String? avatarUrl;
  final VoidCallback onSettings;
  final VoidCallback onWallet;
  final VoidCallback onLogout;

  const _HeaderProfileMenu({
    required this.username,
    this.avatarUrl,
    required this.onSettings,
    required this.onWallet,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final String initial = username.isNotEmpty ? username[0].toUpperCase() : 'Y';
    return PopupMenuButton<String>(
      offset: const Offset(0, 45),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: Colors.white,
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.1),
      onSelected: (val) {
        if (val == 'profile') Navigator.pushNamed(context, '/profile');
        if (val == 'wallet') onWallet;
        if (val == 'settings') onSettings;
        if (val == 'logout') onLogout();
      },
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: brandPrimary.withOpacity(0.3), width: 1.5),
        ),
        child: ClipOval(
          child: avatarUrl != null && avatarUrl!.isNotEmpty
              ? Image.network(
                  avatarUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _fallback(initial),
                )
              : _fallback(initial),
        ),
      ),
      itemBuilder: (_) => [
        _menuItem('profile', Icons.person_outline_rounded, 'Mon profil', brandAnchor),
        _menuItem('wallet', Icons.account_balance_wallet_outlined, 'Portefeuille', const Color(0xFFE2A84B)),
        _menuItem('settings', Icons.settings_outlined, 'Paramètres', const Color(0xFF64748B)),
        const PopupMenuDivider(height: 1),
        _menuItem('logout', Icons.logout_rounded, 'Déconnexion', const Color(0xFFEF4444)),
      ],
    );
  }

  Widget _fallback(String initial) => Container(
        color: brandPrimary.withOpacity(0.1),
        child: Center(
          child: Text(
            initial,
            style: const TextStyle(color: brandAnchor, fontWeight: FontWeight.w900, fontSize: 13),
          ),
        ),
      );

  PopupMenuItem<String> _menuItem(String val, IconData icon, String label, Color color) => PopupMenuItem(
        value: val,
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 12),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 14)),
          ],
        ),
      );
}