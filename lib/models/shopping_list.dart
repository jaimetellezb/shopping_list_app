import 'package:shopping_list_app/models/shopping_item.dart';

class ShoppingList {
  String id;
  String name;
  List<ShoppingItem> items;
  DateTime createdAt;
  DateTime? completedAt;
  bool isCompleted;

  ShoppingList({
    required this.id,
    required this.name,
    List<ShoppingItem>? items,
    DateTime? createdAt,
    this.completedAt,
    this.isCompleted = false,
  }) : items = items ?? [],
       createdAt = createdAt ?? DateTime.now();

  double get totalAmount {
    return items.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  int get totalItems {
    return items.fold(0, (sum, item) => sum + item.quantity);
  }

  int get completedItemsCount {
    return items.where((item) => item.isCompleted).length;
  }

  double get completedAmount {
    return items.where((item) => item.isCompleted)
        .fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'items': items.map((item) => item.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'isCompleted': isCompleted,
    };
  }

  factory ShoppingList.fromJson(Map<String, dynamic> json) {
    return ShoppingList(
      id: json['id'],
      name: json['name'],
      items: (json['items'] as List)
          .map((item) => ShoppingItem.fromJson(item))
          .toList(),
      createdAt: DateTime.parse(json['createdAt']),
      completedAt: json['completedAt'] != null 
          ? DateTime.parse(json['completedAt']) 
          : null,
      isCompleted: json['isCompleted'],
    );
  }
}