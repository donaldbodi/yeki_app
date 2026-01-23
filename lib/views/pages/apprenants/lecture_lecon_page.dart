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

  String get fullPdfUrl {
    if (widget.pdfUrl.startsWith("http")) {
      return widget.pdfUrl;
    }
    return "https://yekiapp.pythonanywhere.com${widget.pdfUrl}";
  }

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
          builder: (context, setModalState) {
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
                        setModalState(() => isSending = true);

                        // TODO : appel API question contextuelle
                        await Future.delayed(const Duration(seconds: 1));

                        if (mounted) Navigator.pop(context);
                      },
                      child: isSending
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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
              "Page $currentPage",
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 12),
            const Text(
              "Je peux t'expliquer cette page, te la résumer ou répondre à tes questions.",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                // TODO : appel IA
              },
              icon: const Icon(Icons.psychology),
              label: const Text("Expliquer cette page"),
            ),
          ],
        ),
      ),
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    if (widget.pdfUrl.isEmpty) {
      return const Scaffold(
        body: Center(child: Text("Aucun document disponible")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.titre,
          style: const TextStyle(fontSize: 18, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF008080),
      ),
      body: Stack(
        children: [
          SfPdfViewer.network(
            fullPdfUrl,
            controller: _pdfController,
            onPageChanged: (details) {
              setState(() => currentPage = details.newPageNumber);
            },
          ),

          // 🔒 FILIGRANE
          IgnorePointer(
            child: Center(
              child: Opacity(
                opacity: 0.05,
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
