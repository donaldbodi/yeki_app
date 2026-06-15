// lib/views/pages/apprenants/olympiade_inscription_page.dart
// ═══════════════════════════════════════════════════════════════════════════
//  PAGE D'INSCRIPTION OLYMPIADE — CORRIGÉE AVEC DESIGN SYSTEM
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:yeki/core/theme/app_theme.dart';
import 'package:yeki/core/constants/api_constants.dart';
import 'package:yeki/utils/error_handler.dart';

class OlympiadeInscriptionPage extends StatefulWidget {
  final int olympiadeId;
  final String titre;
  final String reglement;
  final String prixDesc;
  final DateTime datDebut;
  final DateTime datFin;

  const OlympiadeInscriptionPage({
    super.key,
    required this.olympiadeId,
    required this.titre,
    required this.reglement,
    required this.prixDesc,
    required this.datDebut,
    required this.datFin,
  });

  @override
  State<OlympiadeInscriptionPage> createState() => _OlympiadeInscriptionPageState();
}

class _OlympiadeInscriptionPageState extends State<OlympiadeInscriptionPage> {
  bool _accepte = false;
  bool _loading = false;

  Future<String?> _token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> _inscrire() async {
    if (!_accepte) {
      ErrorHandler.showWarning(context, 'Vous devez accepter le règlement.');
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

      if (!mounted) return;
      setState(() => _loading = false);

      if (response.statusCode == 201) {
        ErrorHandler.showSuccess(context, 'Inscription confirmée ! Bonne chance.');
        Navigator.pop(context, true);
      } else if (response.statusCode == 409) {
        ErrorHandler.showWarning(context, 'Vous êtes déjà inscrit à cette olympiade.');
        Navigator.pop(context, true);
      } else {
        final errorData = jsonDecode(response.body);
        final message = errorData['detail'] ?? errorData['message'] ?? 'Erreur lors de l\'inscription.';
        ErrorHandler.showError(context, message);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ErrorHandler.showError(context, 'Erreur de connexion: ${e.toString()}');
      }
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy à HH:mm', 'fr_FR').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: YekiColors.backgroundLight,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Hero header
          SliverAppBar(
            expandedHeight: 210,
            pinned: true,
            backgroundColor: YekiColors.purple,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded, color: YekiColors.white, size: 18),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [YekiColors.purple, YekiColors.purple.withValues(alpha: 0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: YekiColors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.emoji_events_rounded, color: YekiColors.gold, size: 40),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'OLYMPIADE',
                      style: TextStyle(
                        color: YekiColors.white.withValues(alpha: 0.7),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        widget.titre,
                        style: const TextStyle(
                          color: YekiColors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Calendrier
                _section('Calendrier', Icons.calendar_month_rounded, [
                  _dateRow('Début compétition', widget.datDebut),
                  _dateRow('Fin compétition', widget.datFin),
                ]),
                const SizedBox(height: 16),

                // Prix / Récompenses
                if (widget.prixDesc.isNotEmpty) ...[
                  _section('Récompenses', Icons.stars_rounded, [
                    Text(
                      widget.prixDesc,
                      style: const TextStyle(fontSize: 13.5, height: 1.6, color: YekiColors.textMedium),
                    ),
                  ]),
                  const SizedBox(height: 16),
                ],

                // Règlement
                if (widget.reglement.isNotEmpty) ...[
                  _section('Règlement', Icons.gavel_rounded, [
                    Text(
                      widget.reglement,
                      style: const TextStyle(fontSize: 13.5, height: 1.6, color: YekiColors.textMedium),
                    ),
                  ]),
                  const SizedBox(height: 16),
                ],

                // Anti-triche
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: YekiColors.warning.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: YekiColors.warning.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.security_rounded, color: YekiColors.warning, size: 17),
                          const SizedBox(width: 8),
                          const Text(
                            'Règles anti-triche',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: YekiColors.warning,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...[
                        'Minuteur strict — soumission automatique à expiration',
                        'Questions mélangées (ordre différent par participant)',
                        'Navigation question par question sans retour arrière',
                        'Toute sortie de l\'application est détectée et pénalisée',
                        'IP et heure de soumission enregistrées',
                      ].map((text) => Padding(
                        padding: const EdgeInsets.only(top: 5),
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
                      )),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Checkbox règlement
                GestureDetector(
                  onTap: () => setState(() => _accepte = !_accepte),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _accepte ? YekiColors.purple.withValues(alpha: 0.05) : YekiColors.white,
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
                              ? const Icon(Icons.check_rounded, color: YekiColors.white, size: 14)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'J\'ai lu et j\'accepte le règlement de cette olympiade ainsi que les règles anti-triche',
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

                // Bouton inscription
                GestureDetector(
                  onTap: _loading ? null : _inscrire,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: _accepte ? YekiColors.purple : YekiColors.borderMedium,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: _accepte
                          ? [BoxShadow(
                              color: YekiColors.purple.withValues(alpha: 0.35),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            )]
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
                                Icons.emoji_events_rounded,
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
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String titre, IconData icon, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: YekiColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: YekiShadows.subtle,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: YekiColors.purple),
              const SizedBox(width: 8),
              Text(
                titre,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: YekiColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _dateRow(String label, DateTime date) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: YekiColors.textLight,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: YekiColors.purple.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _formatDate(date),
              style: const TextStyle(
                fontSize: 11.5,
                color: YekiColors.purple,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}