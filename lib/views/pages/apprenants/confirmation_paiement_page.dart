import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ConfirmationPaiementPage extends StatelessWidget {
  final String concours;
  final double montant;
  final String moyen;
  final String reference;

  const ConfirmationPaiementPage({
    super.key,
    required this.concours,
    required this.montant,
    required this.moyen,
    required this.reference,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Paiement Réussi"),
        backgroundColor: const Color(0xFF03224C),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline,
                size: 100, color: Colors.green),
            const SizedBox(height: 20),
            const Text("Merci pour votre paiement",
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87)),
            const SizedBox(height: 12),
            Text("Concours : $concours",
                style: const TextStyle(fontSize: 16)),
            Text("Montant payé : ${montant.toStringAsFixed(0)} FCFA",
                style: const TextStyle(fontSize: 16)),
            Text("Méthode : $moyen", style: const TextStyle(fontSize: 16)),
            Text("Référence : $reference", style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              icon: const Icon(Icons.history),
              label: const Text("Voir historique"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF5722),
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HistoriquePaiementPage(),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class HistoriquePaiementPage extends StatelessWidget {
  const HistoriquePaiementPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> paiements = [
      {
        'concours': "Concours ENS",
        'montant': 20000,
        'date': DateTime.now().subtract(const Duration(days: 1)),
        'reference': "YEKI-83920ENS"
      },
      {
        'concours': "Concours IUT",
        'montant': 18000,
        'date': DateTime.now().subtract(const Duration(days: 5)),
        'reference': "YEKI-27351IUT"
      },
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Historique des Paiements"),
        backgroundColor: const Color(0xFF03224C),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: paiements.length,
        itemBuilder: (context, index) {
          final paiement = paiements[index];
          return Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            elevation: 5,
            shadowColor: Colors.orange.shade100,
            child: ListTile(
              leading: const Icon(Icons.receipt_long, color: Color(0xFF03224C)),
              title: Text(paiement['concours']),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Réf : ${paiement['reference']}"),
                  Text(
                    "Date : ${DateFormat('dd MMM yyyy').format(paiement['date'])}",
                  ),
                ],
              ),
              trailing: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "${paiement['montant']} FCFA",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.deepOrange),
                  ),
                  TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Téléchargement du reçu..."),
                        ),
                      );
                    },
                    child: const Text("Télécharger",
                        style: TextStyle(fontSize: 12)),
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
