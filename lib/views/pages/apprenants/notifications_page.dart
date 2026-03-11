import 'package:flutter/material.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  // Palette Yeki
  final Color primaryColor = const Color(0xFF2884A0);
  final Color darkBlue = const Color(0xFF1A1C1E);
  final Color bgColor = const Color(0xFFF8FAFB);

  @override
  Widget build(BuildContext context) {
    // Données enrichies
    final List<Map<String, dynamic>> notifications = [
      {
        'id': 1,
        'type': 'devoir',
        'titre': 'Nouveau devoir : Mathématiques',
        'contenu': 'Le chapitre "Suites Numériques" a un nouvel exercice à rendre avant demain.',
        'temps': '12 min',
        'isRead': false,
        'icon': Icons.assignment_outlined,
        'color': Colors.orange,
      },
      {
        'id': 2,
        'type': 'message',
        'titre': 'M. Kamga (Enseignant)',
        'contenu': 'N\'oubliez pas de réviser la partie 2 du module de Physique pour le quiz de vendredi.',
        'temps': '1h',
        'isRead': false,
        'icon': Icons.forum_outlined,
        'color': primaryColor,
      },
      {
        'id': 3,
        'type': 'correction',
        'titre': 'Correction disponible',
        'contenu': 'Votre exercice d\'Anglais a été noté. Score : 16/20. Cliquez pour voir le feedback.',
        'temps': '3h',
        'isRead': true,
        'icon': Icons.fact_check_outlined,
        'color': Colors.green,
      },
      {
        'id': 4,
        'type': 'cours',
        'titre': 'Module débloqué',
        'contenu': 'Félicitations ! Vous avez accès au nouveau cours : Introduction à l\'Algorithmique.',
        'temps': 'Hier',
        'isRead': true,
        'icon': Icons.auto_stories_outlined,
        'color': Colors.purple,
      },
    ];

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text("Centre d'alertes", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
        backgroundColor: darkBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all_rounded, size: 20),
            onPressed: () {}, // Marquer tout comme lu
            tooltip: "Tout marquer comme lu",
          )
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(), // Petit bonus : une barre de filtre
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notif = notifications[index];
                return _buildNotificationCard(notif);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _filterChip("Toutes", true),
          _filterChip("Cours", false),
          _filterChip("Devoirs", false),
          _filterChip("Messages", false),
        ],
      ),
    );
  }

  Widget _filterChip(String label, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: isSelected ? primaryColor : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isSelected ? primaryColor : Colors.grey.shade300),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade600,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notif) {
    bool isRead = notif['isRead'];

    return Dismissible(
      key: Key(notif['id'].toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(20)),
        child: const Icon(Icons.delete_sweep_rounded, color: Colors.white),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: isRead ? Colors.white.withOpacity(0.7) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isRead ? Colors.transparent : primaryColor.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(isRead ? 0.01 : 0.04), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icone dynamique
                Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: notif['color'].withOpacity(0.1),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(notif['icon'], color: notif['color'], size: 24),
                    ),
                    if (!isRead)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          height: 12,
                          width: 12,
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                // Contenu
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              notif['titre'],
                              style: TextStyle(
                                fontWeight: isRead ? FontWeight.w600 : FontWeight.w800,
                                fontSize: 15,
                                color: darkBlue,
                              ),
                            ),
                          ),
                          Text(
                            notif['temps'],
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        notif['contenu'],
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: isRead ? Colors.grey.shade500 : Colors.grey.shade700,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}