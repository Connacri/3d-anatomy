import 'package:flutter/material.dart';
import '../core/app_localization.dart';
import '../data/anatomy_catalog_repository.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key, required this.language});
  final AppLanguage language;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings(language);
    return Scaffold(
      appBar: AppBar(title: Text(s.about)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(s.appName, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(
            language == AppLanguage.fr
                ? 'Atlas 3D d’anatomie humaine pour l’étude, l’enseignement et l’exploration interactive.'
                : '3D human anatomy atlas for study, teaching and interactive exploration.',
            style: const TextStyle(fontSize: 16, color: Colors.white70),
          ),
          const SizedBox(height: 20),
          Text(
            language == AppLanguage.fr
                ? 'Projet : Zenasni Kamel — Professeur Anatomy. Objectif : réunir des structures anatomiques détaillées, une nomenclature rigoureuse et un visualiseur 3D fluide, tout en conservant les sources et leurs licences séparées.'
                : 'Project: Zenasni Kamel — Professeur Anatomy. Goal: combine detailed anatomical structures, rigorous nomenclature and a fluid 3D viewer while preserving each source and its licence.',
          ),
          const SizedBox(height: 20),
          Text(s.anatomyData, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ...AnatomyCatalogRepository.sources.map((source) => Card(
                child: ListTile(
                  title: Text(language == AppLanguage.fr ? source.titleFr : source.titleEn),
                  subtitle: Text(
                    '${source.license}\n${language == AppLanguage.fr ? source.noteFr : source.noteEn}\nStructures/références: ${source.structureCount}',
                  ),
                  isThreeLine: true,
                ),
              )),
          const SizedBox(height: 16),
          Text(s.disclaimer, style: const TextStyle(color: Colors.white60)),
        ],
      ),
    );
  }
}
