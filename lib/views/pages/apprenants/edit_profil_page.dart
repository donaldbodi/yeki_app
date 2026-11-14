// lib/views/pages/apprenants/edit_profil_page.dart
//
// Refondu en P11.8 (rituel P5.0) : bascule vers `AuthRepository` (plus de
// `http`/`SharedPreferences` bruts) et les tokens/composants `Yk*`
// (`YkTextField`/`YkDropdown` remplacent les champs faits main).

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:yeki/core/design/components/components.dart';
import 'package:yeki/core/design/tokens/tokens.dart';
import 'package:yeki/core/network/api_exception.dart';
import 'package:yeki/core/providers/current_user_provider.dart';
import 'package:yeki/repositories/auth_repository.dart';

/// Édition du profil de l'utilisateur CONNECTÉ — toujours « mon propre
/// profil », jamais celui d'un tiers : autonome, fetch son propre profil
/// via `/profil/me/` plutôt que de le recevoir en paramètre (P3.3,
/// nécessaire pour une route déclarative go_router sans état
/// pré-chargé transmis par le site d'appel).
///
/// Invalide `currentUserProvider` après sauvegarde (bug corrigé : la photo
/// de profil ne se répercutait pas ailleurs dans l'app, ex.
/// `enseignant_shell.dart`, qui la lit désormais depuis ce même provider
/// partagé plutôt que via son propre fetch local figé au premier chargement).
class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _repo = AuthRepository();

  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _niveauCtrl = TextEditingController();
  final _villeCtrl = TextEditingController();
  final _whatsappCtrl = TextEditingController();

  // Cursus/Niveau : lecture seule (voir section "Scolarité" du build())
  // — plus de sélecteur `_cursusOptions`/`FormationRepository.parcours()`
  // à charger, la valeur brute du profil suffit pour un simple affichage.
  String? _cursus;
  DateTime? _dateNaissance;
  YkPickedFile? _avatar;
  bool _saving = false;
  bool _chargement = true;
  Map<String, dynamic> _profil = {};

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    try {
      final profil = await _repo.getCurrentUserRaw();
      if (!mounted) return;
      setState(() {
        _profil = profil;
        _firstNameCtrl.text = profil['first_name'] ?? '';
        _lastNameCtrl.text = profil['last_name'] ?? '';
        _emailCtrl.text = profil['email'] ?? '';
        _phoneCtrl.text = profil['phone'] ?? '';
        _bioCtrl.text = profil['bio'] ?? '';
        _niveauCtrl.text = profil['niveau'] ?? '';
        _villeCtrl.text = profil['ville'] ?? '';
        _whatsappCtrl.text = profil['whatsapp'] ?? '';
        _cursus = profil['cursus'] as String?;
        final dateNaissanceValue = profil['date_naissance'] as String?;
        _dateNaissance = (dateNaissanceValue != null && dateNaissanceValue.isNotEmpty)
            ? DateTime.tryParse(dateNaissanceValue)
            : null;
      });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _chargement = false);
    }
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _bioCtrl.dispose();
    _niveauCtrl.dispose();
    _villeCtrl.dispose();
    _whatsappCtrl.dispose();
    super.dispose();
  }

  Future<void> _enregistrer() async {
    setState(() => _saving = true);
    try {
      await _repo.updateProfil({
        'first_name': _firstNameCtrl.text.trim(),
        'last_name': _lastNameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'bio': _bioCtrl.text.trim(),
        // 'niveau'/'cursus' ne sont plus envoyés — ces 2 champs de scolarité
        // sont passés en lecture seule (demande explicite), voir la section
        // "Scolarité" du build() (YkKeyValue au lieu de YkDropdown/
        // YkTextField). Barrière serveur correspondante :
        // apps/accounts/views/profil.py::ProfilUpdateView.patch().
        'ville': _villeCtrl.text.trim(),
        'whatsapp': _whatsappCtrl.text.trim(),
        if (_dateNaissance != null) 'date_naissance': _dateNaissance!.toIso8601String().split('T').first,
      }, avatar: _avatar);
      ref.invalidate(currentUserProvider);
      if (mounted) {
        YkSnack.success(context, 'Profil mis à jour avec succès !');
        Navigator.pop(context, true);
      }
    } on ApiException catch (e) {
      if (mounted) YkSnack.error(context, e.message);
    } catch (_) {
      if (mounted) YkSnack.error(context, 'Erreur réseau.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  bool get _isEnseignant {
    final userType = _profil['user_type']?.toString() ?? '';
    return userType.contains('enseignant') || userType == 'admin';
  }

  @override
  Widget build(BuildContext context) {
    if (_chargement) {
      return Scaffold(backgroundColor: YkColors.background(context), body: Center(child: YkProgress(shape: YkProgressShape.circular)));
    }

    return Scaffold(
      backgroundColor: YkColors.background(context),
      appBar: const YkGradientAppBar(title: 'Édition du profil'),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(YkSpacing.md),
        child: Column(
          children: [
            _avatarSection(context),
            SizedBox(height: YkSpacing.lg),
            YkSection(
              title: 'Informations personnelles',
              child: YkCard(
                child: Column(
                  children: [
                    YkTextField(controller: _firstNameCtrl, label: 'Prénom'),
                    SizedBox(height: YkSpacing.sm),
                    YkTextField(controller: _lastNameCtrl, label: 'Nom'),
                    SizedBox(height: YkSpacing.sm),
                    YkDateTimePicker(
                      mode: YkDateTimePickerMode.date,
                      label: 'Date de naissance',
                      value: _dateNaissance,
                      onChanged: (d) => setState(() => _dateNaissance = d),
                      firstDate: DateTime.now().subtract(const Duration(days: 365 * 100)),
                      lastDate: DateTime.now(),
                    ),
                    SizedBox(height: YkSpacing.sm),
                    YkTextField(controller: _bioCtrl, label: 'Bio / Résumé', type: YkTextFieldType.multiline, maxLines: 3),
                  ],
                ),
              ),
            ),
            SizedBox(height: YkSpacing.md),
            // Cursus/Niveau d'étude : lecture seule (demande explicite —
            // aucun utilisateur ne doit pouvoir modifier ses informations
            // de scolarité depuis son profil, seulement les consulter).
            // Même motif d'affichage déjà utilisé par `profil_page.dart`
            // pour ces 2 champs.
            YkSection(
              title: 'Scolarité',
              child: YkCard(
                child: Column(
                  children: [
                    YkKeyValue(
                      icon: Icons.route_rounded,
                      label: 'Cursus actuel',
                      value: (_cursus == null || _cursus!.isEmpty) ? 'Non défini' : _cursus!,
                    ),
                    YkKeyValue(
                      icon: Icons.grade_rounded,
                      label: "Niveau d'étude",
                      value: _niveauCtrl.text.isEmpty ? 'Non défini' : _niveauCtrl.text,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: YkSpacing.md),
            YkSection(
              title: 'Contact',
              child: YkCard(
                child: Column(
                  children: [
                    YkTextField(controller: _emailCtrl, label: 'Email'),
                    SizedBox(height: YkSpacing.sm),
                    YkTextField(controller: _phoneCtrl, label: 'Téléphone'),
                    SizedBox(height: YkSpacing.sm),
                    YkTextField(controller: _villeCtrl, label: 'Ville'),
                    if (_isEnseignant) ...[
                      SizedBox(height: YkSpacing.sm),
                      YkTextField(controller: _whatsappCtrl, label: 'WhatsApp'),
                    ],
                  ],
                ),
              ),
            ),
            SizedBox(height: YkSpacing.lg),
            YkButton(label: 'Enregistrer les modifications', icon: Icons.save_rounded, isLoading: _saving, onPressed: _saving ? null : _enregistrer),
            SizedBox(height: YkSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _avatarSection(BuildContext context) {
    final avatarUrlActuel = _profil['avatar'] as String?;
    return Center(
      child: Stack(
        children: [
          ClipOval(
            child: SizedBox(
              width: 114,
              height: 114,
              child: _avatar != null
                  ? Image.memory(_avatar!.bytes, fit: BoxFit.cover)
                  : (avatarUrlActuel != null && avatarUrlActuel.isNotEmpty
                      ? Image.network(avatarUrlActuel, fit: BoxFit.cover)
                      : YkAvatar(fallbackText: _firstNameCtrl.text.isNotEmpty ? _firstNameCtrl.text : '?', size: YkAvatarSize.lg)),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: YkIconButton(
              icon: Icons.camera_alt_rounded,
              label: 'Changer la photo de profil',
              variant: YkIconButtonVariant.filled,
              onPressed: _choisirAvatar,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _choisirAvatar() async {
    // Réutilise `YkFileUpload._pick()` indirectement via son propre
    // sélecteur serait plus lourd qu'utile ici (pas de zone de dépôt
    // nécessaire pour un simple avatar) — on garde `FilePicker` direct
    // mais on lit toujours via `.bytes` (jamais `.path`), cohérent avec
    // la règle CDC §5.5.2 documentée par `YkFileUpload`.
    final resultat = await _ouvrirSelecteurImage();
    if (resultat != null) setState(() => _avatar = resultat);
  }

  Future<YkPickedFile?> _ouvrirSelecteurImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
    final fichier = result?.files.single;
    if (fichier?.bytes == null) return null;
    final extension = fichier!.name.contains('.') ? fichier.name.split('.').last.toLowerCase() : '';
    return YkPickedFile(
      bytes: fichier.bytes!,
      name: fichier.name,
      mimeType: extension == 'png' ? 'image/png' : 'image/jpeg',
      size: fichier.size,
    );
  }
}
