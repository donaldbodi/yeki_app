import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

import 'lecture_lecon_page.dart';

class Lecon {
  final String id;
  final String titre;
  final String resume;
  final String videoUrl;
  final String documentUrl;

  Lecon({
    required this.id,
    required this.titre,
    required this.resume,
    required this.videoUrl,
    required this.documentUrl,
  });
}

class DetailLeconPage extends StatefulWidget {
  final Lecon leconActuelle;
  final List<Lecon> autresLecons;

  const DetailLeconPage({
    Key? key,
    required this.leconActuelle,
    required this.autresLecons,
  }) : super(key: key);

  @override
  State<DetailLeconPage> createState() => _DetailLeconPageState();
}

class _DetailLeconPageState extends State<DetailLeconPage> {
  late VideoPlayerController _videoController;
  ChewieController? _chewieController;

  double videoHeight = 250.0;

  @override
  void initState() {
    super.initState();
    _videoController = VideoPlayerController.network(widget.leconActuelle.videoUrl)
      ..initialize().then((_) => setState(() {}));
    _chewieController = ChewieController(
      videoPlayerController: _videoController,
      autoPlay: false,
      looping: false,
    );
  }

  @override
  void dispose() {
    _videoController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  void _voirDocument() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LectureLeconPage(
          titre: widget.leconActuelle.titre,
          pdfUrl: widget.leconActuelle.documentUrl,
        ),
      ),
    );
  }

  void _poserPreoccupation() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Pose ta préoccupation",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            const TextField(
              maxLines: 4,
              decoration: InputDecoration(
                hintText: "Exprime ta préoccupation ici...",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text("Préoccupation envoyée.")));
              },
              icon: const Icon(Icons.send),
              label: const Text("Envoyer"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lecon = widget.leconActuelle;
    final autres = widget.autresLecons;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(lecon.titre),
        backgroundColor: const Color(0xFF008080),
        elevation: 2,
      ),
      body: NotificationListener<ScrollNotification>(
        onNotification: (scroll) {
          if (scroll.metrics.axis == Axis.vertical) {
            setState(() {
              videoHeight = (250 - scroll.metrics.pixels).clamp(200, 300);
            });
          }
          return false;
        },
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: videoHeight,
              width: double.infinity,
              child: _chewieController != null &&
                      _chewieController!.videoPlayerController.value.isInitialized
                  ? Chewie(controller: _chewieController!)
                  : const Center(child: CircularProgressIndicator()),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _voirDocument,
                          icon: const Icon(Icons.description),
                          label: const Text("Voir le document"),
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.indigo,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _poserPreoccupation,
                          icon: const Icon(Icons.question_answer),
                          label: const Text("Aide"),
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.orange,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "Résumé de la leçon",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.teal[900],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    lecon.resume,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 30),
                  Text(
                    "Autres leçons",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal[800],
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...autres.map((l) => _buildLeconCard(l)).toList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeconCard(Lecon lecon) {
    final isCurrent = lecon.id == widget.leconActuelle.id;
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: isCurrent
            ? const BorderSide(color: Color(0xFF008080), width: 2)
            : const BorderSide(color: Colors.grey, width: 0.3),
      ),
      color: isCurrent ? const Color(0xFFE0F7F7) : Colors.white,
      child: ListTile(
        leading: const Icon(Icons.play_circle_fill, color: Colors.teal),
        title: Text(
          lecon.titre,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(lecon.resume, maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          if (!isCurrent) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => DetailLeconPage(
                  leconActuelle: lecon,
                  autresLecons: widget.autresLecons,
                ),
              ),
            );
          }
        },
      ),
    );
  }
}
