// lib/widgets/yeki_app_bar.dart
// ═══════════════════════════════════════════════════════════════
//  YEKI HEADER — GLASSMORPHISM EDITION
//  AVEC BOUTON RÉPÉTITEURS INTÉGRÉ
// ═══════════════════════════════════════════════════════════════
// DÉPRÉCIÉ (P4.3) : ce fichier exporte un header d'accueil SPÉCIALISÉ
// (wallet, notifications, menu profil), pas un app bar de navigation
// générique. Le remplaçant générique (titre/retour/actions/recherche/
// rétrécissement) est lib/core/design/components/containers/yk_app_bar.dart
// (YkAppBar). Conservé actif : seul importeur, cursus_page.dart, non migré
// dans ce ticket (Phase 4 — aucun écran métier touché).

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:ui';
import 'package:yeki/core/theme/yeki_design_system.dart';
import 'package:yeki/core/constants/api_constants.dart';
import 'package:yeki/core/router/route_names.dart';

@Deprecated(
  'Remplacé par lib/core/design/components/containers/yk_app_bar.dart '
  '(YkAppBar) — voir P4.3. Ne pas utiliser dans du nouveau code ; '
  'migration écran par écran.',
)
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
  final VoidCallback? onRepetiteurs;

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
    this.onRepetiteurs,
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
        Uri.parse('${ApiConstants.baseUrl}/wallet/solde/'),
        headers: ApiHeaders.auth(token),
      );
      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body);
        setState(() {
          _solde = data['solde'] ?? 0;
          _loadingSolde = false;
        });
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
    
    final double horizontalPadding = screenWidth > 800 ? (screenWidth - 760) / 2 : 16.0;

    return Container(
      padding: EdgeInsets.only(top: statusBarHeight, left: horizontalPadding, right: horizontalPadding),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: widget.preferredSize.height,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  YekiColors.white.withValues(alpha: 0.75),
                  YekiColors.white.withValues(alpha: 0.50),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
              border: Border.all(
                color: YekiColors.white.withValues(alpha: 0.6),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // ── Logo ─────────────────────────────────────────
                Text(
                  'Yéki',
                  style: TextStyle(
                    fontSize: screenWidth > 600 ? 30 : 26,
                    fontWeight: FontWeight.w900,
                    color: YekiColors.primary,
                    letterSpacing: -0.8,
                  ),
                ),
                const Spacer(),
                
                // ── Solde ────────────────────────────────────────────
                GestureDetector(
                  onTap: widget.onWallet ?? () => context.pushNamed(AppRoute.wallet),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: YekiColors.white.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(YekiRadius.lg),
                      border: Border.all(
                        color: YekiColors.white.withValues(alpha: 0.8),
                        width: 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.account_balance_wallet_rounded, size: 15, color: YekiColors.gold),
                        const SizedBox(width: 5),
                        if (_loadingSolde)
                          const SizedBox(
                            width: 30,
                            height: 2,
                            child: LinearProgressIndicator(
                              minHeight: 2,
                              color: YekiColors.primaryDark,
                              backgroundColor: Colors.transparent,
                            ),
                          )
                        else
                          Text(
                            '$_solde F',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: YekiColors.textDark),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                
                // Notifications
                _NotifBell(count: widget.unreadNotifications, onTap: widget.onNotifications),
                const SizedBox(width: 10),
                
                // ── Profil & Menu Popover ─────────────────────────
                _HeaderProfileMenu(
                  username: widget.username,
                  avatarUrl: widget.avatarUrl,
                  onSettings: widget.onSettings,
                  onWallet: widget.onWallet ?? () => context.pushNamed(AppRoute.wallet),
                  onLogout: widget.onLogout,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}

// ─── Notifications ─────────────────────────────────────────────────
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
        decoration: BoxDecoration(
          color: YekiColors.white.withValues(alpha: 0.5),
          shape: BoxShape.circle,
          border: Border.all(
            color: YekiColors.white.withValues(alpha: 0.8),
            width: 1.0,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(Icons.notifications_none_rounded, color: YekiColors.textDark, size: 22),
            if (count > 0)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: YekiColors.accent, shape: BoxShape.circle),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Menu Profil ──────────────────────────────────────────────────
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(YekiRadius.lg)),
      color: YekiColors.white.withValues(alpha: 0.9),
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      onSelected: (val) {
        if (val == 'profile') {
          context.pushNamed(AppRoute.profile);
        } else if (val == 'wallet') {
          onWallet();
        } else if (val == 'repetiteurs') {
          context.pushNamed(AppRoute.repetiteurs);
        } else if (val == 'settings') {
          onSettings();
        } else if (val == 'logout') {
          onLogout();
        }
      },
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: YekiColors.primary.withValues(alpha: 0.3), width: 1.5),
        ),
        child: ClipOval(
          child: avatarUrl != null && avatarUrl!.isNotEmpty
              ? Image.network(
                  avatarUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _fallback(initial),
                )
              : _fallback(initial),
        ),
      ),
      itemBuilder: (_) => [
        _menuItem('profile', Icons.person_outline_rounded, 'Mon profil', YekiColors.primaryDark),
        _menuItem('wallet', Icons.account_balance_wallet_outlined, 'Portefeuille', YekiColors.gold),
        _menuItem('repetiteurs', Icons.chat_rounded, 'Répétiteurs', const Color(0xFF25D366)),
        _menuItem('settings', Icons.settings_outlined, 'Paramètres', YekiColors.textMedium),
        const PopupMenuDivider(height: 1),
        _menuItem('logout', Icons.logout_rounded, 'Déconnexion', YekiColors.error),
      ],
    );
  }

  Widget _fallback(String initial) => Container(
        color: YekiColors.primary.withValues(alpha: 0.1),
        child: Center(
          child: Text(
            initial,
            style: const TextStyle(color: YekiColors.primaryDark, fontWeight: FontWeight.w900, fontSize: 13),
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