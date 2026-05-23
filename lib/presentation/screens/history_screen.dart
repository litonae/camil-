import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/supabase_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _supabaseService = SupabaseService();
  List<Map<String, dynamic>> _allServices = [];
  List<Map<String, dynamic>> _allBarbers = [];
  bool _dataLoaded = false;

  @override
  void initState() {
    super.initState();
    _prepareData();
  }

  Future<void> _prepareData() async {
    try {
      final svs = await _supabaseService.getServices();
      final brbs = await _supabaseService.getBarbers();
      if (mounted) {
        setState(() {
          _allServices = svs;
          _allBarbers = brbs;
          _dataLoaded = true;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _dataLoaded = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('MIS CITAS', style: TextStyle(letterSpacing: 2, fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: !_dataLoaded 
        ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
        : StreamBuilder<List<Map<String, dynamic>>>(
            stream: _supabaseService.getAppointmentsStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              
              final myId = Supabase.instance.client.auth.currentUser?.id;
              final myApps = (snapshot.data ?? []).where((a) => a['user_id'] == myId).toList();

              if (myApps.isEmpty) {
                return const Center(child: Text('No tienes citas agendadas', style: TextStyle(color: Colors.white24)));
              }

              return DefaultTabController(
                length: 2,
                child: Column(
                  children: [
                    const TabBar(
                      indicatorColor: AppColors.primary,
                      labelColor: AppColors.primary,
                      unselectedLabelColor: Colors.white24,
                      tabs: [Tab(text: 'PRÓXIMAS'), Tab(text: 'HISTORIAL')],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _buildList(myApps, isUpcoming: true),
                          _buildList(myApps, isUpcoming: false),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> apps, {required bool isUpcoming}) {
    final List<Map<String, dynamic>> filtered = apps.where((a) {
      final status = a['status']?.toString() ?? 'pending';
      
      // LÓGICA MEJORADA: 
      // Próximas = Todo lo que no ha sido finalizado/cancelado por el admin
      final bool isActive = (status == 'confirmed' || status == 'pending');
      
      return isUpcoming ? isActive : !isActive;
    }).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isUpcoming ? Icons.calendar_today_outlined : Icons.history, size: 40, color: Colors.white10),
            const SizedBox(height: 12),
            Text(isUpcoming ? 'No tienes citas activas' : 'Tu historial está vacío', 
              style: const TextStyle(color: Colors.white12, fontSize: 12)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final item = filtered[index];
        final date = DateTime.parse(item['appointment_date']);
        
        // Búsqueda segura
        final service = _allServices.firstWhere(
          (s) => s['id'].toString() == item['service_id'].toString(), 
          orElse: () => {'name': 'Servicio Atelier'}
        );
        final barber = _allBarbers.firstWhere(
          (b) => b['id'].toString() == item['barber_id'].toString(), 
          orElse: () => {'full_name': 'Barbero Asignado'}
        );

        final String serviceName = service['name'] ?? 'Servicio';
        final String barberName = barber['full_name'] ?? 'Barbero';

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface, 
            borderRadius: BorderRadius.circular(20), 
            border: Border.all(color: AppColors.border)
          ),
          child: Row(
            children: [
              Column(
                children: [
                  Text(DateFormat('dd').format(date), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(DateFormat('MMM').format(date).toUpperCase(), style: const TextStyle(fontSize: 10, color: AppColors.primary)),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(serviceName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    Text("Barbero: $barberName", style: const TextStyle(color: Colors.white38, fontSize: 12)),
                    Text(DateFormat('hh:mm a').format(date), style: const TextStyle(color: AppColors.primary, fontSize: 11)),
                  ],
                ),
              ),
              _statusChip(item['status']?.toString() ?? 'pending'),
            ],
          ),
        ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.1, end: 0);
      },
    );
  }

  Widget _statusChip(String status) {
    Color color = Colors.orange;
    if (status == 'confirmed') color = Colors.green;
    if (status == 'completed') color = Colors.blue;
    if (status == 'no-show') color = Colors.purple;
    if (status == 'cancelled') color = Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold)),
    );
  }
}
