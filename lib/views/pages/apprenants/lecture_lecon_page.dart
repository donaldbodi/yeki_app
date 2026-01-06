import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

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
  final PdfViewerController _pdfController = PdfViewerController();
  int currentPage = 1;

  // ================= QUESTION CONTEXTUELLE =================
  void _showQuestionModal() {
    final controller = TextEditingController();
    bool isSending = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Question sur la page",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "Page $currentPage",
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    minLines: 3,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: "Pose ta question ici...",
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (controller.text.trim().isEmpty) return;
                        setState(() => isSending = true);
                        await Future.delayed(const Duration(seconds: 1));
                        Navigator.pop(context);
                      },
                      child: isSending
                          ? const CircularProgressIndicator()
                          : const Text("Envoyer"),
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

  // ================= IA PEDAGOGIQUE =================
  void _showIAAssistant() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Assistant pédagogique IA",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              "Aide basée sur la page $currentPage",
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 12),
            const Text(
              "💡 Je peux t'expliquer cette page, te résumer le contenu ou répondre à tes questions.",
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {},
              child: const Text("Demander une explication"),
            ),
          ],
        ),
      ),
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.titre,
          style: TextStyle(
                  fontSize: 18,
                  color: Colors.white70,
                ),),
        backgroundColor: const Color(0xFF008080),
      ),

      body: Stack(
        children: [
          SfPdfViewer.asset(
            widget.pdfUrl,
            controller: _pdfController,
            onPageChanged: (details) {
              setState(() => currentPage = details.newPageNumber);
            },
          ),

          // 🔒 FILIGRANE ANTI-COPIE
          IgnorePointer(
            child: Center(
              child: Opacity(
                opacity: 0.06,
                child: Transform.rotate(
                  angle: -0.4,
                  child: const Text(
                    "GROUPE YEKI",
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),

      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: "question",
            backgroundColor: Colors.orange,
            onPressed: _showQuestionModal,
            child: const Icon(Icons.help_outline),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: "ia",
            backgroundColor: Colors.green,
            onPressed: _showIAAssistant,
            child: const Icon(Icons.smart_toy),
          ),
        ],
      ),
    );
  }
}
