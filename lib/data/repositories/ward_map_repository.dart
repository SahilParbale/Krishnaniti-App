import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ward_map_point_model.dart';

final wardMapRepoProvider = Provider((ref) => WardMapRepository());

class WardMapRepository {
  // Official boundary coordinates matching Nagarsevak-Managment WardMap.tsx
  final List<Map<String, double>> _wardBoundaryCoords = const [
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

  final List<WardMapPointModel> _defaultPoints = [
    // 1. Office Landmark
    const WardMapPointModel(
      id: 'pt-01',
      title: 'Nagarsevak Public Office (प्रभाग १२ जनसंपर्क कार्यालय)',
      category: 'Office',
      address: 'Shop 1-3, Royal Complex, Shivaji Chowk, Prabhag 12',
      latitude: 18.5021,
      longitude: 73.8442,
      description: 'Central administrative ward office. Public grievances, letter inward/outward, and citizen meeting desk.',
      relativeX: 0.50,
      relativeY: 0.46,
      status: 'Open 10 AM - 7 PM',
    ),
    // 2. Electoral Booths
    const WardMapPointModel(
      id: 'pt-02',
      title: 'Booth 14: Municipal Secondary School (म.न.पा. शाळा क्र. १४)',
      category: 'Booth',
      address: 'Main Gaothan Road, Near Maruti Temple',
      latitude: 18.5052,
      longitude: 73.8415,
      description: 'Polling Booth No. 14 (Voters: 1,420). 4 Classrooms, ramp accessible, drinking water & EVM room ready.',
      relativeX: 0.38,
      relativeY: 0.35,
      status: 'Active Booth',
    ),
    const WardMapPointModel(
      id: 'pt-03',
      title: 'Booth 15: Abhinav English Medium School (अभिनव विद्यालय)',
      category: 'Booth',
      address: 'Sector 3, Lane 4, Shivajinagar',
      latitude: 18.5078,
      longitude: 73.8465,
      description: 'Polling Booth No. 15 (Voters: 1,380). Ground floor sports hall, verified electricity & biometric desk.',
      relativeX: 0.62,
      relativeY: 0.28,
      status: 'Active Booth',
    ),
    const WardMapPointModel(
      id: 'pt-04',
      title: 'Booth 16: Ganpati Mandir Community Hall (गणपती मंदिर सभागृह)',
      category: 'Booth',
      address: 'Lane 4, Near Ganpati Temple Chowk',
      latitude: 18.4985,
      longitude: 73.8430,
      description: 'Polling Booth No. 16 (Voters: 1,250). Community hall with queue barricading and police aid post.',
      relativeX: 0.44,
      relativeY: 0.62,
      status: 'Active Booth',
    ),
    const WardMapPointModel(
      id: 'pt-05',
      title: 'Booth 17: Bharat Scouts & Guides Pavilion (स्काऊट मैदान)',
      category: 'Booth',
      address: 'Canal Ring Road, Adjacent to Sambhaji Garden',
      latitude: 18.4960,
      longitude: 73.8510,
      description: 'Polling Booth No. 17 (Voters: 1,510). Covered sports pavilion with generator backup.',
      relativeX: 0.68,
      relativeY: 0.72,
      status: 'Active Booth',
    ),

    // 3. Civil Development Works
    const WardMapPointModel(
      id: 'pt-06',
      title: 'Concrete Road Paving Work (सिमेंट काँक्रीटीकरण रस्ता काम)',
      category: 'CivilWorks',
      address: 'Internal Lane 3 & 4, Shivajinagar',
      latitude: 18.5085,
      longitude: 73.8420,
      description: 'PMC Tender No. 412: 450-meter heavy load CC road pavement with side storm-water gutters. Fund: ₹42 Lakhs.',
      relativeX: 0.42,
      relativeY: 0.24,
      status: 'In Progress (70% Completed)',
    ),
    const WardMapPointModel(
      id: 'pt-07',
      title: 'Storm Water Drainage Overhaul (वादळी पाण्याचा निचरा ड्रेनेज)',
      category: 'CivilWorks',
      address: 'Shivaji Chowk to Vegetable Mandi Junction',
      latitude: 18.5015,
      longitude: 73.8480,
      description: '600mm RCC Hume pipe laying to prevent monsoon water logging. Executed by Ward Junior Engineer.',
      relativeX: 0.60,
      relativeY: 0.48,
      status: 'In Progress',
    ),
    const WardMapPointModel(
      id: 'pt-08',
      title: 'LED High-Mast & Streetlight Modernization (स्ट्रीटलाईट प्रकल्प)',
      category: 'CivilWorks',
      address: 'Gaothan Main Approach Road',
      latitude: 18.5035,
      longitude: 73.8385,
      description: 'Installation of 24 octagonal poles with 120W energy-efficient LED fixtures. Fund: ₹18.5 Lakhs.',
      relativeX: 0.28,
      relativeY: 0.42,
      status: 'Completed',
    ),
    const WardMapPointModel(
      id: 'pt-09',
      title: 'Public Open Gymnasium & Nana-Nani Park (नाना-नानी पार्क)',
      category: 'CivilWorks',
      address: 'Sambhaji Garden Corner, Sector 4',
      latitude: 18.4970,
      longitude: 73.8450,
      description: 'Senior citizen reflexology track, 8 outdoor gym instruments, and solar lighting installation.',
      relativeX: 0.48,
      relativeY: 0.68,
      status: 'Completed',
    ),

    // 4. Civic Amenities
    const WardMapPointModel(
      id: 'pt-10',
      title: 'Prabhag 12 Municipal Ward Office (प्रभाग १२ मनपा कार्यालय)',
      category: 'Amenity',
      address: 'Sector 2, Administrative Zone Road',
      latitude: 18.5060,
      longitude: 73.8450,
      description: 'Municipal Ward Officer, Property Tax collection desk, Birth/Death certificate counter & Building permission.',
      relativeX: 0.55,
      relativeY: 0.34,
      status: 'Municipal Office',
    ),
    const WardMapPointModel(
      id: 'pt-11',
      title: 'Sambhaji Municipal Park & Jogging Track (संभाजी पार्क)',
      category: 'Amenity',
      address: 'Canal Road, Prabhag 12',
      latitude: 18.4950,
      longitude: 73.8435,
      description: '5.2 acre municipal botanical garden with 1.2km synthetic jogging track, children play area, and yoga gazebo.',
      relativeX: 0.45,
      relativeY: 0.78,
      status: 'Public Park',
    ),
    const WardMapPointModel(
      id: 'pt-12',
      title: 'PMC Urban Primary Health Clinic (शहरी प्राथमिक आरोग्य केंद्र)',
      category: 'Amenity',
      address: 'Behind Ganpati Temple, Lane 4',
      latitude: 18.4995,
      longitude: 73.8410,
      description: 'Free OPD, Ayushman Bharat registration desk, generic medicines dispensary, and child vaccination center.',
      relativeX: 0.36,
      relativeY: 0.56,
      status: 'Health Center',
    ),
    const WardMapPointModel(
      id: 'pt-13',
      title: 'MSEDCL 33kV Electric Substation (महावितरण उपकेंद्र)',
      category: 'Amenity',
      address: 'Industrial Road, Near West Boundary',
      latitude: 18.5040,
      longitude: 73.8360,
      description: 'Power distribution hub for Prabhag 12. 24x7 fuse-off breakdown repair team station.',
      relativeX: 0.20,
      relativeY: 0.40,
      status: 'Essential Service',
    ),

    // 5. Problem / Pain Points
    const WardMapPointModel(
      id: 'pt-14',
      title: 'Chronic Garbage Dumping Spot (कचरा डंपिंग समस्या)',
      category: 'ProblemSpot',
      address: 'Canal Ring Road, Behind Water Tank 2',
      latitude: 18.4930,
      longitude: 73.8540,
      description: 'Persistent open waste dumping spot by night vegetable vendors. Requires daily municipal compactor pickup.',
      relativeX: 0.74,
      relativeY: 0.82,
      status: 'Flagged Issue',
    ),
    const WardMapPointModel(
      id: 'pt-15',
      title: 'Low Water Pressure Pipeline Junction (कमी पाण्याचा दाब केंद्र)',
      category: 'ProblemSpot',
      address: 'Sector 3 Booster Pump Crossroad',
      latitude: 18.5100,
      longitude: 73.8440,
      description: 'Sluice valve line choked. 28 residential societies reporting zero morning pressure.',
      relativeX: 0.52,
      relativeY: 0.20,
      status: 'Flagged Issue',
    ),
    const WardMapPointModel(
      id: 'pt-16',
      title: 'Dangerous Choked Silt Chamber (धोकादायक उघडे चेंबर)',
      category: 'ProblemSpot',
      address: 'Opposite Old Vegetable Mandi Gate',
      latitude: 18.5005,
      longitude: 73.8470,
      description: 'Cement cover cracked during drainage desilting. Traffic hazard during evening rush.',
      relativeX: 0.58,
      relativeY: 0.52,
      status: 'Flagged Issue',
    ),
  ];

  late List<WardMapPointModel> _points;

  WardMapRepository() {
    _points = List.from(_defaultPoints);
  }

  List<Map<String, double>> getWardBoundaryCoordinates() => _wardBoundaryCoords;

  Future<List<WardMapPointModel>> getWardPoints() async {
    return List.from(_points);
  }

  Future<WardMapPointModel> addWardPoint(WardMapPointModel point) async {
    _points.insert(0, point);
    return point;
  }
}

