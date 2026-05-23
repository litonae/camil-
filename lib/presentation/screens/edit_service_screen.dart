import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/supabase_service.dart';

class EditServiceScreen extends StatefulWidget {
  final Map<String, dynamic>? service;

  const EditServiceScreen({super.key, this.service});

  @override
  State<EditServiceScreen> createState() => _EditServiceScreenState();
}

class _EditServiceScreenState extends State<EditServiceScreen> {
  final _supabaseService = SupabaseService();
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _durationCtrl;
  late TextEditingController _urlCtrl;
  late TextEditingController _philosophyCtrl;
  late TextEditingController _tipsCtrl;
  
  String _category = 'Cortes Premium';
  File? _imageFile;
  bool _isLoading = false;
  bool _hasInitialImage = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.service?['name']?.toString() ?? '');
    _descCtrl = TextEditingController(text: widget.service?['description']?.toString() ?? '');
    _priceCtrl = TextEditingController(text: widget.service?['price']?.toString() ?? '');
    _durationCtrl = TextEditingController(text: widget.service?['duration_minutes']?.toString() ?? '');
    _urlCtrl = TextEditingController(text: widget.service?['image_url']?.toString() ?? '');
    _philosophyCtrl = TextEditingController(text: widget.service?['philosophy']?.toString() ?? '');
    _tipsCtrl = TextEditingController(text: widget.service?['style_tips']?.toString() ?? '');
    
    _hasInitialImage = _urlCtrl.text.isNotEmpty;
    if (widget.service != null) {
      _category = widget.service!['category']?.toString() ?? 'Cortes Premium';
    }
  }

  Future<void> _pickImage() async {
    if (_urlCtrl.text.isNotEmpty) {
      _showError('Borra la URL para poder subir una foto local');
      return;
    }
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
      });
    }
  }

  void _removeImage() {
    setState(() {
      _imageFile = null;
      _urlCtrl.clear();
      _hasInitialImage = false;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final data = {
        'name': _nameCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'price': double.tryParse(_priceCtrl.text) ?? 0.0,
        'duration_minutes': int.tryParse(_durationCtrl.text) ?? 0,
        'image_url': _urlCtrl.text.trim(),
        'category': _category,
        'philosophy': _philosophyCtrl.text.trim(),
        'style_tips': _tipsCtrl.text.trim(),
      };

      if (widget.service == null) {
        await _supabaseService.createService(
          name: data['name'] as String,
          description: data['description'] as String,
          price: data['price'] as double,
          duration: data['duration_minutes'] as int,
          imageUrl: data['image_url'] as String?,
          category: _category,
          philosophy: data['philosophy'] as String,
          styleTips: data['style_tips'] as String,
          imageFile: _imageFile,
        );
      } else {
        // Enviar solo los campos que cambiaron o el mapa completo
        await _supabaseService.updateService(
          widget.service!['id'].toString(), 
          data, 
          imageFile: _imageFile
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Cambios guardados con éxito!'), backgroundColor: Colors.green)
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error detallado: $e');
      _showError('Error al guardar: Asegúrate de ejecutar el SQL de permisos.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('¿ELIMINAR SERVICIO?', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        content: const Text('Esta acción no se puede deshacer.', style: TextStyle(color: Colors.white70)),
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
        await _supabaseService.deleteService(widget.service!['id'].toString());
        if (mounted) Navigator.pop(context);
      } catch (e) {
        _showError('Error al eliminar: $e');
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.service == null ? 'NUEVO SERVICIO' : 'FICHA TÉCNICA DEL CORTE'),
        actions: [
          if (widget.service != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: _isLoading ? null : _delete,
            ),
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
              const Text('INFORMACIÓN BÁSICA', style: TextStyle(color: AppColors.primary, fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _field(_nameCtrl, 'Nombre del Servicio', Icons.content_cut, validator: (v) => v!.isEmpty ? 'Requerido' : null),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: _field(_priceCtrl, 'Precio (\$)', Icons.attach_money, keyboard: TextInputType.number, validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null)),
                const SizedBox(width: 16),
                Expanded(child: _field(_durationCtrl, 'Minutos', Icons.timer, keyboard: TextInputType.number, validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null)),
              ]),
              const SizedBox(height: 16),
              _buildCategoryDropdown(),
              
              const SizedBox(height: 32),
              const Text('FICHA TÉCNICA AVANZADA', style: TextStyle(color: AppColors.primary, fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _field(_descCtrl, 'Descripción Corta', Icons.short_text, validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null),
              const SizedBox(height: 16),
              _field(_philosophyCtrl, 'Filosofía del Corte (Texto largo)', Icons.auto_awesome, maxLines: 4, validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null),
              const SizedBox(height: 16),
              _field(_tipsCtrl, 'Tips de Estilo y Recomendaciones', Icons.lightbulb_outline, maxLines: 3, validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null),
              const SizedBox(height: 16),
              TextFormField(
                controller: _urlCtrl,
                enabled: _imageFile == null, // SE DESACTIVA SI HAY FOTO LOCAL
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
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('GUARDAR CAMBIOS'),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSelector() {
    final bool hasImage = _imageFile != null || _hasInitialImage;
    
    return GestureDetector(
      onTap: _pickImage,
      child: Stack(
        children: [
          Container(
            height: 180, width: double.infinity,
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.border)),
            child: _imageFile != null 
              ? ClipRRect(borderRadius: BorderRadius.circular(20), child: Image.file(_imageFile!, fit: BoxFit.cover))
              : _urlCtrl.text.isNotEmpty && widget.service != null
                ? ClipRRect(borderRadius: BorderRadius.circular(20), child: Image.network(_urlCtrl.text, fit: BoxFit.cover))
                : const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_a_photo, size: 40, color: Colors.white24), Text('SUBIR FOTO LOCAL', style: TextStyle(color: Colors.white24))]),
          ),
          if (hasImage)
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

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<String>(
      value: _category,
      dropdownColor: AppColors.surface,
      items: ['Cortes Premium', 'Barba y Rostro', 'Servicios Extra']
          .map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(color: Colors.white)))).toList(),
      onChanged: (v) => setState(() => _category = v!),
      decoration: const InputDecoration(labelText: 'Categoría'),
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
