import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/theme/app_theme.dart';
import 'presentation/screens/splash_screen.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/barber_vision_screen_FIXED.dart';
import 'presentation/screens/service_selection_screen.dart';
import 'presentation/screens/booking_screen.dart';
import 'presentation/screens/store_screen.dart';
import 'presentation/screens/cart_screen.dart';
import 'presentation/screens/qr_code_screen.dart';
import 'presentation/screens/map_screen.dart';
import 'presentation/screens/admin_dashboard_screen.dart';
import 'presentation/screens/manage_catalog_screen.dart';
import 'presentation/screens/manage_barbers_screen.dart';
import 'presentation/screens/manage_appointments_screen.dart';
import 'presentation/screens/manage_boutique_screen.dart';
import 'presentation/screens/edit_product_screen.dart';
import 'presentation/screens/black_card_screen.dart';
import 'presentation/screens/qr_scanner_screen.dart';
import 'presentation/screens/edit_barber_screen.dart';
import 'presentation/screens/edit_service_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar formato de fechas en español
  await initializeDateFormatting('es', null);

  // LIMPIEZA TOTAL DE MEMORIA AL INICIAR
  PaintingBinding.instance.imageCache.clear();
  PaintingBinding.instance.imageCache.clearLiveImages();

  // OPTIMIZACIÓN EXTREMA: Límite de memoria muy bajo para evitar cierres en Xiaomi
  PaintingBinding.instance.imageCache.maximumSizeBytes = 30 * 1024 * 1024;

  await Supabase.initialize(
    url: 'https://uagahltzndyunpewixbt.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVhZ2FobHR6bmR5dW5wZXdpeGJ0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg5NDU2NjMsImV4cCI6MjA5NDUyMTY2M30.ZsLN6ggvFDx-SheHqz6N-0xLS7vqphoIMeu74tOcwbo',
  );

  runApp(
    const ProviderScope(
      child: CamilApp(),
    ),
  );
}

class CamilApp extends StatelessWidget {
  const CamilApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CAMIL',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/barber-vision': (context) => const BarberVisionScreen(),
        '/services': (context) => const ServiceSelectionScreen(),
        '/booking': (context) => const BookingScreen(),
        '/store': (context) => const StoreScreen(),
        '/cart': (context) => const CartScreen(),
        '/qr-code': (context) => const QRCodeScreen(),
        '/map': (context) => const MapScreen(),
        '/admin-dashboard': (context) => const AdminDashboardScreen(),
        '/qr-scanner': (context) => const QRScannerScreen(),
        '/manage-catalog': (context) => const ManageCatalogScreen(),
        '/add-service': (context) => const EditServiceScreen(),
        '/manage-barbers': (context) => const ManageBarbersScreen(),
        '/add-barber': (context) => const EditBarberScreen(),
        '/manage-appointments': (context) => const ManageAppointmentsScreen(),
        '/manage-boutique': (context) => const ManageBoutiqueScreen(),
        '/add-product': (context) => const EditProductScreen(),
        '/black-card': (context) => const BlackCardScreen(),
      },
    );
  }
}
