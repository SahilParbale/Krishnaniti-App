import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/improvement_model.dart';

final improvementsRepoProvider = Provider<ImprovementsRepository>((ref) {
  return ImprovementsRepository();
});

class ImprovementsRepository {
  static final List<ImprovementModel> _improvements = [
    ImprovementModel(
      id: 'imp-1',
      title: 'Pedestrian Skywalk with Escalators at Bajirao Road Junction',
      description:
          'Citizen proposal to construct an elevated glass-enclosed pedestrian foot-over-bridge connecting Shaniwar Wada precinct to City Post Chowk, equipped with solar-powered escalators and handicap elevators to eliminate severe pedestrian-traffic conflict.',
      votes: 342,
      location: 'Bajirao Road & Shivaji Road Crossing',
      area: 'Prabhag 12 Central',
      status: 'Planned',
      completionDate: '2026-12-15',
      peopleBenefited: 28000,
      estimatedBudget: 4500000,
      createdAt: '2025-10-14',
      proposedBy: 'Prabhag Citizens Forum',
    ),
    ImprovementModel(
      id: 'imp-2',
      title: 'Underground Electrical Ducting & Overhead Transformer Relocation',
      description:
          'Ducting and shifting of exposed high-voltage MSEDCL overhead cables underground along residential lanes, eliminating hazardous open transformers from narrow footpaths.',
      votes: 289,
      location: 'Tilak Road & Lane 3 Junction',
      area: 'Shaniwar Peth',
      status: 'In Progress',
      completionDate: '2026-08-30',
      peopleBenefited: 14000,
      estimatedBudget: 2800000,
      createdAt: '2025-11-02',
      proposedBy: 'Shaniwar Peth Vyapari Mandal',
    ),
    ImprovementModel(
      id: 'imp-3',
      title: 'Senior Citizen Green Walking Track & Open Reflexology Garden',
      description:
          'Creation of an acupressure pebble walkway, aromatic herbal garden, and specialized low-impact ergonomic exercise pavilions inside Sambhaji Park for morning walkers.',
      votes: 215,
      location: 'Sambhaji Park North Quad',
      area: 'Central Ward',
      status: 'Complete',
      completionDate: '2026-01-20',
      peopleBenefited: 4500,
      estimatedBudget: 850000,
      createdAt: '2025-08-22',
      proposedBy: 'Senior Citizen Association',
    ),
    ImprovementModel(
      id: 'imp-4',
      title: 'Automated Multi-Level Two-Wheeler Smart Parking Tower',
      description:
          'High-density 4-tier rotary automated hydraulic parking facility accommodating 300 scooters and bikes to clear congested roadside parking near the weekly vegetable bazaar.',
      votes: 198,
      location: 'Old Bazaar Market Chowk',
      area: 'Bazaar Ward',
      status: 'Pending',
      completionDate: '2027-03-31',
      peopleBenefited: 12000,
      estimatedBudget: 6200000,
      createdAt: '2026-01-05',
      proposedBy: 'Local Commuters Committee',
    ),
    ImprovementModel(
      id: 'imp-5',
      title: 'AI Smart CCTV Network & Public Emergency Panic Poles',
      description:
          'Installation of 4K night-vision AI security cameras with integrated police helpline SOS buttons across 12 vulnerable intersections, school zones, and transit stops.',
      votes: 184,
      location: 'School Corridors & Main Bus Depots',
      area: 'Ward 12',
      status: 'Planned',
      completionDate: '2026-09-10',
      peopleBenefited: 35000,
      estimatedBudget: 3200000,
      createdAt: '2025-12-18',
      proposedBy: 'Women Safety Ward Initiative',
    ),
    ImprovementModel(
      id: 'imp-6',
      title: 'Decentralized Solar Rooftop Grid on Ward Public Buildings',
      description:
          'Grid-tied 80 kW rooftop solar photovoltaic system across ward office, municipal dispensary, and primary schools, aiming for net-zero carbon energy independence.',
      votes: 156,
      location: 'Ward Office & PMC School No. 8',
      area: 'Ward 12 North',
      status: 'In Progress',
      completionDate: '2026-06-30',
      peopleBenefited: 16000,
      estimatedBudget: 1950000,
      createdAt: '2025-09-11',
      proposedBy: 'Eco-Prabhag Green Council',
    ),
    ImprovementModel(
      id: 'imp-7',
      title: 'Public Digital Study Hub & E-Library for Students',
      description:
          'Air-conditioned 120-seat study hall with high-speed fiber internet, digital tablet access, competitive exam archives, and silent reading zones for college students.',
      votes: 165,
      location: 'Near Tilak Smarak Mandir, 1st Floor',
      area: 'Shaniwar Peth',
      status: 'Complete',
      completionDate: '2025-12-10',
      peopleBenefited: 3200,
      estimatedBudget: 1250000,
      createdAt: '2025-07-15',
      proposedBy: 'Student Youth Wing',
    ),
    ImprovementModel(
      id: 'imp-8',
      title: 'Percolation Pits & Rainwater Recharge Wells in Public Grounds',
      description:
          'Construction of 18 deep rainwater harvesting groundwater recharge pits with sand-gravel filter beds to elevate declining water table levels across Ward 12 open parks.',
      votes: 112,
      location: 'Nana-Nani Park & PMC Ground',
      area: 'Ward 12',
      status: 'Pending',
      completionDate: '2026-05-15',
      peopleBenefited: 9500,
      estimatedBudget: 650000,
      createdAt: '2026-02-01',
      proposedBy: 'Groundwater Conservation Cell',
    ),
  ];

  Future<List<ImprovementModel>> getImprovements() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return List.from(_improvements);
  }

  Future<ImprovementModel?> getImprovementById(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      return _improvements.firstWhere((i) => i.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<ImprovementModel> addImprovement(ImprovementModel improvement) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _improvements.insert(0, improvement);
    return improvement;
  }

  Future<ImprovementModel> updateImprovement(ImprovementModel updated) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final idx = _improvements.indexWhere((i) => i.id == updated.id);
    if (idx != -1) {
      _improvements[idx] = updated;
    }
    return updated;
  }

  Future<bool> deleteImprovement(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final countBefore = _improvements.length;
    _improvements.removeWhere((i) => i.id == id);
    return _improvements.length < countBefore;
  }

  Future<int> voteImprovement(String id) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final idx = _improvements.indexWhere((i) => i.id == id);
    if (idx != -1) {
      final existing = _improvements[idx];
      final newVotes = existing.votes + 1;
      _improvements[idx] = existing.copyWith(votes: newVotes);
      return newVotes;
    }
    return 0;
  }
}

