import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  static const String _base = 'https://yekiapp.pythonanywhere.com/api';

  final Color primaryColor   = const Color(0xFF2884A0);
  final Color darkBlue       = const Color(0xFF1A1C1E);
  final Color backgroundColor = const Color(0xFFF8FAFB);

  bool _notificationsEnabled = true;
  bool _biometryEnabled      = false;
  String _language           = "Français";

  Future<String?> _token() async {
    final p = await SharedPreferences.getInstance();
    return p.getString('token');
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? Colors.red : Colors.green,
    ));
  }

  // ── Déconnexion ───────────────────────────────────
  Future<void> _handleLogout() async {
    final bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("Déconnexion",
            style: TextStyle(fontWeight: FontWeight.bold)),
        content:
            const Text("Souhaitez-vous vraiment quitter l'application ?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child:
                  Text("Annuler", style: TextStyle(color: Colors.grey[600]))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Se déconnecter"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final token = await _token();
      if (token != null) {
        try {
          await http.post(Uri.parse('$_base/auth/logout/'),
              headers: {'Authorization': 'Token $token'});
        } catch (_) {}
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
            context, '/login', (route) => false);
      }
    }
  }

  // ── Changer le mot de passe ───────────────────────
  Future<void> _showChangePasswordDialog() async {
    final oldCtrl  = TextEditingController();
    final newCtrl  = TextEditingController();
    final confCtrl = TextEditingController();
    bool loading = false;
    bool obscureOld  = true;
    bool obscureNew  = true;
    bool obscureConf = true;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: const Text("Changer le mot de passe"),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            _pwField("Ancien mot de passe", oldCtrl, obscureOld,
                () => setSt(() => obscureOld = !obscureOld)),
            const SizedBox(height: 10),
            _pwField("Nouveau mot de passe", newCtrl, obscureNew,
                () => setSt(() => obscureNew = !obscureNew)),
            const SizedBox(height: 10),
            _pwField("Confirmer", confCtrl, obscureConf,
                () => setSt(() => obscureConf = !obscureConf)),
          ]),
          actions: [
            TextButton(
                onPressed: loading ? null : () => Navigator.pop(ctx),
                child: const Text("Annuler")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor),
              onPressed: loading
                  ? null
                  : () async {
                      if (newCtrl.text != confCtrl.text) {
                        _snack('Les mots de passe ne correspondent pas.',
                            error: true);
                        return;
                      }
                      setSt(() => loading = true);
                      final token = await _token();
                      try {
                        final res = await http.post(
                          Uri.parse('$_base/auth/change-password/'),
                          headers: {
                            'Authorization': 'Token $token',
                            'Content-Type': 'application/json',
                          },
                          body:
                              '{"old_password":"${oldCtrl.text}","new_password":"${newCtrl.text}"}',
                        );
                        setSt(() => loading = false);
                        if (res.statusCode == 200) {
                          Navigator.pop(ctx);
                          _snack('Mot de passe modifié ! Reconnectez-vous.');
                          // Déconnecter après changement de mot de passe
                          final prefs =
                              await SharedPreferences.getInstance();
                          await prefs.clear();
                          if (mounted) {
                            Navigator.pushNamedAndRemoveUntil(
                                context, '/login', (r) => false);
                          }
                        } else {
                          _snack('Erreur : vérifiez l\'ancien mot de passe.',
                              error: true);
                        }
                      } catch (e) {
                        setSt(() => loading = false);
                        _snack('Erreur réseau.', error: true);
                      }
                    },
              child: loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text("Confirmer",
                      style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pwField(
      String label, TextEditingController ctrl, bool obscure, VoidCallback toggle) =>
      TextField(
        controller: ctrl,
        obscureText: obscure,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12)),
          suffixIcon: IconButton(
            icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
            onPressed: toggle,
          ),
        ),
      );

  // ── Supprimer le compte ───────────────────────────
  Future<void> _confirmAccountDeletion() async {
    final bool? confirm = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24)),
        title: const Text("Action irréversible",
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.redAccent)),
        content: const Text(
            "La suppression de votre compte effacera toutes vos données. Continuer ?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Annuler")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Supprimer",
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final token = await _token();
      try {
        final res = await http.delete(
          Uri.parse('$_base/profil/delete/'),
          headers: {'Authorization': 'Token $token'},
        );
        if (res.statusCode == 200) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.clear();
          if (mounted) {
            Navigator.pushNamedAndRemoveUntil(
                context, '/login', (r) => false);
          }
        } else {
          _snack('Erreur lors de la suppression.', error: true);
        }
      } catch (e) {
        _snack('Erreur réseau.', error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text("Paramètres",
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
        backgroundColor: darkBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView(
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        physics: const BouncingScrollPhysics(),
        children: [
          _buildSection("SÉCURITÉ", [
            _buildSwitchTile("Biométrie (Face ID / Empreinte)",
                Icons.fingerprint_rounded, _biometryEnabled, (v) {
              setState(() => _biometryEnabled = v);
            }),
            _buildActionTile(
              "Changer le mot de passe",
              Icons.lock_outline_rounded,
              _showChangePasswordDialog,
            ),
          ]),
          _buildSection("APPARENCE & LANGUE", [
            _buildDropdownTile(
              "Langue de l'interface",
              Icons.translate_rounded,
              _language,
              ["Français", "Anglais"],
              (val) => setState(() => _language = val!),
            ),
          ]),
          _buildSection("NOTIFICATIONS", [
            _buildSwitchTile(
              "Alertes de nouveaux cours",
              Icons.notifications_none_rounded,
              _notificationsEnabled,
              (v) => setState(() => _notificationsEnabled = v),
            ),
          ]),
          _buildSection("COMPTE", [
            _buildActionTile("Se déconnecter", Icons.logout_rounded,
                _handleLogout,
                color: Colors.blueAccent),
            _buildActionTile("Supprimer mon compte",
                Icons.delete_outline_rounded, _confirmAccountDeletion,
                color: Colors.redAccent),
          ]),
          const SizedBox(height: 40),
          Column(children: [
            Image.asset('assets/images/logo_yeki.png',
                height: 40,
                errorBuilder: (_, __, ___) =>
                    Icon(Icons.school, color: primaryColor, size: 40)),
            const SizedBox(height: 10),
            Text("Yéki — Version 1.0.0",
                style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                    fontWeight: FontWeight.w500)),
            Text("Fait avec ❤️ pour les étudiants",
                style: TextStyle(
                    color: Colors.grey.shade400, fontSize: 10)),
          ]),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding:
                const EdgeInsets.only(top: 25, bottom: 10, left: 10),
            child: Text(title,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: primaryColor,
                    letterSpacing: 1.2)),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade100),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4))
              ],
            ),
            child: Column(children: children),
          ),
        ],
      );

  Widget _buildActionTile(String title, IconData icon, VoidCallback onTap,
          {Color? color}) =>
      ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: (color ?? primaryColor).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color ?? primaryColor, size: 20),
        ),
        title: Text(title,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: darkBlue)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded,
            size: 14, color: Colors.grey),
        onTap: onTap,
      );

  Widget _buildSwitchTile(String title, IconData icon, bool value,
          Function(bool) onChanged) =>
      SwitchListTile(
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: primaryColor, size: 20),
        ),
        title: Text(title,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: darkBlue)),
        activeColor: primaryColor,
        value: value,
        onChanged: onChanged,
      );

  Widget _buildDropdownTile(String title, IconData icon,
          String currentValue, List<String> items,
          Function(String?) onChanged) =>
      ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: primaryColor, size: 20),
        ),
        title: Text(title,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: darkBlue)),
        trailing: DropdownButton<String>(
          value: currentValue,
          underline: const SizedBox(),
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          style: TextStyle(
              color: primaryColor, fontWeight: FontWeight.bold),
          onChanged: onChanged,
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
        ),
      );
}