import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/supabase_service.dart';
import '../models/ward_map_point_model.dart';

final wardMapRepoProvider = Provider((ref) => WardMapRepository());

class WardMapRepository {
  // Official boundary coordinates matching Nagarsevak-Managment WardMap.tsx
  final List<Map<String, double>> _defaultBoundaryCoords = const [
    {'lat': 18.500915, 'lng': 73.858573},
    {'lat': 18.511455, 'lng': 73.845119},
    {'lat': 18.512137, 'lng': 73.843810},
    {'lat': 18.512819, 'lng': 73.843842},
    {'lat': 18.513653, 'lng': 73.843027},
    {'lat': 18.512025, 'lng': 73.841364},
    {'lat': 18.510143, 'lng': 73.840012},
    {'lat': 18.507599, 'lng': 73.837351},
    {'lat': 18.506094, 'lng': 73.836547},
    {'lat': 18.504568, 'lng': 73.836557},
    {'lat': 18.501851, 'lng': 73.836847},
    {'lat': 18.499287, 'lng': 73.836182},
    {'lat': 18.498158, 'lng': 73.835495},
    {'lat': 18.497527, 'lng': 73.836321},
    {'lat': 18.497527, 'lng': 73.838381},
    {'lat': 18.498585, 'lng': 73.838671},
    {'lat': 18.499145, 'lng': 73.839057},
    {'lat': 18.501027, 'lng': 73.839164},
    {'lat': 18.500935, 'lng': 73.842222},
    {'lat': 18.502695, 'lng': 73.843746},
    {'lat': 18.502848, 'lng': 73.845237},
    {'lat': 18.501118, 'lng': 73.845645},
    {'lat': 18.501037, 'lng': 73.847608},
    {'lat': 18.500518, 'lng': 73.849132},
    {'lat': 18.499491, 'lng': 73.850526},
    {'lat': 18.498392, 'lng': 73.850172},
    {'lat': 18.498117, 'lng': 73.849668},
    {'lat': 18.496326, 'lng': 73.849292},
    {'lat': 18.496011, 'lng': 73.849067},
    {'lat': 18.496235, 'lng': 73.848059},
    {'lat': 18.495177, 'lng': 73.847361},
    {'lat': 18.492663, 'lng': 73.848005},
    {'lat': 18.492582, 'lng': 73.849861},
    {'lat': 18.492378, 'lng': 73.857768},
  ];

  final List<WardMapPointModel> _customPoints = [];

  List<Map<String, double>> getWardBoundaryCoordinates() => _defaultBoundaryCoords;

  Future<List<WardMapPointModel>> getWardPoints() async {
    final List<WardMapPointModel> points = [];
    final client = SupabaseService.instance.client;
    final tenantId = SupabaseService.instance.activeTenantId;

    // 1. Fetch live government offices
    try {
      var query = client.from('government_offices').select('*');
      if (tenantId != null && tenantId.isNotEmpty) {
        query = query.eq('tenant_id', tenantId);
      }
      final response = await query.limit(10);
      for (final item in response as List<dynamic>) {
        final map = Map<String, dynamic>.from(item as Map);
        points.add(WardMapPointModel(
          id: 'gov-${map['id']}',
          title: map['name']?.toString() ?? 'Government Office',
          category: 'Facility',
          address: map['address']?.toString() ?? '',
          latitude: 18.5020,
          longitude: 73.8440,
          description: map['officer_name'] != null ? 'Officer: ${map['officer_name']} (${map['contact_number'] ?? ''})' : '',
          relativeX: 0.50,
          relativeY: 0.45,
          status: 'Open',
        ));
      }
    } catch (_) {}

    // 2. Fetch live problem spots from complaints
    try {
      var query = client.from('complaints').select('id, title, area, category, status').eq('status', 'Pending');
      if (tenantId != null && tenantId.isNotEmpty) {
        query = query.eq('tenant_id', tenantId);
      }
      final response = await query.limit(10);
      for (final item in response as List<dynamic>) {
        final map = Map<String, dynamic>.from(item as Map);
        points.add(WardMapPointModel(
          id: 'prob-${map['id']}',
          title: map['title']?.toString() ?? 'Complaint',
          category: 'ProblemSpot',
          address: map['area']?.toString() ?? '',
          latitude: 18.5000,
          longitude: 73.8460,
          description: 'Category: ${map['category'] ?? 'Civic'}',
          relativeX: 0.55,
          relativeY: 0.50,
          status: 'Pending Issue',
        ));
      }
    } catch (_) {}

    points.addAll(_customPoints);
    return points;
  }

  Future<WardMapPointModel> addWardPoint(WardMapPointModel point) async {
    _customPoints.insert(0, point);
    return point;
  }
}
