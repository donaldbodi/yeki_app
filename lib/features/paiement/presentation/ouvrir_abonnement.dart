// lib/features/paiement/presentation/ouvrir_abonnement.dart
//
// Point d'entrée unique vers l'achat d'un abonnement Premium — utilisé par
// tout écran qui affiche `YkPremiumRequired` (Devoirs, Forum, leçon/vidéo).
// Rectification (demande explicite) : l'abonnement n'est plus global, il
// est PROPRE À CHAQUE DÉPARTEMENT, aux prix RÉELS fixés par l'enseignant
// administrateur de CE département (`Departement.prix_mensuel`/
// `prix_annuel`, `StatutAbonnementView`) — jamais une constante globale
// figée côté client (règle 3).

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

/// [coursId] : n'importe quel cours DU département concerné (le serveur
/// résout le département depuis ce cours) — déjà disponible à chacun des
/// écrans « univers du cours » qui appellent cette fonction.
Future<void> ouvrirAbonnementPremium(BuildContext context, {required int coursId, String? coursNom}) async {
  try {
    final statut = await PaiementRepository().statutAbonnement(coursId);
    if (!statut.disponible) {
      if (context.mounted) {
        YkSnack.error(
          context,
          "L'abonnement Premium n'est pas encore disponible pour ce département — "
          "l'administrateur n'a pas encore fixé de prix.",
        );
      }
      return;
    }
    if (!context.mounted) return;
    context.pushNamed(
      AppRoute.paiement,
      queryParameters: {
        'type': PaiementType.abonnementMensuel.name,
        'titre': coursNom == null ? 'Abonnement Premium' : 'Abonnement Premium — $coursNom',
        'montant': statut.prixMensuel.toString(),
        'departementId': statut.departementId.toString(),
        if (statut.prixAnnuel > 0) 'montantAnnuel': statut.prixAnnuel.toString(),
      },
    );
  } on ApiException catch (e) {
    if (context.mounted) YkSnack.error(context, e.message);
  } catch (_) {
    if (context.mounted) YkSnack.error(context, 'Erreur réseau.');
  }
}
