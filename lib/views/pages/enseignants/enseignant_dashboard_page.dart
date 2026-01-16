import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yeki/views/pages/enseignants/interface_enseignant_page.dart';

import '../../../widgets/yeki_app_bar.dart';


class DashboardEnseignantPage extends StatefulWidget {
  final RoleEnseignant role;
  final String nomEnseignant;
  final String roleEnseignant;

  /// Données minimales:
  /// - role Cadre  -> List<Departement> : [{id, nom, cours:[{id, titre, enseignant_principal:{id, name}?}]}]
  /// - role Principal -> List<Cours> : [{id, titre, lecons_count? (int), enseignants_secondaires:[{id, name}]}]
  final List<dynamic>? extraInfo;

  const DashboardEnseignantPage({
    super.key,
    required this.role,
    required this.nomEnseignant,
    required this.roleEnseignant,
    this.extraInfo,
  });

  @override
  State<DashboardEnseignantPage> createState() => _DashboardEnseignantPageState();
}

class _DashboardEnseignantPageState extends State<DashboardEnseignantPage> {
  static const String baseUrl = 'https://yekiapp.pythonanywhere.com';
  bool _creatingCourse = false;
  final List<String> _colors = [
  '#4F46E5', // indigo
  '#16A34A', // green
  '#DC2626', // red
  '#EA580C', // orange
  '#0EA5E9', // sky
];

final Map<String, IconData> _icons = {
  'book': Icons.menu_book,
  'science': Icons.science,
  'code': Icons.code,
  'calculate': Icons.calculate,
  'history': Icons.history_edu,
};

  final TextEditingController _titreCoursCtrl = TextEditingController();
  final TextEditingController _niveauCtrl = TextEditingController();
  // ====== AJOUT MODULE ======
final TextEditingController _titreModuleCtrl = TextEditingController();
final TextEditingController _descriptionModuleCtrl = TextEditingController();
final TextEditingController _ordreModuleCtrl = TextEditingController();

List<Map<String, dynamic>> _modulesDuCours = [];
bool _loadingModules = false;

bool _addingModule = false;

  // ====== AJOUT LEÇON ======
final TextEditingController _titreLeconCtrl = TextEditingController();
final TextEditingController _descriptionLeconCtrl = TextEditingController();

int? _moduleId; // module sélectionné

FilePickerResult? _pdfFile;
FilePickerResult? _videoFile;

bool _addingLecon = false;

  int? _depSelectionneId;
  int? _principalSelectionneId;
  final bool isSubscribed = true;
  final TextEditingController _descriptionCtrl = TextEditingController();

  String _selectedColor = '#4F46E5'; // couleur par défaut
  String _selectedIcon = 'book';


  // listes pour sélecteurs (chargées selon le rôle)
  List<Map<String, dynamic>> _enseignantsPrincipaux = [];   // pour Cadre
  List<Map<String, dynamic>> _enseignantsSecondaires = [];  // pour Principal (ajout)

  // Helpers --------------------------------------------------------------------
  Future<Map<String, String>> _authHeaders() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');
  return {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Token $token',
  };
}

Future<Map<String, String>> _authHeadersMultipart() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');
  return {
    if (token != null) 'Authorization': 'Token $token',
  };
}

  List<Map<String, dynamic>> _asListOfMap(List<dynamic>? raw) {
    if (raw == null) return [];
    return raw
        .where((e) => e is Map)
        .map<Map<String, dynamic>>(
          (e) => Map<String, dynamic>.from((e as Map).map((k, v) => MapEntry(k.toString(), v))),
        )
        .toList();
  }

  @override
  void initState() {
    super.initState();
    if (widget.role == RoleEnseignant.enseignantCadre) {
      _fetchEnseignantsPrincipaux();
    } else if (widget.role == RoleEnseignant.enseignantPrincipal) {
      _fetchEnseignantsSecondaires();
    }
  }

  void _ouvrirFormulaireAjoutModule(int coursId) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) {
      return Padding(
        padding: MediaQuery.of(context).viewInsets.add(
          const EdgeInsets.all(16),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  "Créer un module",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _titreModuleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Titre du module',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 12),

              TextField(
                controller: _ordreModuleCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Ordre du module',
                  hintText: 'Ex: 1, 2, 3...',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 12),

              TextField(
                controller: _descriptionModuleCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description (optionnelle)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: _addingModule
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add_box),
                  label: const Text("Créer le module"),
                  onPressed: _addingModule
                      ? null
                      : () async {
                          await _creerModule(coursId);
                          if (context.mounted) Navigator.pop(context);
                        },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

  void _ouvrirFormulaireCreationCours() {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          final deps = _asListOfMap(_localExtraInfo);

          return Padding(
            padding: MediaQuery.of(context).viewInsets.add(
              const EdgeInsets.all(16),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Text(
                      "Créer un cours",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: _titreCoursCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Titre du cours',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: _niveauCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Niveau',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: _descriptionCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Description courte',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  /// 🎨 COULEURS
                  const Text('Couleur du cours'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _colors.map((c) {
                      return GestureDetector(
                        onTap: () {
                          setModalState(() {
                            _selectedColor = c;
                          });
                        },
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Color(int.parse(c.replaceFirst('#', '0xff'))),
                            shape: BoxShape.circle,
                            border: _selectedColor == c
                                ? Border.all(width: 3, color: Colors.black)
                                : null,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),

                  /// 🧩 ICONES
                  const Text('Icône du cours'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _icons.entries.map((entry) {
                      return ChoiceChip(
                        label: Icon(entry.value),
                        selected: _selectedIcon == entry.key,
                        onSelected: (_) {
                          setModalState(() {
                            _selectedIcon = entry.key;
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  DropdownButtonFormField<int>(
                    value: _depSelectionneId,
                    items: deps
                        .map((d) => DropdownMenuItem<int>(
                              value: d['id'] as int,
                              child: Text(d['nom'] ?? ''),
                            ))
                        .toList(),
                    onChanged: (v) => setModalState(() => _depSelectionneId = v),
                    decoration: const InputDecoration(
                      labelText: 'Département',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<int>(
                    value: _principalSelectionneId,
                    items: _enseignantsPrincipaux
                        .map((e) => DropdownMenuItem<int>(
                              value: e['id'] as int,
                              child: Text(e['user']['username'].toString()),
                            ))
                        .toList(),
                    onChanged: (v) =>
                        setModalState(() => _principalSelectionneId = v),
                    decoration: const InputDecoration(
                      labelText: 'Enseignant principal',
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: _creatingCourse
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check),
                      label: const Text("Créer le cours"),
                      onPressed: _creatingCourse
                          ? null
                          : () async {
                              await _creerCours();
                              if (context.mounted) Navigator.pop(context);
                            },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}


void _ouvrirFormulaireAjoutLecon(int coursId) {
  _titreLeconCtrl.clear();
  _descriptionLeconCtrl.clear();
  _pdfFile = null;
  _videoFile = null;
  _moduleId = null;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) {
      bool loading = true;
      String? erreur;
      List<Map<String, dynamic>> modules = [];

      return StatefulBuilder(
        builder: (context, modalSetState) {
          /// chargement UNE SEULE FOIS
          if (loading && modules.isEmpty && erreur == null) {
            _chargerModules(coursId).then((data) {
              modalSetState(() {
                modules = data;
                loading = false;
              });
            }).catchError((e) {
              modalSetState(() {
                erreur = e.toString();
                loading = false;
              });
            });
          }

          return Padding(
            padding: MediaQuery.of(context).viewInsets.add(
              const EdgeInsets.all(16),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Text(
                      "Ajouter une leçon",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 16),

                  /// TITRE
                  TextField(
                    controller: _titreLeconCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Titre de la leçon',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  /// DESCRIPTION
                  TextField(
                    controller: _descriptionLeconCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Brève description',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  /// MODULE
                  if (loading)
                    const Center(child: CircularProgressIndicator())
                  else if (erreur != null)
                    Text(
                      "Erreur : $erreur",
                      style: const TextStyle(color: Colors.red),
                    )
                  else if (modules.isEmpty)
                    const Text(
                      "Aucun module disponible. Créez d'abord un module.",
                      style: TextStyle(color: Colors.orange),
                    )
                  else
                    DropdownButtonFormField<int>(
                      value: _moduleId,
                      items: modules
                          .map(
                            (m) => DropdownMenuItem<int>(
                              value: m['id'],
                              child: Text(m['titre']),
                            ),
                          )
                          .toList(),
                      onChanged: (v) =>
                          modalSetState(() => _moduleId = v),
                      decoration: const InputDecoration(
                        labelText: 'Module',
                        border: OutlineInputBorder(),
                      ),
                    ),

                  const SizedBox(height: 12),

                  /// PDF
                  ElevatedButton.icon(
                    icon: const Icon(Icons.picture_as_pdf),
                    label: Text(
                      _pdfFile == null
                          ? "Choisir le PDF"
                          : _pdfFile!.files.single.name,
                    ),
                    onPressed: _pickPdf,
                  ),

                  const SizedBox(height: 8),

                  /// VIDEO
                  ElevatedButton.icon(
                    icon: const Icon(Icons.video_file),
                    label: Text(
                      _videoFile == null
                          ? "Choisir la vidéo (optionnel)"
                          : _videoFile!.files.single.name,
                    ),
                    onPressed: _pickVideo,
                  ),

                  const SizedBox(height: 20),

                  /// VALIDATION
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _addingLecon
                          ? null
                          : () async {
                              await _envoyerLecon(coursId);
                              if (context.mounted) Navigator.pop(context);
                            },
                      child: _addingLecon
                          ? const CircularProgressIndicator()
                          : const Text("Ajouter la leçon"),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

Future<List<Map<String, dynamic>>> _chargerModules(int coursId) async {
  final headers = await _authHeaders();
  final response = await http.get(
    Uri.parse('$baseUrl/api/cours/$coursId/liste-modules/'),
    headers: headers,
  );

  if (response.statusCode == 200) {
    final List decoded = jsonDecode(response.body);
    return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
  } else {
    throw Exception("Erreur chargement modules");
  }
}


Future<void> _creerModule(int coursId) async {
  final titre = _titreModuleCtrl.text.trim();

  final ordre = int.tryParse(_ordreModuleCtrl.text.trim());

  if (ordre == null || ordre <= 0) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("L'ordre du module est obligatoire")),
    );
    setState(() => _addingModule = false);
    return;
  }

  if (titre.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Le titre du module est obligatoire")),
    );
    return;
  }

  setState(() => _addingModule = true);

  try {
    final headers = await _authHeaders();

    final res = await http.post(
      Uri.parse('$baseUrl/api/cours/$coursId/modules/'),
      headers: headers,
      body: jsonEncode({
        'titre': titre,
        'description': _descriptionModuleCtrl.text.trim(),
        'ordre': ordre,
      }),
    );

    if (res.statusCode == 201) {
      final module = jsonDecode(res.body);

      // 🔁 Mise à jour locale
      final coursList = _asListOfMap(_localExtraInfo);
      for (final c in coursList) {
        if (c['id'] == coursId) {
          final List modules = (c['modules'] as List?) ?? [];
          modules.add(module);
          c['modules'] = modules;
          break;
        }
      }

      _titreModuleCtrl.clear();
      _descriptionModuleCtrl.clear();
      _ordreModuleCtrl.clear();

      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Module créé avec succès")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur (${res.statusCode})")),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Erreur: $e")),
    );
  } finally {
    setState(() => _addingModule = false);
  }
}

Future<void> _envoyerLecon(int coursId) async {
  if (_pdfFile == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Le PDF est obligatoire")),
    );
    return;
  }

  if (_moduleId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Veuillez sélectionner un module")),
    );
    return;
  }

  setState(() => _addingLecon = true);

  try {
    final headers = await _authHeadersMultipart();

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/api/cours/$coursId/lecons/'),
    );

    request.headers.addAll(headers);

    /// 🔹 Champs texte
    request.fields['titre'] = _titreLeconCtrl.text.trim();
    request.fields['description'] = _descriptionLeconCtrl.text.trim();
    request.fields['module'] = _moduleId.toString(); // ⚠️ adapter si backend = module_id

    /// 🔹 PDF obligatoire
    request.files.add(
      await http.MultipartFile.fromPath(
        'fichier_pdf',
        _pdfFile!.files.single.path!,
      ),
    );

    /// 🔹 Vidéo optionnelle
    if (_videoFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'video',
          _videoFile!.files.single.path!,
        ),
      );
    }

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Leçon ajoutée avec succès")),
      );

      _titreLeconCtrl.clear();
      _descriptionLeconCtrl.clear();
      _pdfFile = null;
      _videoFile = null;
      _moduleId = null;
    } else {
      debugPrint("❌ ${response.statusCode} → $responseBody");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur ${response.statusCode}")),
      );
    }
  } catch (e) {
    debugPrint("Erreur: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Erreur: $e")),
    );
  } finally {
    setState(() => _addingLecon = false);
  }
}

  // Fetch lists for pickers ---------------------------------------------------- bien gerer le token
  Future<void> _fetchEnseignantsPrincipaux() async {
    try {
      final headers = await _authHeaders();
      final res = await http.get(Uri.parse('$baseUrl/api/enseignants_principaux/'), headers: headers);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        setState(() {
          _enseignantsPrincipaux = _asListOfMap(body);
        });
      }
    } catch (_) {}
  }

  Future<void> _pickPdf() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['pdf'],
  );

  if (result != null) {
    setState(() {
      _pdfFile = result;
    });
  }
}

Future<void> _pickVideo() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.video,
  );

  if (result != null) {
    setState(() {
      _videoFile = result;
    });
  }
}


  Future<void> _fetchEnseignantsSecondaires() async {
    try {
      final headers = await _authHeaders();
      final res = await http.get(Uri.parse('$baseUrl/api/enseignants_secondaires/'), headers: headers);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        setState(() {
          _enseignantsSecondaires = _asListOfMap(body);
        });
      }
    } catch (_) {}
  }

  // Actions CADRE --------------------------------------------------------------
  Future<void> _creerCours() async {
    if (_creatingCourse) return;
    final titre = _titreCoursCtrl.text.trim();
    final niveau = _niveauCtrl.text.trim();
    if (titre.isEmpty || _depSelectionneId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez renseigner le titre et le département.')),
      );
      return;
    }
    setState(() => _creatingCourse = true);
    try {
      final headers = await _authHeaders();
      final body = {
        'titre': titre,
        'niveau': niveau,
        'departement': _depSelectionneId,
        'description_brief': _descriptionCtrl.text.trim(),
        'color_code': _selectedColor,
        'icon_name': _selectedIcon,
        if (_principalSelectionneId != null)
          'enseignant_principal': _principalSelectionneId,
      };
      final res = await http.post(Uri.parse('$baseUrl/api/cours/create/'),
          headers: headers, body: jsonEncode(body));

      if (res.statusCode == 201) {
        final created = Map<String, dynamic>.from(jsonDecode(res.body));
        // mise à jour locale (pas besoin de recharger tout)
        final deps = _asListOfMap(widget.extraInfo);
        final idx = deps.indexWhere((d) => d['id'] == _depSelectionneId);
        if (idx != -1) {
          final List cours = (deps[idx]['cours'] as List?) ?? [];
          cours.add(created);
          deps[idx]['cours'] = cours;
          // pousse dans widget.extraInfo localement
          setState(() {
            (_localExtraInfo as List).clear();
            (_localExtraInfo as List).addAll(deps);
          });
        }
        _titreCoursCtrl.clear();
        _niveauCtrl.clear();
        _descriptionCtrl.clear();
        _selectedColor = '#4F46E5';
        _selectedIcon = 'book';
        _principalSelectionneId = null;
        _depSelectionneId = null;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cours créé.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur création (${res.statusCode})')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    } finally {
      setState(() => _creatingCourse = false);
    }
  }

  Future<void> _modifierPrincipal(int coursId, int nouveauPrincipalId) async {
    try {
      final headers = await _authHeaders();
      final res = await http.patch(
        Uri.parse('$baseUrl/api/cours/$coursId/'),
        headers: headers,
        body: jsonEncode({'enseignant_principal': nouveauPrincipalId}),
      );
      if (res.statusCode == 200) {
        // update local
        final deps = _asListOfMap(_localExtraInfo);
        for (final d in deps) {
          final List cours = (d['cours'] as List?) ?? [];
          for (final c in cours) {
            final mc = c as Map<String, dynamic>;
            if (mc['id'] == coursId) {
              mc['enseignant_principal'] = _enseignantsPrincipaux
                  .firstWhere((e) => e['id'] == nouveauPrincipalId, orElse: () => {'id': nouveauPrincipalId});
              break;
            }
          }
        }
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enseignant principal mis à jour.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  // Actions PRINCIPAL ----------------------------------------------------------


  Future<void> _ajouterEnseignantSecondaire(int coursId) async {
    int? enseignantId;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) {
        // filtre ceux déjà dans le cours
        final cours = _asListOfMap(_localExtraInfo).firstWhere((c) => c['id'] == coursId, orElse: () => {});
        final existants = _asListOfMap((cours['enseignants_secondaires'] as List?) ?? []);
        final existantsIds = existants.map((e) => e['id']).toSet();
        final candidats = _enseignantsSecondaires.where((e) => !existantsIds.contains(e['id'])).toList();

        return Padding(
          padding: MediaQuery.of(context).viewInsets.add(const EdgeInsets.all(16)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Ajouter un enseignant secondaire', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                items: candidats
                    .map((e) => DropdownMenuItem<int>(value: e['id'] as int, child: Text(e['user']['username']?.toString() ?? '')))
                    .toList(),
                onChanged: (v) => enseignantId = v,
                decoration: const InputDecoration(labelText: 'Sélectionner un enseignant'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () async {
                  if (enseignantId == null) return;
                  final headers = await _authHeaders();
                  final res = await http.post(
                    Uri.parse('$baseUrl/api/cours/$coursId/add-enseignant/'),
                    headers: headers,
                    body: jsonEncode({'enseignant_id': enseignantId}),
                  );
                  if (res.statusCode == 201 || res.statusCode == 200) {
                    final coursList = _asListOfMap(_localExtraInfo);
                    for (final c in coursList) {
                      if (c['id'] == coursId) {
                        final List sec = (c['enseignants_secondaires'] as List?) ?? [];
                        final added = _enseignantsSecondaires
                            .firstWhere((e) => e['id'] == enseignantId, orElse: () => {'id': enseignantId});
                        sec.add(added);
                        c['enseignants_secondaires'] = sec;
                        break;
                      }
                    }
                    setState(() {});
                    if (context.mounted) Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ajouté.')));
                  } else {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text('Erreur (${res.statusCode})')));
                  }
                },
                child: const Text('Ajouter'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _retirerEnseignantSecondaire(int coursId, int enseignantId) async {
    try {
      final headers = await _authHeaders();
      final res = await http.delete(
        Uri.parse('$baseUrl/api/cours/$coursId/enseignants-secondaires/$enseignantId/'),
        headers: headers,
      );
      if (res.statusCode == 204 || res.statusCode == 200) {
        final coursList = _asListOfMap(_localExtraInfo);
        for (final c in coursList) {
          if (c['id'] == coursId) {
            final List sec = (c['enseignants_secondaires'] as List?) ?? [];
            sec.removeWhere((e) => (e is Map ? e['id'] : e) == enseignantId);
            c['enseignants_secondaires'] = sec;
            break;
          }
        }
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Retiré.')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  // State local (copie éditable de extraInfo) ----------------------------------
  late final List<dynamic> _localExtraInfo = List<dynamic>.from(widget.extraInfo ?? const []);

  // UI -------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: YekiHeader(
        unreadNotifications: 3,
        isSubscribed: isSubscribed,
        userRole: widget.roleEnseignant,
        username: widget.nomEnseignant,
        avatarUrl: null,
        onNotifications: () {},
        onSettings: () {},
        onLogout: () {},
      ),
      floatingActionButton: widget.role == RoleEnseignant.enseignantCadre
      ? FloatingActionButton.extended(
          icon: const Icon(Icons.add),
          label: const Text("Créer un cours"),
          onPressed: _ouvrirFormulaireCreationCours,
        )
      : null,

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _buildByRole(),
      ),
    );
  }

  Widget _buildByRole() {
  switch (widget.role) {
    case RoleEnseignant.enseignantCadre:
      return _uiCadre();
    case RoleEnseignant.enseignantPrincipal:
      return _uiPrincipal();
    case RoleEnseignant.enseignantSecondaire:
      return _uiEnseignantSimple();
    default:
      return const Center(child: Text("Interface non prévue pour ce rôle."));
  }
}

  Widget _uiEnseignantSimple() {
  final cours = _asListOfMap(_localExtraInfo);
  return ListView(
    children: [
      const Text('Mes cours assignés',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      const SizedBox(height: 12),
      if (cours.isEmpty)
        const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text('Aucun cours assigné pour le moment'),
          ),
        ),
      ...cours.map((c) {
        final int leconsCount = (c['lecons_count'] as int?) ??
            ((c['lecons'] is List) ? (c['lecons'] as List).length : 0);
        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: const Icon(Icons.book_outlined, color: Colors.indigo),
            title: Text(c['titre']?.toString() ?? ''),
            subtitle: Text('Leçons: $leconsCount'),
            onTap: () {
              /*Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => InterfaceEnseignantPage(cours: c),
                ),
              );*/
            },
          ),
        );
      }),
    ],
  );
}

  // UI Cadre -------------------------------------------------------------------
  Widget _uiCadre() {
    final deps = _asListOfMap(_localExtraInfo);
    return ListView(
      children: [

        // Liste départements + cours
        const Text('Mes départements', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...deps.map((d) {
          final List<Map<String, dynamic>> cours =
              _asListOfMap((d['cours'] as List?) ?? const []);
          return Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ExpansionTile(
              title: Text('🏫 ${d['nom'] ?? ''}'),
              children: cours.isEmpty
                  ? [const ListTile(title: Text('Aucun cours'))]
                  : cours
                      .map((c) => ListTile(
                            title: Text(c['titre']?.toString() ?? ''),
                            subtitle: Text(
                              'Principal: ${((c['enseignant_principal'] as Map?)?['user']['username']?.toString() ?? 'Aucun')}',
                            ),
                            trailing: PopupMenuButton<int>(
                              icon: const Icon(Icons.edit),
                              itemBuilder: (context) => _enseignantsPrincipaux
                                  .map((e) => PopupMenuItem<int>(
                                        value: e['id'] as int,
                                        child: Text(e['name']?.toString() ?? ''),
                                      ))
                                  .toList(),
                              onSelected: (id) => _modifierPrincipal(c['id'] as int, id),
                            ),
                          ))
                      .toList(),
            ),
          );
        }),
      ],
    );
  }

  // UI Principal ---------------------------------------------------------------
  Widget _uiPrincipal() {
    final cours = _asListOfMap(_localExtraInfo);
    return ListView(
      children: [
        const Text('Mes cours', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (cours.isEmpty)
          const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('Aucun cours'))),
        ...cours.map((c) {
          final int leconsCount = (c['lecons_count'] as int?) ??
              ((c['lecons'] is List) ? (c['lecons'] as List).length : 0);
          final secondaires = _asListOfMap((c['enseignants_secondaires'] as List?) ?? const []);
          return Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('📘 ${c['titre'] ?? ''}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Text('Leçons: $leconsCount'),
                const Divider(),
                const Text('👥 Enseignants secondaires',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                if (secondaires.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('Aucun enseignant secondaire'),
                  ),
                ...secondaires.map((e) => ListTile(
                      dense: true,
                      leading: const Icon(Icons.person_outline),
                      title: Text(e['name']?.toString() ?? ''),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () =>
                            _retirerEnseignantSecondaire(c['id'] as int, e['id'] as int),
                      ),
                    )),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => _ajouterEnseignantSecondaire(c['id'] as int),
                    icon: const Icon(Icons.person_add),
                    label: const Text('Ajouter un enseignant secondaire'),
                  ),
                ),
                const Divider(),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.view_module),
                        label: const Text("Créer un module"),
                        onPressed: () => _ouvrirFormulaireAjoutModule(c['id'] as int),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.add_circle),
                        label: const Text("Ajouter une leçon"),
                        onPressed: () {
                          _ouvrirFormulaireAjoutLecon(c['id'] as int);
                        },
                      ),
                    ),
                  ],
                ),
              ]),
            ),
          );
        }),
      ],
    );
  }
}
