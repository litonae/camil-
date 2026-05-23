import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/supabase_service.dart';
import 'booking_screen.dart';

class AtelierScreen extends StatefulWidget {
  const AtelierScreen({super.key});

  @override
  State<AtelierScreen> createState() => _AtelierScreenState();
}

class _AtelierScreenState extends State<AtelierScreen> {
  final _supabaseService = SupabaseService();
  List<Map<String, dynamic>> _services = [];
  String? _avatarUrl;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final servicesData = await _supabaseService.getServices();
      final profileData = await _supabaseService.getMyProfile();
      final user = Supabase.instance.client.auth.currentUser;

      if (mounted) {
        setState(() {
          _services = servicesData;
          // Prioridad: 1. Perfil BD, 2. Metadata Google, 3. Imagen vacía
          _avatarUrl = profileData?['avatar_url'] ?? user?.userMetadata?['avatar_url'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showDetailModal(Map<String, dynamic> service) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 30),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: CachedNetworkImage(
                        imageUrl: service['image_url'] ?? '',
                        width: double.infinity, height: 300, fit: BoxFit.cover,
                        memCacheWidth: 400, // Optimizado
                        placeholder: (context, url) => Container(color: Colors.white10),
                        errorWidget: (context, url, error) => const Icon(Icons.cut, color: Colors.white10, size: 50),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(service['name'] ?? '', style: GoogleFonts.playfairDisplay(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.timer_outlined, size: 14, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text("${service['duration_minutes']} MINUTOS DE PRECISIÓN", style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text('FILOSOFÍA DEL CORTE', style: TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Text(service['philosophy'] ?? service['description'] ?? 'Sin descripción disponible.', style: const TextStyle(color: Colors.white70, fontSize: 15, height: 1.6)),
                    const SizedBox(height: 24),
                    if (service['style_tips'] != null) ...[
                      const Text('TIPS DE ESTILO', style: TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Text(service['style_tips'], style: const TextStyle(color: Colors.white70, fontSize: 14, fontStyle: FontStyle.italic)),
                    ],
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity, height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(context, MaterialPageRoute(builder: (context) => BookingScreen(selectedService: service)));
                        },
                        child: const Text('AGENDAR ESTE SERVICIO'),
                      ),
                    ),
                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
        : CustomScrollView(
            slivers: [
              _buildAppBar(),
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 30),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text('El Menú\nAtelier', style: GoogleFonts.playfairDisplay(fontSize: 48, fontWeight: FontWeight.bold, height: 1.1, color: Colors.white)).animate().fadeIn(),
                    ),
                    const SizedBox(height: 40),
                    
                    _buildCategoryRow('Cortes Premium'),
                    _buildCategoryRow('Barba y Rostro'),
                    _buildCategoryRow('Servicios Extra'),
                    
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      backgroundColor: Colors.black,
      floating: true, pinned: true, elevation: 0,
      centerTitle: true,
      title: Text('BARBER CAMIL', style: GoogleFonts.sora(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 4)),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 20),
          child: ClipOval(
            child: Container(
              width: 34, height: 34,
              color: AppColors.surface,
              child: _avatarUrl != null 
                ? CachedNetworkImage(
                    imageUrl: _avatarUrl!,
                    fit: BoxFit.cover,
                    memCacheWidth: 100, // Ultra ligero
                    placeholder: (context, url) => const Icon(Icons.person, color: Colors.white10),
                    errorWidget: (context, url, error) => const Icon(Icons.person, color: Colors.white24),
                  )
                : const Icon(Icons.person, color: Colors.white24, size: 20),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryRow(String categoryName) {
    final categoryServices = _services.where((s) => s['category'] == categoryName).toList();
    if (categoryServices.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Text(categoryName.toUpperCase(), style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 2)),
        ),
        SizedBox(
          height: 280, // Reducido un poco para mayor estabilidad
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: categoryServices.length,
            itemBuilder: (context, index) {
              final service = categoryServices[index];
              return _buildCarouselItem(service, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCarouselItem(Map<String, dynamic> service, int index) {
    final String price = (service['price'] as num?)?.toInt().toString() ?? '0';

    return RepaintBoundary(
      child: GestureDetector(
        onTap: () => _showDetailModal(service),
        child: Container(
          width: 200,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: CachedNetworkImage(
                        imageUrl: service['image_url'] ?? '',
                        width: double.infinity, height: double.infinity, fit: BoxFit.cover,
                        memCacheWidth: 200, // OPTIMIZACIÓN EXTREMA (Antes 300)
                        placeholder: (context, url) => Container(color: Colors.white.withValues(alpha: 0.05)),
                        errorWidget: (context, url, error) => const Icon(Icons.cut, color: Colors.white10),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withValues(alpha: 0.9)]),
                      ),
                    ),
                    Positioned(
                      bottom: 12, right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(10)),
                        child: Text("\$$price", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(service['name'] ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
              Text("${service['duration_minutes']} MIN", style: const TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 1)),
            ],
          ),
        ),
      ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.1, end: 0),
    );
  }
}
