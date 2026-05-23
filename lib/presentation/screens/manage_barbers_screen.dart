import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/supabase_service.dart';
import 'edit_barber_screen.dart';

class ManageBarbersScreen extends StatefulWidget {
  const ManageBarbersScreen({super.key});

  @override
  State<ManageBarbersScreen> createState() => _ManageBarbersScreenState();
}

class _ManageBarbersScreenState extends State<ManageBarbersScreen> {
  final _supabaseService = SupabaseService();
  List<Map<String, dynamic>> _barbers = [];
  bool _isLoading = true;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('GESTIÓN DE BARBEROS', style: TextStyle(fontSize: 14, letterSpacing: 2)),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1, color: AppColors.primary),
            onPressed: () => Navigator.pushNamed(context, '/add-barber').then((_) => _fetchBarbers()),
          )
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
        : _barbers.isEmpty 
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: _barbers.length,
              itemBuilder: (context, index) {
                final item = _barbers[index];
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
                      MaterialPageRoute(builder: (context) => EditBarberScreen(barber: item))
                    ).then((_) => _fetchBarbers()),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CachedNetworkImage(
                            imageUrl: item['image_url'] ?? '',
                            width: 60, height: 60, fit: BoxFit.cover,
                            memCacheWidth: 150,
                            memCacheHeight: 150,
                            errorWidget: (context, url, error) => const Icon(Icons.person, color: Colors.white10),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item['full_name'] ?? 'Sin nombre', style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text(item['specialty'] ?? 'Sin especialidad', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                              Row(
                                children: [
                                  const Icon(Icons.star, color: Colors.amber, size: 10),
                                  Text(" ${item['rating']}", style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                                ],
                              ),
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
          const Icon(Icons.people_outline, size: 60, color: Colors.white10),
          const SizedBox(height: 16),
          const Text('No hay barberos en la base de datos', style: TextStyle(color: Colors.white38)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/add-barber').then((_) => _fetchBarbers()),
            child: const Text('AGREGAR MI PRIMER BARBERO'),
          )
        ],
      ),
    );
  }
}
