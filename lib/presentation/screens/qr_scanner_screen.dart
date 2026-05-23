import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/supabase_service.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final _supabaseService = SupabaseService();
  bool _isProcessing = false;

  Future<void> _processScan(String code) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      // 1. Intentar ver si es un Pedido de Boutique (ID de Pedido)
      final orderRes = await Supabase.instance.client
          .from('orders')
          .select('*, profiles(full_name)')
          .eq('id', code)
          .maybeSingle();

      if (orderRes != null) {
        _showOrderDetails(orderRes);
        return;
      }

      // 2. Si no es pedido, intentar ver si es un Usuario (ID de Black Card)
      final profileRes = await Supabase.instance.client
          .from('profiles')
          .select('id')
          .eq('id', code)
          .maybeSingle();

      if (profileRes != null) {
        await _supabaseService.addVisitToUser(code);
        _showVisitSuccess();
        return;
      }

      throw "Código no reconocido por el sistema CAMIL";
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _showOrderDetails(Map<String, dynamic> order) {
    final List items = order['items'] as List;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111111),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.shopping_bag, color: AppColors.primary, size: 48),
            const SizedBox(height: 16),
            const Text("PEDIDO BOUTIQUE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 2)),
            Text("Cliente: ${order['profiles']['full_name']}", style: const TextStyle(color: Colors.white38)),
            const Divider(color: Colors.white10, height: 40),
            ...items.map((item) => ListTile(
              leading: const Icon(Icons.check, color: Colors.green, size: 16),
              title: Text(item['name'], style: const TextStyle(color: Colors.white, fontSize: 14)),
              trailing: Text("x${item['qty']}", style: const TextStyle(color: AppColors.primary)),
            )).toList(),
            const Divider(color: Colors.white10, height: 40),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text("TOTAL A COBRAR:", style: TextStyle(fontWeight: FontWeight.bold)),
              Text("\$${order['total_amount']}", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w900, fontSize: 20)),
            ]),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () async {
                await Supabase.instance.client.from('orders').update({'status': 'delivered'}).eq('id', order['id']);
                Navigator.pop(context);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Pedido Entregado con Éxito")));
              },
              child: const Text("CONFIRMAR ENTREGA"),
            ),
          ],
        ),
      ),
    );
  }

  void _showVisitSuccess() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("¡VISITA REGISTRADA!"), backgroundColor: Colors.green));
    Navigator.pop(context);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text('ESCÁNER MAESTRO'), backgroundColor: Colors.transparent),
      body: Stack(
        children: [
          MobileScanner(
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                _processScan(barcodes.first.rawValue!);
              }
            },
          ),
          Center(
            child: Container(
              width: 260, height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.5), width: 2),
                borderRadius: BorderRadius.circular(32),
              ),
            ),
          ),
          if (_isProcessing) const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        ],
      ),
    );
  }
}
