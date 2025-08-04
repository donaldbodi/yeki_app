import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sound/public/flutter_sound_player.dart';
import 'package:flutter_sound/public/flutter_sound_recorder.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

Uint8List? _imageBytes;

class Enseignant {
  final int id;
  final String nom;
  final String email;
  final String specialite;
  final String photoUrl;

  Enseignant({
    required this.id,
    required this.nom,
    required this.email,
    required this.specialite,
    required this.photoUrl,
  });
}

class Question {
  final String enonce;
  final List<String>? choix; // null si ce n’est pas un QCM
  final String correction;
  final int points;
  final bool estQCM;

  Question({
    required this.enonce,
    this.choix,
    required this.correction,
    required this.points,
    required this.estQCM,
  });
}

class ExerciceDevoir {
  final String titre;
  final String enonce;
  final List<Question> questions;

  ExerciceDevoir({
    required this.titre,
    required this.enonce,
    required this.questions,
  });
}


class Devoir {
  final String titre;
  final String dateLimite;
  final List<ExerciceDevoir> exercices;
  bool estDeroule;

  Devoir({
    required this.titre,
    required this.dateLimite,
    required this.exercices,
    this.estDeroule = false,
  });
}

class Exercice {
  final String titre;
  final int nbQuestions;

  Exercice({
    required this.titre,
    required this.nbQuestions,
  });
}


class Lecon {
  final String id;
  final String titre;
  final String resume;
  final String duree;
  final bool estActive;
  final String contenu;
  final String dateCreation;
  final String auteur;

  Lecon({
    required this.id,
    required this.titre,
    required this.resume,
    required this.duree,
    required this.estActive,
    required this.contenu,
    required this.dateCreation,
    required this.auteur,
  });
}

class DetailCoursEnseignantPage extends StatefulWidget {
  final Map<String, dynamic> cours;
  final bool estEnseignantPrincipal;

  List<Enseignant> enseignants = [
  Enseignant(
    id: 1,
    nom: 'Mme. Aissatou Ndongo',
    email: 'aissatou.ndongo@ecole.com',
    specialite: 'Mathématiques',
    photoUrl: 'assets/images/enseignant1.jpeg',
  ),
  Enseignant(
    id: 2,
    nom: 'M. Jules Bissala',
    email: 'jules.bissala@ecole.com',
    specialite: 'Statistiques',
    photoUrl: 'assets/images/enseignant2.jpeg',
  ),
];


String filtreDevoir = "";

List<Exercice> exercices = [
  Exercice(titre: 'Exercice 1 : Logique booléenne', nbQuestions: 5),
  Exercice(titre: 'Exercice 2 : Fonctions numériques', nbQuestions: 4),
];


List<Lecon> lecons = [
  Lecon(
    id: 'lecon1',
    titre: 'Introduction à la géométrie',
    resume: 'Notions de base sur les figures géométriques.',
    duree: '45 min',
    estActive: true,
    contenu: 'Contenu détaillé de la leçon',
    dateCreation: '2025-06-01',
    auteur: 'Mme Dupont',
  ),
  Lecon(
    id: 'lecon2',
    titre: 'Les angles et leurs mesures',
    resume: 'Types d’angles et leur mesure.',
    duree: '30 min',
    estActive: true,
    contenu: 'Contenu sur les angles',
    dateCreation: '2025-06-05',
    auteur: 'Mme Dupont',
  ),
];

  DetailCoursEnseignantPage({
    super.key,
    required this.cours,
    required this.estEnseignantPrincipal,
  });

  @override
  State<DetailCoursEnseignantPage> createState() => _DetailCoursEnseignantPageState();
}

class _DetailCoursEnseignantPageState extends State<DetailCoursEnseignantPage> with TickerProviderStateMixin {
  late TabController _tabController;
  List<Devoir> devoirs = [
  Devoir(
    titre: "Devoir maison : Chapitre 1",
    dateLimite: "2025-07-20",
    exercices: [
      ExerciceDevoir(
        titre: "Exercice 1",
        enonce: "Résolvez les équations suivantes...",
        questions: [
          Question(
              enonce: "x² - 4 = 0",
              correction: "x = ±2",
              points: 2,
              estQCM: false),
          Question(
              enonce: "x² + 2x + 1 = 0",
              correction: "x = -1",
              points: 3,
              estQCM: false),
        ],
      ),
    ],
  ),
];

final TextEditingController _messageController = TextEditingController();
final List<Map<String, dynamic>> _messages = [];
final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  bool isRecording = false;
  bool isPlaying = false;
  String? recordedPath;

//juste pour le test
  Future<Uint8List> loadAssetImage(String path) async {
    final data = await rootBundle.load(path);
    return data.buffer.asUint8List();
  }

  @override
  void initState() {
    _tabController = TabController(length: 4, vsync: this);
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
  
  void _ajouterLecon(BuildContext context) {
  if (!widget.estEnseignantPrincipal) return;

  showDialog(
    context: context,
    builder: (context) {
      final TextEditingController titreCtrl = TextEditingController();
      final TextEditingController resumeCtrl = TextEditingController();
      final TextEditingController dureeCtrl = TextEditingController();

      return AlertDialog(
        title: const Text("Ajouter une nouvelle leçon"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titreCtrl,
                decoration: const InputDecoration(labelText: "Titre de la leçon"),
              ),
              TextField(
                controller: resumeCtrl,
                decoration: const InputDecoration(labelText: "Résumé"),
              ),
              TextField(
                controller: dureeCtrl,
                decoration: const InputDecoration(labelText: "Durée (ex: 45 min)"),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () {
              // Ajouter la logique pour insérer la leçon dans la base ou l’état
              print("Nouvelle leçon : ${titreCtrl.text}, ${resumeCtrl.text}, ${dureeCtrl.text}");
              Navigator.pop(context);
            },
            child: const Text("Ajouter"),
          ),
        ],
      );
    },
  );
}

void _modifierDevoir(int index) {
  final devoir = devoirs[index];
  final titreCtrl = TextEditingController(text: devoir.titre);
  final dateCtrl = TextEditingController(text: devoir.dateLimite);

  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text("Modifier le devoir"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: titreCtrl, decoration: const InputDecoration(labelText: "Titre")),
          TextField(controller: dateCtrl, decoration: const InputDecoration(labelText: "Date limite")),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
        ElevatedButton(
          onPressed: () {
            setState(() {
              devoirs[index] = Devoir(
                titre: titreCtrl.text,
                dateLimite: dateCtrl.text,
                exercices: devoir.exercices,
              );
            });
            Navigator.pop(context);
          },
          child: const Text("Modifier"),
        ),
      ],
    ),
  );
}

void _modifierLecon(BuildContext context, Lecon lecon) {
  final titreController = TextEditingController(text: lecon.titre);
  final resumeController = TextEditingController(text: lecon.resume);
  final dureeController = TextEditingController(text: lecon.duree);

  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text("Modifier ${lecon.titre}"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: titreController, decoration: const InputDecoration(labelText: 'Titre')),
          TextField(controller: resumeController, decoration: const InputDecoration(labelText: 'Résumé')),
          TextField(controller: dureeController, decoration: const InputDecoration(labelText: 'Durée')),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
        ElevatedButton(
          onPressed: () {
            final index = widget.lecons.indexWhere((l) => l.id == lecon.id);
            if (index != -1) {
              setState(() {
                widget.lecons[index] = Lecon(
                  id: lecon.id,
                  titre: titreController.text,
                  resume: resumeController.text,
                  duree: dureeController.text,
                  estActive: lecon.estActive,
                  contenu: lecon.contenu,
                  dateCreation: lecon.dateCreation,
                  auteur: lecon.auteur,
                );
              });
            }
            Navigator.pop(context);
          },
          child: const Text("Enregistrer"),
        ),
      ],
    ),
  );
}


  void _ajouterExercice(BuildContext context) {
  final titreController = TextEditingController();
  final nbQuestionsController = TextEditingController();

  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text("Ajouter un exercice"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: titreController,
            decoration: const InputDecoration(labelText: "Titre"),
          ),
          TextField(
            controller: nbQuestionsController,
            decoration: const InputDecoration(labelText: "Nombre de questions"),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Annuler"),
        ),
        ElevatedButton(
          onPressed: () {
            if (titreController.text.isNotEmpty && nbQuestionsController.text.isNotEmpty) {
              setState(() {
                widget.exercices.add(
                  Exercice(
                    titre: titreController.text,
                    nbQuestions: int.tryParse(nbQuestionsController.text) ?? 0,
                  ),
                );
              });
              Navigator.pop(context);
            }
          },
          child: const Text("Ajouter"),
        ),
      ],
    ),
  );
}


  void _ajouterEnseignant(BuildContext context) {
  if (!widget.estEnseignantPrincipal) return;

  showDialog(
    context: context,
    builder: (context) {
      final TextEditingController nomCtrl = TextEditingController();
      final TextEditingController emailCtrl = TextEditingController();

      return AlertDialog(
        title: const Text("Ajouter un enseignant secondaire"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nomCtrl,
              decoration: const InputDecoration(labelText: "Nom complet"),
            ),
            TextField(
              controller: emailCtrl,
              decoration: const InputDecoration(labelText: "Email"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () {
              // Logique d'ajout réel
              print("Nouvel enseignant : ${nomCtrl.text}, ${emailCtrl.text}");
              Navigator.pop(context);
            },
            child: const Text("Ajouter"),
          ),
        ],
      );
    },
  );
}

Future<Question?> _ajouterQuestion(BuildContext context) async {
  final enonceCtrl = TextEditingController();
  final correctionCtrl = TextEditingController();
  final pointsCtrl = TextEditingController();
  final List<String> choix = [];
  bool estQCM = false;

  return await showDialog<Question>(
    context: context,
    builder: (_) {
      return StatefulBuilder(
        builder: (ctx, setStateDialog) {
          return AlertDialog(
            title: const Text("Nouvelle question"),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  SwitchListTile(
                    value: estQCM,
                    title: const Text("Question à choix multiple"),
                    onChanged: (val) => setStateDialog(() => estQCM = val),
                  ),
                  TextField(controller: enonceCtrl, decoration: const InputDecoration(labelText: "Énoncé")),
                  TextField(controller: correctionCtrl, decoration: const InputDecoration(labelText: "Correction")),
                  TextField(controller: pointsCtrl, decoration: const InputDecoration(labelText: "Nombre de points"), keyboardType: TextInputType.number),
                  if (estQCM)
                    Column(
                      children: [
                        for (int i = 0; i < choix.length; i++)
                          ListTile(title: Text(choix[i])),
                        TextField(
                          decoration: const InputDecoration(labelText: "Ajouter un choix"),
                          onSubmitted: (val) => setStateDialog(() => choix.add(val)),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
              ElevatedButton(
                onPressed: () {
                  if (enonceCtrl.text.isNotEmpty && correctionCtrl.text.isNotEmpty) {
                    Navigator.pop(
                      context,
                      Question(
                        enonce: enonceCtrl.text,
                        correction: correctionCtrl.text,
                        points: int.tryParse(pointsCtrl.text) ?? 0,
                        estQCM: estQCM,
                        choix: estQCM ? choix : null,
                      ),
                    );
                  }
                },
                child: const Text("Ajouter"),
              ),
            ],
          );
        },
      );
    },
  );
}

Future<ExerciceDevoir?> _creerExercice(BuildContext context) async {
  final titreCtrl = TextEditingController();
  final enonceCtrl = TextEditingController();
  final questions = <Question>[];

  return await showDialog<ExerciceDevoir>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setStateDialog) => AlertDialog(
        title: const Text("Nouvel exercice"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: titreCtrl, decoration: const InputDecoration(labelText: "Titre de l'exercice")),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text("Ajouter une question"),
                onPressed: () async {
                  final q = await _ajouterQuestion(context);
                  if (q != null) {
                    setStateDialog(() => questions.add(q));
                  }
                },
              ),
              Text("Questions ajoutées : ${questions.length}")
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Annuler")),
          ElevatedButton(
            onPressed: () {
              if (titreCtrl.text.isNotEmpty && questions.isNotEmpty) {
                Navigator.pop(
                    ctx,
                    ExerciceDevoir(enonce: enonceCtrl.text,
                        titre: titreCtrl.text, questions: questions));
              }
            },
            child: const Text("Valider"),
          ),
        ],
      ),
    ),
  );
}

void _ajouterDevoirComplet(BuildContext context) {
  final titreCtrl = TextEditingController();
  final dateCtrl = TextEditingController();
  final exercices = <ExerciceDevoir>[];

  showDialog(
    context: context,
    builder: (_) {
      return StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text("Créer un nouveau devoir"),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(controller: titreCtrl, decoration: const InputDecoration(labelText: "Titre du devoir")),
                  TextField(controller: dateCtrl, decoration: const InputDecoration(labelText: "Date limite (ex: 2025-07-20)")),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final exercice = await _creerExercice(context);
                      if (exercice != null) {
                        setStateDialog(() {
                          exercices.add(exercice);
                        });
                      }
                    },
                    icon: const Icon(Icons.add),
                    label: const Text("Ajouter un exercice"),
                  ),
                  const SizedBox(height: 10),
                  Text("Exercices ajoutés : ${exercices.length}"),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
              ElevatedButton(
                onPressed: () {
                  if (titreCtrl.text.isNotEmpty && dateCtrl.text.isNotEmpty) {
                    setState(() {
                      devoirs.add(Devoir(
                        titre: titreCtrl.text,
                        dateLimite: dateCtrl.text,
                        exercices: exercices,
                      ));
                    });
                    Navigator.pop(context);
                  }
                },
                child: const Text("Créer"),
              ),
            ],
          );
        },
      );
    },
  );
}


void _supprimerDevoir(int index) async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text("Supprimer ce devoir"),
      content: const Text("Voulez-vous vraiment supprimer ce devoir ?"),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Annuler")),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () => Navigator.pop(context, true),
          child: const Text("Supprimer"),
        ),
      ],
    ),
  );

  if (confirm == true) {
    setState(() {
      devoirs.removeAt(index);
    });
  }
}

  void _retirerEnseignant(BuildContext context, Enseignant enseignant) async {
  final bool? confirmation = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text("Retirer l'enseignant"),
      content: Text("Voulez-vous vraiment retirer ${enseignant.nom} de ce cours ?"),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text("Annuler"),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () => Navigator.pop(context, true),
          child: const Text("Retirer"),
        ),
      ],
    ),
  );

  if (confirmation == true) {
    // 🔄 Traitement : appel API ou suppression locale
    setState(() {
      widget.enseignants.removeWhere((e) => e.id == enseignant.id);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("${enseignant.nom} a été retiré du cours")),
    );
  }
}

Widget _champFiltreDevoirs() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
    child: TextField(
      decoration: const InputDecoration(
        labelText: "Filtrer les devoirs par titre ou date",
        prefixIcon: Icon(Icons.search),
        border: OutlineInputBorder(),
      ),
      onChanged: (val) {
        setState(() => widget.filtreDevoir = val.toLowerCase());
      },
    ),
  );
}

Widget _ongletExercices(bool estEnseignantPrincipal) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (estEnseignantPrincipal)
        Padding(
          padding: const EdgeInsets.only(right: 16.0, top: 10),
          child: Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () => _ajouterExercice(context),
              icon: const Icon(Icons.add),
              label: const Text("Nouvel exercice"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00695C),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ),
      const SizedBox(height: 10),
      Expanded(
        child: widget.exercices.isEmpty
            ? const Center(child: Text("Aucun exercice disponible."))
            : ListView.builder(
                itemCount: widget.exercices.length,
                itemBuilder: (_, index) {
                  final exo = widget.exercices[index];
                  return Card(
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: const Icon(Icons.assignment, color: Colors.teal),
                      title: Text(exo.titre,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("${exo.nbQuestions} question(s)"),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        // TODO: Naviguer vers détail de l’exercice
                      },
                    ),
                  );
                },
              ),
      ),
    ],
  );
}

Widget _buildCarteLecon(Lecon lecon) {
  return Card(
    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    elevation: 3,
    child: ListTile(
      title: Text(lecon.titre, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(lecon.resume),
          Text("Durée : ${lecon.duree}"),
        ],
      ),
      trailing: widget.estEnseignantPrincipal
          ? IconButton(
              icon: const Icon(Icons.edit, color: Colors.teal),
              tooltip: "Modifier la leçon",
              onPressed: () => _modifierLecon(context, lecon),
            )
          : null,
    ),
  );
}

Widget _buildCarteEnseignant(Enseignant enseignant) {
  return Card(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    child: ListTile(
      leading: CircleAvatar(
        backgroundImage: AssetImage(enseignant.photoUrl),
      ),
      title: Text(enseignant.nom),
      subtitle: Text(enseignant.specialite),
      trailing: widget.estEnseignantPrincipal
          ? IconButton(
              icon: const Icon(Icons.remove_circle, color: Colors.red),
              tooltip: "Retirer cet enseignant",
              onPressed: () => _retirerEnseignant(context, enseignant),
            )
          : null,
    ),
  );
}

  Widget _sectionLecons() {

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text("📘 Leçons du cours", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ...widget.lecons.map((Lecon lecon) => _buildCarteLecon(lecon)).toList(),
        const Divider(),
        const Text("👩‍🏫 Enseignants secondaires", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ...widget.enseignants.map((Enseignant ens) => _buildCarteEnseignant(ens)).toList(),
        if (widget.estEnseignantPrincipal)
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text("Ajouter un enseignant secondaire"),
            onPressed: () => _ajouterEnseignant(context),
          ),
        if (widget.estEnseignantPrincipal)
          ElevatedButton.icon(
            icon: const Icon(Icons.note_add),
            label: const Text("Créer une nouvelle leçon"),
            onPressed: () => _ajouterLecon(context),
          ),
      ],
    );
  }

  /*Widget _sectionExercices() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text("📚 Exercices", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ...widget.exercices.map((Exercice ex) => _ongletExercices(widget.estEnseignantPrincipal)).toList(),
        if (widget.estEnseignantPrincipal)
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text("Ajouter un exercice"),
            onPressed: () => _ajouterExercice,
          ),
      ],
    );
  }*/

  Widget _sectionDevoirs() {
  return Column(
    children: [
      if (widget.estEnseignantPrincipal)
        Padding(
          padding: const EdgeInsets.only(right: 16, top: 10),
          child: Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text("Nouveau devoir"),
              onPressed: () => _ajouterDevoirComplet(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF008080),
              ),
            ),
          ),
        ),
      Expanded(
        child: devoirs.isEmpty
            ? const Center(child: Text("Aucun devoir disponible."))
            : ListView.builder(
                itemCount: devoirs.length,
                itemBuilder: (_, index) {
                  final d = devoirs[index];
                  final devoirsFiltres = devoirs.where((d) =>
                  d.titre.toLowerCase().contains(widget.filtreDevoir) ||
                  d.dateLimite.toLowerCase().contains(widget.filtreDevoir)).toList();
                  return Card(
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ExpansionTile(
                      title: Text(d.titre, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("📅 Limite : ${d.dateLimite}"),
                      initiallyExpanded: d.estDeroule,
                      children: [
                        ...d.exercices.map((exo) => Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("📘 ${exo.titre}",
                                      style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Text("📝 Énoncé : ${exo.enonce}"),
                                  const SizedBox(height: 6),
                                  ...exo.questions.map((q) => ListTile(
                                        leading: q.estQCM
                                            ? const Icon(Icons.check_box)
                                            : const Icon(Icons.short_text),
                                        title: Text(q.enonce),
                                        subtitle: Text("Correction : ${q.correction} • ${q.points} pts"),
                                      )),
                                ],
                              ),
                            )),
                        if (widget.estEnseignantPrincipal)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                onPressed: () => _modifierDevoir(index),
                                icon: const Icon(Icons.edit),
                                label: const Text("Modifier"),
                              ),
                              TextButton.icon(
                                onPressed: () => _supprimerDevoir(index),
                                icon: const Icon(Icons.delete, color: Colors.red),
                                label: const Text("Supprimer", style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                      ],
                    ),
                  );
                },
              ),
      )
    ],
  );
}

Widget _sectionForum() {
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

  @override
  Widget build(BuildContext context) {
    final titre = widget.cours['titre'];
    //final niveau = widget.cours['niveau'];
    //final matiere = widget.cours['matiere'];

    return Scaffold(
      appBar: AppBar(
        title: Text("$titre"),
        backgroundColor: const Color(0xff008080),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Leçons", icon: Icon(Icons.menu_book)),
            Tab(text: "Exercices", icon: Icon(Icons.fitness_center)),
            Tab(text: "Devoirs", icon: Icon(Icons.assignment)),
            Tab(text: "Forum", icon: Icon(Icons.forum)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _sectionLecons(),
          _ongletExercices(widget.estEnseignantPrincipal),
          _sectionDevoirs(),
          _sectionForum(),
        ],
      ),
    );
  }
}
