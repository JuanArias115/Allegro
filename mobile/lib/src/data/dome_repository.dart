import '../core/api/api_client.dart';
import '../models/dome.dart';

class DomeRepository {
  final ApiClient _api;
  DomeRepository(this._api);

  Future<List<Dome>> getAll({bool onlyActive = false}) async {
    final data = await _api.get<List<dynamic>>(
      '/api/domes',
      query: {'onlyActive': onlyActive},
    );
    return data.map((e) => Dome.fromJson(e as Map<String, dynamic>)).toList();
  }
}
