import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';

Future<String> extractTextFromDocx(String assetPath) async {
  final bytes = await rootBundle.load(assetPath);
  final archive = ZipDecoder().decodeBytes(bytes.buffer.asUint8List());

  final documentXml = archive.files.firstWhere(
    (file) => file.name == 'word/document.xml',
    orElse: () => throw Exception("Fichier XML non trouvé"),
  );

  final content = utf8.decode(documentXml.content);
  final text = content
      .replaceAll(RegExp(r'</w:p>'), '\n')
      .replaceAll(RegExp(r'<[^>]+>'), '')
      .trim();

  return text;
}

class LectureLeconPage extends StatefulWidget {
  final String titre;
  final String pdfUrl;

  const LectureLeconPage({
    super.key,
    required this.titre,
    required this.pdfUrl,
  });

  @override
  State<LectureLeconPage> createState() => _LectureLeconPageState();
}

class _LectureLeconPageState extends State<LectureLeconPage> {
  String contenu = "";
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    extractTextFromDocx(widget.pdfUrl).then((text) {
      setState(() {
        contenu = text;
        isLoading = false;
      });
    });
  }

  void _showQuestionModal() {
  final TextEditingController controller = TextEditingController();
  bool isSending = false;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              top: 20,
              left: 20,
              right: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const Text(
                  "Poser une question",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF03224C),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: controller,
                  minLines: 3,
                  maxLines: 5,
                  textInputAction: TextInputAction.newline,
                  decoration: InputDecoration(
                    hintText: "Écris ta question ici...",
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: const EdgeInsets.all(16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Bouton enregistrement vocal (non fonctionnel pour l'instant)
                ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text("Fonctionnalité à venir : enregistrement vocal"),
                    ));
                  },
                  icon: const Icon(Icons.mic),
                  label: const Text("Enregistrer un vocal"),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
                const SizedBox(height: 14),

                // Bouton envoyer
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: isSending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.send),
                    label: Text(isSending ? "Envoi en cours..." : "Envoyer"),
                    onPressed: () async {
                      if (controller.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text("Veuillez saisir une question."),
                        ));
                        return;
                      }

                      setModalState(() => isSending = true);
                      await Future.delayed(const Duration(seconds: 1)); // Simulation de traitement

                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text("Votre question a été envoyée avec succès !"),
                        backgroundColor: Colors.teal,
                      ));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF03224C),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      );
    },
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.titre, style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF03224C),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // futur système de recherche dans le texte
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : HtmlWidget(contenu.replaceAll('\n', '<br>')),
          const SizedBox(height: 24),

          // --- Poser une question ---
          Center(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.question_answer),
              label: const Text("Poser une question"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
              ),
              onPressed: _showQuestionModal,
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
