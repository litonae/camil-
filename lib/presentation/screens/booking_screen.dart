import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/supabase_service.dart';

class BookingScreen extends StatefulWidget {
  final Map<String, dynamic>? selectedService;

  const BookingScreen({super.key, this.selectedService});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _supabaseService = SupabaseService();
  List<Map<String, dynamic>> _barbers = [];
  bool _isLoading = true;
  
  DateTime _selectedDate = DateTime.now();
  String _selectedTime = "10:00 AM";

  final List<String> _timeSlots = [
    "10:00 AM", "11:00 AM", "12:00 PM", "1:00 PM", 
    "3:00 PM", "4:00 PM", "5:00 PM", "6:00 PM"
  ];

  @override
  void initState() {
    super.initState();
    _fetchBarbers();
  }

  Future<void> _fetchBarbers() async {
    try {
      final data = await _supabaseService.getBarbers();
      if (mounted) {
        setState(() {
          _barbers = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmBooking() async {
    if (_barbers.isEmpty) {
      _showMsg('No hay barberos disponibles en este momento');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final appointmentDate = DateTime(
        _selectedDate.year, _selectedDate.month, _selectedDate.day,
        int.parse(_selectedTime.split(':')[0]) + (_selectedTime.contains('PM') && !_selectedTime.startsWith('12') ? 12 : 0)
      );

      final isoDate = appointmentDate.toIso8601String();

      // VALIDACIÓN 1: ¿El usuario ya tiene una cita a esta hora?
      final hasDuplicate = await _supabaseService.checkIfUserHasAppointment(isoDate);
      if (hasDuplicate) {
        _showMsg('Ya tienes una cita agendada para este horario.');
        setState(() => _isLoading = false);
        return;
      }

      // VALIDACIÓN 2: ¿Barberos saturados?
      final count = await _supabaseService.getAppointmentCountForSlot(isoDate);
      if (count >= _barbers.length) {
        _showMsg('Citas ya no disponibles: barberos saturados en este horario');
        setState(() => _isLoading = false);
        return;
      }

      // SELECCIÓN ALEATORIA DE BARBERO DISPONIBLE
      // Primero obtenemos los IDs de los barberos ya ocupados en ese slot
      final occupiedBarberIds = await Supabase.instance.client
          .from('appointments')
          .select('barber_id')
          .eq('appointment_date', isoDate)
          .neq('status', 'cancelled');
      
      final List<String> occupiedIds = (occupiedBarberIds as List).map((e) => e['barber_id'].toString()).toList();
      
      final availableBarbers = _barbers.where((b) => !occupiedIds.contains(b['id'].toString())).toList();
      
      if (availableBarbers.isEmpty) {
        _showMsg('Citas ya no disponibles: barberos saturados');
        setState(() => _isLoading = false);
        return;
      }

      final randomBarber = availableBarbers[Random().nextInt(availableBarbers.length)];

      await _supabaseService.createAppointment({
        'barber_id': randomBarber['id'],
        'service_id': widget.selectedService?['id'],
        'appointment_date': isoDate,
        'status': 'confirmed'
      });

      if (mounted) {
        _showMsg('¡Cita agendada con éxito!', isError: false);
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      }
    } catch (e) {
      _showMsg('Error al agendar: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMsg(String m, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(m), backgroundColor: isError ? AppColors.primary : Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text('AGENDAR SESIÓN', style: TextStyle(fontSize: 14, letterSpacing: 2))),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                // RESUMEN DEL SERVICIO
                if (widget.selectedService != null)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.content_cut, color: AppColors.primary),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.selectedService!['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text('\$${widget.selectedService!['price']}', style: const TextStyle(color: Colors.white54)),
                          ],
                        ),
                      ],
                    ),
                  ).animate().fadeIn().slideY(begin: -0.2),

                const SizedBox(height: 40),
                
                // 1. LA FECHA
                const Text('SELECCIONA EL DÍA', style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 2)),
                const SizedBox(height: 16),
                _buildDateSelector(),

                const SizedBox(height: 32),

                // 2. LA HORA
                const Text('HORARIOS DISPONIBLES', style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 2)),
                const SizedBox(height: 16),
                _buildTimeSlots(),

                const SizedBox(height: 48),
                
                const Text(
                  '* El barbero se asignará automáticamente según disponibilidad.',
                  style: TextStyle(color: Colors.white24, fontSize: 11, fontStyle: FontStyle.italic),
                ),

                const SizedBox(height: 24),
                
                SizedBox(
                  width: double.infinity, height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _confirmBooking,
                    child: const Text('CONFIRMAR RESERVA'),
                  ),
                ),
                const SizedBox(height: 50),
              ],
            ),
          ),
    );
  }

  Widget _buildDateSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(DateFormat('EEEE, d MMMM', 'es').format(_selectedDate).toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
          IconButton(
            icon: const Icon(Icons.calendar_month, color: AppColors.primary),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 30)),
              );
              if (picked != null) setState(() => _selectedDate = picked);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSlots() {
    return Wrap(
      spacing: 12, runSpacing: 12,
      children: _timeSlots.map((time) {
        final isSelected = _selectedTime == time;
        return GestureDetector(
          onTap: () => setState(() => _selectedTime = time),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
            ),
            child: Text(time, style: TextStyle(color: isSelected ? Colors.white : Colors.white60, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        );
      }).toList(),
    );
  }
}
