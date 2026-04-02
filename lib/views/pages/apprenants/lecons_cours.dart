// lib/views/pages/apprenants/lecons_cours.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:yeki/views/pages/apprenants/detail_lecon_page.dart';
import 'package:yeki/views/pages/enseignants/interface_enseignant_page.dart';
import 'package:yeki/views/pages/apprenants/lecture_lecon_page.dart';

const String _baseUrl = 'https://yeki.pythonanywhere.com/api';
const Color _primary = Color(0xFF2884A0);

class LeconsCoursPage extends StatefulWidget {
  final String coursId;
  final String coursTitre;
  final RoleEnseignant? role;
  final TabController tabController;
  final void Function(int questionId)? onNaviguerForum;
  final bool isPremium;

  const LeconsCoursPage({
    super.key,
    required this.coursId,
    required this.coursTitre,
    this.role,
    required this.tabController,
    this.onNaviguerForum,
    this.isPremium = false,
  });

  @override
  State<LeconsCoursPage> createState() => _LeconsCoursPageState();
}

class _LeconsCoursPageState extends State<LeconsCoursPage> {
  bool loading = true;
  List<dynamic> modules = [];

  bool get _canEdit =>
      widget.role == RoleEnseignant.enseignantCadre ||
      widget.role == RoleEnseignant.enseignantPrincipal;

  @override
  void initState() {
    super.initState();
    fetchLecons();
  }

  Future<String?> _getToken() async =>
      (await SharedPreferences.getInstance()).getString('token');

  Future<Map<String, String>> _authHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Token $token',
    };
  }

  Future<void> fetchLecons() async {
    setState(() => loading = true);
    final token = await _getToken();
    if (token == null) {
      setState(() => loading = false);
      return;
    }

    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/cours/${widget.coursId}/liste-modules/'),
        headers: {'Authorization': 'Token $token'},
      );

      if (res.statusCode == 200) {
        setState(() {
          modules = jsonDecode(res.body) as List;
          loading = false;
        });
      } else {
        setState(() => loading = false);
        _showError('Erreur ${res.statusCode}');
      }
    } catch (e) {
      setState(() => loading = false);
      _showError('Erreur réseau : $e');
    }
  }

  Future<void> _createModule(String titre, String desc, int ordre) async {
    final headers = await _authHeaders();
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/cours/${widget.coursId}/modules/'),
        headers: headers,
        body: jsonEncode({'titre': titre, 'description': desc, 'ordre': ordre}),
      );
      if (res.statusCode == 201) {
        _showSuccess('Module créé !');
        fetchLecons();
      } else {
        final e = jsonDecode(res.body);
        _showError(e['detail'] ?? 'Erreur');
      }
    } catch (_) {
      _showError('Erreur réseau.');
    }
  }

  Future<void> _updateModule(int id, String titre, String desc, int ordre) async {
    final headers = await _authHeaders();
    try {
      final res = await http.patch(
        Uri.parse('$_baseUrl/modules/$id/modifier/'),
        headers: headers,
        body: jsonEncode({'titre': titre, 'description': desc, 'ordre': ordre}),
      );
      if (res.statusCode == 200) {
        _showSuccess('Module modifié !');
        fetchLecons();
      } else {
        final e = jsonDecode(res.body);
        _showError(e['detail'] ?? 'Erreur');
      }
    } catch (_) {
      _showError('Erreur réseau.');
    }
  }

  Future<void> _deleteModule(int id) async {
    if (await _confirm('Supprimer ce module ?', 'Toutes les leçons liées seront supprimées.') != true)
      return;

    final headers = await _authHeaders();
    try {
      final res = await http.delete(
        Uri.parse('$_baseUrl/modules/$id/supprimer/'),
        headers: headers,
      );
      if (res.statusCode == 204 || res.statusCode == 200) {
        _showSuccess('Module supprimé.');
        fetchLecons();
      } else {
        _showError('Erreur suppression.');
      }
    } catch (_) {
      _showError('Erreur réseau.');
    }
  }

  Future<void> _createLecon({
    required String moduleId,
    required String titre,
    required String description,
    PlatformFile? pdfFile,
    PlatformFile? videoFile,
  }) async {
    final token = await _getToken();
    if (token == null) return;

    try {
      final req = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/cours/${widget.coursId}/lecons/'),
      );
      req.headers['Authorization'] = 'Token $token';
      req.fields['titre'] = titre;
      req.fields['description'] = description;
      req.fields['module'] = moduleId;

      if (pdfFile?.path != null) {
        req.files.add(await http.MultipartFile.fromPath(
          'fichier_pdf', pdfFile!.path!,
          contentType: MediaType('application', 'pdf'),
        ));
      }
      if (videoFile?.path != null) {
        req.files.add(await http.MultipartFile.fromPath(
          'video', videoFile!.path!,
          contentType: MediaType('video', 'mp4'),
        ));
      }

      final res = await http.Response.fromStream(await req.send());
      if (res.statusCode == 201) {
        _showSuccess('Leçon publiée !');
        fetchLecons();
      } else {
        final e = jsonDecode(res.body);
        _showError(e['detail'] ?? e.toString());
      }
    } catch (e) {
      _showError('Erreur réseau : $e');
    }
  }

  Future<void> _updateLecon({
    required int leconId,
    required String titre,
    required String description,
    PlatformFile? newPdfFile,
    PlatformFile? newVideoFile,
    String? newModuleId,
  }) async {
    final token = await _getToken();
    if (token == null) return;

    try {
      final req = http.MultipartRequest(
        'PATCH',
        Uri.parse('$_baseUrl/lecons/$leconId/modifier/'),
      );
      req.headers['Authorization'] = 'Token $token';
      req.fields['titre'] = titre;
      req.fields['description'] = description;
      if (newModuleId != null) req.fields['module'] = newModuleId;

      if (newPdfFile?.path != null) {
        req.files.add(await http.MultipartFile.fromPath(
          'fichier_pdf', newPdfFile!.path!,
          contentType: MediaType('application', 'pdf'),
        ));
      }
      if (newVideoFile?.path != null) {
        req.files.add(await http.MultipartFile.fromPath(
          'video', newVideoFile!.path!,
          contentType: MediaType('video', 'mp4'),
        ));
      }

      final res = await http.Response.fromStream(await req.send());
      if (res.statusCode == 200) {
        _showSuccess('Leçon modifiée !');
        fetchLecons();
      } else {
        final e = jsonDecode(res.body);
        _showError(e['detail'] ?? e.toString());
      }
    } catch (e) {
      _showError('Erreur réseau : $e');
    }
  }

  Future<void> _deleteLecon(int id) async {
    if (await _confirm('Supprimer cette leçon ?', 'Action irréversible.') != true) return;

    final headers = await _authHeaders();
    try {
      final res = await http.delete(
        Uri.parse('$_baseUrl/lecons/$id/supprimer/'),
        headers: headers,
      );
      if (res.statusCode == 204 || res.statusCode == 200) {
        _showSuccess('Leçon supprimée.');
        fetchLecons();
      } else {
        _showError('Erreur suppression.');
      }
    } catch (_) {
      _showError('Erreur réseau.');
    }
  }

  int _numeroGlobal(String leconId) {
    int num = 1;
    for (final m in modules) {
      for (final l in (m['lecons'] as List? ?? [])) {
        if (l['id']?.toString() == leconId) return num;
        num++;
      }
    }
    return num;
  }

  // lib/views/pages/apprenants/lecons_cours.dart
// Modifier la méthode _ouvrirLecon

void _ouvrirLecon(Map leconMap) {
  final leconId = leconMap['id'] as int;
  final coursId = int.tryParse(widget.coursId) ?? 0;
  if (coursId == 0) return;
  
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => DetailLeconPage(
        leconId: leconId,
        coursId: coursId,
        coursTitre: widget.coursTitre,
      ),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator(color: _primary));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Sommaire du cours',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _primary,
                ),
              ),
              if (_canEdit)
                ElevatedButton.icon(
                  onPressed: () => _showModuleDialog(),
                  icon: const Icon(Icons.add, size: 18, color: Colors.white),
                  label: const Text('Module',
                      style: TextStyle(color: Colors.white, fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    elevation: 0,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          if (modules.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 60),
                child: Column(
                  children: [
                    Icon(Icons.folder_open, size: 60, color: Colors.grey.shade300),
                    const SizedBox(height: 12),
                    Text('Aucun module disponible.',
                        style: TextStyle(color: Colors.grey.shade500)),
                    if (_canEdit) ...[
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => _showModuleDialog(),
                        icon: const Icon(Icons.add, color: Colors.white),
                        label: const Text('Créer le premier module',
                            style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            )
          else
            ...modules.map((m) => _buildModuleBlock(m)),
        ],
      ),
    );
  }

  Widget _buildModuleBlock(Map module) {
    final List lecons = module['lecons'] ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                module['titre'] ?? '',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ),
            if (_canEdit) ...[
              IconButton(
                icon: Icon(Icons.edit_outlined, color: Colors.grey.shade500, size: 18),
                tooltip: 'Modifier le module',
                onPressed: () => _showModuleDialog(existingModule: module),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, color: _primary, size: 20),
                tooltip: 'Ajouter une leçon',
                onPressed: () => _showLeconDialog(moduleId: module['id'].toString()),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                tooltip: 'Supprimer le module',
                onPressed: () => _deleteModule(module['id'] as int),
              ),
            ],
          ],
        ),
        if ((module['description'] ?? '').isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(module['description'],
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
          ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
            ],
          ),
          child: lecons.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: Colors.grey.shade400),
                      const SizedBox(width: 8),
                      Text('Aucune leçon dans ce module.',
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
                    ],
                  ),
                )
              : Column(
                  children: lecons.asMap().entries.map((entry) {
                    final globalNum = _numeroGlobal(entry.value['id']?.toString() ?? '');
                    return _buildLeconTile(
                      entry.value,
                      globalNum,
                      module['id'].toString(),
                    );
                  }).toList(),
                ),
        ),
        const SizedBox(height: 25),
      ],
    );
  }

  Widget _buildLeconTile(Map lecon, int numero, String moduleId) {
    final hasPdf = lecon['fichier_pdf'] != null && lecon['fichier_pdf'] != '';
    final hasVideo = lecon['video'] != null && lecon['video'] != '';

    return InkWell(
      onTap: () => _ouvrirLecon(lecon),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 4),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: _primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$numero',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lecon['titre'] ?? 'Sans titre',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3142),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lecon['description'] ?? 'Aucune description.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (hasPdf) _badge(Icons.picture_as_pdf, 'PDF', Colors.red),
                      if (hasVideo) _badge(Icons.videocam, 'Vidéo', Colors.blue),
                    ],
                  ),
                ],
              ),
            ),
            if (_canEdit)
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, size: 18, color: Colors.grey.shade400),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                onSelected: (val) {
                  if (val == 'edit') {
                    _showLeconDialog(moduleId: moduleId, existingLecon: lecon);
                  } else if (val == 'delete') {
                    _deleteLecon(lecon['id'] as int);
                  } else if (val == 'open') {
                    _ouvrirLecon(lecon);
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'open',
                    child: Row(children: [
                      Icon(Icons.open_in_new, size: 16, color: _primary),
                      SizedBox(width: 8),
                      Text('Ouvrir'),
                    ]),
                  ),
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(children: [
                      Icon(Icons.edit_outlined, size: 16, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('Modifier'),
                    ]),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(children: [
                      Icon(Icons.delete_outline, size: 16, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Supprimer'),
                    ]),
                  ),
                ],
              )
            else
              IconButton(
                icon: const Icon(
                  Icons.play_circle_outline,
                  color: Color(0xFF008088),
                  size: 28,
                ),
                onPressed: () => _ouvrirLecon(lecon),
              ),
          ],
        ),
      ),
    );
  }

  void _showModuleDialog({Map? existingModule}) {
    final isEdit = existingModule != null;
    final titreCtrl = TextEditingController(text: isEdit ? existingModule['titre'] ?? '' : '');
    final descCtrl = TextEditingController(text: isEdit ? existingModule['description'] ?? '' : '');
    final ordreCtrl = TextEditingController(
        text: isEdit ? existingModule['ordre'].toString() : (modules.length + 1).toString());
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          padding: EdgeInsets.only(
            left: 25, right: 25, top: 15,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _sheetHandle(),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isEdit ? Icons.edit_note : Icons.add_box_outlined,
                      color: _primary, size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isEdit ? 'Modifier le module' : 'Nouveau module',
                    style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _field(titreCtrl, 'Titre du module', Icons.title, 'Ex: Algèbre linéaire'),
              const SizedBox(height: 14),
              _field(descCtrl, 'Description', Icons.description_outlined,
                  'Objectifs du module', maxLines: 2),
              const SizedBox(height: 14),
              _field(ordreCtrl, 'Position (ordre)', Icons.sort, '', isNumber: true),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity, height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 0,
                  ),
                  onPressed: isLoading ? null : () async {
                    if (titreCtrl.text.trim().isEmpty) {
                      _showError('Le titre est requis.'); return;
                    }
                    final ordre = int.tryParse(ordreCtrl.text.trim()) ?? 1;
                    setS(() => isLoading = true);
                    Navigator.pop(ctx);
                    if (isEdit) {
                      await _updateModule(
                        existingModule['id'] as int,
                        titreCtrl.text.trim(), descCtrl.text.trim(), ordre,
                      );
                    } else {
                      await _createModule(
                        titreCtrl.text.trim(), descCtrl.text.trim(), ordre,
                      );
                    }
                    setS(() => isLoading = false);
                  },
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          isEdit ? 'Enregistrer les modifications' : 'Créer le module',
                          style: const TextStyle(
                            color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLeconDialog({required String moduleId, Map? existingLecon}) {
    final isEdit = existingLecon != null;
    final titreCtrl = TextEditingController(text: isEdit ? existingLecon['titre'] ?? '' : '');
    final descCtrl = TextEditingController(text: isEdit ? existingLecon['description'] ?? '' : '');
    PlatformFile? selectedPdf;
    PlatformFile? selectedVideo;
    String? currentPdfName = isEdit && existingLecon['fichier_pdf'] != null ? 'PDF actuel' : null;
    String? currentVideoName = isEdit && existingLecon['video'] != null ? 'Vidéo actuelle' : null;
    String selectedModuleId = moduleId;
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          padding: EdgeInsets.only(
            left: 25, right: 25, top: 15,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _sheetHandle(),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isEdit ? Icons.edit : Icons.menu_book_outlined,
                        color: Colors.blueAccent, size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      isEdit ? 'Modifier la leçon' : 'Ajouter une leçon',
                      style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _field(titreCtrl, 'Titre de la leçon', Icons.menu_book, 'Ex: Chapitre 1 : Introduction'),
                const SizedBox(height: 14),
                _field(descCtrl, 'Résumé / Description', Icons.short_text,
                    'De quoi parle cette leçon ?', maxLines: 3),
                const SizedBox(height: 14),
                if (isEdit && modules.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: selectedModuleId,
                        icon: const Icon(Icons.keyboard_arrow_down, color: _primary),
                        items: modules.map<DropdownMenuItem<String>>((m) {
                          return DropdownMenuItem<String>(
                            value: m['id'].toString(),
                            child: Row(
                              children: [
                                const Icon(Icons.folder_outlined, size: 18, color: _primary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    m['titre'] ?? 'Module ${m['id']}',
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setS(() => selectedModuleId = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                InkWell(
                  onTap: () async {
                    final result = await FilePicker.platform.pickFiles(
                      type: FileType.custom, allowedExtensions: ['pdf'],
                    );
                    if (result != null) {
                      setS(() { selectedPdf = result.files.single; currentPdfName = null; });
                    }
                  },
                  borderRadius: BorderRadius.circular(15),
                  child: Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: _primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: selectedPdf != null ? _primary : _primary.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.picture_as_pdf,
                            color: selectedPdf != null ? _primary : Colors.grey.shade400),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                selectedPdf != null
                                    ? selectedPdf!.name
                                    : (currentPdfName ?? 'Joindre le support PDF'),
                                style: TextStyle(
                                  color: selectedPdf != null ? _primary : Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (currentPdfName != null && selectedPdf == null)
                                const Text('Cliquez pour remplacer le PDF existant',
                                    style: TextStyle(fontSize: 10, color: Colors.grey)),
                            ],
                          ),
                        ),
                        if (selectedPdf != null)
                          Icon(Icons.check_circle, color: _primary, size: 20)
                        else if (currentPdfName != null)
                          Icon(Icons.description, color: Colors.green.shade400, size: 20)
                        else
                          Icon(Icons.upload_file, color: Colors.grey.shade400, size: 20),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text('Seuls les fichiers PDF sont acceptés.',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                const SizedBox(height: 14),
                InkWell(
                  onTap: () async {
                    final result = await FilePicker.platform.pickFiles(
                      type: FileType.custom,
                      allowedExtensions: ['mp4', 'mov', 'avi', 'mkv', 'webm'],
                    );
                    if (result != null) {
                      setS(() { selectedVideo = result.files.single; currentVideoName = null; });
                    }
                  },
                  borderRadius: BorderRadius.circular(15),
                  child: Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: selectedVideo != null ? Colors.blueAccent : Colors.blue.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.videocam_outlined,
                            color: selectedVideo != null ? Colors.blueAccent : Colors.grey.shade400),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                selectedVideo != null
                                    ? selectedVideo!.name
                                    : (currentVideoName ?? 'Joindre une vidéo (optionnel)'),
                                style: TextStyle(
                                  color: selectedVideo != null ? Colors.blueAccent : Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (currentVideoName != null && selectedVideo == null)
                                const Text('Cliquez pour remplacer la vidéo existante',
                                    style: TextStyle(fontSize: 10, color: Colors.grey)),
                            ],
                          ),
                        ),
                        if (selectedVideo != null)
                          const Icon(Icons.check_circle, color: Colors.blueAccent, size: 20)
                        else if (currentVideoName != null)
                          Icon(Icons.videocam, color: Colors.green.shade400, size: 20)
                        else
                          Icon(Icons.upload, color: Colors.grey.shade400, size: 20),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text('Formats acceptés : MP4, MOV, AVI, MKV, WEBM.',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity, height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      elevation: 0,
                    ),
                    onPressed: isLoading ? null : () async {
                      if (titreCtrl.text.trim().isEmpty) {
                        _showError('Le titre est requis.'); return;
                      }
                      setS(() => isLoading = true);
                      Navigator.pop(ctx);
                      if (isEdit) {
                        await _updateLecon(
                          leconId: existingLecon['id'] as int,
                          titre: titreCtrl.text.trim(),
                          description: descCtrl.text.trim(),
                          newPdfFile: selectedPdf,
                          newVideoFile: selectedVideo,
                          newModuleId: selectedModuleId,
                        );
                      } else {
                        await _createLecon(
                          moduleId: moduleId,
                          titre: titreCtrl.text.trim(),
                          description: descCtrl.text.trim(),
                          pdfFile: selectedPdf,
                          videoFile: selectedVideo,
                        );
                      }
                      setS(() => isLoading = false);
                    },
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            isEdit ? 'Enregistrer les modifications' : 'Publier la leçon',
                            style: const TextStyle(
                              color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<bool?> _confirm(String title, String content) => showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );

  Widget _badge(IconData icon, String text, Color color) => Container(
    margin: const EdgeInsets.only(right: 6),
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 10, color: color),
        const SizedBox(width: 3),
        Text(text, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
      ],
    ),
  );

  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon,
    String hint, {
    int maxLines = 1,
    bool isNumber = false,
  }) =>
      TextField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: _primary, size: 20),
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: _primary),
          ),
        ),
      );

  Widget _sheetHandle() => Center(
    child: Container(
      width: 40, height: 4,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(10),
      ),
    ),
  );

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  void _showSuccess(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green));
  }
}