// lib/views/pages/enseignants/edit_profil_page.dart (ou shared/edit_profil_page.dart)
// ═══════════════════════════════════════════════════════════════════════════
// PAGE D'ÉDITION DU PROFIL — AVEC VILLE ET WHATSAPP
// ═══════════════════════════════════════════════════════════════════════════

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
  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _lastNameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _bioCtrl;
  late final TextEditingController _niveauCtrl;
  late final TextEditingController _villeCtrl;
  late final TextEditingController _whatsappCtrl;

  String? _cursus;
  Uint8List? _avatarBytes;
  String? _avatarName;
  bool _saving = false;
  bool _loadingProfil = true;
  Map<String, dynamic> _profil = {};

  final List<String> _cursusOptions = [
    'Secondaire - Francophone',
    'Secondaire - Anglophone',
    'Licence',
  ];

  @override
  void initState() {
    super.initState();
    _firstNameCtrl = TextEditingController();
    _lastNameCtrl = TextEditingController();
    _emailCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    _bioCtrl = TextEditingController();
    _niveauCtrl = TextEditingController();
    _villeCtrl = TextEditingController();
    _whatsappCtrl = TextEditingController();
    _cursus = _cursusOptions.first;
    _fetchProfil();
  }

  Future<void> _fetchProfil() async {
    final token = await _getToken();
    if (token == null) {
      if (mounted) setState(() => _loadingProfil = false);
      return;
    }
    try {
      final res = await http.get(
        Uri.parse(ApiConstants.profilMe),
        headers: {'Authorization': 'Token $token'},
      );
      if (res.statusCode == 200) {
        final profil = jsonDecode(res.body) as Map<String, dynamic>;
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
          _loadingProfil = false;
        });
      } else if (mounted) {
        setState(() => _loadingProfil = false);
      }
    } catch (e) {
      if (mounted) setState(() => _loadingProfil = false);
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

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> _pickAvatar() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );
      if (result != null && result.files.single.bytes != null) {
        setState(() {
          _avatarBytes = result.files.single.bytes;
          _avatarName = result.files.single.name;
        });
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, 'Erreur lors de la sélection de l\'image');
      }
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    
    setState(() => _saving = true);
    
    final token = await _getToken();
    if (token == null) {
      if (mounted) {
        ErrorHandler.showError(context, 'Session expirée. Veuillez vous reconnecter.');
        setState(() => _saving = false);
      }
      return;
    }

    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}/profil/update/');
      final request = http.MultipartRequest('PATCH', uri);
      request.headers['Authorization'] = 'Token $token';

      // Ajout des champs texte
      request.fields['first_name'] = _firstNameCtrl.text.trim();
      request.fields['last_name'] = _lastNameCtrl.text.trim();
      request.fields['email'] = _emailCtrl.text.trim();
      request.fields['phone'] = _phoneCtrl.text.trim();
      request.fields['bio'] = _bioCtrl.text.trim();
      request.fields['niveau'] = _niveauCtrl.text.trim();
      request.fields['ville'] = _villeCtrl.text.trim();
      request.fields['whatsapp'] = _whatsappCtrl.text.trim();
      
      if (_cursus != null && _cursus!.isNotEmpty) {
        request.fields['cursus'] = _cursus!;
      }

      // Ajout de l'avatar si sélectionné
      if (_avatarBytes != null && _avatarName != null) {
        final extension = _avatarName!.split('.').last.toLowerCase();
        final mimeType = extension == 'png' ? 'png' : 'jpeg';
        
        request.files.add(
          http.MultipartFile.fromBytes(
            'avatar',
            _avatarBytes!,
            filename: _avatarName,
            contentType: MediaType('image', mimeType),
          ),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (!mounted) return;
      
      setState(() => _saving = false);

      if (response.statusCode == 200) {
        ErrorHandler.showSuccess(context, 'Profil mis à jour avec succès !');
        Navigator.pop(context, true);
      } else {
        String errorMessage = 'Erreur ${response.statusCode}';
        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['detail'] ?? errorData['message'] ?? errorMessage;
        } catch (_) {}
        ErrorHandler.showError(context, errorMessage);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ErrorHandler.showError(context, 'Erreur réseau: ${e.toString()}');
      }
    }
  }

  bool get _isEnseignant {
    final userType = _profil['user_type']?.toString() ?? '';
    return userType.contains('enseignant') || userType == 'admin';
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingProfil) {
      return const Scaffold(
        backgroundColor: YekiColors.backgroundLight,
        body: Center(child: CircularProgressIndicator(color: YekiColors.primaryDark)),
      );
    }

    final currentAvatarUrl = _profil['avatar'] as String?;

    return Scaffold(
      backgroundColor: YekiColors.backgroundLight,
      appBar: AppBar(
        title: const Text(
          "Édition du Profil",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: YekiColors.white),
        ),
        backgroundColor: YekiColors.textDark,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: YekiColors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ── Avatar ────────────────────────────────────
            _buildAvatarSection(currentAvatarUrl),
            const SizedBox(height: 30),

            // ── Informations personnelles ─────────────────
            _formSection("Informations Personnelles", [
              _buildField("Prénom", _firstNameCtrl, Icons.person_outline),
              _buildField("Nom", _lastNameCtrl, Icons.person_outline),
              _buildField("Bio / Résumé", _bioCtrl, Icons.description_outlined, maxLines: 3),
            ]),

            // ── Scolarité ─────────────────────────────────
            _formSection("Scolarité", [
              _buildDropdown("Cursus actuel", _cursus, _cursusOptions, (value) => setState(() => _cursus = value)),
              _buildField("Niveau d'étude", _niveauCtrl, Icons.school_outlined),
            ]),

            // ── Contact ───────────────────────────────────
            _formSection("Contact", [
              _buildField("Email", _emailCtrl, Icons.email_outlined, type: TextInputType.emailAddress),
              _buildField("Téléphone", _phoneCtrl, Icons.phone_outlined, type: TextInputType.phone),
              _buildField("Ville", _villeCtrl, Icons.location_on_outlined),
              if (_isEnseignant)
                _buildField("WhatsApp", _whatsappCtrl, Icons.chat_bubble_outline, type: TextInputType.phone),
            ]),

            const SizedBox(height: 20),
            _buildSaveButton(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarSection(String? currentAvatarUrl) {
    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundColor: YekiColors.primaryDark,
            child: CircleAvatar(
              radius: 57,
              backgroundColor: YekiColors.white,
              backgroundImage: _avatarBytes != null
                  ? MemoryImage(_avatarBytes!) as ImageProvider
                  : (currentAvatarUrl != null && currentAvatarUrl.isNotEmpty
                      ? NetworkImage(currentAvatarUrl)
                      : const AssetImage('assets/images/user.jpg') as ImageProvider),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: FloatingActionButton.small(
              onPressed: _pickAvatar,
              backgroundColor: YekiColors.primaryDark,
              child: const Icon(Icons.camera_alt, color: YekiColors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _formSection(String title, List<Widget> fields) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 5, bottom: 10, top: 20),
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: YekiColors.textDark,
              fontSize: 15,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: YekiColors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: YekiShadows.subtle,
          ),
          child: Column(children: fields),
        ),
      ],
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller,
    IconData icon, {
    int maxLines = 1,
    TextInputType type = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: type,
        style: const TextStyle(color: YekiColors.textDark),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: YekiColors.textMedium),
          prefixIcon: Icon(icon, color: YekiColors.primaryDark, size: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: YekiColors.borderLight),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: YekiColors.borderLight),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: YekiColors.primaryDark, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: YekiColors.error),
          ),
          filled: true,
          fillColor: YekiColors.white,
        ),
      ),
    );
  }

  Widget _buildDropdown<T>(
    String label,
    T? value,
    List<T> items,
    void Function(T?) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: DropdownButtonFormField<T>(
        value: items.contains(value) ? value : items.first,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: YekiColors.textMedium),
          prefixIcon: Icon(Icons.list_alt_rounded, color: YekiColors.primaryDark),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: YekiColors.borderLight),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: YekiColors.borderLight),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: YekiColors.primaryDark, width: 1.5),
          ),
          filled: true,
          fillColor: YekiColors.white,
        ),
        items: items.map((item) {
          return DropdownMenuItem<T>(
            value: item,
            child: Text(
              item.toString(),
              style: const TextStyle(color: YekiColors.textDark),
            ),
          );
        }).toList(),
        onChanged: onChanged,
        dropdownColor: YekiColors.white,
        icon: Icon(Icons.keyboard_arrow_down_rounded, color: YekiColors.primaryDark),
        style: const TextStyle(color: YekiColors.textDark),
      ),
    );
  }

  Widget _buildSaveButton() {
    return YekiButton(
      label: "Enregistrer les modifications",
      icon: Icons.save_rounded,
      onPressed: _saving ? null : _save,
      isLoading: _saving,
      backgroundColor: YekiColors.primaryDark,
    );
  }
}