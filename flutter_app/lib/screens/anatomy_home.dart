import 'dart:async';
import 'package:flutter/material.dart';
import 'package:interactive_3d/interactive_3d.dart';
import '../core/app_localization.dart';
import '../data/anatomy_catalog_repository.dart';
import '../data/anatomy_repository.dart';
import '../data/catalog_models.dart';
import 'about_screen.dart';

class AnatomyHome extends StatefulWidget {
  const AnatomyHome({super.key});
  @override
  State<AnatomyHome> createState() => _AnatomyHomeState();
}

class _AnatomyHomeState extends State<AnatomyHome> {
  final _repository = AnatomyRepository();
  final _catalog = AnatomyCatalogRepository();
  final _viewerController = Interactive3dController();
  final _searchController = TextEditingController();

  Map<String, List<String>> _systemsData = {};
  Map<String, dynamic> _definitions = {};
  AppLanguage _language = AppLanguage.fr;
  String _system = 'skeletal';
  bool _female = false;
  bool _loadingData = true;
  bool _searching = false;
  String? _error;
  String? _selectedCanonical;
  String? _selectedNode;
  double _opacity = 1.0;
  List<AnatomyStructure> _results = const [];

  static const _male3dSystems = {
    'skeletal','muscular','articular','cardiovascular','lymphatic','nervous',
    'digestive','respiratory','endocrine','renal','reproductive','visceral','regional',
  };
  static const _female3dSystems = {
    'skeletal','cardiovascular','digestive','lymphatic','renal','reproductive','integumentary',
  };

  @override
  void initState() { super.initState(); _loadData(); }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final systems = await _repository.loadSystems();
      final definitions = await _repository.loadDefinitions();
      // The large merged catalog is loaded lazily when Search is opened.
      if (!mounted) return;
      setState(() {
        _systemsData = systems;
        _definitions = definitions;
        _loadingData = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() { _loadingData = false; _error = error.toString(); });
    }
  }

  bool _systemHas3d(String system) =>
      (_female ? _female3dSystems : _male3dSystems).contains(system);

  void _changeSystem(String id) {
    if (!_systemHas3d(id)) return;
    setState(() {
      _system = id;
      _selectedCanonical = null;
      _selectedNode = null;
      _opacity = 1.0;
    });
  }

  void _changeSex(bool female) {
    setState(() {
      _female = female;
      if (!_systemHas3d(_system)) _system = 'skeletal';
      _selectedCanonical = null;
      _selectedNode = null;
    });
  }

  Future<void> _runSearch(String value) async {
    setState(() => _searching = true);
    final results = await _catalog.search(value, sex: _female ? 'female' : 'male');
    if (!mounted) return;
    setState(() { _results = results; _searching = false; });
  }

  String _definitionFor(String? canonical) {
    if (canonical == null) return '';
    final value = _definitions[canonical];
    if (value is String) return value;
    if (value is Map<String, dynamic>) {
      return (value['fr'] ?? value['en'] ?? value['definition'] ?? value['text'] ?? '').toString();
    }
    return '';
  }

  Future<void> _applyOpacity() async {
    final node = _selectedNode;
    if (node == null) return;
    await _viewerController.setEntityMaterial(
      name: node, color: [1.0, 1.0, 1.0, _opacity],
    );
  }

  Future<void> _showSearch() async {
    _searchController.clear();
    _results = const [];
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0E1621),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => SafeArea(
          child: SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.82,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    autofocus: true,
                    onChanged: (value) async {
                      await _runSearch(value);
                      setModalState(() {});
                    },
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: AppStrings(_language).search,
                      suffixIcon: IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setModalState(() {});
                        },
                        icon: const Icon(Icons.clear),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _searching
                        ? const Center(child: CircularProgressIndicator())
                        : _results.isEmpty
                            ? Center(child: Text(AppStrings(_language).noResults))
                            : ListView.builder(
                                itemCount: _results.length,
                                itemBuilder: (context, index) {
                                  final item = _results[index];
                                  return ListTile(
                                    leading: Icon(item.meshAvailable
                                        ? Icons.view_in_ar_outlined
                                        : Icons.menu_book_outlined),
                                    title: Text(_language == AppLanguage.fr
                                        ? item.nameFr : item.nameEn),
                                    subtitle: Text(item.system + ' · ' + item.source),
                                    trailing: item.meshAvailable
                                        ? const Icon(Icons.play_arrow)
                                        : const Icon(Icons.info_outline),
                                    onTap: () {
                                      Navigator.pop(context);
                                      if (!item.meshAvailable) {
                                        _showSourceOnly(item);
                                        return;
                                      }
                                      _changeSex(item.sex == 'female');
                                      if (_systemHas3d(item.system)) _changeSystem(item.system);
                                      setState(() {
                                        _selectedCanonical = _language == AppLanguage.fr
                                            ? item.nameFr : item.nameEn;
                                        _selectedNode = item.nameEn;
                                      });
                                    },
                                  );
                                },
                              ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showSourceOnly(AnatomyStructure item) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_language == AppLanguage.fr ? item.nameFr : item.nameEn),
        content: Text(_language == AppLanguage.fr
            ? 'Cette structure est référencée dans le catalogue scientifique, mais aucun maillage natif local n’est actuellement associé à ce résultat.'
            : 'This structure exists in the scientific catalog, but no native local mesh is currently associated with this result.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppStrings(_language).reset),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings(_language);
    if (_loadingData) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: Text(s.appName)),
        body: Center(child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_error!, textAlign: TextAlign.center),
        )),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(s.atlas),
        actions: [
          IconButton(tooltip: s.search, onPressed: _showSearch, icon: const Icon(Icons.search)),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'fr') setState(() => _language = AppLanguage.fr);
              if (value == 'en') setState(() => _language = AppLanguage.en);
              if (value == 'about') {
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => AboutScreen(language: _language),
                ));
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'fr', child: Text('Français')),
              const PopupMenuItem(value: 'en', child: Text('English')),
              PopupMenuItem(value: 'about', child: Text(s.about)),
            ],
          ),
        ],
      ),
      drawer: _buildSystemsDrawer(),
      body: Column(
        children: [
          _buildBodySelector(s),
          Expanded(
            child: Container(
              color: const Color(0xFF0A1018),
              child: Interactive3d(
                key: ValueKey(_female.toString() + '_' + _system),
                controller: _viewerController,
                modelUrl: _repository.modelUrl(_system, female: _female),
                defaultZoom: 1.0,
                solidBackgroundColor: const [0.02, 0.04, 0.07, 1.0],
                selectionColor: const [0.20, 0.65, 1.0, 1.0],
                backgroundColor: const Color(0xFF0A1018),
                loadingWidget: const Center(child: CircularProgressIndicator()),
                onSelectionChanged: (entities) {
                  if (entities.isEmpty) {
                    setState(() { _selectedCanonical = null; _selectedNode = null; });
                    return;
                  }
                  final entity = entities.last;
                  setState(() {
                    _selectedNode = entity.name;
                    _selectedCanonical = entity.name;
                    _opacity = 1.0;
                  });
                },
              ),
            ),
          ),
          _buildDetailsPanel(s),
        ],
      ),
    );
  }

  Widget _buildBodySelector(AppStrings s) {
    return Material(
      color: const Color(0xFF0E1621),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: SegmentedButton<bool>(
          segments: [
            ButtonSegment(value: false, label: Text(s.male), icon: const Icon(Icons.man)),
            ButtonSegment(value: true, label: Text(s.female), icon: const Icon(Icons.woman)),
          ],
          selected: {_female},
          onSelectionChanged: (value) => _changeSex(value.first),
        ),
      ),
    );
  }

  Widget _buildSystemsDrawer() {
    final s = AppStrings(_language);
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(s.systems, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                children: AnatomyRepository.systems.entries.map((entry) {
                  final available = _systemHas3d(entry.key);
                  final count = _systemsData[entry.key]?.length ?? 0;
                  return ListTile(
                    enabled: available,
                    selected: entry.key == _system,
                    leading: Icon(available ? Icons.account_tree_outlined : Icons.lock_outline),
                    title: Text(entry.value),
                    subtitle: Text(available
                        ? count.toString() + ' structures · 3D'
                        : (_language == AppLanguage.fr ? 'Catalogue uniquement' : 'Catalog only')),
                    onTap: available ? () {
                      Navigator.pop(context);
                      _changeSystem(entry.key);
                    } : null,
                  );
                }).toList(),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(s.about),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => AboutScreen(language: _language),
                ));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsPanel(AppStrings s) {
    final selected = _selectedCanonical;
    final definition = _definitionFor(selected);
    return Material(
      color: const Color(0xFF0E1621),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (selected == null)
                Text(s.tapToSelect, style: const TextStyle(fontWeight: FontWeight.w600))
              else ...[
                Text(_repository.displayName(selected),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                if (definition.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(definition, maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white70)),
                  ),
                Row(
                  children: [
                    const Icon(Icons.opacity, size: 18),
                    Expanded(
                      child: Slider(
                        value: _opacity,
                        min: 0.15,
                        max: 1.0,
                        divisions: 17,
                        label: (_opacity * 100).round().toString() + '%',
                        onChanged: (value) {
                          setState(() => _opacity = value);
                          _applyOpacity();
                        },
                      ),
                    ),
                    Text((_opacity * 100).round().toString() + '%'),
                    IconButton(
                      tooltip: s.reset,
                      onPressed: () {
                        setState(() => _opacity = 1.0);
                        _viewerController.resetAllMaterialOverrides();
                      },
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
