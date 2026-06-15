// lib/views/pages/apprenants/classement_departement_page.dart
// ═══════════════════════════════════════════════════════════════════════════
//  PAGE CLASSEMENT PAR DÉPARTEMENT
//  Affiche le classement des apprenants avec scores et badges
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yeki/core/theme/app_theme.dart';

class ClassementDepartementPage extends StatefulWidget {
  final int departementId;
  final String departementNom;

  const ClassementDepartementPage({
    super.key,
    required this.departementId,
    required this.departementNom,
  });

  @override
  State<ClassementDepartementPage> createState() =>
      _ClassementDepartementPageState();
}

class _ClassementDepartementPageState
    extends State<ClassementDepartementPage> {
  bool _loading = true;
  List<Map<String, dynamic>> _classement = [];
  Map<String, dynamic>? _monRang;
  Map<String, dynamic>? _stats;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _chargerClassement();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> _chargerClassement() async {
    setState(() {
      _loading = true;
      _error = '';
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
        Uri.parse(
            'https://yeki.pythonanywhere.com/api/classement/departement/${widget.departementId}/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _classement = List<Map<String, dynamic>>.from(data['classement'] ?? []);
          _monRang = data['mon_rang'];
          _stats = data['stats'];
          _loading = false;
        });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: YekiColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Classement · ${widget.departementNom}',
          style: YekiTextStyles.h6,
        ),
        backgroundColor: YekiColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20),
            onPressed: _chargerClassement,
          ),
        ],
      ),
      body: _loading
          ? _buildSkeleton()
          : _error.isNotEmpty
              ? _buildErrorState()
              : RefreshIndicator(
                  onRefresh: _chargerClassement,
                  color: YekiColors.primaryDark,
                  child: CustomScrollView(
                    slivers: [
                      if (_stats != null) _buildStatsHeader(),
                      if (_monRang != null) _buildMonRangCard(),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: YekiSpacing.paddingLg,
                          child: Row(
                            children: [
                              Text(
                                'Classement complet',
                                style: YekiTextStyles.h5,
                              ),
                              const Spacer(),
                              Container(
                                padding: YekiSpacing.paddingXs,
                                decoration: BoxDecoration(
                                  color: YekiColors.primaryDark
                                      .withValues(alpha: 0.1),
                                  borderRadius: YekiRadius.borderRadiusSm,
                                ),
                                child: Text(
                                  '${_classement.length} apprenants',
                                  style: YekiTextStyles.labelSmall.copyWith(
                                    color: YekiColors.primaryDark,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) =>
                              _buildClassementTile(_classement[index], index),
                          childCount: _classement.length,
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 40)),
                    ],
                  ),
                ),
    );
  }

  Widget _buildStatsHeader() {
    final stats = _stats!;
    return SliverToBoxAdapter(
      child: Container(
        margin: YekiSpacing.paddingLg,
        padding: YekiSpacing.paddingLg,
        decoration: BoxDecoration(
          gradient: YekiColors.primaryGradient,
          borderRadius: YekiRadius.borderRadiusLg,
        ),
        child: Row(
          children: [
            Expanded(
              child: _statItem(
                '${stats['total']}',
                'Participants',
                Icons.people_rounded,
              ),
            ),
            Container(
              width: 1,
              height: 40,
              color: YekiColors.white.withValues(alpha: 0.2),
            ),
            Expanded(
              child: _statItem(
                '${stats['moyenne'].toStringAsFixed(0)}',
                'Moyenne',
                Icons.star_rounded,
              ),
            ),
            Container(
              width: 1,
              height: 40,
              color: YekiColors.white.withValues(alpha: 0.2),
            ),
            Expanded(
              child: _statItem(
                '${stats['meilleur'].toStringAsFixed(0)}',
                'Meilleur score',
                Icons.emoji_events_rounded,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: YekiColors.white, size: 20),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: YekiColors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: YekiColors.white.withValues(alpha: 0.7),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildMonRangCard() {
    final rang = _monRang!;
    final isTop3 = rang['rang'] <= 3;
    final medal = isTop3
        ? _getMedalIcon(rang['rang'])
        : Icons.leaderboard_rounded;

    return SliverToBoxAdapter(
      child: Container(
        margin: YekiSpacing.paddingLg,
        padding: YekiSpacing.paddingLg,
        decoration: BoxDecoration(
          color: isTop3 ? YekiColors.gold.withValues(alpha: 0.1) : YekiColors.white,
          borderRadius: YekiRadius.borderRadiusLg,
          border: Border.all(
            color: isTop3 ? YekiColors.gold.withValues(alpha: 0.3) : YekiColors.borderLight,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isTop3 ? YekiColors.gold : YekiColors.primaryDark,
                shape: BoxShape.circle,
              ),
              child: Icon(
                medal,
                color: YekiColors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Votre position',
                    style: YekiTextStyles.caption,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '#${rang['rang']}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isTop3 ? YekiColors.gold : YekiColors.primaryDark,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '• ${rang['score'].toStringAsFixed(0)} pts',
                        style: YekiTextStyles.bodyMedium,
                      ),
                      if (rang['progression'] != 0) ...[
                        const SizedBox(width: 8),
                        _buildProgressionBadge(rang['progression']),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressionBadge(double progression) {
    final isPositive = progression > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isPositive
            ? YekiColors.success.withValues(alpha: 0.1)
            : YekiColors.error.withValues(alpha: 0.1),
        borderRadius: YekiRadius.borderRadiusSm,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
            size: 12,
            color: isPositive ? YekiColors.success : YekiColors.error,
          ),
          const SizedBox(width: 2),
          Text(
            '${progression.abs().toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isPositive ? YekiColors.success : YekiColors.error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassementTile(Map<String, dynamic> item, int index) {
    final rang = item['rang'];
    final isTop3 = rang <= 3;
    final medal = isTop3 ? _getMedalIcon(rang) : null;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      decoration: BoxDecoration(
        color: YekiColors.white,
        borderRadius: YekiRadius.borderRadiusLg,
        border: Border.all(color: YekiColors.borderLight),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isTop3
                ? _getMedalColor(rang).withValues(alpha: 0.1)
                : YekiColors.backgroundAlt,
            borderRadius: YekiRadius.borderRadiusMd,
          ),
          child: Center(
            child: medal != null
                ? Icon(medal, color: _getMedalColor(rang), size: 24)
                : Text(
                    '$rang',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: YekiColors.textMedium,
                    ),
                  ),
          ),
        ),
        title: Text(
          item['nom'],
          style: YekiTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '@${item['username']}',
          style: YekiTextStyles.caption,
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${item['score'].toStringAsFixed(0)} pts',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: YekiColors.primaryDark,
              ),
            ),
            if (item['progression'] != 0)
              _buildProgressionBadge(item['progression']),
          ],
        ),
      ),
    );
  }

  IconData _getMedalIcon(int rang) {
    switch (rang) {
      case 1:
        return Icons.emoji_events_rounded;
      case 2:
        return Icons.emoji_events_rounded;
      case 3:
        return Icons.emoji_events_rounded;
      default:
        return Icons.leaderboard_rounded;
    }
  }

  Color _getMedalColor(int rang) {
    switch (rang) {
      case 1:
        return const Color(0xFFFFD700); // Or
      case 2:
        return const Color(0xFFC0C0C0); // Argent
      case 3:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return YekiColors.primaryDark;
    }
  }

  Widget _buildSkeleton() {
    return ListView.builder(
      padding: YekiSpacing.paddingLg,
      itemCount: 8,
      itemBuilder: (_, _) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        height: 70,
        decoration: BoxDecoration(
          color: YekiColors.borderLight,
          borderRadius: YekiRadius.borderRadiusLg,
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded, size: 48, color: YekiColors.textLight),
          const SizedBox(height: 16),
          Text(_error, style: YekiTextStyles.bodyMedium),
          const SizedBox(height: 20),
          YekiButton(
            label: 'Réessayer',
            onPressed: _chargerClassement,
            width: 160,
          ),
        ],
      ),
    );
  }
}