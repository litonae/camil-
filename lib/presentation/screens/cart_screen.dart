import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/supabase_service.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _supabaseService = SupabaseService();
  bool _orderConfirmed = false;
  String? _orderId;

  // Lógica de carrito simulada (en una app real usarías Riverpod/Provider)
  final List<Map<String, dynamic>> _items = [
    {'name': 'Cera Matte Premium', 'price': 25.0, 'qty': 1},
    {'name': 'Aceite Barba Wood', 'price': 18.0, 'qty': 1},
  ];

  double get _total => _items.fold(0, (sum, item) => sum + (item['price'] * item['qty']));

  Future<void> _processOrder() async {
    setState(() => _orderConfirmed = true);
    final id = await _supabaseService.createOrder(_items, _total);
    setState(() => _orderId = id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text('TU SESIÓN DE COMPRA', style: TextStyle(fontSize: 12, letterSpacing: 2))),
      body: _orderConfirmed ? _buildOrderSuccess() : _buildCartItems(),
    );
  }

  Widget _buildCartItems() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _items.length,
              itemBuilder: (ctx, i) => Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: const Color(0xFF111111), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)),
                child: Row(
                  children: [
                    const Icon(Icons.inventory_2_outlined, color: AppColors.primary),
                    const SizedBox(width: 16),
                    Expanded(child: Text(_items[i]['name'], style: const TextStyle(fontWeight: FontWeight.bold))),
                    Text("\$${_items[i]['price']}", style: const TextStyle(color: Colors.white38)),
                  ],
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(32),
            decoration: const BoxDecoration(color: Color(0xFF0D0D0D), borderRadius: BorderRadius.vertical(top: Radius.circular(40))),
            child: Column(
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text("TOTAL ESTIMADO", style: TextStyle(color: Colors.white24, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  Text("\$$_total", style: GoogleFonts.sora(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.primary)),
                ]),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity, height: 60,
                  child: ElevatedButton(onPressed: _processOrder, child: const Text("CONFIRMAR Y GENERAR QR")),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSuccess() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.green, size: 80).animate().scale(),
            const SizedBox(height: 32),
            const Text("¡ORDEN GENERADA!", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 3)),
            const SizedBox(height: 12),
            const Text("Muestra este código en la recepción para recoger tus productos premium.", textAlign: TextAlign.center, style: TextStyle(color: Colors.white38)),
            const SizedBox(height: 40),
            if (_orderId != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                child: QrImageView(data: _orderId!, size: 200, version: QrVersions.auto),
              ).animate().fadeIn(delay: 500.ms).scale(),
            const SizedBox(height: 60),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("VOLVER A LA BOUTIQUE", style: TextStyle(color: AppColors.primary))),
          ],
        ),
      ),
    );
  }
}
