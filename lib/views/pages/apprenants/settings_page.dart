// lib/views/pages/apprenants/settings_page.dart
// ═══════════════════════════════════════════════════════════════════════════
// PAGE PARAMÈTRES — CORRIGÉE
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yeki/main.dart';
import 'package:yeki/core/theme/app_theme.dart';
import 'package:yeki/core/constants/api_constants.dart';
import 'package:yeki/utils/error_handler.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notifEnabled = true;
  bool _biometry = false;
  final String _lang = 'Français';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notifEnabled = prefs.getBool('notifications_enabled') ?? true;
      _biometry = prefs.getBool('biometry_enabled') ?? false;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', _notifEnabled);
    await prefs.setBool('biometry_enabled', _biometry);
  }

  Future<String?> _token() async =>
      (await SharedPreferences.getInstance()).getString('token');

  Future<void> _confirmLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: YekiColors.white,
        title: const Text('Déconnexion',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Souhaitez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Annuler', style: TextStyle(color: YekiColors.textMedium)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: YekiColors.error,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Se déconnecter',
                style: TextStyle(color: YekiColors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await YekiAuth.logout(context);
    }
  }

  Future<void> _confirmerSuppression() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: YekiColors.white,
        title: const Text('Supprimer le compte',
            style: TextStyle(fontWeight: FontWeight.bold, color: YekiColors.error)),
        content: const Text(
            'Cette action est irréversible. Toutes vos données seront perdues.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Annuler', style: TextStyle(color: YekiColors.textMedium)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: YekiColors.error, elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer', style: TextStyle(color: YekiColors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final token = await _token();
      final res = await http.delete(
        Uri.parse(ApiConstants.profilDelete),
        headers: ApiHeaders.auth(token),
      );
      if (!mounted) return;
      if (res.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('token');
        await prefs.remove('role');
        if (mounted) await YekiAuth.logout(context);
      } else {
        ErrorHandler.showError(context, 'Erreur lors de la suppression.');
      }
    } catch (_) {
      ErrorHandler.showError(context, 'Erreur réseau.');
    }
  }

  Future<void> _changerMotDePasse(
      String ancien, String nouveau, String confirm) async {
    if (nouveau != confirm) {
      ErrorHandler.showError(context, 'Les mots de passe ne correspondent pas.');
      return;
    }
    if (nouveau.length < 8) {
      ErrorHandler.showError(context, 'Le mot de passe doit contenir au moins 8 caractères.');
      return;
    }
    try {
      final token = await _token();
      final res = await http.post(
        Uri.parse(ApiConstants.changePassword),
        headers: ApiHeaders.auth(token),
        body: jsonEncode({'old_password': ancien, 'new_password': nouveau}),
      );
      if (!mounted) return;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200) {
        ErrorHandler.showSuccess(context, 'Mot de passe modifié avec succès !');
        if (data['token'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', data['token'] as String);
        }
        if (mounted) Navigator.pop(context);
      } else {
        ErrorHandler.showError(context, data['detail'] ?? 'Erreur.');
      }
    } catch (_) {
      ErrorHandler.showError(context, 'Erreur réseau.');
    }
  }

  void _showChangerMdpSheet() {
    final ancienCtrl = TextEditingController();
    final nouveauCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool loading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Container(
          decoration: const BoxDecoration(
            color: YekiColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: YekiColors.borderLight, borderRadius: BorderRadius.circular(8)))),
            const SizedBox(height: 20),
            const Text('Changer le mot de passe',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _pwdField(ancienCtrl, 'Ancien mot de passe'),
            const SizedBox(height: 12),
            _pwdField(nouveauCtrl, 'Nouveau mot de passe'),
            const SizedBox(height: 12),
            _pwdField(confirmCtrl, 'Confirmer le nouveau'),
            const SizedBox(height: 20),
            YekiButton(
              label: 'Confirmer',
              onPressed: loading ? null : () async {
                setS(() => loading = true);
                await _changerMotDePasse(
                  ancienCtrl.text, nouveauCtrl.text, confirmCtrl.text);
                setS(() => loading = false);
              },
              isLoading: loading,
            ),
          ]),
        ),
      ),
    );
  }

  Widget _pwdField(TextEditingController ctrl, String hint) => TextField(
    controller: ctrl, obscureText: true,
    decoration: InputDecoration(
      hintText: hint, prefixIcon: Icon(Icons.lock_outline, color: YekiColors.primaryDark, size: 20),
      filled: true, fillColor: YekiColors.backgroundLight,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: YekiColors.primaryDark, width: 1.5)),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: YekiColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Paramètres',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: YekiColors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle('Sécurité'),
          _tile(
            icon: Icons.lock_reset_rounded, color: YekiColors.primaryDark,
            title: 'Changer le mot de passe',
            onTap: _showChangerMdpSheet,
          ),
          const SizedBox(height: 16),
          _sectionTitle('Notifications'),
          _switchTile(
            icon: Icons.notifications_rounded, color: YekiColors.warning,
            title: 'Notifications push',
            subtitle: 'Recevoir les alertes de l\'app',
            value: _notifEnabled,
            onChanged: (v) async {
              setState(() => _notifEnabled = v);
              await _saveSettings();
            },
          ),
          const SizedBox(height: 16),
          _sectionTitle('Préférences'),
          _tile(
            icon: Icons.language_rounded, color: YekiColors.purple,
            title: 'Langue',
            trailing: Text(_lang, style: TextStyle(color: YekiColors.textLight, fontSize: 13)),
            onTap: () {},
          ),
          _switchTile(
            icon: Icons.fingerprint_rounded, color: YekiColors.success,
            title: 'Biométrie',
            subtitle: 'Connexion par empreinte / Face ID',
            value: _biometry,
            onChanged: (v) async {
              setState(() => _biometry = v);
              await _saveSettings();
            },
          ),
          const SizedBox(height: 16),
          _sectionTitle('Compte'),
          _tile(
            icon: Icons.logout_rounded, color: YekiColors.warning,
            title: 'Se déconnecter',
            onTap: _confirmLogout,
          ),
          _tile(
            icon: Icons.delete_forever_rounded, color: YekiColors.error,
            title: 'Supprimer mon compte',
            titleColor: YekiColors.error,
            onTap: _confirmerSuppression,
          ),
          const SizedBox(height: 32),
          Center(child: Text('Yéki v1.0.3',
              style: TextStyle(color: YekiColors.textLight, fontSize: 12))),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _sectionTitle(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(t, style: TextStyle(
      fontSize: 12, fontWeight: FontWeight.w700,
      color: YekiColors.textLight, letterSpacing: 0.8)),
  );

  Widget _tile({
    required IconData icon, required Color color,
    required String title, Color? titleColor,
    Widget? trailing, required VoidCallback onTap,
  }) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    decoration: BoxDecoration(
      color: YekiColors.white, borderRadius: BorderRadius.circular(16),
      boxShadow: YekiShadows.subtle,
    ),
    child: ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      leading: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: color, size: 18)),
      title: Text(title, style: TextStyle(
        fontSize: 14, fontWeight: FontWeight.w600,
        color: titleColor ?? YekiColors.textDark)),
      trailing: trailing ?? Icon(Icons.chevron_right_rounded, size: 18),
      onTap: onTap,
    ),
  );

  Widget _switchTile({
    required IconData icon, required Color color,
    required String title, required String subtitle,
    required bool value, required ValueChanged<bool> onChanged,
  }) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    decoration: BoxDecoration(
      color: YekiColors.white, borderRadius: BorderRadius.circular(16),
      boxShadow: YekiShadows.subtle,
    ),
    child: SwitchListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      secondary: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: color, size: 18)),
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      value: value,
      onChanged: onChanged,
      activeColor: YekiColors.primaryDark,
    ),
  );
}