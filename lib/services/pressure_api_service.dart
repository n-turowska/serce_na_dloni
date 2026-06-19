import '../models/pressure_entry.dart';
import 'api_client.dart';

class PressureApiService {
  final ApiClient _apiClient;

  PressureApiService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  Future<List<PressureEntry>> getPressures() async {
    final data = await _apiClient.get('/pressures'); 
    final entries = data['entries'] as List; 
    return entries
       .map((e) => PressureEntry.fromJson(e as Map<String, dynamic>))
       .toList();
  }



}