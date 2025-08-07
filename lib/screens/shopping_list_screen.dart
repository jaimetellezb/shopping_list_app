import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../providers/shopping_provider.dart';
import '../widgets/add_item_dialog.dart';
import '../widgets/edit_item_dialog.dart';
import '../ads/ad_manager.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  _ShoppingListScreenState createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  BannerAd? _bannerAd;

  @override
  void initState() {
    super.initState();
    _bannerAd = BannerAd(
      adUnitId: AdManager.bannerAdUnitId,
      size: AdSize.banner,
      request: AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) => setState(() {}),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double bannerHeight = _bannerAd?.size.height.toDouble() ?? 0;
    return Scaffold(
      appBar: AppBar(
        title: Consumer<ShoppingProvider>(
          builder: (context, provider, child) {
            return Text(provider.currentList?.name ?? 'Selecciona una lista');
          },
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          Consumer<ShoppingProvider>(
            builder: (context, provider, child) {
              if (provider.currentList == null) return Container();
              return PopupMenuButton(
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'complete',
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green),
                        SizedBox(width: 8),
                        Text('Completar compra'),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'complete') {
                    _showCompleteDialog(context, Provider.of<ShoppingProvider>(context, listen: false));
                  }
                },
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Contenido principal con padding inferior para el banner
          Consumer<ShoppingProvider>(
            builder: (context, provider, child) {
              if (provider.currentList == null) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.list_alt, size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Selecciona una lista de compras',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                      SizedBox(height: 24),
                    ],
                  ),
                );
              }

              final currentList = provider.currentList!;
              return SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Column(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(12),
                          color: Colors.green.shade50,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Total de productos: ${currentList.totalItems}',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    'Completados: ${currentList.completedItemsCount}',
                                    style: TextStyle(color: Colors.green),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '\$${currentList.totalAmount.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                  Text(
                                    'Gastado: \$${currentList.completedAmount.toStringAsFixed(2)}',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Flexible(
                          child: currentList.items.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.shopping_basket, size: 80, color: Colors.grey),
                                      SizedBox(height: 16),
                                      Text(
                                        'No hay productos en esta lista',
                                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  padding: EdgeInsets.only(
                                    left: 16,
                                    right: 16,
                                    bottom: bannerHeight + 24, // espacio para el banner y margen
                                  ),
                                  itemCount: currentList.items.length,
                                  itemBuilder: (context, index) {
                                    final item = currentList.items[index];
                                    return Card(
                                      margin: EdgeInsets.only(bottom: 8),
                                      child: ListTile(
                                        leading: Checkbox(
                                          value: item.isCompleted,
                                          onChanged: (value) {
                                            provider.toggleItemCompletion(item.id);
                                          },
                                          activeColor: Colors.green,
                                        ),
                                        title: Text(
                                          item.name,
                                          style: TextStyle(
                                            decoration: item.isCompleted 
                                                ? TextDecoration.lineThrough 
                                                : null,
                                          ),
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('Cantidad: ${item.quantity}'),
                                            Text('Precio unitario: \$${item.price.toStringAsFixed(2)}'),
                                            Text('Categoría: ${item.category}'),
                                          ],
                                        ),
                                        trailing: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              '\$${item.totalPrice.toStringAsFixed(2)}',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.green,
                                              ),
                                            ),
                                            Expanded(
                                              child: PopupMenuButton(
                                                itemBuilder: (context) => [
                                                  PopupMenuItem(
                                                    value: 'edit',
                                                    child: Row(
                                                      children: [
                                                        Icon(Icons.edit, color: Colors.blue),
                                                        SizedBox(width: 8),
                                                        Text('Editar'),
                                                      ],
                                                    ),
                                                  ),
                                                  PopupMenuItem(
                                                    value: 'delete',
                                                    child: Row(
                                                      children: [
                                                        Icon(Icons.delete, color: Colors.red),
                                                        SizedBox(width: 8),
                                                        Text('Eliminar'),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                                onSelected: (value) {
                                                  if (value == 'edit') {
                                                    _showEditItemDialog(context, item);
                                                  } else if (value == 'delete') {
                                                    provider.removeItem(item.id);
                                                  }
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    );
                  },
                ),
              );
            },
          ),
          if (_bannerAd != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                color: Colors.white,
                width: _bannerAd!.size.width.toDouble(),
                height: _bannerAd!.size.height.toDouble(),
                child: AdWidget(ad: _bannerAd!),
              ),
            ),
        ],
      ),
      floatingActionButton: Consumer<ShoppingProvider>(
        builder: (context, provider, child) {
          if (provider.currentList == null) return Container();
          return Padding(
            padding: EdgeInsets.only(bottom: bannerHeight + 8),
            child: FloatingActionButton(
              onPressed: () => _showAddItemDialog(context),
              backgroundColor: Colors.green,
              child: Icon(Icons.add, color: Colors.white),
            ),
          );
        },
      ),
    );
  }

  void _showAddItemDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AddItemDialog(),
    );
  }

  void _showEditItemDialog(BuildContext context, item) {
    showDialog(
      context: context,
      builder: (context) => EditItemDialog(item: item),
    );
  }

  void _showCompleteDialog(BuildContext context, ShoppingProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Completar Compra'),
        content: Text('¿Has terminado de hacer las compras? Esto moverá la lista al historial.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              provider.completeShoppingList();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('¡Compra completada!')),
              );
            },
            child: Text('Completar', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );
  }
}