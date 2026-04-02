// lib/views/pages/apprenants/yeki_ia_chat_page.dart
// ════════════════════════════════════════════════════════════════
// DISCUSSION PRIVÉE AVEC YEKI IA
// Conversation persistante par cours. L'IA répond en temps réel.
// Sources : leçon, exercice, devoir, libre
// ════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _iaBase = 'https://yeki.pythonanywhere.com/api';

// ── Palette ──────────────────────────────────────────────────────
const Color _navy   = Color(0xFF0D1B2A);
const Color _teal   = Color(0xFF008088);
const Color _tealL  = Color(0xFF39A0C2);
const Color _gold   = Color(0xFFE2A84B);
const Color _bg     = Color(0xFF0D1117);
const Color _surf   = Color(0xFF161B22);
const Color _card   = Color(0xFF1C2128);
const Color _bord   = Color(0xFF30363D);

// Source colors
const Map<String, Color> _srcColors = {
  'lecon':    Color(0xFF3B82F6),
  'exercice': Color(0xFFA855F7),
  'devoir':   Color(0xFFF97316),
  'libre':    Color(0xFF22C55E),
};

Future<String?> _getToken() async =>
    (await SharedPreferences.getInstance()).getString('token');

// ── Modèle message ───────────────────────────────────────────────
class _IAChatMessage {
  final int?   id;
  final String role;      // 'user' | 'assistant'
  final String contenu;
  final String? imageUrl;
  final String  source;
  final String  sourceTitre;
  final DateTime creeLe;
  final bool   isStreaming;

  const _IAChatMessage({
    this.id,
    required this.role,
    required this.contenu,
    this.imageUrl,
    this.source = 'libre',
    this.sourceTitre = '',
    required this.creeLe,
    this.isStreaming = false,
  });

  factory _IAChatMessage.fromJson(Map<String, dynamic> j) => _IAChatMessage(
        id:          j['id'],
        role:        j['role'] ?? 'user',
        contenu:     j['contenu'] ?? '',
        imageUrl:    j['image_url'] as String?,
        source:      j['source'] ?? 'libre',
        sourceTitre: j['source_titre'] ?? '',
        creeLe:      DateTime.tryParse(j['cree_le'] ?? '') ?? DateTime.now(),
      );

  _IAChatMessage copyWith({String? contenu, bool? isStreaming}) =>
      _IAChatMessage(
        id:          id,
        role:        role,
        contenu:     contenu ?? this.contenu,
        imageUrl:    imageUrl,
        source:      source,
        sourceTitre: sourceTitre,
        creeLe:      creeLe,
        isStreaming: isStreaming ?? this.isStreaming,
      );
}

// ════════════════════════════════════════════════════════════════
// PAGE PRINCIPALE
// ════════════════════════════════════════════════════════════════
class YekiIAChatPage extends StatefulWidget {
  final int    coursId;
  final String coursTitre;
  // Préoccupation pré-remplie
  final String? messageInitial;
  final String  sourceInitiale;
  final int?    sourceId;
  final String  sourceTitreInit;

  const YekiIAChatPage({
    super.key,
    required this.coursId,
    required this.coursTitre,
    this.messageInitial,
    this.sourceInitiale = 'libre',
    this.sourceId,
    this.sourceTitreInit = '',
  });

  @override
  State<YekiIAChatPage> createState() => _YekiIAChatPageState();
}

class _YekiIAChatPageState extends State<YekiIAChatPage>
    with TickerProviderStateMixin {
  final List<_IAChatMessage> _messages = [];
  final _msgCtrl  = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool  _loading  = true;
  bool  _sending  = false;
  File? _imageFile;

  late AnimationController _typingCtrl;

  @override
  void initState() {
    super.initState();
    _typingCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
    _chargerHistorique();

    // Pré-remplir le message si fourni
    if (widget.messageInitial != null && widget.messageInitial!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _msgCtrl.text = widget.messageInitial!;
      });
    }
  }

  @override
  void dispose() {
    _typingCtrl.dispose();
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _chargerHistorique() async {
    setState(() => _loading = true);
    final token = await _getToken();
    try {
      final res = await http.get(
        Uri.parse('$_iaBase/ia/cours/${widget.coursId}/historique/'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Token $token',
        },
      );
      if (res.statusCode == 200 && mounted) {
        final List data = jsonDecode(res.body);
        setState(() {
          _messages.clear();
          _messages.addAll(
              data.map((j) => _IAChatMessage.fromJson(j)).toList());
          _loading = false;
        });
        _scrollToBottom();

        // Envoyer automatiquement le message initial si présent
        if (widget.messageInitial != null &&
            widget.messageInitial!.isNotEmpty &&
            _messages.isEmpty) {
          _envoyer(prefill: widget.messageInitial!);
        }
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _envoyer({String? prefill}) async {
    final texte = (prefill ?? _msgCtrl.text).trim();
    if (texte.isEmpty && _imageFile == null) return;

    // Ajouter le message utilisateur localement
    final msgUser = _IAChatMessage(
      role:        'user',
      contenu:     texte,
      source:      widget.sourceInitiale,
      sourceTitre: widget.sourceTitreInit,
      creeLe:      DateTime.now(),
    );
    setState(() {
      _messages.add(msgUser);
      _sending = true;
    });
    _msgCtrl.clear();
    _scrollToBottom();

    // Ajouter un message "IA en train de taper"
    final typing = _IAChatMessage(
      role:        'assistant',
      contenu:     '…',
      creeLe:      DateTime.now(),
      isStreaming: true,
    );
    setState(() => _messages.add(typing));
    _scrollToBottom();

    final token = await _getToken();
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_iaBase/ia/cours/${widget.coursId}/chat/'),
      );
      request.headers['Authorization'] = 'Token ${token ?? ''}';
      request.fields['message']      = texte;
      request.fields['source']       = widget.sourceInitiale;
      request.fields['source_id']    = '${widget.sourceId ?? ''}';
      request.fields['source_titre'] = widget.sourceTitreInit;
      if (_imageFile != null) {
        request.files.add(
            await http.MultipartFile.fromPath('image', _imageFile!.path));
      }
      setState(() => _imageFile = null);

      final streamed = await request.send();
      final res = await http.Response.fromStream(streamed);

      if (res.statusCode == 200 && mounted) {
        final data = jsonDecode(res.body);
        final reponse = data['reponse'] as String? ?? '';
        // Remplacer le message "typing" par la vraie réponse
        setState(() {
          _messages.removeLast();
          _messages.add(_IAChatMessage(
            id:      data['assistant_id'],
            role:    'assistant',
            contenu: reponse,
            creeLe:  DateTime.now(),
          ));
        });
      } else {
        setState(() {
          _messages.removeLast();
          _messages.add(_IAChatMessage(
            role:    'assistant',
            contenu: 'Yeki IA : Désolé, une erreur est survenue. Réessayez.',
            creeLe:  DateTime.now(),
          ));
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _messages.removeLast();
          _messages.add(_IAChatMessage(
            role:    'assistant',
            contenu: 'Yeki IA : Erreur de connexion. Vérifiez votre réseau.',
            creeLe:  DateTime.now(),
          ));
        });
      }
    }
    if (mounted) {
      setState(() => _sending = false);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent + 200,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _choisirImage() async {
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked != null && mounted) {
      setState(() => _imageFile = File(picked.path));
    }
  }

  Future<void> _effacerConversation() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _card,
        title: const Text('Effacer la conversation',
            style: TextStyle(color: Colors.white, fontSize: 16)),
        content: const Text(
            'Toute la conversation avec Yeki IA sera supprimée.',
            style: TextStyle(color: Colors.white54, fontSize: 13)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child:
                  const Text('Annuler', style: TextStyle(color: Colors.white54))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Effacer',
                  style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
    if (ok != true) return;
    final token = await _getToken();
    await http.delete(
      Uri.parse('$_iaBase/ia/cours/${widget.coursId}/historique/'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Token $token',
      },
    );
    if (mounted) setState(() => _messages.clear());
  }

  // ── BUILD ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Bandeau contexte source
          if (widget.sourceInitiale != 'libre' &&
              widget.sourceTitreInit.isNotEmpty)
            _buildSourceBanner(),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: _teal))
                : _messages.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                        itemCount: _messages.length,
                        itemBuilder: (_, i) => _buildBubble(_messages[i]),
                      ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: _surf,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: Colors.white, size: 18),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [_teal, _tealL],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Text('YIA',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w900)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Yéki IA',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800)),
                Text(widget.coursTitre,
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.delete_outline_rounded,
              color: Colors.white54, size: 20),
          onPressed: _messages.isNotEmpty ? _effacerConversation : null,
          tooltip: 'Effacer la conversation',
        ),
        const SizedBox(width: 4),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: _bord),
      ),
    );
  }

  Widget _buildSourceBanner() {
    final color = _srcColors[widget.sourceInitiale] ?? _teal;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      color: color.withOpacity(0.1),
      child: Row(
        children: [
          Icon(_sourceIcon(widget.sourceInitiale), color: color, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${_sourceLabel(widget.sourceInitiale)} : ${widget.sourceTitreInit}',
              style: TextStyle(
                  color: color, fontSize: 12, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [_teal, _tealL],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                      color: _teal.withOpacity(0.3),
                      blurRadius: 24,
                      offset: const Offset(0, 8)),
                ],
              ),
              child: const Center(
                child: Text('YIA',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900)),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Yéki IA',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text(
              'Votre assistant pédagogique personnel.\nPosez vos questions sur ce cours.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 24),
            _buildSuggestion(
                'Explique-moi ce concept en détail',
                Icons.lightbulb_outline_rounded),
            const SizedBox(height: 8),
            _buildSuggestion(
                'Donne-moi un exemple concret',
                Icons.science_outlined),
            const SizedBox(height: 8),
            _buildSuggestion(
                'Je n\'ai pas compris cette partie',
                Icons.help_outline_rounded),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestion(String text, IconData icon) {
    return GestureDetector(
      onTap: () {
        _msgCtrl.text = text;
        setState(() {});
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _surf,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _bord),
        ),
        child: Row(
          children: [
            Icon(icon, color: _teal, size: 16),
            const SizedBox(width: 10),
            Expanded(
              child: Text(text,
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 13)),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.white24, size: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildBubble(_IAChatMessage msg) {
    final isUser = msg.role == 'user';
    final isStreaming = msg.isStreaming;

    if (isUser) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12, left: 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Badge source
            if (msg.source != 'libre' && msg.sourceTitre.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 4, right: 4),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: (_srcColors[msg.source] ?? _teal).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_sourceLabel(msg.source)} : ${msg.sourceTitre}',
                    style: TextStyle(
                        fontSize: 10,
                        color: _srcColors[msg.source] ?? _teal,
                        fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            // Image jointe
            if (msg.imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(msg.imageUrl!,
                    height: 160,
                    width: 220,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink()),
              ),
            if (msg.contenu.isNotEmpty)
              Container(
                margin: msg.imageUrl != null
                    ? const EdgeInsets.only(top: 4)
                    : EdgeInsets.zero,
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [_teal, _tealL],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(4),
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                  boxShadow: [
                    BoxShadow(
                        color: _teal.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 3)),
                  ],
                ),
                child: Text(msg.contenu,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 14, height: 1.5)),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 4, right: 4),
              child: Text(_formatTime(msg.creeLe),
                  style: const TextStyle(
                      color: Colors.white24, fontSize: 10)),
            ),
          ],
        ),
      );
    }

    // Message IA
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, right: 48),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [_teal, _tealL],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text('YIA',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w900)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('Yéki IA',
                        style: TextStyle(
                            color: _teal,
                            fontSize: 11,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(width: 8),
                    if (isStreaming)
                      _buildTypingIndicator()
                    else
                      Text(_formatTime(msg.creeLe),
                          style: const TextStyle(
                              color: Colors.white24, fontSize: 10)),
                  ],
                ),
                const SizedBox(height: 4),
                if (isStreaming)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: _card,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                      border: Border.all(color: _bord),
                    ),
                    child: _buildDots(),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: _card,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                      border: Border.all(color: _bord),
                    ),
                    child: Text(
                      // Enlever le préfixe "Yeki IA :" du contenu
                      msg.contenu.startsWith('Yeki IA :')
                          ? msg.contenu.substring(9).trim()
                          : msg.contenu,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          height: 1.6),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: _teal.withOpacity(0.15),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text('en train de rédiger…',
            style: TextStyle(
                color: _teal, fontSize: 9, fontWeight: FontWeight.w600)),
      );

  Widget _buildDots() {
    return AnimatedBuilder(
      animation: _typingCtrl,
      builder: (_, __) {
        final v = _typingCtrl.value;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final opacity = ((v * 3 - i).clamp(0.0, 1.0) * (1 - (v * 3 - i - 1).clamp(0.0, 1.0))).clamp(0.3, 1.0);
            return Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Opacity(
                opacity: opacity,
                child: Container(
                  width: 7, height: 7,
                  decoration: const BoxDecoration(
                      color: _teal, shape: BoxShape.circle),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.only(
          left: 12, right: 12, top: 10,
          bottom: MediaQuery.of(context).padding.bottom + 10),
      decoration: BoxDecoration(
        color: _surf,
        border: Border(top: BorderSide(color: _bord)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Image preview
          if (_imageFile != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Stack(
                alignment: Alignment.topRight,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(_imageFile!,
                        height: 80, width: 80, fit: BoxFit.cover),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _imageFile = null),
                    child: Container(
                      width: 20, height: 20,
                      decoration: const BoxDecoration(
                          color: Colors.red, shape: BoxShape.circle),
                      child: const Icon(Icons.close_rounded,
                          color: Colors.white, size: 12),
                    ),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              // Bouton image
              GestureDetector(
                onTap: _choisirImage,
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: _card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _bord),
                  ),
                  child: const Icon(Icons.image_outlined,
                      color: Colors.white54, size: 20),
                ),
              ),
              const SizedBox(width: 8),
              // Champ texte
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: _card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _bord),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _msgCtrl,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 14),
                          maxLines: 4,
                          minLines: 1,
                          decoration: const InputDecoration(
                            hintText: 'Posez votre question…',
                            hintStyle: TextStyle(
                                color: Colors.white24, fontSize: 13),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Bouton envoyer
              GestureDetector(
                onTap: (_sending || (_msgCtrl.text.trim().isEmpty && _imageFile == null))
                    ? null
                    : _envoyer,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    gradient: (_sending ||
                            (_msgCtrl.text.trim().isEmpty &&
                                _imageFile == null))
                        ? LinearGradient(colors: [
                            Colors.grey.shade700,
                            Colors.grey.shade600
                          ])
                        : const LinearGradient(
                            colors: [_teal, _tealL],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight),
                    shape: BoxShape.circle,
                  ),
                  child: _sending
                      ? const Center(
                          child: SizedBox(
                              width: 18, height: 18,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2)))
                      : const Icon(Icons.send_rounded,
                          color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    if (now.difference(dt).inDays == 0) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return '${dt.day}/${dt.month} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _sourceLabel(String src) {
    switch (src) {
      case 'lecon':    return 'Leçon';
      case 'exercice': return 'Exercice';
      case 'devoir':   return 'Devoir';
      default:         return 'Question';
    }
  }

  IconData _sourceIcon(String src) {
    switch (src) {
      case 'lecon':    return Icons.play_lesson_rounded;
      case 'exercice': return Icons.edit_note_rounded;
      case 'devoir':   return Icons.assignment_rounded;
      default:         return Icons.chat_bubble_outline_rounded;
    }
  }
}
