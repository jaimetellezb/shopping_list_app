import 'package:hive/hive.dart';

part 'shopping_item.g.dart';

@HiveType(typeId: 0)
class ShoppingItem extends HiveObject {
  @HiveField(0)
  String id;
  @HiveField(1)
  String name;
  @HiveField(2)
  double price;
  @HiveField(3)
  int quantity;
  @HiveField(4)
  String category;
  @HiveField(5)
  bool isCompleted;

  ShoppingItem({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
    required this.category,
    this.isCompleted = false,
  });

  double get totalPrice => price * quantity;

  ShoppingItem copyWith({
    String? id,
    String? name,
    double? price,
    int? quantity,
    String? category,
    bool? isCompleted,
  }) {
    return ShoppingItem(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      category: category ?? this.category,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
