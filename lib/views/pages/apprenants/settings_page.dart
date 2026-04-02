import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yeki/main.dart';   // YekiAuth

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  static const String _base = 'https://yeki.pythonanywhere.com/api';

  final Color _blue = const Color(0xFF2884A0);
  final Color _dark = const Color(0xFF0D1B2A);
  final Color _bg   = const Color(0xFFF8FAFB);

  bool _notifEnabled = true;
  bool _biometry     = false;
  String _lang       = 'Français';

  Future<String?> _token() async =>
      (await SharedPreferences.getInstance()).getString('token');

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? Colors.red : Colors.green,
      behavior: SnackBarBehavior.floating,
    ));
  }

  // ── Confirmation déconnexion ──────────────────────────────────
  Future<void> _confirmLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Déconnexion',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Souhaitez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Annuler', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Se déconnecter',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      // ✅ YekiAuth.logout → efface token/rôle, conserve onboarding_done
      await YekiAuth.logout(context);
    }
  }

  // ── Supprimer le compte ───────────────────────────────────────
  Future<void> _confirmerSuppression() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Supprimer le compte',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
        content: const Text(
            'Cette action est irréversible. Toutes vos données seront perdues.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Annuler', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red, elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final token = await _token();
      final res = await http.delete(
        Uri.parse('$_base/profil/delete/'),
        headers: {'Authorization': 'Token $token'},
      );
      if (!mounted) return;
      if (res.statusCode == 200) {
        // Même logique que logout mais on garde onboarding_done
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('token');
        await prefs.remove('role');
        if (mounted) await YekiAuth.logout(context);
      } else {
        _snack('Erreur lors de la suppression.', error: true);
      }
    } catch (_) {
      _snack('Erreur réseau.', error: true);
    }
  }

  // ── Changer mot de passe ──────────────────────────────────────
  Future<void> _changerMotDePasse(
      String ancien, String nouveau, String confirm) async {
    if (nouveau != confirm) {
      _snack('Les mots de passe ne correspondent pas.', error: true);
      return;
    }
    try {
      final token = await _token();
      final res = await http.post(
        Uri.parse('$_base/auth/change-password/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
        body: jsonEncode({'old_password': ancien, 'new_password': nouveau}),
      );
      if (!mounted) return;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200) {
        _snack('Mot de passe modifié avec succès !');
        // Re-login avec le nouveau token si renvoyé
        if (data['token'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', data['token'] as String);
        }
        Navigator.pop(context);
      } else {
        _snack(data['detail'] ?? 'Erreur.', error: true);
      }
    } catch (_) {
      _snack('Erreur réseau.', error: true);
    }
  }

  void _showChangerMdpSheet() {
    final ancienCtrl  = TextEditingController();
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
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10)))),
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
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _blue, elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: loading ? null : () async {
                  setS(() => loading = true);
                  await _changerMotDePasse(
                    ancienCtrl.text, nouveauCtrl.text, confirmCtrl.text);
                  setS(() => loading = false);
                },
                child: loading
                    ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Confirmer',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _pwdField(TextEditingController ctrl, String hint) => TextField(
    controller: ctrl, obscureText: true,
    decoration: InputDecoration(
      hintText: hint, prefixIcon: Icon(Icons.lock_outline, color: _blue, size: 20),
      filled: true, fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _blue, width: 1.5)),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('Paramètres',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: _dark,
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Sécurité ──────────────────────────────────────────
          _sectionTitle('Sécurité'),
          _tile(
            icon: Icons.lock_reset_rounded, color: _blue,
            title: 'Changer le mot de passe',
            onTap: _showChangerMdpSheet,
          ),

          const SizedBox(height: 16),

          // ── Notifications ─────────────────────────────────────
          _sectionTitle('Notifications'),
          _switchTile(
            icon: Icons.notifications_rounded, color: const Color(0xFFF97316),
            title: 'Notifications push',
            subtitle: 'Recevoir les alertes de l\'app',
            value: _notifEnabled,
            onChanged: (v) => setState(() => _notifEnabled = v),
          ),

          const SizedBox(height: 16),

          // ── Préférences ───────────────────────────────────────
          _sectionTitle('Préférences'),
          _tile(
            icon: Icons.language_rounded, color: const Color(0xFF8B5CF6),
            title: 'Langue',
            trailing: Text(_lang,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
            onTap: () {},
          ),
          _switchTile(
            icon: Icons.fingerprint_rounded, color: const Color(0xFF10B981),
            title: 'Biométrie',
            subtitle: 'Connexion par empreinte / Face ID',
            value: _biometry,
            onChanged: (v) => setState(() => _biometry = v),
          ),

          const SizedBox(height: 16),

          // ── Compte ────────────────────────────────────────────
          _sectionTitle('Compte'),
          _tile(
            icon: Icons.logout_rounded, color: Colors.orange,
            title: 'Se déconnecter',
            onTap: _confirmLogout,
          ),
          _tile(
            icon: Icons.delete_forever_rounded, color: Colors.red,
            title: 'Supprimer mon compte',
            titleColor: Colors.red,
            onTap: _confirmerSuppression,
          ),

          const SizedBox(height: 32),
          Center(child: Text('Yéki v1.0.0',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 12))),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _sectionTitle(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(t, style: TextStyle(
      fontSize: 12, fontWeight: FontWeight.w700,
      color: Colors.grey.shade500, letterSpacing: 0.8)),
  );

  Widget _tile({
    required IconData icon, required Color color,
    required String title, Color? titleColor,
    Widget? trailing, required VoidCallback onTap,
  }) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    decoration: BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(14),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)],
    ),
    child: ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      leading: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 18)),
      title: Text(title, style: TextStyle(
        fontSize: 14, fontWeight: FontWeight.w600,
        color: titleColor ?? _dark)),
      trailing: trailing ?? Icon(Icons.chevron_right_rounded,
          color: Colors.grey.shade400, size: 18),
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
      color: Colors.white, borderRadius: BorderRadius.circular(14),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)],
    ),
    child: SwitchListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      secondary: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 18)),
      title: Text(title, style: TextStyle(
        fontSize: 14, fontWeight: FontWeight.w600, color: _dark)),
      subtitle: Text(subtitle,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
      value: value,
      onChanged: onChanged,
      activeColor: _blue,
    ),
  );
}
