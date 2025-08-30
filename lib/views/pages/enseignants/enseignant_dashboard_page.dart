import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yeki/views/pages/enseignants/interface_enseignant_page.dart';


class DashboardEnseignantPage extends StatefulWidget {
  final RoleEnseignant role;
  final String nomEnseignant;

  /// Données minimales:
  /// - role Cadre  -> List<Departement> : [{id, nom, cours:[{id, titre, enseignant_principal:{id, name}?}]}]
  /// - role Principal -> List<Cours> : [{id, titre, lecons_count? (int), enseignants_secondaires:[{id, name}]}]
  final List<dynamic>? extraInfo;

  const DashboardEnseignantPage({
    super.key,
    required this.role,
    required this.nomEnseignant,
    this.extraInfo,
  });

  @override
  State<DashboardEnseignantPage> createState() => _DashboardEnseignantPageState();
}

class _DashboardEnseignantPageState extends State<DashboardEnseignantPage> {
  static const String baseUrl = 'https://yekiapp.pythonanywhere.com';
  bool _creatingCourse = false;
  final TextEditingController _titreCoursCtrl = TextEditingController();
  final TextEditingController _niveauCtrl = TextEditingController();
  int? _depSelectionneId;
  int? _principalSelectionneId;

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

  // Fetch lists for pickers ----------------------------------------------------
  Future<void> _fetchEnseignantsPrincipaux() async {
    try {
      final headers = await _authHeaders();
      final res = await http.get(Uri.parse('$baseUrl/api/enseignants/'), headers: headers);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        setState(() {
          _enseignantsPrincipaux = _asListOfMap(body);
        });
      }
    } catch (_) {}
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
        if (_principalSelectionneId != null) 'enseignant_principal': _principalSelectionneId,
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
  final Set<int> _addingLessonFor = {};
  Future<void> _ajouterLecon(int coursId) async {
    final ctrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Ajouter une leçon'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Titre de la leçon'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          StatefulBuilder(
            builder: (context, setSB) => ElevatedButton(
              onPressed: _addingLessonFor.contains(coursId)
                  ? null
                  : () async {
                      final titre = ctrl.text.trim();
                      if (titre.isEmpty) return;
                      setState(() => _addingLessonFor.add(coursId));
                      try {
                        final headers = await _authHeaders();
                        final res = await http.post(
                          Uri.parse('$baseUrl/api/cours/$coursId/lessons/'),
                          headers: headers,
                          body: jsonEncode({'titre': titre}),
                        );
                        if (res.statusCode == 201) {
                          // incrémente localement le compteur si présent
                          final cours = _asListOfMap(_localExtraInfo);
                          for (final c in cours) {
                            if (c['id'] == coursId) {
                              final current = (c['lecons_count'] as int?) ?? 0;
                              c['lecons_count'] = current + 1;
                              break;
                            }
                          }
                          setState(() {});
                          if (context.mounted) Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Leçon ajoutée.')),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Erreur (${res.statusCode})')),
                          );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
                      } finally {
                        setState(() => _addingLessonFor.remove(coursId));
                      }
                    },
              child: _addingLessonFor.contains(coursId)
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Ajouter'),
            ),
          ),
        ],
      ),
    );
  }

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
                    .map((e) => DropdownMenuItem<int>(value: e['id'] as int, child: Text(e['name']?.toString() ?? '')))
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
                    Uri.parse('$baseUrl/api/cours/$coursId/enseignants-secondaires/'),
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
      appBar: AppBar(
        title: Text('Bienvenue ${widget.nomEnseignant}'),
        backgroundColor: Colors.indigo,
      ),
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
        // Formulaire création cours
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Créer un cours', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              TextField(
                controller: _titreCoursCtrl,
                decoration: const InputDecoration(labelText: 'Titre du cours', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _niveauCtrl,
                decoration: const InputDecoration(labelText: 'Niveau', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: _depSelectionneId,
                items: deps
                    .map((d) => DropdownMenuItem<int>(value: d['id'] as int, child: Text(d['nom']?.toString() ?? '')))
                    .toList(),
                onChanged: (v) => setState(() => _depSelectionneId = v),
                decoration:
                    const InputDecoration(labelText: 'Département', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: _principalSelectionneId,
                items: _enseignantsPrincipaux
                    .map((e) => DropdownMenuItem<int>(
                          value: e['id'] as int,
                          child: Text(e['name']?.toString() ?? ''),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _principalSelectionneId = v),
                decoration: const InputDecoration(
                    labelText: 'Enseignant principal (optionnel)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: _creatingCourse
                      ? const SizedBox(
                          height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.add),
                  onPressed: _creatingCourse ? null : _creerCours,
                  label: const Text('Créer'),
                ),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 16),

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
                              'Principal: ${((c['enseignant_principal'] as Map?)?['name']?.toString() ?? 'Aucun')}',
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
                Row(
                  children: [
                    Expanded(child: Text('Leçons: $leconsCount')),
                    TextButton.icon(
                      onPressed: () => _ajouterLecon(c['id'] as int),
                      icon: const Icon(Icons.add_circle),
                      label: const Text('Ajouter une leçon'),
                    ),
                  ],
                ),
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
                )
              ]),
            ),
          );
        }),
      ],
    );
  }
}
