// lib/features/paiement/presentation/ouvrir_abonnement.dart
//
// Point d'entrée unique vers l'achat d'un abonnement Premium — utilisé par
// tout écran qui affiche `YkPremiumRequired` (Devoirs, Forum, à terme
// Exercices/IA). Récupère les tarifs RÉELS (`AbonnementPremium.TARIFS`
// côté backend, `StatutAbonnementView`) plutôt que de les figer en dur
// côté client (règle 3) — aucune valeur inventée si l'appel échoue.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:yeki/core/design/components/components.dart';
import 'package:yeki/core/network/api_exception.dart';
import 'package:yeki/core/router/route_names.dart';
import 'package:yeki/repositories/paiement_repository.dart';

import 'paiement_page.dart';

/// Message exact renvoyé par `AccesMatricePermission`
/// (`apps/core/permissions.py:28`) quand un apprenant sans
/// `AbonnementPremium` actif tente d'accéder à un `Devoir`/
/// `QuestionForum`/`Exercice` verrouillé — comparé tel quel (pas de code
/// d'erreur dédié côté backend) pour distinguer ce cas des autres erreurs
/// réseau/serveur et afficher `YkPremiumRequired` plutôt qu'un état
/// d'erreur générique.
const kMessagePremiumRequis = 'Cette fonctionnalité est réservée aux abonnés Premium.';

Future<void> ouvrirAbonnementPremium(BuildContext context) async {
  try {
    final statut = await PaiementRepository().statutAbonnement();
    final tarifs = statut['tarifs'] as Map<String, dynamic>?;
    final mensuel = (tarifs?['mensuel'] as num?)?.toInt();
    final annuel = (tarifs?['annuel'] as num?)?.toInt();
    if (mensuel == null) {
      if (context.mounted) {
        YkSnack.error(context, "Tarifs de l'abonnement indisponibles pour le moment.");
      }
      return;
    }
    if (!context.mounted) return;
    context.pushNamed(
      AppRoute.paiement,
      queryParameters: {
        'type': PaiementType.abonnementMensuel.name,
        'titre': 'Abonnement Premium',
        'montant': mensuel.toString(),
        if (annuel != null) 'montantAnnuel': annuel.toString(),
      },
    );
  } on ApiException catch (e) {
    if (context.mounted) YkSnack.error(context, e.message);
  } catch (_) {
    if (context.mounted) YkSnack.error(context, 'Erreur réseau.');
  }
}
