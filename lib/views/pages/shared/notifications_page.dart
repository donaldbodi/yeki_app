// lib/views/pages/shared/notifications_page.dart
// ═══════════════════════════════════════════════════════════════════════════
// PAGE NOTIFICATIONS — Avec Firebase et In-App
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yeki/core/theme/app_theme.dart';
import 'package:yeki/core/constants/api_constants.dart';

class NotificationItem {
  final int id;
  final String type;
  final String titre;
  final String contenu;
  bool estLue;
  final DateTime creeLe;
  final String? actionUrl;

  NotificationItem({
    required this.id,
    required this.type,
    required this.titre,
    required this.contenu,
    required this.estLue,
    required this.creeLe,
    this.actionUrl,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> j) => NotificationItem(
    id: j['id'],
    type: j['type'] ?? 'system',
    titre: j['titre'] ?? '',
    contenu: j['contenu'] ?? '',
    estLue: j['est_lue'] ?? false,
    creeLe: DateTime.parse(j['cree_le']),
    actionUrl: j['action_url'],
  );
}

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  bool _loading = true;
  List<NotificationItem> _notifications = [];
  String _filtre = 'Toutes';
  int _nonLues = 0;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<String?> _getToken() async =>
      (await SharedPreferences.getInstance()).getString('token');

  Future<void> _charger() async {
    setState(() => _loading = true);
    final token = await _getToken();
    try {
      final res = await http.get(
        Uri.parse(ApiConstants.notifications),
        headers: ApiHeaders.auth(token),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as List;
        setState(() {
          _notifications = data
              .map((j) => NotificationItem.fromJson(j as Map<String, dynamic>))
              .toList();
          _nonLues = _notifications.where((n) => !n.estLue).length;
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _marquerLue(int id) async {
    final token = await _getToken();
    await http.patch(
      Uri.parse(ApiConstants.notificationLire(id)),
      headers: ApiHeaders.auth(token),
    );
    setState(() {
      final index = _notifications.indexWhere((n) => n.id == id);
      if (index != -1) {
        _notifications[index].estLue = true;
        _nonLues = _notifications.where((n) => !n.estLue).length;
      }
    });
  }

  Future<void> _marquerToutesLues() async {
    final token = await _getToken();
    await http.post(
      Uri.parse(ApiConstants.notificationsToutLire),
      headers: ApiHeaders.auth(token),
    );
    setState(() {
      for (final n in _notifications) {
        n.estLue = true;
      }
      _nonLues = 0;
    });
  }

  List<NotificationItem> get _filtered {
    if (_filtre == 'Non lues') {
      return _notifications.where((n) => !n.estLue).toList();
    }
    return _notifications;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: YekiColors.backgroundLight,
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Notifications',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
            if (_nonLues > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: YekiColors.error,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('$_nonLues',
                    style: const TextStyle(color: YekiColors.white, fontSize: 11, fontWeight: FontWeight.w900)),
              ),
            ],
          ],
        ),
        actions: [
          if (_nonLues > 0)
            TextButton(
              onPressed: _marquerToutesLues,
              child: const Text('Tout lire',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _charger,
          ),
        ],
        backgroundColor: YekiColors.white,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: YekiLoader())
          : _notifications.isEmpty
              ? _buildEmpty()
              : Column(
                  children: [
                    _buildFilters(),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                        itemCount: _filtered.length,
                        itemBuilder: (_, i) => _buildNotifCard(_filtered[i]),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildFilters() {
    final filters = ['Toutes', 'Non lues', 'Devoirs', 'Corrections', 'Olympiades', 'Rappels'];
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((f) {
            final sel = _filtre == f;
            return GestureDetector(
              onTap: () => setState(() => _filtre = f),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: sel ? YekiColors.primaryDark : YekiColors.backgroundLight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: sel ? YekiColors.primaryDark : YekiColors.borderLight),
                ),
                child: Text(f,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: sel ? YekiColors.white : YekiColors.textLight)),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildNotifCard(NotificationItem n) {
    final colors = {
      'devoir': YekiColors.warning,
      'correction': YekiColors.success,
      'olympiade': YekiColors.purple,
      'rappel': YekiColors.accent,
      'classement': YekiColors.gold,
      'forum': YekiColors.primaryDark,
      'system': YekiColors.textLight,
    };
    final icons = {
      'devoir': Icons.assignment_rounded,
      'correction': Icons.fact_check_rounded,
      'olympiade': Icons.emoji_events_rounded,
      'rappel': Icons.access_time_rounded,
      'classement': Icons.leaderboard_rounded,
      'forum': Icons.forum_rounded,
      'system': Icons.notifications_rounded,
    };
    final color = colors[n.type] ?? YekiColors.textLight;
    final icon = icons[n.type] ?? Icons.notifications_rounded;

    return Dismissible(
      key: Key('notif_${n.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: YekiColors.success.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.check_rounded, color: YekiColors.success),
      ),
      onDismissed: (_) => _marquerLue(n.id),
      child: GestureDetector(
        onTap: () {
          if (!n.estLue) _marquerLue(n.id);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: n.estLue ? YekiColors.white : color.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: n.estLue ? YekiColors.borderLight : color.withValues(alpha: 0.2),
            ),
            boxShadow: n.estLue ? [] : [BoxShadow(color: color.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 3))],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            n.titre,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: n.estLue ? FontWeight.w600 : FontWeight.w800,
                            ),
                          ),
                        ),
                        if (!n.estLue)
                          Container(
                            width: 8, height: 8,
                            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      n.contenu,
                      style: const TextStyle(fontSize: 12, height: 1.4),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      DateFormat('dd/MM/yyyy HH:mm').format(n.creeLe),
                      style: const TextStyle(fontSize: 11, color: YekiColors.textLight),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: YekiColors.primaryDark.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.notifications_outlined, size: 52, color: YekiColors.primaryDark.withValues(alpha: 0.4)),
            ),
            const SizedBox(height: 16),
            const Text('Aucune notification',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('Vous êtes à jour !',
                style: const TextStyle(fontSize: 13)),
          ],
        ),
      );
}