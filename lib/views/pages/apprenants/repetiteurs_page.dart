// lib/views/pages/apprenants/repetiteurs_page.dart
// ═══════════════════════════════════════════════════════════════════════════
//  PAGE RECHERCHE RÉPÉTITEURS PAR MATIÈRE (WHATSAPP)
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yeki/core/theme/app_theme.dart';
import 'package:yeki/core/constants/api_constants.dart';

class RepetiteursPage extends StatefulWidget {
  const RepetiteursPage({super.key});

  @override
  State<RepetiteursPage> createState() => _RepetiteursPageState();
}

class _RepetiteursPageState extends State<RepetiteursPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _repetiteurs = [];
  bool _loading = false;
  String? _selectedMatiere;
  String? _error;

  final List<String> _matieresPopulaires = [
    'Mathématiques', 'Physique', 'Chimie', 'SVT', 
    'Informatique', 'Français', 'Anglais', 'Histoire-Géo'
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> _rechercher(String matiere) async {
    if (matiere.trim().isEmpty) return;

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
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/repetiteurs/search/?matiere=${Uri.encodeComponent(matiere)}'),
        headers: ApiHeaders.auth(token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _repetiteurs = List<Map<String, dynamic>>.from(data['repetiteurs'] ?? []);
          _loading = false;
        });
        if (_repetiteurs.isEmpty) {
          _showError('Aucun répétiteur trouvé pour "$matiere"');
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

  Future<void> _contacterWhatsApp(String numero, String nom, String matiere) async {
    // Nettoyer le numéro
    String cleanNumber = numero.replaceAll(RegExp(r'[^0-9+]'), '');
    if (!cleanNumber.startsWith('+237') && cleanNumber.startsWith('6')) {
      cleanNumber = '+237$cleanNumber';
    }
    
    final message = Uri.encodeComponent(
      'Bonjour $nom,\n\n'
      'Je souhaite prendre des cours particuliers en $matiere avec vous via Yéki.\n'
      'Tarif : 5000 FCFA/mois.\n\n'
      'Pouvez-vous me donner plus d\'informations ?\n\n'
      'Cordialement.'
    );
    
    final url = Uri.parse('https://wa.me/$cleanNumber?text=$message');
    
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        _showError('Impossible d\'ouvrir WhatsApp');
      }
    } catch (e) {
      _showError('Erreur: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: YekiColors.white)),
        backgroundColor: YekiColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: YekiColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Rechercher un répétiteur'),
        backgroundColor: YekiColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildMatieresPopulaires(),
          Expanded(
            child: _loading
                ? const Center(child: YekiLoader())
                : _error != null
                    ? _buildErrorState()
                    : _repetiteurs.isEmpty && _selectedMatiere != null
                        ? _buildEmptyState()
                        : _buildResultsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: YekiSpacing.paddingLg,
      decoration: BoxDecoration(
        color: YekiColors.white,
        border: Border(bottom: BorderSide(color: YekiColors.borderLight)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: YekiColors.backgroundAlt,
                borderRadius: YekiRadius.borderRadiusMd,
              ),
              child: TextField(
                controller: _searchCtrl,
                style: YekiTextStyles.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'Rechercher par matière...',
                  hintStyle: YekiTextStyles.bodySmall,
                  prefixIcon: const Icon(Icons.search_rounded, color: YekiColors.textLight),
                  border: InputBorder.none,
                  contentPadding: YekiSpacing.paddingLg,
                ),
                onSubmitted: _rechercher,
              ),
            ),
          ),
          const SizedBox(width: 12),
          YekiButton(
            label: 'Rechercher',
            onPressed: () => _rechercher(_searchCtrl.text),
            width: 100,
            height: 48,
          ),
        ],
      ),
    );
  }

  Widget _buildMatieresPopulaires() {
    return Container(
      padding: YekiSpacing.paddingLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Matières populaires',
            style: YekiTextStyles.labelMedium.copyWith(
              color: YekiColors.textLight,
            ),
          ),
          const SizedBox(height: 12),
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
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? YekiColors.primaryDark.withValues(alpha: 0.1)
                        : YekiColors.white,
                    borderRadius: YekiRadius.borderRadiusPill,
                    border: Border.all(
                      color: isSelected 
                          ? YekiColors.primaryDark 
                          : YekiColors.borderLight,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Text(
                    matiere,
                    style: YekiTextStyles.labelSmall.copyWith(
                      color: isSelected ? YekiColors.primaryDark : YekiColors.textMedium,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
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
    if (_repetiteurs.isEmpty) return const SizedBox.shrink();
    
    return ListView.builder(
      padding: YekiSpacing.paddingLg,
      itemCount: _repetiteurs.length,
      itemBuilder: (context, index) {
        final r = _repetiteurs[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: YekiColors.white,
            borderRadius: YekiRadius.borderRadiusLg,
            border: Border.all(color: YekiColors.borderLight),
          ),
          child: Padding(
            padding: YekiSpacing.paddingLg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: YekiColors.primaryDark.withValues(alpha: 0.1),
                      backgroundImage: r['avatar'] != null 
                          ? NetworkImage(r['avatar']) 
                          : null,
                      child: r['avatar'] == null
                          ? Text(
                              r['nom'][0].toUpperCase(),
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
                            r['nom'],
                            style: YekiTextStyles.h5,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '@${r['username']}',
                            style: YekiTextStyles.caption,
                          ),
                        ],
                      ),
                    ),
                    YekiBadge(
                      label: '${r['tarif']} F/mois',
                      color: YekiColors.gold,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _infoChip(Icons.school_rounded, r['matiere']),
                    const SizedBox(width: 8),
                    _infoChip(Icons.check_circle_rounded, 'Disponible', 
                        color: YekiColors.success),
                  ],
                ),
                const SizedBox(height: 16),
                YekiButton(
                  label: 'Contacter sur WhatsApp',
                  icon: Icons.chat_rounded,
                  backgroundColor: const Color(0xFF25D366),
                  onPressed: () => _contacterWhatsApp(
                    r['whatsapp'], 
                    r['nom'], 
                    r['matiere'],
                  ),
                ),
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
        borderRadius: YekiRadius.borderRadiusSm,
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
            style: YekiTextStyles.h5.copyWith(color: YekiColors.textMedium),
          ),
          const SizedBox(height: 8),
          Text(
            'Essayez une autre matière ou vérifiez votre connexion.',
            style: YekiTextStyles.bodySmall,
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
          Text(_error!, style: YekiTextStyles.bodyMedium),
          const SizedBox(height: 20),
          YekiButton(
            label: 'Réessayer',
            onPressed: () => _rechercher(_searchCtrl.text),
            width: 160,
          ),
        ],
      ),
    );
  }
}