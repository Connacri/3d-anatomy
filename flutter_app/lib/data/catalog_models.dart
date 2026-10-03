class AnatomyStructure {
  const AnatomyStructure({
    required this.id, required this.nameEn, required this.nameFr,
    required this.system, required this.sex, required this.source,
    this.latin, this.conceptId, this.meshFile, this.meshAvailable = false,
    this.descriptionEn, this.descriptionFr,
  });
  final String id, nameEn, nameFr, system, sex, source;
  final String? latin, conceptId, meshFile, descriptionEn, descriptionFr;
  final bool meshAvailable;
  String get searchText => '${nameEn} ${nameFr} ${latin ?? ''} ${conceptId ?? ''} ${system} ${source}'.toLowerCase();
}

class AnatomySourceInfo {
  const AnatomySourceInfo({
    required this.id, required this.titleEn, required this.titleFr,
    required this.url, required this.license, required this.structureCount,
    required this.noteEn, required this.noteFr,
  });
  final String id, titleEn, titleFr, url, license, noteEn, noteFr;
  final int structureCount;
}
