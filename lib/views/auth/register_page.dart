import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
//import 'dart:developer';
import 'login_page.dart';



class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  //final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController(); // 👈 Nouveau champ
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  String? selectedUserType;
  String? selectedCursus;
  String? selectedSubCursus;
  String? selectedNiveau;
  String? selectedFiliere; // 👈 Nouveau champ pour F2, F3, ...
  String? selectedLicence;

  final userTypes = ["Apprenant", "Enseignant"];
  final cursusOptions = [
    "Secondaire francophone",
    "Secondaire anglophone",
    "Licence"
  ];
  final subOptions = ["Générale", "Technique"];
  final filiereOptions = ["F1", "F2", "F3", "F4", "F5"];

  final niveauxFrGeneral = [
    "6ème",
    "5ème",
    "4ème",
    "3ème",
    "2nde A",
    "2nde C",
    "1ère A",
    "1ère C",
    "Terminale A",
    "Terminale C"
  ];

  final niveauxFrTechnique = ["1ère année", "2ème année", "3ème année"];

  final niveauxEnGeneral = [
    "Form 1",
    "Form 2",
    "Form 3",
    "Form 4",
    "Form 5",
    "Lower Sixth",
    "Upper Sixth"
  ];

  final niveauxEnTechnique = ["1st Year", "2nd Year", "3rd Year"];

  final licenceOptions = [
    "Mathématiques",
    "Physique",
    "Génie des procédés métallurgiques",
    "Droit",
    "Biologie animale",
    "Biologie végétale"
  ];

  void _submitRegistration() async {
    final dio = Dio();

    final body = {
      "username": _usernameController.text,
      "email": _emailController.text,
      "password": _passwordController.text,
      "name": _nameController.text,
      "user_type": selectedUserType?.toLowerCase(),
      "cursus": selectedCursus,
      "sub_cursus": selectedSubCursus,
      "niveau": selectedNiveau,
      "filiere": selectedFiliere,
      "licence": selectedLicence,
    };

    try {
      final response = await dio.post(
        'https://yekiapp.pythonanywhere.com/api/auth/register/',
        data: body,
        options: Options(
          headers: {"Content-Type": "application/json"},
        ),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        // ✅ Inscription réussie
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      } else {
        // ❌ Erreur du backend (pas 201)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erreur ${response.statusCode}: ${response.data}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } on DioException catch (e) {
      final errorMsg = e.response?.data.toString() ?? e.message;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur : $errorMsg"),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      // ❌ Autres erreurs
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur inattendue : $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // HEADER BLEU
            Container(
              height: size.height * 0.35,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFF3498db),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  SizedBox(height: 20),
                  Image(
                    image: AssetImage("assets/images/yeki_logo.png"),
                    width: 80,
                    height: 80,
                  ),
                  SizedBox(height: 12),
                  Text(
                    "Creation d'un nouveau compte",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 18,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),

            // FORMULAIRE
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
              child: Material(
                elevation: 20,
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                          labelText: "Nom complet",
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                          prefixIcon: const Icon(Icons.person)),
                      validator: (value) =>
                          value!.isEmpty ? "Entrez votre nom" : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                          labelText: "Nom d'utilisateur",
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                          prefixIcon: const Icon(Icons.account_circle)),
                      validator: (value) =>
                          value!.isEmpty ? "Nom d'utilisateur requis" : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                          labelText: "Email",
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                          prefixIcon: const Icon(Icons.email)),
                      validator: (value) =>
                          value!.contains("@") ? null : "Email invalide",
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedUserType,
                      decoration: InputDecoration(
                          labelText: "Type d'utilisateur",
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12))),
                      items: userTypes
                          .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (value) => setState(() {
                        selectedUserType = value;
                        selectedCursus = null;
                        selectedSubCursus = null;
                        selectedNiveau = null;
                        selectedLicence = null;
                      }),
                      validator: (value) =>
                          value == null ? "Choisissez un type" : null,
                    ),
                    const SizedBox(height: 16),
                    if (selectedUserType == "Apprenant") ...[
                      DropdownButtonFormField<String>(
                        value: selectedCursus,
                        decoration: InputDecoration(
                            labelText: "Cursus",
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12))),
                        items: cursusOptions
                            .map((e) =>
                                DropdownMenuItem(value: e, child: Text(e)))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedCursus = value;
                            selectedSubCursus = null;
                            selectedNiveau = null;
                            selectedLicence = null;
                            selectedFiliere = null;
                          });
                        },
                        validator: (value) =>
                            value == null ? "Choisissez un cursus" : null,
                      ),
                      const SizedBox(height: 16),
                      if (selectedCursus != null && selectedCursus != "Licence")
                        DropdownButtonFormField<String>(
                          value: selectedSubCursus,
                          decoration: InputDecoration(
                              labelText: "Type",
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12))),
                          items: subOptions
                              .map((e) =>
                                  DropdownMenuItem(value: e, child: Text(e)))
                              .toList(),
                          onChanged: (value) => setState(() {
                            selectedSubCursus = value;
                            selectedNiveau = null;
                            selectedFiliere = null;
                          }),
                          validator: (value) =>
                              value == null ? "Choisissez une option" : null,
                        ),
                        const SizedBox(height: 16),
                      if (selectedSubCursus == "Technique")
                        DropdownButtonFormField<String>(
                          value: selectedFiliere,
                          decoration: InputDecoration(
                              labelText: "Filière technique",
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12))),
                          items: filiereOptions
                              .map((e) =>
                                  DropdownMenuItem(value: e, child: Text(e)))
                              .toList(),
                          onChanged: (value) =>
                              setState(() => selectedFiliere = value),
                          validator: (value) =>
                              value == null ? "Choisissez une filière" : null,
                        ),
                      if (selectedCursus == "Secondaire francophone" &&
                          selectedSubCursus == "Générale")
                        DropdownButtonFormField<String>(
                          value: selectedNiveau,
                          decoration: InputDecoration(
                              labelText: "Niveau",
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12))),
                          items: niveauxFrGeneral
                              .map((e) =>
                                  DropdownMenuItem(value: e, child: Text(e)))
                              .toList(),
                          onChanged: (value) =>
                              setState(() => selectedNiveau = value),
                          validator: (value) =>
                              value == null ? "Choisissez un niveau" : null,
                        ),
                      if (selectedCursus == "Secondaire francophone" &&
                          selectedSubCursus == "Technique")
                        DropdownButtonFormField<String>(
                          value: selectedNiveau,
                          decoration: InputDecoration(
                              labelText: "Niveau technique",
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12))),
                          items: niveauxFrTechnique
                              .map((e) =>
                                  DropdownMenuItem(value: e, child: Text(e)))
                              .toList(),
                          onChanged: (value) =>
                              setState(() => selectedNiveau = value),
                          validator: (value) =>
                              value == null ? "Choisissez un niveau" : null,
                        ),
                      if (selectedCursus == "Secondaire anglophone" &&
                          selectedSubCursus == "Générale")
                        DropdownButtonFormField<String>(
                          value: selectedNiveau,
                          decoration: InputDecoration(
                              labelText: "Niveau général anglophone",
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12))),
                          items: niveauxEnGeneral
                              .map((e) =>
                                  DropdownMenuItem(value: e, child: Text(e)))
                              .toList(),
                          onChanged: (value) =>
                              setState(() => selectedNiveau = value),
                          validator: (value) =>
                              value == null ? "Choisissez un niveau" : null,
                        ),
                      if (selectedCursus == "Secondaire anglophone" &&
                          selectedSubCursus == "Technique")
                        DropdownButtonFormField<String>(
                          value: selectedNiveau,
                          decoration: InputDecoration(
                              labelText: "Niveau technique anglophone",
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12))),
                          items: niveauxEnTechnique
                              .map((e) =>
                                  DropdownMenuItem(value: e, child: Text(e)))
                              .toList(),
                          onChanged: (value) =>
                              setState(() => selectedNiveau = value),
                          validator: (value) =>
                              value == null ? "Choisissez un niveau" : null,
                        ),
                      if (selectedCursus == "Licence")
                        DropdownButtonFormField<String>(
                          value: selectedLicence,
                          decoration: InputDecoration(
                              labelText: "Filière de licence",
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12))),
                          items: licenceOptions
                              .map((e) =>
                                  DropdownMenuItem(value: e, child: Text(e)))
                              .toList(),
                          onChanged: (value) =>
                              setState(() => selectedLicence = value),
                          validator: (value) =>
                              value == null ? "Choisissez une filière" : null,
                        ),
                    ],
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: "Mot de passe",
                        prefixIcon: const Icon(Icons.lock),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off),
                          onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (value) => value != null && value.length >= 6
                          ? null
                          : "Minimum 6 caractères",
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirm,
                      decoration: InputDecoration(
                        labelText: "Confirmation",
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureConfirm
                              ? Icons.visibility
                              : Icons.visibility_off),
                          onPressed: () => setState(
                              () => _obscureConfirm = !_obscureConfirm),
                        ),
                      ),
                      validator: (value) => value == _passwordController.text
                          ? null
                          : "Les mots de passe ne correspondent pas",
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _submitRegistration,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF008080),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                          side: const BorderSide(
                              color: Color(0xFFD0D0D0), width: 1.4),
                        ),
                        padding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 50),
                      ),
                      child: const Text("S'inscrire",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const LoginPage()));
                      },
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                        side: const BorderSide(color: Color(0xFF008080)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50)),
                      ),
                      child: const Text("Connectez-vous",
                          style: TextStyle(color: Color(0xFF008080))),
                    ),
                  ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
