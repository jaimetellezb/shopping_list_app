import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../ads/ad_manager.dart';
import '../providers/shopping_provider.dart';
import '../widgets/create_list_dialog.dart';
import '../widgets/add_item_dialog.dart';
import 'shopping_list_screen.dart';
import 'history_screen.dart';
import 'lists_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  String _appVersion = '';

  final List<Widget> _screens = [
    ListsScreen(),
    ShoppingListScreen(),
    HistoryScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() => _appVersion = info.version);
    }
  }

  void _showPrivacyDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.privacy_tip_rounded,
                      color: Theme.of(context).colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Política de Privacidad',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Flexible(
                child: SingleChildScrollView(
                  child: Text(
                    'Tus listas y productos se almacenan exclusivamente en tu dispositivo. '
                    'No compartimos ni vendemos tus datos.\n\n'
                    'Usamos Google AdMob para mostrar anuncios. '
                    'Google puede recopilar identificadores de publicidad, '
                    'dirección IP y datos del dispositivo para mostrar anuncios '
                    'personalizados.\n\n'
                    'Puedes restablecer tu ID de publicidad o desactivar la '
                    'personalización de anuncios desde Ajustes → Google → Anuncios '
                    'en tu dispositivo.\n\n'
                    'Para más información, consulta:\n'
                    'https://jaimetellezb.github.io/shopping_list_app/',
                    style: TextStyle(fontSize: 14, height: 1.6),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cerrar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: _buildAppBar(),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.transparent,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 50,
                      height: 50,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              ListTile(
                leading: Icon(Icons.privacy_tip_rounded, color: colorScheme.primary),
                title: const Text('Política de Privacidad'),
                onTap: () {
                  Navigator.of(context).pop();
                  _showPrivacyDialog();
                },
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Versión $_appVersion',
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: _screens[_currentIndex],
      floatingActionButton: _buildFab(),
      bottomNavigationBar: ValueListenableBuilder<bool>(
        valueListenable: AdManager().isBannerReady,
        builder: (context, ready, child) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (ready) ...[
                SizedBox(
                  width: AdManager().bannerAd!.size.width.toDouble(),
                  height: AdManager().bannerAd!.size.height.toDouble(),
                  child: Container(
                    color: Colors.white,
                    child: AdWidget(ad: AdManager().bannerAd!),
                  ),
                ),
                Divider(height: 1, color: Colors.grey.shade200),
              ],
              _buildNavBar(),
            ],
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    switch (_currentIndex) {
      case 0:
        return AppBar(
          title: const Text('Mis Listas'),
          actions: [
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () => _showCreateListDialog(context),
            ),
          ],
        );
      case 1:
        return AppBar(
          title: Consumer<ShoppingProvider>(
            builder: (context, provider, child) {
              return Text(
                provider.currentList?.name ?? 'Selecciona una lista',
                overflow: TextOverflow.ellipsis,
              );
            },
          ),
          actions: [
            Consumer<ShoppingProvider>(
              builder: (context, provider, child) {
                if (provider.currentList == null) return Container();
                return IconButton(
                  icon: const Icon(Icons.check_circle_outline),
                  onPressed: () => _showCompleteDialog(context, provider),
                  tooltip: 'Completar compra',
                );
              },
            ),
          ],
        );
      case 2:
        return AppBar(title: const Text('Historial'));
      default:
        return AppBar();
    }
  }

  Widget? _buildFab() {
    switch (_currentIndex) {
      case 0:
        return FloatingActionButton(
          onPressed: () => _showCreateListDialog(context),
          child: const Icon(Icons.add),
        );
      case 1:
        return Consumer<ShoppingProvider>(
          builder: (context, provider, child) {
            if (provider.currentList == null) return Container();
            return FloatingActionButton(
              onPressed: () => _showAddItemDialog(context),
              child: const Icon(Icons.add),
            );
          },
        );
      default:
        return null;
    }
  }

  Widget _buildNavBar() {

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                0,
                Icons.list_alt_rounded,
                Icons.list_alt_outlined,
                'Listas',
              ),
              _buildNavItem(
                1,
                Icons.shopping_cart_rounded,
                Icons.shopping_cart_outlined,
                'Compras',
              ),
              _buildNavItem(
                2,
                Icons.history_rounded,
                Icons.history_outlined,
                'Historial',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData activeIcon,
    IconData inactiveIcon,
    String label,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 20 : 16,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : inactiveIcon,
              color: isSelected ? colorScheme.primary : Colors.grey.shade500,
              size: 24,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showCreateListDialog(BuildContext context) {
    showDialog(context: context, builder: (context) => CreateListDialog());
  }

  void _showAddItemDialog(BuildContext context) {
    showDialog(context: context, builder: (context) => AddItemDialog());
  }

  void _showCompleteDialog(BuildContext context, ShoppingProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Completar Compra'),
        content: const Text(
          '¿Has terminado de hacer las compras? Esto moverá la lista al historial.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              provider.completeShoppingList();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('¡Compra completada!')),
              );
            },
            child: const Text('Completar', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );
  }
}
