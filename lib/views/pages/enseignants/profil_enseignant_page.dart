import 'package:flutter/material.dart';

class ProfilEnseignantPage extends StatelessWidget {
  const ProfilEnseignantPage({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isPrincipal = true;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F6FF),
      body: ListView(
        children: [
          // --- Bannière + avatar ---
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                height: 180,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/profile_banner.jpg'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Container(
                height: 180,
                color: Colors.black.withOpacity(0.3),
              ),
              Positioned(
                bottom: -45,
                left: 20,
                child: Stack(
                  children: [
                    const CircleAvatar(
                      radius: 48,
                      backgroundColor: Colors.white,
                      child: CircleAvatar(
                        radius: 45,
                        backgroundImage:
                            AssetImage('assets/images/avatar_user.png'),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        radius: 14,
                        backgroundColor: Colors.orange,
                        child:
                            Icon(Icons.edit, size: 14, color: Colors.white),
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 56),
          const Center(
            child: Text("Mme Carole Ndongo",
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF03224C))),
          ),
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                // ignore: dead_code
                color: isPrincipal ? Colors.red.shade100 :Colors.blue.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isPrincipal
                    ? "Enseignant Principal"
                    // ignore: dead_code
                    : "Enseignant",
                style: TextStyle(
                    // ignore: dead_code
                    color: isPrincipal ? Colors.red :Colors.blue,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // --- Statistiques ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatBox("Cours", "10", Colors.orange),
                _buildStatBox("Devoirs", "17", Colors.blue),
                _buildStatBox("Élèves", "230", Colors.green),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // --- Infos personnelles ---
          _sectionTitle("Informations"),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                _buildInfoRow(Icons.school, "Spécialité", "Mathématiques"),
                _buildInfoRow(Icons.work_outline, "Poste", "Titulaire"),
                _buildInfoRow(Icons.mail_outline, "Email",
                    "carole.ndongo@yeki.com"),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // --- Matières enseignées ---
          _sectionTitle("Matières enseignées"),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                _buildSubjectChip("Algèbre 1"),
                _buildSubjectChip("Géométrie 2"),
                _buildSubjectChip("Analyse complexe"),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // --- Cursus gérés (enseignant principal uniquement) ---
          if (isPrincipal) ...[
            _sectionTitle("Cursus supervisés"),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _buildCursusCard("Licence Mathématiques", "Francophone"),
                  _buildCursusCard("Secondaire Scientifique", "Anglophone"),
                ],
              ),
            ),
          ],

          const SizedBox(height: 32),

          // --- Boutons ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF03224C),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.edit, color: Colors.white),
                  label: const Text("Modifier",
                      style: TextStyle(color: Colors.white)),
                  onPressed: () {},
                ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF03224C)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.settings, color: Color(0xFF03224C)),
                  label: const Text("Paramètres",
                      style: TextStyle(color: Color(0xFF03224C))),
                  onPressed: () {},
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text("Ajouter un devoir",
                      style: TextStyle(color: Colors.white)),
                  onPressed: () {},
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildStatBox(String title, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 20, color: color)),
        const SizedBox(height: 4),
        Text(title, style: TextStyle(color: Colors.grey.shade700)),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.orangeAccent),
          const SizedBox(width: 12),
          Text(
            "$label : ",
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 15),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.bold,
          color: Color(0xFF03224C),
        ),
      ),
    );
  }

  Widget _buildSubjectChip(String subject) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.orange.withOpacity(0.08),
              blurRadius: 6,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.book_rounded, color: Colors.orange),
          const SizedBox(width: 12),
          Expanded(
            child: Text(subject,
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _buildCursusCard(String title, String langue) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              color: Colors.black12, blurRadius: 10, offset: Offset(2, 5))
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.account_balance, color: Colors.deepPurple),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "$title ($langue)",
              style: const TextStyle(fontSize: 15),
            ),
          )
        ],
      ),
    );
  }
}
