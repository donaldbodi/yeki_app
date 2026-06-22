// lib/views/pages/enseignants/admin_general_page.dart
// Admin Général - Dashboard avec gestion des parcours, départements et enseignants

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yeki/core/design/yeki_design.dart';
import 'package:yeki/core/constants/api_constants.dart';
import 'package:yeki/views/pages/enseignants/detail_cours_enseignant.dart';
import 'package:yeki/views/pages/enseignants/interface_enseignant_page.dart' show RoleEnseignant;
import 'package:intl/intl.dart';

class AdminGeneralPage extends StatefulWidget {
  const AdminGeneralPage({super.key});

  @override
  State<AdminGeneralPage> createState() => _AdminGeneralPageState();
}

class _AdminGeneralPageState extends State<AdminGeneralPage>
    with SingleTickerProviderStateMixin {
  bool _loading = true;
  bool _hasError = false;
  String _errorMessage = '';
  String _errorDetail = '';
  Map<String, dynamic> _stats = {};
  List _parcours = [];
  List _departements = [];
  List _topEnseignants = [];
  String _nomEnseignant = '';
  late TabController _tabCtrl;

  // Nouveaux champs pour la gestion des enseignants
  List _enseignants = [];
  bool _loadingEnseignants = false;

  // Champs pour la recherche
  String _searchQuery = '';
  String _filterUserType = '';
  String _filterStatus = '';
  int? _filterParcours;
  int? _filterDepartement;
  int? _filterCours;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 5, vsync: this);
    _charger();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<String?> _getToken() async {
    final p = await SharedPreferences.getInstance();
    return p.getString('token');
  }

  Future<void> _charger() async {
    setState(() {
      _loading = true;
      _hasError = false;
      _errorMessage = '';
      _errorDetail = '';
    });
    
    final token = await _getToken();
    if (token == null) {
      if (mounted) {
        setState(() {
          _loading = false;
          _hasError = true;
          _errorMessage = 'Vous devez être connecté pour accéder à cette page.';
        });
      }
      return;
    }
    
    try {
      final res = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/admin-general/dashboard/'),
        headers: ApiHeaders.auth(token),
      );
      
      if (mounted) {
        if (res.statusCode == 200) {
          try {
            final data = jsonDecode(res.body);
            setState(() {
              _stats = data['stats'] ?? {};
              _parcours = data['parcours'] ?? [];
              _departements = data['departements'] ?? [];
              _topEnseignants = data['top_enseignants'] ?? [];
              _nomEnseignant = data['nom'] ?? '';
              _enseignants = data['enseignants'] ?? [];
              _loading = false;
              _hasError = false;
            });
          } catch (e) {
            setState(() {
              _loading = false;
              _hasError = true;
              _errorMessage = 'Erreur de parsing des données';
              _errorDetail = e.toString();
            });
          }
        } else if (res.statusCode == 403) {
          setState(() {
            _loading = false;
            _hasError = true;
            _errorMessage = 'Accès refusé. Vous devez être administrateur général pour accéder à cette page.';
          });
        } else if (res.statusCode == 500) {
          String detail = '';
          try {
            final errorData = jsonDecode(res.body);
            detail = errorData['detail'] ?? 'Erreur interne du serveur';
          } catch (_) {
            detail = 'Erreur interne du serveur (500)';
          }
          setState(() {
            _loading = false;
            _hasError = true;
            _errorMessage = 'Erreur serveur';
            _errorDetail = detail;
          });
        } else {
          setState(() {
            _loading = false;
            _hasError = true;
            _errorMessage = 'Erreur lors du chargement';
            _errorDetail = 'Code: ${res.statusCode} - ${res.reasonPhrase}';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _hasError = true;
          _errorMessage = 'Erreur réseau';
          _errorDetail = e.toString();
        });
      }
    }
  }

  // ─── Recherche d'enseignants ──────────────────────────────────────
  Future<void> _rechercherEnseignants() async {
    setState(() => _loadingEnseignants = true);

    final token = await _getToken();
    if (token == null) {
      setState(() => _loadingEnseignants = false);
      _showError('Vous devez être connecté');
      return;
    }

    final params = <String, String>{};
    if (_searchQuery.isNotEmpty) params['q'] = _searchQuery;
    if (_filterUserType.isNotEmpty) params['user_type'] = _filterUserType;
    if (_filterStatus.isNotEmpty) params['is_active'] = _filterStatus;
    if (_filterParcours != null) params['parcours_id'] = _filterParcours.toString();
    if (_filterDepartement != null) params['departement_id'] = _filterDepartement.toString();
    if (_filterCours != null) params['cours_id'] = _filterCours.toString();

    final uri = Uri.parse('${ApiConstants.baseUrl}/admin-general/enseignants/search/')
        .replace(queryParameters: params);

    try {
      final res = await http.get(uri, headers: ApiHeaders.auth(token));
      if (mounted) {
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          setState(() {
            _enseignants = data['results'] ?? [];
            _loadingEnseignants = false;
          });
        } else {
          setState(() => _loadingEnseignants = false);
          _showError('Erreur lors de la recherche (${res.statusCode})');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingEnseignants = false);
        _showError('Erreur réseau');
      }
    }
  }

  // ─── Modifier un enseignant ──────────────────────────────────────
  Future<void> _modifierEnseignant(Map enseignant) async {
    final token = await _getToken();
    if (token == null) {
      _showError('Vous devez être connecté');
      return;
    }

    String currentType = enseignant['user_type'] ?? 'enseignant';
    bool currentActive = enseignant['is_active'] ?? false;
    String selectedType = currentType;
    bool selectedActive = currentActive;
    bool isLoading = false;

    final types = [
      {'code': 'enseignant', 'label': 'Enseignant'},
      {'code': 'enseignant_principal', 'label': 'Enseignant Principal'},
      {'code': 'enseignant_cadre', 'label': 'Enseignant Cadre'},
      {'code': 'enseignant_admin', 'label': 'Enseignant Administrateur'},
    ];

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Container(
          decoration: BoxDecoration(
            color: kECard,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(kRadiusLg)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: kEBorder, borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Modifier ${enseignant['nom']}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kEDark),
              ),
              const SizedBox(height: 8),
              Text(
                'Email: ${enseignant['email']}',
                style: const TextStyle(fontSize: 12, color: kEMuted),
              ),
              const SizedBox(height: 20),
              // Type
              const Text('Type d\'enseignant', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kEDark)),
              const SizedBox(height: 8),
              ...types.map((t) {
                final isSelected = t['code'] == selectedType;
                return RadioListTile<String>(
                  value: t['code'] as String,
                  groupValue: selectedType,
                  onChanged: (value) => setS(() => selectedType = value!),
                  activeColor: kPrimary,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                  title: Text(
                    t['label'] as String,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? kPrimary : kEDark,
                    ),
                  ),
                );
              }),
              const SizedBox(height: 16),
              // État
              SwitchListTile(
                value: selectedActive,
                onChanged: (v) => setS(() => selectedActive = v),
                title: const Text('Compte actif', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(
                  selectedActive ? 'L\'enseignant peut se connecter' : 'L\'enseignant ne peut pas se connecter',
                  style: const TextStyle(fontSize: 12, color: kEMuted),
                ),
                activeColor: kPrimary,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusMd)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                  ),
                  onPressed: (selectedType == currentType && selectedActive == currentActive) || isLoading
                      ? null
                      : () async {
                          setS(() => isLoading = true);
                          await _envoyerModificationEnseignant(
                            enseignant['id'] as int,
                            selectedType,
                            selectedActive,
                          );
                          setS(() => isLoading = false);
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                  child: isLoading
                      ? const SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Enregistrer',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _envoyerModificationEnseignant(int profileId, String newType, bool newActive) async {
    final token = await _getToken();
    if (token == null) {
      _showError('Vous devez être connecté');
      return;
    }

    try {
      final res = await http.patch(
        Uri.parse('${ApiConstants.baseUrl}/admin-general/enseignants/$profileId/modifier/'),
        headers: ApiHeaders.auth(token),
        body: jsonEncode({
          'user_type': newType,
          'is_active': newActive,
        }),
      );

      if (mounted) {
        if (res.statusCode == 200) {
          _showSuccess('Enseignant modifié avec succès !');
          _rechercherEnseignants();
          _charger();
        } else {
          try {
            final err = jsonDecode(res.body);
            _showError(err['detail'] ?? 'Erreur ${res.statusCode}');
          } catch (_) {
            _showError('Erreur ${res.statusCode}');
          }
        }
      }
    } catch (_) {
      _showError('Erreur réseau');
    }
  }

  // ─── Créer un parcours ────────────────────────────────────────────
  void _creerParcours() {
    final nomCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String selectedType = 'cursus';
    bool isLoading = false;

    final List<Map<String, dynamic>> typesParcours = [
      {'code': 'cursus', 'label': 'Cursus scolaire / universitaire', 'icon': Icons.school_rounded, 'color': Colors.indigo},
      {'code': 'prepa', 'label': 'Prépa Concours', 'icon': Icons.emoji_events_rounded, 'color': kGold},
      {'code': 'formation', 'label': 'Formations professionnelles', 'icon': Icons.work_rounded, 'color': kAccent},
      {'code': 'autre', 'label': 'Autre', 'icon': Icons.category_rounded, 'color': Colors.grey},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Container(
          decoration: BoxDecoration(
            color: kECard,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(kRadiusLg)),
          ),
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sheetHandle(),
                const SizedBox(height: 20),
                const Text('Créer un parcours',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kEDark)),
                const SizedBox(height: 6),
                const Text(
                  'Un enseignant administrateur pourra être nommé à la tête du parcours.',
                  style: TextStyle(fontSize: 12, color: kEMuted),
                ),
                const SizedBox(height: 24),
                _field(nomCtrl, 'Nom du parcours *', Icons.route, 'Ex: Licence Informatique'),
                const SizedBox(height: 16),
                _field(descCtrl, 'Description', Icons.description_outlined,
                    'Objectifs et contenu du parcours', maxLines: 3),
                const SizedBox(height: 20),
                const Text('Type de parcours *',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kEDark)),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: kEBg,
                    borderRadius: BorderRadius.circular(kRadiusMd),
                    border: Border.all(color: kEBorder, width: 1),
                  ),
                  child: Column(
                    children: typesParcours.map((type) {
                      return RadioListTile<String>(
                        value: type['code'],
                        groupValue: selectedType,
                        onChanged: (value) => setS(() => selectedType = value!),
                        activeColor: type['color'],
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        title: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: (type['color'] as Color).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(type['icon'], size: 18, color: type['color']),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(type['label'],
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: kEDark)),
                            ),
                          ],
                        ),
                        controlAffinity: ListTileControlAffinity.trailing,
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusMd)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                    ),
                    onPressed: isLoading ? null : () async {
                      if (nomCtrl.text.trim().isEmpty) {
                        _showError('Le nom est obligatoire');
                        return;
                      }
                      setS(() => isLoading = true);
                      final token = await _getToken();
                      if (token == null) {
                        setS(() => isLoading = false);
                        _showError('Vous devez être connecté');
                        return;
                      }
                      try {
                        final res = await http.post(
                          Uri.parse('${ApiConstants.baseUrl}/parcours/creer/'),
                          headers: ApiHeaders.auth(token),
                          body: jsonEncode({
                            'nom': nomCtrl.text.trim(),
                            'description': descCtrl.text.trim(),
                            'type_parcours': selectedType,
                          }),
                        );
                        setS(() => isLoading = false);
                        if (res.statusCode == 201) {
                          if (ctx.mounted) Navigator.pop(ctx);
                          _showSuccess('Parcours créé avec succès !');
                          _charger();
                        } else {
                          try {
                            final err = jsonDecode(res.body);
                            _showError(err['detail'] ?? 'Erreur ${res.statusCode}');
                          } catch (_) {
                            _showError('Erreur ${res.statusCode}');
                          }
                        }
                      } catch (_) {
                        setS(() => isLoading = false);
                        _showError('Erreur réseau');
                      }
                    },
                    child: isLoading
                        ? const SizedBox(
                            width: 22, height: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Créer le parcours',
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Modifier un parcours ──────────────────────────────────────────
  Future<void> _modifierParcours(Map parcours) async {
    final token = await _getToken();
    if (token == null) {
      _showError('Vous devez être connecté');
      return;
    }

    final nomCtrl = TextEditingController(text: parcours['nom'] ?? '');
    final descCtrl = TextEditingController(text: parcours['description'] ?? '');
    String selectedType = parcours['type_parcours'] ?? 'autre';
    bool isLoading = false;

    final List<Map<String, dynamic>> typesParcours = [
      {'code': 'cursus', 'label': 'Cursus scolaire / universitaire', 'icon': Icons.school_rounded, 'color': Colors.indigo},
      {'code': 'prepa', 'label': 'Prépa Concours', 'icon': Icons.emoji_events_rounded, 'color': kGold},
      {'code': 'formation', 'label': 'Formations professionnelles', 'icon': Icons.work_rounded, 'color': kAccent},
      {'code': 'autre', 'label': 'Autre', 'icon': Icons.category_rounded, 'color': Colors.grey},
    ];

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Container(
          decoration: BoxDecoration(
            color: kECard,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(kRadiusLg)),
          ),
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sheetHandle(),
                const SizedBox(height: 20),
                Text('Modifier le parcours',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kEDark)),
                const SizedBox(height: 6),
                const Text(
                  'Seul le nom, la description et le type peuvent être modifiés.',
                  style: TextStyle(fontSize: 12, color: kEMuted),
                ),
                const SizedBox(height: 24),
                _field(nomCtrl, 'Nom du parcours *', Icons.route, 'Ex: Licence Informatique'),
                const SizedBox(height: 16),
                _field(descCtrl, 'Description', Icons.description_outlined,
                    'Objectifs et contenu du parcours', maxLines: 3),
                const SizedBox(height: 20),
                const Text('Type de parcours *',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kEDark)),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: kEBg,
                    borderRadius: BorderRadius.circular(kRadiusMd),
                    border: Border.all(color: kEBorder, width: 1),
                  ),
                  child: Column(
                    children: typesParcours.map((type) {
                      return RadioListTile<String>(
                        value: type['code'],
                        groupValue: selectedType,
                        onChanged: (value) => setS(() => selectedType = value!),
                        activeColor: type['color'],
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        title: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: (type['color'] as Color).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(type['icon'], size: 18, color: type['color']),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(type['label'],
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: kEDark)),
                            ),
                          ],
                        ),
                        controlAffinity: ListTileControlAffinity.trailing,
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusMd)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                    ),
                    onPressed: isLoading ? null : () async {
                      if (nomCtrl.text.trim().isEmpty) {
                        _showError('Le nom est obligatoire');
                        return;
                      }
                      setS(() => isLoading = true);
                      final token2 = await _getToken();
                      if (token2 == null) {
                        setS(() => isLoading = false);
                        _showError('Vous devez être connecté');
                        return;
                      }
                      try {
                        final res = await http.patch(
                          Uri.parse('${ApiConstants.baseUrl}/parcours/${parcours['id']}/modifier/'),
                          headers: ApiHeaders.auth(token2),
                          body: jsonEncode({
                            'nom': nomCtrl.text.trim(),
                            'description': descCtrl.text.trim(),
                            'type_parcours': selectedType,
                          }),
                        );
                        setS(() => isLoading = false);
                        if (res.statusCode == 200) {
                          if (ctx.mounted) Navigator.pop(ctx);
                          _showSuccess('Parcours modifié avec succès !');
                          _charger();
                        } else {
                          try {
                            final err = jsonDecode(res.body);
                            _showError(err['detail'] ?? 'Erreur ${res.statusCode}');
                          } catch (_) {
                            _showError('Erreur ${res.statusCode}');
                          }
                        }
                      } catch (_) {
                        setS(() => isLoading = false);
                        _showError('Erreur réseau');
                      }
                    },
                    child: isLoading
                        ? const SizedBox(
                            width: 22, height: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Enregistrer les modifications',
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Changer admin de parcours ────────────────────────────────────
  void _changerAdmin(Map parcours) async {
    final token = await _getToken();
    if (token == null) {
      _showError('Vous devez être connecté');
      return;
    }

    List enseignants = [];
    try {
      final res = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/enseignants/liste/?role=admin'),
        headers: ApiHeaders.auth(token),
      );
      if (res.statusCode == 200) {
        enseignants = jsonDecode(res.body);
      } else {
        _showError('Impossible de charger les enseignants (${res.statusCode})');
        return;
      }
    } catch (_) {
      _showError('Erreur réseau');
      return;
    }

    if (!mounted) return;

    int? selected = parcours['enseignant_admin']?['id'] as int?;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Container(
          decoration: BoxDecoration(
            color: kECard,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(kRadiusLg)),
          ),
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _sheetHandle(),
              const SizedBox(height: 20),
              Text(
                parcours['enseignant_admin'] == null
                    ? 'Nommer un enseignant administrateur'
                    : 'Changer l\'enseignant administrateur',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kEDark),
              ),
              const SizedBox(height: 6),
              Text(
                'Parcours : ${parcours['nom'] ?? ''}',
                style: const TextStyle(fontSize: 13, color: kEMuted),
              ),
              const SizedBox(height: 20),
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.4),
                child: enseignants.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Text(
                            'Aucun enseignant administrateur disponible.\n'
                            'Vérifiez qu\'il existe des comptes avec le rôle "enseignant_admin" actifs.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: kEMuted),
                          ),
                        ),
                      )
                    : ListView(
                        shrinkWrap: true,
                        children: enseignants.map<Widget>((e) => RadioListTile<int>(
                          value: e['id'] as int,
                          groupValue: selected,
                          activeColor: kPrimary,
                          title: Text(e['nom'] ?? e['username'] ?? '',
                              style: const TextStyle(color: kEDark)),
                          subtitle: Text(e['email'] ?? '',
                              style: const TextStyle(color: kEMuted)),
                          onChanged: (v) => setS(() => selected = v),
                        )).toList(),
                      ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusMd)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                  ),
                  onPressed: selected == null ? null : () async {
                    if (ctx.mounted) Navigator.pop(ctx);
                    final token2 = await _getToken();
                    if (token2 == null) {
                      _showError('Vous devez être connecté');
                      return;
                    }
                    try {
                      final res = await http.patch(
                        Uri.parse('${ApiConstants.baseUrl}/parcours/${parcours['id']}/nommer-admin/'),
                        headers: ApiHeaders.auth(token2),
                        body: jsonEncode({'enseignant_admin_id': selected}),
                      );
                      if (res.statusCode == 200) {
                        _showSuccess('Enseignant administrateur mis à jour !');
                        _charger();
                      } else {
                        try {
                          final err = jsonDecode(res.body);
                          _showError(err['detail'] ?? 'Erreur ${res.statusCode}');
                        } catch (_) {
                          _showError('Erreur ${res.statusCode}');
                        }
                      }
                    } catch (_) {
                      _showError('Erreur réseau');
                    }
                  },
                  child: const Text('Confirmer',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Charger tous les cours ──────────────────────────────────────
  Future<List> _chargerTousLesCours() async {
    final token = await _getToken();
    if (token == null) return [];
    try {
      final res = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/cours/'),
        headers: ApiHeaders.auth(token),
      );
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kEBg,
      body: _loading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: kPrimary),
                  const SizedBox(height: 16),
                  const Text('Chargement du tableau de bord...',
                      style: TextStyle(color: kEMuted, fontSize: 14)),
                ],
              ),
            )
          : _hasError
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline_rounded, size: 72, color: kAccent),
                        const SizedBox(height: 20),
                        Text(
                          _errorMessage,
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kEDark),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        if (_errorDetail.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: kEBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: kEBorder, width: 1),
                            ),
                            child: Text(
                              _errorDetail,
                              style: TextStyle(fontSize: 14, color: kEMuted),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton(
                              onPressed: _charger,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kPrimary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(kRadiusMd),
                                ),
                              ),
                              child: const Text('Réessayer'),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(kRadiusMd),
                                ),
                              ),
                              child: const Text('Retour'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                )
              : NestedScrollView(
                  headerSliverBuilder: (context, innerBoxIsScrolled) => [
                    _buildSliverHeader(),
                    _buildSliverTabBar(),
                  ],
                  body: TabBarView(
                    controller: _tabCtrl,
                    children: [
                      _tabParcours(),
                      _tabDepartements(),
                      _tabGlobal(),
                      _tabEnseignants(),
                      _tabTousCours(),
                    ],
                  ),
                ),
      floatingActionButton: !_loading && !_hasError ? _buildPremiumFAB() : null,
    );
  }

  // ─── En-tête ──────────────────────────────────────────────────────
  Widget _buildSliverHeader() {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [kPrimary, kPrimary.withValues(alpha: 0.85)],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: kGold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(kRadiusLg),
                ),
                child: const Text("ADMINISTRATION",
                    style: TextStyle(color: kGold, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
              ),
              const SizedBox(height: 12),
              Text(
                _nomEnseignant.isEmpty ? 'Admin Général' : _nomEnseignant,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildBadge('Admin Général', Colors.white.withValues(alpha: 0.15)),
                  const SizedBox(width: 8),
                  _buildBadge('Vue complète', kGold.withValues(alpha: 0.3)),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _buildMiniStat('${_stats['nb_parcours'] ?? 0}', 'Parcours'),
                  const SizedBox(width: 24),
                  _buildMiniStat('${_stats['nb_departements'] ?? 0}', 'Départements'),
                  const SizedBox(width: 24),
                  _buildMiniStat('${_stats['nb_apprenants'] ?? 0}', 'Apprenants'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSliverTabBar() {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _StickyTabBarDelegate(
        TabBar(
          controller: _tabCtrl,
          labelColor: kPrimary,
          unselectedLabelColor: kEMuted,
          indicatorColor: kPrimary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: 'Parcours'),
            Tab(text: 'Départements'),
            Tab(text: 'Vue globale'),
            Tab(text: 'Enseignants'),
            Tab(text: 'Tous les cours'),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumFAB() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: FloatingActionButton(
        onPressed: _creerParcours,
        backgroundColor: kPrimary,
        elevation: 4,
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildBadge(String text, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(kRadiusLg)),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildMiniStat(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }

  // ─── TAB 1 : Parcours ────────────────────────────────────────────
  Widget _tabParcours() {
    if (_parcours.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: kPrimary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
                border: Border.all(color: kPrimary.withValues(alpha: 0.2), width: 1),
              ),
              child: Icon(Icons.route_outlined, size: 48, color: kPrimary),
            ),
            const SizedBox(height: 16),
            const Text('Aucun parcours créé', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: kEDark)),
            const SizedBox(height: 8),
            const Text('Commencez par créer votre premier parcours', style: TextStyle(fontSize: 13, color: kEMuted)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _charger,
      color: kPrimary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _parcours.length,
        itemBuilder: (_, i) => _buildParcoursCard(_parcours[i]),
      ),
    );
  }

  Widget _buildParcoursCard(Map p) {
    final nbDepts = p['nb_departements'] ?? 0;
    final nbApp = p['nb_apprenants'] ?? 0;
    final admin = p['enseignant_admin'];
    final taux = (p['taux_moyen'] as num? ?? 0).toDouble();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: kECard,
        borderRadius: BorderRadius.circular(kRadiusLg),
        border: Border.all(color: kEBorder, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: kPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(kRadiusMd),
                    border: Border.all(color: kPrimary.withValues(alpha: 0.2), width: 0.8),
                  ),
                  child: const Icon(Icons.route, color: kPrimary, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p['nom'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: kEDark)),
                      const SizedBox(height: 4),
                      Text('$nbDepts départements · $nbApp apprenants',
                          style: const TextStyle(fontSize: 12, color: kEMuted)),
                    ],
                  ),
                ),
                // Boutons d'action
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: kPrimary),
                  tooltip: 'Modifier le parcours',
                  onPressed: () => _modifierParcours(p),
                ),
                IconButton(
                  icon: Icon(
                    admin == null ? Icons.person_add_outlined : Icons.swap_horiz,
                    color: kPrimary,
                  ),
                  tooltip: admin == null ? 'Nommer un admin' : 'Changer l\'admin',
                  onPressed: () => _changerAdmin(p),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (admin != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: kPrimary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: kPrimary.withValues(alpha: 0.15), width: 0.8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.admin_panel_settings, size: 14, color: kPrimary),
                    const SizedBox(width: 8),
                    Text(
                      'Admin : ${admin['nom'] ?? admin['username'] ?? ''}',
                      style: const TextStyle(fontSize: 12, color: kPrimary, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: kAccent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: kAccent.withValues(alpha: 0.2), width: 0.8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.warning_outlined, size: 14, color: kAccent),
                    SizedBox(width: 8),
                    Text('Aucun administrateur nommé',
                        style: TextStyle(fontSize: 12, color: kAccent, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: taux / 100,
                      backgroundColor: kEBorder,
                      color: kPrimary,
                      minHeight: 6,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text('${taux.toStringAsFixed(0)}%',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: kPrimary)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── TAB 2 : Départements ────────────────────────────────────────
  Widget _tabDepartements() {
    if (_departements.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: kPrimary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
                border: Border.all(color: kPrimary.withValues(alpha: 0.2), width: 1),
              ),
              child: Icon(Icons.domain_outlined, size: 48, color: kPrimary),
            ),
            const SizedBox(height: 16),
            const Text('Aucun département', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: kEDark)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _charger,
      color: kPrimary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _departements.length,
        itemBuilder: (_, i) {
          final d = _departements[i];
          final taux = (d['taux_moyen'] as num? ?? 0).toDouble();
          final cadre = d['cadre'];
          final parcours = d['parcours'] ?? '';
          final nbCours = d['nb_cours'] ?? 0;
          final nbApprenants = d['nb_apprenants'] ?? 0;
          
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kECard,
              borderRadius: BorderRadius.circular(kRadiusMd),
              border: Border.all(color: kEBorder, width: 1),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: kPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(kRadiusSm),
                    border: Border.all(color: kPrimary.withValues(alpha: 0.2), width: 0.8),
                  ),
                  child: const Icon(Icons.domain, color: kPrimary, size: 18),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(d['nom'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: kEDark)),
                      Text(
                        '$nbCours cours · $nbApprenants apprenants',
                        style: const TextStyle(fontSize: 12, color: kEMuted),
                      ),
                      if (parcours.isNotEmpty)
                        Text('Parcours: $parcours',
                            style: const TextStyle(fontSize: 11, color: kEMuted)),
                      if (cadre != null)
                        Text('Cadre: ${cadre['nom'] ?? ''}',
                            style: const TextStyle(fontSize: 11, color: kPrimary)),
                    ],
                  ),
                ),
                Text('${taux.toStringAsFixed(0)}%',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: kPrimary, fontSize: 16)),
              ],
            ),
          );
        },
      ),
    );
  }

  // ─── TAB 3 : Vue globale ─────────────────────────────────────────
  Widget _tabGlobal() {
    final cards = [
      _GS('Parcours', '${_stats['nb_parcours'] ?? 0}', Icons.route, kPrimary),
      _GS('Départements', '${_stats['nb_departements'] ?? 0}', Icons.domain, kTealDark),
      _GS('Cours', '${_stats['nb_cours'] ?? 0}', Icons.book, kPurple),
      _GS('Apprenants', '${_stats['nb_apprenants'] ?? 0}', Icons.people, kGold),
      _GS('Enseignants', '${_stats['nb_enseignants'] ?? 0}', Icons.person_outline, kAccent),
      _GS('Leçons', '${_stats['nb_lecons'] ?? 0}', Icons.play_lesson, kTealLight),
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: cards.map((c) => _buildGCard(c)).toList(),
          ),
          if (_topEnseignants.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Row(
              children: [
                Icon(Icons.emoji_events, color: kGold, size: 20),
                SizedBox(width: 8),
                Text('Top enseignants',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kEDark)),
              ],
            ),
            const SizedBox(height: 12),
            ..._topEnseignants.asMap().entries.map((e) {
              final i = e.key;
              final t = e.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: kECard,
                  borderRadius: BorderRadius.circular(kRadiusMd),
                  border: Border.all(color: kEBorder, width: 1),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: i == 0
                            ? kGold
                            : i == 1
                                ? kEMuted
                                : kAccent,
                        shape: BoxShape.circle,
                      ),
                      child: Text('${i + 1}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t['nom'] ?? '',
                              style: const TextStyle(fontWeight: FontWeight.w600, color: kEDark)),
                          Text(t['role'] ?? '',
                              style: const TextStyle(fontSize: 11, color: kEMuted)),
                        ],
                      ),
                    ),
                    Text('${(t['score'] as num? ?? 0).toStringAsFixed(1)}/20',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: kPrimary)),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  // ─── TAB 4 : Enseignants ──────────────────────────────────────────
  Widget _tabEnseignants() {
    return Column(
      children: [
        // Barre de recherche et filtres
        Container(
          padding: const EdgeInsets.all(16),
          color: kECard,
          child: Column(
            children: [
              TextField(
                decoration: InputDecoration(
                  hintText: 'Rechercher un enseignant...',
                  prefixIcon: const Icon(Icons.search, color: kPrimary),
                  filled: true,
                  fillColor: kEBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(kRadiusMd),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(kRadiusMd),
                    borderSide: BorderSide(color: kEBorder, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(kRadiusMd),
                    borderSide: const BorderSide(color: kPrimary, width: 1.5),
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear, color: kEMuted),
                    onPressed: () {
                      setState(() => _searchQuery = '');
                      _rechercherEnseignants();
                    },
                  ),
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
                onSubmitted: (_) => _rechercherEnseignants(),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // Filtre par type
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: kEBg,
                        borderRadius: BorderRadius.circular(kRadiusMd),
                        border: Border.all(color: kEBorder, width: 1),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _filterUserType.isEmpty ? null : _filterUserType,
                          hint: const Text('Type', style: TextStyle(fontSize: 13)),
                          items: [
                            const DropdownMenuItem(value: '', child: Text('Tous', style: TextStyle(fontSize: 13))),
                            const DropdownMenuItem(value: 'enseignant', child: Text('Enseignant', style: TextStyle(fontSize: 13))),
                            const DropdownMenuItem(value: 'enseignant_principal', child: Text('Enseignant Principal', style: TextStyle(fontSize: 13))),
                            const DropdownMenuItem(value: 'enseignant_cadre', child: Text('Enseignant Cadre', style: TextStyle(fontSize: 13))),
                            const DropdownMenuItem(value: 'enseignant_admin', child: Text('Enseignant Admin', style: TextStyle(fontSize: 13))),
                          ],
                          onChanged: (value) {
                            setState(() => _filterUserType = value ?? '');
                            _rechercherEnseignants();
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Filtre par état
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: kEBg,
                        borderRadius: BorderRadius.circular(kRadiusMd),
                        border: Border.all(color: kEBorder, width: 1),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _filterStatus.isEmpty ? null : _filterStatus,
                          hint: const Text('État', style: TextStyle(fontSize: 13)),
                          items: [
                            const DropdownMenuItem(value: '', child: Text('Tous', style: TextStyle(fontSize: 13))),
                            const DropdownMenuItem(value: 'true', child: Text('Autorisé', style: TextStyle(fontSize: 13))),
                            const DropdownMenuItem(value: 'false', child: Text('Non autorisé', style: TextStyle(fontSize: 13))),
                          ],
                          onChanged: (value) {
                            setState(() => _filterStatus = value ?? '');
                            _rechercherEnseignants();
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Bouton de recherche
                    ElevatedButton.icon(
                      onPressed: _rechercherEnseignants,
                      icon: const Icon(Icons.search, size: 16),
                      label: const Text('Rechercher'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusMd)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Liste des enseignants
        Expanded(
          child: _loadingEnseignants
              ? const Center(child: CircularProgressIndicator(color: kPrimary))
              : _enseignants.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: kPrimary.withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                              border: Border.all(color: kPrimary.withValues(alpha: 0.2), width: 1),
                            ),
                            child: Icon(Icons.person_outline, size: 48, color: kPrimary),
                          ),
                          const SizedBox(height: 16),
                          const Text('Aucun enseignant trouvé',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: kEDark)),
                          const SizedBox(height: 8),
                          const Text('Essayez d\'ajuster vos filtres de recherche',
                              style: TextStyle(fontSize: 13, color: kEMuted)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _enseignants.length,
                      itemBuilder: (_, i) => _buildEnseignantCard(_enseignants[i]),
                    ),
        ),
      ],
    );
  }

  Widget _buildEnseignantCard(Map e) {
    final isActive = e['is_active'] ?? false;
    final userType = e['user_type'] ?? 'enseignant';
    final typeLabel = {
      'enseignant': 'Enseignant',
      'enseignant_principal': 'Enseignant Principal',
      'enseignant_cadre': 'Enseignant Cadre',
      'enseignant_admin': 'Enseignant Administrateur',
    }[userType] ?? userType;
    final avatarUrl = e['avatar'];
    final dateJoined = e['date_joined'] != null 
        ? DateTime.parse(e['date_joined']).toLocal()
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: kECard,
        borderRadius: BorderRadius.circular(kRadiusMd),
        border: Border.all(color: isActive ? kPrimary.withValues(alpha: 0.3) : kAccent.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 26,
                  backgroundColor: kPrimary.withValues(alpha: 0.1),
                  backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                  child: avatarUrl == null
                      ? Text(
                          (e['nom'] ?? e['username'] ?? '?')[0].toUpperCase(),
                          style: const TextStyle(color: kPrimary, fontWeight: FontWeight.bold, fontSize: 18),
                        )
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e['nom'] ?? e['username'] ?? 'Inconnu',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: kEDark),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        e['email'] ?? '',
                        style: const TextStyle(fontSize: 12, color: kEMuted),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: kPrimary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              typeLabel,
                              style: TextStyle(fontSize: 10, color: kPrimary, fontWeight: FontWeight.w600),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isActive ? kGreen.withValues(alpha: 0.1) : kAccent.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isActive ? '✓ Autorisé' : '✗ Non autorisé',
                              style: TextStyle(
                                fontSize: 10,
                                color: isActive ? kGreen : kAccent,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Boutons d'action
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: kPrimary),
                  tooltip: 'Modifier le profil',
                  onPressed: () => _modifierEnseignant(e),
                ),
              ],
            ),
            if (dateJoined != null) ...[
              const SizedBox(height: 8),
              Text(
                'Inscrit le ${DateFormat('dd/MM/yyyy').format(dateJoined)}',
                style: const TextStyle(fontSize: 11, color: kEMuted),
              ),
            ],
            if (e['bio'] != null && e['bio'].toString().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                e['bio'],
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: kEMuted),
              ),
            ],
            if (e['phone'] != null && e['phone'].toString().isNotEmpty) ...[
              const SizedBox(height: 2),
              Text('📞 ${e['phone']}', style: const TextStyle(fontSize: 11, color: kEMuted)),
            ],
          ],
        ),
      ),
    );
  }

  // ─── TAB 5 : Tous les cours ───────────────────────────────────────
  Widget _tabTousCours() {
    return FutureBuilder<List>(
      future: _chargerTousLesCours(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: kPrimary));
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline_rounded, size: 48, color: kAccent),
                const SizedBox(height: 16),
                const Text('Erreur lors du chargement des cours', style: TextStyle(fontSize: 16, color: kEDark)),
              ],
            ),
          );
        }
        final cours = snapshot.data ?? [];
        if (cours.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: kPrimary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                    border: Border.all(color: kPrimary.withValues(alpha: 0.2), width: 1),
                  ),
                  child: Icon(Icons.book_outlined, size: 48, color: kPrimary),
                ),
                const SizedBox(height: 16),
                const Text('Aucun cours créé', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: kEDark)),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: _charger,
          color: kPrimary,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: cours.length,
            itemBuilder: (_, i) => _buildCoursCard(cours[i]),
          ),
        );
      },
    );
  }

  Widget _buildCoursCard(Map cours) {
    final colorHex = (cours['color_code'] as String? ?? '#008080').replaceAll('#', '');
    Color coursColor;
    try {
      coursColor = Color(int.parse('FF$colorHex', radix: 16));
    } catch (_) {
      coursColor = kPrimary;
    }
    
    // Pour l'admin général, utiliser le rôle adminGeneral
    final RoleEnseignant role = RoleEnseignant.administrateurGeneral;
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DetailCoursEnseignantPage(
              coursId: cours['id'].toString(),
              titre: cours['titre'] ?? 'Sans titre',
              estEnseignantPrincipal: false,
              role: role,
              courseColor: coursColor,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: kECard,
          borderRadius: BorderRadius.circular(kRadiusMd),
          border: Border.all(color: kEBorder, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: coursColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(kRadiusSm),
                  border: Border.all(color: coursColor.withValues(alpha: 0.2), width: 0.8),
                ),
                child: Icon(Icons.book, color: coursColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cours['titre'] ?? 'Sans titre',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: kEDark),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${cours['niveau'] ?? 'Niveau non spécifié'} · ${cours['nb_apprenants'] ?? 0} apprenants',
                      style: const TextStyle(fontSize: 12, color: kEMuted),
                    ),
                    if (cours['departement'] != null)
                      Text(
                        'Département: ${cours['departement']}',
                        style: const TextStyle(fontSize: 11, color: kEMuted),
                      ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: kPrimary, size: 14),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGCard(_GS item) {
    return Container(
      decoration: BoxDecoration(
        color: kECard,
        borderRadius: BorderRadius.circular(kRadiusLg),
        border: Border.all(color: kEBorder, width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(kRadiusMd),
              border: Border.all(color: item.color.withValues(alpha: 0.2), width: 0.8),
            ),
            child: Icon(item.icon, color: item.color, size: 22),
          ),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.value,
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: item.color)),
              Text(item.label,
                  style: const TextStyle(fontSize: 12, color: kEMuted)),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────
  Widget _sheetHandle() => Center(
    child: Container(
      width: 40, height: 4,
      decoration: BoxDecoration(color: kEBorder, borderRadius: BorderRadius.circular(10)),
    ),
  );

  Widget _field(TextEditingController ctrl, String label, IconData icon, String hint,
      {int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: const TextStyle(color: kEDark, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: const TextStyle(color: kEMuted, fontSize: 13),
        labelStyle: const TextStyle(color: kEMuted, fontSize: 13),
        prefixIcon: Icon(icon, color: kPrimary, size: 20),
        filled: true,
        fillColor: kEBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kRadiusMd),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kRadiusMd),
          borderSide: BorderSide(color: kEBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kRadiusMd),
          borderSide: const BorderSide(color: kPrimary, width: 1.5),
        ),
      ),
    );
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: kAccent,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusMd)),
      ),
    );
  }

  void _showSuccess(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: kGreen,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusMd)),
      ),
    );
  }
}

class _GS {
  final String label, value;
  final IconData icon;
  final Color color;
  const _GS(this.label, this.value, this.icon, this.color);
}

class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  const _StickyTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: kECard,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_StickyTabBarDelegate oldDelegate) => false;
}