// lib/views/pages/apprenants/yeki_ia_chat_page.dart
// ═══════════════════════════════════════════════════════════════════════════
// DISCUSSION PRIVÉE AVEC YEKI IA (CLAUDE 3.5 SONNET) — CORRIGÉE
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:yeki/core/theme/app_theme.dart';
import 'package:yeki/core/constants/api_constants.dart';
import 'package:yeki/utils/error_handler.dart';

const double minWalletBalance = 50.0;

Future<String?> _getToken() async =>
    (await SharedPreferences.getInstance()).getString('token');

class _IAChatMessage {
  final int? id;
  final String role;
  final String contenu;
  final String? imageUrl;
  final String? audioUrl;
  final String source;
  final String sourceTitre;
  final DateTime creeLe;
  final bool isStreaming;
  final int? tokensInput;
  final int? tokensOutput;
  final int? coutXaf;

  const _IAChatMessage({
    this.id,
    required this.role,
    required this.contenu,
    this.imageUrl,
    this.audioUrl,
    this.source = 'libre',
    this.sourceTitre = '',
    required this.creeLe,
    this.isStreaming = false,
    this.tokensInput,
    this.tokensOutput,
    this.coutXaf,
  });

  factory _IAChatMessage.fromJson(Map<String, dynamic> j) => _IAChatMessage(
        id: j['id'],
        role: j['role'] ?? 'user',
        contenu: j['contenu'] ?? '',
        imageUrl: j['image_url'] as String?,
        audioUrl: j['audio_url'] as String?,
        source: j['source'] ?? 'libre',
        sourceTitre: j['source_titre'] ?? '',
        creeLe: DateTime.tryParse(j['cree_le'] ?? '') ?? DateTime.now(),
        tokensInput: j['tokens_input'],
        tokensOutput: j['tokens_output'],
        coutXaf: j['cout_xaf'],
      );
}

class _WalletInfo {
  final int solde;
  final int totalRecharge;
  final int totalDepense;
  const _WalletInfo({
    required this.solde,
    required this.totalRecharge,
    required this.totalDepense,
  });
  factory _WalletInfo.fromJson(Map<String, dynamic> j) => _WalletInfo(
        solde: j['solde'] ?? 0,
        totalRecharge: j['total_recharge'] ?? 0,
        totalDepense: j['total_depense'] ?? 0,
      );
}

const Map<String, Color> _srcColors = {
  'lecon': Colors.blue,
  'exercice': YekiColors.purple,
  'devoir': YekiColors.warning,
  'libre': YekiColors.success,
};

class YekiIAChatPage extends StatefulWidget {
  final int coursId;
  final String coursTitre;
  final String? messageInitial;
  final String sourceInitiale;
  final int? sourceId;
  final String sourceTitreInit;
  final File? initialImage;
  final File? initialAudio;

  const YekiIAChatPage({
    super.key,
    required this.coursId,
    required this.coursTitre,
    this.messageInitial,
    this.sourceInitiale = 'libre',
    this.sourceId,
    this.sourceTitreInit = '',
    this.initialImage,
    this.initialAudio,
  });

  @override
  State<YekiIAChatPage> createState() => _YekiIAChatPageState();
}

class _YekiIAChatPageState extends State<YekiIAChatPage>
    with TickerProviderStateMixin {
  final List<_IAChatMessage> _messages = [];
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _loading = true;
  bool _sending = false;
  File? _imageFile;
  File? _audioFile;
  _WalletInfo? _wallet;

  // Enregistrement audio
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  bool _hasPermission = false;
  Duration _recordingDuration = Duration.zero;
  Timer? _recordingTimer;

  late AnimationController _typingCtrl;

  @override
  void initState() {
    super.initState();
    _typingCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
    _chargerHistorique();
    _chargerWallet();
    _checkMicrophonePermission();

    if (widget.initialImage != null) {
      _imageFile = widget.initialImage;
    }
    if (widget.initialAudio != null) {
      _audioFile = widget.initialAudio;
    }

    if (widget.messageInitial != null && widget.messageInitial!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _msgCtrl.text = widget.messageInitial!;
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && _msgCtrl.text.isNotEmpty) {
            _envoyer();
          }
        });
      });
    }
  }

  @override
  void dispose() {
    _typingCtrl.dispose();
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    _stopRecording();
    _recordingTimer?.cancel();
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _checkMicrophonePermission() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        setState(() => _hasPermission = true);
      } else {
        final permission = await _audioRecorder.hasPermission();
        setState(() => _hasPermission = permission);
        if (!permission && mounted) {
          ErrorHandler.showError(context, 'Permission microphone requise');
        }
      }
    } catch (e) {
      setState(() => _hasPermission = false);
    }
  }

  Future<void> _requestMicrophonePermission() async {
    try {
      final permission = await _audioRecorder.hasPermission();
      setState(() => _hasPermission = permission);
      if (!permission && mounted) {
        ErrorHandler.showError(context, 'Autorisez l\'accès au microphone');
      }
    } catch (e) {
      ErrorHandler.showError(context, 'Erreur permission microphone');
    }
  }

  Future<void> _startRecording() async {
    if (!_hasPermission) {
      await _requestMicrophonePermission();
      if (!_hasPermission) return;
    }

    try {
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = '${directory.path}/audio_$timestamp.m4a';
      
      await _audioRecorder.start(
        RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000, sampleRate: 44100),
        path: path,
      );
      
      setState(() {
        _isRecording = true;
        _recordingDuration = Duration.zero;
      });
      
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted && _isRecording) {
          setState(() {
            _recordingDuration = _recordingDuration + const Duration(seconds: 1);
          });
        }
      });
    } catch (e) {
      ErrorHandler.showError(context, 'Erreur démarrage enregistrement: $e');
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;
    
    try {
      final path = await _audioRecorder.stop();
      _recordingTimer?.cancel();
      
      if (path != null && mounted) {
        final file = File(path);
        if (await file.exists() && await file.length() > 0) {
          setState(() {
            _audioFile = file;
            _isRecording = false;
          });
          ErrorHandler.showSuccess(context, 'Audio enregistré');
        } else {
          ErrorHandler.showError(context, 'Enregistrement vide');
          setState(() => _isRecording = false);
        }
      } else {
        setState(() => _isRecording = false);
      }
    } catch (e) {
      setState(() => _isRecording = false);
      ErrorHandler.showError(context, 'Erreur arrêt enregistrement');
    }
  }

  void _cancelRecording() {
    _recordingTimer?.cancel();
    _audioRecorder.cancel();
    setState(() {
      _isRecording = false;
      _recordingDuration = Duration.zero;
    });
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  Future<void> _chargerWallet() async {
    final token = await _getToken();
    try {
      final res = await http.get(
        Uri.parse(ApiConstants.walletSolde),
        headers: ApiHeaders.auth(token),
      );
      if (res.statusCode == 200 && mounted) {
        setState(() {
          _wallet = _WalletInfo.fromJson(jsonDecode(res.body));
        });
      }
    } catch (_) {}
  }

  Future<void> _chargerHistorique() async {
    setState(() => _loading = true);
    final token = await _getToken();
    try {
      final res = await http.get(
        Uri.parse(ApiConstants.iaHistorique(widget.coursId)),
        headers: ApiHeaders.auth(token),
      );
      if (res.statusCode == 200 && mounted) {
        final List data = jsonDecode(res.body);
        setState(() {
          _messages.clear();
          _messages.addAll(data.map((j) => _IAChatMessage.fromJson(j)));
          _loading = false;
        });
        _scrollToBottom();

        if (widget.messageInitial != null &&
            widget.messageInitial!.isNotEmpty &&
            _messages.isEmpty) {
          _envoyer();
        }
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<bool> _verifierSoldeSuffisant() async {
    if (_wallet == null) await _chargerWallet();
    
    if (_wallet != null && _wallet!.solde < minWalletBalance) {
      if (mounted) {
        ErrorHandler.showError(context,
          'Solde insuffisant. Minimum requis: ${minWalletBalance.toInt()} FCFA.\n'
          'Votre solde: ${_wallet!.solde} FCFA.\n\n'
          'Veuillez recharger votre wallet.');
      }
      return false;
    }
    return true;
  }

  Future<void> _envoyer({String? prefill}) async {
    final texte = (prefill ?? _msgCtrl.text).trim();
    if (texte.isEmpty && _imageFile == null && _audioFile == null) return;

    final soldeOk = await _verifierSoldeSuffisant();
    if (!soldeOk) return;

    final msgUser = _IAChatMessage(
      role: 'user',
      contenu: texte,
      source: widget.sourceInitiale,
      sourceTitre: widget.sourceTitreInit,
      creeLe: DateTime.now(),
    );
    setState(() {
      _messages.add(msgUser);
      _sending = true;
    });
    _msgCtrl.clear();
    _scrollToBottom();

    final typing = _IAChatMessage(
      role: 'assistant',
      contenu: '…',
      creeLe: DateTime.now(),
      isStreaming: true,
    );
    setState(() => _messages.add(typing));
    _scrollToBottom();

    final token = await _getToken();
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConstants.iaChat(widget.coursId)),
      );
      request.headers['Authorization'] = 'Token ${token ?? ''}';
      request.fields['message'] = texte;
      request.fields['source'] = widget.sourceInitiale;
      request.fields['source_id'] = '${widget.sourceId ?? ''}';
      request.fields['source_titre'] = widget.sourceTitreInit;
      
      if (_imageFile != null) {
        request.files.add(await http.MultipartFile.fromPath('image', _imageFile!.path));
      }
      if (_audioFile != null) {
        request.files.add(await http.MultipartFile.fromPath('audio', _audioFile!.path));
      }
      
      setState(() {
        _imageFile = null;
        _audioFile = null;
      });

      final streamed = await request.send();
      final res = await http.Response.fromStream(streamed);

      if (res.statusCode == 200 && mounted) {
        final data = jsonDecode(res.body);
        final reponse = data['reponse'] as String? ?? '';
        final cout = data['cout_xaf'] as int? ?? 0;
        final soldeRestant = data['solde_restant'] as int?;
        
        if (soldeRestant != null && _wallet != null) {
          setState(() {
            _wallet = _WalletInfo(
              solde: soldeRestant,
              totalRecharge: _wallet!.totalRecharge,
              totalDepense: _wallet!.totalDepense + cout,
            );
          });
        } else {
          await _chargerWallet();
        }
        
        setState(() {
          _messages.removeLast();
          _messages.add(_IAChatMessage(
            id: data['assistant_id'],
            role: 'assistant',
            contenu: reponse,
            creeLe: DateTime.now(),
            tokensInput: data['tokens_input'],
            tokensOutput: data['tokens_output'],
            coutXaf: cout,
          ));
        });
        
        if (cout > 0) {
          ErrorHandler.showSuccess(context, '💰 Coût: $cout FCFA | Solde: ${soldeRestant ?? _wallet?.solde} FCFA');
        }
      } else {
        String errorMsg = 'Erreur lors de l\'envoi';
        try {
          final errorData = jsonDecode(res.body);
          errorMsg = errorData['detail'] ?? errorData['reponse_secours'] ?? errorMsg;
        } catch (_) {}
        
        setState(() {
          _messages.removeLast();
          _messages.add(_IAChatMessage(
            role: 'assistant',
            contenu: 'Yeki IA : $errorMsg',
            creeLe: DateTime.now(),
          ));
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _messages.removeLast();
          _messages.add(_IAChatMessage(
            role: 'assistant',
            contenu: 'Yeki IA : Erreur de connexion. Vérifiez votre réseau.',
            creeLe: DateTime.now(),
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
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked != null && mounted) {
      setState(() => _imageFile = File(picked.path));
    }
  }

  Future<void> _effacerConversation() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: YekiRadius.borderRadiusXl),
        backgroundColor: YekiColors.white,
        title: const Text('Effacer la conversation',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: const Text('Toute la conversation avec Yeki IA sera supprimée.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler', style: TextStyle(color: YekiColors.textMedium))),
          TextButton(onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Effacer', style: TextStyle(color: YekiColors.error))),
        ],
      ),
    );
    if (ok != true) return;
    final token = await _getToken();
    await http.delete(
      Uri.parse(ApiConstants.iaHistorique(widget.coursId)),
      headers: ApiHeaders.auth(token),
    );
    if (mounted) setState(() => _messages.clear());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: YekiColors.backgroundLight,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildSoldeBanner(),
          Expanded(
            child: _loading
                ? const Center(child: YekiLoader())
                : _messages.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                        itemCount: _messages.length,
                        itemBuilder: (_, i) => _buildBubble(_messages[i]),
                      ),
          ),
          if (_isRecording)
            _buildRecordingBar()
          else
            _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildRecordingBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: YekiColors.white,
        border: Border(top: BorderSide(color: YekiColors.borderLight)),
      ),
      child: Row(
        children: [
          Container(width: 12, height: 12, decoration: const BoxDecoration(color: YekiColors.error, shape: BoxShape.circle)),
          const SizedBox(width: 12),
          Container(width: 12, height: 12, decoration: BoxDecoration(color: YekiColors.error.withValues(alpha: 0.5), shape: BoxShape.circle)),
          const SizedBox(width: 12),
          Text('Enregistrement • ${_formatDuration(_recordingDuration)}',
              style: const TextStyle(color: YekiColors.error, fontWeight: FontWeight.w600, fontSize: 14)),
          const Spacer(),
          GestureDetector(
            onTap: _stopRecording,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: YekiColors.success, borderRadius: BorderRadius.circular(20)),
              child: const Text('Arrêter', style: TextStyle(color: YekiColors.white, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _cancelRecording,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: YekiColors.textLight, borderRadius: BorderRadius.circular(20)),
              child: const Text('Annuler', style: TextStyle(color: YekiColors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: YekiColors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [YekiColors.primaryDark, YekiColors.primaryLight]),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(child: Text('YIA', style: TextStyle(color: YekiColors.white, fontSize: 11, fontWeight: FontWeight.w900))),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Yéki IA', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                Text(widget.coursTitre, style: const TextStyle(fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.delete_outline_rounded, size: 20),
          onPressed: _messages.isNotEmpty ? _effacerConversation : null,
          tooltip: 'Effacer la conversation',
        ),
        const SizedBox(width: 4),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(height: 1, color: YekiColors.borderLight),
      ),
    );
  }

  Widget _buildSoldeBanner() {
    if (_wallet == null) return const SizedBox.shrink();
    
    final solde = _wallet!.solde;
    final isLow = solde < minWalletBalance;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      color: isLow ? YekiColors.accent.withValues(alpha: 0.1) : YekiColors.primaryDark.withValues(alpha: 0.05),
      child: Row(
        children: [
          Icon(isLow ? Icons.warning_amber_rounded : Icons.account_balance_wallet_rounded,
              color: isLow ? YekiColors.accent : YekiColors.primaryDark, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isLow 
                  ? '⚠️ Solde faible: $solde FCFA (minimum $minWalletBalance FCFA requis)'
                  : '💰 Solde: $solde FCFA',
              style: TextStyle(color: isLow ? YekiColors.accent : YekiColors.textMedium, fontSize: 12, fontWeight: FontWeight.w600),
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
                gradient: LinearGradient(colors: [YekiColors.primaryDark, YekiColors.primaryLight]),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Center(child: Text('YIA', style: TextStyle(color: YekiColors.white, fontSize: 22, fontWeight: FontWeight.w900))),
            ),
            const SizedBox(height: 20),
            const Text('Yéki IA', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text(
              'Votre assistant pédagogique expert de ce cours.\n'
              'Posez vos questions, je les analyse et y réponds '
              'en utilisant le contenu du cours.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
            if (_wallet != null && _wallet!.solde < minWalletBalance) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: YekiColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: YekiColors.accent.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: YekiColors.accent, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Solde minimum: $minWalletBalance FCFA par question.\n'
                        'Rechargez votre wallet pour continuer.',
                        style: TextStyle(color: YekiColors.accent, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            _buildSuggestion('Explique-moi ce concept en détail', Icons.lightbulb_outline_rounded),
            const SizedBox(height: 8),
            _buildSuggestion('Donne-moi un exemple concret tiré du cours', Icons.science_outlined),
            const SizedBox(height: 8),
            _buildSuggestion('Je n\'ai pas compris cette partie du cours', Icons.help_outline_rounded),
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
          color: YekiColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: YekiColors.borderLight),
        ),
        child: Row(
          children: [
            Icon(icon, color: YekiColors.primaryDark, size: 16),
            const SizedBox(width: 10),
            Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
            const Icon(Icons.arrow_forward_ios_rounded, size: 12),
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
            if (msg.source != 'libre' && msg.sourceTitre.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 4, right: 4),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: (_srcColors[msg.source] ?? YekiColors.primaryDark).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_sourceLabel(msg.source)} : ${msg.sourceTitre}',
                    style: TextStyle(fontSize: 10, color: _srcColors[msg.source] ?? YekiColors.primaryDark, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            if (msg.imageUrl != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(msg.imageUrl!, height: 160, width: 220, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink()),
                ),
              ),
            if (msg.audioUrl != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: YekiColors.backgroundLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: YekiColors.borderLight),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.audiotrack_rounded, color: YekiColors.purple, size: 16),
                      const SizedBox(width: 8),
                      const Text('Fichier audio', style: TextStyle(fontSize: 11)),
                    ],
                  ),
                ),
              ),
            if (msg.contenu.isNotEmpty)
              Container(
                margin: (msg.imageUrl != null || msg.audioUrl != null) ? const EdgeInsets.only(top: 4) : EdgeInsets.zero,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [YekiColors.primaryDark, YekiColors.primaryDark.withValues(alpha: 0.8)]),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(8),
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Text(msg.contenu, style: const TextStyle(color: YekiColors.white, fontSize: 14, height: 1.5)),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 4, right: 4),
              child: Text(_formatTime(msg.creeLe), style: const TextStyle(fontSize: 10)),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16, right: 48),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [YekiColors.primaryDark, YekiColors.primaryLight]),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(child: Text('YIA', style: TextStyle(color: YekiColors.white, fontSize: 9, fontWeight: FontWeight.w900))),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('Yéki IA', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                    const SizedBox(width: 8),
                    if (isStreaming)
                      _buildTypingIndicator()
                    else
                      Text(_formatTime(msg.creeLe), style: const TextStyle(fontSize: 10)),
                  ],
                ),
                const SizedBox(height: 4),
                if (isStreaming)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: YekiColors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                      border: Border.all(color: YekiColors.borderLight),
                    ),
                    child: _buildDots(),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: YekiColors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                      border: Border.all(color: YekiColors.borderLight),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(msg.contenu, style: const TextStyle(fontSize: 14, height: 1.6)),
                        if (msg.coutXaf != null && msg.coutXaf! > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text('💰 Coût: ${msg.coutXaf} FCFA', style: const TextStyle(fontSize: 10)),
                          ),
                      ],
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
        decoration: BoxDecoration(color: YekiColors.primaryDark.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
        child: const Text('en train de rédiger…',
            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600)),
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
                child: Container(width: 7, height: 7, decoration: const BoxDecoration(color: YekiColors.primaryDark, shape: BoxShape.circle)),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildInputBar() {
    final hasImage = _imageFile != null;
    final hasAudio = _audioFile != null;
    final soldeOk = _wallet != null && _wallet!.solde >= minWalletBalance;
    final canSend = !_sending && soldeOk && 
                    (_msgCtrl.text.trim().isNotEmpty || hasImage || hasAudio);
    
    return Container(
      padding: EdgeInsets.only(
          left: 12, right: 12, top: 10,
          bottom: MediaQuery.of(context).padding.bottom + 10),
      decoration: BoxDecoration(
        color: YekiColors.white,
        border: Border(top: BorderSide(color: YekiColors.borderLight)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasImage || hasAudio)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  if (hasImage)
                    _buildFilePreview(
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(_imageFile!, height: 50, width: 50, fit: BoxFit.cover),
                          ),
                          Positioned(
                            top: 0, right: 0,
                            child: GestureDetector(
                              onTap: () => setState(() => _imageFile = null),
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(color: YekiColors.error, shape: BoxShape.circle),
                                child: const Icon(Icons.close_rounded, size: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (hasAudio)
                    _buildFilePreview(
                      child: Row(
                        children: [
                          Icon(Icons.audiotrack_rounded, color: YekiColors.purple, size: 16),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 100,
                            child: Text(_audioFile!.path.split('/').last, style: const TextStyle(fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                          GestureDetector(
                            onTap: () => setState(() => _audioFile = null),
                            child: const Icon(Icons.close_rounded, size: 14),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              GestureDetector(
                onTap: _choisirImage,
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: YekiColors.backgroundLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: YekiColors.borderLight),
                  ),
                  child: const Icon(Icons.image_outlined, size: 20),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _startRecording,
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: _isRecording ? YekiColors.error.withValues(alpha: 0.1) : YekiColors.backgroundLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _isRecording ? YekiColors.error : YekiColors.borderLight),
                  ),
                  child: Icon(Icons.mic_rounded, color: _isRecording ? YekiColors.error : YekiColors.textLight, size: 20),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: YekiColors.backgroundLight,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: YekiColors.borderLight),
                  ),
                  child: TextField(
                    controller: _msgCtrl,
                    style: const TextStyle(fontSize: 14),
                    maxLines: 4,
                    minLines: 1,
                    decoration: const InputDecoration(
                      hintText: 'Posez votre question (minimum 50 FCFA)...',
                      hintStyle: TextStyle(fontSize: 13),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: canSend ? _envoyer : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    gradient: canSend
                        ? LinearGradient(colors: [YekiColors.primaryDark, YekiColors.primaryDark.withValues(alpha: 0.8)])
                        : const LinearGradient(colors: [YekiColors.borderLight, YekiColors.borderLight]),
                    shape: BoxShape.circle,
                  ),
                  child: _sending
                      ? const Center(child: YekiLoader(color: YekiColors.white, size: 18))
                      : const Icon(Icons.send_rounded, color: YekiColors.white, size: 20),
                ),
              ),
            ],
          ),
          if (!soldeOk && _wallet != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '⚠️ Solde insuffisant. Minimum requis: ${minWalletBalance.toInt()} FCFA',
                style: TextStyle(color: YekiColors.error, fontSize: 11),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilePreview({required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: YekiColors.backgroundLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: YekiColors.borderLight),
      ),
      child: child,
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
      case 'lecon': return 'Leçon';
      case 'exercice': return 'Exercice';
      case 'devoir': return 'Devoir';
      default: return 'Question';
    }
  }
}