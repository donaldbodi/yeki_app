import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

/// Page historique - Enregistrement des activités importantes
class HistoriquePage extends StatefulWidget {
  const HistoriquePage({super.key});

  @override
  State<HistoriquePage> createState() => _HistoriquePageState();
}

class _HistoriquePageState extends State<HistoriquePage> {
  static const String baseUrl = 'https://yeki.pythonanywhere.com';

  final Color primaryColor = const Color(0xFF2884A0);
  final Color bgLight = const Color(0xFFF1F5F9);
  final Color surfaceColor = Colors.white;
  final Color textDark = const Color(0xFF1E293B);

  List<Map<String, dynamic>> _activites = [];
  List<Map<String, dynamic>> _activitesFiltrees = [];
  bool _isLoading = true;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _chargerActivites();
  }

  Future<Map<String, String>> _authHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Token $token',
    };
  }

  Future<void> _chargerActivites() async {
    setState(() => _isLoading = true);
    try {
      final headers = await _authHeaders();
      final res = await http.get(
        Uri.parse('$baseUrl/api/historique/'),
        headers: headers,
      );

      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        setState(() {
          _activites = data
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
          _appliquerFiltres();
        });
      }
    } catch (e) {
      debugPrint('Erreur chargement historique: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _appliquerFiltres() {
    setState(() {
      if (_selectedFilter == 'all') {
        _activitesFiltrees = _activites;
      } else {
        _activitesFiltrees = _activites
            .where((a) => a['action']?.toString().toLowerCase().contains(_selectedFilter) ?? false)
            .toList();
      }
    });
  }

  Map<String, dynamic> _getActionDetails(String action) {
    final details = {
      'course_created': {
        'icon': Icons.add_circle_outline,
        'color': Colors.green,
        'label': 'Cours créé',
      },
      'course_modified': {
        'icon': Icons.edit,
        'color': Colors.blue,
        'label': 'Cours modifié',
      },
      'teacher_assigned': {
        'icon': Icons.person_add,
        'color': Colors.orange,
        'label': 'Enseignant assigné',
      },
      'teacher_removed': {
        'icon': Icons.person_remove,
        'color': Colors.red,
        'label': 'Enseignant retiré',
      },
      'homework_created': {
        'icon': Icons.assignment_turned_in,
        'color': Colors.purple,
        'label': 'Devoir créé',
      },
      'exercise_created': {
        'icon': Icons.quiz,
        'color': Colors.indigo,
        'label': 'Exercice créé',
      },
      'olympiad_created': {
        'icon': Icons.emoji_events,
        'color': Colors.deepOrange,
        'label': 'Olympiade créée',
      },
      'department_created': {
        'icon': Icons.domain_add,
        'color': Colors.teal,
        'label': 'Département créé',
      },
      'cadre_assigned': {
        'icon': Icons.supervisor_account,
        'color': Colors.cyan,
        'label': 'Cadre assigné',
      },
      'login': {
        'icon': Icons.login,
        'color': Colors.lightBlue,
        'label': 'Connexion',
      },
      'logout': {
        'icon': Icons.logout,
        'color': Colors.lightBlue,
        'label': 'Déconnexion',
      },
    };

    return details[action] ?? {
      'icon': Icons.history,
      'color': Colors.grey,
      'label': action.replaceAll('_', ' ').toUpperCase(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        title: const Text('Historique des activités'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _chargerActivites,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildFilterBar(),
                Expanded(
                  child: _activitesFiltrees.isEmpty
                      ? _buildEmptyState()
                      : _buildActivityList(),
                ),
              ],
            ),
    );
  }

  Widget _buildFilterBar() {
    final filters = [
      ('all', 'Tous'),
      ('course', 'Cours'),
      ('teacher', 'Enseignants'),
      ('homework', 'Devoirs'),
      ('exercise', 'Exercices'),
      ('olympiad', 'Olympiades'),
      ('department', 'Départements'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: filters.map((filter) {
          final isSelected = _selectedFilter == filter.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(filter.$2),
              selected: isSelected,
              onSelected: (_) {
                setState(() => _selectedFilter = filter.$1);
                _appliquerFiltres();
              },
              backgroundColor: Colors.white,
              selectedColor: primaryColor.withOpacity(0.2),
              side: BorderSide(
                color: isSelected ? primaryColor : Colors.grey[300]!,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActivityList() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _activitesFiltrees.length,
      itemBuilder: (context, index) {
        final activite = _activitesFiltrees[index];
        return _buildActivityCard(activite, index);
      },
    );
  }

  Widget _buildActivityCard(Map<String, dynamic> activite, int index) {
    final action = activite['action']?.toString() ?? 'action_inconnue';
    final actionDetails = _getActionDetails(action);
    final timestamp = activite['timestamp'];
    final description = activite['description'] ?? '';
    final data = activite['data'] as Map<String, dynamic>? ?? {};

    DateTime? parsedTime;
    try {
      if (timestamp != null) {
        parsedTime = DateTime.parse(timestamp.toString());
      }
    } catch (_) {}

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (actionDetails['color'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    actionDetails['icon'] as IconData,
                    color: actionDetails['color'] as Color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        actionDetails['label'] as String,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: textDark,
                        ),
                      ),
                      if (parsedTime != null)
                        Text(
                          _formatDateTime(parsedTime),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Description
          if (description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

          // Détails si disponibles
          if (data.isNotEmpty) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: _buildDataSummary(data),
            ),
          ],

          // Bouton expansion si plus de détails
          if (data.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8),
              child: ExpansionTile(
                title: const Text('Détails',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: _buildDetailedData(data),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDataSummary(Map<String, dynamic> data) {
    final items = <Widget>[];

    if (data['titre'] != null) {
      items.add(
        _dataChip('Titre', data['titre'].toString()),
      );
    }
    if (data['nom'] != null) {
      items.add(
        _dataChip('Nom', data['nom'].toString()),
      );
    }
    if (data['enseignant'] != null) {
      items.add(
        _dataChip('Enseignant', data['enseignant'].toString()),
      );
    }
    if (data['departement'] != null) {
      items.add(
        _dataChip('Département', data['departement'].toString()),
      );
    }

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: items.take(3).toList(),
    );
  }

  Widget _dataChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: primaryColor.withOpacity(0.3)),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontSize: 10,
          color: primaryColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildDetailedData(Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: data.entries
          .map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 100,
                      child: Text(
                        '${e.key}:',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        e.value.toString(),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Aucune activité',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Vous verrez ici vos actions importantes',
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inMinutes < 60) {
      return 'Il y a ${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return 'Il y a ${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays}j';
    } else {
      return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
    }
  }
}

/// Modèle pour les activités
class HistoriqueAction {
  final int id;
  final int userId;
  final String action;
  final String description;
  final DateTime timestamp;
  final Map<String, dynamic>? data;

  HistoriqueAction({
    required this.id,
    required this.userId,
    required this.action,
    required this.description,
    required this.timestamp,
    this.data,
  });

  factory HistoriqueAction.fromJson(Map<String, dynamic> json) {
    return HistoriqueAction(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      action: json['action'] ?? '',
      description: json['description'] ?? '',
      timestamp: DateTime.parse(json['timestamp'].toString()),
      data: json['data'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'action': action,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'data': data,
    };
  }
}
