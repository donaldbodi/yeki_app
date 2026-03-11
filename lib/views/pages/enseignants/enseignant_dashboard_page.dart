import 'package:flutter/material.dart';
import 'package:yeki/views/pages/enseignants/cadre_dashboard_page.dart';
import 'package:yeki/views/pages/enseignants/interface_enseignant_page.dart';
import 'package:yeki/views/pages/enseignants/principal_dashboard_page.dart';
import 'package:yeki/views/pages/enseignants/secondaire_dashboard_page.dart';



class DashboardEnseignantPage extends StatelessWidget {
  final RoleEnseignant role;
  final String nomEnseignant;
  final String roleEnseignant;

  /// Données minimales:
  /// - role Cadre      -> List<Departement> : [{id, nom, cours:[{id, titre, enseignant_principal:{id, name}?}]}]
  /// - role Principal  -> List<Cours>       : [{id, titre, lecons_count? (int), enseignants_secondaires:[{id, name}]}]
  /// - role Secondaire -> List<Cours>       : [{id, titre, lecons_count?}]
  final List<dynamic>? extraInfo;

  const DashboardEnseignantPage({
    super.key,
    required this.role,
    required this.nomEnseignant,
    required this.roleEnseignant,
    this.extraInfo,
  });

  @override
  Widget build(BuildContext context) {
    switch (role) {
      case RoleEnseignant.enseignantCadre:
        return CadreDashboardPage( );

      case RoleEnseignant.enseignantPrincipal:
        return DashboardPrincipalPage(
          nomEnseignant: nomEnseignant,
          roleEnseignant: roleEnseignant,
          extraInfo: extraInfo,
        );

      case RoleEnseignant.enseignantSecondaire:
        return SecondaireDashboardPage();

      default:
        return const Scaffold(
          body: Center(
            child: Text("Interface non prévue pour ce rôle."),
          ),
        );
    }
  }
}
