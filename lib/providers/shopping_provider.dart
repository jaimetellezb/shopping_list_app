import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../db/shopping_item.dart';
import '../db/shopping_list.dart';
import '../ads/ad_manager.dart';

class ShoppingProvider with ChangeNotifier {
  List<ShoppingList> _shoppingLists = [];
  List<ShoppingList> _completedLists = [];
  ShoppingList? _currentList;
  Set<String> _customCategories = {};
  bool _isInitialized = false;
  bool _initFailed = false;

  late Box<ShoppingList> _shoppingBox;
  late Box<ShoppingList> _completedBox;
  late Box<String> _categoriesBox;
  late Box<double> _budgetsBox;

  List<ShoppingList> get shoppingLists => _shoppingLists;
  List<ShoppingList> get completedLists => _completedLists;
  ShoppingList? get currentList => _currentList;
  bool get isInitialized => _isInitialized;
  bool get initFailed => _initFailed;

  ShoppingProvider() {
    _initHive();
  }

  String _newId() {
    return '${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(1 << 32)}';
  }

  Future<void> _initHive() async {
    try {
      _shoppingBox = await Hive.openBox<ShoppingList>('shoppingLists');
      _completedBox = await Hive.openBox<ShoppingList>('completedLists');
      _categoriesBox = await Hive.openBox<String>('categories');
      _budgetsBox = await Hive.openBox<double>('budgets');
      _shoppingLists = _shoppingBox.values.map(_withMutableItems).toList();
      _completedLists = _completedBox.values.map(_withMutableItems).toList();
      _customCategories = _categoriesBox.values
          .map((c) => c.trim())
          .where((c) => c.isNotEmpty)
          .toSet();
      if (_customCategories.isEmpty) {
        // Migración: sembrar categorías existentes para no depender del
        // escaneo de todas las listas en cada build.
        final seeded = <String>{};
        for (var list in [..._shoppingLists, ..._completedLists]) {
          for (var item in list.items) {
            final category = item.category.trim();
            if (category.isNotEmpty && category != 'General') {
              seeded.add(category);
            }
          }
        }
        for (var category in seeded) {
          await _categoriesBox.add(category);
        }
        _customCategories = seeded;
      }
      if (_shoppingLists.isNotEmpty) {
        _currentList = _shoppingLists.first;
      }
      _isInitialized = true;
    } catch (e) {
      debugPrint('ShoppingProvider: Hive init failed: $e');
      _initFailed = true;
    }
    notifyListeners();
  }

  Future<void> retryInit() async {
    if (_isInitialized || _initFailed == false) return;
    _initFailed = false;
    await _initHive();
  }

  static ShoppingList _withMutableItems(ShoppingList list) {
    list.items = List<ShoppingItem>.from(list.items);
    return list;
  }

  void _ensureMutableItems(ShoppingList list) {
    // Las listas leídas de Hive o creadas con `const []` pueden ser
    // inmutables; copiar antes de mutar evita UnsupportedError.
    try {
      list.items = List<ShoppingItem>.from(list.items);
    } catch (_) {
      list.items = <ShoppingItem>[];
    }
  }

  bool get _ready => _isInitialized && !_initFailed;

  Future<void> _persistActiveList(ShoppingList list) async {
    try {
      await _shoppingBox.put(list.id, list);
    } catch (e) {
      debugPrint('ShoppingProvider: persist active list failed: $e');
    }
  }

  // Crear nueva lista
  Future<void> createNewList(String name) async {
    if (!_ready) return;
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final newList = ShoppingList(
      id: _newId(),
      name: trimmed,
      items: <ShoppingItem>[],
    );
    _shoppingLists.add(newList);
    _currentList = newList;
    notifyListeners();
    try {
      await _shoppingBox.put(newList.id, newList);
    } catch (e) {
      debugPrint('ShoppingProvider: create list persist failed: $e');
    }
  }

  // Seleccionar lista actual
  void selectList(ShoppingList list) {
    _currentList = list;
    notifyListeners();
  }

  // Agregar producto a la lista actual
  Future<void> addItem(
    String name,
    double price, {
    int quantity = 1,
    String category = 'General',
  }) async {
    if (!_ready || _currentList == null) return;
    final trimmedName = name.trim();
    if (trimmedName.isEmpty || price <= 0 || quantity <= 0) return;
    final trimmedCategory =
        category.trim().isEmpty ? 'General' : category.trim();
    _ensureMutableItems(_currentList!);
    final newItem = ShoppingItem(
      id: _newId(),
      name: trimmedName,
      price: price,
      quantity: quantity,
      category: trimmedCategory,
    );
    _currentList!.items.add(newItem);
    if (trimmedCategory != 'General' &&
        !_customCategories.contains(trimmedCategory)) {
      _customCategories.add(trimmedCategory);
      try {
        await _categoriesBox.add(trimmedCategory);
      } catch (e) {
        debugPrint('ShoppingProvider: persist category failed: $e');
      }
    }
    notifyListeners();
    await _persistActiveList(_currentList!);
  }

  // Editar producto
  Future<void> editItem(
    String itemId, {
    String? name,
    double? price,
    int? quantity,
    String? category,
  }) async {
    if (!_ready || _currentList == null) return;
    final itemIndex = _currentList!.items.indexWhere(
      (item) => item.id == itemId,
    );
    if (itemIndex == -1) return;
    if (name != null && name.trim().isEmpty) return;
    if (price != null && price <= 0) return;
    if (quantity != null && quantity <= 0) return;
    _ensureMutableItems(_currentList!);
    final trimmedCategory = category?.trim();
    _currentList!.items[itemIndex] = _currentList!.items[itemIndex].copyWith(
      name: name?.trim(),
      price: price,
      quantity: quantity,
      category:
          trimmedCategory == null || trimmedCategory.isEmpty
              ? null
              : trimmedCategory,
    );
    final effectiveCategory = _currentList!.items[itemIndex].category;
    if (effectiveCategory != 'General' &&
        !_customCategories.contains(effectiveCategory)) {
      _customCategories.add(effectiveCategory);
      try {
        await _categoriesBox.add(effectiveCategory);
      } catch (e) {
        debugPrint('ShoppingProvider: persist category failed: $e');
      }
    }
    notifyListeners();
    await _persistActiveList(_currentList!);
  }

  // Eliminar producto
  Future<void> removeItem(String itemId) async {
    if (!_ready || _currentList == null) return;
    _ensureMutableItems(_currentList!);
    _currentList!.items.removeWhere((item) => item.id == itemId);
    notifyListeners();
    await _persistActiveList(_currentList!);
  }

  // Restaurar un producto eliminado en su posición (para Deshacer).
  Future<void> restoreItem(ShoppingItem item, int index) async {
    if (!_ready || _currentList == null) return;
    _ensureMutableItems(_currentList!);
    if (_currentList!.items.any((e) => e.id == item.id)) return;
    final safeIndex = index.clamp(0, _currentList!.items.length);
    _currentList!.items.insert(safeIndex, item);
    notifyListeners();
    await _persistActiveList(_currentList!);
  }

  // Marcar producto como completado
  Future<void> toggleItemCompletion(String itemId) async {
    if (!_ready || _currentList == null) return;
    final itemIndex = _currentList!.items.indexWhere(
      (item) => item.id == itemId,
    );
    if (itemIndex == -1) return;
    _ensureMutableItems(_currentList!);
    _currentList!.items[itemIndex].isCompleted =
        !_currentList!.items[itemIndex].isCompleted;
    notifyListeners();
    await _persistActiveList(_currentList!);
  }

  // Completar lista de compras
  Future<void> completeShoppingList() async {
    if (!_ready || _currentList == null) return;
    final current = _currentList!;
    // Crear una copia profunda de la lista para evitar conflicto de HiveObject
    final completedList = ShoppingList(
      id: current.id,
      name: current.name,
      items:
          current.items
              .map(
                (item) => ShoppingItem(
                  id: item.id,
                  name: item.name,
                  price: item.price,
                  quantity: item.quantity,
                  category: item.category,
                  isCompleted: item.isCompleted,
                ),
              )
              .toList(),
      isCompleted: true,
      completedAt: DateTime.now(),
    );
    _completedLists.add(completedList);
    _shoppingLists.removeWhere((list) => list.id == current.id);
    _currentList = null;
    notifyListeners();
    try {
      await _shoppingBox.delete(current.id);
      await _completedBox.put(completedList.id, completedList);
      await _budgetsBox.delete(current.id);
    } catch (e) {
      debugPrint('ShoppingProvider: complete list persist failed: $e');
    }
    // Mostrar anuncio intersticial al completar una lista
    AdManager().showInterstitialAd();
  }

  // Eliminar lista (activa o del historial)
  Future<void> deleteList(String listId) async {
    if (!_ready) return;
    _shoppingLists.removeWhere((list) => list.id == listId);
    _completedLists.removeWhere((list) => list.id == listId);
    if (_currentList?.id == listId) {
      _currentList = null;
    }
    notifyListeners();
    try {
      await _shoppingBox.delete(listId);
      await _completedBox.delete(listId);
      await _budgetsBox.delete(listId);
    } catch (e) {
      debugPrint('ShoppingProvider: delete list persist failed: $e');
    }
  }

  // Duplicar una lista (activa o del historial) como nueva lista activa.
  Future<ShoppingList?> duplicateList(String listId) async {
    if (!_ready) return null;
    ShoppingList? source;
    for (final list in [..._shoppingLists, ..._completedLists]) {
      if (list.id == listId) {
        source = list;
        break;
      }
    }
    if (source == null) return null;
    final copy = ShoppingList(
      id: _newId(),
      name: '${source.name} (copia)',
      items:
          source.items
              .map(
                (item) => ShoppingItem(
                  id: _newId(),
                  name: item.name,
                  price: item.price,
                  quantity: item.quantity,
                  category: item.category,
                ),
              )
              .toList(),
    );
    _shoppingLists.add(copy);
    _currentList = copy;
    notifyListeners();
    try {
      await _shoppingBox.put(copy.id, copy);
    } catch (e) {
      debugPrint('ShoppingProvider: duplicate list persist failed: $e');
    }
    return copy;
  }

  // Presupuesto por lista (null = sin presupuesto).
  double? getBudget(String listId) {
    if (!_ready) return null;
    return _budgetsBox.get(listId);
  }

  Future<void> setBudget(String listId, double? amount) async {
    if (!_ready) return;
    try {
      if (amount == null || amount <= 0) {
        await _budgetsBox.delete(listId);
      } else {
        await _budgetsBox.put(listId, amount);
      }
    } catch (e) {
      debugPrint('ShoppingProvider: set budget persist failed: $e');
    }
    notifyListeners();
  }

  // Registrar una categoría sin el hack del item temporal.
  Future<void> addCategory(String name) async {
    if (!_ready) return;
    final trimmed = name.trim();
    if (trimmed.isEmpty ||
        trimmed == 'General' ||
        _customCategories.contains(trimmed)) {
      return;
    }
    _customCategories.add(trimmed);
    notifyListeners();
    try {
      await _categoriesBox.add(trimmed);
    } catch (e) {
      debugPrint('ShoppingProvider: add category persist failed: $e');
    }
  }

  // Obtener categorías únicas
  List<String> getCategories() {
    final categories = <String>{'General', ..._customCategories};
    // Incluir categorías legacy que aún no estén migradas.
    for (var list in _shoppingLists) {
      for (var item in list.items) {
        categories.add(item.category);
      }
    }
    for (var list in _completedLists) {
      for (var item in list.items) {
        categories.add(item.category);
      }
    }
    final sorted = categories.toList()..sort();
    sorted.remove('General');
    return ['General', ...sorted];
  }
}
