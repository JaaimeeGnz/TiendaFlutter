import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/product_provider.dart';
import 'providers/favorites_provider.dart';
import 'providers/address_provider.dart';
import 'providers/settings_provider.dart';
import 'services/supabase_service.dart';
import 'services/stripe_service.dart';
import 'screens/root_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/products/product_list_screen.dart';
import 'screens/products/product_detail_screen.dart';
import 'screens/cart/cart_screen.dart';
import 'screens/account/account_screen.dart';
import 'screens/account/orders_history_screen.dart';
import 'screens/account/refunds_history_screen.dart';
import 'screens/account/profile_settings_screen.dart';
import 'screens/addresses/addresses_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/favorites/favorites_screen.dart';
import 'screens/admin/admin_panel_screen.dart';
import 'screens/admin/admin_product_edit_screen.dart';
import 'screens/admin/admin_order_detail_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await SupabaseService.initialize();
  await StripeService.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
        ChangeNotifierProvider(create: (_) => AddressProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, _) {
          return MaterialApp(
            title: 'JGMarket',
            debugShowCheckedModeBanner: false,
            locale: settingsProvider.appLocale,
            supportedLocales: const [
              Locale('es', 'ES'),
              Locale('en', 'US'),
              Locale('fr', 'FR'),
            ],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: settingsProvider.themeMode,
            home: const RootScreen(),
            routes: {
              '/auth': (context) => const LoginScreen(),
              '/login': (context) => const LoginScreen(),
              '/cart': (context) => const CartScreen(),
              '/account': (context) => const AccountScreen(),
              '/orders': (context) => const OrdersHistoryScreen(),
              '/refunds': (context) => const RefundsHistoryScreen(),
              '/profile-settings': (context) => const ProfileSettingsScreen(),
              '/addresses': (context) => const AddressesScreen(),
              '/settings': (context) => const SettingsScreen(),
              '/favorites': (context) => const FavoritesScreen(),
              '/admin': (context) => const AdminPanelScreen(),
              '/admin/products/new': (context) => const AdminProductEditScreen(),
            },
            onGenerateRoute: (settings) {
              final uri = Uri.parse(settings.name ?? '');

              // Ruta de productos con búsqueda o filtro de marca
              if (uri.path == '/products') {
                final searchQuery = uri.queryParameters['q'] ?? '';
                final brandFilter = uri.queryParameters['brand'];
                return MaterialPageRoute(
                  builder: (context) => ProductListScreen(
                    searchQuery: searchQuery,
                    brandFilter: brandFilter,
                  ),
                );
              }

              // Ruta de detalle de producto: /product/{slug}
              if (uri.pathSegments.length == 2 &&
                  uri.pathSegments[0] == 'product') {
                final slug = uri.pathSegments[1];
                return MaterialPageRoute(
                  builder: (context) => ProductDetailScreen(slug: slug),
                );
              }

              // Ruta de edición de producto: /admin/products/{id}
              if (uri.pathSegments.length == 3 &&
                  uri.pathSegments[0] == 'admin' &&
                  uri.pathSegments[1] == 'products') {
                final productId = uri.pathSegments[2];
                return MaterialPageRoute(
                  builder: (context) =>
                      AdminProductEditScreen(productId: productId),
                );
              }

              // Ruta de detalle de pedido: /admin/orders/{id}
              if (uri.pathSegments.length == 3 &&
                  uri.pathSegments[0] == 'admin' &&
                  uri.pathSegments[1] == 'orders') {
                final orderId = uri.pathSegments[2];
                return MaterialPageRoute(
                  builder: (context) => AdminOrderDetailScreen(orderId: orderId),
                );
              }

              // Ruta de productos por categoría: /category/{slug}
              if (uri.pathSegments.length == 2 &&
                  uri.pathSegments[0] == 'category') {
                final categorySlug = uri.pathSegments[1];
                return MaterialPageRoute(
                  builder: (context) =>
                      ProductListScreen(categorySlug: categorySlug),
                );
              }

              // Ruta de ofertas
              if (settings.name == '/sales' || settings.name == '/ofertas') {
                return MaterialPageRoute(
                  builder: (context) => const ProductListScreen(onlyOnSale: true),
                );
              }

              return null;
            },
          );
        },
      ),
    );
  }
}
