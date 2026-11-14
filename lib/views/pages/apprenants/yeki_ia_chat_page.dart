// lib/views/pages/apprenants/yeki_ia_chat_page.dart
//
// Refondu en P10.6 (migration mécanique, rituel P5.0) : bascule vers
// `IaRepository` (plus de `http`/`SharedPreferences` bruts) et vers les
// tokens/composants `Yk*` (plus de `YekiColors`/`YekiButton`/`YekiLoader`,
// dépréciés). Structure et comportement globalement inchangés — migration
// mécanique, pas une réinvention visuelle.
//
// Corrections apportées au passage (bugs/écarts confirmés par le ticket,
// pas des choix de design) :
// - `minWalletBalance = 50.0` — valeur métier codée en dur (règle 3),
//   déconnectée du vrai seuil backend (`ParametreSysteme['solde_min_ia']`,
//   20 FCFA par défaut) et jamais synchronisée. Aucun endpoint ne permet
//   de lire ce seuil par avance (`estimer_fourchette_cout` n'existe que
//   DANS la vue d'envoi) — supprimée : le solde insuffisant n'est plus
//   anticipé côté client, il est détecté à partir de la vraie réponse 402
//   du backend (`solde_actuel`, `minimum_requis`, `cout_estime_min/max`),
//   qui fait autorité.
// - `ApiException.fromEnvelope` perdait silencieusement les champs
//   `solde_actuel`/`minimum_requis`/`cout_estime_min/max` du 402/503 (repli
//   `detail is String` ne gardait que le message) — corrigé dans
//   `api_exception.dart` au passage, condition nécessaire pour afficher
//   ces informations ici.
// - `_imageFile`/`_audioFile` (choisis via `image_picker`) passent de
//   `File` (dart:io) à `Uint8List` : `File` plante sur le web, même bug
//   déjà corrigé ailleurs dans le projet. L'enregistrement microphone
//   (`record`) garde un chemin temporaire disque le temps de
//   l'enregistrement (exigence du plugin), converti en `Uint8List`
//   immédiatement après l'arrêt — jamais transporté plus loin.
// - Réponses IA rendues via `YkRichViewer` (formules incluses si le
//   contenu utilise un jour la convention `yk-formula`), plus un `Text`
//   brut.

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import 'package:yeki/core/design/components/components.dart';
import 'package:yeki/core/design/tokens/tokens.dart';
import 'package:yeki/core/network/api_exception.dart';
import 'package:yeki/core/router/route_names.dart';
import 'package:yeki/repositories/ia_repository.dart';
import 'package:yeki/repositories/wallet_repository.dart';
import 'package:yeki/utils/error_handler.dart';

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

/// Détail d'un refus 402 (solde insuffisant) — fait autorité, jamais
/// anticipé côté client (voir commentaire de tête).
class _SoldeInsuffisantInfo {
  const _SoldeInsuffisantInfo({
    required this.soldeActuel,
    required this.minimumRequis,
    required this.coutEstimeMin,
    required this.coutEstimeMax,
  });

  final int soldeActuel;
  final int minimumRequis;
  final int coutEstimeMin;
  final int coutEstimeMax;
}

String _sourceLabel(String src) {
  switch (src) {
    case 'lecon':
      return 'Leçon';
    case 'exercice':
      return 'Exercice';
    case 'devoir':
      return 'Devoir';
    default:
      return 'Question';
  }
}

class YekiIAChatPage extends StatefulWidget {
  final int coursId;
  final String coursTitre;
  final String? messageInitial;
  final String sourceInitiale;
  final int? sourceId;
  final String sourceTitreInit;

  /// Prérempli depuis `detail_lecon_page.dart::_PreoccupationSheet` (bottom
  /// sheet propre à cet écran — pas `form_preoccupation_sheet.dart`), qui
  /// travaille encore en `File` (hors périmètre P10.5/P10.6, non retouché
  /// ici). Convertis en `Uint8List` dès `initState` — jamais réutilisés
  /// comme `File` au-delà.
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

class _YekiIAChatPageState extends State<YekiIAChatPage> with TickerProviderStateMixin {
  final _iaRepo = IaRepository();
  final _walletRepo = WalletRepository();
  final List<_IAChatMessage> _messages = [];
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _loading = true;
  bool _sending = false;
  Uint8List? _imageBytes;
  Uint8List? _audioBytes;
  int? _solde;
  _SoldeInsuffisantInfo? _soldeInsuffisant;

  // Enregistrement audio.
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  bool _hasPermission = false;
  Duration _recordingDuration = Duration.zero;
  Timer? _recordingTimer;

  late AnimationController _typingCtrl;

  @override
  void initState() {
    super.initState();
    _typingCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
    _chargerHistorique();
    _chargerSolde();
    _checkMicrophonePermission();
    _chargerMediaInitiaux();

    if (widget.messageInitial != null && widget.messageInitial!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _msgCtrl.text = widget.messageInitial!;
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && _msgCtrl.text.isNotEmpty) _envoyer();
        });
      });
    }
  }

  Future<void> _chargerMediaInitiaux() async {
    final image = widget.initialImage;
    final audio = widget.initialAudio;
    if (image == null && audio == null) return;
    final imageBytes = image != null ? await image.readAsBytes() : null;
    final audioBytes = audio != null ? await audio.readAsBytes() : null;
    if (!mounted) return;
    setState(() {
      _imageBytes = imageBytes;
      _audioBytes = audioBytes;
    });
  }

  @override
  void dispose() {
    _typingCtrl.dispose();
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    _recordingTimer?.cancel();
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _checkMicrophonePermission() async {
    try {
      final permission = await _audioRecorder.hasPermission();
      if (mounted) setState(() => _hasPermission = permission);
    } catch (_) {
      if (mounted) setState(() => _hasPermission = false);
    }
  }

  Future<void> _requestMicrophonePermission() async {
    try {
      final permission = await _audioRecorder.hasPermission();
      if (mounted) setState(() => _hasPermission = permission);
      if (!permission && mounted) {
        ErrorHandler.showError(context, "Autorisez l'accès au microphone");
      }
    } catch (_) {
      if (mounted) ErrorHandler.showError(context, 'Erreur permission microphone');
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
          setState(() => _recordingDuration += const Duration(seconds: 1));
        }
      });
    } catch (e) {
      if (mounted) ErrorHandler.showError(context, 'Erreur démarrage enregistrement: $e');
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
          final bytes = await file.readAsBytes();
          await file.delete();
          setState(() {
            _audioBytes = bytes;
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
    } catch (_) {
      setState(() => _isRecording = false);
      if (mounted) ErrorHandler.showError(context, "Erreur d'arrêt d'enregistrement");
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
    return '${twoDigits(d.inMinutes.remainder(60))}:${twoDigits(d.inSeconds.remainder(60))}';
  }

  Future<void> _chargerSolde() async {
    try {
      final solde = await _walletRepo.solde();
      if (mounted) setState(() => _solde = solde);
    } catch (_) {}
  }

  Future<void> _chargerHistorique() async {
    setState(() => _loading = true);
    try {
      final data = await _iaRepo.historique(widget.coursId);
      if (!mounted) return;
      setState(() {
        _messages.clear();
        _messages.addAll(data.map((j) => _IAChatMessage.fromJson(j)));
        _loading = false;
      });
      _scrollToBottom();
      if (widget.messageInitial != null && widget.messageInitial!.isNotEmpty && _messages.isEmpty) {
        _envoyer();
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _envoyer({String? prefill}) async {
    final texte = (prefill ?? _msgCtrl.text).trim();
    if (texte.isEmpty && _imageBytes == null && _audioBytes == null) return;

    final msgUser = _IAChatMessage(
      role: 'user',
      contenu: texte,
      source: widget.sourceInitiale,
      sourceTitre: widget.sourceTitreInit,
      creeLe: DateTime.now(),
    );
    final typing = _IAChatMessage(
      role: 'assistant',
      contenu: '…',
      creeLe: DateTime.now(),
      isStreaming: true,
    );
    setState(() {
      _messages.add(msgUser);
      _messages.add(typing);
      _sending = true;
    });
    _msgCtrl.clear();
    _scrollToBottom();

    final imageBytes = _imageBytes;
    final audioBytes = _audioBytes;
    setState(() {
      _imageBytes = null;
      _audioBytes = null;
    });

    try {
      final data = await _iaRepo.chat(
        coursId: widget.coursId,
        message: texte,
        source: widget.sourceInitiale,
        sourceId: widget.sourceId,
        sourceTitre: widget.sourceTitreInit,
        imageBytes: imageBytes,
        audioBytes: audioBytes,
      );
      if (!mounted) return;
      setState(() {
        _messages.removeLast();
        _messages.add(
          _IAChatMessage(
            id: data['assistant_id'],
            role: 'assistant',
            contenu: data['reponse'] as String? ?? '',
            creeLe: DateTime.now(),
            tokensInput: data['tokens_input'],
            tokensOutput: data['tokens_output'],
            coutXaf: data['cout_xaf'] as int?,
          ),
        );
        _solde = data['solde_restant'] as int? ?? _solde;
        _soldeInsuffisant = null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 402) {
        setState(() {
          _messages.removeLast();
          _messages.removeLast();
          _soldeInsuffisant = _SoldeInsuffisantInfo(
            soldeActuel: (e.fields['solde_actuel'] as num?)?.toInt() ?? 0,
            minimumRequis: (e.fields['minimum_requis'] as num?)?.toInt() ?? 0,
            coutEstimeMin: (e.fields['cout_estime_min'] as num?)?.toInt() ?? 0,
            coutEstimeMax: (e.fields['cout_estime_max'] as num?)?.toInt() ?? 0,
          );
        });
      } else {
        setState(() {
          _messages.removeLast();
          _messages.add(
            _IAChatMessage(role: 'assistant', contenu: 'Yéki IA : ${e.message}', creeLe: DateTime.now()),
          );
          final soldeActuel = e.fields['solde_actuel'];
          if (soldeActuel is num) _solde = soldeActuel.toInt();
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.removeLast();
        _messages.add(
          _IAChatMessage(
            role: 'assistant',
            contenu: 'Yéki IA : Erreur de connexion. Vérifiez votre réseau.',
            creeLe: DateTime.now(),
          ),
        );
      });
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
      final bytes = await picked.readAsBytes();
      setState(() => _imageBytes = bytes);
    }
  }

  Future<void> _effacerConversation() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(YkRadius.lg)),
        title: const Text('Effacer la conversation'),
        content: const Text('Toute la conversation avec Yéki IA sera supprimée.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Effacer', style: TextStyle(color: YkColors.error)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _iaRepo.effacerHistorique(widget.coursId);
      if (mounted) setState(() => _messages.clear());
    } catch (_) {
      if (mounted) ErrorHandler.showError(context, "Erreur lors de l'effacement.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: YkColors.background(context),
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          _buildSoldeBanner(context),
          Expanded(
            child: _loading
                ? Center(child: YkProgress(shape: YkProgressShape.circular))
                : (_messages.isEmpty && _soldeInsuffisant != null)
                ? _buildSoldeInsuffisantEmptyState(context)
                : _messages.isEmpty
                ? _buildEmptyState(context)
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: EdgeInsets.fromLTRB(YkSpacing.sm, YkSpacing.sm, YkSpacing.sm, YkSpacing.xs),
                    itemCount: _messages.length,
                    itemBuilder: (_, i) => _buildBubble(context, _messages[i]),
                  ),
          ),
          if (_isRecording) _buildRecordingBar(context) else _buildInputBar(context),
        ],
      ),
    );
  }

  Widget _buildRecordingBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(YkSpacing.md),
      decoration: BoxDecoration(
        color: YkColors.surface(context),
        border: Border(top: BorderSide(color: YkColors.border(context))),
      ),
      child: Row(
        children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(color: YkColors.error, shape: BoxShape.circle)),
          SizedBox(width: YkSpacing.sm),
          Text(
            'Enregistrement • ${_formatDuration(_recordingDuration)}',
            style: YkTypography.label(context).copyWith(color: YkColors.error),
          ),
          const Spacer(),
          YkButton(label: 'Arrêter', variant: YkButtonVariant.primary, onPressed: _stopRecording),
          SizedBox(width: YkSpacing.xs),
          YkButton(label: 'Annuler', variant: YkButtonVariant.tertiary, onPressed: _cancelRecording),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    // Dégradé de marque (`YkGradientAppBar`) — le titre/sous-titre passent
    // en blanc pour rester lisibles sur ce fond, comme le reste des
    // en-têtes dégradés de l'app.
    return YkGradientAppBar(
      titleWidget: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.white24,
            child: Text('YIA', style: YkTypography.caption(context).copyWith(color: Colors.white)),
          ),
          SizedBox(width: YkSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Yéki IA'),
                Text(
                  widget.coursTitre,
                  style: YkTypography.caption(context).copyWith(color: Colors.white70),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.delete_outline_rounded),
          onPressed: _messages.isNotEmpty ? _effacerConversation : null,
          tooltip: 'Effacer la conversation',
        ),
      ],
    );
  }

  Widget _buildSoldeBanner(BuildContext context) {
    if (_solde == null) return const SizedBox.shrink();
    final enAlerte = _soldeInsuffisant != null;
    final color = enAlerte ? YkColors.error : YkColors.accent(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: YkSpacing.md, vertical: YkSpacing.xs),
      color: color.withValues(alpha: 0.08),
      child: Row(
        children: [
          Icon(
            enAlerte ? Icons.warning_amber_rounded : Icons.account_balance_wallet_rounded,
            color: color,
            size: 16,
          ),
          SizedBox(width: YkSpacing.xs),
          Expanded(
            child: Text(
              'Solde : $_solde FCFA',
              style: YkTypography.label(context).copyWith(color: color),
            ),
          ),
          if (enAlerte)
            TextButton(
              onPressed: () => context.pushNamed(AppRoute.recharge),
              child: const Text('Recharger'),
            ),
        ],
      ),
    );
  }

  Widget _buildSoldeInsuffisantEmptyState(BuildContext context) {
    final info = _soldeInsuffisant!;
    return YkEmptyState(
      icon: Icons.account_balance_wallet_outlined,
      title: 'Solde insuffisant',
      message:
          'Votre solde (${info.soldeActuel} FCFA) est sous le minimum requis '
          '(${info.minimumRequis} FCFA).\nCoût estimé de cette question : '
          'entre ${info.coutEstimeMin} et ${info.coutEstimeMax} FCFA.',
      actionLabel: 'Recharger',
      onAction: () => context.pushNamed(AppRoute.recharge),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final accent = YkColors.accent(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.all(YkSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: accent,
              child: Text(
                'YIA',
                style: YkTypography.h3(context).copyWith(color: YkColors.onAccent(context)),
              ),
            ),
            SizedBox(height: YkSpacing.lg),
            Text('Yéki IA', style: YkTypography.h3(context).copyWith(color: YkColors.textPrimary(context))),
            SizedBox(height: YkSpacing.xs),
            Text(
              'Votre assistant pédagogique expert de ce cours.\n'
              'Posez vos questions, je les analyse et y réponds '
              'en utilisant le contenu du cours.',
              textAlign: TextAlign.center,
              style: YkTypography.bodyMd(context).copyWith(color: YkColors.textSecondary(context)),
            ),
            SizedBox(height: YkSpacing.lg),
            _buildSuggestion(context, 'Explique-moi ce concept en détail', Icons.lightbulb_outline_rounded),
            SizedBox(height: YkSpacing.xs),
            _buildSuggestion(context, 'Donne-moi un exemple concret tiré du cours', Icons.science_outlined),
            SizedBox(height: YkSpacing.xs),
            _buildSuggestion(context, "Je n'ai pas compris cette partie du cours", Icons.help_outline_rounded),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestion(BuildContext context, String text, IconData icon) {
    return YkCard(
      onTap: () {
        _msgCtrl.text = text;
        setState(() {});
      },
      child: Row(
        children: [
          Icon(icon, color: YkColors.accent(context), size: 16),
          SizedBox(width: YkSpacing.sm),
          Expanded(
            child: Text(text, style: YkTypography.bodySm(context).copyWith(color: YkColors.textPrimary(context))),
          ),
          Icon(Icons.arrow_forward_ios_rounded, size: 12, color: YkColors.textTertiary(context)),
        ],
      ),
    );
  }

  Widget _buildBubble(BuildContext context, _IAChatMessage msg) {
    final isUser = msg.role == 'user';
    if (isUser) return _buildBubbleUser(context, msg);
    return _buildBubbleAssistant(context, msg);
  }

  Widget _buildBubbleUser(BuildContext context, _IAChatMessage msg) {
    final accent = YkColors.accent(context);
    return Padding(
      padding: EdgeInsets.only(bottom: YkSpacing.sm, left: 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (msg.source != 'libre' && msg.sourceTitre.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(bottom: YkSpacing.xxs),
              child: YkBadge(
                variant: YkBadgeVariant.label,
                label: '${_sourceLabel(msg.source)} : ${msg.sourceTitre}',
                color: accent,
              ),
            ),
          if (msg.imageUrl != null)
            Padding(
              padding: EdgeInsets.only(bottom: YkSpacing.xxs),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(YkRadius.md),
                child: Image.network(
                  msg.imageUrl!,
                  height: 160,
                  width: 220,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            ),
          if (msg.audioUrl != null)
            Padding(
              padding: EdgeInsets.only(bottom: YkSpacing.xxs),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: YkSpacing.sm, vertical: YkSpacing.xs),
                decoration: BoxDecoration(
                  color: YkColors.surfaceVariant(context),
                  borderRadius: BorderRadius.circular(YkRadius.sm),
                  border: Border.all(color: YkColors.border(context)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.audiotrack_rounded, color: accent, size: 16),
                    SizedBox(width: YkSpacing.xs),
                    Text('Fichier audio', style: YkTypography.caption(context)),
                  ],
                ),
              ),
            ),
          if (msg.contenu.isNotEmpty)
            Container(
              padding: EdgeInsets.symmetric(horizontal: YkSpacing.md, vertical: YkSpacing.sm),
              decoration: BoxDecoration(
                color: accent,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(8),
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Text(
                msg.contenu,
                style: YkTypography.bodyMd(context).copyWith(color: YkColors.onAccent(context)),
              ),
            ),
          Padding(
            padding: EdgeInsets.only(top: YkSpacing.xxs),
            child: Text(
              _formatTime(msg.creeLe),
              style: YkTypography.caption(context).copyWith(color: YkColors.textTertiary(context)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBubbleAssistant(BuildContext context, _IAChatMessage msg) {
    final accent = YkColors.accent(context);
    return Padding(
      padding: EdgeInsets.only(bottom: YkSpacing.md, right: 48),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: accent,
            child: Text('YIA', style: YkTypography.caption(context).copyWith(color: YkColors.onAccent(context))),
          ),
          SizedBox(width: YkSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Yéki IA', style: YkTypography.label(context).copyWith(color: YkColors.textPrimary(context))),
                    SizedBox(width: YkSpacing.xs),
                    if (msg.isStreaming)
                      _buildTypingIndicator(context)
                    else
                      Text(
                        _formatTime(msg.creeLe),
                        style: YkTypography.caption(context).copyWith(color: YkColors.textTertiary(context)),
                      ),
                  ],
                ),
                SizedBox(height: YkSpacing.xxs),
                YkCard(
                  variant: YkCardVariant.outlined,
                  child: msg.isStreaming
                      ? _buildDots(context)
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            YkRichViewer(html: msg.contenu),
                            if (msg.coutXaf != null && msg.coutXaf! > 0)
                              Padding(
                                padding: EdgeInsets.only(top: YkSpacing.xs),
                                child: Text(
                                  'Coût : ${msg.coutXaf} FCFA',
                                  style: YkTypography.caption(
                                    context,
                                  ).copyWith(color: YkColors.textTertiary(context)),
                                ),
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

  Widget _buildTypingIndicator(BuildContext context) => YkBadge(
    variant: YkBadgeVariant.label,
    label: 'en train de rédiger…',
    color: YkColors.accent(context),
  );

  Widget _buildDots(BuildContext context) {
    final accent = YkColors.accent(context);
    return AnimatedBuilder(
      animation: _typingCtrl,
      builder: (_, _) {
        final v = _typingCtrl.value;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final opacity = ((v * 3 - i).clamp(0.0, 1.0) * (1 - (v * 3 - i - 1).clamp(0.0, 1.0))).clamp(0.3, 1.0);
            return Padding(
              padding: EdgeInsets.only(right: YkSpacing.xxs),
              child: Opacity(
                opacity: opacity,
                child: Container(width: 7, height: 7, decoration: BoxDecoration(color: accent, shape: BoxShape.circle)),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildInputBar(BuildContext context) {
    final hasImage = _imageBytes != null;
    final hasAudio = _audioBytes != null;
    final canSend = !_sending && (_msgCtrl.text.trim().isNotEmpty || hasImage || hasAudio);

    return Container(
      padding: EdgeInsets.only(
        left: YkSpacing.sm,
        right: YkSpacing.sm,
        top: YkSpacing.sm,
        bottom: MediaQuery.of(context).padding.bottom + YkSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: YkColors.surface(context),
        border: Border(top: BorderSide(color: YkColors.border(context))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasImage || hasAudio)
            Padding(
              padding: EdgeInsets.only(bottom: YkSpacing.xs),
              child: Row(
                children: [
                  if (hasImage)
                    _buildFilePreview(
                      context,
                      onRemove: () => setState(() => _imageBytes = null),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(YkRadius.xs),
                        child: Image.memory(_imageBytes!, height: 40, width: 40, fit: BoxFit.cover),
                      ),
                    ),
                  if (hasAudio)
                    _buildFilePreview(
                      context,
                      onRemove: () => setState(() => _audioBytes = null),
                      child: Icon(Icons.audiotrack_rounded, color: YkColors.accent(context), size: 20),
                    ),
                ],
              ),
            ),
          Row(
            children: [
              YkIconButton(
                icon: Icons.image_outlined,
                label: 'Ajouter une image',
                variant: YkIconButtonVariant.tonal,
                onPressed: _choisirImage,
              ),
              SizedBox(width: YkSpacing.xs),
              YkIconButton(
                icon: Icons.mic_rounded,
                label: 'Enregistrer un message vocal',
                variant: _isRecording ? YkIconButtonVariant.filled : YkIconButtonVariant.tonal,
                onPressed: _startRecording,
              ),
              SizedBox(width: YkSpacing.xs),
              Expanded(
                child: YkTextField(
                  controller: _msgCtrl,
                  type: YkTextFieldType.multiline,
                  maxLines: 4,
                  hint: 'Posez votre question...',
                  onChanged: (_) => setState(() {}),
                ),
              ),
              SizedBox(width: YkSpacing.xs),
              _sending
                  ? Padding(
                      padding: EdgeInsets.all(YkSpacing.sm),
                      child: YkProgress(shape: YkProgressShape.circular, size: 24),
                    )
                  : YkIconButton(
                      icon: Icons.send_rounded,
                      label: 'Envoyer',
                      variant: YkIconButtonVariant.filled,
                      onPressed: canSend ? _envoyer : null,
                    ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilePreview(BuildContext context, {required Widget child, required VoidCallback onRemove}) {
    return Container(
      margin: EdgeInsets.only(right: YkSpacing.xs),
      padding: EdgeInsets.all(YkSpacing.xxs),
      decoration: BoxDecoration(
        color: YkColors.surfaceVariant(context),
        borderRadius: BorderRadius.circular(YkRadius.sm),
        border: Border.all(color: YkColors.border(context)),
      ),
      child: Stack(
        children: [
          child,
          Positioned(
            top: -4,
            right: -4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: EdgeInsets.all(2),
                decoration: BoxDecoration(color: YkColors.error, shape: BoxShape.circle),
                child: const Icon(Icons.close_rounded, size: 12, color: Colors.white),
              ),
            ),
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
}
