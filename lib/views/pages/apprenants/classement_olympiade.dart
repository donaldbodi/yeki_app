// lib/views/pages/apprenants/classement_olympiade.dart
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yeki/core/theme/app_theme.dart';
import 'package:yeki/core/constants/api_constants.dart';

class ClassementOlympiadePage extends StatefulWidget {
  final int olympiadeId;
  final String titre;
  const ClassementOlympiadePage({super.key, required this.olympiadeId, required this.titre});

  @override
  State<ClassementOlympiadePage> createState() => _ClassementOlympiadePageState();
}

class _ClassementOlympiadePageState extends State<ClassementOlympiadePage> {
  bool _loading = true;
  List _entrees = [];

  @override
  void initState() { 
    super.initState(); 
    _charger(); 
  }

  Future<String?> _token() async {
    final p = await SharedPreferences.getInstance();
    return p.getString('token');
  }

  Future<void> _charger() async {
    final token = await _token();
    // ✅ CORRIGÉ : Utiliser la bonne méthode avec paramètre
    final url = ApiConstants.olympiadeClassement(widget.olympiadeId);
    final res = await http.get(
      Uri.parse(url),
      headers: ApiHeaders.auth(token),
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
      backgroundColor: YekiColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: YekiColors.purple,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Classement — ${widget.titre}',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
      ),
      body: _loading
          ? const Center(child: YekiLoader())
          : _entrees.isEmpty
              ? Center(child: Text('Aucun participant classé.', style: TextStyle(color: YekiColors.textLight)))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                  itemCount: _entrees.length,
                  itemBuilder: (_, i) => _buildEntree(_entrees[i], i),
                ),
    );
  }

  Widget _buildEntree(Map e, int i) {
    final rang = e['rang'] as int;
    final name = e['username'] as String;
    final note20 = (e['note_sur_20'] as num).toDouble();

    Color bgColor = YekiColors.white;
    Color rnColor = YekiColors.textLight;
    Widget? medal;

    if (rang == 1) {
      bgColor = const Color(0xFFFFF8E1);
      rnColor = const Color(0xFFE2A84B);
      medal = const Icon(Icons.emoji_events_rounded, color: Color(0xFFE2A84B), size: 22);
    } else if (rang == 2) {
      bgColor = const Color(0xFFF5F5F5);
      rnColor = YekiColors.textMedium;
      medal = const Icon(Icons.emoji_events_rounded, color: YekiColors.textMedium, size: 20);
    } else if (rang == 3) {
      bgColor = const Color(0xFFFFF3E0);
      rnColor = YekiColors.warning;
      medal = const Icon(Icons.emoji_events_rounded, color: YekiColors.warning, size: 18);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: YekiRadius.borderRadiusLg,
        boxShadow: YekiShadows.subtle,
      ),
      child: Row(children: [
        SizedBox(
          width: 36,
          child: medal ?? Text('#$rang', style: TextStyle(color: rnColor, fontWeight: FontWeight.w900, fontSize: 14)),
        ),
        const SizedBox(width: 12),
        CircleAvatar(
          radius: 18,
          backgroundColor: YekiColors.purple.withValues(alpha: 0.15),
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14))),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: YekiColors.purple.withValues(alpha: 0.1),
            borderRadius: YekiRadius.borderRadiusSm,
          ),
          child: Text('${note20.toStringAsFixed(1)}/20',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
        ),
      ]),
    );
  }
}