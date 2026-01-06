import 'package:flutter/material.dart';
import 'package:yeki/views/auth/login_page.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class YekiHeader extends StatelessWidget implements PreferredSizeWidget {
  final int unreadNotifications;
  final bool isSubscribed;
  final String username;
  final String userRole;
  final String? avatarUrl;
  final VoidCallback onLogout;
  final VoidCallback onSettings;
  final VoidCallback onNotifications;

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
  });

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    Future<void> handleLogout(BuildContext context) async {
  final dio = Dio();
  try {
    // Récupérer le token JWT ou token depuis SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final response = await dio.post(
      'https://yekiapp.pythonanywhere.com/api/auth/logout/',
      options: Options(
        headers: {
          "Authorization": "Token $token",
          "Accept": "application/json",
        },
      ),
    );

    if (response.statusCode == 200) {
      // Supprimer le token local
      await prefs.remove('token');

      // Rediriger vers la page de connexion
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Déconnecté avec succès")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur lors de la déconnexion")),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Erreur : $e")),
    );
  }
}
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      automaticallyImplyLeading: false,
      titleSpacing: 16,

      title: Row(
        children: [
          // ===== LOGO TEXTE =====
          RichText(
            text: const TextSpan(
              children: [
                TextSpan(
                  text: "Yéki",
                  style: TextStyle(
                    color: Color(0xFF008088),
                    fontSize: 26,
                    fontFamily: "FredokaOne",
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2, // + large
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          // ===== NOTIFICATIONS =====
          Stack(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.notifications_none_rounded,
                  color: Colors.black87,
                ),
                onPressed: onNotifications,
              ),
              if (unreadNotifications > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      unreadNotifications.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          // ===== MENU 3 POINTS =====
          PopupMenuButton<int>(
            icon: const Icon(Icons.more_vert, color: Colors.black87),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            itemBuilder: (_) => <PopupMenuEntry<int>>[
              // ===== PROFIL =====
              PopupMenuItem<int>(
                enabled: false,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundImage: avatarUrl != null
                          ? NetworkImage(avatarUrl!)
                          : const AssetImage(
                              'assets/images/avatar_default.png',
                            ) as ImageProvider,
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          username,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          userRole, // 👈 rôle remis
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const PopupMenuDivider(),

              // ===== ABONNEMENT =====
              PopupMenuItem<int>(
                value: 1,
                child: Row(
                  children: [
                    const Icon(Icons.workspace_premium, size: 18),
                    const SizedBox(width: 10),
                    Text(
                      isSubscribed
                          ? "Abonnement actif"
                          : "Aucun abonnement",
                    ),
                  ],
                ),
              ),

              // ===== PARAMÈTRES =====
              PopupMenuItem<int>(
                value: 2,
                child: Row(
                  children: const [
                    Icon(Icons.settings, size: 18),
                    SizedBox(width: 10),
                    Text("Paramètres"),
                  ],
                ),
              ),

              const PopupMenuDivider(),

              // ===== DÉCONNEXION =====
              PopupMenuItem<int>(
                value: 3,
                child: Row(
                  children: const [
                    Icon(Icons.logout, size: 18, color: Colors.red),
                    SizedBox(width: 10),
                    Text(
                      "Déconnexion",
                      style: TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              switch (value) {
                case 1:
                  break;
                case 2:
                  onSettings();
                  break;
                case 3:
                  handleLogout(context);
                  break;
              }
            },
          ),
        ],
      ),
    );
  }
}
