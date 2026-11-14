// lib/core/utils/cycles_departement.dart
//
// Calcul des cycles d'un département (abonnement et classement), pour
// l'aperçu du formulaire de l'enseignant admin. Même règle que le serveur
// (`apps/formation/cycles.py`), qui reste la seule référence : les deux
// doivent rester identiques.

import 'dart:math' as math;

const String kPlacementSuite = 'suite';
const String kPlacementRepartis = 'repartis';

class CycleDepartement {
  const CycleDepartement({required this.numero, required this.debut, required this.fin});

  final int numero;

  /// Premier jour du cycle.
  final DateTime debut;

  /// Lendemain du dernier jour (borne exclue).
  final DateTime fin;

  DateTime get dernierJour => fin.subtract(const Duration(days: 1));
}

/// Nombre maximal de cycles par an : 12 ÷ durée, arrondi à l'entier inférieur.
int nombreMaxCycles(int dureeMois) => (dureeMois < 1 || dureeMois > 12) ? 0 : 12 ~/ dureeMois;

/// Ajoute des mois en restant sur le dernier jour du mois si besoin
/// (31 janvier + 1 mois = 28 ou 29 février), comme `relativedelta`.
DateTime ajouterMois(DateTime date, int mois) {
  final total = date.month - 1 + mois;
  final annee = date.year + total ~/ 12;
  final moisCible = total % 12 + 1;
  final dernierJour = DateTime(annee, moisCible + 1, 0).day;
  return DateTime(annee, moisCible, math.min(date.day, dernierJour));
}

List<int> decalagesMois(int dureeMois, int nombre, String placement) => [
  for (var i = 0; i < nombre; i++) placement == kPlacementRepartis ? (i * 12) ~/ nombre : i * dureeMois,
];

/// Cycles de l'année [annee] (0 = la première), à partir de [debut].
List<CycleDepartement> calculerCycles({
  required DateTime debut,
  required int dureeMois,
  required int nombre,
  required String placement,
  int annee = 0,
}) {
  if (nombreMaxCycles(dureeMois) == 0 || nombre < 1) return const [];
  final base = ajouterMois(DateTime(debut.year, debut.month, debut.day), 12 * annee);
  final decalages = decalagesMois(dureeMois, nombre, placement);
  return [
    for (var i = 0; i < decalages.length; i++)
      CycleDepartement(
        numero: i + 1,
        debut: ajouterMois(base, decalages[i]),
        fin: ajouterMois(base, decalages[i] + dureeMois),
      ),
  ];
}

/// Libellé de l'abonnement payé au prix du cycle (même texte que le serveur).
const String kLibelleAbonnementCycle = 'Abonnement annuel';
