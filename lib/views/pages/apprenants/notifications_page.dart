import 'package:flutter/material.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final notifications = [
      {
        'titre': '📝 Nouveau devoir',
        'contenu': 'Un devoir vient d\'être publié. Consultez-le dès maintenant !'
      },
      {
        'titre': '📢 Message de l’enseignant',
        'contenu': 'Lisez le nouveau message posté dans le forum de discussion.'
      },
      {
        'titre': '📌 Rappel de correction',
        'contenu': 'Vos réponses ont été corrigées. Vérifiez votre score.'
      },
      {
        'titre': '🎓 Nouveau cours disponible',
        'contenu': 'Un nouveau module vient d\'être ajouté à votre programme.'
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Notifications",
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF03224C),
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF5F7FA), Color(0xFFEFF2F7)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final notif = notifications[index];
            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
              margin: const EdgeInsets.only(bottom: 16),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFA726).withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.notifications_active,
                      color: Colors.orange, size: 28),
                ),
                title: Text(
                  notif['titre']!,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF03224C),
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    notif['contenu']!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.4,
                    ),
                  ),
                ),
                trailing: const Icon(Icons.chevron_right_rounded,
                    color: Colors.grey, size: 28),
                onTap: () {
                  // Ajouter une action plus tard
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
