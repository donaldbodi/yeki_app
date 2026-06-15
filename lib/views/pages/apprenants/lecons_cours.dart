// lib/views/pages/apprenants/lecons_cours.dart
// ═══════════════════════════════════════════════════════════════
//  YEKI LEÇONS — Design Unifié Premium
// ═══════════════════════════════════════════════════════════════

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:yeki/views/pages/apprenants/detail_lecon_page.dart';
import 'package:yeki/views/pages/enseignants/interface_enseignant_page.dart';

const String _baseUrl = 'https://yeki.pythonanywhere.com/api';

// Palette unifiée
const Color brandPrimary = Color(0xFF2884A0);
const Color brandGold = Color(0xFFFF6B00);
const Color _textDark = Color(0xFF1E293B);
const Color _textMedium = Color(0xFF5A5C5E);
const Color _textLight = Color(0xFF94A3B8);
const Color _borderLight = Color(0xFFE2E8F0);
const Color _bgLight = Color(0xFFF8FAFC);
const Color _white = Color(0xFFFFFFFF);
const Color _green = Color(0xFF10B981);
const Color _red = Color(0xFFEF4444);
const Color _blue = Color(0xFF3B82F6);

class LeconsCoursPage extends StatefulWidget {
  final String coursId;
  final String coursTitre;
  final RoleEnseignant? role;
  final TabController tabController;
  final void Function(int questionId)? onNaviguerForum;
  final bool isPremium;
  final Color courseColor;

  const LeconsCoursPage({
    super.key,
    required this.coursId,
    required this.coursTitre,
    this.role,
    required this.tabController,
    this.onNaviguerForum,
    this.isPremium = false,
    required this.courseColor,
  });

  @override
  State<LeconsCoursPage> createState() => _LeconsCoursPageState();
}

class _LeconsCoursPageState extends State<LeconsCoursPage>
    with SingleTickerProviderStateMixin {
  bool loading = true;
  List<dynamic> modules = [];

  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;

  bool get _canEdit =>
      widget.role == RoleEnseignant.enseignantCadre ||
      widget.role == RoleEnseignant.enseignantPrincipal;

  @override
  void initState() {
    super.initState();

    // ✅ CORRECTION : Initialisation immédiate avec late final
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: Curves.easeOutCubic,
    );
    // ✅ CORRECTION : Définir la valeur initiale à 1.0
    _animCtrl.value = 1.0;

    // ✅ CORRECTION : Différer le chargement après le premier rendu
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchLecons();
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
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
        if (mounted) {
          setState(() {
            modules = jsonDecode(res.body) as List;
            loading = false;
          });
          // ✅ CORRECTION : Redémarrer l'animation depuis 0
          _animCtrl.forward(from: 0.0);
        }
      } else {
        if (mounted) {
          setState(() => loading = false);
          _showError('Erreur ${res.statusCode}');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => loading = false);
        _showError('Erreur réseau');
      }
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
        _showError('Erreur lors de la création');
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
        _showError('Erreur lors de la modification');
      }
    } catch (_) {
      _showError('Erreur réseau.');
    }
  }

  Future<void> _deleteModule(int id) async {
    if (await _confirm('Supprimer ce module ?',
            'Toutes les leçons liées seront supprimées.') !=
        true) return;

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
          'fichier_pdf',
          pdfFile!.path!,
          contentType: MediaType('application', 'pdf'),
        ));
      }
      if (videoFile?.path != null) {
        req.files.add(await http.MultipartFile.fromPath(
          'video',
          videoFile!.path!,
          contentType: MediaType('video', 'mp4'),
        ));
      }

      final res = await http.Response.fromStream(await req.send());
      if (res.statusCode == 201) {
        _showSuccess('Leçon publiée !');
        fetchLecons();
      } else {
        _showError('Erreur lors de la publication');
      }
    } catch (e) {
      _showError('Erreur réseau');
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
          'fichier_pdf',
          newPdfFile!.path!,
          contentType: MediaType('application', 'pdf'),
        ));
      }
      if (newVideoFile?.path != null) {
        req.files.add(await http.MultipartFile.fromPath(
          'video',
          newVideoFile!.path!,
          contentType: MediaType('video', 'mp4'),
        ));
      }

      final res = await http.Response.fromStream(await req.send());
      if (res.statusCode == 200) {
        _showSuccess('Leçon modifiée !');
        fetchLecons();
      } else {
        _showError('Erreur lors de la modification');
      }
    } catch (e) {
      _showError('Erreur réseau');
    }
  }

  Future<void> _deleteLecon(int id) async {
    if (await _confirm('Supprimer cette leçon ?', 'Action irréversible.') !=
        true) return;

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
          coursColor: widget.courseColor.value,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double padX = screenWidth > 800 ? (screenWidth - 760) / 2 : 20.0;

    if (loading) {
      return Center(
        child: CircularProgressIndicator(color: widget.courseColor),
      );
    }

    return FadeTransition(
      opacity: _fadeAnim,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(padX, 20, padX, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ═══ EN-TÊTE ═══
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: widget.courseColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.menu_book_rounded,
                          color: widget.courseColor, size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Sommaire du cours',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: _textDark,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
                if (_canEdit)
                  Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: widget.courseColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _showModuleDialog(),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add, size: 16, color: _white),
                            SizedBox(width: 6),
                            Text(
                              'Module',
                              style: TextStyle(
                                color: _white,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 24),

            // ═══ CONTENU ═══
            if (modules.isEmpty)
              _buildEmptyState()
            else
              ...modules.map((m) => _buildModuleBlock(m)),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  ÉTAT VIDE
  // ═══════════════════════════════════════════════════════════
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: widget.courseColor.withOpacity(0.06),
                shape: BoxShape.circle,
                border: Border.all(
                    color: widget.courseColor.withOpacity(0.12), width: 1),
              ),
              child:
                  Icon(Icons.folder_open, size: 48, color: _textLight),
            ),
            const SizedBox(height: 16),
            const Text(
              'Aucun module disponible.',
              style: TextStyle(
                  color: _textMedium,
                  fontSize: 15,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              'Créez votre premier module pour commencer.',
              style: TextStyle(color: _textLight, fontSize: 13),
            ),
            if (_canEdit) ...[
              const SizedBox(height: 24),
              Container(
                height: 42,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: widget.courseColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _showModuleDialog(),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add, size: 16, color: _white),
                        SizedBox(width: 6),
                        Text(
                          'Créer le premier module',
                          style: TextStyle(
                            color: _white,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  BLOC MODULE (Design Unifié)
  // ═══════════════════════════════════════════════════════════
  Widget _buildModuleBlock(Map module) {
    final List lecons = module['lecons'] ?? [];
    final String moduleTitre = module['titre'] ?? '';
    final String moduleDesc = module['description'] ?? '';
    final int moduleId = module['id'] as int;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _borderLight, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: brandPrimary.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ═══ EN-TÊTE DU MODULE ═══
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
            decoration: BoxDecoration(
              color: widget.courseColor.withOpacity(0.04),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(22)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: widget.courseColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.folder_rounded,
                      color: widget.courseColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        moduleTitre,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: _textDark,
                          letterSpacing: -0.2,
                        ),
                      ),
                      if (moduleDesc.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Text(
                            moduleDesc,
                            style: const TextStyle(
                              fontSize: 12,
                              color: _textMedium,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
                // Compteur de leçons
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.courseColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${lecons.length} leçon${lecons.length > 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: widget.courseColor,
                    ),
                  ),
                ),
                if (_canEdit) ...[
                  const SizedBox(width: 4),
                  _iconBtn(
                    icon: Icons.edit_outlined,
                    color: _textLight,
                    onTap: () =>
                        _showModuleDialog(existingModule: module),
                  ),
                  _iconBtn(
                    icon: Icons.add_circle_outline,
                    color: widget.courseColor,
                    onTap: () => _showLeconDialog(
                        moduleId: moduleId.toString()),
                  ),
                  _iconBtn(
                    icon: Icons.delete_outline,
                    color: _red,
                    onTap: () => _deleteModule(moduleId),
                  ),
                ],
              ],
            ),
          ),

          // ═══ LISTE DES LEÇONS ═══
          if (lecons.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info_outline, size: 16, color: _textLight),
                  const SizedBox(width: 8),
                  Text(
                    'Aucune leçon dans ce module.',
                    style: TextStyle(color: _textLight, fontSize: 13),
                  ),
                ],
              ),
            )
          else
            Column(
              children: lecons.asMap().entries.map((entry) {
                final globalNum =
                    _numeroGlobal(entry.value['id']?.toString() ?? '');
                return _buildLeconTile(
                  entry.value,
                  globalNum,
                  moduleId.toString(),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  TUILE LEÇON (Design Unifié)
  // ═══════════════════════════════════════════════════════════
  Widget _buildLeconTile(Map lecon, int numero, String moduleId) {
    final hasPdf =
        lecon['fichier_pdf'] != null && lecon['fichier_pdf'] != '';
    final hasVideo = lecon['video'] != null && lecon['video'] != '';
    final leconId = lecon['id'] as int;
    final leconTitre = lecon['titre'] ?? 'Sans titre';
    final leconDesc = lecon['description'] ?? 'Aucune description.';

    return InkWell(
      onTap: () => _ouvrirLecon(lecon),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border:
              Border(bottom: BorderSide(color: _borderLight, width: 1)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ═══ NUMÉRO ═══
            Container(
              margin: const EdgeInsets.only(top: 2),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: widget.courseColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  '$numero',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: widget.courseColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // ═══ CONTENU ═══
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    leconTitre,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: _textDark,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    leconDesc,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: _textMedium,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // Badges PDF / Vidéo
                  Row(
                    children: [
                      if (hasPdf)
                        _badge(
                            Icons.picture_as_pdf_outlined, 'PDF', _red),
                      if (hasVideo)
                        _badge(Icons.videocam_outlined, 'Vidéo', _blue),
                    ],
                  ),
                ],
              ),
            ),

            // ═══ ACTIONS ═══
            if (_canEdit)
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, size: 18, color: _textLight),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                color: _white,
                elevation: 4,
                onSelected: (val) {
                  if (val == 'edit') {
                    _showLeconDialog(
                        moduleId: moduleId, existingLecon: lecon);
                  } else if (val == 'delete') {
                    _deleteLecon(leconId);
                  } else if (val == 'open') {
                    _ouvrirLecon(lecon);
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'open',
                    child: Row(children: [
                      Icon(Icons.open_in_new,
                          size: 16, color: brandPrimary),
                      SizedBox(width: 8),
                      Text('Ouvrir',
                          style:
                              TextStyle(fontSize: 13, color: _textDark)),
                    ]),
                  ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(children: [
                      Icon(Icons.edit_outlined,
                          size: 16, color: _blue),
                      SizedBox(width: 8),
                      Text('Modifier',
                          style:
                              TextStyle(fontSize: 13, color: _textDark)),
                    ]),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(children: [
                      Icon(Icons.delete_outline,
                          size: 16, color: _red),
                      SizedBox(width: 8),
                      Text('Supprimer',
                          style:
                              TextStyle(fontSize: 13, color: _textDark)),
                    ]),
                  ),
                ],
              )
            else
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: widget.courseColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.play_circle_outline,
                    color: widget.courseColor,
                    size: 22,
                  ),
                  onPressed: () => _ouvrirLecon(lecon),
                  padding: EdgeInsets.zero,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  DIALOG MODULE
  // ═══════════════════════════════════════════════════════════
  void _showModuleDialog({Map? existingModule}) {
    final isEdit = existingModule != null;
    final titreCtrl = TextEditingController(
        text: isEdit ? existingModule['titre'] ?? '' : '');
    final descCtrl = TextEditingController(
        text: isEdit ? existingModule['description'] ?? '' : '');
    final ordreCtrl = TextEditingController(
        text: isEdit
            ? existingModule['ordre'].toString()
            : (modules.length + 1).toString());
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Container(
          decoration: BoxDecoration(
            color: _white,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 16,
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
                      color: widget.courseColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isEdit ? Icons.edit_note : Icons.add_box_outlined,
                      color: widget.courseColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    isEdit ? 'Modifier le module' : 'Nouveau module',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: _textDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _field(titreCtrl, 'Titre du module', Icons.title,
                  'Ex: Algèbre linéaire'),
              const SizedBox(height: 16),
              _field(descCtrl, 'Description', Icons.description_outlined,
                  'Objectifs du module', maxLines: 2),
              const SizedBox(height: 16),
              _field(ordreCtrl, 'Position (ordre)', Icons.sort, '',
                  isNumber: true),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.courseColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  onPressed: isLoading
                      ? null
                      : () async {
                          if (titreCtrl.text.trim().isEmpty) {
                            _showError('Le titre est requis.');
                            return;
                          }
                          final ordre =
                              int.tryParse(ordreCtrl.text.trim()) ?? 1;
                          setS(() => isLoading = true);
                          Navigator.pop(ctx);
                          if (isEdit) {
                            await _updateModule(
                              existingModule['id'] as int,
                              titreCtrl.text.trim(),
                              descCtrl.text.trim(),
                              ordre,
                            );
                          } else {
                            await _createModule(
                              titreCtrl.text.trim(),
                              descCtrl.text.trim(),
                              ordre,
                            );
                          }
                          setS(() => isLoading = false);
                        },
                  child: isLoading
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: _white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          isEdit ? 'Enregistrer' : 'Créer le module',
                          style: const TextStyle(
                            color: _white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
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

  // ═══════════════════════════════════════════════════════════
  //  DIALOG LEÇON
  // ═══════════════════════════════════════════════════════════
  void _showLeconDialog(
      {required String moduleId, Map? existingLecon}) {
    final isEdit = existingLecon != null;
    final titreCtrl = TextEditingController(
        text: isEdit ? existingLecon['titre'] ?? '' : '');
    final descCtrl = TextEditingController(
        text: isEdit ? existingLecon['description'] ?? '' : '');
    PlatformFile? selectedPdf;
    PlatformFile? selectedVideo;
    String? currentPdfName = isEdit && existingLecon['fichier_pdf'] != null
        ? 'PDF actuel'
        : null;
    String? currentVideoName = isEdit && existingLecon['video'] != null
        ? 'Vidéo actuelle'
        : null;
    String selectedModuleId = moduleId;
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Container(
          decoration: BoxDecoration(
            color: _white,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 16,
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
                        color: widget.courseColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isEdit ? Icons.edit : Icons.menu_book_outlined,
                        color: widget.courseColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      isEdit ? 'Modifier la leçon' : 'Ajouter une leçon',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: _textDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _field(titreCtrl, 'Titre de la leçon', Icons.menu_book,
                    'Ex: Chapitre 1 : Introduction'),
                const SizedBox(height: 16),
                _field(descCtrl, 'Résumé / Description', Icons.short_text,
                    'De quoi parle cette leçon ?', maxLines: 3),
                const SizedBox(height: 16),
                if (isEdit && modules.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: _bgLight,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _borderLight, width: 1),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: selectedModuleId,
                        icon: Icon(Icons.keyboard_arrow_down,
                            color: widget.courseColor),
                        items: modules.map<DropdownMenuItem<String>>((m) {
                          return DropdownMenuItem<String>(
                            value: m['id'].toString(),
                            child: Row(
                              children: [
                                Icon(Icons.folder_outlined,
                                    size: 18,
                                    color: widget.courseColor),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    m['titre'] ?? 'Module ${m['id']}',
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 14, color: _textDark),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setS(() => selectedModuleId = val);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                _filePickerButton(
                  icon: Icons.picture_as_pdf_outlined,
                  label: 'Fichier PDF',
                  color: _red,
                  onTap: () async {
                    final result = await FilePicker.platform.pickFiles(
                      type: FileType.custom,
                      allowedExtensions: ['pdf'],
                    );
                    if (result != null) {
                      setS(() {
                        selectedPdf = result.files.single;
                        currentPdfName = null;
                      });
                    }
                  },
                  selectedFile: selectedPdf,
                  existingFileName: currentPdfName,
                ),
                const SizedBox(height: 12),
                _filePickerButton(
                  icon: Icons.videocam_outlined,
                  label: 'Vidéo (optionnel)',
                  color: _blue,
                  onTap: () async {
                    final result = await FilePicker.platform.pickFiles(
                      type: FileType.custom,
                      allowedExtensions: [
                        'mp4',
                        'mov',
                        'avi',
                        'mkv',
                        'webm'
                      ],
                    );
                    if (result != null) {
                      setS(() {
                        selectedVideo = result.files.single;
                        currentVideoName = null;
                      });
                    }
                  },
                  selectedFile: selectedVideo,
                  existingFileName: currentVideoName,
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.courseColor,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    onPressed: isLoading
                        ? null
                        : () async {
                            if (titreCtrl.text.trim().isEmpty) {
                              _showError('Le titre est requis.');
                              return;
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
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: _white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            isEdit ? 'Enregistrer' : 'Publier la leçon',
                            style: const TextStyle(
                              color: _white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
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

  // ═══════════════════════════════════════════════════════════
  //  HELPERS UI
  // ═══════════════════════════════════════════════════════════
  Widget _iconBtn({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }

  Widget _filePickerButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    PlatformFile? selectedFile,
    String? existingFileName,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selectedFile != null
                ? color.withOpacity(0.4)
                : _borderLight,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: selectedFile != null ? color : _textLight, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    selectedFile != null
                        ? selectedFile.name
                        : (existingFileName ?? label),
                    style: TextStyle(
                      color: selectedFile != null ? _textDark : _textMedium,
                      fontSize: 13,
                      fontWeight: selectedFile != null
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (existingFileName != null &&
                      selectedFile == null &&
                      !label.contains('optionnel'))
                    const Text(
                      'Cliquez pour remplacer',
                      style: TextStyle(fontSize: 10, color: _textLight),
                    ),
                ],
              ),
            ),
            if (selectedFile != null)
              Icon(Icons.check_circle, color: color, size: 20)
            else if (existingFileName != null)
              const Icon(Icons.check_circle, color: _green, size: 20)
            else
              Icon(Icons.upload_file, color: _textLight, size: 20),
          ],
        ),
      ),
    );
  }

  Future<bool?> _confirm(String title, String content) => showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          backgroundColor: _white,
          title: Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: _textDark)),
          content:
              Text(content, style: TextStyle(color: _textMedium)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler',
                  style: TextStyle(color: _textMedium)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _red,
                foregroundColor: _white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Supprimer'),
            ),
          ],
        ),
      );

  Widget _badge(IconData icon, String text, Color color) => Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.15), width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 10, color: color),
            const SizedBox(width: 4),
            Text(
              text,
              style: TextStyle(
                  fontSize: 10, color: color, fontWeight: FontWeight.w600),
            ),
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
        keyboardType:
            isNumber ? TextInputType.number : TextInputType.text,
        style: const TextStyle(color: _textDark, fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          hintStyle: TextStyle(color: _textLight, fontSize: 12),
          labelStyle: TextStyle(color: _textMedium, fontSize: 12),
          prefixIcon:
              Icon(icon, color: widget.courseColor, size: 20),
          filled: true,
          fillColor: _bgLight,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: _borderLight, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                BorderSide(color: widget.courseColor, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 14),
        ),
      );

  Widget _sheetHandle() => Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: _borderLight,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: _white)),
        backgroundColor: _red,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showSuccess(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: _white)),
        backgroundColor: _green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}