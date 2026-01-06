import 'package:flutter/material.dart';

import '../../../../widgets/yeki_app_bar.dart';

class DevoirsPage extends StatefulWidget {
  const DevoirsPage({super.key});

  @override
  State<DevoirsPage> createState() => _DevoirsPageState();
}

class _DevoirsPageState extends State<DevoirsPage> {
  final bool isSubscribed = true;
  final List<Map<String, dynamic>> devoirs = [
    {
      "matiere": "Mathématiques",
      "titre": "Devoir 3 : Dérivées",
      "niveau": 3,
      "dateLimite": DateTime(2025, 6, 27),
      "statut": "En attente",
      "isConcours": false,
    },
    {
      "matiere": "Physique",
      "titre": "Concours ENS : Optique",
      "niveau": 1,
      "dateLimite": DateTime(2025, 7, 15),
      "statut": "Corrigé",
      "isConcours": true,
      "concours": "Concours ENS 2025",
    },
  ];

  String? filtreMatiere;
  String? filtreStatut;
  bool filtreConcours = false;

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> devoirsFiltres = devoirs.where((d) {
      final byMatiere = filtreMatiere == null || d["matiere"] == filtreMatiere;
      final byStatut = filtreStatut == null || d["statut"] == filtreStatut;
      final byConcours = !filtreConcours || d["isConcours"] == true;
      return byMatiere && byStatut && byConcours;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: YekiHeader(
  unreadNotifications: 3,
  isSubscribed: isSubscribed,
  userRole: "Apprenant",
  username: "Bodi Donald",
  avatarUrl: null, // ou URL réelle
  onNotifications: () {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Notifications")),
    );
  },
  onSettings: () {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Paramètres")),
    );
  },
  onLogout: () {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Déconnexion")),
    );
  },
),
      body: ListView(
  padding: const EdgeInsets.all(12),
  children: [

    // ================= FILTRES =================
    SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [

          _miniDropdown(
            hint: "Matière",
            value: filtreMatiere,
            items: ["Mathématiques", "Physique"],
            onChanged: (v) => setState(() => filtreMatiere = v),
          ),

          const SizedBox(width: 8),

          _miniDropdown(
            hint: "Statut",
            value: filtreStatut,
            items: ["En attente", "Corrigé"],
            onChanged: (v) => setState(() => filtreStatut = v),
          ),

          const SizedBox(width: 8),

          FilterChip(
            label: const Text("🎯 Concours", style: TextStyle(fontSize: 12)),
            selected: filtreConcours,
            onSelected: (v) => setState(() => filtreConcours = v),
            selectedColor: const Color(0xFF008080),
            backgroundColor: Colors.grey.shade200,
            labelStyle: TextStyle(
              color: filtreConcours ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),

    const SizedBox(height: 14),

    // ================= LISTE =================
    ...devoirsFiltres.map((d) {
      final now = DateTime.now();
      final restant = d["dateLimite"].difference(now);
      final estTermine = restant.isNegative;

      final Color statusColor =
          d["statut"] == "Corrigé" ? Colors.green : Colors.orange;

      return Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
          ],
        ),
        child: Row(
          children: [

            // ===== BARRE STATUT =====
            Container(
              width: 6,
              height: 140,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                ),
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // Matière + Temps
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          d["matiere"],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Color(0xFF03224C),
                          ),
                        ),
                        Text(
                          estTermine
                              ? "Terminé"
                              : "${restant.inDays} j restants",
                          style: TextStyle(
                            fontSize: 12,
                            color: estTermine ? Colors.red : Colors.teal,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    Text(
                      d["titre"],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    if (d["isConcours"]) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.emoji_events, size: 16, color: Colors.orange),
                          const SizedBox(width: 6),
                          Text(
                            d["concours"],
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: Colors.orange,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 10),

                    Row(
                      children: [
                        _tag(icon: Icons.grade, text: "Niveau ${d["niveau"]}", color: Colors.teal),
                        const SizedBox(width: 10),
                        _tag(
                          icon: Icons.calendar_today,
                          text:
                              "${d["dateLimite"].day}/${d["dateLimite"].month}/${d["dateLimite"].year}",
                          color: Colors.grey,
                        ),
                        const Spacer(),
                        Text(
                          d["statut"],
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.arrow_forward_ios, size: 14),
                        label: Text(estTermine ? "Voir résultats" : "Commencer"),
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: const Color(0xFF008080),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }),
  ],
),

    );
  }


  Widget _miniDropdown({
  required String hint,
  required String? value,
  required List<String> items,
  required void Function(String?) onChanged,
}) {
  return SizedBox(
    width: 130,
    child: DropdownButtonFormField<String>(
      value: value,
      isDense: true,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.grey.shade200,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      items: items
          .map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 12))))
          .toList(),
      onChanged: onChanged,
    ),
  );
}


  // Tag style
  Widget _tag({required IconData icon, required String text, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(fontSize: 13, color: color),
          ),
        ],
      ),
    );
  }
}
