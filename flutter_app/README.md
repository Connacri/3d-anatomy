# Zenasni Kamel Professeur Anatomy — Flutter

Native Flutter anatomy application for Android and iOS.

## Product scope

This client is designed as a **lazy, bilingual (French/English) 3D anatomy atlas**:

- native GLB/GLTF rendering through `interactive_3d`;
- Google Filament on Android and SceneKit on iOS;
- rotate, pan, zoom and tap-to-select;
- runtime PBR material overrides;
- system-by-system model loading;
- male and female reference bodies where source geometry exists;
- unified search across Anatria-3D and Human Reference Atlas catalogs;
- English + French application interface;
- scientific-source and licence information in the About screen.

The renderer package itself supports network GLB/GLTF loading, selection, visibility groups, PBR overrides and adaptive Android rendering. The application therefore avoids a WebView and avoids loading every anatomical mesh at startup.

## Sources and coverage

The current catalog combines metadata from:

1. **Anatria-3D / Z-Anatomy lineage** — detailed educational GLBs and manifests.
2. **Human Reference Atlas / HuBMAP** — a much broader reference catalog, including structures that do not yet have a native GLB in this Flutter client.
3. **Foundational Model of Anatomy (FMA)** — used as a reference ontology/identifier source.
4. **FIPAT / Terminologia Anatomica** — international anatomical nomenclature reference.
5. **Wikidata** — planned controlled cross-language label layer because Wikidata structured data is CC0.

A search result marked **catalog only** is intentionally not presented as a 3D mesh. This prevents the application from inventing geometry for a concept that the currently selected source does not model.

## Lazy strategy

The app does not download the full anatomy catalog at startup.

- Core manifests required to build the first system list are small.
- The merged multi-source catalog is loaded only when Search is opened.
- Search results are limited to 100 ranked matches.
- Only the selected anatomical system's GLB is sent to the native renderer.
- Switching sex or system destroys the previous viewer instance, preventing several large scenes from remaining resident.
- Human Reference Atlas metadata is used as a catalog source; its custom chunked web renderer is not copied into the Flutter viewer.

## French / English

The interface is fully available in French and English.

For anatomical names, the application must not fabricate a French medical translation. Until a controlled French term is available from a source such as a validated terminology mapping, the canonical English/scientific name remains visible. The architecture is ready for a generated Wikidata/FMA French lexicon.

## Medical scope

This is an educational anatomy atlas, not a medical device and not a diagnostic or treatment system.

## Build

From `flutter_app/`:

    flutter pub get
    flutter analyze
    flutter run

Android release builds are produced by `.github/workflows/flutter-android.yml`.

## Attribution

Do not merge source geometries or licences blindly. Anatria-3D, Human Reference Atlas, BodyParts3D/Z-Anatomy and other datasets have different provenance and licensing terms. Keep their attribution with the corresponding dataset.
