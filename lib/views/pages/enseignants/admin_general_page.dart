import 'package:flutter/material.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:yeki/widgets/api_service.dart';

class AdminGeneralPage extends StatefulWidget {
  const AdminGeneralPage({super.key});
  @override
  State<AdminGeneralPage> createState() => _AdminGeneralPageState();
}

class _AdminGeneralPageState extends State<AdminGeneralPage> {
  final RefreshController _refreshCtrl = RefreshController(initialRefresh: false);

  List<dynamic> enseignants = [];
  List<dynamic> parcours = [];
  Map<String, dynamic>? stats;

  void _refresh() async {
  try {
    final data = await Future.wait([
      ApiService.getParcours(),
      ApiService.getEnseignants(),
      ApiService.getStatistiquesGlobales(),
    ]);
    setState(() {
      parcours = data[0] as List<dynamic>;
      enseignants = data[1] as List<dynamic>;
      stats = data[2] as Map<String, dynamic>?;
    });
  } catch (e) {
    print("Erreur lors du chargement: $e");
  }
  _refreshCtrl.refreshCompleted();
}

@override
void initState() {
  super.initState();
  _refresh();
}

  void _changerAdmin(int index) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) {
      return Container(
        padding: const EdgeInsets.all(16),
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          children: [
            const Text("Choisir un nouvel administrateur",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.separated(
                itemCount: enseignants.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (ctx, i) {
                  var e = enseignants[i];
                  return GestureDetector(
                    onTap: () async {
                      bool success = await ApiService.changerAdmin(
                        parcours[index]['id'],
                        e['id'],
                      );
                      if (success) {
                        setState(() {
                          parcours[index]['admin'] = e;
                        });
                        Navigator.pop(context);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text("Échec de la modification."),
                        ));
                      }
                    },
                    child: Card(
                      elevation: 2,
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Row(children: [
                          CircleAvatar(
                            backgroundColor: Colors.teal,
                            child: Text(e['name'][0].toUpperCase()),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(e['name'],
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600, fontSize: 14)),
                                  const SizedBox(height: 4),
                                  Text(e['email'] ?? "",
                                      style: const TextStyle(fontSize: 12, color: Colors.black87)),
                                  Text(e['user_type'],
                                      style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                ]),
                          )
                        ]),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Tableau de bord Admin Général",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: const Color(0xFF008080),
        centerTitle: true,
      ),
      body: SmartRefresher(
        controller: _refreshCtrl,
        onRefresh: _refresh,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildStatGlobalCard(),
              const SizedBox(height: 16),
              ..._buildParcoursCards(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatGlobalCard() {
  if (stats == null) return const SizedBox.shrink();
  return Card(
    elevation: 3,
    shape: _cardShape(),
    margin: const EdgeInsets.symmetric(vertical: 8),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text("Statistiques globales",
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF008080))),
            Icon(Icons.analytics_outlined, color: Color(0xFF008080)),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            _StatInfo(icon: Icons.person, text: "Apprenants : ${stats!['total_apprenants']}"),
            _StatInfo(icon: Icons.book, text: "Cours : ${stats!['total_cours']}"),
            _StatInfo(icon: Icons.show_chart, text: "Moyenne : ${stats!['moyenne_globale']} /20"),
          ],
        )
      ]),
    ),
  );
}


  List<Widget> _buildParcoursCards() {
    return List.generate(parcours.length, (i) => _carteParcours(parcours[i], i));
  }

  Widget _carteParcours(Map<String, dynamic> p, int index) {
    return Card(
      elevation: 3,
      shape: _cardShape(),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(p['nom'],
                  style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF008080))),
              IconButton(
                icon: const Icon(Icons.edit, color: Color(0xFF008080)),
                onPressed: () => _changerAdmin(index),
                tooltip: "Changer l’administrateur",
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(spacing: 16, runSpacing: 8, children: [
            _infoItem(Icons.person, "Admin: ${p['admin']['name']}"),
            _infoItem(Icons.book, "Cours: ${p['cours']}"),
            _infoItem(Icons.group, "Apprenants: ${p['apprenants']}"),
            _infoItem(Icons.show_chart, "Moyenne: ${p['moyenne']}"),
          ]),
        ]),
      ),
    );
  }

  ShapeBorder _cardShape() =>
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));

  Widget _infoItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF008080)),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 14)),
      ],
    );
  }
}

class _StatInfo extends StatelessWidget {
  final IconData icon;
  final String text;
  const _StatInfo({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 18, color: Color(0xFF008080)),
      SizedBox(width: 6),
      Text(text, style: TextStyle(fontSize: 14)),
    ]);
  }
}
