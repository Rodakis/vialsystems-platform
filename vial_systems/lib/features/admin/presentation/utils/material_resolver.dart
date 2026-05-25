import 'package:flutter/foundation.dart';
import '../../../../core/providers/catalog_provider.dart';
import '../../../remito/domain/models/remito_model.dart';
import '../../../catalogs/domain/models/catalog_models.dart';

/// Generic helper to resolve any catalog field (Obra, Material, Transportista, Chofer).
String _resolveCatalogItem({
  required String? rawId,
  required List<dynamic> items,
  required String catalogName,
  required String Function(dynamic) getName,
  required String Function(dynamic) getId,
}) {
  if (rawId == null || rawId.trim().isEmpty) {
    return 'N/A';
  }

  final trimmedRaw = rawId.trim();

  // 1. Try exact ID match
  for (final item in items) {
    if (getId(item).trim() == trimmedRaw) {
      return getName(item);
    }
  }

  // 2. Try numeric comparison if rawId is numeric
  final isNumericRaw = RegExp(r'^\d+$').hasMatch(trimmedRaw);
  if (isNumericRaw) {
    for (final item in items) {
      final itemId = getId(item).trim();
      final isNumericItem = RegExp(r'^\d+$').hasMatch(itemId);
      if (isNumericItem && int.parse(itemId) == int.parse(trimmedRaw)) {
        return getName(item);
      }
    }

    // If it is numeric but not found in the catalog, it's a missing old ID
    debugPrint('WARNING: ID numérico viejo "$trimmedRaw" no encontrado en el catálogo de $catalogName.');
    return 'No encontrado';
  }

  // 3. If it's not a numeric ID, we assume it's the direct name
  return rawId;
}

/// Resolves the human-readable obra name.
String resolveObraName(String? obraId, CatalogProvider catalogs) {
  return _resolveCatalogItem(
    rawId: obraId,
    items: catalogs.obras,
    catalogName: 'Obras',
    getId: (item) => (item as ObraModel).id,
    getName: (item) => (item as ObraModel).nombre,
  );
}

/// Resolves the human-readable material name from just a raw material ID string.
String resolveMaterialNameFromId(String? materialId, CatalogProvider catalogs) {
  return _resolveCatalogItem(
    rawId: materialId,
    items: catalogs.materiales,
    catalogName: 'Materiales',
    getId: (item) => (item as MaterialModel).id,
    getName: (item) => (item as MaterialModel).nombre,
  );
}

/// Resolves the human-readable material name from the remito's material information.
String resolveMaterialName(RemitoModel remito, CatalogProvider catalogs) {
  return resolveMaterialNameFromId(remito.materialId, catalogs);
}

/// Resolves the human-readable transportista name.
String resolveTransportistaName(String? transportistaId, CatalogProvider catalogs) {
  return _resolveCatalogItem(
    rawId: transportistaId,
    items: catalogs.transportistas,
    catalogName: 'Transportistas',
    getId: (item) => (item as TransportistaModel).id,
    getName: (item) => (item as TransportistaModel).nombre,
  );
}

/// Resolves the human-readable chofer name.
String resolveChoferName(String? choferId, CatalogProvider catalogs) {
  return _resolveCatalogItem(
    rawId: choferId,
    items: catalogs.choferes,
    catalogName: 'Choferes',
    getId: (item) => (item as ChoferModel).id,
    getName: (item) => (item as ChoferModel).nombre,
  );
}

/// Robustly checks if a remito matches the selected material filter.
bool matchesMaterialFilter(RemitoModel remito, String? selectedMaterial, CatalogProvider catalogs) {
  // If no material filter is selected (empty or "Todos"), it always matches.
  if (selectedMaterial == null ||
      selectedMaterial.isEmpty ||
      selectedMaterial.toLowerCase() == 'todos' ||
      selectedMaterial.toLowerCase() == 'todas') {
    return true;
  }

  final remitoRaw = remito.materialId;
  final resolvedName = resolveMaterialName(remito, catalogs);
  final trimmedSelected = selectedMaterial.trim();

  // Retrieve selected material's name from standard catalog
  String? selectedCatalogName = resolveMaterialNameFromId(trimmedSelected, catalogs);
  if (selectedCatalogName == 'No encontrado' || selectedCatalogName == 'N/A') {
    selectedCatalogName = null;
  }

  bool isMatch = false;

  // 1. Comparison by raw ID
  if (remitoRaw != null && remitoRaw.trim() == trimmedSelected) {
    isMatch = true;
  }
  // 2. Comparison by numeric IDs
  else if (remitoRaw != null &&
      RegExp(r'^\d+$').hasMatch(remitoRaw.trim()) &&
      RegExp(r'^\d+$').hasMatch(trimmedSelected) &&
      int.parse(remitoRaw.trim()) == int.parse(trimmedSelected)) {
    isMatch = true;
  }
  // 3. Comparison of resolved name with the name of selected catalog item
  else if (selectedCatalogName != null &&
      resolvedName.toLowerCase().trim() == selectedCatalogName.toLowerCase().trim()) {
    isMatch = true;
  }
  // 4. Direct comparison of resolved name with selectedMaterial string (if text name was selected/passed)
  else if (resolvedName.toLowerCase().trim() == trimmedSelected.toLowerCase()) {
    isMatch = true;
  }
  // 5. Comparison of raw field with selected catalog name
  else if (remitoRaw != null &&
      selectedCatalogName != null &&
      remitoRaw.toLowerCase().trim() == selectedCatalogName.toLowerCase().trim()) {
    isMatch = true;
  }

  // Debug logs as requested
  debugPrint('--- TEMP DEBUG FILTER MATERIAL ---');
  debugPrint('• selectedMaterial: $selectedMaterial');
  debugPrint('• remito.materialId: $remitoRaw');
  debugPrint('• remito.materialNombre (remito.materialId fallback): $remitoRaw');
  debugPrint('• resolvedMaterialName: $resolvedName');
  debugPrint('• matchesMaterial: $isMatch');
  debugPrint('----------------------------------');

  return isMatch;
}

/// Robustly checks if a remito matches the selected obra filter.
bool matchesObraFilter(RemitoModel remito, String? selectedObra, CatalogProvider catalogs) {
  if (selectedObra == null ||
      selectedObra.isEmpty ||
      selectedObra.toLowerCase() == 'todos' ||
      selectedObra.toLowerCase() == 'todas') {
    return true;
  }
  final remitoRaw = remito.obraId;
  final resolvedName = resolveObraName(remitoRaw, catalogs);
  final trimmedSelected = selectedObra.trim();

  String? selectedCatalogName = resolveObraName(trimmedSelected, catalogs);
  if (selectedCatalogName == 'No encontrado' || selectedCatalogName == 'N/A') {
    selectedCatalogName = null;
  }

  bool isMatch = false;
  if (remitoRaw != null && remitoRaw.trim() == trimmedSelected) {
    isMatch = true;
  } else if (remitoRaw != null &&
      RegExp(r'^\d+$').hasMatch(remitoRaw.trim()) &&
      RegExp(r'^\d+$').hasMatch(trimmedSelected) &&
      int.parse(remitoRaw.trim()) == int.parse(trimmedSelected)) {
    isMatch = true;
  } else if (selectedCatalogName != null &&
      resolvedName.toLowerCase().trim() == selectedCatalogName.toLowerCase().trim()) {
    isMatch = true;
  } else if (resolvedName.toLowerCase().trim() == trimmedSelected.toLowerCase()) {
    isMatch = true;
  } else if (remitoRaw != null &&
      selectedCatalogName != null &&
      remitoRaw.toLowerCase().trim() == selectedCatalogName.toLowerCase().trim()) {
    isMatch = true;
  }
  return isMatch;
}

/// Robustly checks if a remito matches the selected transportista filter.
bool matchesTransportistaFilter(RemitoModel remito, String? selectedTransportista, CatalogProvider catalogs) {
  if (selectedTransportista == null ||
      selectedTransportista.isEmpty ||
      selectedTransportista.toLowerCase() == 'todos' ||
      selectedTransportista.toLowerCase() == 'todas') {
    return true;
  }
  final remitoRaw = remito.transportistaId;
  final resolvedName = resolveTransportistaName(remitoRaw, catalogs);
  final trimmedSelected = selectedTransportista.trim();

  String? selectedCatalogName = resolveTransportistaName(trimmedSelected, catalogs);
  if (selectedCatalogName == 'No encontrado' || selectedCatalogName == 'N/A') {
    selectedCatalogName = null;
  }

  bool isMatch = false;
  if (remitoRaw != null && remitoRaw.trim() == trimmedSelected) {
    isMatch = true;
  } else if (remitoRaw != null &&
      RegExp(r'^\d+$').hasMatch(remitoRaw.trim()) &&
      RegExp(r'^\d+$').hasMatch(trimmedSelected) &&
      int.parse(remitoRaw.trim()) == int.parse(trimmedSelected)) {
    isMatch = true;
  } else if (selectedCatalogName != null &&
      resolvedName.toLowerCase().trim() == selectedCatalogName.toLowerCase().trim()) {
    isMatch = true;
  } else if (resolvedName.toLowerCase().trim() == trimmedSelected.toLowerCase()) {
    isMatch = true;
  } else if (remitoRaw != null &&
      selectedCatalogName != null &&
      remitoRaw.toLowerCase().trim() == selectedCatalogName.toLowerCase().trim()) {
    isMatch = true;
  }
  return isMatch;
}
