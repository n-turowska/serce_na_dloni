import '../models/pressure_entry.dart';
import 'api_client.dart';

class PressureApiService {
  final ApiClient _apiClient;

  PressureApiService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();



}