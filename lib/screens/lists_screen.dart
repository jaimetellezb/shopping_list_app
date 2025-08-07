import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../providers/shopping_provider.dart';
import '../widgets/create_list_dialog.dart';
import '../ads/ad_manager.dart';

class ListsScreen extends StatefulWidget {
  const ListsScreen({super.key});

  @override
  _ListsScreenState createState() => _ListsScreenState();
}

class _ListsScreenState extends State<ListsScreen> {
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
        title: Text('Mis Listas de Compras'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          Consumer<ShoppingProvider>(
            builder: (context, provider, child) {
              if (provider.shoppingLists.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No tienes listas de compras',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                      SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => _showCreateListDialog(context),
                        icon: Icon(Icons.add),
                        label: Text('Crear primera lista'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  bottom: bannerHeight + 24, // espacio para el banner y margen
                ),
                itemCount: provider.shoppingLists.length,
                itemBuilder: (context, index) {
                  final list = provider.shoppingLists[index];
                  return Card(
                    margin: EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.green,
                        child: Icon(Icons.shopping_cart, color: Colors.white),
                      ),
                      title: Text(list.name, style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${list.totalItems} productos'),
                          Text('\$${list.totalAmount.toStringAsFixed(2)}',
                              style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      trailing: PopupMenuButton(
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'select',
                            child: Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.green),
                                SizedBox(width: 8),
                                Text('Seleccionar'),
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
                          if (value == 'select') {
                            provider.selectList(list);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Lista "${list.name}" seleccionada')),
                            );
                          } else if (value == 'delete') {
                            _showDeleteDialog(context, provider, list.id, list.name);
                          }
                        },
                      ),
                      onTap: () {
                        provider.selectList(list);
                        Navigator.of(context).pushNamed('/shopping');
                      },
                    ),
                  );
                },
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
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: bannerHeight + 8),
        child: FloatingActionButton(
          onPressed: () => _showCreateListDialog(context),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          child: Icon(Icons.add),
        ),
      ),
    );
  }

  void _showCreateListDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => CreateListDialog(),
    );
  }

  void _showDeleteDialog(BuildContext context, ShoppingProvider provider, String listId, String listName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Eliminar Lista'),
        content: Text('¿Estás seguro de que quieres eliminar la lista "$listName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              provider.deleteList(listId);
              Navigator.of(context).pop();
            },
            child: Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}