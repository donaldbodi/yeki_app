/// Profil de l'utilisateur connecté (`GET /profil/me/`,
/// `ProfilDetailSerializer` côté backend). Champs les plus larguement
/// utiles seulement — pas un miroir exhaustif du serializer, qui a
/// beaucoup plus de champs spécifiques par type d'utilisateur.
class UserProfile {
  final int id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String userType;
  final String? phone;
  final String? niveau;
  final String? ville;
  final String? avatar;

  /// `"YYYY-MM-DD"` — ajouté pour le tagging AdMob des mineurs
  /// (`tagForChildDirectedTreatment`/`tagForUnderAgeOfConsent`, CDC
  /// §8.3/§9.3), déjà collectée à l'inscription mais jamais relue jusqu'ici.
  final String? dateNaissance;

  const UserProfile({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.userType,
    this.phone,
    this.niveau,
    this.ville,
    this.avatar,
    this.dateNaissance,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'] as int? ?? 0,
        username: json['username'] as String? ?? '',
        email: json['email'] as String? ?? '',
        firstName: json['first_name'] as String? ?? '',
        lastName: json['last_name'] as String? ?? '',
        userType: json['user_type'] as String? ?? '',
        phone: json['phone'] as String?,
        niveau: json['niveau'] as String?,
        ville: json['ville'] as String?,
        avatar: json['avatar'] as String?,
        dateNaissance: json['date_naissance'] as String?,
      );
}
