import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class ForumCoursPage extends StatefulWidget {
  const ForumCoursPage({super.key});

  @override
  State<ForumCoursPage> createState() => _ForumCoursPageState();
}

class _ForumCoursPageState extends State<ForumCoursPage> {
  final List<Map<String, dynamic>> _messages = [];
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = "";
  bool _isRecording = false;
  Uint8List? _pickedImage;
  String? _audioPath;

  @override
  void initState() {
    super.initState();
    _player.openPlayer();
    _recorder.openRecorder();
    _loadMockData();
  }

  @override
  void dispose() {
    _player.closePlayer();
    _recorder.closeRecorder();
    super.dispose();
  }

  void _loadMockData() {
    _messages.addAll([
      {
        'id': 'q1',
        'parentId': null,
        'text': "Je ne comprends pas la notion de fonction affine.",
        'sender': 'Samuel',
        'role': 'élève',
        'timestamp': DateTime.now().subtract(const Duration(minutes: 10)),
        'origin': {
          'type': 'lecon',
          'coursTitre': 'Mathématiques – 3e',
          'itemTitre': 'Fonctions affines',
        },
      },
      {
        'id': 'r1',
        'parentId': 'q1',
        'text': "Une fonction affine est de la forme f(x)=ax+b.",
        'sender': 'Mme Essomba',
        'role': 'enseignant',
        'timestamp': DateTime.now().subtract(const Duration(minutes: 5)),
      },
    ]);
  }

  List<Map<String, dynamic>> get _questions =>
      _messages.where((m) => m['parentId'] == null).where((q) {
        return q['text']
            .toString()
            .toLowerCase()
            .contains(_searchQuery.toLowerCase());
      }).toList();

  List<Map<String, dynamic>> _repliesOf(String id) =>
      _messages.where((m) => m['parentId'] == id).toList();

  int _depthOf(Map msg) {
    int depth = 0;
    String? parent = msg['parentId'];
    while (parent != null) {
      depth++;
      parent =
          _messages.firstWhere((m) => m['id'] == parent)['parentId'];
    }
    return depth;
  }

  Future<void> _playAudio(String path) async {
    await _player.startPlayer(fromURI: path);
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      _pickedImage = await picked.readAsBytes();
    }
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      _audioPath = await _recorder.stopRecorder();
    } else {
      final dir = await getApplicationDocumentsDirectory();
      _audioPath =
          "${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.aac";
      await _recorder.startRecorder(toFile: _audioPath);
    }
    setState(() => _isRecording = !_isRecording);
  }

  void _openReplyModal(String parentId, int depth) {
    if (depth >= 2) return; // 🚫 stop au 3e niveau

    final controller = TextEditingController();
    _pickedImage = null;
    _audioPath = null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.of(context).viewInsets.bottom + 20,
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
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const Text(
              "Ajouter une réponse",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              minLines: 3,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: "Votre réponse...",
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.image, color: Colors.orange),
                  onPressed: _pickImage,
                ),
                IconButton(
                  icon: Icon(
                    _isRecording ? Icons.stop : Icons.mic,
                    color: _isRecording ? Colors.red : Colors.green,
                  ),
                  onPressed: _toggleRecording,
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () {
                    if (controller.text.isEmpty &&
                        _pickedImage == null &&
                        _audioPath == null) return;

                    setState(() {
                      _messages.add({
                        'id': DateTime.now().millisecondsSinceEpoch.toString(),
                        'parentId': parentId,
                        'text': controller.text,
                        'image': _pickedImage,
                        'audio': _audioPath,
                        'sender': 'M. Bodi',
                        'role': 'enseignant',
                        'timestamp': DateTime.now(),
                      });
                    });
                    Navigator.pop(context);
                  },
                  child: const Text("Envoyer"),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageCard(Map msg, int depth) {
    final isTeacher = msg['role'] == 'enseignant';

    return Container(
      margin: EdgeInsets.only(top: 10, left: depth * 32),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isTeacher ? Colors.orange.shade50 : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border(
          left: BorderSide(
            width: 4,
            color: isTeacher ? Colors.orange : Colors.blue,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor:
                    isTeacher ? Colors.orange : Colors.blue,
                child: Text(
                  msg['sender'][0],
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(width: 8),
              Text(msg['sender'],
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              if (isTeacher)
                const Text("ENSEIGNANT",
                    style: TextStyle(fontSize: 10, color: Colors.orange)),
            ],
          ),
          const SizedBox(height: 8),
          if ((msg['text'] as String).isNotEmpty) Text(msg['text']),
          if (msg['image'] != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Image.memory(msg['image'], height: 140),
            ),
          if (msg['audio'] != null)
            TextButton.icon(
              onPressed: () => _playAudio(msg['audio']),
              icon: const Icon(Icons.play_arrow),
              label: const Text("Écouter l’audio"),
            ),
          Row(
            children: [
              Text(
                "${msg['timestamp'].hour.toString().padLeft(2, '0')}:${msg['timestamp'].minute.toString().padLeft(2, '0')}",
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
              const Spacer(),
              if (depth < 2)
                TextButton.icon(
                  icon: const Icon(Icons.reply, size: 16),
                  label: const Text("Répondre"),
                  onPressed: () =>
                      _openReplyModal(msg['id'], depth),
                ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildThread(Map msg, int depth) {
    final replies = _repliesOf(msg['id']);
    return [
      _buildMessageCard(msg, depth),
      ...replies.expand((r) => _buildThread(r, depth + 1)),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children:
                  _questions.expand((q) => _buildThread(q, 0)).toList(),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade300)),
            ),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: "Rechercher une question...",
                prefixIcon: Icon(Icons.search),
                border: InputBorder.none,
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
        ],
      ),
    );
  }
}
