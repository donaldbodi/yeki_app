/// Fuseau Africa/Douala — UTC+1 fixe, toute l'année (le Cameroun
/// n'observe pas l'heure d'été) — règle standing du projet (français,
/// fuseau Africa/Douala).
///
/// Décalage constant : pas besoin du paquet `timezone` (base IANA
/// complète) pour une seule zone à décalage fixe sans DST — une
/// `Duration` suffit et évite une dépendance lourde pour un besoin
/// simple.
class YkDoualaTime {
  YkDoualaTime._();

  static const Duration offset = Duration(hours: 1);

  /// Heure actuelle à Douala.
  static DateTime now() => DateTime.now().toUtc().add(offset);

  /// Convertit un instant UTC (ex. reçu du backend) en heure locale Douala.
  static DateTime fromUtc(DateTime utc) => utc.toUtc().add(offset);

  /// Convertit une heure locale Douala en UTC (ex. avant envoi au backend).
  static DateTime toUtcFromDouala(DateTime doualaLocal) => doualaLocal.subtract(offset);
}
