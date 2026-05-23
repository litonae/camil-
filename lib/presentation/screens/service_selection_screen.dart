import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/supabase_service.dart';

class ServiceSelectionScreen extends StatefulWidget {
  const ServiceSelectionScreen({super.key});

  @override
  State<ServiceSelectionScreen> createState() => _ServiceSelectionScreenState();
}

class _ServiceSelectionScreenState extends State<ServiceSelectionScreen> {
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
      appBar: AppBar(
        title: const Text('SELECCIONA TU SERVICIO', style: TextStyle(fontSize: 14, letterSpacing: 2)),
        backgroundColor: Colors.transparent, elevation: 0,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
        : ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _buildCategorySection('Cortes Premium'),
              _buildCategorySection('Barba y Rostro'),
              _buildCategorySection('Servicios Extra'),
              const SizedBox(height: 100),
            ],
          ),
    );
  }

  Widget _buildCategorySection(String categoryName) {
    final categoryServices = _services.where((s) => s['category'] == categoryName).toList();
    
    if (categoryServices.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(categoryName.toUpperCase(), 
            style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2)),
        ),
        ...categoryServices.map((service) => _buildServiceTile(service)).toList(),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildServiceTile(Map<String, dynamic> service) {
    final String name = service['name']?.toString() ?? 'Servicio';
    final String duration = service['duration_minutes']?.toString() ?? '0';
    final String price = (service['price'] as num?)?.toInt().toString() ?? '0';
    final String? imageUrl = service['image_url'];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: imageUrl != null 
              ? CachedNetworkImage(
                  imageUrl: imageUrl,
                  width: 70, height: 70, fit: BoxFit.cover,
                  errorWidget: (context, url, error) => const Icon(Icons.cut, color: Colors.white10),
                )
              : Container(width: 70, height: 70, color: Colors.white10, child: const Icon(Icons.cut, color: Colors.white24)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text("$duration MIN", style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          Text("\$$price", style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.add_circle, color: AppColors.primary),
            onPressed: () => Navigator.pushNamed(context, '/booking'),
          ),
        ],
      ),
    ).animate().fadeIn().slideX(begin: 0.1);
  }
}
