import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isDarkMode = false;
  bool _notificationsEnabled = true;
  bool _biometryEnabled = false;
  String _language = "Français";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text("Paramètres", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF03224C),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection("🔒 Sécurité", [
            _buildSwitchTile("Activer la biométrie", _biometryEnabled, (v) {
              setState(() => _biometryEnabled = v);
            }),
            _buildActionTile("Changer le mot de passe", Icons.lock, () {
              // Naviguer vers page de modification du mot de passe
            }),
          ]),

          _buildSection("🎨 Apparence & Langue", [
            _buildSwitchTile("Mode sombre", _isDarkMode, (v) {
              setState(() => _isDarkMode = v);
            }),
            _buildDropdownTile("Langue", _language, ["Français", "Anglais"], (val) {
              setState(() => _language = val!);
            }),
          ]),

          _buildSection("🔔 Notifications", [
            _buildSwitchTile("Notifications activées", _notificationsEnabled, (v) {
              setState(() => _notificationsEnabled = v);
            }),
          ]),

          _buildSection("🧑 Compte", [
            _buildActionTile("Déconnexion", Icons.exit_to_app, () {
              // Déconnexion
            }, color: Colors.blue),
            _buildActionTile("Supprimer mon compte", Icons.delete_forever, () {
              _confirmAccountDeletion();
            }, color: Colors.red),
          ]),

          const SizedBox(height: 30),
          Center(
            child: Text("Yéki v1.0.0", style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 12),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.deepOrange.shade700,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
            ],
          ),
          child: Column(children: children),
        )
      ],
    );
  }

  Widget _buildActionTile(String title, IconData icon, VoidCallback onTap, {Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color ?? Colors.teal),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile(String title, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      activeColor: Colors.green,
      title: Text(title),
      value: value,
      onChanged: onChanged,
    );
  }

  Widget _buildDropdownTile(
      String title, String currentValue, List<String> items, Function(String?) onChanged) {
    return ListTile(
      title: Text(title),
      trailing: DropdownButton<String>(
        value: currentValue,
        underline: Container(),
        onChanged: onChanged,
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      ),
    );
  }

  void _confirmAccountDeletion() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Supprimer votre compte ?"),
        content: const Text("Cette action est irréversible. Confirmez-vous ?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Compte supprimé (simulé)")));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Confirmer"),
          ),
        ],
      ),
    );
  }
}
