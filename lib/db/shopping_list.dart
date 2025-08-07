import 'package:hive/hive.dart';
import 'shopping_item.dart';

part 'shopping_list.g.dart';

@HiveType(typeId: 1)
class ShoppingList extends HiveObject {
  @HiveField(0)
  String id;
  @HiveField(1)
  String name;
  @HiveField(2)
  List<ShoppingItem> items;
  @HiveField(3)
  bool isCompleted;
  @HiveField(4)
  DateTime? completedAt;

  ShoppingList({
    required this.id,
    required this.name,
    this.items = const [],
    this.isCompleted = false,
    this.completedAt,
  });

  int get totalItems => items.length;
  int get completedItemsCount => items.where((item) => item.isCompleted).length;
  double get totalAmount => items.fold(0, (sum, item) => sum + (item.price * item.quantity));
  double get completedAmount => items.where((item) => item.isCompleted).fold(0, (sum, item) => sum + (item.price * item.quantity));
}
