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

  Future<PressureEntry> createPressure(
    int systolic,
    int diastolic,
    String? note, {
    DateTime? createdAt,
  }) async {
    final body = {
      'systolic': systolic,
      'diastolic': diastolic,
      'note': note,
      if (createdAt != null) 'created_at': createdAt.toIso8601String(),
    };

    dynamic data;
    try {
      data = await _apiClient.post('/pressures', body);
    } on ApiException catch (e) {
      if (createdAt == null || (e.statusCode != 400 && e.statusCode != 422)) {
        rethrow;
      }

      data = await _apiClient.post('/pressures', {
        'systolic': systolic,
        'diastolic': diastolic,
        'note': note,
      });
    }

    final entry = PressureEntry.fromJson(data as Map<String, dynamic>);
    return createdAt == null ? entry : entry.copyWith(createdAt: createdAt);
  }

  Future<void> deletePressure(String id) async {
    await _apiClient.delete('/pressures/$id');
  }

  Future<PressureEntry> updatePressure(
    String id,
    int systolic,
    int diastolic,
    String? note, {
    DateTime? createdAt,
  }) async {
    final data = await _apiClient.put('/pressures/$id', {
      'systolic': systolic,
      'diastolic': diastolic,
      'note': note,
      if (createdAt != null) 'created_at': createdAt.toIso8601String(),
    });
    return PressureEntry.fromJson(data as Map<String, dynamic>);
  }
}
