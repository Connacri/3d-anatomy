import 'dart:convert';
import 'package:http/http.dart' as http;
import 'catalog_models.dart';

class AnatomyCatalogRepository {
  static const _anatria =
      'https://raw.githubusercontent.com/Connacri/Anatria-3D/main/public/anatomy';
  static const _humanAtlas =
      'https://raw.githubusercontent.com/Connacri/Human-Atlas/main/public/models';

  List<AnatomyStructure>? _cache;

  Future<List<AnatomyStructure>> loadCatalog() async {
    if (_cache != null) return _cache!;
    final results = await Future.wait([
      _loadAnatriaManifest(false),
      _loadAnatriaManifest(true),
      _loadHumanAtlas('atlas.json', 'male'),
      _loadHumanAtlas('atlas-female.json', 'female'),
    ]);
    final merged = <String, AnatomyStructure>{};
    for (final batch in results) {
      for (final item in batch) {
        final key = _dedupeKey(item);
        final old = merged[key];
        if (old == null ||
            (!old.meshAvailable && item.meshAvailable) ||
            (item.source == 'Anatria-3D' && old.source != 'Anatria-3D')) {
          merged[key] = item;
        }
      }
    }
    _cache = merged.values.toList(growable: false)
      ..sort((a, b) => a.nameEn.compareTo(b.nameEn));
    return _cache!;
  }

  Future<List<AnatomyStructure>> search(String query, {String? sex}) async {
    final all = await loadCatalog();
    final q = query.trim().toLowerCase();
    final candidates = all.where((x) => sex == null || x.sex == sex);
    if (q.isEmpty) return candidates.take(100).toList(growable: false);

    final tokens = q.split(RegExp(r'\s+')).where((x) => x.isNotEmpty);
    final scored = <MapEntry<int, AnatomyStructure>>[];
    for (final item in candidates) {
      final haystack = item.searchText;
      if (!tokens.every(haystack.contains)) continue;
      var score = 0;
      final en = item.nameEn.toLowerCase();
      final fr = item.nameFr.toLowerCase();
      if (en == q || fr == q) score += 1000;
      if (en.startsWith(q) || fr.startsWith(q)) score += 500;
      if (en.contains(q) || fr.contains(q)) score += 250;
      if (item.meshAvailable) score += 50;
      if (item.source == 'Anatria-3D') score += 25;
      scored.add(MapEntry(score, item));
    }
    scored.sort((a, b) {
      final s = b.key.compareTo(a.key);
      return s != 0 ? s : a.value.nameEn.compareTo(b.value.nameEn);
    });
    return scored.take(100).map((x) => x.value).toList(growable: false);
  }

  Future<List<AnatomyStructure>> _loadAnatriaManifest(bool female) async {
    final url = '\$_anatria/\${female ? 'manifest_female.json' : 'manifest.json'}';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) return const [];
      final json = jsonDecode(response.body);
      final organs = json is Map<String, dynamic> ? json['organs'] : null;
      if (organs is! List) return const [];
      return organs.whereType<Map<String, dynamic>>().map((o) {
        final name = (o['name_en'] ?? o['name'] ?? o['ta2_latin'] ?? 'Unknown').toString();
        final mesh = o['mesh_file']?.toString();
        return AnatomyStructure(
          id: 'anatria:\${o['organ_id'] ?? o['node'] ?? name}',
          nameEn: name,
          nameFr: _frenchName(name),
          latin: o['ta2_latin']?.toString(),
          conceptId: o['concept_id']?.toString(),
          system: (o['system'] ?? 'other').toString(),
          sex: female ? 'female' : 'male',
          source: 'Anatria-3D',
          meshFile: mesh,
          meshAvailable: mesh != null,
        );
      }).toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  Future<List<AnatomyStructure>> _loadHumanAtlas(String file, String sex) async {
    try {
      final response = await http.get(Uri.parse('\$_humanAtlas/\$file'));
      if (response.statusCode != 200) return const [];
      final json = jsonDecode(response.body);
      final parts = json is Map<String, dynamic> ? json['parts'] : null;
      if (parts is! List) return const [];
      return parts.whereType<Map<String, dynamic>>().map((p) {
        final name = (p['name'] ?? p['id'] ?? 'Unknown').toString();
        return AnatomyStructure(
          id: 'hra:\${p['id'] ?? name}',
          nameEn: name,
          nameFr: _frenchName(name),
          conceptId: p['conceptId']?.toString(),
          system: (p['system'] ?? 'other').toString(),
          sex: sex,
          source: 'Human Reference Atlas',
          meshAvailable: false,
          descriptionEn: '3D reference structure from the Human Reference Atlas.',
          descriptionFr: 'Structure 3D de référence issue du Human Reference Atlas.',
        );
      }).toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  String _dedupeKey(AnatomyStructure item) {
    if (item.conceptId != null && item.conceptId!.isNotEmpty) {
      return item.conceptId!.toLowerCase();
    }
    return '\${item.sex}:\${item.nameEn.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '')}';
  }

  String _frenchName(String value) => value;

  static const sources = <AnatomySourceInfo>[
    AnatomySourceInfo(
      id: 'anatria',
      titleEn: 'Anatria-3D / Z-Anatomy lineage',
      titleFr: 'Anatria-3D / lignée Z-Anatomy',
      url: 'https://github.com/Connacri/Anatria-3D',
      license: 'Atlas data: CC BY-SA 4.0 / CC BY 4.0',
      structureCount: 4698,
      noteEn: 'Detailed educational meshes and structured anatomical manifests.',
      noteFr: 'Maillages pédagogiques détaillés et manifestes anatomiques structurés.',
    ),
    AnatomySourceInfo(
      id: 'human-atlas',
      titleEn: 'Human Reference Atlas / HuBMAP',
      titleFr: 'Human Reference Atlas / HuBMAP',
      url: 'https://humanatlas.io/',
      license: 'CC BY 4.0 for referenced HRA data',
      structureCount: 4807,
      noteEn: 'Reference anatomy, organs, structures, cell types and biomarkers.',
      noteFr: 'Anatomie de référence, organes, structures, types cellulaires et biomarqueurs.',
    ),
    AnatomySourceInfo(
      id: 'fma',
      titleEn: 'Foundational Model of Anatomy',
      titleFr: 'Foundational Model of Anatomy',
      url: 'https://bioportal.bioontology.org/ontologies/FMA',
      license: 'See source terms and attribution',
      structureCount: 104721,
      noteEn: 'Large ontology for anatomical concepts and relationships.',
      noteFr: 'Grande ontologie des concepts et relations anatomiques.',
    ),
    AnatomySourceInfo(
      id: 'uberon',
      titleEn: 'Uberon Anatomy Ontology',
      titleFr: 'Uberon Anatomy Ontology',
      url: 'https://uberon.github.io/',
      license: 'CC BY 3.0',
      structureCount: 26735,
      noteEn: 'Cross-species anatomy ontology useful for concept mapping and relationships.',
      noteFr: 'Ontologie anatomique multi-espèces utile pour le mapping et les relations.',
    ),
    AnatomySourceInfo(
      id: 'fipat',
      titleEn: 'FIPAT / Terminologia Anatomica',
      titleFr: 'FIPAT / Terminologia Anatomica',
      url: 'https://ifaa.net/committees/anatomical-terminology-fipat/',
      license: 'Terminology reference; use under its terms',
      structureCount: 0,
      noteEn: 'International anatomical nomenclature reference.',
      noteFr: 'Référence internationale de nomenclature anatomique.',
    ),
  ];
}
