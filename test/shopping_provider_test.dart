import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shopping_list_app/db/shopping_item.dart';
import 'package:shopping_list_app/db/shopping_list.dart';
import 'package:shopping_list_app/providers/shopping_provider.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_provider_test_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(ShoppingItemAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(ShoppingListAdapter());
    }
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  Future<ShoppingProvider> newProvider() async {
    final provider = ShoppingProvider();
    final deadline = DateTime.now().add(const Duration(seconds: 5));
    while (!provider.isInitialized && !provider.initFailed) {
      if (DateTime.now().isAfter(deadline)) {
        throw StateError('ShoppingProvider init timeout');
      }
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    if (provider.initFailed) throw StateError('ShoppingProvider init failed');
    return provider;
  }

  test('createNewList crea, selecciona y persiste', () async {
    final provider = await newProvider();

    await provider.createNewList('Super');
    expect(provider.currentList?.name, 'Super');
    expect(provider.shoppingLists, hasLength(1));
    expect(provider.currentList?.items, isEmpty);

    // Reabrir: los datos deben sobrevivir al reinicio.
    await Hive.close();
    Hive.init(tempDir.path);
    final reopened = await newProvider();
    expect(reopened.shoppingLists, hasLength(1));
    expect(reopened.shoppingLists.first.name, 'Super');
    expect(reopened.currentList?.name, 'Super');
  });

  test('createNewList ignora nombres vacíos', () async {
    final provider = await newProvider();
    await provider.createNewList('   ');
    expect(provider.shoppingLists, isEmpty);
    expect(provider.currentList, isNull);
  });

  test('los IDs generados son únicos', () async {
    final provider = await newProvider();
    await provider.createNewList('A');
    await provider.createNewList('B');
    expect(provider.shoppingLists[0].id == provider.shoppingLists[1].id, false);

    provider.selectList(provider.shoppingLists[0]);
    await provider.addItem('Leche', 1.5);
    await provider.addItem('Leche', 1.5);
    final items = provider.currentList!.items;
    expect(items[0].id == items[1].id, false);
  });

  test('addItem valida y registra la categoría', () async {
    final provider = await newProvider();

    // Sin lista actual no hace nada.
    await provider.addItem('Nada', 1.0);
    expect(provider.shoppingLists, isEmpty);

    await provider.createNewList('Super');
    await provider.addItem('  ', 1.0);
    await provider.addItem('Pan', 0);
    await provider.addItem('Pan', 1.0, quantity: 0);
    expect(provider.currentList!.items, isEmpty);

    await provider.addItem('Pan', 2.5, quantity: 2, category: 'Panadería');
    expect(provider.currentList!.items, hasLength(1));
    expect(provider.currentList!.totalAmount, 5.0);
    expect(provider.getCategories(), ['General', 'Panadería']);
  });

  test('toggle, edit y remove de items', () async {
    final provider = await newProvider();
    await provider.createNewList('Super');
    await provider.addItem('Leche', 2.0, quantity: 3);
    final itemId = provider.currentList!.items.first.id;

    await provider.toggleItemCompletion(itemId);
    expect(provider.currentList!.items.first.isCompleted, true);
    expect(provider.currentList!.completedItemsCount, 1);

    await provider.editItem(itemId, name: 'Leche entera', price: 2.5);
    expect(provider.currentList!.items.first.name, 'Leche entera');
    expect(provider.currentList!.totalAmount, 7.5);

    // Ediciones inválidas se ignoran.
    await provider.editItem(itemId, price: -1);
    expect(provider.currentList!.items.first.price, 2.5);

    await provider.removeItem(itemId);
    expect(provider.currentList!.items, isEmpty);
  });

  test('restoreItem reinserta en su posición y evita duplicados', () async {
    final provider = await newProvider();
    await provider.createNewList('Super');
    await provider.addItem('A', 1.0);
    await provider.addItem('B', 2.0);
    await provider.addItem('C', 3.0);
    final removed = provider.currentList!.items[1];

    await provider.removeItem(removed.id);
    expect(
      provider.currentList!.items.map((e) => e.name),
      ['A', 'C'],
    );

    await provider.restoreItem(removed, 1);
    expect(
      provider.currentList!.items.map((e) => e.name),
      ['A', 'B', 'C'],
    );

    // Restaurar dos veces no duplica.
    await provider.restoreItem(removed, 1);
    expect(provider.currentList!.items, hasLength(3));

    // Índices fuera de rango se ajustan.
    await provider.removeItem(removed.id);
    await provider.restoreItem(removed, 99);
    expect(provider.currentList!.items.last.id, removed.id);
  });

  test('completeShoppingList mueve al historial y limpia la actual', () async {
    final provider = await newProvider();
    await provider.createNewList('Super');
    await provider.addItem('Leche', 2.0);
    final listId = provider.currentList!.id;

    await provider.completeShoppingList();

    expect(provider.currentList, isNull);
    expect(provider.shoppingLists, isEmpty);
    expect(provider.completedLists, hasLength(1));
    expect(provider.completedLists.first.id, listId);
    expect(provider.completedLists.first.isCompleted, true);
    expect(provider.completedLists.first.completedAt, isNotNull);

    // Completar sin lista actual no falla.
    await provider.completeShoppingList();
    expect(provider.completedLists, hasLength(1));
  });

  test('deleteList borra activas y del historial', () async {
    final provider = await newProvider();
    await provider.createNewList('A');
    final idA = provider.currentList!.id;
    await provider.createNewList('B');
    provider.selectList(
      provider.shoppingLists.firstWhere((l) => l.id == idA),
    );
    await provider.completeShoppingList();
    expect(provider.completedLists, hasLength(1));

    await provider.deleteList(idA);
    expect(provider.completedLists, isEmpty);

    final idB = provider.shoppingLists.single.id;
    await provider.deleteList(idB);
    expect(provider.shoppingLists, isEmpty);
    expect(provider.currentList, isNull);
  });

  test('addCategory dedica caja y getCategories ordena', () async {
    final provider = await newProvider();
    await provider.createNewList('Super');

    await provider.addCategory('  ');
    await provider.addCategory('General');
    expect(provider.getCategories(), ['General']);

    await provider.addCategory('Frutas');
    await provider.addCategory('Abarrotes');
    await provider.addCategory('Frutas');
    expect(provider.getCategories(), ['General', 'Abarrotes', 'Frutas']);

    // Las categorías sobreviven al reinicio sin escanear items.
    await Hive.close();
    Hive.init(tempDir.path);
    final reopened = await newProvider();
    expect(reopened.getCategories(), ['General', 'Abarrotes', 'Frutas']);
  });
}
