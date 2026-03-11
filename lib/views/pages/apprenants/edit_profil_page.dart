import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';

class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic> profil;
  const EditProfilePage({super.key, required this.profil});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  static const String _base = 'https://yekiapp.pythonanywhere.com/api';

  final Color primaryColor = const Color(0xFF2884A0);
  final Color darkBlue     = const Color(0xFF1A1C1E);

  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _lastNameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _bioCtrl;
  late final TextEditingController _niveauCtrl;

  String? _cursus;
  Uint8List? _avatarBytes;
  String?   _avatarName;
  bool _saving = false;

  final List<String> _cursusOptions = [
    'Secondaire - Francophone',
    'Secondaire - Anglophone',
    'Licence',
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.profil;
    _firstNameCtrl = TextEditingController(text: p['first_name'] ?? '');
    _lastNameCtrl  = TextEditingController(text: p['last_name']  ?? '');
    _emailCtrl     = TextEditingController(text: p['email']      ?? '');
    _phoneCtrl     = TextEditingController(text: p['phone']      ?? '');
    _bioCtrl       = TextEditingController(text: p['bio']        ?? '');
    _niveauCtrl    = TextEditingController(text: p['niveau']     ?? '');
    _cursus = (p['cursus'] as String?)?.isNotEmpty == true
        ? p['cursus']
        : _cursusOptions.first;
  }

  @override
  void dispose() {
    for (final c in [
      _firstNameCtrl, _lastNameCtrl, _emailCtrl,
      _phoneCtrl, _bioCtrl, _niveauCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<String?> _token() async {
    final p = await SharedPreferences.getInstance();
    return p.getString('token');
  }

  Future<void> _pickAvatar() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result != null && result.files.single.bytes != null) {
      setState(() {
        _avatarBytes = result.files.single.bytes;
        _avatarName  = result.files.single.name;
      });
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final token = await _token();
    if (token == null) {
      _snack('Session expirée.', error: true);
      setState(() => _saving = false);
      return;
    }

    try {
      final uri = Uri.parse('$_base/profil/update/');
      final request = http.MultipartRequest('PATCH', uri);
      request.headers['Authorization'] = 'Token $token';

      request.fields['first_name'] = _firstNameCtrl.text.trim();
      request.fields['last_name']  = _lastNameCtrl.text.trim();
      request.fields['email']      = _emailCtrl.text.trim();
      request.fields['phone']      = _phoneCtrl.text.trim();
      request.fields['bio']        = _bioCtrl.text.trim();
      request.fields['niveau']     = _niveauCtrl.text.trim();
      if (_cursus != null) request.fields['cursus'] = _cursus!;

      if (_avatarBytes != null && _avatarName != null) {
        final ext = _avatarName!.split('.').last.toLowerCase();
        final mime = ext == 'png' ? 'png' : 'jpeg';
        request.files.add(http.MultipartFile.fromBytes(
          'avatar',
          _avatarBytes!,
          filename: _avatarName,
          contentType: MediaType('image', mime),
        ));
      }

      final streamed = await request.send();
      final res = await http.Response.fromStream(streamed);

      setState(() => _saving = false);

      if (res.statusCode == 200) {
        _snack('Profil mis à jour !');
        if (mounted) Navigator.pop(context);
      } else {
        _snack('Erreur ${res.statusCode}', error: true);
      }
    } catch (e) {
      setState(() => _saving = false);
      _snack('Erreur réseau : $e', error: true);
    }
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? Colors.red : Colors.green,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final currentAvatarUrl = widget.profil['avatar'] as String?;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      appBar: AppBar(
        title: const Text("Édition du Profil",
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        backgroundColor: darkBlue,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          // ── Avatar ────────────────────────────────────
          Center(
            child: Stack(children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: primaryColor,
                child: CircleAvatar(
                  radius: 57,
                  backgroundColor: Colors.white,
                  backgroundImage: _avatarBytes != null
                      ? MemoryImage(_avatarBytes!) as ImageProvider
                      : (currentAvatarUrl != null &&
                              currentAvatarUrl.isNotEmpty
                          ? NetworkImage(currentAvatarUrl)
                          : const AssetImage('assets/images/user.jpg')
                              as ImageProvider),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: FloatingActionButton.small(
                  onPressed: _pickAvatar,
                  backgroundColor: primaryColor,
                  child: const Icon(Icons.camera_alt,
                      color: Colors.white),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 30),

          // ── Informations personnelles ─────────────────
          _formSection("Informations Personnelles", [
            _buildField("Prénom",     _firstNameCtrl, Icons.person),
            _buildField("Nom",        _lastNameCtrl,  Icons.person_outline),
            _buildField("Bio / Résumé", _bioCtrl,     Icons.info_outline, maxLines: 3),
          ]),

          // ── Scolarité ─────────────────────────────────
          _formSection("Scolarité", [
            _buildDropdown(
              "Cursus actuel",
              _cursus,
              _cursusOptions,
              (v) => setState(() => _cursus = v),
            ),
            _buildField("Niveau d'étude", _niveauCtrl, Icons.grade),
          ]),

          // ── Contact ───────────────────────────────────
          _formSection("Contact", [
            _buildField("Email", _emailCtrl, Icons.email,
                type: TextInputType.emailAddress),
            _buildField("Téléphone", _phoneCtrl, Icons.phone,
                type: TextInputType.phone),
          ]),

          const SizedBox(height: 20),
          _buildSaveButton(),
          const SizedBox(height: 40),
        ]),
      ),
    );
  }

  Widget _formSection(String title, List<Widget> fields) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding:
                const EdgeInsets.only(left: 5, bottom: 10, top: 20),
            child: Text(title,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: darkBlue,
                    fontSize: 15)),
          ),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10)
              ],
            ),
            child: Column(children: fields),
          ),
        ],
      );

  Widget _buildField(
    String label,
    TextEditingController ctrl,
    IconData icon, {
    int maxLines = 1,
    TextInputType type = TextInputType.text,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 15),
        child: TextField(
          controller: ctrl,
          maxLines: maxLines,
          keyboardType: type,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon, color: primaryColor, size: 20),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: primaryColor)),
          ),
        ),
      );

  Widget _buildDropdown(String label, String? value,
          List<String> items, Function(String?) onChanged) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 15),
        child: DropdownButtonFormField<String>(
          value: items.contains(value) ? value : items.first,
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(Icons.list, color: primaryColor),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        ),
      );

  Widget _buildSaveButton() => ElevatedButton(
        onPressed: _saving ? null : _save,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          minimumSize: const Size.fromHeight(55),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15)),
        ),
        child: _saving
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5))
            : const Text("Enregistrer les modifications",
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
      );
}