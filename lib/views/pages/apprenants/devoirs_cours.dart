import 'package:flutter/material.dart';
import 'detail_devoir_page.dart';

class DevoirsCoursPage extends StatelessWidget {
   DevoirsCoursPage({super.key});

  final List<Map<String, dynamic>> devoirs = [
    {
      "matiere": "Mathématiques",
      "titre": "Devoir 3 : Dérivées",
      "niveau": 3,
      "dateLimite": DateTime(2025, 6, 27),
      "statut": "En attente",
    },
    {
      "matiere": "Physique",
      "titre": "Devoir 1 : Cinématique",
      "niveau": 1,
      "dateLimite": DateTime(2025, 7, 23),
      "statut": "Corrigé",
    },
  ];

  String? filtreMatiere;
  String? filtreStatut;

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(
    builder: (context, setState) {
      List<Map<String, dynamic>> devoirsFiltres = devoirs.where((d) {
        final byMatiere = filtreMatiere == null || d["matiere"] == filtreMatiere;
        final byStatut = filtreStatut == null || d["statut"] == filtreStatut;
        return byMatiere && byStatut;
      }).toList();

      return Column(
        children: [
          // 🔍 Filtres
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: filtreMatiere,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: "📚 Matière",
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: ["Mathématiques", "Physique"]
                        .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                        .toList(),
                    onChanged: (value) => setState(() => filtreMatiere = value),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: filtreStatut,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: "📌 Statut",
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: ["En attente", "Corrigé"]
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (value) => setState(() => filtreStatut = value),
                  ),
                ),
              ],
            ),
          ),

          // 📋 Liste des devoirs
          Expanded(
            child: devoirsFiltres.isEmpty
                ? const Center(child: Text("Aucun devoir trouvé."))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: devoirsFiltres.length,
                    itemBuilder: (_, index) {
                      final devoir = devoirsFiltres[index];
                      final now = DateTime.now();
                      final restant = devoir["dateLimite"].difference(now);
                      final estTermine = restant.isNegative;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          border: Border.all(color: Colors.grey.shade100),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Matière + Temps restant
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    devoir["matiere"],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Color(0xFF03224C),
                                    ),
                                  ),
                                  Text(
                                    estTermine
                                        ? "⏰ Terminé il y a ${restant.inDays.abs()} j"
                                        : "⏰ ${restant.inDays} j restants",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: estTermine
                                          ? Colors.red
                                          : Colors.teal.shade700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              // Titre
                              Text(
                                devoir["titre"],
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 10),

                              // Infos complémentaires
                              Row(
                                children: [
                                  // Niveau
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.star,
                                            color: Colors.amber, size: 16),
                                        const SizedBox(width: 4),
                                        Text("Niveau ${devoir["niveau"]}"),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),

                                  // Date limite
                                  Row(
                                    children: [
                                      const Icon(Icons.calendar_today,
                                          size: 16, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(
                                        "${devoir["dateLimite"].day}/${devoir["dateLimite"].month}/${devoir["dateLimite"].year}",
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ],
                                  ),
                                  const Spacer(),

                                  // Statut
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: devoir["statut"] == "Corrigé"
                                          ? Colors.green.shade100
                                          : Colors.orange.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      devoir["statut"],
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: devoir["statut"] == "Corrigé"
                                            ? Colors.green.shade800
                                            : Colors.orange.shade800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Bouton action
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  icon: const Icon(Icons.arrow_forward_ios, size: 16),
                                  label: Text(
                                    estTermine
                                        ? "Voir les résultats"
                                        : "Faire le devoir",
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.teal,
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => DetailDevoirPage(
                                          titre: devoir["titre"],
                                          tempsFini: estTermine,
                                          devoirRemis: false,
                                          devoirCorrige:
                                              devoir["statut"] == "Corrigé",
                                          correcteur: "Mr. Mendy",
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      );
    },
  );
  }
}
