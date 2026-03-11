import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Page de profil unifiée pour apprenant ET enseignant
class ProfilPage extends StatefulWidget {
  const ProfilPage({super.key});

  @override
  State<ProfilPage> createState() => _ProfilPageState();
}

class _ProfilPageState extends State<ProfilPage> {
  static const String _base = 'https://yekiapp.pythonanywhere.com/api';

  final Color primaryColor = const Color(0xFF2884A0);
  final Color goldAccent = const Color(0xFFD4AF37);
  final Color backgroundColor = const Color(0xFFF8FAFB);
  final Color darkBlue = const Color(0xFF1A1C1E);

  bool _loading = true;
  Map<String, dynamic> _profil = {};
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<String?> _token() async {
    final p = await SharedPreferences.getInstance();
    return p.getString('token');
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    await Future.wait([_fetchProfil(), _fetchStats()]);
    setState(() => _loading = false);
  }

  Future<void> _fetchProfil() async {
    final token = await _token();
    if (token == null) return;
    try {
      final res = await http.get(
        Uri.parse('$_base/profil/me/'),
        headers: {'Authorization': 'Token $token'},
      );
      if (res.statusCode == 200) {
        setState(() => _profil = jsonDecode(res.body));
      }
    } catch (_) {}
  }

  Future<void> _fetchStats() async {
    final token = await _token();
    if (token == null) return;
    try {
      final res = await http.get(
        Uri.parse('$_base/profil/stats/'),
        headers: {'Authorization': 'Token $token'},
      );
      if (res.statusCode == 200) {
        setState(() => _stats = jsonDecode(res.body));
      }
    } catch (_) {}
  }

  bool _isEnseignant() {
    final role = _profil['role']?.toString().toLowerCase() ?? '';
    return role.contains('enseignant') || 
           role.contains('admin') || 
           role.contains('cadre') || 
           role.contains('principal') ||
           role.contains('secondaire');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                _buildAppBar(),
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      _buildProfileSection(),
                      const SizedBox(height: 24),
                      _isEnseignant()
                          ? _buildEnseignantStats()
                          : _buildApprenantStats(),
                      const SizedBox(height: 24),
                      _buildActionButtons(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      backgroundColor: primaryColor,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryColor, primaryColor.withOpacity(0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  child: Text(
                    (_profil['user']?['username']?[0] ?? '?')
                        .toUpperCase(),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _profil['user']?['username'] ?? 'Utilisateur',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow('Email', _profil['user']?['email'] ?? 'N/A'),
          const SizedBox(height: 12),
          if (_profil['phone'] != null)
            _buildInfoRow('Téléphone', _profil['phone']),
          const SizedBox(height: 12),
          if (_isEnseignant()) ...[
            _buildInfoRow(
              'Type',
              _profil['type_enseignant']?.toString().toUpperCase() ?? 'Enseignant',
            ),
            const SizedBox(height: 12),
            if (_profil['specialite'] != null)
              _buildInfoRow('Spécialité', _profil['specialite']),
            const SizedBox(height: 12),
            if (_profil['departement'] != null)
              _buildInfoRow('Département', _profil['departement']),
            const SizedBox(height: 12),
            if (_profil['parcours'] != null)
              _buildInfoRow('Parcours', _profil['parcours']),
          ] else ...[
            _buildInfoRow(
              'Niveau',
              _profil['niveau_etudes']?.toString() ?? 'N/A',
            ),
            const SizedBox(height: 12),
            if (_profil['classe'] != null)
              _buildInfoRow('Classe', _profil['classe']),
            const SizedBox(height: 12),
            if (_profil['date_inscription'] != null)
              _buildInfoRow(
                'Inscrit depuis',
                _formatDate(_profil['date_inscription']),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1C1E),
          ),
        ),
      ],
    );
  }

  Widget _buildEnseignantStats() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Statistiques',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _statCard(
                  icon: Icons.school_outlined,
                  label: 'Cours',
                  value: '${_stats['total_courses'] ?? 0}',
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statCard(
                  icon: Icons.people_outline,
                  label: 'Élèves',
                  value: '${_stats['total_students'] ?? 0}',
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statCard(
                  icon: Icons.trending_up,
                  label: 'Moyenne',
                  value: '${(_stats['average_grade'] as num?)?.toStringAsFixed(1) ?? 'N/A'}/20',
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          if (_stats['courses'] != null) ...[
            const SizedBox(height: 20),
            const Text(
              'Cours assignés',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ...((_stats['courses'] as List?) ?? [])
                .take(5)
                .map((course) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            height: 20,
                            decoration: BoxDecoration(
                              color: primaryColor,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              course['titre'] ?? 'Cours',
                              style: const TextStyle(fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ))
                .toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildApprenantStats() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Progression',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _statCard(
                  icon: Icons.assignment_turned_in,
                  label: 'Devoirs',
                  value: '${_stats['homework_submitted'] ?? 0}/${_stats['total_homework'] ?? 0}',
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statCard(
                  icon: Icons.quiz,
                  label: 'Exercices',
                  value: '${_stats['exercises_done'] ?? 0}/${_stats['total_exercises'] ?? 0}',
                  color: Colors.purple,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statCard(
                  icon: Icons.stars,
                  label: 'Moyenne',
                  value: '${(_stats['average_grade'] as num?)?.toStringAsFixed(1) ?? 'N/A'}/20',
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          if (_stats['formations'] != null) ...[
            const SizedBox(height: 20),
            const Text(
              'Formations suivies',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ...((_stats['formations'] as List?) ?? [])
                .take(3)
                .map((formation) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            height: 20,
                            decoration: BoxDecoration(
                              color: primaryColor,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              formation['titre'] ?? 'Formation',
                              style: const TextStyle(fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ))
                .toList(),
          ],
        ],
      ),
    );
  }

  Widget _statCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: _actionButton(
                  icon: Icons.edit,
                  label: 'Éditer',
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Navigation vers édition')),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _actionButton(
                  icon: Icons.settings,
                  label: 'Paramètres',
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Navigation vers paramètres')),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: _actionButton(
            icon: Icons.logout,
            label: 'Se déconnecter',
            color: Colors.red,
            onPressed: () {
              _handleLogout();
            },
          ),
        ),
      ],
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    Color color = Colors.white,
    Color textColor = Colors.white,
  }) {
    return ElevatedButton.icon(
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: textColor,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: onPressed,
    );
  }

  Future<void> _handleLogout() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
      }
    }
  }

  String _formatDate(String? date) {
    if (date == null) return 'N/A';
    try {
      final parsed = DateTime.parse(date);
      return '${parsed.day}/${parsed.month}/${parsed.year}';
    } catch (_) {
      return date;
    }
  }
}
