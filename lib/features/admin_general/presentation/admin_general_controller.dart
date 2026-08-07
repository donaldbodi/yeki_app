import 'package:flutter/foundation.dart';

import '../data/admin_general_models.dart';
import '../data/admin_general_repository.dart';

/// État + logique de l'administration générale (P9.6) — un contrôleur pour
/// les 6 onglets (parcours/départements/vue globale/enseignants/tous les
/// cours/transactions). `ChangeNotifier` plutôt que `setState` (interdit
/// sous `lib/features/`, règle 7).
class AdminGeneralController extends ChangeNotifier {
  AdminGeneralController({AdminGeneralRepository? repository}) : _repo = repository ?? AdminGeneralRepository();

  final AdminGeneralRepository _repo;

  // ── Dashboard (parcours/départements/stats/top enseignants) ────────
  bool chargementDashboard = true;
  bool enErreurDashboard = false;
  AdminGeneralDashboard? dashboard;

  // ── Enseignants (recherche/filtres) ─────────────────────────────────
  bool chargementEnseignants = false;
  bool enErreurEnseignants = false;
  List<EnseignantAdmin> enseignants = const [];
  String searchQuery = '';
  String filterUserType = '';
  bool? filterActif;

  // ── Tous les cours ───────────────────────────────────────────────────
  bool chargementCours = true;
  bool enErreurCours = false;
  List<CoursAdmin> tousLesCours = const [];

  // ── Transactions (P9.6) ──────────────────────────────────────────────
  bool chargementTransactions = true;
  bool enErreurTransactions = false;
  List<AdminTransaction> transactions = const [];
  int? filtreDepartementId;
  String filtreCategorie = '';
  String filtreStatut = '';
  String filtreDu = '';
  String filtreAu = '';

  // ── Tableau de bord financier (P9.6) ─────────────────────────────────
  bool chargementFinancier = true;
  bool enErreurFinancier = false;
  AdminDashboardFinancier? financier;

  Future<void> chargerTout() => Future.wait([
    chargerDashboard(),
    chargerTousLesCours(),
    chargerTransactions(),
    chargerFinancier(),
  ]);

  Future<void> chargerDashboard() async {
    chargementDashboard = true;
    enErreurDashboard = false;
    notifyListeners();
    try {
      dashboard = await _repo.dashboard();
      enseignants = dashboard!.enseignants;
    } catch (_) {
      enErreurDashboard = true;
    } finally {
      chargementDashboard = false;
      notifyListeners();
    }
  }

  Future<void> rechercherEnseignants() async {
    chargementEnseignants = true;
    enErreurEnseignants = false;
    notifyListeners();
    try {
      enseignants = await _repo.rechercherEnseignants(
        q: searchQuery,
        userType: filterUserType,
        isActive: filterActif,
      );
    } catch (_) {
      enErreurEnseignants = true;
    } finally {
      chargementEnseignants = false;
      notifyListeners();
    }
  }

  Future<void> chargerTousLesCours() async {
    chargementCours = true;
    enErreurCours = false;
    notifyListeners();
    try {
      tousLesCours = await _repo.tousLesCours();
    } catch (_) {
      enErreurCours = true;
    } finally {
      chargementCours = false;
      notifyListeners();
    }
  }

  Future<void> chargerTransactions() async {
    chargementTransactions = true;
    enErreurTransactions = false;
    notifyListeners();
    try {
      transactions = await _repo.transactions(
        departementId: filtreDepartementId,
        categorie: filtreCategorie,
        du: filtreDu,
        au: filtreAu,
        statut: filtreStatut,
      );
    } catch (_) {
      enErreurTransactions = true;
    } finally {
      chargementTransactions = false;
      notifyListeners();
    }
  }

  Future<void> chargerFinancier() async {
    chargementFinancier = true;
    enErreurFinancier = false;
    notifyListeners();
    try {
      financier = await _repo.dashboardFinancier();
    } catch (_) {
      enErreurFinancier = true;
    } finally {
      chargementFinancier = false;
      notifyListeners();
    }
  }

  Future<List<AdminEnseignantRef>> chargerEnseignantsAdmins() => _repo.enseignantsAdmins();

  Future<void> creerParcours({required String nom, required String description, required String typeParcours}) async {
    await _repo.creerParcours(nom: nom, description: description, typeParcours: typeParcours);
    await chargerDashboard();
  }

  Future<void> modifierParcours(
    int parcoursId, {
    required String nom,
    required String description,
    required String typeParcours,
  }) async {
    await _repo.modifierParcours(parcoursId, nom: nom, description: description, typeParcours: typeParcours);
    await chargerDashboard();
  }

  Future<void> nommerAdminParcours(int parcoursId, int enseignantAdminId) async {
    await _repo.nommerAdminParcours(parcoursId, enseignantAdminId);
    await chargerDashboard();
  }

  Future<void> modifierEnseignant(int profileId, {required String userType, required bool isActive}) async {
    await _repo.modifierEnseignant(profileId, userType: userType, isActive: isActive);
    await Future.wait([rechercherEnseignants(), chargerDashboard()]);
  }
}
