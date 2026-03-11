import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

const String _baseO = 'https://yeki.pythonanywhere.com/api';

// ─── Palette ────────────────────────────────────────────────────
const Color _olymp  = Color(0xFF7B2FBE);
const Color _gold   = Color(0xFFE2A84B);
const Color _teal   = Color(0xFF008088);
const Color _accent = Color(0xFFFF7F77);
const Color _dark   = Color(0xFF1A1C1E);
const Color _bg     = Color(0xFFF5F7FA);

// ═══════════════════════════════════════════════════════════════
// Page classement olympiade
// ═══════════════════════════════════════════════════════════════
class ClassementPage extends StatefulWidget {
  final int    olympiadeId;
  final String titre;
  const ClassementPage({super.key, required this.olympiadeId, required this.titre});

  @override
  State<ClassementPage> createState() => _ClassementPageState();
}

class _ClassementPageState extends State<ClassementPage> {
  bool  _loading = true;
  List  _entrees = [];

  @override
  void initState() { super.initState(); _charger(); }

  Future<String?> _token() async {
    final p = await SharedPreferences.getInstance();
    return p.getString('token');
  }

  Future<void> _charger() async {
    final token = await _token();
    final res = await http.get(
      Uri.parse('$_baseO/olympiades/${widget.olympiadeId}/classement/'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Token $token',
      },
    );
    if (res.statusCode == 200) {
      setState(() {
        _entrees = jsonDecode(res.body) as List;
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _olymp,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Classement — ${widget.titre}',
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 14)),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: _olymp))
          : _entrees.isEmpty
              ? Center(
                  child: Text('Aucun participant classé.',
                      style: TextStyle(color: Colors.grey.shade400)),
                )
              : ListView.builder(
                  padding:
                      const EdgeInsets.fromLTRB(16, 16, 16, 40),
                  itemCount: _entrees.length,
                  itemBuilder: (_, i) =>
                      _buildEntree(_entrees[i], i),
                ),
    );
  }

  Widget _buildEntree(Map e, int i) {
    final rang    = e['rang'] as int;
    final name    = e['username'] as String;
    final note20  = (e['note_sur_20'] as num).toDouble();

    Color  bgColor  = Colors.white;
    Color  rnColor  = Colors.grey.shade400;
    Widget? medal;

    if (rang == 1) {
      bgColor = const Color(0xFFFFF8E1);
      rnColor = const Color(0xFFE2A84B);
      medal   = const Icon(Icons.emoji_events_rounded,
          color: Color(0xFFE2A84B), size: 22);
    } else if (rang == 2) {
      bgColor = const Color(0xFFF5F5F5);
      rnColor = Colors.blueGrey;
      medal   = const Icon(Icons.emoji_events_rounded,
          color: Colors.blueGrey, size: 20);
    } else if (rang == 3) {
      bgColor = const Color(0xFFFFF3E0);
      rnColor = Colors.orange;
      medal   = const Icon(Icons.emoji_events_rounded,
          color: Colors.orange, size: 18);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Row(children: [
        // Rang
        SizedBox(
          width: 36,
          child: medal ??
              Text('#$rang', style: TextStyle(
                color: rnColor, fontWeight: FontWeight.w900,
                fontSize: 14,
              )),
        ),
        const SizedBox(width: 12),
        // Avatar
        CircleAvatar(
          radius: 18,
          backgroundColor: _olymp.withOpacity(0.15),
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: const TextStyle(
                color: _olymp, fontWeight: FontWeight.w900,
                fontSize: 14),
          ),
        ),
        const SizedBox(width: 12),
        // Nom
        Expanded(child: Text(name, style: const TextStyle(
          fontWeight: FontWeight.w700, fontSize: 14, color: _dark,
        ))),
        // Note
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: _olymp.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '${note20.toStringAsFixed(1)}/20',
            style: const TextStyle(
                color: _olymp, fontWeight: FontWeight.w800,
                fontSize: 13),
          ),
        ),
      ]),
    );
  }
}