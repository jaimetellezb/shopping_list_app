import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../db/shopping_item.dart';
import '../db/shopping_list.dart';
import '../ads/ad_manager.dart';

class ShoppingProvider with ChangeNotifier {
  List<ShoppingList> _shoppingLists = [];
  List<ShoppingList> _completedLists = [];
  ShoppingList? _currentList;

  late Box<ShoppingList> _shoppingBox;
  late Box<ShoppingList> _completedBox;

  List<ShoppingList> get shoppingLists => _shoppingLists;
  List<ShoppingList> get completedLists => _completedLists;
  ShoppingList? get currentList => _currentList;

  ShoppingProvider() {
    _initHive();
  }

  Future<void> _initHive() async {
    _shoppingBox = await Hive.openBox<ShoppingList>('shoppingLists');
    _completedBox = await Hive.openBox<ShoppingList>('completedLists');
    _shoppingLists = _shoppingBox.values
        .map((list) => ShoppingList(
              id: list.id,
              name: list.name,
              items: List<ShoppingItem>.from(list.items),
              isCompleted: list.isCompleted,
              completedAt: list.completedAt,
            ))
        .toList();
    _completedLists = _completedBox.values
        .map((list) => ShoppingList(
              id: list.id,
              name: list.name,
              items: List<ShoppingItem>.from(list.items),
              isCompleted: list.isCompleted,
              completedAt: list.completedAt,
            ))
        .toList();
    if (_shoppingLists.isNotEmpty) {
      _currentList = _shoppingLists.first;
    }
    notifyListeners();
  }

  Future<void> _saveLists() async {
    await _shoppingBox.clear();
    await _completedBox.clear();
    for (var list in _shoppingLists) {
      final copy = ShoppingList(
        id: list.id,
        name: list.name,
        items: list.items.map((item) => ShoppingItem(
          id: item.id,
          name: item.name,
          price: item.price,
          quantity: item.quantity,
          category: item.category,
          isCompleted: item.isCompleted,
        )).toList(),
        isCompleted: list.isCompleted,
        completedAt: list.completedAt,
      );
      await _shoppingBox.add(copy);
    }
    for (var list in _completedLists) {
      final copy = ShoppingList(
        id: list.id,
        name: list.name,
        items: list.items.map((item) => ShoppingItem(
          id: item.id,
          name: item.name,
          price: item.price,
          quantity: item.quantity,
          category: item.category,
          isCompleted: item.isCompleted,
        )).toList(),
        isCompleted: list.isCompleted,
        completedAt: list.completedAt,
      );
      await _completedBox.add(copy);
    }
  }

  // Crear nueva lista
  void createNewList(String name) {
    final newList = ShoppingList(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      items: [], // Siempre mutable
    );
    _shoppingLists.add(newList);
    _currentList = newList;
    _saveLists();
    notifyListeners();
    // Show interstitial ad if more than 3 lists have been created
    if (_shoppingLists.length > 3) {
      AdManager().showInterstitialAd();
    }
  }

  // Seleccionar lista actual
  void selectList(ShoppingList list) {
    _currentList = list;
    notifyListeners();
  }

  // Agregar producto a la lista actual
  void addItem(String name, double price, {int quantity = 1, String category = 'General'}) {
    if (_currentList == null) return;
    final newItem = ShoppingItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      price: price,
      quantity: quantity,
      category: category,
    );
    // Asegura que la lista sea mutable
    if (_currentList!.items is UnmodifiableListView) {
      _currentList!.items = List<ShoppingItem>.from(_currentList!.items);
    }
    _currentList!.items.add(newItem);
    _saveLists();
    notifyListeners();
  }

  // Editar producto
  void editItem(String itemId, {String? name, double? price, int? quantity, String? category}) {
    if (_currentList == null) return;
    final itemIndex = _currentList!.items.indexWhere((item) => item.id == itemId);
    if (itemIndex != -1) {
      _currentList!.items[itemIndex] = _currentList!.items[itemIndex].copyWith(
        name: name,
        price: price,
        quantity: quantity,
        category: category,
      );
      _saveLists();
      notifyListeners();
    }
  }

  // Eliminar producto
  void removeItem(String itemId) {
    if (_currentList == null) return;
    _currentList!.items.removeWhere((item) => item.id == itemId);
    _saveLists();
    notifyListeners();
  }

  // Marcar producto como completado
  void toggleItemCompletion(String itemId) {
    if (_currentList == null) return;
    final itemIndex = _currentList!.items.indexWhere((item) => item.id == itemId);
    if (itemIndex != -1) {
      _currentList!.items[itemIndex].isCompleted = 
          !_currentList!.items[itemIndex].isCompleted;
      _saveLists();
      notifyListeners();
    }
  }

  // Completar lista de compras
  void completeShoppingList() {
    if (_currentList == null) return;
    // Crear una copia profunda de la lista para evitar conflicto de HiveObject
    final completedList = ShoppingList(
      id: _currentList!.id,
      name: _currentList!.name,
      items: _currentList!.items.map((item) => ShoppingItem(
        id: item.id,
        name: item.name,
        price: item.price,
        quantity: item.quantity,
        category: item.category,
        isCompleted: item.isCompleted,
      )).toList(),
      isCompleted: true,
      completedAt: DateTime.now(),
    );
    _completedLists.add(completedList);
    _shoppingLists.remove(_currentList!);
    _currentList = null;
    _saveLists();
    notifyListeners();
    // Mostrar anuncio intersticial al completar una lista
    AdManager().showInterstitialAd();
  }

  // Eliminar lista
  void deleteList(String listId) {
    _shoppingLists.removeWhere((list) => list.id == listId);
    _completedLists.removeWhere((list) => list.id == listId);
    if (_currentList?.id == listId) {
      _currentList = null;
    }
    _saveLists();
    notifyListeners();
  }

  // Obtener categorías únicas
  List<String> getCategories() {
    Set<String> categories = {'General'};
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
    return categories.toList();
  }
}