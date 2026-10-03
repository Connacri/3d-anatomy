import 'dart:convert';
import 'package:http/http.dart' as http;

class AnatomyRepository {
  static const String rawBase =
      'https://raw.githubusercontent.com/Connacri/3d-anatomy/master/public';

  static const systems = <String, String>{
    'skeletal': 'Skeletal',
    'muscular': 'Muscular',
    'joints': 'Joints',
    'cardiovascular': 'Cardiovascular',
    'lymphatic': 'Lymphatic',
    'nervous': 'Nervous',
    'visceral': 'Visceral',
  };

  Future<Map<String, List<String>>> loadSystems() async {
    final response = await http.get(Uri.parse('$rawBase/data/systems.json'));
    if (response.statusCode != 200) {
      throw Exception('Unable to load anatomy index (${response.statusCode})');
    }
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return decoded.map(
      (key, value) => MapEntry(
        key,
        (value as List).map((item) => item.toString()).toList(growable: false),
      ),
    );
  }

  Future<Map<String, dynamic>> loadDefinitions() async {
    final response =
        await http.get(Uri.parse('$rawBase/data/definitions.json'));
    if (response.statusCode != 200) return const {};
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  String modelUrl(String systemId) => '$rawBase/models/$systemId.glb';

  static String normalized(String value) => value
      .toLowerCase()
      .replaceAll(RegExp(r'[.\\s\\-()]'), '')
      .replaceAll(RegExp(r'[^a-z0-9]'), '');

  String? matchCanonicalName(String nodeName, List<String> canonicalNames) {
    final target = normalized(nodeName);
    for (final name in canonicalNames) {
      if (normalized(name) == target) return name;
    }
    return null;
  }

  String displayName(String name) {
    final clean = name.replaceFirst(RegExp(r'^\\((.*)\\)$'), r'$1');
    if (clean.endsWith('.l')) return '${clean.substring(0, clean.length - 2)} (left)';
    if (clean.endsWith('.r')) return '${clean.substring(0, clean.length - 2)} (right)';
    return clean;
  }
}
