import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/gb_register_entry_model.dart';

final gbRegisterRepoProvider = Provider<GbRegisterRepository>((ref) {
  return GbRegisterRepository();
});

class GbRegisterRepository {
  static final List<GbRegisterEntryModel> _entries = [
    GbRegisterEntryModel(
      id: 'gb-001',
      meetingType: 'GB',
      meetingDate: '2024-06-15',
      subject: 'Sanctioning of 24x7 Equal Water Distribution Mainline in Shaniwar Peth',
      description:
          'Urgent motion submitted to address acute low water pressure and intermittent water contamination during peak morning supply hours. Demand for immediate allocation of 250mm DI pipeline replacement from PMC water works corpus.',
      department: 'Water Supply Department',
      area: 'Shaniwar Peth',
      status: 'Action Taken',
      beneficiaries: '14,500 Residents',
      response:
          'Superintending Engineer (Water Supply) confirmed administrative approval under PMC Resolution No. 412. Tendering process initiated with completion target set within 90 days.',
      resolutionNo: 'PMC/GB/RES/2024/412',
      tags: ['Water Infrastructure', 'Pipeline', 'Equal Distribution', 'PMC GB'],
      createdAt: '2024-06-15T11:30:00Z',
    ),
    GbRegisterEntryModel(
      id: 'gb-002',
      meetingType: 'Standing Committee',
      meetingDate: '2024-07-02',
      subject: 'Tender Sanction for Arterial CC Road Concreting and Box Storm Drain Network',
      description:
          'Proposal placed before Standing Committee for commercial sanction of Rs 4.50 Cr for complete cement concrete resurfacing and underground precast RCC storm water drainage along Bajirao Road transit corridor.',
      department: 'Roads & Civil Infrastructure',
      area: 'Bajirao Road Corridor',
      status: 'Action Taken',
      beneficiaries: '35,000 Commuters & Shopkeepers',
      response:
          'Standing Committee sanctioned work order PMC/STC/2024/889. Contractor mobilized on site with strict monsoon drain clearance directives.',
      resolutionNo: 'PMC/STC/2024/889',
      tags: ['Roads', 'Civil Works', 'Storm Drain', 'Standing Committee'],
      createdAt: '2024-07-02T15:00:00Z',
    ),
    GbRegisterEntryModel(
      id: 'gb-003',
      meetingType: 'Ward Committee',
      meetingDate: '2024-07-18',
      subject: 'Modernization of Ward 12 Municipal Maternity Home & 8-Station Dialysis Wing',
      description:
          'Discussion on upgrading primary health center infrastructure, procurement of digital ultrasound sonography, emergency neonatal incubators, and operationalizing an 8-station affordable hemodialysis unit.',
      department: 'Health & Medical Services',
      area: 'Ward 12 Central',
      status: 'In Discussion',
      beneficiaries: '22,000 Citizens',
      response:
          'Chief Medical Officer submitted technical feasibility report. Joint inspection scheduled with Prabhag Assistant Municipal Commissioner next Tuesday.',
      resolutionNo: 'PMC/WC/2024/204',
      tags: ['Healthcare', 'Dialysis Center', 'Maternity Hospital', 'Prabhag Samiti'],
      createdAt: '2024-07-18T10:45:00Z',
    ),
    GbRegisterEntryModel(
      id: 'gb-004',
      meetingType: 'GB',
      meetingDate: '2024-08-10',
      subject: 'Strict Enforcement of Heritage By-Laws and Shaniwar Wada Tourism Corridor Upgrades',
      description:
          'Starred question regarding unchecked illegal encroachments, inadequate public toilet amenities, and pedestrian bottlenecking around historic heritage zone. Demanded smart pedestrian pathway and heritage illumination.',
      department: 'Town Planning & Heritage Cell',
      area: 'Heritage Precinct (Shaniwar Wada)',
      status: 'In Discussion',
      beneficiaries: '50,000 Visitors & Locals',
      response:
          'Municipal Commissioner directed Encroachment Department and Heritage Cell to prepare a unified conservation and pedestrianization master plan.',
      resolutionNo: 'PMC/GB/Q/2024/115',
      tags: ['Heritage', 'Encroachment', 'Tourism', 'PMC GB'],
      createdAt: '2024-08-10T12:15:00Z',
    ),
    GbRegisterEntryModel(
      id: 'gb-005',
      meetingType: 'Special GB',
      meetingDate: '2024-08-28',
      subject: 'Emergency Flood Relief and Pre-Monsoon Nallah Desilting Audit in Low-Lying Peths',
      description:
          'Special adjournment motion moved in General Body over localized water-logging and silt deposition during heavy downpours. Motion sought punitive action against erring desilting contractors and deployment of 4 dewatering pump sets.',
      department: 'Drainage & Disaster Management',
      area: 'Kasba & Shaniwar Lowland',
      status: 'Action Taken',
      beneficiaries: '18,000 Residents',
      response:
          '2 additional high-power 25 HP diesel dewatering pumps positioned at flood points. Contractor penalized Rs 2,50,000 for negligence.',
      resolutionNo: 'PMC/SGB/2024/052',
      tags: ['Flood Control', 'Disaster Relief', 'Drainage', 'Special GB'],
      createdAt: '2024-08-28T16:20:00Z',
    ),
    GbRegisterEntryModel(
      id: 'gb-006',
      meetingType: 'Standing Committee',
      meetingDate: '2024-09-12',
      subject: 'Solar Rooftop & LED High-Mast Lighting Installation at Public Squares',
      description:
          'Proposal to convert 800 conventional sodium street lights to smart photocell-enabled LED luminaires and install rooftop solar grids on all municipal schools in Ward 12 to reduce municipal energy bills.',
      department: 'Electrical & Energy Department',
      area: 'Ward 12 Public Squares',
      status: 'Raised',
      beneficiaries: 'Ward 12 Entire Population',
      response:
          'Awaiting revised revenue model and Energy Efficiency Services Limited (EESL) rate analysis from Chief Electrical Engineer.',
      resolutionNo: null,
      tags: ['Solar Energy', 'Street Lighting', 'Green Ward', 'Standing Committee'],
      createdAt: '2024-09-12T14:10:00Z',
    ),
    GbRegisterEntryModel(
      id: 'gb-007',
      meetingType: 'Ward Committee',
      meetingDate: '2024-09-25',
      subject: 'Scientific Decentralized Waste Segregation and Organic Compost Plant Setup',
      description:
          'Resolution to set up zero-waste citizen collection centers, distributed organic composting pits in public parks, and penalty framework for open garbage dumping on street corners.',
      department: 'Solid Waste Management',
      area: 'Bazaar Ward & Society Pockets',
      status: 'Action Taken',
      beneficiaries: '16,000 Residents',
      response:
          'Ward Sanitation Inspector instructed to deploy 2 dedicated wet-waste pickup e-rickshaws. Wet waste compost pit setup approved at Sambhaji Garden nursery.',
      resolutionNo: 'PMC/WC/2024/298',
      tags: ['Swachh Bharat', 'Solid Waste', 'Compost', 'Ward Committee'],
      createdAt: '2024-09-25T11:00:00Z',
    ),
    GbRegisterEntryModel(
      id: 'gb-008',
      meetingType: 'GB',
      meetingDate: '2024-10-05',
      subject: 'Erection of Multi-Level Automated Car Parking Facility near Vegetable Market',
      description:
          'Calling attention motion to construct a G+4 hydraulic stack car parking structure on municipal amenity plot to decongest dense market access lanes and curb unauthorized roadside parking.',
      department: 'Traffic & Estate Management',
      area: 'Mandai & Market Junction',
      status: 'Rejected',
      beneficiaries: 'Market Traders & Shoppers',
      response:
          'Plot is currently earmarked for underground utility duct reservation under Draft Development Plan 2041. Alternate site identification instructed by Municipal Commissioner.',
      resolutionNo: 'PMC/GB/RES/2024/534',
      tags: ['Parking', 'Traffic', 'Development Plan', 'PMC GB'],
      createdAt: '2024-10-05T13:40:00Z',
    ),
  ];

  Future<List<GbRegisterEntryModel>> getEntries({
    String? meetingType,
    String? status,
    String? query,
    String? area,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
    var results = List<GbRegisterEntryModel>.from(_entries);

    if (meetingType != null && meetingType.isNotEmpty && meetingType != 'All') {
      results = results.where((e) {
        return e.meetingType.toLowerCase() == meetingType.toLowerCase();
      }).toList();
    }

    if (status != null && status.isNotEmpty && status != 'All') {
      results = results.where((e) {
        return e.status.toLowerCase() == status.toLowerCase();
      }).toList();
    }

    if (area != null && area.isNotEmpty && area != 'All') {
      results = results.where((e) => e.area.toLowerCase().contains(area.toLowerCase())).toList();
    }

    if (query != null && query.trim().isNotEmpty) {
      final q = query.toLowerCase().trim();
      results = results.where((e) {
        return e.subject.toLowerCase().contains(q) ||
            e.description.toLowerCase().contains(q) ||
            e.department.toLowerCase().contains(q) ||
            e.area.toLowerCase().contains(q) ||
            (e.resolutionNo?.toLowerCase().contains(q) ?? false) ||
            e.tags.any((tag) => tag.toLowerCase().contains(q));
      }).toList();
    }

    results.sort((a, b) => b.meetingDate.compareTo(a.meetingDate));
    return results;
  }

  Future<GbRegisterEntryModel?> getEntryById(String id) async {
    await Future.delayed(const Duration(milliseconds: 50));
    try {
      return _entries.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<GbRegisterEntryModel> addEntry(GbRegisterEntryModel entry) async {
    await Future.delayed(const Duration(milliseconds: 120));
    _entries.insert(0, entry);
    return entry;
  }

  Future<GbRegisterEntryModel> updateEntry(GbRegisterEntryModel entry) async {
    await Future.delayed(const Duration(milliseconds: 120));
    final index = _entries.indexWhere((e) => e.id == entry.id);
    if (index != -1) {
      _entries[index] = entry;
      return entry;
    }
    throw Exception('GB Register entry not found');
  }

  Future<bool> deleteEntry(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final index = _entries.indexWhere((e) => e.id == id);
    if (index != -1) {
      _entries.removeAt(index);
      return true;
    }
    return false;
  }
}

