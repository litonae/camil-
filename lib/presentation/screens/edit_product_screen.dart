import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/supabase_service.dart';

class EditProductScreen extends StatefulWidget {
  final Map<String, dynamic>? product;

  const EditProductScreen({super.key, this.product});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _supabaseService = SupabaseService();
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _categoryCtrl;
  late TextEditingController _benefitsCtrl;
  late TextEditingController _aiTipCtrl;
  late TextEditingController _stockCtrl;
  late TextEditingController _urlCtrl;
  
  File? _imageFile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.product?['name']?.toString() ?? '');
    _descCtrl = TextEditingController(text: widget.product?['description']?.toString() ?? '');
    _priceCtrl = TextEditingController(text: widget.product?['price']?.toString() ?? '');
    _categoryCtrl = TextEditingController(text: widget.product?['category']?.toString() ?? 'CERAS');
    _benefitsCtrl = TextEditingController(text: widget.product?['benefits']?.toString() ?? '');
    _aiTipCtrl = TextEditingController(text: widget.product?['ai_tip']?.toString() ?? '');
    _stockCtrl = TextEditingController(text: widget.product?['stock']?.toString() ?? '10');
    _urlCtrl = TextEditingController(text: widget.product?['image_url']?.toString() ?? '');
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
        'name': _nameCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'price': double.tryParse(_priceCtrl.text) ?? 0.0,
        'category': _categoryCtrl.text.trim().toUpperCase(),
        'benefits': _benefitsCtrl.text.trim(),
        'ai_tip': _aiTipCtrl.text.trim(),
        'stock': int.tryParse(_stockCtrl.text) ?? 10,
        'image_url': _urlCtrl.text.trim(),
      };

      if (widget.product == null) {
        await _supabaseService.createProduct(
          name: data['name'] as String,
          description: data['description'] as String,
          price: data['price'] as double,
          category: data['category'] as String,
          imageUrl: data['image_url'] as String?,
          benefits: data['benefits'] as String,
          aiTip: data['ai_tip'] as String,
          stock: data['stock'] as int,
          imageFile: _imageFile,
        );
      } else {
        await _supabaseService.updateProduct(widget.product!['id'].toString(), data, imageFile: _imageFile);
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
        title: const Text('¿ELIMINAR PRODUCTO?'),
        content: const Text('Esta acción eliminará el producto de la boutique.'),
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
        await _supabaseService.deleteProduct(widget.product!['id'].toString());
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
        title: Text(widget.product == null ? 'NUEVO PRODUCTO' : 'EDITAR PRODUCTO'),
        actions: [
          if (widget.product != null)
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
              _field(_nameCtrl, 'Nombre del Producto', Icons.shopping_bag),
              const SizedBox(height: 16),
              _field(_descCtrl, 'Descripción Breve', Icons.description, maxLines: 2),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _field(_priceCtrl, 'Precio', Icons.attach_money, keyboard: TextInputType.number)),
                  const SizedBox(width: 16),
                  Expanded(child: _field(_stockCtrl, 'Stock', Icons.inventory, keyboard: TextInputType.number)),
                ],
              ),
              const SizedBox(height: 16),
              _field(_categoryCtrl, 'Categoría (CERAS, ACEITES, SHAMPOOS, PREMIUM)', Icons.category),
              const SizedBox(height: 16),
              _field(_benefitsCtrl, 'Beneficios (Detallados)', Icons.list_alt, maxLines: 3),
              const SizedBox(height: 16),
              _field(_aiTipCtrl, 'Recomendación IA (Tip)', Icons.auto_awesome, maxLines: 2),
              const SizedBox(height: 16),
              TextFormField(
                controller: _urlCtrl,
                enabled: _imageFile == null,
                onChanged: (v) => setState(() {}),
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
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('GUARDAR PRODUCTO'),
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
    return GestureDetector(
      onTap: _pickImage,
      child: Stack(
        children: [
          Container(
            height: 200, width: double.infinity,
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

  Widget _field(TextEditingController ctrl, String hint, IconData icon, {int maxLines = 1, TextInputType? keyboard}) {
    return TextFormField(
      controller: ctrl, maxLines: maxLines, keyboardType: keyboard,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(hintText: hint, prefixIcon: Icon(icon, color: AppColors.primary)),
      validator: (v) => v!.isEmpty ? 'Requerido' : null,
    );
  }
}
