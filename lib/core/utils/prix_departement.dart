// lib/core/utils/prix_departement.dart
//
// Prix affiché sur les cartes de département. Bug corrigé : les cartes
// lisaient l'ancien champ `prix` (accès unique, plus saisi depuis le
// formulaire, donc toujours 0) et affichaient « Gratuit » même pour un
// département à abonnement payant. Le prix réel est celui des abonnements
// (`prix_mensuel`, `prix_annuel`) ; `prix` ne sert plus que de repli pour
// les anciens départements.

import 'package:intl/intl.dart';

final _format = NumberFormat('#,###', 'fr_FR');

bool estGratuit({int prixMensuel = 0, int prixAnnuel = 0, int prix = 0}) =>
    prixMensuel <= 0 && prixAnnuel <= 0 && prix <= 0;

/// « 1 500 FCFA/mois », « 13 000 FCFA/an », ou « Gratuit ».
String libellePrixDepartement({int prixMensuel = 0, int prixAnnuel = 0, int prix = 0}) {
  if (prixMensuel > 0) return '${_format.format(prixMensuel)} FCFA/mois';
  if (prixAnnuel > 0) return '${_format.format(prixAnnuel)} FCFA/an';
  if (prix > 0) return '${_format.format(prix)} FCFA';
  return 'Gratuit';
}

/// Même chose à partir de la réponse brute de l'API (tableaux de bord).
String libellePrixDepuisJson(Map<String, dynamic> dept) => libellePrixDepartement(
  prixMensuel: (dept['prix_mensuel'] as num?)?.toInt() ?? 0,
  prixAnnuel: (dept['prix_annuel'] as num?)?.toInt() ?? 0,
  prix: (dept['prix'] as num?)?.toInt() ?? 0,
);

bool estGratuitDepuisJson(Map<String, dynamic> dept) => estGratuit(
  prixMensuel: (dept['prix_mensuel'] as num?)?.toInt() ?? 0,
  prixAnnuel: (dept['prix_annuel'] as num?)?.toInt() ?? 0,
  prix: (dept['prix'] as num?)?.toInt() ?? 0,
);
