import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/supabase_service.dart';

class EditBarberScreen extends StatefulWidget {
  final Map<String, dynamic>? barber;

  const EditBarberScreen({super.key, this.barber});

  @override
  State<EditBarberScreen> createState() => _EditBarberScreenState();
}

class _EditBarberScreenState extends State<EditBarberScreen> {
  final _supabaseService = SupabaseService();
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameCtrl;
  late TextEditingController _specialtyCtrl;
  late TextEditingController _ratingCtrl;
  late TextEditingController _urlCtrl;
  
  File? _imageFile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.barber?['full_name']?.toString() ?? '');
    _specialtyCtrl = TextEditingController(text: widget.barber?['specialty']?.toString() ?? '');
    _ratingCtrl = TextEditingController(text: widget.barber?['rating']?.toString() ?? '5.0');
    _urlCtrl = TextEditingController(text: widget.barber?['image_url']?.toString() ?? '');
  }

  Future<void> _pickImage() async {
    if (_urlCtrl.text.isNotEmpty) {
      _showMsg('Borra la URL para subir una foto local');
      return;
    }
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (picked != null) setState(() => _imageFile = File(picked.path));
  }

  void _removeImage() {
    setState(() {
      _imageFile = null;
      _urlCtrl.clear();
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final data = {
        'full_name': _nameCtrl.text.trim(),
        'specialty': _specialtyCtrl.text.trim(),
        'rating': double.tryParse(_ratingCtrl.text) ?? 5.0,
        'image_url': _urlCtrl.text.trim(),
      };

      if (widget.barber == null) {
        await _supabaseService.createBarber(
          fullName: data['full_name'] as String,
          specialty: data['specialty'] as String,
          rating: data['rating'] as double,
          imageUrl: data['image_url'] as String?,
          imageFile: _imageFile,
        );
      } else {
        await _supabaseService.updateBarber(widget.barber!['id'].toString(), data, imageFile: _imageFile);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showMsg('Error al guardar: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('¿ELIMINAR BARBERO?'),
        content: const Text('Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCELAR')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('ELIMINAR'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        await _supabaseService.deleteBarber(widget.barber!['id'].toString());
        if (mounted) Navigator.pop(context);
      } catch (e) {
        _showMsg('Error al eliminar: $e');
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _showMsg(String m) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), backgroundColor: AppColors.primary));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.barber == null ? 'NUEVO BARBERO' : 'EDITAR BARBERO'),
        actions: [
          if (widget.barber != null)
            IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent), onPressed: _isLoading ? null : _delete),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImageSelector(),
              const SizedBox(height: 32),
              _field(_nameCtrl, 'Nombre Completo', Icons.person, validator: (v) => v!.isEmpty ? 'Requerido' : null),
              const SizedBox(height: 16),
              _field(_specialtyCtrl, 'Especialidad (ej: Maestro en Fades)', Icons.star_outline),
              const SizedBox(height: 16),
              _field(_ratingCtrl, 'Rating (0.0 - 5.0)', Icons.star, keyboard: TextInputType.number),
              const SizedBox(height: 16),
              TextFormField(
                controller: _urlCtrl,
                enabled: _imageFile == null,
                style: TextStyle(color: _imageFile == null ? Colors.white : Colors.white24),
                decoration: InputDecoration(
                  hintText: _imageFile == null ? 'URL de la imagen (Opcional)' : 'Desactivado (Usando foto local)',
                  prefixIcon: Icon(Icons.link, color: _imageFile == null ? AppColors.primary : Colors.white10),
                ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity, height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('GUARDAR BARBERO'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSelector() {
    return GestureDetector(
      onTap: _pickImage,
      child: Stack(
        children: [
          Container(
            height: 180, width: double.infinity,
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.border)),
            child: _imageFile != null 
              ? ClipRRect(borderRadius: BorderRadius.circular(20), child: Image.file(_imageFile!, fit: BoxFit.cover))
              : _urlCtrl.text.isNotEmpty
                ? ClipRRect(borderRadius: BorderRadius.circular(20), child: Image.network(_urlCtrl.text, fit: BoxFit.cover))
                : const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_a_photo, size: 40, color: Colors.white24), Text('SUBIR FOTO LOCAL', style: TextStyle(color: Colors.white24))]),
          ),
          if (_imageFile != null || _urlCtrl.text.isNotEmpty)
            Positioned(
              top: 10, right: 10,
              child: GestureDetector(
                onTap: _removeImage,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                  child: const Icon(Icons.close, color: Colors.white, size: 20),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String hint, IconData icon, {int maxLines = 1, TextInputType? keyboard, String? Function(String?)? validator}) {
    return TextFormField(
      controller: ctrl, maxLines: maxLines, keyboardType: keyboard, validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(hintText: hint, prefixIcon: Icon(icon, color: AppColors.primary)),
    );
  }
}
