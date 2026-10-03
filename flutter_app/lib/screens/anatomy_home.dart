import 'package:flutter/material.dart';
import 'package:interactive_3d/interactive_3d.dart';

import '../data/anatomy_repository.dart';

class AnatomyHome extends StatefulWidget {
  const AnatomyHome({super.key});
  @override
  State<AnatomyHome> createState() => _AnatomyHomeState();
}

class _AnatomyHomeState extends State<AnatomyHome> {
  final _repository = AnatomyRepository();
  final _viewerController = Interactive3dController();

  Map<String, List<String>> _systemsData = {};
  Map<String, dynamic> _definitions = {};
  String _system = 'skeletal';
  String? _selectedCanonical;
  String? _selectedNode;
  double _opacity = 1.0;
  bool _loadingData = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final systems = await _repository.loadSystems();
      final definitions = await _repository.loadDefinitions();
      if (!mounted) return;
      setState(() {
        _systemsData = systems;
        _definitions = definitions;
        _loadingData = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingData = false;
        _error = error.toString();
      });
    }
  }

  void _changeSystem(String id) {
    if (id == _system) return;
    setState(() {
      _system = id;
      _selectedCanonical = null;
      _selectedNode = null;
      _opacity = 1.0;
    });
  }

  String _definitionFor(String? canonical) {
    if (canonical == null) return '';
    final value = _definitions[canonical];
    if (value is String) return value;
    if (value is Map<String, dynamic>) {
      return (value['en'] ?? value['definition'] ?? value['text'] ?? '').toString();
    }
    return '';
  }

  Future<void> _applyOpacity() async {
    final node = _selectedNode;
    if (node == null) return;
    await _viewerController.setEntityMaterial(
      name: node,
      color: [1.0, 1.0, 1.0, _opacity],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingData) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('3D Anatomy Atlas')),
        body: Center(child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_error!, textAlign: TextAlign.center),
        )),
      );
    }

    final names = _systemsData[_system] ?? const <String>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('3D Anatomy Atlas'),
        actions: [
          IconButton(
            tooltip: 'Reset materials',
            onPressed: () => _viewerController.resetAllMaterialOverrides(),
            icon: const Icon(Icons.layers_clear_outlined),
          ),
          IconButton(
            tooltip: 'Reset camera',
            onPressed: () => _viewerController.setCameraZoomLevel(1.0),
            icon: const Icon(Icons.center_focus_strong),
          ),
        ],
      ),
      drawer: _buildSystemsDrawer(),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: const Color(0xFF0A1018),
              child: Interactive3d(
                key: ValueKey(_system),
                controller: _viewerController,
                modelUrl: _repository.modelUrl(_system),
                defaultZoom: 1.0,
                solidBackgroundColor: const [0.02, 0.04, 0.07, 1.0],
                selectionColor: const [0.20, 0.65, 1.0, 1.0],
                backgroundColor: const Color(0xFF0A1018),
                loadingWidget: const Center(child: CircularProgressIndicator()),
                onSelectionChanged: (entities) {
                  if (entities.isEmpty) {
                    setState(() {
                      _selectedCanonical = null;
                      _selectedNode = null;
                      _opacity = 1.0;
                    });
                    return;
                  }
                  final entity = entities.last;
                  final canonical = _repository.matchCanonicalName(entity.name, names);
                  setState(() {
                    _selectedNode = entity.name;
                    _selectedCanonical = canonical ?? entity.name;
                    _opacity = 1.0;
                  });
                },
              ),
            ),
          ),
          _buildDetailsPanel(),
        ],
      ),
    );
  }

  Widget _buildSystemsDrawer() {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Text('Anatomical systems',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                children: AnatomyRepository.systems.entries.map((entry) {
                  final count = _systemsData[entry.key]?.length ?? 0;
                  return ListTile(
                    selected: entry.key == _system,
                    leading: const Icon(Icons.account_tree_outlined),
                    title: Text(entry.value),
                    subtitle: Text(count.toString() + ' structures'),
                    onTap: () {
                      Navigator.pop(context);
                      _changeSystem(entry.key);
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsPanel() {
    final selected = _selectedCanonical;
    final definition = _definitionFor(selected);
    return Material(
      color: const Color(0xFF0E1621),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (selected == null)
                const Text('Tap an anatomical structure',
                  style: TextStyle(fontWeight: FontWeight.w600))
              else ...[
                Text(_repository.displayName(selected),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                if (definition.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(definition, maxLines: 3, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70)),
                ],
                const SizedBox(height: 8),
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
