import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:yeki/views/pages/apprenants/detail_lecon_page.dart';
import 'package:yeki/views/pages/enseignants/interface_enseignant_page.dart';
//import 'lecture_lecon_page.dart';

class LeconsCoursPage extends StatefulWidget {
  final String coursId;
  final RoleEnseignant? role;
  final TabController tabController;

  const LeconsCoursPage({
    super.key,
    required this.coursId,
    this.role,
    required this.tabController,
  });

  @override
  State<LeconsCoursPage> createState() => _LeconsCoursPageState();
}

class _LeconsCoursPageState extends State<LeconsCoursPage> {
  bool loading = true;
  List modules = [];
  final Color primaryColor = const Color(0xFF2884A0);

  static const String _baseUrl = 'https://yeki.pythonanywhere.com/api';

  final List<Map<String, String>> enseignants = const [
    {"nom": "Mr. Talla Jean", "role": "Principal"},
    {"nom": "Mme Carole Ndongo", "role": "Assistant"},
    {"nom": "M. Jules Kamtchoum", "role": "Assistant"},
  ];

  @override
  void initState() {
    super.initState();
    fetchLecons();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> fetchLecons() async {
    setState(() => loading = true);
    final token = await _getToken();
    if (token == null) {
      setState(() => loading = false);
      return;
    }
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/cours/${widget.coursId}/liste-modules/'),
        headers: {'Authorization': 'Token $token'},
      );
      if (res.statusCode == 200) {
        setState(() {
          modules = jsonDecode(res.body);
          loading = false;
        });
      } else {
        setState(() => loading = false);
        _showError('Erreur ${res.statusCode} lors du chargement des modules.');
      }
    } catch (e) {
      setState(() => loading = false);
      _showError('Erreur réseau : $e');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }


  // ── Convertit les modules API en liste de Lecon pour LectureLeconPage ────────
  List<Lecon> _getAllLecons() {
    final List<Lecon> toutes = [];
    int numero = 1;
    for (final module in modules) {
      final lecons = module["lecons"] as List? ?? [];
      for (final l in lecons) {
        toutes.add(Lecon(
          id: l["id"]?.toString() ?? 'l$numero',
          numero: numero,
          titre: l["titre"] ?? "Sans titre",
          duree: l["duree"] ?? "",
          description: l["description"] ?? "",
          hasPdf: (l["fichier_pdf"] != null && l["fichier_pdf"] != ""),
          estTerminee: l["est_termine"] == true,
          videoUrl: l["video_url"] ?? "",
        ));
        numero++;
      }
    }
    return toutes;
  }

  // ── Navigation vers LectureLeconPage ─────────────────────────────────────────
  void _ouvrirLecon(Map lecon, int numero) {
    final toutesLecons = _getAllLecons();

    // Trouver la leçon correspondante dans la liste complète
    final leconObj = toutesLecons.firstWhere(
      (l) => l.id == lecon["id"]?.toString(),
      orElse: () => Lecon(
        id: lecon["id"]?.toString() ?? 'l$numero',
        numero: numero,
        titre: lecon["titre"] ?? "Sans titre",
        duree: lecon["duree"] ?? "",
        description: lecon["description"] ?? "",
        hasPdf: (lecon["fichier_pdf"] != null && lecon["fichier_pdf"] != ""),
        estTerminee: lecon["est_termine"] == true,
        videoUrl: lecon["video_url"] ?? "",
      ),
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DetailLeconPage(
          lecon: leconObj,
          toutesLesLecons: toutesLecons.isNotEmpty ? toutesLecons : [leconObj],
          tabController: widget.tabController,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Center(child: CircularProgressIndicator(color: primaryColor));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Sommaire
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Sommaire du cours",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              if (widget.role == RoleEnseignant.enseignantCadre ||
                  widget.role == RoleEnseignant.enseignantPrincipal)
                IconButton(
                  onPressed: _showCreateModuleDialog,
                  icon: Icon(Icons.add_box, color: primaryColor, size: 30),
                  tooltip: 'Créer un module',
                ),
            ],
          ),
          const SizedBox(height: 20),

          // Liste des modules
          if (modules.isEmpty)
            Center(
              child: Text(
                'Aucun module disponible.',
                style: TextStyle(color: Colors.grey.shade500),
              ),
            )
          else
            ...modules.map((module) => _buildModuleBlock(module)).toList(),

          const SizedBox(height: 30),
          Text(
            "Équipe enseignante",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 15),

          SizedBox(
            height: 150,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const ClampingScrollPhysics(),
              itemCount: enseignants.length,
              separatorBuilder: (_, __) => const SizedBox(width: 15),
              itemBuilder: (context, index) =>
                  _buildTeacherCard(enseignants[index]),
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildModuleBlock(Map module) {
    List lecons = module["lecons"] ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                module["titre"] ?? "",
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (widget.role == RoleEnseignant.enseignantCadre ||
                widget.role == RoleEnseignant.enseignantPrincipal)
              IconButton(
                icon: Icon(
                  Icons.add_circle_outline,
                  color: primaryColor,
                  size: 20,
                ),
                onPressed: () =>
                    _showCreateLeconDialog(module["id"].toString()),
                tooltip: 'Ajouter une leçon',
              ),
          ],
        ),
        if (module["description"] != null && module["description"] != '')
          Text(
            module["description"],
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
              ),
            ],
          ),
          child: lecons.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Aucune leçon dans ce module.',
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 13,
                    ),
                  ),
                )
              : Column(
                  children: lecons.asMap().entries.map((entry) {
                    // Calcul du numéro global de la leçon
                    int globalNum = 1;
                    for (final m in modules) {
                      final ls = m["lecons"] as List? ?? [];
                      for (final l in ls) {
                        if (l["id"]?.toString() ==
                            entry.value["id"]?.toString()) {
                          break;
                        }
                        globalNum++;
                      }
                      if ((m["lecons"] as List? ?? [])
                          .any((l) =>
                              l["id"]?.toString() ==
                              entry.value["id"]?.toString())) {
                        break;
                      }
                    }
                    return _buildLeconTile(entry.value, globalNum);
                  }).toList(),
                ),
        ),
        const SizedBox(height: 25),
      ],
    );
  }

  Widget _buildLeconTile(Map lecon, int numero) {
    return InkWell(
      onTap: () => _ouvrirLecon(lecon, numero), // ← navigation vers LectureLeconPage
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade100),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 4),
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lecon["titre"] ?? "Sans titre",
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3142),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lecon["description"] ?? "Aucune description disponible.",
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.play_circle_outline,
              color: Color(0xFF008088),
              size: 26,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeacherCard(Map ens) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 25,
            backgroundColor: Color(0xFFE0F2F1),
            child: Icon(Icons.person, color: Colors.teal),
          ),
          const SizedBox(height: 10),
          Text(
            ens["nom"]!,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          Text(
            ens["role"]!,
            style: const TextStyle(fontSize: 10, color: Colors.teal),
          ),
        ],
      ),
    );
  }

  Widget _buildModernField(TextEditingController ctrl, String label,
      IconData icon, String hint,
      {int maxLines = 1, bool isNumber = false}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType:
          isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: primaryColor, size: 20),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: primaryColor)),
      ),
    );
  }

  Widget _buildSubmitButton(
      {required bool isLoading,
      required String label,
      required VoidCallback onTap}) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: isLoading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15)),
          elevation: 0,
        ),
        child: isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _showCreateModuleDialog() {
    final titreCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final ordreCtrl = TextEditingController();
    bool isLoading = false;
    ordreCtrl.text = (modules.length + 1).toString();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateSheet) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          padding: EdgeInsets.only(
            left: 25,
            right: 25,
            top: 15,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 20),
              Text("Nouveau Module",
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.blueGrey)),
              const SizedBox(height: 20),
              _buildModernField(
                  titreCtrl, "Titre du module", Icons.title, "Ex: Algèbre linéaire"),
              const SizedBox(height: 15),
              _buildModernField(descCtrl, "Description",
                  Icons.description_outlined, "Objectifs du module",
                  maxLines: 2),
              const SizedBox(height: 15),
              _buildModernField(
                  ordreCtrl, "Position (Ordre)", Icons.sort, "",
                  isNumber: true),
              const SizedBox(height: 25),
              _buildSubmitButton(
                isLoading: isLoading,
                label: "Créer le module",
                onTap: () async {
                  if (titreCtrl.text.isEmpty) {
                    return _showError("Titre requis");
                  }
                  setStateSheet(() => isLoading = true);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateLeconDialog(String moduleId) {
    final titreCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String? selectedPdfName;
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateSheet) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          padding: EdgeInsets.only(
            left: 25,
            right: 25,
            top: 15,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 20),
              Text("Ajouter une leçon",
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.blueAccent)),
              const SizedBox(height: 20),
              _buildModernField(titreCtrl, "Titre de la leçon",
                  Icons.menu_book, "Ex: Chapitre 1 : Introduction"),
              const SizedBox(height: 15),
              _buildModernField(
                  descCtrl,
                  "Résumé / Description",
                  Icons.short_text,
                  "De quoi parle cette leçon ?",
                  maxLines: 3),
              const SizedBox(height: 15),
              InkWell(
                onTap: () async {
                  final result = await FilePicker.platform.pickFiles(
                      type: FileType.custom,
                      allowedExtensions: ['pdf']);
                  if (result != null) {
                    setStateSheet(() {
                      selectedPdfName = result.files.single.name;
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: primaryColor.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.picture_as_pdf, color: primaryColor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          selectedPdfName ?? "Joindre le support PDF",
                          style: TextStyle(
                              color: selectedPdfName != null
                                  ? Colors.blueAccent
                                  : Colors.grey[600],
                              fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (selectedPdfName != null)
                        Icon(Icons.check_circle, color: primaryColor, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 25),
              _buildSubmitButton(
                isLoading: isLoading,
                label: "Publier la leçon",
                onTap: () async {},
              ),
            ],
          ),
        ),
      ),
    );
  }

}