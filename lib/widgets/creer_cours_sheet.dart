// lib/widgets/creer_cours_sheet.dart
// ═══════════════════════════════════════════════════════════════════
// FORMULAIRE CRÉATION DE COURS — complet selon le modèle Cours
// Champs : titre, niveau, matière, concours, description_brief,
//          color_code, icon_name, enseignant_principal, image
// ═══════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:yeki/core/theme/app_theme.dart';
import 'package:yeki/core/constants/api_constants.dart';
import 'package:yeki/utils/error_handler.dart';
import 'package:yeki/core/design/components/inputs/yk_color_picker.dart';

// ── Listes de référence ──────────────────────────────────────────

const List<String> _niveaux = [
  'Terminale', '1ère', '2nde', '3ème',
  'Licence 1', 'Licence 2', 'Licence 3',
  'Master 1', 'Master 2', 'Autre',
];

const List<String> _matieres = [
  'Mathématiques', 'Physique', 'Chimie', 'SVT',
  'Informatique', 'Français', 'Anglais',
  'Histoire-Géo', 'Philosophie', 'Économie', 'Autre',
];

// Icônes disponibles : nom Flutter MaterialIcons → label lisible
const List<Map<String, dynamic>> _icones = [
  {'name': 'school',           'icon': Icons.school,           'label': 'École'},
  {'name': 'book',             'icon': Icons.book,             'label': 'Livre'},
  {'name': 'calculate',        'icon': Icons.calculate,        'label': 'Maths'},
  {'name': 'science',          'icon': Icons.science,          'label': 'Sciences'},
  {'name': 'language',         'icon': Icons.language,         'label': 'Langue'},
  {'name': 'computer',         'icon': Icons.computer,         'label': 'Info'},
  {'name': 'history_edu',      'icon': Icons.history_edu,      'label': 'Histoire'},
  {'name': 'psychology',       'icon': Icons.psychology,       'label': 'Philo'},
  {'name': 'bar_chart',        'icon': Icons.bar_chart,        'label': 'Stats'},
  {'name': 'biotech',          'icon': Icons.biotech,          'label': 'Bio'},
  {'name': 'music_note',       'icon': Icons.music_note,       'label': 'Musique'},
  {'name': 'sports_soccer',    'icon': Icons.sports_soccer,    'label': 'Sport'},
  {'name': 'palette',          'icon': Icons.palette,          'label': 'Art'},
  {'name': 'engineering',      'icon': Icons.engineering,      'label': 'Ingé'},
  {'name': 'medical_services', 'icon': Icons.medical_services, 'label': 'Médecine'},
];


// ── Widget principal ─────────────────────────────────────────────

class CreerCoursSheet extends StatefulWidget {
  final int departementId;
  final String departementNom;
  final VoidCallback onSuccess;

  const CreerCoursSheet({
    super.key,
    required this.departementId,
    required this.departementNom,
    required this.onSuccess,
  });

  @override
  State<CreerCoursSheet> createState() => _CreerCoursSheetState();
}

class _CreerCoursSheetState extends State<CreerCoursSheet> {
  // Controllers
  final _titreCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _concoursCtrl = TextEditingController();

  // Valeurs sélectionnées
  String? _niveau;
  String? _matiere;
  String _colorCode = '#008080';
  String _iconName = 'school';
  int? _enseignantPrincipalId;

  // Image
  Uint8List? _imageBytes;
  String? _imageName;

  // État
  bool _isLoading = false;
  List<Map<String, dynamic>> _enseignants = [];
  bool _loadingEP = false;

  @override
  void initState() {
    super.initState();
    _chargerEnseignants();
  }

  @override
  void dispose() {
    _titreCtrl.dispose();
    _descCtrl.dispose();
    _concoursCtrl.dispose();
    super.dispose();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> _chargerEnseignants() async {
    setState(() => _loadingEP = true);
    final token = await _getToken();
    try {
      final res = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/enseignants/liste/?role=principal'),
        headers: ApiHeaders.auth(token),
      );
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List;
        setState(() {
          _enseignants = list.map((e) => Map<String, dynamic>.from(e)).toList();
        });
      }
    } catch (_) {}
    setState(() => _loadingEP = false);
  }

  // ── Soumission ───────────────────────────────────────────────────
  Future<void> _soumettre() async {
    // Validations frontend
    if (_titreCtrl.text.trim().isEmpty) {
      _showError('Le titre est obligatoire');
      return;
    }
    if (_niveau == null) {
      _showError('Le niveau est obligatoire');
      return;
    }

    setState(() => _isLoading = true);
    final token = await _getToken();

    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}/cours/create/');
      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Token $token';

      // ── Champs obligatoires ──────────────────────────────────
      request.fields['titre'] = _titreCtrl.text.trim();
      request.fields['niveau'] = _niveau!;
      request.fields['departement'] = widget.departementId.toString();
      request.fields['color_code'] = _colorCode;
      request.fields['icon_name'] = _iconName;

      // ── Champs optionnels ────────────────────────────────────
      if (_matiere != null && _matiere!.isNotEmpty) {
        request.fields['matiere'] = _matiere!;
      }
      if (_concoursCtrl.text.trim().isNotEmpty) {
        request.fields['concours'] = _concoursCtrl.text.trim();
      }
      if (_descCtrl.text.trim().isNotEmpty) {
        request.fields['description_brief'] = _descCtrl.text.trim();
      }
      if (_enseignantPrincipalId != null) {
        request.fields['enseignant_principal'] = _enseignantPrincipalId.toString();
      }

      // ── Image ────────────────────────────────────────────────
      if (_imageBytes != null && _imageName != null) {
        request.files.add(http.MultipartFile.fromBytes(
          'image', _imageBytes!,
          filename: _imageName,
          contentType: MediaType('image', 'jpeg'),
        ));
      }

      final streamed = await request.send();
      final res = await http.Response.fromStream(streamed);
      setState(() => _isLoading = false);

      if (res.statusCode == 201) {
        if (mounted) Navigator.pop(context);
        widget.onSuccess();
      } else {
        final body = jsonDecode(res.body);
        String msg = 'Erreur ${res.statusCode}';
        if (body is Map) {
          final firstKey = body.keys.first;
          final firstVal = body[firstKey];
          msg = firstVal is List ? firstVal.first.toString() : firstVal.toString();
        }
        _showError(msg);
      }
    } catch (_) {
      setState(() => _isLoading = false);
      _showError('Erreur réseau');
    }
  }

  // ── Build ────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: YekiColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Handle ──────────────────────────────────────────
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: YekiColors.borderLight,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Titre formulaire ─────────────────────────────────
            const Text(
              'Créer un cours',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: YekiColors.textDark,
              ),
            ),
            const SizedBox(height: 6),

            // ── Badge département ────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: YekiColors.purple.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.domain, color: YekiColors.purple, size: 15),
                  const SizedBox(width: 7),
                  Text(
                    'Département : ${widget.departementNom}',
                    style: const TextStyle(
                      color: YekiColors.purple,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            _sectionLabel('Informations principales'),
            const SizedBox(height: 12),

            // ── Titre ────────────────────────────────────────────
            _field(_titreCtrl, 'Titre du cours *', Icons.title,
                'Ex: Algèbre Linéaire S1'),
            const SizedBox(height: 14),

            // ── Niveau (dropdown) ────────────────────────────────
            _dropdown(
              value: _niveau,
              hint: 'Niveau *',
              icon: Icons.school_outlined,
              items: _niveaux,
              onChanged: (v) => setState(() => _niveau = v),
            ),
            const SizedBox(height: 14),

            // ── Matière (dropdown) ───────────────────────────────
            _dropdown(
              value: _matiere,
              hint: 'Matière',
              icon: Icons.subject,
              items: _matieres,
              onChanged: (v) => setState(() => _matiere = v),
            ),
            const SizedBox(height: 14),

            // ── Description ──────────────────────────────────────
            _field(_descCtrl, 'Description brève', Icons.description_outlined,
                'Objectifs et contenu du cours', maxLines: 3),
            const SizedBox(height: 14),

            // ── Concours lié ─────────────────────────────────────
            _field(_concoursCtrl, 'Concours lié (optionnel)',
                Icons.emoji_events_outlined, 'Ex: BEPC, BAC, ENS…'),

            const SizedBox(height: 24),
            _sectionLabel('Apparence'),
            const SizedBox(height: 12),

            // ── Couleur ──────────────────────────────────────────
            _buildColorPicker(),
            const SizedBox(height: 16),

            // ── Icône ────────────────────────────────────────────
            _buildIconPicker(),

            const SizedBox(height: 24),
            _sectionLabel('Enseignant principal'),
            const SizedBox(height: 12),

            // ── Sélecteur EP ─────────────────────────────────────
            _buildEPSelector(),

            const SizedBox(height: 24),
            _sectionLabel('Image de couverture'),
            const SizedBox(height: 12),

            // ── Image ────────────────────────────────────────────
            _buildImagePicker(),

            const SizedBox(height: 28),

            // ── Bouton soumettre ─────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: YekiColors.purple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: _isLoading ? null : _soumettre,
                child: _isLoading
                    ? const SizedBox(
                        width: 22, height: 22,
                        child: YekiLoader(color: YekiColors.white, size: 22),
                      )
                    : const Text(
                        'Créer le cours',
                        style: TextStyle(
                          color: YekiColors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── Couleur picker ───────────────────────────────────────────────
  // Migré vers YkColorPicker (P4.7) : alimenté exclusivement par
  // YkCourseColors.palette, plus de grille de couleurs en dur ici.
  Widget _buildColorPicker() {
    return YkColorPicker(
      label: 'Couleur',
      selectedHex: _colorCode,
      onChanged: (hex) => setState(() => _colorCode = hex),
    );
  }

  // ── Icône picker ─────────────────────────────────────────────────
  Widget _buildIconPicker() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _icones.map((item) {
        final selected = _iconName == item['name'];
        final couleur = _hexToColor(_colorCode);
        return GestureDetector(
          onTap: () => setState(() => _iconName = item['name'] as String),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? couleur : YekiColors.backgroundLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? couleur : Colors.transparent,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  item['icon'] as IconData,
                  size: 18,
                  color: selected ? YekiColors.white : YekiColors.textLight,
                ),
                const SizedBox(width: 5),
                Text(
                  item['label'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    color: selected ? YekiColors.white : YekiColors.textMedium,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Sélecteur enseignant principal ──────────────────────────────
  Widget _buildEPSelector() {
    if (_loadingEP) {
      return const Center(
        child: SizedBox(
          height: 30,
          child: YekiLoader(color: YekiColors.purple, size: 24),
        ),
      );
    }
    if (_enseignants.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: YekiColors.backgroundLight,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: YekiColors.textLight, size: 18),
            const SizedBox(width: 8),
            const Text(
              'Aucun enseignant principal disponible',
              style: TextStyle(color: YekiColors.textLight, fontSize: 13),
            ),
          ],
        ),
      );
    }

    // Trouver le nom de l'EP sélectionné
    String epNom = 'Aucun (optionnel)';
    if (_enseignantPrincipalId != null) {
      final ep = _enseignants.firstWhere(
        (e) => e['id'] == _enseignantPrincipalId,
        orElse: () => {},
      );
      if (ep.isNotEmpty) {
        epNom = ep['nom'] ?? ep['username'] ?? '';
      }
    }

    return GestureDetector(
      onTap: _ouvrirSelecteurEP,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _enseignantPrincipalId != null
              ? YekiColors.purple.withValues(alpha: 0.05)
              : YekiColors.backgroundLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _enseignantPrincipalId != null
                ? YekiColors.purple.withValues(alpha: 0.3)
                : YekiColors.borderLight,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: YekiColors.purple.withValues(alpha: 0.12),
              child: const Icon(Icons.person, color: YekiColors.purple, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Enseignant principal',
                    style: TextStyle(fontSize: 11, color: YekiColors.textLight),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    epNom,
                    style: TextStyle(
                      fontSize: 14,
                      color: _enseignantPrincipalId != null
                          ? YekiColors.textDark
                          : YekiColors.textLight,
                      fontWeight: _enseignantPrincipalId != null
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: YekiColors.textLight,
            ),
          ],
        ),
      ),
    );
  }

  void _ouvrirSelecteurEP() {
    int? tempSelected = _enseignantPrincipalId;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Container(
          decoration: const BoxDecoration(
            color: YekiColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 14,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: YekiColors.borderLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Choisir l\'enseignant principal',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: YekiColors.textDark,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Optionnel — peut être assigné plus tard',
                style: TextStyle(fontSize: 12, color: YekiColors.textLight),
              ),
              const SizedBox(height: 10),
              // Option "aucun"
              RadioListTile<int?>(
                value: null,
                groupValue: tempSelected,
                activeColor: YekiColors.purple,
                title: const Text(
                  'Aucun pour l\'instant',
                  style: TextStyle(fontSize: 14, color: YekiColors.textLight),
                ),
                onChanged: (v) => setS(() => tempSelected = v),
              ),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(ctx).size.height * 0.35,
                ),
                child: ListView(
                  shrinkWrap: true,
                  children: _enseignants.map((e) => RadioListTile<int>(
                    value: e['id'] as int,
                    groupValue: tempSelected,
                    activeColor: YekiColors.purple,
                    title: Text(
                      e['nom'] ?? e['username'] ?? '',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      e['email'] ?? '',
                      style: const TextStyle(fontSize: 12),
                    ),
                    onChanged: (v) => setS(() => tempSelected = v),
                  )).toList(),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: YekiColors.purple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  onPressed: () {
                    setState(() => _enseignantPrincipalId = tempSelected);
                    Navigator.pop(ctx);
                  },
                  child: const Text(
                    'Confirmer',
                    style: TextStyle(color: YekiColors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Image picker ─────────────────────────────────────────────────
  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: () async {
        final res = await FilePicker.platform.pickFiles(
          type: FileType.image,
          withData: true,
        );
        if (res != null && res.files.single.bytes != null) {
          setState(() {
            _imageBytes = res.files.single.bytes;
            _imageName = res.files.single.name;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _imageName != null
              ? YekiColors.purple.withValues(alpha: 0.05)
              : YekiColors.backgroundLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _imageName != null
                ? YekiColors.purple.withValues(alpha: 0.3)
                : YekiColors.borderLight,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _imageName != null
                    ? YekiColors.purple.withValues(alpha: 0.1)
                    : YekiColors.borderLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _imageName != null ? Icons.image : Icons.add_photo_alternate_outlined,
                color: _imageName != null ? YekiColors.purple : YekiColors.textLight,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _imageName != null
                        ? 'Image sélectionnée'
                        : 'Ajouter une image de couverture',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: _imageName != null ? FontWeight.w600 : FontWeight.normal,
                      color: _imageName != null ? YekiColors.textDark : YekiColors.textLight,
                    ),
                  ),
                  if (_imageName != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      _imageName!,
                      style: TextStyle(fontSize: 11, color: YekiColors.textLight),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ] else ...[
                    const SizedBox(height: 2),
                    Text(
                      'Optionnel — JPEG, PNG',
                      style: TextStyle(fontSize: 11, color: YekiColors.textLight),
                    ),
                  ],
                ],
              ),
            ),
            if (_imageName != null)
              GestureDetector(
                onTap: () => setState(() {
                  _imageBytes = null;
                  _imageName = null;
                }),
                child: Icon(Icons.close, color: YekiColors.textLight, size: 18),
              )
            else
              Icon(Icons.arrow_forward_ios, size: 13, color: YekiColors.textLight),
          ],
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────
  Widget _sectionLabel(String label) => Row(
        children: [
          Container(
            width: 4, height: 16,
            decoration: BoxDecoration(
              color: YekiColors.purple,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: YekiColors.textDark,
            ),
          ),
        ],
      );

  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon,
    String hint, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: YekiColors.purple, size: 20),
        filled: true,
        fillColor: YekiColors.backgroundLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: YekiColors.purple),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: YekiColors.borderLight),
        ),
      ),
    );
  }

  Widget _dropdown({
    required String? value,
    required String hint,
    required IconData icon,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: hint,
        prefixIcon: Icon(icon, color: YekiColors.purple, size: 20),
        filled: true,
        fillColor: YekiColors.backgroundLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: YekiColors.purple),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: YekiColors.borderLight),
        ),
      ),
      icon: const Icon(Icons.keyboard_arrow_down, color: YekiColors.purple),
      dropdownColor: YekiColors.white,
      items: items.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
      onChanged: onChanged,
    );
  }

  Color _hexToColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return const Color(0xFF008080);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ErrorHandler.showError(context, msg);
  }
}