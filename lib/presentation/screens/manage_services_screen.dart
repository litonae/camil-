import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/supabase_service.dart';

class ManageServicesScreen extends StatefulWidget {
  const ManageServicesScreen({super.key});

  @override
  State<ManageServicesScreen> createState() => _ManageServicesScreenState();
}

class _ManageServicesScreenState extends State<ManageServicesScreen> {
  final _supabaseService = SupabaseService();
  final _formKey = GlobalKey<FormState>();
  
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _durationController = TextEditingController();
  final _urlController = TextEditingController();
  final _philosophyController = TextEditingController();
  final _tipsController = TextEditingController();
  
  String _category = 'Cortes Premium';
  File? _imageFile;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 60);
    if (picked != null) setState(() => _imageFile = File(picked.path));
  }

  Future<void> _saveService() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await _supabaseService.createService(
        name: _nameController.text,
        description: _descController.text,
        price: double.parse(_priceController.text),
        duration: int.parse(_durationController.text),
        imageUrl: _urlController.text.isNotEmpty ? _urlController.text : null,
        category: _category,
        philosophy: _philosophyController.text,
        styleTips: _tipsController.text, // Corregido
        imageFile: _imageFile,
      );
      if (mounted) {
        _showMsg('¡Servicio creado con éxito!', isError: false);
        Navigator.pop(context);
      }
    } catch (e) {
      _showMsg('Error al guardar: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMsg(String m, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), backgroundColor: isError ? AppColors.primary : Colors.green));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('NUEVO SERVICIO ATELIER', style: TextStyle(fontSize: 14, letterSpacing: 2))),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 180, width: double.infinity,
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.border)),
                  child: _imageFile == null 
                    ? const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_a_photo, size: 40, color: Colors.white24), SizedBox(height: 12), Text('SUBIR FOTO DEL CORTE', style: TextStyle(color: Colors.white24))])
                    : ClipRRect(borderRadius: BorderRadius.circular(24), child: Image.file(_imageFile!, fit: BoxFit.cover)),
                ),
              ),
              const SizedBox(height: 32),
              const Text('INFORMACIÓN BÁSICA', style: TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2)),
              const SizedBox(height: 16),
              _field(_nameController, 'Nombre del servicio', Icons.content_cut, validator: (v) => v!.isEmpty ? 'Requerido' : null),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _field(_priceController, 'Precio (\$)', Icons.attach_money, keyboard: TextInputType.number, validator: (v) => v!.isEmpty ? 'Requerido' : null)),
                  const SizedBox(width: 16),
                  Expanded(child: _field(_durationController, 'Minutos', Icons.timer_outlined, keyboard: TextInputType.number, validator: (v) => v!.isEmpty ? 'Requerido' : null)),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _category,
                dropdownColor: AppColors.surface,
                items: ['Cortes Premium', 'Barba y Rostro', 'Servicios Extra']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(color: Colors.white)))).toList(),
                onChanged: (v) => setState(() => _category = v!),
                decoration: const InputDecoration(labelText: 'Categoría', prefixIcon: Icon(Icons.category, color: AppColors.primary)),
              ),
              const SizedBox(height: 32),
              const Text('FICHA TÉCNICA', style: TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2)),
              const SizedBox(height: 16),
              _field(_descController, 'Descripción corta', Icons.short_text),
              const SizedBox(height: 16),
              _field(_philosophyController, 'Filosofía del corte', Icons.auto_awesome, maxLines: 3),
              const SizedBox(height: 16),
              _field(_tipsController, 'Tips de Estilo', Icons.lightbulb_outline, maxLines: 2),
              const SizedBox(height: 16),
              _field(_urlController, 'URL de imagen (opcional)', Icons.link),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity, height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveService,
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('GUARDAR EN CATÁLOGO'),
                ),
              ),
            ],
          ),
        ),
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
