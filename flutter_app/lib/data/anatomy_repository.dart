import 'dart:convert';
import 'package:http/http.dart' as http;

class AnatomyRepository {
  static const anatomyBase =
      'https://raw.githubusercontent.com/Connacri/Anatria-3D/main/public/anatomy';

  static const systems = <String, String>{
    'skeletal': 'Skeletal',
    'muscular': 'Muscular',
    'articular': 'Articular',
    'cardiovascular': 'Cardiovascular',
    'lymphatic': 'Lymphatic',
    'nervous': 'Nervous',
    'digestive': 'Digestive',
    'respiratory': 'Respiratory',
    'endocrine': 'Endocrine',
    'renal': 'Renal',
    'reproductive': 'Reproductive',
    'visceral': 'Visceral',
    'regional': 'Regional',
    'integumentary': 'Integumentary',
  };

  Map<String, List<String>>? _systemsCache;
  Map<String, dynamic>? _definitionsCache;

  Future<Map<String, List<String>>> loadSystems() async {
    if (_systemsCache != null) return _systemsCache!;
    final results = await Future.wait([
      _loadManifest(false),
      _loadManifest(true),
    ]);
    final map = <String, List<String>>{};
    for (final item in results) {
      for (final entry in item.entries) {
        map.putIfAbsent(entry.key, () => <String>[]).addAll(entry.value);
      }
    }
    _systemsCache =
        map.map((key, value) => MapEntry(key, value.toSet().toList()));
    return _systemsCache!;
  }

  Future<Map<String, dynamic>> loadDefinitions() async {
    if (_definitionsCache != null) return _definitionsCache!;
    try {
      final response = await http.get(Uri.parse(
        'https://raw.githubusercontent.com/Connacri/3d-anatomy/master/public/data/definitions.json',
      ));
      if (response.statusCode != 200) return _definitionsCache = {};
      return _definitionsCache =
          jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      return _definitionsCache = {};
    }
  }

  Future<Map<String, List<String>>> _loadManifest(bool female) async {
    try {
      final file = female ? 'manifest_female.json' : 'manifest.json';
      final response = await http.get(Uri.parse('$anatomyBase/$file'));
      if (response.statusCode != 200) return {};
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final organs = data['organs'];
      if (organs is! List) return {};
      final out = <String, List<String>>{};
      for (final raw in organs.whereType<Map<String, dynamic>>()) {
        final system =
            (raw['system'] ?? 'other').toString();
        final name =
            (raw['name_en'] ?? raw['name'] ?? raw['ta2_latin'] ?? '').toString();
        if (name.isNotEmpty) {
          out.putIfAbsent(system, () => <String>[]).add(name);
        }
      }
      return out;
    } catch (_) {
      return {};
    }
  }

  String modelUrl(String systemId, {required bool female}) {
    final suffix = female ? '_female' : '_male';
    final baseName = systemId == 'regional' ? 'regional' : systemId;
    return anatomyBase + '/' + baseName + suffix + '.glb';
  }

  String displayName(String name) {
    if (name.endsWith('.l')) {
      return name.substring(0, name.length - 2) + ' (left)';
    }
    if (name.endsWith('.r')) {
      return name.substring(0, name.length - 2) + ' (right)';
    }
    return name;
  }
}
