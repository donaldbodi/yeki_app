import 'package:flutter/material.dart';

import '../../../../widgets/yeki_app_bar.dart';

class DevoirsPage extends StatefulWidget {
  const DevoirsPage({super.key});

  @override
  State<DevoirsPage> createState() => _DevoirsPageState();
}

class _DevoirsPageState extends State<DevoirsPage> {
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
      backgroundColor: const Color(0xFFF4F7FA),
      appBar: const YekiAppBar(
        title: "Yéki - Mes devoirs",
        subtitle: "Travaillez vos devoirs et rendez les attent",
        icon: Icons.menu_book_rounded,
      ),
      body: Column(
        children: [
          // Filtres
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
              ],
            ),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _buildDropdown(
                  label: "📚 Matière",
                  value: filtreMatiere,
                  items: ["Mathématiques", "Physique"],
                  onChanged: (val) => setState(() => filtreMatiere = val),
                ),
                _buildDropdown(
                  label: "📌 Statut",
                  value: filtreStatut,
                  items: ["En attente", "Corrigé"],
                  onChanged: (val) => setState(() => filtreStatut = val),
                ),
                FilterChip(
                  label: const Text("🎯 Concours"),
                  selected: filtreConcours,
                  selectedColor: const Color(0xFF008080),
                  checkmarkColor: Colors.white,
                  backgroundColor: Colors.grey[100],
                  onSelected: (v) => setState(() => filtreConcours = v),
                ),
              ],
            ),
          ),

          // Liste
          Expanded(
            child: devoirsFiltres.isEmpty
                ? const Center(child: Text("Aucun devoir trouvé."))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: devoirsFiltres.length,
                    itemBuilder: (_, index) {
                      final d = devoirsFiltres[index];
                      final now = DateTime.now();
                      final restant = d["dateLimite"].difference(now);
                      final estTermine = restant.isNegative;

                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        elevation: 3,
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    d["matiere"],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Color(0xFF03224C),
                                    ),
                                  ),
                                  Text(
                                    estTermine
                                        ? "⏰ Terminé"
                                        : "⏰ ${restant.inDays} j restants",
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: estTermine
                                          ? Colors.red
                                          : const Color(0xFF008080),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 8),

                              Text(
                                d["titre"],
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),

                              if (d["isConcours"] == true) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade50,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.emoji_events_rounded,
                                          color: Colors.orange, size: 18),
                                      const SizedBox(width: 6),
                                      Text(
                                        d["concours"] ?? "",
                                        style: const TextStyle(
                                            fontSize: 13,
                                            color: Colors.orange,
                                            fontWeight: FontWeight.w600),
                                      )
                                    ],
                                  ),
                                ),
                              ],

                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  _tag(
                                      icon: Icons.grade,
                                      text: "Niveau ${d["niveau"]}",
                                      color: Colors.teal),
                                  const SizedBox(width: 10),
                                  _tag(
                                      icon: Icons.calendar_today,
                                      text:
                                          "${d["dateLimite"].day}/${d["dateLimite"].month}/${d["dateLimite"].year}",
                                      color: Colors.grey),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: d["statut"] == "Corrigé"
                                          ? Colors.green.shade100
                                          : Colors.orange.shade100,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      d["statut"],
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: d["statut"] == "Corrigé"
                                            ? Colors.green.shade800
                                            : Colors.orange.shade800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  onPressed: () {
                                    // 👉 Aller au détail
                                  },
                                  icon: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                                  label: Text(
                                    estTermine
                                        ? "Voir les résultats"
                                        : "Faire le devoir",
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  style: TextButton.styleFrom(
                                    foregroundColor: const Color(0xFF008080),
                                  ),
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
      ),
    );
  }

  // Widget dropdown filter
  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return SizedBox(
      width: 160,
      child: DropdownButtonFormField<String>(
        value: value,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        items: items
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
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
