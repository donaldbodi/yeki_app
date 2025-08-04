import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'detail_devoir_page.dart';
import 'detail_lecon_page.dart';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;

Uint8List? _imageBytes;

class CoursDetailTabs extends StatefulWidget {
  const CoursDetailTabs({super.key});

  @override
  State<CoursDetailTabs> createState() => _CoursDetailTabsState();
}

class _CoursDetailTabsState extends State<CoursDetailTabs>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  bool isRecording = false;
  bool isPlaying = false;
  String? recordedPath;

  int niveauActuel = 1;
  bool soumis = false;
  num score = 0;
  bool chronoActive = false;
  int secondes = 0;
  Duration dureeRestante = const Duration(minutes: 10); // Par défaut 10 min
  Timer? timer;
  

  final lecons = [
    {
      "titre": "Introduction aux fonctions",
      "statut": "fait",
      'resume': "Les bases de l'électricité en physique.",
      'videoUrl': "https://sample-videos.com/video123/mp4/720/big_buck_bunny_720p_1mb.mp4",
      'documentUrl': "assets/pdfs/Chap1.docx",
    },
    {
      "titre": "Fonctions affines",
      "statut": "en cours",
      'resume': "Les bases de l'électricité en physique.",
      'videoUrl': "https://sample-videos.com/video123/mp4/720/big_buck_bunny_720p_1mb.mp4",
      'documentUrl': "assets/pdfs/Chap2.docx",
    },
    {
      "titre": "Fonctions polynômes",
      "statut": "à faire",
      'resume': "Les bases de l'électricité en physique.",
      'videoUrl': "https://sample-videos.com/video123/mp4/720/big_buck_bunny_720p_1mb.mp4",
      'documentUrl': "assets/pdfs/Chap1.docx",
    },
  ];

  final devoirs = [
    {"titre": "Devoir 1 : Fonctions", "date": "24 Juin"},
    {"titre": "Quiz : Fonctions affines", "date": "26 Juin"},
  ];

  final forum = [
    {
      "auteur": "Donald",
      "question": "Pourquoi une fonction affine est-elle linéaire ?",
      "reponse": "Car sa courbe est une droite non horizontale."
    },
    {
      "auteur": "Claire",
      "question": "Comment déterminer le signe d'une fonction ?",
      "reponse": "En utilisant un tableau de signes."
    },
  ];

  final enseignants = [
    {
      "nom": "Mr. Talla Jean",
      "role": "principal",
      "image": "assets/images/user.jpg"
    },
    {
      "nom": "Mme Carole Ndongo",
      "role": "assistant",
      "image": "assets/images/user.jpg"
    },
    {
      "nom": "M. Jules Kamtchoum",
      "role": "assistant",
      "image": "assets/images/user.jpg"
    },
  ];

  //juste pour le test
  Future<Uint8List> loadAssetImage(String path) async {
    final data = await rootBundle.load(path);
    return data.buffer.asUint8List();
  }

  @override
  void initState() {
    super.initState();
    // Ajout de messages d'exemple
    Future<void> _loadInitialMessages() async {
      final bytes = await loadAssetImage('assets/images/image1.jpeg');

      setState(() {
        _messages.addAll([
          {
            'text': "Bonjour à tous, bienvenue dans ce cours.",
            'image': null,
            'audio': null,
            'sender': 'Mme Essomba',
            'role': 'enseignant',
            'isOnline': true,
            'timestamp': DateTime.now().subtract(const Duration(minutes: 5)),
          },
          {
            'text': "Merci madame, on commence par quel chapitre ?",
            'image': null,
            'audio': null,
            'sender': 'Samuel',
            'role': 'élève',
            'isOnline': true,
            'timestamp': DateTime.now().subtract(const Duration(minutes: 4)),
          },
          {
            'text': "Voici le schéma du premier exercice.",
            'image': bytes, // Remplace par un chemin valide
            'audio': null,
            'sender': 'Samuel',
            'role': 'élève',
            'isOnline': true,
            'timestamp': DateTime.now().subtract(const Duration(minutes: 3)),
          },
          {
            'text': "",
            'image': null,
            'audio':
                'assets/audio/exemple.aac', // Remplace par un chemin valide
            'sender': 'Mme Essomba',
            'role': 'enseignant',
            'isOnline': true,
            'timestamp': DateTime.now().subtract(const Duration(minutes: 2)),
          },
        ]);
      });
    }

    _recorder.openRecorder();
    _player.openPlayer();
    _tabController = TabController(length: 4, vsync: this);
    _loadInitialMessages();
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    _player.closePlayer();
    super.dispose();
  }

  Future<void> _pickImage() async {
  final picker = ImagePicker();
  final pickedFile = await picker.pickImage(source: ImageSource.gallery);
  if (pickedFile != null) {
    final bytes = await pickedFile.readAsBytes();
    setState(() {
      _imageBytes = bytes;
    });
    _sendMessage(); // si tu veux envoyer automatiquement après sélection
  }
}


  Future<void> _toggleRecording() async {
    if (!isRecording) {
      await Permission.microphone.request();
      if (await Permission.microphone.isGranted) {
        final dir = await getApplicationDocumentsDirectory();
        final path =
            '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.aac';
        await _recorder.startRecorder(toFile: path);
        setState(() {
          isRecording = true;
          recordedPath = path;
        });
      }
    } else {
      final path = await _recorder.stopRecorder();
      setState(() {
        isRecording = false;
        recordedPath = path;
      });
    }
  }

  Future<void> _playAudio(String path) async {
    if (isPlaying) {
      await _player.stopPlayer();
    } else {
      await _player.startPlayer(
        fromURI: path,
        whenFinished: () => setState(() => isPlaying = false),
      );
    }
    setState(() {
      isPlaying = !isPlaying;
    });
  }

  void _sendMessage() {
    if (_messageController.text.trim().isNotEmpty ||
        _imageBytes  != null ||
        recordedPath != null) {
      setState(() {
        _messages.add({
          'text': _messageController.text.trim(),
          'image': _imageBytes ,
          'audio': recordedPath,
          'sender': 'M. Bodi',
          'role': 'enseignant', // ou 'élève'
          'isOnline': true,
          'timestamp': DateTime.now(),
        });
        _messageController.clear();
        _imageBytes  = null;
        recordedPath = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Détail du cours",
            style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xff008080),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.orangeAccent,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.orangeAccent,
          tabs: const [
            Tab(icon: Icon(Icons.menu_book_rounded), text: "Leçons"),
            Tab(icon: Icon(Icons.school), text: "Exercices"),
            Tab(icon: Icon(Icons.assignment), text: "Devoirs"),
            Tab(icon: Icon(Icons.forum), text: "Forum"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLecons(),
          _buildExercices(),
          _buildDevoirs(),
          _buildForum(),
        ],
      ),
    );
  }

  Widget _buildEquipeEnseignanteHorizontal() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        "Équipe enseignante",
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.teal,
        ),
      ),
      const SizedBox(height: 10),
      SizedBox(
        height: 140,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: enseignants.length,
          separatorBuilder: (_, __) => const SizedBox(width: 14),
          itemBuilder: (context, index) {
            final ens = enseignants[index];
            final isPrincipal = ens["role"] == "principal";
            final badgeColor = isPrincipal ? Colors.deepOrange : Colors.teal;

            return Container(
              width: 170,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(2, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundImage: AssetImage(ens["image"] ?? "assets/avatar.png"),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ens["nom"] ?? "Nom",
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isPrincipal ? "Principal" : "Assistant",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: badgeColor,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    ],
  );
}

  Widget _buildLecons() {
  return ListView(
    padding: const EdgeInsets.all(16),
    children: [
      const Text(
        "Leçons du cours",
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.teal,
        ),
      ),
      const SizedBox(height: 12),
      ...lecons.map((lecon) {
        Color color;
        IconData icon;
        String statut = lecon["statut"] ?? "non défini";

        switch (statut) {
          case "fait":
            color = Colors.green;
            icon = Icons.check_circle_outline;
            break;
          case "en cours":
            color = Colors.orange;
            icon = Icons.timelapse;
            break;
          default:
            color = Colors.grey;
            icon = Icons.circle_outlined;
        }

        final titre = lecon["titre"] ?? "Titre inconnu";
        final description = lecon["description"] ??
            "Cette leçon vous permettra de mieux comprendre les bases du sujet abordé.";
            List<Lecon> autresLecons = lecons.map((map) => Lecon(id: 'id', titre: titre, resume: 'resume', videoUrl: 'videoUrl', documentUrl: 'documentUrl')).toList();

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DetailLeconPage(
                  leconActuelle: Lecon(
                    id: '5',
                    titre: "Fonctions affines",
                    resume: "Les bases de l'électricité en physique.",
                    videoUrl: "https://www.youtube.com/watch?v=1H47VtVQLDM&list=RD1H47VtVQLDM&start_radio=1",
                    documentUrl: "assets/pdfs/Chap2.docx",
                  ),
                  autresLecons: autresLecons,
                ),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: color.withOpacity(0.3),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(1, 4),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: color, size: 30),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titre,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          statut.toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            color: color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
      const SizedBox(height: 20),
      _buildEquipeEnseignanteHorizontal(),
    ],
  );
}


  Widget _buildExercices() {
  final niveauxDisponibles = [1, 2, 3, 4, 5];
  int niveauActuel = 1;

  final Map<String, String> reponsesDonnees = {};
  final Map<String, String> corrections = {};
  final Map<int, bool> evalExerciceFaite = {};
  bool evalGlobaleFaite = false;

  int scoreTotalGlobal = 0;
  int scoreObtenuGlobal = 0;

  final List<Map<String, dynamic>> historique = [
    {
      'niveau': 1,
      'score': "4 / 5",
      'date': DateTime.now().subtract(const Duration(days: 1)),
      'reponses': {
        "Quelle est la capitale du Cameroun ?": "Yaoundé",
        "En quelle année le Cameroun est-il devenu indépendant ?": "1961",
      }
    },
    {
      'niveau': 1,
      'score': "5 / 5",
      'date': DateTime.now().subtract(const Duration(days: 2)),
      'reponses': {
        "Quelle est la capitale du Cameroun ?": "Yaoundé",
        "En quelle année le Cameroun est-il devenu indépendant ?": "1960",
      }
    }
  ];

  final Map<int, List<Map<String, dynamic>>> exercicesParNiveau = {
    1: [
      {
        'titre': 'Introduction',
        'enonce': 'Répondez à ces questions de base.',
        'questions': [
          {
            'text': 'Quelle est la capitale du Cameroun ?',
            'type': 'qcm',
            'choix': ['Yaoundé', 'Douala', 'Bamenda'],
            'reponse': 'Yaoundé',
            'points': 2,
          },
          {
            'text': 'En quelle année le Cameroun est-il devenu indépendant ?',
            'type': 'texte',
            'reponse': '1960',
            'points': 3,
          }
        ],
      },
    ],
    2: [],
    3: [],
    4: [],
    5: [],
  };

  void _rafraichir() {
    reponsesDonnees.clear();
    corrections.clear();
    evalGlobaleFaite = false;
    evalExerciceFaite.clear();
    scoreObtenuGlobal = 0;
    scoreTotalGlobal = 0;
  }

  void _poserPreoccupation(String question) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            children: [
              Text("Préoccupation : $question",
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              TextField(
                controller: controller,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: "Votre préoccupation ici...",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text("Préoccupation envoyée"),
                    backgroundColor: Colors.teal,
                  ));
                },
                child: const Text("Envoyer"),
              ),
            ],
          ),
        );
      },
    );
  }

  void _evaluerExercice(Map exercice, int index, StateSetter setState) {
    int score = 0;
    int total = 0;

    for (var q in exercice['questions']) {
      final bonne = q['reponse'].toString().toLowerCase().trim();
      final user = reponsesDonnees[q['text']]?.toLowerCase().trim() ?? '';
      final pts = q['points'] ?? 1;

      total += (pts as num).toInt();
      if (user == bonne) score += (pts as num).toInt();

      corrections[q['text']] = bonne;
    }

    evalExerciceFaite[index] = true;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("Score Exercice ${index + 1} : $score / $total"),
      backgroundColor: Colors.teal,
    ));
  }

  void _evaluerGlobal(StateSetter setState) {
    scoreTotalGlobal = 0;
    scoreObtenuGlobal = 0;

    final exercices = exercicesParNiveau[niveauActuel] ?? [];
    for (var ex in exercices) {
      for (var q in ex['questions']) {
        final bonne = q['reponse'].toString().toLowerCase().trim();
        final user = reponsesDonnees[q['text']]?.toLowerCase().trim() ?? '';
        final pts = q['points'] ?? 1;

        scoreTotalGlobal += (pts as num).toInt();
        if (user == bonne) scoreObtenuGlobal += (pts as num).toInt();

        corrections[q['text']] = bonne;
      }
    }

    evalGlobaleFaite = true;

    historique.add({
      'niveau': niveauActuel,
      'score': "$scoreObtenuGlobal / $scoreTotalGlobal",
      'date': DateTime.now(),
      'reponses': Map<String, String>.from(reponsesDonnees),
    });

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("Résultat global : $scoreObtenuGlobal / $scoreTotalGlobal"),
      backgroundColor: Colors.deepPurple,
    ));

    setState(() {});
  }

  void _showReponsesModal(Map<String, String> reponses) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          shrinkWrap: true,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const Text("Réponses données",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Color(0xFF03224C))),
            const SizedBox(height: 14),
            if (reponses.isEmpty)
              const Text("Aucune réponse disponible",
                  style: TextStyle(fontStyle: FontStyle.italic)),
            ...reponses.entries.map((entry) => ListTile(
                  leading: const Icon(Icons.question_answer_outlined),
                  title: Text(entry.key),
                  subtitle: Text("Réponse : ${entry.value}"),
                )),
          ],
        ),
      ),
    );
  }

  void _showHistoriqueModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: historique.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (context, index) {
            final h = historique[index];
            final date = h['date'] as DateTime;
            return ListTile(
              leading: const Icon(Icons.school, color: Colors.deepPurple),
              title: Text("Niveau ${h['niveau']}"),
              subtitle: Text("Score : ${h['score']}"),
              trailing: Text(
                "${date.day.toString().padLeft(2, '0')}/"
                "${date.month.toString().padLeft(2, '0')} "
                "${date.hour.toString().padLeft(2, '0')}:"
                "${date.minute.toString().padLeft(2, '0')}",
                style: const TextStyle(fontSize: 12),
              ),
              onTap: () => _showReponsesModal(h['reponses'] ?? {}),
            );
          },
        ),
      ),
    );
  }

  return StatefulBuilder(
    builder: (context, setState) {
      return Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Text("Niveau : ",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 10),
                DropdownButton<int>(
                  value: niveauActuel,
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        niveauActuel = val;
                        _rafraichir();
                      });
                    }
                  },
                  items: niveauxDisponibles
                      .map((n) =>
                          DropdownMenuItem(value: n, child: Text("Niveau $n")))
                      .toList(),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    setState(() => _rafraichir());
                  },
                  icon: const Icon(Icons.refresh, color: Colors.teal),
                  tooltip: "Réinitialiser",
                ),
                IconButton(
                  onPressed: _showHistoriqueModal,
                  icon: const Icon(Icons.history, color: Colors.deepPurple),
                  tooltip: "Historique",
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: exercicesParNiveau[niveauActuel]?.length ?? 0,
              itemBuilder: (context, index) {
                final exercice = exercicesParNiveau[niveauActuel]![index];
                return Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Exercice ${index + 1} : ${exercice['titre']}",
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 8),
                        Text(exercice['enonce']),
                        const Divider(),
                        ...exercice['questions'].asMap().entries.map((entry) {
                          final q = entry.value;
                          final qIndex = entry.key + 1;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  "Q$qIndex (${q['points']} pts) : ${q['text']}",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              if (q['type'] == 'qcm')
                                ...q['choix'].map<Widget>((opt) {
                                  return RadioListTile(
                                    value: opt,
                                    groupValue: reponsesDonnees[q['text']],
                                    onChanged: (val) {
                                      setState(() {
                                        reponsesDonnees[q['text']] = val!;
                                      });
                                    },
                                    title: Text(opt),
                                  );
                                }).toList()
                              else
                                TextField(
                                  onChanged: (val) =>
                                      reponsesDonnees[q['text']] = val,
                                  decoration: const InputDecoration(
                                      hintText: "Votre réponse",
                                      border: OutlineInputBorder()),
                                ),
                              if (corrections.containsKey(q['text']))
                                Padding(
                                  padding:
                                      const EdgeInsets.only(top: 4, bottom: 4),
                                  child: Text(
                                    "Correction : ${corrections[q['text']]}",
                                    style: const TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              TextButton.icon(
                                onPressed: () =>
                                    _poserPreoccupation(q['text']),
                                icon: const Icon(Icons.help_outline),
                                label: const Text("Préoccupation"),
                              ),
                              const Divider(),
                            ],
                          );
                        }),
                        Center(
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                _evaluerExercice(exercice, index, setState),
                            icon: const Icon(Icons.check_circle),
                            label: const Text("S'auto-évaluer", style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xff008080)),
                          ),
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _evaluerGlobal(setState),
                  icon: const Icon(Icons.check),
                  label: const Text("Évaluation globale", style: TextStyle(color: Colors.white)),
                  style:
                      ElevatedButton.styleFrom(backgroundColor: const Color(0xff008080)),
                ),
                if (evalGlobaleFaite)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      "Note globale : $scoreObtenuGlobal / $scoreTotalGlobal",
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.teal),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
        ],
      );
    },
  );
}


  Widget _buildDevoirs() {
  List<Map<String, dynamic>> devoirs = [
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


  Widget _buildForum() {
  final scrollController = ScrollController();

  void scrollToBottom() {
    Future.delayed(Duration(milliseconds: 300), () {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  return Column(
    children: [
      Expanded(
        child: ListView.builder(
          controller: scrollController,
          padding: const EdgeInsets.all(8),
          itemCount: _messages.length,
          itemBuilder: (context, index) {
            final msg = _messages[index];
            final isTeacher = msg['role'] == 'enseignant';
            final align =
                isTeacher ? CrossAxisAlignment.end : CrossAxisAlignment.start;
            final backgroundColor =
                isTeacher ? Colors.orange.shade100 : Colors.blue.shade50;

            return Container(
              margin: const EdgeInsets.symmetric(vertical: 6),
              alignment:
                  isTeacher ? Alignment.centerRight : Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: align,
                children: [
                  Row(
                    mainAxisAlignment: isTeacher
                        ? MainAxisAlignment.end
                        : MainAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        backgroundColor:
                            isTeacher ? Colors.orange : Colors.blue,
                        radius: 16,
                        child: Text(
                          msg['sender'][0].toUpperCase(),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Column(
                        crossAxisAlignment: isTeacher
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        children: [
                          Text(
                            msg['sender'],
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isTeacher
                                  ? Colors.deepOrange
                                  : Colors.blueGrey,
                            ),
                          ),
                          if (isTeacher)
                            Text(
                              msg['isOnline'] ? "🟢 En ligne" : "⚫ Hors ligne",
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.grey),
                            ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Container(
                    constraints: const BoxConstraints(maxWidth: 320),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.shade300,
                          blurRadius: 4,
                          offset: const Offset(1, 2),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if ((msg['text'] as String).isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text(msg['text']),
                          ),
                        if (msg['image'] != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.memory(
                                msg['image'],
                                height: 150,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        if (msg['audio'] != null)
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.play_circle,
                                    color: Colors.deepOrange),
                                onPressed: () => _playAudio(msg['audio']),
                              ),
                              const Text("Écouter audio"),
                            ],
                          ),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Text(
                            '${msg['timestamp'].hour.toString().padLeft(2, '0')}:${msg['timestamp'].minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(
                                fontSize: 11, color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade300)),
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.image, color: Colors.orange),
              onPressed: () async {
                await _pickImage(); // fonction d'import image
                scrollToBottom(); // 📜 descente automatique
              },
            ),
            IconButton(
              icon: Icon(
                isRecording ? Icons.stop_circle : Icons.mic,
                color: isRecording ? Colors.red : Colors.green,
              ),
              onPressed: () {
                _toggleRecording(); // gestion enregistrement
                scrollToBottom();
              },
            ),
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: const InputDecoration(
                  hintText: "Écrire un message...",
                  border: InputBorder.none,
                ),
                onSubmitted: (_) {
                  _sendMessage();
                  scrollToBottom();
                },
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send, color: Colors.blue),
              onPressed: () {
                _sendMessage();
                scrollToBottom();
              },
            ),
          ],
        ),
      )
    ],
  );
}

}
