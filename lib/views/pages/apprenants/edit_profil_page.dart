import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final TextEditingController _nomController = TextEditingController(text: "Donald Bodi");
  final TextEditingController _emailController = TextEditingController(text: "yeki@app.com");
  final TextEditingController _telController = TextEditingController(text: "+237 699000000");
  final TextEditingController _adresseController = TextEditingController();
  final TextEditingController _etablissementController = TextEditingController();
  final TextEditingController _niveauController = TextEditingController();
  final TextEditingController _linkedinController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  String? _genre = "Homme";
  String? _cursus = "Secondaire - Francophone";
  File? _imageFile;
  DateTime? _dateNaissance;

  final List<String> _genres = ["Homme", "Femme", "Autre"];
  final List<String> _cursusList = [
    "Secondaire - Francophone",
    "Secondaire - Anglophone",
    "Licence"
  ];

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _imageFile = File(picked.path));
    }
  }

  void _changerDeCompte() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Changer de compte"),
        content: const Text("Souhaitez-vous vraiment vous déconnecter ?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
          ElevatedButton(
            onPressed: () {
              // TODO: Redirection
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text("Confirmer"),
          ),
        ],
      ),
    );
  }

  void _supprimerCompte() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Supprimer le compte"),
        content: const Text("Cette action est irréversible. Confirmer la suppression ?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
          ElevatedButton(
            onPressed: () {
              // TODO: Supprimer
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Supprimer"),
          )
        ],
      ),
    );
  }

  void _sauvegarderProfil() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Profil mis à jour !")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F6FF),
      appBar: AppBar(
        title: const Text("Modifier le profil"),
        backgroundColor: const Color(0xFF03224C),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _changerDeCompte),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 55,
                  backgroundColor: Colors.white,
                  backgroundImage: _imageFile != null
                      ? FileImage(_imageFile!)
                      : const AssetImage('assets/images/user.jpg') as ImageProvider,
                ),
                Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.orange,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                    onPressed: _pickImage,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // --- Carte d'édition stylée ---
          _buildProfileCard(children: [
            _buildTextField("Nom complet", _nomController, icon: Icons.person),
            _buildTextField("Email", _emailController, type: TextInputType.emailAddress, icon: Icons.email),
            _buildTextField("Téléphone", _telController, type: TextInputType.phone, icon: Icons.phone),
            _buildDropdown("Genre", _genre, _genres, (val) => setState(() => _genre = val), icon: Icons.wc),
            _buildTextField("Adresse", _adresseController, icon: Icons.location_on),
            _buildDatePicker(),
            _buildDropdown("Cursus", _cursus, _cursusList, (val) => setState(() => _cursus = val), icon: Icons.school),
            _buildTextField("Établissement", _etablissementController, icon: Icons.apartment),
            _buildTextField("Niveau d'étude", _niveauController, icon: Icons.grade),
            _buildTextField("Lien LinkedIn ou Facebook", _linkedinController, type: TextInputType.url, icon: Icons.link),
            _buildTextField("Biographie", _bioController, maxLines: 3, icon: Icons.info),
          ]),

          const SizedBox(height: 20),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepOrange,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.save),
            label: const Text("Sauvegarder"),
            onPressed: _sauvegarderProfil,
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            icon: const Icon(Icons.delete_forever, color: Colors.red),
            label: const Text("Supprimer le compte", style: TextStyle(color: Colors.red)),
            onPressed: _supprimerCompte,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {TextInputType type = TextInputType.text, int maxLines = 1, IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType: type,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon != null ? Icon(icon, color: Colors.deepOrange) : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          floatingLabelStyle: const TextStyle(color: Colors.deepOrange),
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, String? value, List<String> items, ValueChanged<String?> onChanged,
      {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: value,
        onChanged: onChanged,
        iconEnabledColor: Colors.deepOrange,
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon != null ? Icon(icon, color: Colors.deepOrange) : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: DateTime(2000),
            firstDate: DateTime(1950),
            lastDate: DateTime.now(),
          );
          if (picked != null) setState(() => _dateNaissance = picked);
        },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: "Date de naissance",
            prefixIcon: const Icon(Icons.cake, color: Colors.deepOrange),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(
            _dateNaissance != null
                ? "${_dateNaissance!.day}/${_dateNaissance!.month}/${_dateNaissance!.year}"
                : "Sélectionner une date",
            style: TextStyle(color: _dateNaissance != null ? Colors.black : Colors.grey),
          ),
        ),
      ),
    );
  }
}
