// lib/widgets/yeki_app_bar.dart
// ═══════════════════════════════════════════════════════════════
//  YEKI HEADER — AppBar premium dynamique (Design Light)
//  • Avatar réseau + initiales fallback
//  • Badge notifications animé
//  • Streak feu
//  • Solde portefeuille
//  • Menu contextuel profil / portefeuille / paramètres / déconnexion
// ═══════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// Palette harmonisée avec RegisterPage
const Color brandBackground = Color(0xFF135F74);
const Color actionOrange = Color(0xFFFF6B00);
const Color _hGold = Color(0xFFE2A84B);
const Color _textDark = Color(0xFF1A1C1E);
const Color _textMedium = Color(0xFF5A5C5E);

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
  Size get preferredSize => const Size.fromHeight(70);

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
        setState(() => _loadingSolde = false);
      }
    } catch (e) {
      setState(() => _loadingSolde = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70 + MediaQuery.of(context).padding.top,
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      decoration: const BoxDecoration(
        color: Color(0xFFFFFFFF),
        boxShadow: [
          BoxShadow(color: Color(0x0A000000), blurRadius: 12, offset: Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Row(
          children: [
            // ── Logo Yéki ─────────────────────────────────────
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [brandBackground, brandBackground],
              ).createShader(bounds),
              child: const Text(
                'Yéki',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const Spacer(),

            // ── Solde Portefeuille ─────────────────────────────
            GestureDetector(
              onTap: widget.onWallet ?? () {
                Navigator.pushNamed(context, '/wallet');
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: brandBackground.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: brandBackground.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.account_balance_wallet_rounded,
                        size: 14, color: _hGold),
                    const SizedBox(width: 4),
                    if (_loadingSolde)
                      const SizedBox(
                        width: 40,
                        height: 12,
                        child: LinearProgressIndicator(),
                      )
                    else
                      Text(
                        '$_solde FCFA',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: brandBackground,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 6),

            // ── Streak ──────────────────────────────────────
            _StatChip(Icons.local_fire_department_rounded, '5', actionOrange),
            const SizedBox(width: 6),

            // ── Notifications ────────────────────────────────
            _NotifIcon(
              count: widget.unreadNotifications,
              onTap: widget.onNotifications,
            ),
            const SizedBox(width: 4),

            // ── Avatar / Menu profil ─────────────────────────
            _ProfileMenu(
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

// ── Stat chip ────────────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;
  const _StatChip(this.icon, this.value, this.color);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 3),
            Text(value,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: color)),
          ],
        ),
      );
}

// ── Icône notification animée ─────────────────────────────────────
class _NotifIcon extends StatelessWidget {
  final int count;
  final VoidCallback onTap;
  const _NotifIcon({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Stack(
          children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFF4F8FC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.notifications_outlined,
                  color: _textDark, size: 20),
            ),
            if (count > 0)
              Positioned(
                top: 2, right: 2,
                child: Container(
                  width: 16, height: 16,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: Center(
                    child: Text(
                      count > 9 ? '9+' : '$count',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
}

// ── Avatar + menu popover ─────────────────────────────────────────
class _ProfileMenu extends StatelessWidget {
  final String username;
  final String? avatarUrl;
  final VoidCallback onSettings;
  final VoidCallback onWallet;
  final VoidCallback onLogout;

  const _ProfileMenu({
    required this.username,
    this.avatarUrl,
    required this.onSettings,
    required this.onWallet,
    required this.onLogout,
  });

  String get _initial =>
      username.isNotEmpty ? username[0].toUpperCase() : 'U';

  @override
  Widget build(BuildContext context) => PopupMenuButton<String>(
        offset: const Offset(0, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.white,
        elevation: 12,
        onSelected: (val) {
          if (val == 'profile') Navigator.pushNamed(context, '/profile');
          if (val == 'wallet') onWallet();
          if (val == 'settings') onSettings();
          if (val == 'logout') onLogout();
        },
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: brandBackground.withOpacity(0.2), width: 2),
          ),
          child: ClipOval(
            child: avatarUrl != null
                ? Image.network(
                    avatarUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _fallback(),
                  )
                : _fallback(),
          ),
        ),
        itemBuilder: (_) => [
          _menuItem('profile', Icons.person_outline, 'Mon profil', brandBackground),
          _menuItem('wallet', Icons.account_balance_wallet_outlined, 'Portefeuille', _hGold),
          _menuItem('settings', Icons.settings_outlined, 'Paramètres', _textMedium),
          const PopupMenuDivider(),
          _menuItem('logout', Icons.logout_rounded, 'Déconnexion', const Color(0xFFEF4444)),
        ],
      );

  Widget _fallback() => Container(
        color: brandBackground.withOpacity(0.1),
        child: Center(
          child: Text(
            _initial,
            style: const TextStyle(
              color: brandBackground,
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
        ),
      );

  PopupMenuItem<String> _menuItem(String val, IconData icon, String label, Color color) =>
      PopupMenuItem(
        value: val,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 15, color: color),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
}