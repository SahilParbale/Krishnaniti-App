import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ward_provision_model.dart';

final wardProvisionsRepoProvider = Provider<WardProvisionsRepository>((ref) {
  return WardProvisionsRepository();
});

class WardProvisionsRepository {
  static final List<WardProvisionModel> _provisions = [
    WardProvisionModel(
      id: 'prov-1',
      title: 'Prabhag 12 Arterial Cement Concrete Road & Storm Drainage Overhaul',
      description:
          'Comprehensive CC road resurfacing and underground storm water box drain construction along 1.8 km arterial stretch connecting Shaniwar Wada to Bajirao Road.',
      requestedAmount: 4500000,
      sanctionedAmount: 4500000,
      requestedDate: '2024-04-12',
      sanctionedDate: '2024-05-18',
      status: 'Approved',
      financialYear: '2024-2025',
      category: 'Roads & Civil',
      area: 'Shaniwar Peth',
      letterReference: 'PMC/RDS/2024/1042',
    ),
    WardProvisionModel(
      id: 'prov-2',
      title: 'Replacement of Corroded 250mm Potable Water Supply Mainline',
      description:
          'Procurement and laying of 250mm ductile iron potable water pipeline to resolve chronic low pressure and water contamination across 6 residential societies.',
      requestedAmount: 2800000,
      sanctionedAmount: 2250000,
      requestedDate: '2024-05-20',
      sanctionedDate: '2024-06-30',
      status: 'Partially Approved',
      financialYear: '2024-2025',
      category: 'Water Supply',
      area: 'Ward 12 Central',
      letterReference: 'PMC/WTR/2024/718',
    ),
    WardProvisionModel(
      id: 'prov-3',
      title: 'High-Mast Energy Efficient LED Lighting Towers at 6 Intersections',
      description:
          'Erection of six 16-meter high mast lighting towers with automatic sunset timer switches to enhance nocturnal public transit safety.',
      requestedAmount: 1200000,
      sanctionedAmount: 1200000,
      requestedDate: '2024-06-05',
      sanctionedDate: '2024-07-10',
      status: 'Approved',
      financialYear: '2024-2025',
      category: 'Street Lighting',
      area: 'Bazaar Ward',
      letterReference: 'PMC/ELEC/2024/319',
    ),
    WardProvisionModel(
      id: 'prov-4',
      title: 'Establishment of Municipal Dialysis & Preventive Healthcare Sub-Centre',
      description:
          'Civil modification and equipment acquisition for an 8-station affordable hemodialysis unit and basic pathology testing lab at PMC dispensary.',
      requestedAmount: 3500000,
      sanctionedAmount: null,
      requestedDate: '2024-08-15',
      sanctionedDate: null,
      status: 'Pending',
      financialYear: '2024-2025',
      category: 'Health & Medical',
      area: 'Ward 12 North',
      letterReference: 'PMC/HLT/2024/552',
    ),
    WardProvisionModel(
      id: 'prov-5',
      title: 'Renovation & Modernization of Sambhaji Park Jogging Track & Open Gym',
      description:
          'Laying of non-slip synthetic jogging pathway, solar illumination studs, and senior-friendly hydraulic outdoor fitness equipment.',
      requestedAmount: 1650000,
      sanctionedAmount: 1650000,
      requestedDate: '2024-07-01',
      sanctionedDate: '2024-08-04',
      status: 'Approved',
      financialYear: '2024-2025',
      category: 'Parks & Recreation',
      area: 'Central Ward',
      letterReference: 'PMC/PRK/2024/204',
    ),
    WardProvisionModel(
      id: 'prov-6',
      title: 'Desilting of Underground Hume Pipe Outfalls & Silt Chambers',
      description:
          'Special pre-monsoon mechanized hydraulic vacuum desilting across all primary stormwater hume pipes in Prabhag 12.',
      requestedAmount: 850000,
      sanctionedAmount: 850000,
      requestedDate: '2024-04-02',
      sanctionedDate: '2024-04-25',
      status: 'Approved',
      financialYear: '2024-2025',
      category: 'Drainage & Sanitation',
      area: 'Ward 12',
      letterReference: 'PMC/DRN/2024/110',
    ),
    WardProvisionModel(
      id: 'prov-7',
      title: 'Construction of Elevated Pedestrian Skywalk at Bajirao Junction',
      description:
          'Citizen-demanded foot-over-bridge with escalators connecting Shaniwar Wada precinct to City Post Chowk to mitigate major traffic congestion.',
      requestedAmount: 6000000,
      sanctionedAmount: null,
      requestedDate: '2024-09-10',
      sanctionedDate: null,
      status: 'Pending',
      financialYear: '2024-2025',
      category: 'Roads & Civil',
      area: 'Shaniwar Peth',
      letterReference: 'PMC/TP/2024/889',
    ),
    WardProvisionModel(
      id: 'prov-8',
      title: 'Installation of Smart Digital Traffic Signals with Solar Back-Up',
      description:
          'AI-adaptive traffic controller signals installed across 4 main chowks in Prabhag 12 with 4-hour battery inverter backup.',
      requestedAmount: 2400000,
      sanctionedAmount: 2400000,
      requestedDate: '2023-05-10',
      sanctionedDate: '2023-06-15',
      status: 'Approved',
      financialYear: '2023-2024',
      category: 'Street Lighting',
      area: 'Ward 12 Central',
      letterReference: 'PMC/TRF/2023/402',
    ),
    WardProvisionModel(
      id: 'prov-9',
      title: 'Underground Electrical Cable Ducting & Shifting of Roadside Transformers',
      description:
          'Converting hazardous overhead power lines to underground trench ducts and shifting two road-blocking transformers.',
      requestedAmount: 3800000,
      sanctionedAmount: 3000000,
      requestedDate: '2023-08-14',
      sanctionedDate: '2023-09-28',
      status: 'Partially Approved',
      financialYear: '2023-2024',
      category: 'Roads & Civil',
      area: 'Shaniwar Peth',
      letterReference: 'PMC/MSE/2023/194',
    ),
    WardProvisionModel(
      id: 'prov-10',
      title: 'Community Waste Segregation & Bio-Composting Facility',
      description:
          'Establishment of mechanical organic shredders and composting bins processing 3 tons of municipal wet waste per day.',
      requestedAmount: 1400000,
      sanctionedAmount: 1400000,
      requestedDate: '2023-07-20',
      sanctionedDate: '2023-08-22',
      status: 'Approved',
      financialYear: '2023-2024',
      category: 'Drainage & Sanitation',
      area: 'Bazaar Ward',
      letterReference: 'PMC/SWM/2023/076',
    ),
  ];

  Future<List<WardProvisionModel>> getProvisions({String? year}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (year != null && year.isNotEmpty && year != 'All') {
      return _provisions.where((p) => p.financialYear == year).toList();
    }
    return List.from(_provisions);
  }

  Future<WardProvisionModel?> getProvisionById(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      return _provisions.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<WardProvisionModel> addProvision(WardProvisionModel newProvision) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _provisions.insert(0, newProvision);
    return newProvision;
  }

  Future<WardProvisionModel> updateProvision(WardProvisionModel updated) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final idx = _provisions.indexWhere((p) => p.id == updated.id);
    if (idx != -1) {
      _provisions[idx] = updated;
    }
    return updated;
  }

  Future<bool> deleteProvision(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final countBefore = _provisions.length;
    _provisions.removeWhere((p) => p.id == id);
    return _provisions.length < countBefore;
  }
}

