import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'auth_state.dart';
import 'guards.dart';
import 'route_names.dart';
import 'route_paths.dart';

import 'package:yeki/features/splash/presentation/splash_page.dart';
import 'package:yeki/views/pages/shared/not_found_page.dart';
import 'package:yeki/views/pages/shared/forbidden_page.dart';
import 'package:yeki/core/design/showcase/design_system_page.dart';
import 'package:yeki/views/pages/shared/profil_page.dart';
import 'package:yeki/views/pages/shared/notifications_page.dart';
import 'package:yeki/features/onboarding/presentation/onboarding_page.dart';
import 'package:yeki/features/login/presentation/login_page.dart';
import 'package:yeki/features/register/presentation/register_page.dart';
import 'package:yeki/features/forgot_password/presentation/forgot_password_page.dart';
import 'package:yeki/features/paiement/presentation/wallet_page.dart';
import 'package:yeki/features/paiement/presentation/recharge_page.dart';
import 'package:yeki/features/paiement/presentation/retrait_page.dart';

import 'package:yeki/views/pages/apprenants/apprenant_shell.dart';
import 'package:yeki/views/pages/apprenants/accueil_page.dart';
import 'package:yeki/views/pages/apprenants/cursus_page.dart';
import 'package:yeki/views/pages/apprenants/concours_pages.dart';
import 'package:yeki/views/pages/apprenants/formations_pages.dart';
import 'package:yeki/features/olympiades/presentation/olympiades_page.dart';
import 'package:yeki/views/pages/apprenants/devoirs_page.dart';
import 'package:yeki/views/pages/apprenants/repetiteurs_page.dart';
import 'package:yeki/views/pages/apprenants/settings_page.dart';
import 'package:yeki/views/pages/apprenants/cours_detail_page.dart';
import 'package:yeki/views/pages/apprenants/detail_lecon_page.dart';
import 'package:yeki/views/pages/apprenants/lecture_lecon_page.dart';
import 'package:yeki/features/exercice/presentation/passer_exercice_page.dart';
import 'package:yeki/features/exercice/presentation/resultat_exercice_page.dart';
import 'package:yeki/features/devoirs_cours/presentation/devoir_detail_page.dart';
import 'package:yeki/features/devoirs_cours/presentation/composer_devoir_page.dart';
import 'package:yeki/features/devoirs_cours/presentation/resultat_devoir_page.dart';
import 'package:yeki/features/olympiades/presentation/olympiade_inscription_page.dart';
import 'package:yeki/features/olympiades/presentation/classement_olympiade_page.dart';
import 'package:yeki/views/pages/apprenants/classement_departement_page.dart';
import 'package:yeki/views/pages/apprenants/formation_detail_page.dart';
import 'package:yeki/features/olympiades/presentation/concours_detail_page.dart';
import 'package:yeki/features/paiement/presentation/paiement_page.dart';
import 'package:yeki/views/pages/apprenants/yeki_ia_chat_page.dart';
import 'package:yeki/views/pages/apprenants/details_question_forum.dart';
import 'package:yeki/views/pages/apprenants/edit_profil_page.dart';
import 'package:yeki/views/pages/apprenants/formations_models.dart' show DepartementItem;
import 'package:yeki/views/pages/apprenants/forum_page.dart' show QForum;

import 'package:yeki/views/pages/enseignants/enseignant_shell.dart';
import 'package:yeki/features/admin_general/presentation/admin_general_page.dart';
import 'package:yeki/views/pages/enseignants/parcours_detail_page.dart';
import 'package:yeki/views/pages/enseignants/departement_detail_page.dart';
import 'package:yeki/views/pages/enseignants/enseignant_admin_dashboard_page.dart';
import 'package:yeki/views/pages/enseignants/cadre_dashboard_page.dart';
import 'package:yeki/views/pages/enseignants/principal_dashboard_page.dart';
import 'package:yeki/views/pages/enseignants/secondaire_dashboard_page.dart';
import 'package:yeki/views/pages/enseignants/historique_page.dart';
import 'package:yeki/views/pages/enseignants/detail_cours_enseignant.dart';
import 'package:yeki/views/pages/enseignants/detail_departement_page.dart';
import 'package:yeki/views/pages/enseignants/gestion_demandes_page.dart';
import 'package:yeki/views/pages/enseignants/interface_enseignant_page.dart'
    show roleEnseignantFromBackend;

import 'package:yeki/features/service_client/presentation/service_client_dashboard_page.dart';

// ── Petits parseurs défensifs pour les paramètres de route ──────────────
int _int(String? s, [int fallback = 0]) => int.tryParse(s ?? '') ?? fallback;
int? _intOrNull(String? s) => s == null ? null : int.tryParse(s);
bool _bool(String? s, [bool fallback = false]) =>
    s == null ? fallback : s.toLowerCase() == 'true';
bool? _boolOrNull(String? s) => s == null ? null : s.toLowerCase() == 'true';
String _str(String? s, [String fallback = '']) => s ?? fallback;

/// Public (P10.4) : `PushNotificationService` en a besoin pour afficher un
/// `YkToast` au premier plan (aucun `BuildContext` disponible dans un
/// service, seul un `Overlay` ancré à ce navigateur racine peut en fournir
/// un).
final GlobalKey<NavigatorState> rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _apprenantShellKey =
    GlobalKey<NavigatorState>(debugLabel: 'apprenantShell');
final GlobalKey<NavigatorState> _enseignantShellKey =
    GlobalKey<NavigatorState>(debugLabel: 'enseignantShell');

/// Instance unique du routeur — importée par `main.dart` (MaterialApp.router)
/// et par tout code ayant besoin de naviguer sans `BuildContext`
/// (ex. `AuthInterceptor.onSessionExpired`).
final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: AppPath.splash,
  refreshListenable: authState,
  redirect: redirect,
  errorBuilder: (context, state) => const NotFoundPage(),
  routes: [
    GoRoute(
      path: AppPath.splash,
      name: AppRoute.splash,
      builder: (context, state) => const SplashPage(),
    ),
    GoRoute(
      path: AppPath.onboarding,
      name: AppRoute.onboarding,
      builder: (context, state) => const OnboardingPage(),
    ),
    GoRoute(
      path: AppPath.login,
      name: AppRoute.login,
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: AppPath.register,
      name: AppRoute.register,
      builder: (context, state) => const RegisterPage(),
    ),
    GoRoute(
      path: AppPath.forgotPassword,
      name: AppRoute.forgotPassword,
      builder: (context, state) => const ForgotPasswordPage(),
    ),
    GoRoute(
      path: AppPath.forbidden,
      name: AppRoute.forbidden,
      builder: (context, state) => const ForbiddenPage(),
    ),
    GoRoute(
      path: AppPath.notFound,
      name: AppRoute.notFound,
      builder: (context, state) => const NotFoundPage(),
    ),
    GoRoute(
      path: AppPath.designSystem,
      name: AppRoute.designSystem,
      builder: (context, state) => const DesignSystemPage(),
    ),

    // ── Partagé (apprenant + enseignant) ───────────────────────────────
    GoRoute(
      path: AppPath.profile,
      name: AppRoute.profile,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const ProfilPage(),
    ),
    GoRoute(
      path: AppPath.profileEdit,
      name: AppRoute.profileEdit,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const EditProfilePage(),
    ),
    GoRoute(
      path: AppPath.notifications,
      name: AppRoute.notifications,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const NotificationsPage(),
    ),
    GoRoute(
      path: AppPath.wallet,
      name: AppRoute.wallet,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const WalletPage(),
    ),
    GoRoute(
      path: AppPath.recharge,
      name: AppRoute.recharge,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const RechargePage(),
    ),
    GoRoute(
      path: AppPath.retrait,
      name: AppRoute.retrait,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const RetraitPage(),
    ),

    // ── Arbre apprenant : shell à onglets ────────────────────────────────
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          ApprenantShellPage(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          navigatorKey: _apprenantShellKey,
          routes: [
            GoRoute(
              path: AppPath.dashboardAccueil,
              name: AppRoute.dashboardAccueil,
              builder: (context, state) => const AccueilPage(),
            ),
          ],
        ),
        StatefulShellBranch(routes: [
          GoRoute(
            path: AppPath.dashboardCursus,
            name: AppRoute.dashboardCursus,
            builder: (context, state) => const CursusPage(),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: AppPath.dashboardConcours,
            name: AppRoute.dashboardConcours,
            builder: (context, state) => const ConcoursPage(),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: AppPath.dashboardFormations,
            name: AppRoute.dashboardFormations,
            builder: (context, state) => const FormationsPage(),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: AppPath.dashboardOlympiades,
            name: AppRoute.dashboardOlympiades,
            builder: (context, state) => const OlympiadesPage(),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: AppPath.dashboardDevoirs,
            name: AppRoute.dashboardDevoirs,
            builder: (context, state) =>
                const DevoirsPage(estEnseignantPrincipal: false),
          ),
        ]),
      ],
    ),

    // ── Apprenant : plein écran (navigateur racine, masque la barre du bas) ──
    GoRoute(
      path: AppPath.repetiteurs,
      name: AppRoute.repetiteurs,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const RepetiteursPage(),
    ),
    GoRoute(
      path: AppPath.settings,
      name: AppRoute.settings,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const SettingsPage(),
    ),
    GoRoute(
      path: AppPath.coursDetail,
      name: AppRoute.coursDetail,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) {
        final q = state.uri.queryParameters;
        return CoursDetailTabs(
          coursId: state.pathParameters['coursId']!,
          titre: _str(q['titre']),
          coursColor: _int(q['coursColor'], 0xFF2884A0),
          isPremium: _bool(q['isPremium'], true),
          initialTab: _int(q['tab'], 0),
          scrollToQuestionId: _intOrNull(q['scrollToQuestionId']),
          moduleId: _intOrNull(q['moduleId']),
          leconId: _intOrNull(q['leconId']),
        );
      },
    ),
    GoRoute(
      path: AppPath.leconDetail,
      name: AppRoute.leconDetail,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) {
        final q = state.uri.queryParameters;
        return DetailLeconPage(
          leconId: _int(state.pathParameters['leconId']),
          coursId: _int(state.pathParameters['coursId']),
          coursTitre: _str(q['coursTitre']),
          coursColor: _int(q['coursColor'], 0xFF2884A0),
          estAccessible: _bool(q['isPremium'], true),
        );
      },
    ),
    GoRoute(
      path: AppPath.leconLecture,
      name: AppRoute.leconLecture,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) {
        final q = state.uri.queryParameters;
        return LectureLeconPage(
          leconId: _int(state.pathParameters['leconId']),
          coursId: _int(state.pathParameters['coursId']),
          coursTitre: _str(q['coursTitre']),
          coursColor: _int(q['coursColor'], 0xFF2884A0),
        );
      },
    ),
    GoRoute(
      path: AppPath.exercicePasser,
      name: AppRoute.exercicePasser,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) {
        final q = state.uri.queryParameters;
        return PasserExercicePage(
          exerciceId: _int(state.pathParameters['exerciceId']),
          coursId: _intOrNull(q['coursId']),
          coursTitre: _str(q['coursTitre']),
        );
      },
    ),
    GoRoute(
      path: AppPath.exerciceResultat,
      name: AppRoute.exerciceResultat,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) {
        final q = state.uri.queryParameters;
        return ResultatExercicePage(
          exerciceId: _int(state.pathParameters['exerciceId']),
          exerciceTitre: _str(q['exerciceTitre']),
          coursId: _intOrNull(q['coursId']),
          coursTitre: _str(q['coursTitre']),
          rangGagne: _boolOrNull(q['rangGagne']),
          ancienRang: _intOrNull(q['ancienRang']),
          nouveauRang: _intOrNull(q['nouveauRang']),
        );
      },
    ),
    GoRoute(
      path: AppPath.devoirComposer,
      name: AppRoute.devoirComposer,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) {
        final q = state.uri.queryParameters;
        return ComposerDevoirPage(
          devoirId: _int(state.pathParameters['devoirId']),
          titre: _str(q['titre']),
          dureeMin: _int(q['dureeMin'], 60),
          noteSur: _int(q['noteSur'], 20),
          typeCorrection: q['typeCorrection'],
        );
      },
    ),
    GoRoute(
      path: AppPath.devoirResultat,
      name: AppRoute.devoirResultat,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) {
        final q = state.uri.queryParameters;
        return ResultatDevoirPage(
          devoirId: _int(state.pathParameters['devoirId']),
          titre: _str(q['titre']),
          coursId: _intOrNull(q['coursId']),
          coursTitre: q['coursTitre'],
        );
      },
    ),
    GoRoute(
      path: AppPath.olympiadeInscription,
      name: AppRoute.olympiadeInscription,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) {
        final q = state.uri.queryParameters;
        final now = DateTime.now();
        return OlympiadeInscriptionPage(
          olympiadeId: _int(state.pathParameters['olympiadeId']),
          titre: _str(q['titre']),
          reglement: _str(q['reglement']),
          prixDesc: _str(q['prixDesc']),
          datDebut: DateTime.tryParse(q['datDebut'] ?? '') ?? now,
          datFin: DateTime.tryParse(q['datFin'] ?? '') ?? now,
          prixParticipation: _int(q['prixParticipation'], 0),
        );
      },
    ),
    GoRoute(
      path: AppPath.olympiadeClassement,
      name: AppRoute.olympiadeClassement,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => ClassementOlympiadePage(
        olympiadeId: _int(state.pathParameters['olympiadeId']),
        titre: _str(state.uri.queryParameters['titre']),
      ),
    ),
    GoRoute(
      path: AppPath.departementClassement,
      name: AppRoute.departementClassement,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => ClassementDepartementPage(
        departementId: _int(state.pathParameters['departementId']),
        departementNom: _str(state.uri.queryParameters['departementNom']),
      ),
    ),
    GoRoute(
      path: AppPath.formationDetail,
      name: AppRoute.formationDetail,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => FormationDetailPage(
        formationId: _int(state.pathParameters['formationId']),
        deptPrecharge: state.extra as DepartementItem?,
      ),
    ),
    GoRoute(
      path: AppPath.concoursDetail,
      name: AppRoute.concoursDetail,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => ConcoursDetailPage(
        concoursId: _int(state.pathParameters['concoursId']),
        deptPrecharge: state.extra as DepartementItem?,
      ),
    ),
    GoRoute(
      path: AppPath.paiement,
      name: AppRoute.paiement,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) {
        final q = state.uri.queryParameters;
        return PaiementPage(
          type: PaiementType.values.byName(
              q['type'] ?? PaiementType.rechargeWallet.name),
          titre: _str(q['titre']),
          montant: _int(q['montant']),
          departementId: _intOrNull(q['departementId']),
          olympiadeId: _intOrNull(q['olympiadeId']),
          montantPresentiel: _intOrNull(q['montantPresentiel']),
          isCursus: _bool(q['isCursus']),
          isHybride: _bool(q['isHybride']),
          isFormation: _bool(q['isFormation']),
          montantAnnuel: _intOrNull(q['montantAnnuel']),
          badge: q['badge'],
          ancienPrixMensuel: _intOrNull(q['ancienPrixMensuel']),
        );
      },
    ),
    GoRoute(
      path: AppPath.iaChat,
      name: AppRoute.iaChat,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) {
        final q = state.uri.queryParameters;
        final extra = state.extra as Map<String, dynamic>?;
        return YekiIAChatPage(
          coursId: _int(state.pathParameters['coursId']),
          coursTitre: _str(q['coursTitre']),
          messageInitial: q['messageInitial'],
          sourceInitiale: _str(q['sourceInitiale'], 'libre'),
          sourceId: _intOrNull(q['sourceId']),
          sourceTitreInit: _str(q['sourceTitreInit']),
          initialImage: extra?['initialImage'],
          initialAudio: extra?['initialAudio'],
        );
      },
    ),
    GoRoute(
      path: AppPath.forumQuestionDetail,
      name: AppRoute.forumQuestionDetail,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => DetailQuestionForumPage(
        questionId: _int(state.pathParameters['questionId']),
        question: state.extra as QForum?,
        coursColor: _intOrNull(state.uri.queryParameters['coursColor']),
      ),
    ),

    // ── Arbre enseignant : shell à onglets ──────────────────────────────
    GoRoute(
      // Alias : redirige toujours vers le dashboard concret du rôle
      // courant (guards.homePathForRole) — jamais rendu directement.
      path: AppPath.enseignantDashboard,
      name: AppRoute.enseignantDashboard,
      redirect: (context, state) => homePathForRole(authState.value.role),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          EnseignantShellPage(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          navigatorKey: _enseignantShellKey,
          routes: [
            GoRoute(
              path: AppPath.enseignantAdmin,
              name: AppRoute.enseignantAdmin,
              builder: (context, state) => const AdminGeneralPage(),
            ),
            GoRoute(
              path: AppPath.enseignantCoordination,
              name: AppRoute.enseignantCoordination,
              builder: (context, state) => const EnseignantAdminDashboardPage(),
            ),
            GoRoute(
              path: AppPath.enseignantCadre,
              name: AppRoute.enseignantCadre,
              builder: (context, state) => const CadreDashboardPage(),
            ),
            GoRoute(
              path: AppPath.enseignantPrincipal,
              name: AppRoute.enseignantPrincipal,
              builder: (context, state) => const DashboardPrincipalPage(),
            ),
            GoRoute(
              path: AppPath.enseignantSecondaire,
              name: AppRoute.enseignantSecondaire,
              builder: (context, state) => const SecondaireDashboardPage(),
            ),
            // Nichée ici comme les 5 autres rôles (même chrome partagé,
            // demande explicite) — nom/chemin de route inchangés,
            // `homePathForRole('service_client')` continue de fonctionner
            // à l'identique.
            GoRoute(
              path: AppPath.serviceClientDashboard,
              name: AppRoute.serviceClientDashboard,
              builder: (context, state) => const ServiceClientDashboardPage(),
            ),
          ],
        ),
        StatefulShellBranch(routes: [
          GoRoute(
            path: AppPath.enseignantHistorique,
            name: AppRoute.enseignantHistorique,
            builder: (context, state) => const HistoriquePage(),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: AppPath.enseignantProfil,
            name: AppRoute.enseignantProfil,
            builder: (context, state) => const ProfilPage(),
          ),
        ]),
      ],
    ),

    // ── Enseignant : plein écran ──────────────────────────────────────────
    GoRoute(
      path: AppPath.coursDetailEnseignant,
      name: AppRoute.coursDetailEnseignant,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) {
        final q = state.uri.queryParameters;
        return DetailCoursEnseignantPage(
          coursId: state.pathParameters['coursId']!,
          titre: _str(q['titre']),
          estEnseignantPrincipal: _bool(q['estEnseignantPrincipal']),
          role: roleEnseignantFromBackend(authState.value.role),
          courseColor: Color(_int(q['courseColor'], 0xFF2884A0)),
        );
      },
    ),
    GoRoute(
      path: AppPath.devoirGererEnseignant,
      name: AppRoute.devoirGererEnseignant,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) {
        final q = state.uri.queryParameters;
        return DevoirDetailPage(
          devoirId: _int(state.pathParameters['devoirId']),
          coursId: _int(q['coursId']),
          coursTitre: _str(q['coursTitre']),
        );
      },
    ),
    GoRoute(
      path: AppPath.adminDepartementDetail,
      name: AppRoute.adminDepartementDetail,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) {
        final q = state.uri.queryParameters;
        return DepartementDetailPage(
          departementId: _int(state.pathParameters['departementId']),
          departementNom: _str(q['departementNom']),
          parcoursNom: _str(q['parcoursNom']),
        );
      },
    ),
    GoRoute(
      path: AppPath.adminParcoursDetail,
      name: AppRoute.adminParcoursDetail,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) {
        final q = state.uri.queryParameters;
        return ParcoursDetailPage(
          parcoursId: _int(state.pathParameters['parcoursId']),
          parcoursNom: _str(q['parcoursNom']),
          parcoursType: _str(q['parcoursType']),
        );
      },
    ),
    GoRoute(
      path: AppPath.coordinationDepartementDetail,
      name: AppRoute.coordinationDepartementDetail,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) {
        final q = state.uri.queryParameters;
        return DepartementDetailPage(
          departementId: _int(state.pathParameters['departementId']),
          departementNom: _str(q['departementNom']),
          parcoursNom: _str(q['parcoursNom']),
        );
      },
    ),
    GoRoute(
      path: AppPath.cadreDepartementDetail,
      name: AppRoute.cadreDepartementDetail,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) {
        final q = state.uri.queryParameters;
        return DetailDepartementPage(
          departementId: _int(state.pathParameters['departementId']),
          departementNom: _str(q['departementNom']),
        );
      },
    ),
    GoRoute(
      path: AppPath.cadreGestionDemandes,
      name: AppRoute.cadreGestionDemandes,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => GestionDemandesPage(
        departementId: _int(state.pathParameters['departementId']),
        departementNom: _str(state.uri.queryParameters['departementNom']),
      ),
    ),
  ],
);
