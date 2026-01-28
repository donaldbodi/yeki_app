import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'lecture_lecon_page.dart';

/// 🔹 Modèle Leçon (simple et suffisant)
class Lecon {
  final String id;
  final String titre;
  final String resume;
  final String videoUrl;
  final String documentUrl;

  Lecon({
    required this.id,
    required this.titre,
    required this.resume,
    required this.videoUrl,
    required this.documentUrl,
  });
}

class LeconsCoursPage extends StatefulWidget {
  final String coursId;

  const LeconsCoursPage({super.key, required this.coursId});

  @override
  State<LeconsCoursPage> createState() => _LeconsCoursPageState();
}

class _LeconsCoursPageState extends State<LeconsCoursPage> {
  bool loading = true;
  List modules = [];

  final List<Map<String, String>> enseignants = const [
    {"nom": "Mr. Talla Jean", "role": "Principal"},
    {"nom": "Mme Carole Ndongo", "role": "Assistant"},
    {"nom": "M. Jules Kamtchoum", "role": "Assistant"},
  ];

  @override
  void initState() {
    super.initState();
    fetchLecons();
  }

  Future<void> fetchLecons() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      setState(() => loading = false);
      return;
    }

    final res = await http.get(
      Uri.parse(
        'https://yekiapp.pythonanywhere.com/api/cours/${widget.coursId}/liste-modules/',
      ),
      headers: {'Authorization': 'Token $token'},
    );

    if (res.statusCode == 200) {
      setState(() {
        modules = jsonDecode(res.body);
        loading = false;
      });
    } else {
      setState(() => loading = false);
    }
  }

  Color _statutColor(String statut) {
    switch (statut) {
      case "fait":
        return Colors.green;
      case "en cours":
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator(color: Colors.teal));
    }

    if (modules.isEmpty) {
      return const Center(child: Text("Aucune leçon disponible"));
    }

    return Container(
      color: const Color(0xfffafafa),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 28),
        children: [
          const Text(
            "Sommaire du cours",
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w700,
              color: Colors.teal,
            ),
          ),
          const SizedBox(height: 24),

          /// 📘 MODULES
          ...modules.map((module) {
            final List lecons = module["lecons"] ?? [];

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  module["titre"] ?? "",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  module["description"] ?? "",
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                ),
                const SizedBox(height: 18),

                /// 📖 LEÇONS
                ...lecons.map((lecon) {
                  final color = _statutColor(lecon["statut"] ?? "");
                  debugPrint(lecon["fichier_pdf"]);
                  return InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LectureLeconPage(
                            titre: lecon["titre"] ?? "",
                            pdfUrl: lecon["fichier_pdf"] ?? "",
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        children: [
                          Container(
                            width: 3,
                            height: 44,
                            margin: const EdgeInsets.only(right: 14, top: 4),
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  lecon["titre"] ?? "",
                                  style: const TextStyle(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  lecon["resume"] ?? "",
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: Colors.grey),
                        ],
                      ),
                    ),
                  );
                }).toList(),

                const SizedBox(height: 30),
              ],
            );
          }).toList(),

          /// 👨‍🏫 ÉQUIPE ENSEIGNANTE
          const Text(
            "Équipe enseignante",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.teal,
            ),
          ),
          const SizedBox(height: 12),

          SizedBox(
            height: 135,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: enseignants.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
                final ens = enseignants[index];

                return Container(
                  width: 160,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(2, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const CircleAvatar(
                        radius: 24,
                        backgroundImage: AssetImage("assets/avatar.png"),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        ens["nom"]!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        ens["role"]!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.teal,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
