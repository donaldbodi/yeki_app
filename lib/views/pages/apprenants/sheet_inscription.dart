// lib/views/pages/apprenants/sheet_inscription.dart
// ═══════════════════════════════════════════════════════════════════════════
//  SHEET D'INSCRIPTION OLYMPIADE — CORRIGÉ AVEC DESIGN SYSTEM
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:yeki/core/theme/app_theme.dart';
import 'package:yeki/core/constants/api_constants.dart';

// ═══════════════════════════════════════════════════════════════════════════
// SHEET INSCRIPTION EN BAS DE PAGE
// ═══════════════════════════════════════════════════════════════════════════
class InscriptionSheet extends StatefulWidget {
  final int olympiadeId;
  final String titre;
  final String reglement;
  final String prixDesc;
  final DateTime? datDebut;
  final DateTime? datFin;
  final VoidCallback onSuccess;

  const InscriptionSheet({
    super.key,
    required this.olympiadeId,
    required this.titre,
    this.reglement = '',
    this.prixDesc = '',
    this.datDebut,
    this.datFin,
    required this.onSuccess,
  });

  @override
  State<InscriptionSheet> createState() => _InscriptionSheetState();
}

class _InscriptionSheetState extends State<InscriptionSheet> {
  bool _accepte = false;
  bool _loading = false;

  Future<String?> _token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> _inscrire() async {
    if (!_accepte) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Acceptez d\'abord le règlement.'),
          backgroundColor: YekiColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _loading = true);
    final token = await _token();

    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/olympiades/${widget.olympiadeId}/inscrire/'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Token $token',
        },
        body: jsonEncode({'accepte_reglement': true}),
      );

      setState(() => _loading = false);

      if (response.statusCode == 201 || response.statusCode == 409) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                response.statusCode == 201
                    ? 'Inscription confirmée ! Bonne chance.'
                    : 'Vous êtes déjà inscrit à cette olympiade.',
              ),
              backgroundColor: response.statusCode == 201 ? YekiColors.success : YekiColors.warning,
              behavior: SnackBarBehavior.floating,
            ),
          );
          widget.onSuccess();
          Navigator.pop(context);
        }
      } else {
        final errorData = jsonDecode(response.body);
        final message = errorData['detail'] ?? errorData['message'] ?? 'Erreur lors de l\'inscription.';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: YekiColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur de connexion. Veuillez réessayer.'),
            backgroundColor: YekiColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormatter = DateFormat('dd/MM/yyyy à HH:mm', 'fr_FR');

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: YekiColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle (poignée de fermeture)
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: YekiColors.borderLight,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: YekiColors.purple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.military_tech_rounded,
                    color: YekiColors.purple,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.titre,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: YekiColors.textDark,
                        ),
                      ),
                      const Text(
                        'Inscription olympiade',
                        style: TextStyle(
                          color: YekiColors.textLight,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Dates
            if (widget.datDebut != null)
              _infoRow(
                Icons.play_circle_outline_rounded,
                'Début compétition',
                dateFormatter.format(widget.datDebut!),
              ),
            if (widget.datFin != null)
              _infoRow(
                Icons.stop_circle_outlined,
                'Fin compétition',
                dateFormatter.format(widget.datFin!),
              ),

            // Prix / Récompenses
            if (widget.prixDesc.isNotEmpty) ...[
              const SizedBox(height: 16),
              _sectionTitle('Récompenses', Icons.stars_rounded),
              const SizedBox(height: 8),
              Text(
                widget.prixDesc,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: YekiColors.textMedium,
                  height: 1.5,
                ),
              ),
            ],

            // Règlement
            if (widget.reglement.isNotEmpty) ...[
              const SizedBox(height: 16),
              _sectionTitle('Règlement', Icons.gavel_rounded),
              const SizedBox(height: 8),
              Text(
                widget.reglement,
                style: const TextStyle(
                  fontSize: 13,
                  color: YekiColors.textMedium,
                  height: 1.5,
                ),
              ),
            ],

            // Anti-triche
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: YekiColors.warning.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: YekiColors.warning.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.security_rounded,
                        color: YekiColors.warning,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Règles anti-triche',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: YekiColors.warning,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...[
                    'Minuteur strict — soumission automatique à expiration',
                    'Questions mélangées aléatoirement',
                    'Navigation question par question sans retour arrière',
                    'Toute sortie de l\'app est détectée et pénalisée',
                  ].map(
                    (text) => Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: YekiColors.warning,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              text,
                              style: TextStyle(
                                fontSize: 12,
                                color: YekiColors.warning.withValues(alpha: 0.8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Checkbox d'acceptation
            GestureDetector(
              onTap: () => setState(() => _accepte = !_accepte),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _accepte ? YekiColors.purple.withValues(alpha: 0.05) : YekiColors.backgroundLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _accepte ? YekiColors.purple : YekiColors.borderLight,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: _accepte ? YekiColors.purple : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: _accepte ? YekiColors.purple : YekiColors.borderMedium,
                          width: 2,
                        ),
                      ),
                      child: _accepte
                          ? const Icon(
                              Icons.check_rounded,
                              color: YekiColors.white,
                              size: 14,
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'J\'ai lu et j\'accepte le règlement et les règles anti-triche',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: YekiColors.textDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Bouton de confirmation
            GestureDetector(
              onTap: _loading ? null : _inscrire,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(
                  color: _accepte ? YekiColors.purple : YekiColors.borderMedium,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: _accepte
                      ? [
                          BoxShadow(
                            color: YekiColors.purple.withValues(alpha: 0.35),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ]
                      : [],
                ),
                child: _loading
                    ? const Center(
                        child: YekiLoader(color: YekiColors.white, size: 24),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.military_tech_rounded,
                            color: _accepte ? YekiColors.gold : YekiColors.white.withValues(alpha: 0.5),
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Confirmer mon inscription',
                            style: TextStyle(
                              color: _accepte ? YekiColors.white : YekiColors.white.withValues(alpha: 0.5),
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 15, color: YekiColors.purple),
          const SizedBox(width: 8),
          Text(
            '$label : ',
            style: const TextStyle(
              fontSize: 12,
              color: YekiColors.textLight,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12.5,
              color: YekiColors.textDark,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 15, color: YekiColors.purple),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: YekiColors.textDark,
          ),
        ),
      ],
    );
  }
}