import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/supabase_service.dart';
import 'booking_screen.dart';

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> with SingleTickerProviderStateMixin {
  final _supabaseService = SupabaseService();
  late TabController _tabController;
  
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _services = [];
  bool _isLoading = true;

  // Filtros actuales
  String _selectedServiceCat = 'TODOS';
  String _selectedProductCat = 'TODOS';

  final List<String> _serviceCategories = ['TODOS', 'Cortes Premium', 'Barba y Rostro', 'Servicios Extra'];
  final List<String> _productCategories = ['TODOS', 'CERAS', 'ACEITES', 'SHAMPOOS', 'PREMIUM'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    try {
      final p = await _supabaseService.getProducts();
      final s = await _supabaseService.getServices();
      if (mounted) {
        setState(() {
          _products = p;
          _services = s;
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
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        backgroundColor: const Color(0xFF050505),
        elevation: 0,
        toolbarHeight: 110,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("EXPERIENCIA", style: GoogleFonts.sora(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 4)),
            const SizedBox(height: 4),
            Text("ATELIER & BOUTIQUE", style: GoogleFonts.playfairDisplay(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16, top: 10),
            child: IconButton(
              icon: const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 28),
              onPressed: () => Navigator.pushNamed(context, '/cart'),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          indicatorSize: TabBarIndicatorSize.label,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white24,
          labelStyle: GoogleFonts.sora(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 2),
          tabs: const [Tab(text: "SERVICIOS"), Tab(text: "PRODUCTOS")],
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
        : TabBarView(
            controller: _tabController,
            children: [
              _buildContentPage(isService: true),
              _buildContentPage(isService: false),
            ],
          ),
    );
  }

  Widget _buildContentPage({required bool isService}) {
    final categories = isService ? _serviceCategories : _productCategories;
    final selectedCat = isService ? _selectedServiceCat : _selectedProductCat;

    return Column(
      children: [
        const SizedBox(height: 20),
        // Pastillas de Categoría
        SizedBox(
          height: 45,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: categories.length,
            itemBuilder: (ctx, i) {
              final cat = categories[i];
              final isSelected = selectedCat == cat;
              return GestureDetector(
                onTap: () => setState(() {
                  if (isService) _selectedServiceCat = cat; else _selectedProductCat = cat;
                }),
                child: Container(
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isSelected ? AppColors.primary : Colors.white10),
                  ),
                  child: Text(cat.toUpperCase(), style: TextStyle(color: isSelected ? Colors.white : Colors.white38, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1)),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: selectedCat == 'TODOS' 
            ? _buildGroupedLayout(isService: isService)
            : _buildFilteredGrid(isService: isService, category: selectedCat),
        ),
      ],
    );
  }

  // --- DISEÑO DE CARRUSELES AGRUPADOS (Cuando está en TODOS) ---
  Widget _buildGroupedLayout({required bool isService}) {
    final categories = isService 
        ? _serviceCategories.where((c) => c != 'TODOS').toList()
        : _productCategories.where((c) => c != 'TODOS').toList();

    return ListView.builder(
      padding: const EdgeInsets.only(top: 10, bottom: 120),
      itemCount: categories.length,
      itemBuilder: (ctx, i) {
        final cat = categories[i];
        final items = isService 
            ? _services.where((s) => s['category'] == cat).toList()
            : _products.where((p) => p['category'] == cat).toList();

        if (items.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(cat.toUpperCase(), style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 2)),
                  const Icon(Icons.arrow_forward_ios, size: 10, color: Colors.white10),
                ],
              ),
            ),
            SizedBox(
              height: 280,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: items.length,
                itemBuilder: (context, index) => _buildCarouselItem(items[index], isService: isService, index: index),
              ),
            ),
          ],
        );
      },
    );
  }

  // --- DISEÑO DE GRILLA FILTRADA (Cuando selecciona una pastilla) ---
  Widget _buildFilteredGrid({required bool isService, required String category}) {
    final items = isService 
        ? _services.where((s) => s['category'] == category).toList()
        : _products.where((p) => p['category'] == category).toList();

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 120),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 20, crossAxisSpacing: 20, childAspectRatio: 0.72),
      itemCount: items.length,
      itemBuilder: (ctx, i) => _buildGridItem(items[i], isService: isService),
    );
  }

  Widget _buildCarouselItem(Map<String, dynamic> item, {required bool isService, required int index}) {
    return Container(
      width: 190,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: _buildItemCardContent(item, isService: isService),
    ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.1);
  }

  Widget _buildGridItem(Map<String, dynamic> item, {required bool isService}) {
    return _buildItemCardContent(item, isService: isService);
  }

  Widget _buildItemCardContent(Map<String, dynamic> item, {required bool isService}) {
    final String price = (item['price'] as num?)?.toInt().toString() ?? '0';

    return GestureDetector(
      onTap: () => isService ? _showServiceDetail(item) : _showProductDetail(item),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: CachedNetworkImage(
                    imageUrl: item['image_url'] ?? '',
                    width: double.infinity, height: double.infinity, fit: BoxFit.cover,
                    memCacheWidth: 350,
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withValues(alpha: 0.8)],
                    ),
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
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['name'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                Text(isService ? "${item['duration_minutes']} MIN" : (item['category'] ?? 'BOUTIQUE'), style: const TextStyle(color: Colors.white30, fontSize: 9, letterSpacing: 1)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showServiceDetail(Map<String, dynamic> service) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _buildDetailModal(service, isService: true),
    );
  }

  void _showProductDetail(Map<String, dynamic> product) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _buildDetailModal(product, isService: false),
    );
  }

  Widget _buildDetailModal(Map<String, dynamic> item, {required bool isService}) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(color: Color(0xFF0A0A0A), borderRadius: BorderRadius.vertical(top: Radius.circular(40))),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: CachedNetworkImage(imageUrl: item['image_url'] ?? '', width: double.infinity, height: 350, fit: BoxFit.cover),
            ),
            const SizedBox(height: 32),
            Text(item['name'] ?? '', style: GoogleFonts.playfairDisplay(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 8),
            Text("\$${item['price']}", style: const TextStyle(color: AppColors.primary, fontSize: 24, fontWeight: FontWeight.w900)),
            const SizedBox(height: 24),
            const Text("ANÁLISIS IA", style: TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2)),
            const SizedBox(height: 12),
            Text(isService ? (item['philosophy'] ?? "Un corte diseñado para resaltar tu estructura ósea.") : (item['ai_tip'] ?? "Ideal para mantener la textura de tu estilo."), 
              style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5)),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity, height: 60,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  if (isService) {
                    Navigator.push(context, MaterialPageRoute(builder: (ctx) => BookingScreen(selectedService: item)));
                  } else {
                    _showSuccessSnackBar();
                  }
                },
                child: Text(isService ? "AGENDAR CITA" : "AÑADIR AL CARRITO"),
              ),
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  void _showSuccessSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart_checkout, color: Colors.white, size: 18),
            SizedBox(width: 12),
            Text("AÑADIDO AL CARRITO PREMIUM", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1)),
          ],
        ),
        backgroundColor: const Color(0xFFC1121F),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: const EdgeInsets.only(bottom: 100, left: 40, right: 40),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
