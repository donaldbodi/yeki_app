// lib/views/pages/apprenants/yeki_ia_chat_page.dart
// ════════════════════════════════════════════════════════════════
// DISCUSSION PRIVÉE AVEC YEKI IA - TARIFICATION OPTIMISÉE
// ════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _iaBase = 'https://yeki.pythonanywhere.com/api';

// Palette harmonisée
const Color brandBackground = Color(0xFF135F74);
const Color actionOrange = Color(0xFFFF6B00);
const Color _textDark = Color(0xFF1A1C1E);
const Color _textMedium = Color(0xFF5A5C5E);
const Color _textLight = Color(0xFF8A8C8E);
const Color _borderLight = Color(0xFFE0E4E8);
const Color _bgLight = Color(0xFFF8FAFC);
const Color _white = Color(0xFFFFFFFF);

// ⭐ TARIFICATION OPTIMISÉE - RÉDUCTION SIGNIFICATIVE DES COÛTS
const double DEEPSEEK_COST_PER_1K_TOKENS = 0.14;  // 0.14 FCFA par 1000 tokens (inchangé)
const double YEKI_COMMISSION_RATE = 0.15;         // ⭐ 0.15 FCFA par message (réduit de 2.0 → 0.15)
const double MIN_MESSAGE_COST = 0.20;             // ⭐ 0.20 FCFA minimum (réduit de 5.0 → 0.20)
const double TOKEN_BUFFER = 1.2;                  // Marge de sécurité 20%

// Nouveauté : Tarifs dégressifs pour les utilisateurs actifs
const double LOYALTY_DISCOUNT = 0.10;             // 10% de réduction après 20 messages
const int MESSAGES_FOR_DISCOUNT = 20;              // Seuil pour la réduction

// Estimation des tokens par caractère
const double TOKENS_PER_CHAR = 0.25;               // 1 token ≈ 4 caractères

// ⭐ PACKAGES DE MESSAGES (abonnement léger)
const Map<String, int> MESSAGE_PACKAGES = {
  'Petit pack': 30,    // 30 messages pour 100 FCFA (3.33 FCFA/message)
  'Moyen pack': 100,   // 100 messages pour 250 FCFA (2.5 FCFA/message)
  'Grand pack': 250,   // 250 messages pour 500 FCFA (2 FCFA/message)
  'Premium': 1000,     // 1000 messages pour 1500 FCFA (1.5 FCFA/message)
};

// Map des prix des packs
const Map<String, int> PACKAGE_PRICES = {
  'Petit pack': 100,
  'Moyen pack': 250,
  'Grand pack': 500,
  'Premium': 1500,
};

// ⭐ MODÈLE POUR LE SUIVI D'UTILISATION
class _UsageStats {
  final int totalMessages;
  final int messagesThisMonth;
  final int tokensUsed;
  final double totalSpent;

  const _UsageStats({
    required this.totalMessages,
    required this.messagesThisMonth,
    required this.tokensUsed,
    required this.totalSpent,
  });

  factory _UsageStats.fromJson(Map<String, dynamic> j) => _UsageStats(
        totalMessages: j['total_messages'] ?? 0,
        messagesThisMonth: j['messages_this_month'] ?? 0,
        tokensUsed: j['tokens_used'] ?? 0,
        totalSpent: (j['total_spent'] ?? 0).toDouble(),
      );
}

// Source colors
const Map<String, Color> _srcColors = {
  'lecon':    Color(0xFF3B82F6),
  'exercice': Color(0xFFA855F7),
  'devoir':   Color(0xFFF97316),
  'libre':    Color(0xFF22C55E),
};

Future<String?> _getToken() async =>
    (await SharedPreferences.getInstance()).getString('token');

class _IAChatMessage {
  final int?   id;
  final String role;
  final String contenu;
  final String? imageUrl;
  final String  source;
  final String  sourceTitre;
  final DateTime creeLe;
  final bool   isStreaming;
  final int?   tokens;
  final double? cost;

  const _IAChatMessage({
    this.id,
    required this.role,
    required this.contenu,
    this.imageUrl,
    this.source = 'libre',
    this.sourceTitre = '',
    required this.creeLe,
    this.isStreaming = false,
    this.tokens,
    this.cost,
  });

  factory _IAChatMessage.fromJson(Map<String, dynamic> j) => _IAChatMessage(
        id:          j['id'],
        role:        j['role'] ?? 'user',
        contenu:     j['contenu'] ?? '',
        imageUrl:    j['image_url'] as String?,
        source:      j['source'] ?? 'libre',
        sourceTitre: j['source_titre'] ?? '',
        creeLe:      DateTime.tryParse(j['cree_le'] ?? '') ?? DateTime.now(),
        tokens:      j['tokens'],
        cost:        j['cost']?.toDouble(),
      );
}

class _WalletInfo {
  final int solde;
  final int totalRecharge;
  final int totalDepense;
  final int remainingMessages;      // ⭐ Messages restants dans le pack
  final String currentPack;          // ⭐ Pack actuel

  const _WalletInfo({
    required this.solde,
    required this.totalRecharge,
    required this.totalDepense,
    this.remainingMessages = 0,
    this.currentPack = '',
  });

  factory _WalletInfo.fromJson(Map<String, dynamic> j) => _WalletInfo(
        solde: j['solde'] ?? 0,
        totalRecharge: j['total_recharge'] ?? 0,
        totalDepense: j['total_depense'] ?? 0,
        remainingMessages: j['remaining_messages'] ?? 0,
        currentPack: j['current_pack'] ?? '',
      );
}

// ════════════════════════════════════════════════════════════════
// PAGE PRINCIPALE
// ════════════════════════════════════════════════════════════════
class YekiIAChatPage extends StatefulWidget {
  final int    coursId;
  final String coursTitre;
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
  _WalletInfo? _wallet;
  _UsageStats? _usageStats;
  bool _checkingSolde = false;

  late AnimationController _typingCtrl;

  @override
  void initState() {
    super.initState();
    _typingCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
    _chargerHistorique();
    _chargerWallet();
    _chargerUsageStats();

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

  Future<void> _chargerUsageStats() async {
    final token = await _getToken();
    try {
      final res = await http.get(
        Uri.parse('$_iaBase/ia/stats/'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Token $token',
        },
      );
      if (res.statusCode == 200 && mounted) {
        setState(() {
          _usageStats = _UsageStats.fromJson(jsonDecode(res.body));
        });
      }
    } catch (_) {}
  }

  Future<void> _chargerWallet() async {
    final token = await _getToken();
    try {
      final res = await http.get(
        Uri.parse('$_iaBase/wallet/solde/'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Token $token',
        },
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

  // ⭐ Calcul du coût réel avec réduction pour les utilisateurs fidèles
  double _calculerCoutMessage(int tokens) {
    // Coût de base
    double cost = (tokens / 1000) * DEEPSEEK_COST_PER_1K_TOKENS + YEKI_COMMISSION_RATE;
    
    // Appliquer la réduction de fidélité si applicable
    if (_usageStats != null && _usageStats!.totalMessages >= MESSAGES_FOR_DISCOUNT) {
      cost = cost * (1 - LOYALTY_DISCOUNT);
    }
    
    // Appliquer le coût minimum
    if (cost < MIN_MESSAGE_COST) {
      cost = MIN_MESSAGE_COST;
    }
    
    return cost;
  }

  // ⭐ Estimation plus précise du coût
  double _estimerCoutMessage(String texte) {
    final estimatedTokens = (texte.length * TOKENS_PER_CHAR).ceil();
    return _calculerCoutMessage(estimatedTokens);
  }

  // ⭐ Vérifier si l'utilisateur peut envoyer un message
  Future<bool> _verifierSoldeSuffisant(String texte) async {
    if (_wallet == null) await _chargerWallet();
    
    final coutEstime = _estimerCoutMessage(texte);
    
    // Si l'utilisateur a un pack de messages, utiliser les messages restants
    if (_wallet != null && _wallet!.remainingMessages > 0) {
      return true;  // Les messages du pack sont déjà payés
    }
    
    if (_wallet != null && _wallet!.solde < coutEstime) {
      if (mounted) {
        _showError(
          'Solde insuffisant. Vous avez ${_wallet!.solde.toStringAsFixed(0)} FCFA, '
          'mais cette question coûterait environ ${coutEstime.toStringAsFixed(0)} FCFA.\n'
          'Achetez un pack de messages pour économiser jusqu\'à 70% !',
        );
      }
      return false;
    }
    return true;
  }

  // ⭐ Acheter un pack de messages
  Future<void> _acheterPack(String packName) async {
    final token = await _getToken();
    final price = PACKAGE_PRICES[packName]!;
    
    try {
      final res = await http.post(
        Uri.parse('$_iaBase/wallet/acheter-pack/'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Token $token',
        },
        body: jsonEncode({
          'pack': packName,
          'price': price,
          'messages': MESSAGE_PACKAGES[packName],
        }),
      );
      
      if (res.statusCode == 200 && mounted) {
        await _chargerWallet();
        _showSuccess('Pack ${packName} acheté avec succès ! ${MESSAGE_PACKAGES[packName]} messages ajoutés.');
      } else {
        _showError('Erreur lors de l\'achat du pack.');
      }
    } catch (_) {
      _showError('Erreur réseau.');
    }
  }

  Future<void> _envoyer({String? prefill}) async {
    final texte = (prefill ?? _msgCtrl.text).trim();
    if (texte.isEmpty && _imageFile == null) return;

    setState(() => _checkingSolde = true);
    final soldeOk = await _verifierSoldeSuffisant(texte);
    setState(() => _checkingSolde = false);
    
    if (!soldeOk) return;

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
        final tokens = data['tokens'] as int? ?? 0;
        final cout = _calculerCoutMessage(tokens);
        
        await _chargerWallet();
        await _chargerUsageStats();
        
        setState(() {
          _messages.removeLast();
          _messages.add(_IAChatMessage(
            id:      data['assistant_id'],
            role:    'assistant',
            contenu: reponse,
            creeLe:  DateTime.now(),
            tokens:  tokens,
            cost:    cout,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: _white,
        title: const Text('Effacer la conversation',
            style: TextStyle(color: _textDark, fontSize: 16, fontWeight: FontWeight.bold)),
        content: const Text(
            'Toute la conversation avec Yeki IA sera supprimée.',
            style: TextStyle(color: _textMedium, fontSize: 13)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler', style: TextStyle(color: _textMedium))),
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

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: _white)),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showSuccess(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: _white)),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showPackDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: _white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Acheter des messages',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _textDark),
            ),
            const SizedBox(height: 16),
            const Text(
              'Économisez jusqu\'à 70% avec nos packs',
              style: TextStyle(color: _textMedium, fontSize: 14),
            ),
            const SizedBox(height: 20),
            ...MESSAGE_PACKAGES.keys.map((packName) {
              final messages = MESSAGE_PACKAGES[packName]!;
              final price = PACKAGE_PRICES[packName]!;
              final pricePerMessage = (price / messages).toStringAsFixed(1);
              final savings = ((1 - (pricePerMessage as double) / 5) * 100).toStringAsFixed(0);
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: _borderLight),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: brandBackground.withOpacity(0.1),
                    child: Text(
                      messages.toString(),
                      style: const TextStyle(fontWeight: FontWeight.bold, color: brandBackground),
                    ),
                  ),
                  title: Text(
                    packName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('${price} FCFA • ${pricePerMessage} FCFA/message'),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '-${savings}%',
                        style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _acheterPack(packName);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: brandBackground,
                          minimumSize: const Size(80, 30),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        child: const Text('Acheter', style: TextStyle(color: _white, fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),
            Text(
              '💰 Paiement unique, messages utilisables sur tous les cours',
              style: TextStyle(color: _textLight, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ── BUILD ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgLight,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          if (widget.sourceInitiale != 'libre' && widget.sourceTitreInit.isNotEmpty)
            _buildSourceBanner(),
          _buildSoldeBanner(),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: brandBackground))
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
      backgroundColor: _white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: _textDark, size: 18),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [brandBackground, Color(0xFF2884A0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Text('YIA',
                  style: TextStyle(
                      color: _white,
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
                        color: _textDark,
                        fontSize: 15,
                        fontWeight: FontWeight.w800)),
                Text(widget.coursTitre,
                    style: const TextStyle(
                        color: _textLight, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.shopping_bag_outlined,
              color: _textLight, size: 20),
          onPressed: _showPackDialog,
          tooltip: 'Acheter des messages',
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline_rounded,
              color: _textLight, size: 20),
          onPressed: _messages.isNotEmpty ? _effacerConversation : null,
          tooltip: 'Effacer la conversation',
        ),
        const SizedBox(width: 4),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(height: 1, color: _borderLight),
      ),
    );
  }

  Widget _buildSoldeBanner() {
    if (_wallet == null) return const SizedBox.shrink();
    
    final solde = _wallet!.solde;
    final remainingMessages = _wallet!.remainingMessages;
    final isLow = solde < 50 && remainingMessages == 0;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      color: isLow ? actionOrange.withOpacity(0.1) : brandBackground.withOpacity(0.05),
      child: Row(
        children: [
          Icon(
            isLow ? Icons.warning_amber_rounded : Icons.account_balance_wallet_rounded,
            color: isLow ? actionOrange : brandBackground,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (remainingMessages > 0)
                  Text(
                    '🎫 ${remainingMessages} messages restants',
                    style: TextStyle(
                      color: brandBackground,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                Text(
                  '💰 Solde: ${solde.toStringAsFixed(0)} FCFA',
                  style: TextStyle(
                    color: isLow ? actionOrange : _textMedium,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (isLow)
            GestureDetector(
              onTap: _showPackDialog,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: actionOrange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Acheter',
                  style: TextStyle(color: _white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSourceBanner() {
    final color = _srcColors[widget.sourceInitiale] ?? brandBackground;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      color: color.withOpacity(0.08),
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
                    colors: [brandBackground, Color(0xFF2884A0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Center(
                child: Text('YIA',
                    style: TextStyle(
                        color: _white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900)),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Yéki IA',
                style: TextStyle(
                    color: _textDark,
                    fontSize: 20,
                    fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text(
              'Votre assistant pédagogique personnel.\nPosez vos questions sur ce cours.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _textLight, fontSize: 14, height: 1.5),
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
          color: _white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _borderLight),
        ),
        child: Row(
          children: [
            Icon(icon, color: brandBackground, size: 16),
            const SizedBox(width: 10),
            Expanded(
              child: Text(text,
                  style: const TextStyle(color: _textMedium, fontSize: 13)),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: _textLight, size: 12),
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
                    color: (_srcColors[msg.source] ?? brandBackground).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_sourceLabel(msg.source)} : ${msg.sourceTitre}',
                    style: TextStyle(
                        fontSize: 10,
                        color: _srcColors[msg.source] ?? brandBackground,
                        fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
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
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [brandBackground, brandBackground.withOpacity(0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(4),
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Text(msg.contenu,
                    style: const TextStyle(
                        color: _white, fontSize: 14, height: 1.5)),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 4, right: 4),
              child: Text(_formatTime(msg.creeLe),
                  style: const TextStyle(color: _textLight, fontSize: 10)),
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
              gradient: const LinearGradient(
                  colors: [brandBackground, Color(0xFF2884A0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text('YIA',
                  style: TextStyle(
                      color: _white,
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
                            color: brandBackground,
                            fontSize: 11,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(width: 8),
                    if (isStreaming)
                      _buildTypingIndicator()
                    else
                      Text(_formatTime(msg.creeLe),
                          style: const TextStyle(color: _textLight, fontSize: 10)),
                  ],
                ),
                const SizedBox(height: 4),
                if (isStreaming)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: _white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                      border: Border.all(color: _borderLight),
                    ),
                    child: _buildDots(),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: _white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                      border: Border.all(color: _borderLight),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          msg.contenu.startsWith('Yeki IA :')
                              ? msg.contenu.substring(9).trim()
                              : msg.contenu,
                          style: const TextStyle(
                              color: _textDark,
                              fontSize: 14,
                              height: 1.6),
                        ),
                        if (msg.tokens != null && msg.cost != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              '💰 ~${msg.cost!.toStringAsFixed(1)} FCFA (${msg.tokens} tokens)',
                              style: const TextStyle(
                                  color: _textLight, fontSize: 9),
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

  Widget _buildTypingIndicator() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: brandBackground.withOpacity(0.08),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text('en train de rédiger…',
            style: TextStyle(
                color: brandBackground, fontSize: 9, fontWeight: FontWeight.w600)),
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
                      color: brandBackground, shape: BoxShape.circle),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildInputBar() {
    final canSend = !_sending && !_checkingSolde && 
                    (_msgCtrl.text.trim().isNotEmpty || _imageFile != null);
    
    return Container(
      padding: EdgeInsets.only(
          left: 12, right: 12, top: 10,
          bottom: MediaQuery.of(context).padding.bottom + 10),
      decoration: BoxDecoration(
        color: _white,
        border: Border(top: BorderSide(color: _borderLight)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
                          color: _white, size: 12),
                    ),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              GestureDetector(
                onTap: _choisirImage,
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: _bgLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _borderLight),
                  ),
                  child: const Icon(Icons.image_outlined,
                      color: _textLight, size: 20),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: _bgLight,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _borderLight),
                  ),
                  child: TextField(
                    controller: _msgCtrl,
                    style: const TextStyle(color: _textDark, fontSize: 14),
                    maxLines: 4,
                    minLines: 1,
                    decoration: const InputDecoration(
                      hintText: 'Posez votre question…',
                      hintStyle: TextStyle(color: _textLight, fontSize: 13),
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
                        ? LinearGradient(
                            colors: [brandBackground, brandBackground.withOpacity(0.8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight)
                        : LinearGradient(
                            colors: [_borderLight, _borderLight],
                          ),
                    shape: BoxShape.circle,
                  ),
                  child: _sending || _checkingSolde
                      ? const Center(
                          child: SizedBox(
                              width: 18, height: 18,
                              child: CircularProgressIndicator(
                                  color: _white, strokeWidth: 2)))
                      : const Icon(Icons.send_rounded,
                          color: _white, size: 20),
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