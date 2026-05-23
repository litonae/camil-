import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/supabase_service.dart';
import 'edit_service_screen.dart';

class ManageCatalogScreen extends StatefulWidget {
  const ManageCatalogScreen({super.key});

  @override
  State<ManageCatalogScreen> createState() => _ManageCatalogScreenState();
}

class _ManageCatalogScreenState extends State<ManageCatalogScreen> {
  final _supabaseService = SupabaseService();
  List<Map<String, dynamic>> _services = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchServices();
  }

  Future<void> _fetchServices() async {
    try {
      final data = await _supabaseService.getServices();
      if (mounted) {
        setState(() {
          _services = data;
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
        title: const Text('CATÁLOGO MAESTRO', style: TextStyle(fontSize: 14, letterSpacing: 2)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle, color: AppColors.primary),
            onPressed: () => Navigator.pushNamed(context, '/add-service').then((_) => _fetchServices()),
          )
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
        : ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _buildCategoryGroup('Cortes Premium'),
              _buildCategoryGroup('Barba y Rostro'),
              _buildCategoryGroup('Servicios Extra'),
              const SizedBox(height: 100),
            ],
          ),
    );
  }

  Widget _buildCategoryGroup(String categoryName) {
    final categoryServices = _services.where((s) => s['category'] == categoryName).toList();
    
    if (categoryServices.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(categoryName.toUpperCase(), 
            style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2)),
        ),
        ...categoryServices.map((item) => _buildServiceItem(item)).toList(),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildServiceItem(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: InkWell(
        onTap: () => Navigator.push(
          context, 
          MaterialPageRoute(builder: (context) => EditServiceScreen(service: item))
        ).then((_) => _fetchServices()),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: item['image_url'] ?? '',
                width: 60, height: 60, fit: BoxFit.cover,
                memCacheWidth: 150, // OPTIMIZACIÓN: Solo usa 150px en memoria
                memCacheHeight: 150,
                placeholder: (context, url) => Container(color: Colors.white.withValues(alpha: 0.05)),
                errorWidget: (context, url, error) => const Icon(Icons.cut, color: Colors.white10),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item['name'] ?? 'Sin nombre', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('\$${item['price']}', style: const TextStyle(color: Colors.white38, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.edit, size: 20, color: Colors.white24),
          ],
        ),
      ),
    ).animate().fadeIn().slideX(begin: 0.1);
  }
}
