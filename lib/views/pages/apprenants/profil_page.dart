import 'package:flutter/material.dart';
import 'edit_profil_page.dart';
import 'settings_page.dart';

class ProfilPage extends StatelessWidget {
  ProfilPage({super.key});

  final Color primaryColor = const Color(0xFF008080);
  final Color accentColor = Color(0xFFFF5722);
  final Color textColor = Color(0xFF03224C);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F6FF),
      body: ListView(
        children: [
          // --- Bannière + Avatar ---
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                height: 180,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/banner.jpeg'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Container(
                height: 180,
                color: Colors.black.withOpacity(0.3),
              ),
              Positioned(
                bottom: -50,
                left: 20,
                child: Stack(
                  children: [
                    const CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white,
                      child: CircleAvatar(
                        radius: 47,
                        backgroundImage: AssetImage('assets/images/user.jpg'),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        radius: 14,
                        backgroundColor: Color(0xFFFF5722),
                        child: const Icon(Icons.edit, size: 14, color: Colors.white),
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 70),
          const Center(
            child: Text("Donald Bodi",
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF03224C))),
          ),
          const Center(
              child: Text("Apprenant — Licence Informatique",
                  style: TextStyle(color: Colors.grey, fontSize: 14))),
          const SizedBox(height: 24),

          // --- Statistiques élargies ---
          _sectionTitle("Statistiques"),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _statCard("Cours", "12", Colors.orange),
                _statCard("Devoirs", "8", Colors.blue),
                _statCard("Questions", "21", Colors.green),
                _statCard("Heures", "45h", Colors.deepPurple),
                _statCard("Moyenne", "14.7", Colors.teal),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // --- Infos personnelles étendues ---
          _sectionTitle("Informations personnelles"),
          _infoCard([
            _infoRow(Icons.school, "Filière", "Informatique"),
            _infoRow(Icons.grade, "Niveau", "Licence 1"),
            _infoRow(Icons.language, "Langue", "Francophone"),
            _infoRow(Icons.menu_book, "Système", "LMD"),
            _infoRow(Icons.apartment, "Établissement", "Université de Douala"),
            _infoRow(Icons.calendar_today, "Naissance", "03/06/2002"),
            _infoRow(Icons.person, "Sexe", "Masculin"),
            _infoRow(Icons.phone, "Téléphone", "+237 690 12 34 56"),
            _infoRow(Icons.email, "Email", "donald.bodi@example.com"),
          ]),

          const SizedBox(height: 24),

          // --- Biographie ---
          _sectionTitle("Biographie"),
          _textCard(
              "Étudiant passionné d'informatique, curieux, ambitieux et rigoureux. J’aime apprendre de nouvelles technologies et contribuer à des projets innovants."),

          const SizedBox(height: 24),

          // --- Réseaux sociaux ---
          _sectionTitle("Réseaux sociaux"),
          _infoCard([
            _infoRow(Icons.facebook, "Facebook", "facebook.com/donald.bodi", link: true),
            _infoRow(Icons.business_center, "LinkedIn", "linkedin.com/in/donaldbodi", link: true),
            _infoRow(Icons.alternate_email, "Twitter / X", "@donald_bodi", link: true),
          ]),

          const SizedBox(height: 24),

          // --- Matières principales ---
          _sectionTitle("Matières principales"),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _subjectChip("Analyse 1"),
                _subjectChip("Algorithmique"),
                _subjectChip("Physique MPSI"),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // --- Boutons d'action ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.edit, color: Colors.white),
                    label: const Text("Modifier", style: TextStyle(color: Colors.white)),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const EditProfilePage()),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: primaryColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: Icon(Icons.settings, color: primaryColor),
                    label: Text("Paramètres", style: TextStyle(color: primaryColor)),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SettingsPage()),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // --- Composants réutilisables ---
  Widget _statCard(String label, String value, Color color) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 18, color: color)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Text(title,
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF03224C))),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, {bool link = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, color: Colors.orangeAccent, size: 20),
          const SizedBox(width: 12),
          Text("$label : ",
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 15,
                color: link ? Colors.blue : Colors.black87,
                decoration: link ? TextDecoration.underline : TextDecoration.none,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard(List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(2, 5))
          ],
        ),
        child: Column(children: children),
      ),
    );
  }

  Widget _textCard(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(2, 5))
          ],
        ),
        child: Text(text, style: const TextStyle(fontSize: 15)),
      ),
    );
  }

  Widget _subjectChip(String label) {
    return Chip(
      label: Text(label,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
      backgroundColor: Colors.white,
      elevation: 2,
      shadowColor: Colors.orangeAccent.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.orangeAccent.withOpacity(0.3)),
      ),
      avatar: const Icon(Icons.book_outlined, size: 18, color: Colors.orange),
    );
  }
}
