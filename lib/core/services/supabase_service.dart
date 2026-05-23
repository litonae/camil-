import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  // --- AUTENTICACIÓN ---
  Future<AuthResponse> signIn(String email, String password) async {
    return await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signInWithGoogle() async {
    await _client.auth.signInWithOAuth(OAuthProvider.google, redirectTo: 'io.supabase.barbercamil://');
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // --- PERFIL ---
  Future<Map<String, dynamic>?> getMyProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    try {
      return await _client.from('profiles').select().eq('id', user.id).single();
    } catch (e) { return null; }
  }

  Future<void> updateProfile(Map<String, dynamic> updates) async {
    final user = _client.auth.currentUser;
    if (user == null) return;
    await _client.from('profiles').update(updates).eq('id', user.id);
  }

  Future<void> addVisitToUser(String userId) async {
    await _client.rpc('increment_user_visits', params: {'user_uuid': userId});
  }

  Stream<Map<String, dynamic>> getProfileStream() {
    final user = _client.auth.currentUser;
    return _client
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', user?.id ?? '')
        .map((event) => event.first);
  }

  Future<String?> uploadAvatar(File imageFile) async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    final fileName = '${user.id}_avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await _client.storage.from('avatars').upload(fileName, imageFile, fileOptions: const FileOptions(upsert: true));
    final url = _client.storage.from('avatars').getPublicUrl(fileName);
    await updateProfile({'avatar_url': url});
    return url;
  }

  // --- GESTIÓN DE SERVICIOS ---
  Future<void> createService({
    required String name, required String description, required double price,
    required int duration, required String? imageUrl, required String category,
    required String philosophy, required String styleTips, File? imageFile,
  }) async {
    String? finalUrl = imageUrl;
    if (imageFile != null) {
      final fileName = 'service_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await _client.storage.from('services').upload(fileName, imageFile);
      finalUrl = _client.storage.from('services').getPublicUrl(fileName);
    }
    await _client.from('services').insert({
      'name': name, 'description': description, 'price': price,
      'duration_minutes': duration, 'image_url': finalUrl, 'category': category,
      'philosophy': philosophy, 'style_tips': styleTips,
    });
  }

  Future<void> updateService(String id, Map<String, dynamic> updates, {File? imageFile}) async {
    String? finalUrl = updates['image_url'];
    if (imageFile != null) {
      final fileName = 'service_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await _client.storage.from('services').upload(fileName, imageFile);
      finalUrl = _client.storage.from('services').getPublicUrl(fileName);
    }
    await _client.from('services').update({...updates, 'image_url': finalUrl}).eq('id', id);
  }

  Future<void> deleteService(String id) async {
    await _client.from('services').delete().eq('id', id);
  }

  Future<List<Map<String, dynamic>>> getServices() async {
    return await _client.from('services').select().order('name');
  }

  // --- BARBEROS ---
  Future<List<Map<String, dynamic>>> getBarbers() async {
    return await _client.from('barbers').select().order('full_name');
  }

  // --- GESTIÓN DE PRODUCTOS (BOUTIQUE) ---
  Future<List<Map<String, dynamic>>> getProducts() async {
    return await _client.from('products').select().order('name');
  }

  Future<void> createProduct({
    required String name,
    required String description,
    required double price,
    required String category,
    required String? imageUrl,
    required String benefits,
    required String aiTip,
    required int stock,
    File? imageFile,
  }) async {
    String? finalUrl = imageUrl;
    if (imageFile != null) {
      final fileName = 'product_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await _client.storage.from('products').upload(fileName, imageFile);
      finalUrl = _client.storage.from('products').getPublicUrl(fileName);
    }
    await _client.from('products').insert({
      'name': name,
      'description': description,
      'price': price,
      'category': category,
      'image_url': finalUrl,
      'benefits': benefits,
      'ai_tip': aiTip,
      'stock': stock,
    });
  }

  Future<void> updateProduct(String id, Map<String, dynamic> updates, {File? imageFile}) async {
    String? finalUrl = updates['image_url'];
    if (imageFile != null) {
      final fileName = 'product_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await _client.storage.from('products').upload(fileName, imageFile);
      finalUrl = _client.storage.from('products').getPublicUrl(fileName);
    }
    await _client.from('products').update({...updates, 'image_url': finalUrl}).eq('id', id);
  }

  Future<void> deleteProduct(String id) async {
    await _client.from('products').delete().eq('id', id);
  }

  // --- PEDIDOS (ORDERS) ---
  Future<String> createOrder(List<Map<String, dynamic>> items, double total) async {
    final user = _client.auth.currentUser;
    final res = await _client.from('orders').insert({
      'user_id': user?.id,
      'items': items,
      'total_amount': total,
      'status': 'pending'
    }).select().single();
    return res['id'];
  }

  Future<void> createBarber({required String fullName, required String specialty, required double rating, required String? imageUrl, File? imageFile}) async {
    String? finalUrl = imageUrl;
    if (imageFile != null) {
      final fileName = 'barber_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await _client.storage.from('barbers').upload(fileName, imageFile);
      finalUrl = _client.storage.from('barbers').getPublicUrl(fileName);
    }
    await _client.from('barbers').insert({'full_name': fullName, 'specialty': specialty, 'rating': rating, 'image_url': finalUrl});
  }

  Future<void> updateBarber(String id, Map<String, dynamic> updates, {File? imageFile}) async {
    String? finalUrl = updates['image_url'];
    if (imageFile != null) {
      final fileName = 'barber_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await _client.storage.from('barbers').upload(fileName, imageFile);
      finalUrl = _client.storage.from('barbers').getPublicUrl(fileName);
    }
    await _client.from('barbers').update({...updates, 'image_url': finalUrl}).eq('id', id);
  }

  Future<void> deleteBarber(String id) async {
    await _client.from('barbers').delete().eq('id', id);
  }

  // --- CITAS Y VENTAS (LA SOLUCIÓN) ---
  
  Future<double> getMonthlySales() async {
    try {
      final now = DateTime.now();
      // Traemos TODAS las completadas y filtramos en Dart para 100% precisión
      final response = await _client.from('appointments').select('service_id, appointment_date').eq('status', 'completed');
      final services = await getServices();
      
      double total = 0;
      for (var app in (response as List)) {
        final date = DateTime.parse(app['appointment_date']);
        if (date.month == now.month && date.year == now.year) {
          final s = services.firstWhere((s) => s['id'].toString() == app['service_id'].toString(), orElse: () => {});
          if (s.isNotEmpty) total += (s['price'] as num).toDouble();
        }
      }
      return total;
    } catch (e) { return 0; }
  }

  Future<int> getTodayAppointmentsCount() async {
    try {
      final now = DateTime.now();
      final response = await _client.from('appointments').select('appointment_date').neq('status', 'cancelled');
      
      int count = 0;
      for (var app in (response as List)) {
        final date = DateTime.parse(app['appointment_date']);
        if (date.day == now.day && date.month == now.month && date.year == now.year) count++;
      }
      return count;
    } catch (e) { return 0; }
  }

  Future<void> createAppointment(Map<String, dynamic> data) async {
    final user = _client.auth.currentUser;
    if (user == null) return;
    await _client.from('appointments').insert({...data, 'user_id': user.id});
  }

  Future<List<Map<String, dynamic>>> getAllAppointments() async {
    return await _client.from('appointments').select('*, profiles(full_name, email), barbers(full_name), services(name)').order('appointment_date');
  }

  Future<List<Map<String, dynamic>>> getMyAppointments() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];
    return await _client.from('appointments').select('*, barbers(full_name), services(name)').eq('user_id', user.id).order('appointment_date', ascending: false);
  }

  Future<void> updateAppointmentStatus(String id, String status) async {
    await _client.from('appointments').update({'status': status}).eq('id', id);
  }

  Future<void> deleteAppointment(String id) async {
    await _client.from('appointments').delete().eq('id', id);
  }

  Stream<List<Map<String, dynamic>>> getAppointmentsStream() {
    return _client.from('appointments').stream(primaryKey: ['id']).order('appointment_date');
  }

  Future<bool> checkIfUserHasAppointment(String isoDate) async {
    final user = _client.auth.currentUser;
    if (user == null) return false;
    final res = await _client.from('appointments').select('id').eq('user_id', user.id).eq('appointment_date', isoDate).neq('status', 'cancelled');
    return (res as List).isNotEmpty;
  }

  Future<int> getAppointmentCountForSlot(String isoDate) async {
    final res = await _client.from('appointments').select('id').eq('appointment_date', isoDate).neq('status', 'cancelled');
    return (res as List).length;
  }
}
