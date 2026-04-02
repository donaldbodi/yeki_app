import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────────────────────────
// CRÉER OLYMPIADE SHEET
// Accessible uniquement par un enseignant cadre
// ─────────────────────────────────────────────────────────────────

const String _baseUrlO = 'https://yeki.pythonanywhere.com/api';
const Color _primaryO = Color(0xFF6A1B9A);
const Color _darkO = Color(0xFF0D1B2A);

class CreerOlympiadeSheet extends StatefulWidget {
  final int departementId;
  final String departementNom;
  final VoidCallback onSuccess;

  const CreerOlympiadeSheet({
    super.key,
    required this.departementId,
    required this.departementNom,
    required this.onSuccess,
  });

  @override
  State<CreerOlympiadeSheet> createState() => _CreerOlympiadeSheetState();
}

class _CreerOlympiadeSheetState extends State<CreerOlympiadeSheet>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  late TabController _tabCtrl;

  // ── Étape 1 : Infos générales ─────────────────────────────────
  final _titreCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _editionCtrl = TextEditingController();
  final _prix1Ctrl = TextEditingController();
  final _prix2Ctrl = TextEditingController();
  final _prix3Ctrl = TextEditingController();

  String _matiere = 'Mathématiques';
  String _niveau = 'Terminale';

  // ── Étape 2 : Dates ───────────────────────────────────────────
  DateTime? _dateOuvInscription;
  DateTime? _dateCloInscription;
  DateTime? _dateDebutOlympiade;
  DateTime? _dateFinOlympiade;

  // ── Étape 3 : Paramètres de composition ──────────────────────
  final _dureeCtrl = TextEditingController(text: '120');
  final _nbQuestionsCtrl = TextEditingController(text: '30');
  final _maxFocusCtrl = TextEditingController(text: '3');
  bool _melangerQuestions = true;
  bool _melangerChoix = true;
  bool _uneSeuleSession = true;

  static const List<String> _matieres = [
    'Mathématiques',
    'Physique',
    'Chimie',
    'SVT',
    'Informatique',
    'Français',
    'Anglais',
    'Histoire-Géo',
    'Philosophie',
    'Économie',
    'Autre',
  ];

  static const List<String> _niveaux = [
    'Terminale',
    '1ère',
    '2nde',
    '3ème',
    'Licence 1',
    'Licence 2',
    'Licence 3',
    'Master 1',
    'Master 2',
    'Autre',
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _titreCtrl.dispose();
    _descCtrl.dispose();
    _editionCtrl.dispose();
    _prix1Ctrl.dispose();
    _prix2Ctrl.dispose();
    _prix3Ctrl.dispose();
    _dureeCtrl.dispose();
    _nbQuestionsCtrl.dispose();
    _maxFocusCtrl.dispose();
    super.dispose();
  }

  Future<String?> _getToken() async {
    final p = await SharedPreferences.getInstance();
    return p.getString('token');
  }

  // ── Valider les 3 étapes ────────────────────────────────────────
  bool _validerEtape1() {
    return _titreCtrl.text.trim().isNotEmpty && _matiere.isNotEmpty;
  }

  bool _validerEtape2() {
    return _dateOuvInscription != null &&
        _dateCloInscription != null &&
        _dateDebutOlympiade != null &&
        _dateFinOlympiade != null &&
        _dateCloInscription!.isBefore(_dateDebutOlympiade!) &&
        _dateDebutOlympiade!.isBefore(_dateFinOlympiade!);
  }

  bool _validerEtape3() {
    final duree = int.tryParse(_dureeCtrl.text) ?? 0;
    final nbQ = int.tryParse(_nbQuestionsCtrl.text) ?? 0;
    return duree > 0 && nbQ > 0;
  }

  // ── Soumission ─────────────────────────────────────────────────
  Future<void> _soumettre() async {
    if (!_validerEtape1()) {
      _showError('Remplissez le titre et la matière (onglet 1)');
      _tabCtrl.animateTo(0);
      return;
    }
    if (!_validerEtape2()) {
      _showError('Vérifiez les dates (onglet 2)');
      _tabCtrl.animateTo(1);
      return;
    }
    if (!_validerEtape3()) {
      _showError('Vérifiez la durée et le nombre de questions (onglet 3)');
      _tabCtrl.animateTo(2);
      return;
    }

    setState(() => _loading = true);
    final token = await _getToken();

    try {
      final body = {
        'titre': _titreCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'edition': _editionCtrl.text.trim(),
        'matiere': _matiere,
        'niveau': _niveau,
        'prix_1er': _prix1Ctrl.text.trim(),
        'prix_2eme': _prix2Ctrl.text.trim(),
        'prix_3eme': _prix3Ctrl.text.trim(),
        'date_ouverture_inscription': _dateOuvInscription!.toIso8601String(),
        'date_cloture_inscription': _dateCloInscription!.toIso8601String(),
        'date_debut_olympiade': _dateDebutOlympiade!.toIso8601String(),
        'date_fin_olympiade': _dateFinOlympiade!.toIso8601String(),
        'duree_minutes': int.tryParse(_dureeCtrl.text) ?? 120,
        'nb_questions': int.tryParse(_nbQuestionsCtrl.text) ?? 30,
        'max_focus_perdu': int.tryParse(_maxFocusCtrl.text) ?? 3,
        'melanger_questions': _melangerQuestions,
        'melanger_choix': _melangerChoix,
        'une_seule_session': _uneSeuleSession,
        'departement_id': widget.departementId,
      };

      final res = await http.post(
        Uri.parse('$_baseUrlO/olympiades/cadre/creer/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (res.statusCode == 201) {
        if (mounted) Navigator.pop(context);
        widget.onSuccess();
        _showSuccess('Olympiade créée avec succès !');
      } else {
        final err = jsonDecode(res.body);
        _showError(err['detail'] ?? 'Erreur lors de la création');
      }
    } catch (_) {
      _showError('Erreur réseau');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Sélecteur de date/heure ────────────────────────────────────
  Future<DateTime?> _pickDateTime(BuildContext ctx, {DateTime? initial}) async {
    final date = await showDatePicker(
      context: ctx,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (ctx, child) => Theme(
        data: ThemeData(
          colorScheme: const ColorScheme.light(primary: _primaryO),
        ),
        child: child!,
      ),
    );
    if (date == null) return null;

    if (!ctx.mounted) return null;
    final time = await showTimePicker(
      context: ctx,
      initialTime: TimeOfDay.fromDateTime(initial ?? DateTime.now()),
      builder: (ctx, child) => Theme(
        data: ThemeData(
          colorScheme: const ColorScheme.light(primary: _primaryO),
        ),
        child: child!,
      ),
    );
    if (time == null) return date;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return 'Non définie';
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year} à ${dt.hour.toString().padLeft(2, '0')}h'
        '${dt.minute.toString().padLeft(2, '0')}';
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

  // ── BUILD ───────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // ── Handle ─────────────────────────────────────────────
          const SizedBox(height: 12),
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
          const SizedBox(height: 16),

          // ── En-tête ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.emoji_events, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Nouvelle Olympiade',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _darkO,
                        ),
                      ),
                      Text(
                        widget.departementNom,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── TabBar ─────────────────────────────────────────────
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F4FC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabCtrl,
              labelColor: Colors.white,
              unselectedLabelColor: _primaryO,
              indicator: BoxDecoration(
                color: _primaryO,
                borderRadius: BorderRadius.circular(10),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              padding: const EdgeInsets.all(4),
              tabs: const [
                Tab(text: 'Infos'),
                Tab(text: 'Dates'),
                Tab(text: 'Options'),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // ── Contenu ────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _tabInfos(),
                _tabDates(),
                _tabOptions(),
              ],
            ),
          ),

          // ── Bouton soumettre ───────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(
                24, 12, 24, MediaQuery.of(context).viewInsets.bottom + 20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFA000),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                onPressed: _loading ? null : _soumettre,
                icon: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.emoji_events),
                label: Text(
                  _loading ? 'Création en cours…' : 'Créer l\'olympiade',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── TAB 1 : INFOS GÉNÉRALES ─────────────────────────────────────
  Widget _tabInfos() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel('Titre de l\'olympiade *'),
          _buildField(controller: _titreCtrl, hint: 'Ex: Grand Prix de Mathématiques 2025'),
          const SizedBox(height: 14),

          _buildLabel('Édition'),
          _buildField(controller: _editionCtrl, hint: 'Ex: 2025-1'),
          const SizedBox(height: 14),

          _buildLabel('Description'),
          _buildField(
            controller: _descCtrl,
            hint: 'Décrivez l\'olympiade…',
            maxLines: 3,
          ),
          const SizedBox(height: 14),

          _buildLabel('Matière *'),
          _buildDropdown(
            value: _matiere,
            items: _matieres,
            onChanged: (v) => setState(() => _matiere = v!),
          ),
          const SizedBox(height: 14),

          _buildLabel('Niveau *'),
          _buildDropdown(
            value: _niveau,
            items: _niveaux,
            onChanged: (v) => setState(() => _niveau = v!),
          ),
          const SizedBox(height: 20),

          // ── Prix ───────────────────────────────────────────────
          _buildSectionTitle('🏆 Prix & Récompenses'),
          const SizedBox(height: 12),
          _buildPrixField('1er Prix', _prix1Ctrl, const Color(0xFFFFD700)),
          const SizedBox(height: 10),
          _buildPrixField('2ème Prix', _prix2Ctrl, const Color(0xFFBDBDBD)),
          const SizedBox(height: 10),
          _buildPrixField('3ème Prix', _prix3Ctrl, const Color(0xFFCD7F32)),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ── TAB 2 : DATES ───────────────────────────────────────────────
  Widget _tabDates() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('📅 Calendrier de l\'olympiade'),
          const SizedBox(height: 16),
          _buildDateTile(
            'Ouverture des inscriptions',
            _dateOuvInscription,
            Icons.login,
            Colors.green,
            () async {
              final d = await _pickDateTime(context, initial: _dateOuvInscription);
              if (d != null) setState(() => _dateOuvInscription = d);
            },
          ),
          const SizedBox(height: 12),
          _buildDateTile(
            'Clôture des inscriptions',
            _dateCloInscription,
            Icons.no_accounts,
            Colors.orange,
            () async {
              final d = await _pickDateTime(context, initial: _dateCloInscription);
              if (d != null) setState(() => _dateCloInscription = d);
            },
          ),
          const SizedBox(height: 12),
          _buildDateTile(
            'Début de l\'olympiade',
            _dateDebutOlympiade,
            Icons.play_circle,
            _primaryO,
            () async {
              final d = await _pickDateTime(context, initial: _dateDebutOlympiade);
              if (d != null) setState(() => _dateDebutOlympiade = d);
            },
          ),
          const SizedBox(height: 12),
          _buildDateTile(
            'Fin de l\'olympiade',
            _dateFinOlympiade,
            Icons.stop_circle,
            Colors.red,
            () async {
              final d = await _pickDateTime(context, initial: _dateFinOlympiade);
              if (d != null) setState(() => _dateFinOlympiade = d);
            },
          ),
          const SizedBox(height: 20),

          // ── Validation visuelle ───────────────────────────────
          if (_dateOuvInscription != null &&
              _dateCloInscription != null &&
              _dateDebutOlympiade != null &&
              _dateFinOlympiade != null)
            _buildDateValidation(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ── TAB 3 : OPTIONS ─────────────────────────────────────────────
  Widget _tabOptions() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('⚙️ Paramètres de composition'),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Durée (minutes) *'),
                    _buildField(
                      controller: _dureeCtrl,
                      hint: '120',
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Nb de questions *'),
                    _buildField(
                      controller: _nbQuestionsCtrl,
                      hint: '30',
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          _buildLabel('Pertes de focus max (avant soumission auto)'),
          _buildField(
            controller: _maxFocusCtrl,
            hint: '3',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 20),

          _buildSectionTitle('🎲 Sécurité & Mélange'),
          const SizedBox(height: 8),

          _buildSwitchTile(
            title: 'Mélanger les questions',
            subtitle: 'Ordre différent pour chaque participant',
            value: _melangerQuestions,
            icon: Icons.shuffle,
            onChanged: (v) => setState(() => _melangerQuestions = v),
          ),
          _buildSwitchTile(
            title: 'Mélanger les choix QCM',
            subtitle: 'Ordre des réponses différent par participant',
            value: _melangerChoix,
            icon: Icons.swap_vert,
            onChanged: (v) => setState(() => _melangerChoix = v),
          ),
          _buildSwitchTile(
            title: 'Session unique',
            subtitle: 'Impossible de reprendre après interruption',
            value: _uneSeuleSession,
            icon: Icons.lock_clock,
            onChanged: (v) => setState(() => _uneSeuleSession = v),
          ),
          const SizedBox(height: 20),

          // ── Info note sur ────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _primaryO.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _primaryO.withOpacity(0.2)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: _primaryO, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'La note est automatiquement sur 20. '
                    'Vous pourrez ajouter les questions après la création.',
                    style: TextStyle(fontSize: 12, color: _primaryO),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ── Widgets helpers ─────────────────────────────────────────────
  Widget _buildLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _darkO,
          ),
        ),
      );

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) =>
      TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
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
            borderSide: const BorderSide(color: _primaryO, width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      );

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F4FC),
          borderRadius: BorderRadius.circular(12),
        ),
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          underline: const SizedBox(),
          style: const TextStyle(color: _darkO, fontSize: 14),
          items: items
              .map((i) => DropdownMenuItem(value: i, child: Text(i)))
              .toList(),
          onChanged: onChanged,
        ),
      );

  Widget _buildPrixField(String label, TextEditingController ctrl, Color color) =>
      Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: const Icon(Icons.emoji_events, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextFormField(
              controller: ctrl,
              decoration: InputDecoration(
                hintText: '$label (ex: Trophée + 50 000 FCFA)',
                hintStyle:
                    TextStyle(color: Colors.grey.shade400, fontSize: 12),
                filled: true,
                fillColor: const Color(0xFFF8F4FC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ),
        ],
      );

  Widget _buildDateTile(
    String label,
    DateTime? value,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: value != null
                ? color.withOpacity(0.08)
                : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: value != null
                  ? color.withOpacity(0.4)
                  : Colors.grey.shade200,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (value != null ? color : Colors.grey)
                      .withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: value != null ? color : Colors.grey,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatDate(value),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: value != null ? _darkO : Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.edit_calendar,
                color: value != null ? color : Colors.grey.shade400,
                size: 18,
              ),
            ],
          ),
        ),
      );

  Widget _buildDateValidation() {
    final erreurs = <String>[];
    if (_dateCloInscription!.isAfter(_dateDebutOlympiade!)) {
      erreurs.add(
          '⚠️ La clôture des inscriptions doit être avant le début de l\'olympiade');
    }
    if (_dateDebutOlympiade!.isAfter(_dateFinOlympiade!)) {
      erreurs.add('⚠️ Le début doit être avant la fin de l\'olympiade');
    }

    if (erreurs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 16),
            SizedBox(width: 8),
            Text(
              'Dates valides ✓',
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: erreurs
            .map((e) => Text(
                  e,
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontSize: 12,
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required IconData icon,
    required ValueChanged<bool> onChanged,
  }) =>
      Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: value ? _primaryO.withOpacity(0.05) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                value ? _primaryO.withOpacity(0.3) : Colors.grey.shade200,
          ),
        ),
        child: SwitchListTile(
          dense: true,
          value: value,
          onChanged: onChanged,
          activeColor: _primaryO,
          secondary: Icon(
            icon,
            color: value ? _primaryO : Colors.grey,
            size: 20,
          ),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: value ? _darkO : Colors.grey.shade700,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ),
      );

  Widget _buildSectionTitle(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: _darkO,
        ),
      );
}
