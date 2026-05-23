import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/supabase_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _supabaseService = SupabaseService();
  Map<String, dynamic>? _profile;
  List<Map<String, dynamic>> _barbers = [];
  bool _isLoading = true;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final profileData = await _supabaseService.getMyProfile();
      final barbersData = await _supabaseService.getBarbers();
      if (mounted) {
        setState(() {
          _profile = profileData;
          _barbers = barbersData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery, 
      imageQuality: 50,
      maxWidth: 500,
    );
    
    if (pickedFile == null) return;

    setState(() => _isUploading = true);
    try {
      final url = await _supabaseService.uploadAvatar(File(pickedFile.path));
      if (url != null) {
        if (mounted) {
          await _loadData();
          PaintingBinding.instance.imageCache.clear();
          PaintingBinding.instance.imageCache.clearLiveImages();
          _showMsg('¡Foto de perfil actualizada!', isError: false);
        }
      }
    } catch (e) {
      _showMsg('Error de permisos o conexión.');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _showPersonalData() async {
    final nameController = TextEditingController(text: _profile?['full_name']);
    final phoneController = TextEditingController(text: _profile?['phone_number']);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('MIS DATOS PERSONALES', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2)),
            const SizedBox(height: 24),
            _buildEditField(nameController, 'Nombre Completo', Icons.person_outline),
            const SizedBox(height: 16),
            _buildEditField(phoneController, 'Teléfono', Icons.phone_android_outlined, keyboardType: TextInputType.phone),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () async {
                await _supabaseService.updateProfile({
                  'full_name': nameController.text,
                  'phone_number': phoneController.text,
                });
                await _loadData();
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('ACTUALIZAR DATOS'),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildEditField(TextEditingController controller, String label, IconData icon, {TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primary),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
      ),
    );
  }

  void _showPlaceholder(String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        content: const Text('Esta funcionalidad estará disponible en la próxima actualización premium.', style: TextStyle(color: AppColors.textSecondary)),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('ENTENDIDO'))],
      ),
    );
  }

  Future<void> _handleLogout() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  void _showMsg(String m, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(m), backgroundColor: isError ? AppColors.primary : Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.primary)));
    }

    final user = Supabase.instance.client.auth.currentUser;
    final fullName = _profile?['full_name'] ?? user?.userMetadata?['full_name'] ?? 'Cliente CAMIL';
    final avatarUrl = _profile?['avatar_url'] ?? user?.userMetadata?['avatar_url'] ?? 'https://i.pravatar.cc/300?u=\${user?.id}';
    final email = user?.email ?? '';
    final loyaltyPoints = _profile?['loyalty_points'] ?? 0;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 80),
            Center(
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppColors.premiumGradient,
                        ),
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: AppColors.surface,
                          backgroundImage: CachedNetworkImageProvider(avatarUrl),
                          child: _isUploading ? const CircularProgressIndicator(color: Colors.white) : null,
                        ),
                      ),
                      GestureDetector(
                        onTap: _pickAndUploadImage,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                        ),
                      ),
                    ],
                  ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(fullName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _showPersonalData,
                        child: const Icon(Icons.edit, size: 18, color: AppColors.primary),
                      ),
                    ],
                  ),
                  Text(email, style: const TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      '⭐ $loyaltyPoints PUNTOS LOYALTY',
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // SECCIÓN MIS LOOKS IA
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('MIS LOOKS IA™', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                  TextButton(
                    onPressed: () {},
                    child: const Text('Ver todos', style: TextStyle(color: AppColors.primary, fontSize: 13)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 150,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                scrollDirection: Axis.horizontal,
                itemCount: 3,
                itemBuilder: (context, index) {
                  final looks = [
                    'https://images.pexels.com/photos/1813272/pexels-photo-1813272.jpeg?auto=compress&cs=tinysrgb&w=300',
                    'https://images.pexels.com/photos/3993444/pexels-photo-3993444.jpeg?auto=compress&cs=tinysrgb&w=300',
                    'https://images.pexels.com/photos/3319900/pexels-photo-3319900.jpeg?auto=compress&cs=tinysrgb&w=300',
                  ];
                  return Container(
                    width: 110,
                    margin: const EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      image: DecorationImage(
                        image: CachedNetworkImageProvider(looks[index]), 
                        fit: BoxFit.cover
                      ),
                      border: Border.all(color: AppColors.border),
                    ),
                  ).animate().fadeIn(delay: (index * 150).ms).scale();
                },
              ),
            ),

            const SizedBox(height: 40),

            // SECCIÓN EQUIPO ATELIER (Barberos Reales)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('EQUIPO ATELIER', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/booking'),
                    child: const Text('Agendar', style: TextStyle(color: AppColors.primary, fontSize: 13)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 120,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                scrollDirection: Axis.horizontal,
                itemCount: _barbers.length,
                itemBuilder: (context, index) {
                  final barber = _barbers[index];
                  return Container(
                    margin: const EdgeInsets.only(right: 20),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppColors.premiumGradient,
                          ),
                          child: CircleAvatar(
                            radius: 35,
                            backgroundColor: AppColors.surface,
                            backgroundImage: CachedNetworkImageProvider(barber['image_url'] ?? ''),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          barber['full_name']?.split(' ')[0] ?? 'Barbero',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 10),
                            Text(
                              " ${barber['rating']}",
                              style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: (index * 100).ms).slideX(begin: 0.2, end: 0);
                },
              ),
            ),

            const SizedBox(height: 40),

            // Menú de opciones
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _showPersonalData,
                      child: _buildMenuItem(Icons.person_outline, 'Mis datos personales'),
                    ),
                    GestureDetector(
                      onTap: () => _showPlaceholder('NOTIFICACIONES'),
                      child: _buildMenuItem(Icons.notifications_none_outlined, 'Notificaciones'),
                    ),
                    GestureDetector(
                      onTap: () => _showPlaceholder('PRIVACIDAD Y SEGURIDAD'),
                      child: _buildMenuItem(Icons.security_outlined, 'Privacidad y seguridad'),
                    ),
                    GestureDetector(
                      onTap: () => _showPlaceholder('CENTRO DE AYUDA'),
                      child: _buildMenuItem(Icons.help_outline, 'Centro de ayuda'),
                    ),
                    GestureDetector(
                      onTap: _handleLogout,
                      child: _buildMenuItem(Icons.logout, 'Cerrar sesión', isLast: true, color: Colors.redAccent)
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, {bool isLast = false, Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        border: isLast ? null : const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 22, color: color ?? AppColors.textSecondary),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 15,
                color: color ?? AppColors.textPrimary,
                fontWeight: color != null ? FontWeight.bold : FontWeight.normal
              ),
            ),
          ),
          if (color == null) const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.border),
        ],
      ),
    );
  }
}
