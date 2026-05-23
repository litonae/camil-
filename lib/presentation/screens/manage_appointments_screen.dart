import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/supabase_service.dart';

class ManageAppointmentsScreen extends StatefulWidget {
  const ManageAppointmentsScreen({super.key});

  @override
  State<ManageAppointmentsScreen> createState() => _ManageAppointmentsScreenState();
}

class _ManageAppointmentsScreenState extends State<ManageAppointmentsScreen> with SingleTickerProviderStateMixin {
  final _supabaseService = SupabaseService();
  late TabController _tabController;
  
  List<Map<String, dynamic>> _profiles = [];
  List<Map<String, dynamic>> _services = [];
  List<Map<String, dynamic>> _barbers = [];
  bool _dataReady = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadReferenceData();
  }

  Future<void> _loadReferenceData() async {
    try {
      // Cargamos todas las referencias de una vez para cruzarlas con el Stream
      final p = await Supabase.instance.client.from('profiles').select();
      final s = await _supabaseService.getServices();
      final b = await _supabaseService.getBarbers();
      if (mounted) {
        setState(() {
          _profiles = List<Map<String, dynamic>>.from(p);
          _services = s;
          _barbers = b;
          _dataReady = true;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _dataReady = true);
    }
  }

  Future<void> _updateStatus(String id, String status) async {
    await _supabaseService.updateAppointmentStatus(id, status);
  }

  Future<void> _deleteAppointment(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('¿BORRAR REGISTRO?'),
        content: const Text('Esta acción eliminará la cita permanentemente.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCELAR')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('ELIMINAR', style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
    if (confirm == true) await _supabaseService.deleteAppointment(id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('CONTROL DE AGENDA', style: TextStyle(fontSize: 14, letterSpacing: 2)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          tabs: const [Tab(text: 'HOY'), Tab(text: 'PRÓXIMAS'), Tab(text: 'HISTORIAL')],
        ),
      ),
      body: !_dataReady 
        ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
        : StreamBuilder<List<Map<String, dynamic>>>(
            stream: _supabaseService.getAppointmentsStream(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final appointments = snapshot.data!;

              return TabBarView(
                controller: _tabController,
                children: [
                  _buildList(appointments, 'today'),
                  _buildList(appointments, 'upcoming'),
                  _buildList(appointments, 'history'),
                ],
              );
            },
          ),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> apps, String filter) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final filtered = apps.where((app) {
      final date = DateTime.parse(app['appointment_date']);
      final appDay = DateTime(date.year, date.month, date.day);
      final status = app['status']?.toString() ?? 'pending';
      final isFinished = status == 'completed' || status == 'cancelled' || status == 'no-show';

      if (filter == 'today') return appDay.isAtSameMomentAs(today) && !isFinished;
      if (filter == 'upcoming') return appDay.isAfter(today) && !isFinished;
      return appDay.isBefore(today) || isFinished;
    }).toList();

    if (filtered.isEmpty) return const Center(child: Text('Sin actividad', style: TextStyle(color: Colors.white10)));

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final app = filtered[index];
        final date = DateTime.parse(app['appointment_date']);
        
        // CRUCE DE DATOS SEGURO (Buscamos por ID en nuestras listas de referencia)
        final client = _profiles.firstWhere((p) => p['id'] == app['user_id'], orElse: () => {});
        final service = _services.firstWhere((s) => s['id'].toString() == app['service_id'].toString(), orElse: () => {});
        final barber = _barbers.firstWhere((b) => b['id'].toString() == app['barber_id'].toString(), orElse: () => {});

        final String cName = client['full_name'] ?? 'Usuario CAMIL';
        final String cEmail = client['email'] ?? 'Sin correo';
        final String sName = service['name'] ?? 'Corte Atelier';
        final String bName = barber['full_name'] ?? 'Asignado';

        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface, 
            borderRadius: BorderRadius.circular(24), 
            border: Border.all(color: Colors.white.withValues(alpha: 0.05))
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(DateFormat('hh:mm a').format(date).toUpperCase(), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 24)),
                  _statusChip(app['status']),
                ],
              ),
              const SizedBox(height: 12),
              Text(cName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              Text(cEmail, style: const TextStyle(color: Colors.white24, fontSize: 12)),
              const SizedBox(height: 16),
              Text("Servicio: $sName", style: const TextStyle(color: Colors.white70)),
              Text("Barbero: $bName", style: const TextStyle(color: Colors.white38, fontSize: 12)),
              const SizedBox(height: 24),
              if (app['status'] == 'pending' || app['status'] == 'confirmed')
                Row(
                  children: [
                    _actionBtn('TERMINAR', Colors.blue, () => _updateStatus(app['id'], 'completed')),
                    const SizedBox(width: 8),
                    _actionBtn('FALTA', Colors.purple, () => _updateStatus(app['id'], 'no-show')),
                    const SizedBox(width: 8),
                    _actionBtn('X', Colors.orange, () => _updateStatus(app['id'], 'cancelled')),
                    IconButton(icon: const Icon(Icons.delete_forever, color: Colors.white10, size: 20), onPressed: () => _deleteAppointment(app['id'])),
                  ],
                ),
            ],
          ),
        ).animate().fadeIn(delay: (index * 50).ms);
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
    );
  }

  Widget _actionBtn(String label, Color color, VoidCallback onTap) {
    return Expanded(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withValues(alpha: 0.1), 
          foregroundColor: color, 
          elevation: 0, 
          padding: const EdgeInsets.symmetric(vertical: 12), 
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
        ),
        onPressed: onTap,
        child: Text(label, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
