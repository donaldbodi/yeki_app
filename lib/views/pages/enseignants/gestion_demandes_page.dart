// lib/views/pages/enseignants/gestion_demandes_page.dart
// ════════════════════════════════════════════════════════════════
// GESTION DES DEMANDES D'ACCÈS - ENSEIGNANT CADRE
// ════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yeki/core/theme/app_theme.dart';
import 'package:yeki/core/constants/api_constants.dart';
import 'package:yeki/utils/error_handler.dart';

class GestionDemandesPage extends StatefulWidget {
  final int departementId;
  final String departementNom;
  
  const GestionDemandesPage({
    super.key,
    required this.departementId,
    required this.departementNom,
  });
  
  @override
  State<GestionDemandesPage> createState() => _GestionDemandesPageState();
}

class _GestionDemandesPageState extends State<GestionDemandesPage>
    with SingleTickerProviderStateMixin {
  bool _loading = true;
  List<Map<String, dynamic>> _demandes = [];
  late TabController _tabController;
  String _statutFiltre = 'en_attente';
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    _charger();
  }
  
  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      final statuts = ['en_attente', 'acceptee', 'refusee'];
      setState(() => _statutFiltre = statuts[_tabController.index]);
      _charger();
    }
  }
  
  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }
  
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }
  
  Future<void> _charger() async {
    setState(() => _loading = true);
    final token = await _getToken();
    if (token == null) {
      setState(() => _loading = false);
      return;
    }
    
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/departements/${widget.departementId}/demandes/?statut=$_statutFiltre'),
        headers: ApiHeaders.auth(token),
      );
      
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        setState(() {
          _demandes = data.map((d) => Map<String, dynamic>.from(d)).toList();
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
        ErrorHandler.showError(context, 'Erreur chargement (${response.statusCode})');
      }
    } catch (_) {
      setState(() => _loading = false);
      ErrorHandler.showError(context, 'Erreur réseau');
    }
  }
  
  Future<void> _traiterDemande(int demandeId, String action) async {
    final token = await _getToken();
    if (token == null) return;
    
    final reponseController = TextEditingController();
    bool? result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: YekiColors.white,
        title: Text(
          action == 'accepter' ? 'Accepter la demande' : 'Refuser la demande',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              action == 'accepter' 
                  ? 'Confirmez l\'accès à la formation pour cet apprenant.'
                  : 'Confirmez le refus d\'accès pour cet apprenant.',
              style: const TextStyle(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reponseController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: action == 'accepter' 
                    ? 'Message optionnel pour l\'apprenant...' 
                    : 'Motif du refus...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler', style: TextStyle(color: YekiColors.textMedium)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: action == 'accepter' ? YekiColors.success : YekiColors.error,
              foregroundColor: YekiColors.white,
              elevation: 0,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(action == 'accepter' ? 'Accepter' : 'Refuser'),
          ),
        ],
      ),
    );
    
    if (result != true) return;
    
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/departements/${widget.departementId}/demandes/$demandeId/traiter/'),
        headers: ApiHeaders.auth(token),
        body: jsonEncode({
          'action': action,
          'reponse': reponseController.text.trim(),
        }),
      );
      
      if (response.statusCode == 200) {
        ErrorHandler.showSuccess(
          context, 
          action == 'accepter' 
              ? '✅ Demande acceptée avec succès !' 
              : '❌ Demande refusée.'
        );
        _charger();
      } else {
        final error = jsonDecode(response.body);
        ErrorHandler.showError(context, error['detail'] ?? 'Erreur');
      }
    } catch (_) {
      ErrorHandler.showError(context, 'Erreur réseau');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: YekiColors.backgroundLight,
      appBar: AppBar(
        title: Text('Demandes d\'accès - ${widget.departementNom}'),
        backgroundColor: YekiColors.primaryDark,
        foregroundColor: YekiColors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _charger,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: YekiColors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: YekiColors.primaryDark,
              unselectedLabelColor: YekiColors.textLight,
              indicatorColor: YekiColors.primaryDark,
              tabs: const [
                Tab(text: 'En attente'),
                Tab(text: 'Acceptées'),
                Tab(text: 'Refusées'),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: YekiLoader())
                : _demandes.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _demandes.length,
                        itemBuilder: (_, i) => _buildDemandeCard(_demandes[i]),
                      ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyState() {
    String message;
    switch (_statutFiltre) {
      case 'en_attente':
        message = 'Aucune demande en attente';
        break;
      case 'acceptee':
        message = 'Aucune demande acceptée';
        break;
      case 'refusee':
        message = 'Aucune demande refusée';
        break;
      default:
        message = 'Aucune demande';
    }
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: YekiColors.primaryDark.withValues(alpha: 0.08),
              shape: BoxShape.circle,
              border: Border.all(color: YekiColors.primaryDark.withValues(alpha: 0.2), width: 1),
            ),
            child: Icon(
              _statutFiltre == 'en_attente' 
                  ? Icons.hourglass_empty_rounded 
                  : _statutFiltre == 'acceptee'
                      ? Icons.check_circle_outline_rounded
                      : Icons.cancel_outlined,
              size: 48,
              color: YekiColors.primaryDark,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: YekiColors.textMedium,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDemandeCard(Map<String, dynamic> demande) {
    final bool enAttente = demande['statut'] == 'en_attente';
    final String apprenantNom = demande['apprenant_nom'] ?? demande['apprenant_username'] ?? '';
    final String apprenantEmail = demande['apprenant_email'] ?? '';
    final String message = demande['message'] ?? '';
    final String reponse = demande['reponse_cadre'] ?? '';
    final String creeLe = demande['cree_le'] ?? '';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: YekiColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: enAttente 
              ? YekiColors.warning.withValues(alpha: 0.5) 
              : YekiColors.borderLight,
          width: enAttente ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: YekiColors.primaryDark.withValues(alpha: 0.1),
                child: Text(
                  apprenantNom.isNotEmpty ? apprenantNom[0].toUpperCase() : '?',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: YekiColors.primaryDark,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      apprenantNom,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: YekiColors.textDark,
                      ),
                    ),
                    Text(
                      apprenantEmail,
                      style: const TextStyle(fontSize: 12, color: YekiColors.textLight),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: enAttente 
                      ? YekiColors.warning.withValues(alpha: 0.12) 
                      : demande['statut'] == 'acceptee'
                          ? YekiColors.success.withValues(alpha: 0.12)
                          : YekiColors.error.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  enAttente ? 'En attente' : demande['statut'],
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: enAttente 
                        ? YekiColors.warning 
                        : demande['statut'] == 'acceptee'
                            ? YekiColors.success
                            : YekiColors.error,
                  ),
                ),
              ),
            ],
          ),
          
          if (message.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: YekiColors.backgroundLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Message du demandeur :',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: YekiColors.textLight),
                  ),
                  const SizedBox(height: 4),
                  Text(message, style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),
          ],
          
          if (reponse.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: demande['statut'] == 'acceptee' 
                    ? YekiColors.success.withValues(alpha: 0.05) 
                    : YekiColors.error.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: demande['statut'] == 'acceptee' 
                      ? YekiColors.success.withValues(alpha: 0.2) 
                      : YekiColors.error.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    demande['statut'] == 'acceptee' ? 'Réponse positive :' : 'Motif du refus :',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: demande['statut'] == 'acceptee' ? YekiColors.success : YekiColors.error,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(reponse, style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),
          ],
          
          if (creeLe.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Demande du ${creeLe.substring(0, 10)}',
              style: const TextStyle(fontSize: 11, color: YekiColors.textLight),
            ),
          ],
          
          if (enAttente) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _traiterDemande(demande['id'], 'accepter'),
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Accepter'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: YekiColors.success,
                      foregroundColor: YekiColors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _traiterDemande(demande['id'], 'refuser'),
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: const Text('Refuser'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: YekiColors.error,
                      side: const BorderSide(color: YekiColors.error),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}