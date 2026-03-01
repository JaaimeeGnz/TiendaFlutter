import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../providers/cart_provider.dart';
import '../providers/favorites_provider.dart';
import 'home/home_screen.dart';
import 'products/product_list_screen.dart';
import 'favorites/favorites_screen.dart';
import 'account/account_screen.dart';

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  int _currentIndex = 0;

  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const HomeScreen(),
      const ProductListScreen(),
      const FavoritesScreen(),
      const AccountScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();
    final favoritesProvider = context.watch<FavoritesProvider>();

    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        color: Colors.black,
        child: SafeArea(
          child: SizedBox(
            height: 70,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Inicio
                _buildNavItem(
                  icon: Icons.home,
                  label: 'Inicio',
                  index: 0,
                  isActive: _currentIndex == 0,
                ),
                // Comprar
                Stack(
                  alignment: Alignment.topRight,
                  children: [
                    _buildNavItem(
                      icon: Icons.search,
                      label: 'Comprar',
                      index: 1,
                      isActive: _currentIndex == 1,
                    ),
                    if (cartProvider.itemCount > 0)
                      Positioned(
                        right: 8,
                        top: 4,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: const BoxDecoration(
                            color: AppColors.jdRed,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${cartProvider.itemCount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                // Favoritos
                Stack(
                  alignment: Alignment.topRight,
                  children: [
                    _buildNavItem(
                      icon: Icons.favorite_outline,
                      label: 'Favoritos',
                      index: 2,
                      isActive: _currentIndex == 2,
                    ),
                    if (favoritesProvider.favoritesCount > 0)
                      Positioned(
                        right: 8,
                        top: 4,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: const BoxDecoration(
                            color: AppColors.jdRed,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${favoritesProvider.favoritesCount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                // Mi cuenta
                _buildNavItem(
                  icon: Icons.person_outline,
                  label: 'Mi cuenta',
                  index: 3,
                  isActive: _currentIndex == 3,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required bool isActive,
  }) {
    return InkWell(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: SizedBox(
        height: 70,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isActive ? Colors.white : Colors.grey[600],
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                color: isActive ? Colors.white : Colors.grey[600],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
