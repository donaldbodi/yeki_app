import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yeki/core/constants/api_constants.dart';
import 'package:yeki/core/design/components/inputs/yk_color_picker.dart';

// ─────────────────────────────────────────────────────────────────
// MODIFIER COURS SHEET
// Accessible depuis CadreDashboardPage
// Permet à l'enseignant cadre de modifier un cours de son département
// ─────────────────────────────────────────────────────────────────

const String _baseUrlM = ApiConstants.baseUrl;
const Color _primaryM = Color(0xFF6A1B9A);
const Color _darkM = Color(0xFF0D1B2A);

// Icônes Flutter disponibles pour un cours
const List<Map<String, dynamic>> _iconesCours = [
  {'nom': 'school', 'icon': Icons.school},
  {'nom': 'book', 'icon': Icons.book},
  {'nom': 'science', 'icon': Icons.science},
  {'nom': 'calculate', 'icon': Icons.calculate},
  {'nom': 'history_edu', 'icon': Icons.history_edu},
  {'nom': 'language', 'icon': Icons.language},
  {'nom': 'biotech', 'icon': Icons.biotech},
  {'nom': 'computer', 'icon': Icons.computer},
  {'nom': 'architecture', 'icon': Icons.architecture},
  {'nom': 'psychology', 'icon': Icons.psychology},
  {'nom': 'palette', 'icon': Icons.palette},
  {'nom': 'music_note', 'icon': Icons.music_note},
  {'nom': 'sports_soccer', 'icon': Icons.sports_soccer},
  {'nom': 'medical_services', 'icon': Icons.medical_services},
  {'nom': 'engineering', 'icon': Icons.engineering},
  {'nom': 'eco', 'icon': Icons.eco},
];


class ModifierCoursSheet extends StatefulWidget {
  final Map cours;
  final VoidCallback onSuccess;

  const ModifierCoursSheet({
    super.key,
    required this.cours,
    required this.onSuccess,
  });

  @override
  State<ModifierCoursSheet> createState() => _ModifierCoursSheetState();
}

class _ModifierCoursSheetState extends State<ModifierCoursSheet> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  late TextEditingController _titreCtrl;
  late TextEditingController _niveauCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _matiereCtrl;

  late String _selectedIcone;
  late Color _selectedCouleur;

  @override
  void initState() {
    super.initState();
    final c = widget.cours;

    _titreCtrl = TextEditingController(text: c['titre'] ?? '');
    _niveauCtrl = TextEditingController(text: c['niveau'] ?? '');
    _descCtrl = TextEditingController(text: c['description_brief'] ?? '');
    _matiereCtrl = TextEditingController(text: c['matiere'] ?? '');

    _selectedIcone = c['icon_name'] ?? 'school';

    // Parser la couleur hex
    final colorHex = (c['color_code'] as String? ?? '#008080').replaceAll('#', '');
    try {
      _selectedCouleur = Color(int.parse('FF$colorHex', radix: 16));
    } catch (_) {
      _selectedCouleur = const Color(0xFF008080);
    }
  }

  @override
  void dispose() {
    _titreCtrl.dispose();
    _niveauCtrl.dispose();
    _descCtrl.dispose();
    _matiereCtrl.dispose();
    super.dispose();
  }

  Future<String?> _getToken() async {
    final p = await SharedPreferences.getInstance();
    return p.getString('token');
  }

  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }

  Future<void> _sauvegarder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    final token = await _getToken();

    try {
      final res = await http.patch(
        Uri.parse('$_baseUrlM/cours/${widget.cours['id']}/update/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'titre': _titreCtrl.text.trim(),
          'niveau': _niveauCtrl.text.trim(),
          'description_brief': _descCtrl.text.trim(),
          'color_code': _colorToHex(_selectedCouleur),
          'icon_name': _selectedIcone,
        }),
      );

      if (res.statusCode == 200) {
        if (mounted) Navigator.pop(context);
        widget.onSuccess();
        _showSuccess('Cours modifié avec succès !');
      } else {
        final err = jsonDecode(res.body);
        _showError(err['detail'] ?? 'Erreur lors de la modification');
      }
    } catch (_) {
      _showError('Erreur réseau');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Handle ───────────────────────────────────────────
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Titre section ─────────────────────────────────────
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _primaryM.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.edit, color: _primaryM, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Modifier le cours',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _darkM,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Prévisualisation ──────────────────────────────────
              _buildPreview(),
              const SizedBox(height: 24),

              // ── Champs ────────────────────────────────────────────
              _buildLabel('Titre du cours *'),
              _buildField(
                controller: _titreCtrl,
                hint: 'Ex: Mathématiques Terminale',
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Champ requis' : null,
              ),
              const SizedBox(height: 14),

              _buildLabel('Niveau *'),
              _buildField(
                controller: _niveauCtrl,
                hint: 'Ex: Terminale, Licence 1…',
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Champ requis' : null,
              ),
              const SizedBox(height: 14),

              _buildLabel('Description courte'),
              _buildField(
                controller: _descCtrl,
                hint: 'Description brève du cours',
                maxLines: 2,
              ),
              const SizedBox(height: 20),

              // ── Couleur ───────────────────────────────────────────
              _buildLabel('Couleur du cours'),
              const SizedBox(height: 10),
              _buildCouleurPicker(),
              const SizedBox(height: 20),

              // ── Icône ─────────────────────────────────────────────
              _buildLabel('Icône du cours'),
              const SizedBox(height: 10),
              _buildIconePicker(),
              const SizedBox(height: 28),

              // ── Bouton ────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryM,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  onPressed: _loading ? null : _sauvegarder,
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Enregistrer les modifications',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
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

  // ── Prévisualisation du cours ─────────────────────────────────────
  Widget _buildPreview() {
    final iconeData = _iconesCours.firstWhere(
      (i) => i['nom'] == _selectedIcone,
      orElse: () => {'icon': Icons.school},
    )['icon'] as IconData;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _selectedCouleur.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _selectedCouleur.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _selectedCouleur.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(iconeData, color: _selectedCouleur, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _titreCtrl.text.isEmpty
                      ? 'Titre du cours'
                      : _titreCtrl.text,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: _darkM,
                  ),
                ),
                if (_niveauCtrl.text.isNotEmpty)
                  Text(
                    _niveauCtrl.text,
                    style: TextStyle(
                      fontSize: 12,
                      color: _selectedCouleur,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _darkM,
          ),
        ),
      );

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) =>
      TextFormField(
        controller: controller,
        maxLines: maxLines,
        validator: validator,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          filled: true,
          fillColor: const Color(0xFFF8F4FC),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _primaryM, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 1),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      );

  // ── Sélecteur de couleur ──────────────────────────────────────────
  // Migré vers YkColorPicker (P4.7) : alimenté exclusivement par
  // YkCourseColors.palette, plus de grille de couleurs en dur ici.
  Widget _buildCouleurPicker() {
    return YkColorPicker(
      selectedHex: _colorToHex(_selectedCouleur),
      onChanged: (hex) => setState(() {
        _selectedCouleur =
            Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
      }),
    );
  }

  // ── Sélecteur d'icône ─────────────────────────────────────────────
  Widget _buildIconePicker() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _iconesCours.map((item) {
        final isSelected = item['nom'] == _selectedIcone;
        return GestureDetector(
          onTap: () => setState(() => _selectedIcone = item['nom'] as String),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: isSelected
                  ? _selectedCouleur
                  : _selectedCouleur.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? null
                  : Border.all(
                      color: _selectedCouleur.withOpacity(0.2),
                    ),
            ),
            child: Icon(
              item['icon'] as IconData,
              color: isSelected ? Colors.white : _selectedCouleur,
              size: 22,
            ),
          ),
        );
      }).toList(),
    );
  }
}
