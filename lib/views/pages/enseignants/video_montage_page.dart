/*import 'package:flutter/material.dart';

class VideoMontagePage extends StatefulWidget {
  const VideoMontagePage({super.key});

  @override
  State<VideoMontagePage> createState() => _VideoMontagePageState();
}

class _VideoMontagePageState extends State<VideoMontagePage> {
  List<XFile> images = [];
  String texteNarration = "";
  String? transition;
  final TextEditingController texteController = TextEditingController();
  bool isLoading = false;

  final List<String> transitionsDisponibles = [
    "Fondu enchaîné", "Glissement horizontal", "Zoom", "Fondu au noir"
  ];

  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile>? selected = await picker.pickMultiImage();
    if (selected != null) setState(() => images = selected);
  }

  void _genererVideo() async {
    if (images.isEmpty || texteController.text.trim().isEmpty) return;

    setState(() => isLoading = true);

    // Appel à ton backend (audio + vidéo avec transition)
    final response = await http.post(
      Uri.parse('http://localhost:8000/api/generate-video/'),
      body: {
        'texte': texteController.text,
        'transition': transition ?? 'default',
      },
      // envoyer aussi les fichiers si besoin avec MultipartRequest
    );

    setState(() => isLoading = false);

    if (response.statusCode == 200) {
      // Naviguer vers l’écran de prévisualisation avec la vidéo
      final videoUrl = jsonDecode(response.body)['video_url'];
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => VideoPreviewPage(videoUrl: videoUrl)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Créateur de vidéo de cours")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                children: [
                  ElevatedButton.icon(
                    onPressed: _pickImages,
                    icon: const Icon(Icons.image),
                    label: const Text("Ajouter des images"),
                  ),
                  if (images.isNotEmpty) ...[
                    Text("${images.length} image(s) sélectionnée(s)"),
                    if (images.length > 1)
                      DropdownButton<String>(
                        value: transition,
                        hint: const Text("Choisir une transition"),
                        isExpanded: true,
                        items: transitionsDisponibles.map((t) {
                          return DropdownMenuItem(
                            value: t,
                            child: Text(t),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => transition = value);
                        },
                      ),
                  ],
                  const SizedBox(height: 20),
                  TextField(
                    controller: texteController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: "Texte narratif du cours",
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _genererVideo,
                    icon: const Icon(Icons.movie_creation),
                    label: const Text("Générer la vidéo"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}*/
