// Génère lib/core/network/api_endpoints.dart à partir du schéma OpenAPI
// exporté par drf_spectacular (GET /api/schema/ côté backend).
//
// Usage :
//   dart run tool/generate_endpoints.dart --file=chemin/vers/schema.yaml
//   dart run tool/generate_endpoints.dart --url=https://.../api/schema/
//   dart run tool/generate_endpoints.dart   (défaut : --url=ApiConstants.baseUrl + /schema/)
//
// Script de génération de code, pas du code applicatif : l'usage de
// `package:http` ici (pour --url) n'est pas concerné par la convention
// « http proscrit pour tout nouveau code » de api_client.dart, qui vise le
// code de l'application, pas l'outillage de développement.
//
// À relancer manuellement à chaque évolution du schéma backend — pas de
// build_runner, pas de dépendance Java/openapi_generator.

import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:yaml/yaml.dart';

const _defaultUrl = 'https://yeki.pythonanywhere.com/api/schema/';
const _outputPath = 'lib/core/network/api_endpoints.dart';

const _verbOrder = ['get', 'post', 'put', 'patch', 'delete'];

/// Suffixes que DRF/drf_spectacular ajoutent automatiquement à
/// `operationId` selon le verbe — on les retire car le nom de la méthode
/// Dart destination (get/post/...) porte déjà cette information.
/// Ordre important : les suffixes les plus longs/spécifiques d'abord
/// (`_partial_update` avant `_update`) pour ne pas laisser de résidu.
const _operationIdSuffixes = [
  '_partial_update',
  '_list',
  '_create',
  '_retrieve',
  '_update',
  '_destroy',
];

void main(List<String> args) async {
  String? filePath;
  String? url;
  for (final a in args) {
    if (a.startsWith('--file=')) filePath = a.substring('--file='.length);
    if (a.startsWith('--url=')) url = a.substring('--url='.length);
  }

  final String yamlText;
  if (filePath != null) {
    yamlText = File(filePath).readAsStringSync();
    stderr.writeln('Schéma lu depuis le fichier : $filePath');
  } else {
    final target = url ?? _defaultUrl;
    stderr.writeln('Récupération du schéma depuis : $target');
    final response = await http.get(Uri.parse(target));
    if (response.statusCode != 200) {
      stderr.writeln(
          'Échec de récupération du schéma (HTTP ${response.statusCode}).');
      exit(1);
    }
    yamlText = response.body;
  }

  final doc = loadYaml(yamlText) as YamlMap;
  final paths = doc['paths'] as YamlMap?;
  if (paths == null) {
    stderr.writeln('Aucune clé "paths" trouvée dans le schéma.');
    exit(1);
  }

  // resourceClass -> { memberName -> _Endpoint }
  final classes = <String, Map<String, _Endpoint>>{};
  var warnings = 0;

  paths.forEach((pathKey, pathItemRaw) {
    final pathTemplate = pathKey as String;
    final pathItem = pathItemRaw as YamlMap;

    final operations = <String, YamlMap>{};
    for (final verb in _verbOrder) {
      final op = pathItem[verb];
      if (op is YamlMap) operations[verb] = op;
    }
    if (operations.isEmpty) return;

    // Tag / classe de regroupement.
    String? tag;
    for (final verb in _verbOrder) {
      final tags = operations[verb]?['tags'];
      if (tags is YamlList && tags.isNotEmpty) {
        tag = tags.first.toString();
        break;
      }
    }
    tag ??= _firstPathSegment(pathTemplate) ?? 'misc';
    final className = '${_pascalCase(tag)}Endpoints';

    // Nom de membre, dérivé de operationId (nettoyé) ou, à défaut, du chemin.
    String? operationId;
    for (final verb in _verbOrder) {
      final id = operations[verb]?['operationId'];
      if (id is String && id.isNotEmpty) {
        operationId = id;
        break;
      }
    }
    String memberName;
    if (operationId != null) {
      memberName = _cleanOperationId(operationId);
    } else {
      memberName = _nameFromPath(pathTemplate);
      stderr.writeln(
          'AVERTISSEMENT : pas d\'operationId pour "$pathTemplate" — '
          'nom dérivé du chemin ("$memberName").');
      warnings++;
    }

    // Paramètres de chemin, dans l'ordre d'apparition, avec leur type.
    final paramNames = RegExp(r'\{(\w+)\}')
        .allMatches(pathTemplate)
        .map((m) => m.group(1)!)
        .toList();
    final paramTypes = <String, String>{};
    for (final name in paramNames) {
      paramTypes[name] =
          _paramType(name, pathItem, operations) ?? 'int'; // repli par défaut
    }

    final relativePath = pathTemplate.startsWith('/api/')
        ? pathTemplate.substring('/api'.length)
        : pathTemplate;

    final endpoint = _Endpoint(
      path: relativePath,
      paramNames: paramNames,
      paramTypes: paramTypes,
    );

    final members = classes.putIfAbsent(className, () => {});
    if (members.containsKey(memberName) &&
        members[memberName]!.path != endpoint.path) {
      // Collision réelle entre deux chemins distincts réduits au même nom.
      // Cas le plus fréquent : liste (sans paramètre) vs détail (avec un
      // paramètre de chemin) partageant le même operationId nettoyé —
      // dans ce cas, on suffixe "Detail" plutôt qu'un numéro opaque.
      String candidate;
      if (endpoint.paramNames.isNotEmpty &&
          members[memberName]!.paramNames.isEmpty) {
        candidate = '${memberName}Detail';
      } else if (endpoint.paramNames.isEmpty &&
          members[memberName]!.paramNames.isNotEmpty) {
        // Le membre déjà en place devient le détail, le nouveau prend le
        // nom "propre" (sans paramètre = liste, plus intuitif).
        members['${memberName}Detail'] = members[memberName]!;
        candidate = memberName;
      } else {
        var suffix = 2;
        candidate = '$memberName$suffix';
        while (members.containsKey(candidate)) {
          suffix++;
          candidate = '$memberName$suffix';
        }
      }
      stderr.writeln(
          'AVERTISSEMENT : collision de nom "$memberName" dans $className '
          '("${members[memberName]!.path}" vs "${endpoint.path}") — '
          'renommé en "$candidate".');
      warnings++;
      memberName = candidate;
    }
    members[memberName] = endpoint;
  });

  final buffer = StringBuffer();
  buffer.writeln('// ignore_for_file: non_constant_identifier_names');
  buffer.writeln('// (noms de paramètres = noms littéraux des placeholders');
  buffer.writeln('// OpenAPI, volontairement non renommés — voir plus bas.)');
  buffer.writeln('// GÉNÉRÉ — ne pas éditer à la main.');
  buffer.writeln('// Régénérer : dart run tool/generate_endpoints.dart');
  buffer.writeln('// Source : ${filePath ?? url ?? _defaultUrl}');
  buffer.writeln('// Généré le : ${DateTime.now().toIso8601String()}');
  buffer.writeln('//');
  buffer.writeln('// Chemins RELATIFS uniquement — ApiClient porte seul la');
  buffer.writeln('// base URL (ApiConstants.baseUrl) via Dio BaseOptions.');
  buffer.writeln('// Coexiste avec lib/core/constants/api_constants.dart');
  buffer.writeln('// (conservé pour les écrans pas encore migrés) : ce');
  buffer.writeln('// fichier est purement additif, consommé seulement par');
  buffer.writeln('// les Repositories de lib/repositories/.');
  buffer.writeln();

  final sortedClasses = classes.keys.toList()..sort();
  for (final className in sortedClasses) {
    buffer.writeln('class $className {');
    buffer.writeln('  $className._();');
    buffer.writeln();
    final members = classes[className]!;
    final sortedMembers = members.keys.toList()..sort();
    for (final memberName in sortedMembers) {
      final ep = members[memberName]!;
      if (ep.paramNames.isEmpty) {
        buffer.writeln(
            "  static const String $memberName = '${ep.path}';");
      } else {
        final params = ep.paramNames
            .map((p) => '${ep.paramTypes[p]} $p')
            .join(', ');
        var interpolated = ep.path;
        for (final p in ep.paramNames) {
          interpolated = interpolated.replaceAll('{$p}', '\$$p');
        }
        buffer.writeln(
            "  static String $memberName($params) => '$interpolated';");
      }
    }
    buffer.writeln('}');
    buffer.writeln();
  }

  File(_outputPath).writeAsStringSync(buffer.toString());
  stderr.writeln(
      '${sortedClasses.length} classe(s), '
      '${classes.values.fold<int>(0, (n, m) => n + m.length)} endpoint(s) '
      'écrits dans $_outputPath ($warnings avertissement(s)).');
}

class _Endpoint {
  final String path;
  final List<String> paramNames;
  final Map<String, String> paramTypes;
  _Endpoint({
    required this.path,
    required this.paramNames,
    required this.paramTypes,
  });
}

String? _firstPathSegment(String path) {
  final segments = path
      .split('/')
      .where((s) => s.isNotEmpty && !s.startsWith('{'))
      .toList();
  if (segments.isEmpty) return null;
  return segments.first == 'api' && segments.length > 1
      ? segments[1]
      : segments.first;
}

String _nameFromPath(String path) {
  final segments = path
      .split('/')
      .where((s) => s.isNotEmpty && !s.startsWith('{') && s != 'api')
      .toList();
  if (segments.isEmpty) return 'root';
  return _lowerCamelFromParts(segments.expand((s) => s.split('-')).toList());
}

String _cleanOperationId(String operationId) {
  var id = operationId;
  if (id.startsWith('api_')) id = id.substring('api_'.length);
  for (final suffix in _operationIdSuffixes) {
    if (id.endsWith(suffix)) {
      id = id.substring(0, id.length - suffix.length);
      break;
    }
  }
  final parts = id.split(RegExp(r'[_\-]')).where((s) => s.isNotEmpty).toList();
  if (parts.isEmpty) return 'unnamed';
  return _lowerCamelFromParts(parts);
}

String _lowerCamelFromParts(List<String> parts) {
  final buffer = StringBuffer(parts.first.toLowerCase());
  for (final part in parts.skip(1)) {
    if (part.isEmpty) continue;
    buffer.write(part[0].toUpperCase());
    buffer.write(part.substring(1).toLowerCase());
  }
  return buffer.toString();
}

String _pascalCase(String s) {
  final parts = s.split(RegExp(r'[_\-\s]')).where((p) => p.isNotEmpty);
  return parts
      .map((p) => p[0].toUpperCase() + p.substring(1).toLowerCase())
      .join();
}

/// Cherche le schéma d'un paramètre de chemin nommé [name] — d'abord au
/// niveau du path-item (paramètres partagés entre verbes), puis dans
/// chaque opération individuellement (repli).
String? _paramType(
  String name,
  YamlMap pathItem,
  Map<String, YamlMap> operations,
) {
  String? typeFromParamsList(dynamic paramsRaw) {
    if (paramsRaw is! YamlList) return null;
    for (final p in paramsRaw) {
      if (p is YamlMap && p['in'] == 'path' && p['name'] == name) {
        final type = p['schema']?['type'];
        return type == 'integer' ? 'int' : 'String';
      }
    }
    return null;
  }

  final atPathLevel = typeFromParamsList(pathItem['parameters']);
  if (atPathLevel != null) return atPathLevel;

  for (final op in operations.values) {
    final atOpLevel = typeFromParamsList(op['parameters']);
    if (atOpLevel != null) return atOpLevel;
  }
  return null;
}
