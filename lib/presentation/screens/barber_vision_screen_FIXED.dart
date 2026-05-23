import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/ai_service_FIXED.dart';
import '../widgets/custom_button.dart';

class BarberVisionScreen extends StatefulWidget {
  const BarberVisionScreen({super.key});

  @override
  State<BarberVisionScreen> createState() => _BarberVisionScreenState();
}

class _BarberVisionScreenState extends State<BarberVisionScreen> with TickerProviderStateMixin {
  final _aiService = AIService();
  File? _userImage;
  bool _isAnalyzing = false;
  Map<String, dynamic>? _aiResults;

  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _captureSelfie() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera, preferredCameraDevice: CameraDevice.front, imageQuality: 85);
    if (pickedFile != null) {
      setState(() {
        _userImage = File(pickedFile.path);
        _aiResults = null;
      });
      _analyzeFace();
    }
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (pickedFile != null) {
      setState(() {
        _userImage = File(pickedFile.path);
        _aiResults = null;
      });
      _analyzeFace();
    }
  }

  Future<void> _analyzeFace() async {
    if (_userImage == null) return;
    setState(() => _isAnalyzing = true);
    try {
      final results = await _aiService.analyzeFaceAndRecommend(_userImage!);
      if (mounted) setState(() { _aiResults = results; _isAnalyzing = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _isAnalyzing = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SizedBox(
        width: screenWidth,
        height: screenHeight,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(child: _buildBackground()),
            if (_isAnalyzing) _buildAnalyzingOverlay(screenWidth),
            if (_aiResults != null) _buildResultsPanel(screenWidth),
            if (!_isAnalyzing && _aiResults == null) _buildBottomUI(screenWidth),
            _buildCloseButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildBackground() {
    if (_userImage != null) return Image.file(_userImage!, fit: BoxFit.cover);
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.3), radius: 1.2,
          colors: [Color(0xFF1A0000), Color(0xFF0A0A0A), Colors.black],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.face_retouching_natural, size: 80, color: Colors.white10),
            const SizedBox(height: 24),
            Text('BARBERVISION™', style: GoogleFonts.playfairDisplay(fontSize: 28, color: Colors.white, letterSpacing: 4)),
            const Text('ANÁLISIS DE ROSTRO CON IA', style: TextStyle(color: Colors.white38, letterSpacing: 3, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyzingOverlay(double width) {
    return Container(
      width: width,
      color: Colors.black87,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 20),
            const Text('ANALIZANDO PERFIL...', style: TextStyle(color: Colors.white, letterSpacing: 4)),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsPanel(double width) {
    final recs = (_aiResults!['detailed_recommendations'] as List?) ?? [];
    final String faceShape = _aiResults!['face_shape']?.toString() ?? 'Ovalado';

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        width: width,
        padding: const EdgeInsets.all(32),
        decoration: const BoxDecoration(
          color: Color(0xFF111111),
          borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("FORMA: $faceShape".toUpperCase(), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, letterSpacing: 2)),
            const SizedBox(height: 8),
            const Text('RECOMENDACIÓN ATELIER', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: recs.length,
                itemBuilder: (ctx, i) {
                  final item = recs[i];
                  return Container(
                    width: 220,
                    margin: const EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(20)),
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                          child: CachedNetworkImage(
                            imageUrl: item['image_url'] ?? '', 
                            height: 100, 
                            width: double.infinity, 
                            fit: BoxFit.cover,
                            memCacheWidth: 300,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(item['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 32),
            CustomButton(text: 'REINTENTAR', onPressed: () => setState(() => _aiResults = null)),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomUI(double width) {
    return Positioned(
      bottom: 60,
      child: SizedBox(
        width: width,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _btn(Icons.photo_library, _pickFromGallery),
            const SizedBox(width: 30),
            _mainBtn(),
            const SizedBox(width: 30),
            _btn(Icons.auto_awesome, _userImage != null ? _analyzeFace : null),
          ],
        ),
      ),
    );
  }

  Widget _btn(IconData icon, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60, height: 60,
        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white10),
        child: Icon(icon, color: onTap != null ? Colors.white70 : Colors.white10),
      ),
    );
  }

  Widget _mainBtn() {
    return GestureDetector(
      onTap: _captureSelfie,
      child: Container(
        width: 80, height: 80,
        decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.primary),
        child: const Icon(Icons.camera_alt, color: Colors.white, size: 30),
      ),
    );
  }

  Widget _buildCloseButton() {
    return Positioned(top: 50, left: 20, child: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)));
  }
}
