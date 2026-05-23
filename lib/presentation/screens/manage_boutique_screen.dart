import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/supabase_service.dart';
import 'edit_product_screen.dart';

class ManageBoutiqueScreen extends StatefulWidget {
  const ManageBoutiqueScreen({super.key});

  @override
  State<ManageBoutiqueScreen> createState() => _ManageBoutiqueScreenState();
}

class _ManageBoutiqueScreenState extends State<ManageBoutiqueScreen> {
  final _supabaseService = SupabaseService();
  List<Map<String, dynamic>> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    try {
      final data = await _supabaseService.getProducts();
      if (mounted) {
        setState(() {
          _products = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('GESTIÓN DE BOUTIQUE', style: TextStyle(fontSize: 14, letterSpacing: 2)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_shopping_cart, color: AppColors.primary),
            onPressed: () => Navigator.pushNamed(context, '/add-product').then((_) => _fetchProducts()),
          )
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
        : _products.isEmpty 
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: _products.length,
              itemBuilder: (context, index) {
                final item = _products[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: InkWell(
                    onTap: () => Navigator.push(
                      context, 
                      MaterialPageRoute(builder: (context) => EditProductScreen(product: item))
                    ).then((_) => _fetchProducts()),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CachedNetworkImage(
                            imageUrl: item['image_url'] ?? '',
                            width: 60, height: 60, fit: BoxFit.cover,
                            memCacheWidth: 150,
                            memCacheHeight: 150,
                            errorWidget: (context, url, error) => const Icon(Icons.inventory_2, color: Colors.white10),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item['name'] ?? 'Sin nombre', style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text('\$${item['price']}', style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.bold)),
                              Text('Stock: ${item['stock'] ?? 0}', style: const TextStyle(color: Colors.white24, fontSize: 11)),
                            ],
                          ),
                        ),
                        const Icon(Icons.edit, size: 20, color: Colors.white24),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.1);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.shopping_bag_outlined, size: 60, color: Colors.white10),
          const SizedBox(height: 16),
          const Text('No hay productos en la boutique', style: TextStyle(color: Colors.white38)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/add-product').then((_) => _fetchProducts()),
            child: const Text('AGREGAR MI PRIMER PRODUCTO'),
          )
        ],
      ),
    );
  }
}
