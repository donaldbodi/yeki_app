// lib/views/pages/apprenants/edit_profil_page.dart
//
// Refondu en P11.8 (rituel P5.0) : bascule vers `AuthRepository` (plus de
// `http`/`SharedPreferences` bruts) et les tokens/composants `Yk*`
// (`YkTextField`/`YkDropdown` remplacent les champs faits main).

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'package:yeki/core/design/components/components.dart';
import 'package:yeki/core/design/tokens/tokens.dart';
import 'package:yeki/core/network/api_exception.dart';
import 'package:yeki/repositories/auth_repository.dart';

/// Édition du profil de l'utilisateur CONNECTÉ — toujours « mon propre
/// profil », jamais celui d'un tiers : autonome, fetch son propre profil
/// via `/profil/me/` plutôt que de le recevoir en paramètre (P3.3,
/// nécessaire pour une route déclarative go_router sans état
/// pré-chargé transmis par le site d'appel).
class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _repo = AuthRepository();

  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _niveauCtrl = TextEditingController();
  final _villeCtrl = TextEditingController();
  final _whatsappCtrl = TextEditingController();

  static const _cursusOptions = ['Secondaire - Francophone', 'Secondaire - Anglophone', 'Licence'];

  String? _cursus;
  YkPickedFile? _avatar;
  bool _saving = false;
  bool _chargement = true;
  Map<String, dynamic> _profil = {};

  @override
  void initState() {
    super.initState();
    _cursus = _cursusOptions.first;
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
        final cursusValue = profil['cursus'] as String?;
        _cursus = (cursusValue?.isNotEmpty == true) ? cursusValue : _cursusOptions.first;
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
        'niveau': _niveauCtrl.text.trim(),
        'ville': _villeCtrl.text.trim(),
        'whatsapp': _whatsappCtrl.text.trim(),
        if (_cursus != null && _cursus!.isNotEmpty) 'cursus': _cursus!,
      }, avatar: _avatar);
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
      appBar: AppBar(title: const Text('Édition du profil')),
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
                    YkTextField(controller: _bioCtrl, label: 'Bio / Résumé', type: YkTextFieldType.multiline, maxLines: 3),
                  ],
                ),
              ),
            ),
            SizedBox(height: YkSpacing.md),
            YkSection(
              title: 'Scolarité',
              child: YkCard(
                child: Column(
                  children: [
                    YkDropdown<String>(
                      label: 'Cursus actuel',
                      value: _cursus,
                      items: [for (final c in _cursusOptions) YkDropdownItem(value: c, label: c)],
                      onChanged: (v) => setState(() => _cursus = v),
                    ),
                    SizedBox(height: YkSpacing.sm),
                    YkTextField(controller: _niveauCtrl, label: "Niveau d'étude"),
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
