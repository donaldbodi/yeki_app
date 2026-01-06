import 'package:flutter/material.dart';
import 'detail_lecon_page.dart';
import 'lecture_lecon_page.dart';

class LeconsCoursPage extends StatelessWidget {
  LeconsCoursPage({super.key});

  final modules = [
  {
    "titre": "Module 1 : Notions fondamentales",
    "description": "Introduction progressive aux fonctions.",
    "lecons": [
      {
        "titre": "Introduction aux fonctions",
        "statut": "fait",
        "resume": "Les bases de l'électricité en physique.",
        "videoUrl":
            "https://sample-videos.com/video123/mp4/720/big_buck_bunny_720p_1mb.mp4",
        "documentUrl": "assets/pdfs/Chap1.pdf",
      },
      {
        "titre": "Fonctions affines",
        "statut": "en cours",
        "resume": "Les bases de l'électricité en physique.",
        "videoUrl":
            "https://sample-videos.com/video123/mp4/720/big_buck_bunny_720p_1mb.mp4",
        "documentUrl": "assets/pdfs/Chap2.pdf",
      },
    ],
  },
  {
    "titre": "Module 2 : Fonctions polynomiales",
    "description": "Analyse et applications des fonctions polynomiales.",
    "lecons": [
      {
        "titre": "Fonctions polynômes",
        "statut": "à faire",
        "resume": "Les bases de l'électricité en physique.",
        "videoUrl":
            "https://sample-videos.com/video123/mp4/720/big_buck_bunny_720p_1mb.mp4",
        "documentUrl": "assets/pdfs/Chap1.pdf",
      },
    ],
  },
];
 // 👈 colle ici les modules ci-dessus

  final List<Map<String, String>> enseignants = const [
    {"nom": "Mr. Talla Jean", "role": "Principal"},
    {"nom": "Mme Carole Ndongo", "role": "Assistant"},
    {"nom": "M. Jules Kamtchoum", "role": "Assistant"},
  ];

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
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  module["titre"].toString(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  module["description"].toString(),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 18),

                /// 📖 LEÇONS
                ...(module["lecons"] as List).map((lecon) {
                  final statut = lecon["statut"];
                  final color = _statutColor(statut);

                  final autresLecons = (module["lecons"] as List)
                      .map(
                        (map) => Lecon(
                          id: 'id',
                          titre: map["titre"],
                          resume: map["resume"],
                          videoUrl: map["videoUrl"],
                          documentUrl: map["documentUrl"],
                        ),
                      )
                      .toList();

                  return InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        /*MaterialPageRoute(
                          builder: (_) => DetailLeconPage(
                            leconActuelle: Lecon(
                              id: '5',
                              titre: lecon["titre"],
                              resume: lecon["resume"],
                              videoUrl: lecon["videoUrl"],
                              documentUrl: lecon["documentUrl"],
                            ),
                            autresLecons: autresLecons,
                          ),
                        ),*/
                        MaterialPageRoute(
                          builder: (_) => LectureLeconPage(
                            titre: lecon["titre"],
                            pdfUrl: lecon["documentUrl"],
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
                            margin:
                                const EdgeInsets.only(right: 14, top: 4),
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
                                  lecon["titre"],
                                  style: const TextStyle(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  lecon["resume"],
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
                          const Icon(
                            Icons.chevron_right,
                            color: Colors.grey,
                          ),
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
                        backgroundImage:
                            AssetImage("assets/avatar.png"),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        ens["nom"]!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis, // ✅ overflow corrigé
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        ens["role"]!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis, // ✅ overflow corrigé
                        style: TextStyle(
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
