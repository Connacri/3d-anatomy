import 'package:flutter/material.dart';

enum AppLanguage { fr, en }

class AppStrings {
  const AppStrings(this.language);
  final AppLanguage language;

  String get appName => 'Zenasni Kamel Professeur Anatomy';
  String get atlas => language == AppLanguage.fr ? 'Atlas anatomique 3D' : '3D Anatomy Atlas';
  String get search => language == AppLanguage.fr ? 'Rechercher une structure' : 'Search a structure';
  String get systems => language == AppLanguage.fr ? 'Systèmes anatomiques' : 'Anatomical systems';
  String get selected => language == AppLanguage.fr ? 'Structure sélectionnée' : 'Selected structure';
  String get tapToSelect => language == AppLanguage.fr ? 'Touchez une structure pour la sélectionner' : 'Tap a structure to select it';
  String get opacity => language == AppLanguage.fr ? 'Transparence' : 'Opacity';
  String get reset => language == AppLanguage.fr ? 'Réinitialiser' : 'Reset';
  String get sources => language == AppLanguage.fr ? 'Sources scientifiques' : 'Scientific sources';
  String get about => language == AppLanguage.fr ? 'À propos' : 'About';
  String get noResults => language == AppLanguage.fr ? 'Aucun résultat' : 'No results';
  String get allStructures => language == AppLanguage.fr ? 'Toutes les structures' : 'All structures';
  String get available3d => language == AppLanguage.fr ? '3D disponible' : '3D available';
  String get catalogOnly => language == AppLanguage.fr ? 'Catalogue uniquement' : 'Catalog only';
  String get male => language == AppLanguage.fr ? 'Homme' : 'Male';
  String get female => language == AppLanguage.fr ? 'Femme' : 'Female';
  String get anatomyData => language == AppLanguage.fr ? 'Données anatomiques' : 'Anatomy data';
  String get offlineNote => language == AppLanguage.fr ? 'Les modèles sont chargés à la demande pour garder l’application fluide.' : 'Models are loaded on demand to keep the application responsive.';
  String get disclaimer => language == AppLanguage.fr ? 'Application éducative. Elle ne constitue pas un dispositif médical et ne remplace pas un professionnel de santé.' : 'Educational application. It is not a medical device and does not replace a healthcare professional.';
}
