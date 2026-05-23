import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController mapController;

  // Ubicación Real: Av Torre Universidad 19, Cuautitlán Izcalli
  final LatLng _barberLocation = const LatLng(19.6425, -99.2315);

  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _markers.add(
      Marker(
        markerId: const MarkerId('camil_atelier'),
        position: _barberLocation,
        infoWindow: const InfoWindow(
          title: 'BARBER CAMIL ATELIER',
          snippet: 'Av Torre Universidad 19',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    );
  }

  // Estilo de Mapa Oscuro (Premium)
  final String _darkMapStyle = '''
[
  {
    "elementType": "geometry",
    "stylers": [{"color": "#212121"}]
  },
  {
    "elementType": "labels.icon",
    "stylers": [{"visibility": "on"}]
  },
  {
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#757575"}]
  },
  {
    "elementType": "labels.text.stroke",
    "stylers": [{"color": "#212121"}]
  },
  {
    "featureType": "administrative",
    "elementType": "geometry",
    "stylers": [{"color": "#757575"}]
  },
  {
    "featureType": "poi",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#757575"}]
  },
  {
    "featureType": "road",
    "elementType": "geometry.fill",
    "stylers": [{"color": "#2c2c2c"}]
  },
  {
    "featureType": "road",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#8a8a8a"}]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [{"color": "#000000"}]
  }
]
''';

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    controller.setMapStyle(_darkMapStyle);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _barberLocation,
              zoom: 16.5, // Zoom más cercano para ver la zona
            ),
            markers: _markers,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            compassEnabled: true,
            mapToolbarEnabled: false,
          ),

          // Header de Navegación
          Positioned(
            top: 50,
            left: 20,
            child: CircleAvatar(
              backgroundColor: const Color(0xFF1A1A1A),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ).animate().fadeIn().scale(),
          ),

          // Card de la Ubicación Real
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF151515),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.6), blurRadius: 30, offset: const Offset(0, 10)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('📍 UBICACIÓN PRINCIPAL', style: TextStyle(color: Colors.green, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1)),
                      ),
                      const Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber, size: 14),
                          Text(' 4.9', style: TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('CAMIL ATELIER', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1)),
                  const SizedBox(height: 6),
                  const Text(
                    'Av Torre Universidad 19-Manzana 224, Sta Maria Guadalupe las Torres, Cuautitlán Izcalli.',
                    style: TextStyle(color: Colors.white38, fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pushNamed(context, '/services'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text('RESERVAR CITA AQUÍ', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        height: 54,
                        width: 54,
                        decoration: BoxDecoration(
                          color: const Color(0xFF222222),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.directions, color: AppColors.primary),
                          onPressed: () {
                            // Aquí se podría abrir Google Maps externo
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.3, end: 0),
          ),
        ],
      ),
    );
  }
}
