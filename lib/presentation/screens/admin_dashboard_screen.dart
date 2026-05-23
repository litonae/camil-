import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/supabase_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _supabaseService = SupabaseService();
  double _monthlySales = 0;
  int _todayCitas = 0;
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _refreshDashboard();
  }

  Future<void> _refreshDashboard() async {
    setState(() => _isLoadingStats = true);
    try {
      final sales = await _supabaseService.getMonthlySales();
      final count = await _supabaseService.getTodayAppointmentsCount();
      if (mounted) {
        setState(() {
          _monthlySales = sales;
          _todayCitas = count;
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingStats = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('DASHBOARD REAL', style: TextStyle(letterSpacing: 2, fontSize: 14, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.sync, color: AppColors.primary), onPressed: _refreshDashboard),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white70),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (mounted) Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshDashboard,
        color: AppColors.primary,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // STATS CARDS
              Row(
                children: [
                  _buildStatCard('Citas Hoy', _todayCitas.toString(), Icons.calendar_today),
                  const SizedBox(width: 16),
                  _buildStatCard('Ventas Mes', '\$${_monthlySales.toInt()}', Icons.monetization_on_outlined),
                ],
              ).animate().fadeIn().slideY(begin: 0.1),

              const SizedBox(height: 40),
              _buildActions(context),
              const SizedBox(height: 40),
              
              const Text('AGENDA RÁPIDA', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white38, letterSpacing: 2)),
              const SizedBox(height: 16),
              _buildAgendaMiniList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.border)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.primary, size: 24),
            const SizedBox(height: 12),
            _isLoadingStats 
              ? const SizedBox(height: 30, width: 30, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(value, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white)),
            Text(title.toUpperCase(), style: const TextStyle(color: Colors.white24, fontSize: 9, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _actionBtn(context, 'AGENDA', Icons.event_note, '/manage-appointments')),
            const SizedBox(width: 16),
            Expanded(child: _actionBtn(context, 'ESCANEAR QR', Icons.qr_code_scanner, '/qr-scanner')),
          ],
        ),
        const SizedBox(height: 16),
        _actionBtn(context, 'CATÁLOGO DE CORTES', Icons.content_cut, '/manage-catalog'),
        const SizedBox(height: 16),
        _actionBtn(context, 'EQUIPO DE BARBEROS', Icons.people_alt_outlined, '/manage-barbers'),
        const SizedBox(height: 16),
        _actionBtn(context, 'GESTIONAR BOUTIQUE', Icons.shopping_bag_outlined, '/manage-boutique'),
      ],
    );
  }

  Widget _actionBtn(BuildContext context, String title, IconData icon, String route) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, route).then((_) => _refreshDashboard()),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 22),
        decoration: BoxDecoration(
          gradient: AppColors.premiumGradient,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildAgendaMiniList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _supabaseService.getAppointmentsStream(),
      builder: (context, snapshot) {
        final apps = snapshot.data ?? [];
        final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
        final todayApps = apps.where((a) => DateFormat('yyyy-MM-dd').format(DateTime.parse(a['appointment_date'])) == todayStr).toList();

        if (todayApps.isEmpty) return const Text('Sin citas para hoy', style: TextStyle(color: Colors.white10));

        return Column(
          children: todayApps.take(3).map((app) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                Text(DateFormat('hh:mm a').format(DateTime.parse(app['appointment_date'])), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(width: 12),
                const Text('Cliente en agenda', style: TextStyle(color: Colors.white70, fontSize: 12)),
                const Spacer(),
                Icon(app['status'] == 'completed' ? Icons.check_circle : Icons.timer, color: app['status'] == 'completed' ? Colors.green : Colors.orange, size: 14),
              ],
            ),
          )).toList(),
        );
      },
    );
  }
}
