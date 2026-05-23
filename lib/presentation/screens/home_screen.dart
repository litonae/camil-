import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/supabase_service.dart';
import '../widgets/custom_nav_bar.dart';
import 'store_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';
import 'atelier_screen.dart';
import 'black_card_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  void _onTabChange(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    // Definimos las pantallas aquí para poder pasar el callback _onTabChange
    final List<Widget> screens = [
      HomeContent(onTabChange: _onTabChange), // 0
      StoreScreen(),                          // 1: BOUTIQUE PREMIUM
      BlackCardScreen(),                      // 2
      HistoryScreen(),                        // 3
      ProfileScreen(),                        // 4
    ];

    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: screens,
          ),
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: CustomNavBar(
              currentIndex: _currentIndex,
              onTap: (index) {
                if(index == 99) {
                  Navigator.pushNamed(context, '/barber-vision');
                } else {
                  _onTabChange(index);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class HomeContent extends StatefulWidget {
  final Function(int) onTabChange;
  const HomeContent({super.key, required this.onTabChange});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  final _supabaseService = SupabaseService();
  String _userName = 'Danae';
  String? _avatarUrl;
  List<Map<String, dynamic>> _topServices = [];
  List<Map<String, dynamic>> _barbers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    final user = Supabase.instance.client.auth.currentUser;
    try {
      setState(() => _isLoading = true);
      final profile = await _supabaseService.getMyProfile();
      final services = await _supabaseService.getServices();
      final barbers = await _supabaseService.getBarbers();
      
      if (mounted) {
        setState(() {
          if (user != null) {
            _userName = profile?['full_name']?.split(' ')[0] ?? user.userMetadata?['full_name'] ?? 'Cliente';
            _avatarUrl = profile?['avatar_url'] ?? user.userMetadata?['avatar_url'];
          }
          _topServices = services.take(3).toList();
          _barbers = barbers;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadAllData,
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 32),
            _buildBarberVisionBanner(context),
            const SizedBox(height: 32),
            
            const Text('Barberos Destacados', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildBarbersHorizontalList(),

            const SizedBox(height: 32),
            const Text('Tu actividad', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: _supabaseService.getAppointmentsStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.isEmpty) return _buildEmptyCard();
                final myId = Supabase.instance.client.auth.currentUser?.id;
                final myApps = snapshot.data!.where((a) => a['user_id'] == myId && (a['status'] == 'confirmed' || a['status'] == 'pending')).toList();
                if (myApps.isEmpty) return _buildEmptyCard();
                return _buildActiveCard(myApps.first);
              },
            ),

            const SizedBox(height: 32),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Cortes Atelier', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextButton(onPressed: () => widget.onTabChange(1), child: const Text('Ver todos', style: TextStyle(color: AppColors.primary))),
            ]),
            const SizedBox(height: 16),
            _buildServicesPreview(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Hola, $_userName', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
            const Text('¿Listo para tu cambio?', style: TextStyle(color: AppColors.textSecondary)),
          ]),
        ),
        const SizedBox(width: 16),
        ClipOval(child: Container(width: 50, height: 50, color: AppColors.surface, child: _avatarUrl != null ? CachedNetworkImage(imageUrl: _avatarUrl!, fit: BoxFit.cover, memCacheWidth: 100) : const Icon(Icons.person, color: Colors.white24))),
      ],
    );
  }

  Widget _buildActiveCard(Map<String, dynamic> app) {
    final date = DateTime.parse(app['appointment_date']);
    return GestureDetector(
      onTap: () => widget.onTabChange(3),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.primary.withValues(alpha: 0.5))),
        child: Row(children: [
          const Icon(Icons.calendar_today, color: AppColors.primary),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('PRÓXIMA CITA', style: TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold)),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(DateFormat('EEEE, d MMM - hh:mm a', 'es').format(date).toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ])),
          const SizedBox(width: 10),
          const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white24),
        ]),
      ),
    ).animate().shimmer();
  }

  Widget _buildEmptyCard() {
    return GestureDetector(
      onTap: () => widget.onTabChange(1),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.border)),
        child: const Row(children: [
          Icon(Icons.add_circle_outline, color: Colors.white24),
          SizedBox(width: 16),
          Expanded(
            child: Text('Sin citas próximas. Agenda una ahora.', 
              style: TextStyle(color: Colors.white38),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildBarbersHorizontalList() {
    if (_isLoading) return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()));
    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _barbers.length,
        itemBuilder: (context, index) {
          final b = _barbers[index];
          return Container(
            margin: const EdgeInsets.only(right: 20),
            child: Column(children: [
              ClipOval(child: CachedNetworkImage(imageUrl: b['image_url'] ?? '', width: 65, height: 65, fit: BoxFit.cover, memCacheWidth: 150)),
              const SizedBox(height: 8),
              Text(b['full_name']?.split(' ')[0] ?? 'Barbero', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            ]),
          );
        },
      ),
    );
  }

  Widget _buildServicesPreview() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    return Column(
      children: _topServices.map((s) => Container(
        margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
        child: InkWell(onTap: () => widget.onTabChange(1), child: Row(children: [
          ClipRRect(borderRadius: BorderRadius.circular(10), child: CachedNetworkImage(imageUrl: s['image_url'] ?? '', width: 50, height: 50, fit: BoxFit.cover, memCacheWidth: 100)),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(s['name'], style: const TextStyle(fontWeight: FontWeight.bold)), Text('\$${s['price']}', style: const TextStyle(color: AppColors.primary, fontSize: 12))])),
          const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white24),
        ])),
      )).toList(),
    );
  }

  Widget _buildBarberVisionBanner(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/barber-vision'),
      child: Container(
        width: double.infinity, height: 160,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), image: const DecorationImage(image: CachedNetworkImageProvider('https://images.pexels.com/photos/1319461/pexels-photo-1319461.jpeg?auto=compress&cs=tinysrgb&w=800'), fit: BoxFit.cover, colorFilter: ColorFilter.mode(Colors.black54, BlendMode.darken))),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), gradient: LinearGradient(begin: Alignment.centerLeft, end: Alignment.centerRight, colors: [Colors.black.withValues(alpha: 0.9), Colors.transparent])),
          child: const Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('BARBERVISION™', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2)),
            Text('ESCÁNER FACIAL IA', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 3)),
            SizedBox(height: 16),
            Text('PROBAR AHORA →', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
          ]),
        ),
      ),
    );
  }
}
