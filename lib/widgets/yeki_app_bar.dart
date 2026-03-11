import 'package:flutter/material.dart';

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
  Size get preferredSize => const Size.fromHeight(80);

  @override
  Widget build(BuildContext context) {

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,

      flexibleSpace: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
        ),
      ),

      title: Row(
        children: [

          /// LOGO
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFF2884A0), Color(0xFF6e91a1)],
            ).createShader(bounds),
            child: const Text(
              "Yéki",
              style: TextStyle(
                fontSize: 28,
                fontFamily: "FredokaOne",
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),

          const Spacer(),

          /// STREAK
          _buildStatChip(Icons.local_fire_department_rounded, "5", Colors.orange),

          const SizedBox(width: 8),

          /// NOTIFICATIONS
          _buildNotificationIcon(),

          /// MENU PROFIL
          PopupMenuButton<String>(
            offset: const Offset(0, 45),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),

            onSelected: (value) {

              if (value == "profil") {
                onSettings();
              }

              if (value == "logout") {
                onLogout();
              }
            },

            itemBuilder: (context) => [

              PopupMenuItem(
                value: "profil",
                child: Row(
                  children: const [
                    Icon(Icons.person_outline),
                    SizedBox(width: 10),
                    Text("Profil"),
                  ],
                ),
              ),

              PopupMenuItem(
                value: "logout",
                child: Row(
                  children: const [
                    Icon(Icons.logout, color: Colors.redAccent),
                    SizedBox(width: 10),
                    Text("Déconnexion"),
                  ],
                ),
              ),
            ],

            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFF2884A0), Color(0xFF235768)],
                ),
              ),

              child: CircleAvatar(
                radius: 18,
                backgroundImage: avatarUrl != null
                    ? NetworkImage(avatarUrl!)
                    : const AssetImage('assets/images/avatar_default.jpg')
                        as ImageProvider,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// CHIP STREAK
  Widget _buildStatChip(IconData icon, String text, Color color) {

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),

      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),

      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// NOTIFICATIONS
  Widget _buildNotificationIcon() {

    return Stack(
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
            right: 12,
            top: 12,
            child: Container(
              height: 10,
              width: 10,
              decoration: BoxDecoration(
                color: Colors.redAccent,
                shape: BoxShape.circle,
                border: Border.all(
                    color: Colors.white,
                    width: 2),
              ),
            ),
          ),
      ],
    );
  }
}