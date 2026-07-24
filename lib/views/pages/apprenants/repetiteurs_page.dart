// lib/views/pages/apprenants/repetiteurs_page.dart
// ═══════════════════════════════════════════════════════════════════════════
//  PAGE RECHERCHE RÉPÉTITEURS PAR MATIÈRE (WHATSAPP) - CORRIGÉE
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yeki/core/theme/app_theme.dart';
import 'package:yeki/core/constants/api_constants.dart';
import 'package:yeki/utils/error_handler.dart';

class RepetiteursPage extends StatefulWidget {
  const RepetiteursPage({super.key});

  @override
  State<RepetiteursPage> createState() => _RepetiteursPageState();
}

class _RepetiteursPageState extends State<RepetiteursPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  final TextEditingController _niveauCtrl = TextEditingController();
  final TextEditingController _villeCtrl = TextEditingController();
  
  List<Map<String, dynamic>> _repetiteurs = [];
  bool _loading = false;
  bool _initialLoading = true;
  String? _selectedMatiere;
  String? _error;
  
  // Données du profil
  Map<String, dynamic> _profil = {};
  bool _profilCharged = false;

  final List<String> _matieresPopulaires = [
    'Mathématiques', 'Physique', 'Chimie', 'SVT', 
    'Informatique', 'Français', 'Anglais', 'Histoire-Géo'
  ];

  @override
  void initState() {
    super.initState();
    _chargerProfil();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _niveauCtrl.dispose();
    _villeCtrl.dispose();
    super.dispose();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> _chargerProfil() async {
    setState(() => _initialLoading = true);
    final token = await _getToken();
    if (token == null) {
      setState(() => _initialLoading = false);
      return;
    }
    
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.profilMe),
        headers: ApiHeaders.auth(token),
      );
      
      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body);
        setState(() {
          _profil = data;
          _profilCharged = true;
          
          // Pré-remplir les champs avec les données du profil
          if (_profil['niveau'] != null && _profil['niveau'].toString().isNotEmpty) {
            _niveauCtrl.text = _profil['niveau'].toString();
          }
          if (_profil['ville'] != null && _profil['ville'].toString().isNotEmpty) {
            _villeCtrl.text = _profil['ville'].toString();
          }
          _initialLoading = false;
        });
      } else {
        setState(() => _initialLoading = false);
      }
    } catch (_) {
      setState(() => _initialLoading = false);
    }
  }

  Future<void> _rechercher(String matiere) async {
    if (matiere.trim().isEmpty) {
      ErrorHandler.showWarning(context, 'Veuillez entrer une matière');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _selectedMatiere = matiere;
    });

    final token = await _getToken();
    if (token == null) {
      setState(() {
        _loading = false;
        _error = 'Veuillez vous reconnecter';
      });
      return;
    }

    try {
      // Construire l'URL avec les paramètres
      String url = '${ApiConstants.baseUrl}/repetiteurs/search/?matiere=${Uri.encodeComponent(matiere)}';
      if (_villeCtrl.text.trim().isNotEmpty) {
        url += '&ville=${Uri.encodeComponent(_villeCtrl.text.trim())}';
      }
      if (_niveauCtrl.text.trim().isNotEmpty) {
        url += '&niveau=${Uri.encodeComponent(_niveauCtrl.text.trim())}';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: ApiHeaders.auth(token),
      );

      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body);
        setState(() {
          _repetiteurs = List<Map<String, dynamic>>.from(data['repetiteurs'] ?? []);
          _loading = false;
        });
        if (_repetiteurs.isEmpty) {
          ErrorHandler.showWarning(context, 'Aucun répétiteur trouvé pour "$matiere"');
        }
      } else {
        setState(() {
          _loading = false;
          _error = 'Erreur ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Erreur de connexion';
      });
    }
  }

  // CORRECTION: Version alternative qui fonctionne avec tous les formats
  Future<void> _contacterWhatsAppV2(String numero, String nom, String matiere) async {
    if (numero.isEmpty) {
      ErrorHandler.showError(context, 'Numéro de téléphone non disponible');
      return;
    }
    
    // Nettoyer le numéro - méthode simplifiée
    String cleanNumber = numero.replaceAll(RegExp(r'[^0-9]'), '');
    
    // Si le numéro commence par 237, on garde tel quel
    if (cleanNumber.startsWith('237')) {
      // Rien à faire
    } 
    // Si le numéro commence par 6 (Cameroun), on ajoute 237
    else if (cleanNumber.startsWith('6')) {
      cleanNumber = '237$cleanNumber';
    }
    // Si le numéro est court, on suppose que c'est un numéro camerounais
    else if (cleanNumber.length <= 9) {
      cleanNumber = '237$cleanNumber';
    }
    
    // S'assurer que le numéro a au moins 10 chiffres
    if (cleanNumber.length < 10) {
      ErrorHandler.showError(context, 'Numéro WhatsApp invalide');
      return;
    }
    
    final niveau = _niveauCtrl.text.trim().isNotEmpty ? _niveauCtrl.text.trim() : 'votre niveau';
    final ville = _villeCtrl.text.trim().isNotEmpty ? _villeCtrl.text.trim() : 'votre ville';
    
    final message = Uri.encodeComponent(
      'Bonjour $nom,\n\n'
      'Je souhaite prendre des cours particuliers en $matiere avec vous via Yéki.\n'
      'Niveau : $niveau\n'
      'Ville : $ville\n'
      'Tarif : 5000 FCFA/mois.\n\n'
      'Pouvez-vous me donner plus d\'informations sur vos disponibilités ?\n\n'
      'Cordialement.'
    );
    
    // Utiliser l'URL API WhatsApp qui fonctionne toujours
    final url = Uri.parse('https://api.whatsapp.com/send?phone=$cleanNumber&text=$message');
    
    debugPrint('WhatsApp URL (V2): $url');
    
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        // Fallback sur wa.me
        final fallbackUrl = Uri.parse('https://wa.me/$cleanNumber?text=$message');
        if (await canLaunchUrl(fallbackUrl)) {
          await launchUrl(fallbackUrl, mode: LaunchMode.externalApplication);
        } else {
          ErrorHandler.showError(context, 'Impossible d\'ouvrir WhatsApp. Vérifiez que l\'application est installée.');
        }
      }
    } catch (e) {
      debugPrint('Erreur WhatsApp: $e');
      // Essayer avec le navigateur
      try {
        await launchUrl(
          Uri.parse('https://wa.me/$cleanNumber?text=$message'),
          mode: LaunchMode.platformDefault,
        );
      } catch (_) {
        ErrorHandler.showError(context, 'Impossible d\'ouvrir WhatsApp.');
      }
    }
  }

  // CORRECTION: Widget du bouton WhatsApp avec vérification
  Widget _buildWhatsAppButton(String whatsapp, String nom, String matiere) {
    final hasWhatsApp = whatsapp.isNotEmpty && whatsapp.trim() != '';
    
    if (!hasWhatsApp) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: YekiColors.borderMedium,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            'Numéro non disponible',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }
    
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _contacterWhatsAppV2(whatsapp, nom, matiere),
        icon: const Icon(Icons.chat_rounded, size: 18),
        label: const Text('Contacter sur WhatsApp'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF25D366),
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: YekiColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Trouver un répétiteur'),
        backgroundColor: YekiColors.white,
        elevation: 0,
        foregroundColor: YekiColors.textDark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _initialLoading
          ? const Center(
              child: CircularProgressIndicator(color: YekiColors.primaryDark),
            )
          : Column(
              children: [
                _buildFormulaire(),
                _buildMatieresPopulaires(),
                Expanded(
                  child: _loading
                      ? const Center(
                          child: CircularProgressIndicator(color: YekiColors.primaryDark),
                        )
                      : _error != null && _repetiteurs.isEmpty
                          ? _buildErrorState()
                          : _repetiteurs.isEmpty && _selectedMatiere != null
                              ? _buildEmptyState()
                              : _buildResultsList(),
                ),
              ],
            ),
    );
  }

  Widget _buildFormulaire() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: YekiColors.white,
        border: Border(bottom: BorderSide(color: YekiColors.borderLight)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rechercher un répétiteur',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: YekiColors.textDark,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Container(
                  decoration: BoxDecoration(
                    color: YekiColors.backgroundLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    style: const TextStyle(fontSize: 14, color: YekiColors.textDark),
                    decoration: InputDecoration(
                      hintText: 'Matière...',
                      hintStyle: const TextStyle(fontSize: 13, color: YekiColors.textLight),
                      prefixIcon: const Icon(Icons.search_rounded, color: YekiColors.textLight, size: 20),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    ),
                    onSubmitted: _rechercher,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: YekiColors.backgroundLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _niveauCtrl,
                    style: const TextStyle(fontSize: 14, color: YekiColors.textDark),
                    decoration: InputDecoration(
                      hintText: 'Niveau...',
                      hintStyle: const TextStyle(fontSize: 13, color: YekiColors.textLight),
                      prefixIcon: const Icon(Icons.school_rounded, color: YekiColors.textLight, size: 18),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: YekiColors.backgroundLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _villeCtrl,
                    style: const TextStyle(fontSize: 14, color: YekiColors.textDark),
                    decoration: InputDecoration(
                      hintText: 'Ville...',
                      hintStyle: const TextStyle(fontSize: 13, color: YekiColors.textLight),
                      prefixIcon: const Icon(Icons.location_on_rounded, color: YekiColors.textLight, size: 18),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () => _rechercher(_searchCtrl.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: YekiColors.primaryDark,
                  foregroundColor: YekiColors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Rechercher', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          if (_profilCharged && _profil['ville'] != null && _profil['ville'].toString().isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 12, color: YekiColors.textLight),
                const SizedBox(width: 4),
                Text(
                  'Ville pré-remplie depuis votre profil',
                  style: TextStyle(fontSize: 11, color: YekiColors.textLight, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMatieresPopulaires() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Matières populaires',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: YekiColors.textLight,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _matieresPopulaires.map((matiere) {
              final isSelected = _selectedMatiere == matiere;
              return GestureDetector(
                onTap: () {
                  _searchCtrl.text = matiere;
                  _rechercher(matiere);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? YekiColors.primaryDark.withValues(alpha: 0.1)
                        : YekiColors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected 
                          ? YekiColors.primaryDark 
                          : YekiColors.borderLight,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Text(
                    matiere,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? YekiColors.primaryDark : YekiColors.textMedium,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    if (_repetiteurs.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _repetiteurs.length,
      itemBuilder: (context, index) {
        final r = _repetiteurs[index];
        final whatsapp = r['whatsapp'] ?? '';
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: YekiColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: YekiColors.borderLight),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: YekiColors.primaryDark.withValues(alpha: 0.1),
                      backgroundImage: r['avatar'] != null && r['avatar'].toString().isNotEmpty
                          ? NetworkImage(r['avatar'].toString())
                          : null,
                      child: r['avatar'] == null || r['avatar'].toString().isEmpty
                          ? Text(
                              (r['nom'] ?? '?')[0].toUpperCase(),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: YekiColors.primaryDark,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r['nom'] ?? 'Enseignant',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: YekiColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '@${r['username'] ?? ''}',
                            style: TextStyle(
                              fontSize: 12,
                              color: YekiColors.textLight,
                            ),
                          ),
                          if (r['ville'] != null && r['ville'].toString().isNotEmpty)
                            Text(
                              '📍 ${r['ville']}',
                              style: TextStyle(
                                fontSize: 11,
                                color: YekiColors.textLight,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: YekiColors.gold.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: YekiColors.gold.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        '${r['tarif'] ?? 5000} F/mois',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: YekiColors.gold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    _infoChip(Icons.school_rounded, r['matiere'] ?? ''),
                    _infoChip(Icons.check_circle_rounded, 'Disponible', 
                        color: YekiColors.success),
                    if (whatsapp.isNotEmpty)
                      _infoChip(Icons.chat_rounded, 'WhatsApp', 
                        color: const Color(0xFF25D366)),
                  ],
                ),
                const SizedBox(height: 16),
                _buildWhatsAppButton(whatsapp, r['nom'] ?? 'Enseignant', r['matiere'] ?? ''),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _infoChip(IconData icon, String label, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (color ?? YekiColors.primaryDark).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color ?? YekiColors.primaryDark),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color ?? YekiColors.primaryDark,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_search_rounded, size: 64, color: YekiColors.textLight),
          const SizedBox(height: 16),
          Text(
            'Aucun répétiteur trouvé',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: YekiColors.textMedium,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Essayez une autre matière ou vérifiez votre connexion.',
            style: TextStyle(
              fontSize: 13,
              color: YekiColors.textLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded, size: 64, color: YekiColors.error),
          const SizedBox(height: 16),
          Text(_error!, style: TextStyle(fontSize: 14, color: YekiColors.textMedium)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => _rechercher(_searchCtrl.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: YekiColors.primaryDark,
              foregroundColor: YekiColors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
}