import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/government_office_model.dart';

final governmentOfficeRepoProvider = Provider<GovernmentOfficeRepository>((ref) {
  return GovernmentOfficeRepository();
});

class GovernmentOfficeRepository {
  static final List<GovernmentOfficeModel> _offices = [
    GovernmentOfficeModel(
      id: 'gov-001',
      name: 'PMC Kasba-Vishrambaug Ward Office No. 12',
      officerName: 'Shri. Ramesh Gaikwad (Asst. Municipal Commissioner)',
      contactNumber: '020-25501140',
      secondaryContact: '+91 98811 02450',
      address: 'Near Shaniwar Wada, Appa Balwant Chowk Road, Pune - 411030',
      area: 'Shaniwar Peth',
      category: 'Municipal PMC',
      timing: '9:45 AM - 5:45 PM (Mon - Sat)',
      email: 'ward12@punecorporation.org',
      latitude: 18.5196,
      longitude: 73.8553,
      isEmergency: false,
      createdAt: '2024-01-15T10:00:00Z',
    ),
    GovernmentOfficeModel(
      id: 'gov-002',
      name: 'Vishrambaug Police Station',
      officerName: 'Sr. PI Sunil Mane (Police Inspector In-Charge)',
      contactNumber: '020-24452580',
      secondaryContact: '112',
      address: 'Bajirao Road, Near Shanipar Chowk, Sadashiv Peth, Pune - 411030',
      area: 'Bajirao Road',
      category: 'Police',
      timing: '24x7 Emergency Help Desk',
      email: 'vishrambaug.pune@mahapolice.gov.in',
      latitude: 18.5142,
      longitude: 73.8529,
      isEmergency: true,
      createdAt: '2024-01-15T10:00:00Z',
    ),
    GovernmentOfficeModel(
      id: 'gov-003',
      name: 'MSEDCL Shaniwar Peth Sub-Division (Electricity)',
      officerName: 'Er. Sachin Kulkarni (Executive Engineer)',
      contactNumber: '020-24471920',
      secondaryContact: '1912',
      address: 'Near Mehunpura, Shaniwar Peth, Pune - 411030',
      area: 'Shaniwar Peth',
      category: 'MSEDCL Electricity',
      timing: '10:00 AM - 5:30 PM (Emergency 24x7: 1912)',
      email: 'ee_shaniwar@mahadiscom.in',
      latitude: 18.5188,
      longitude: 73.8519,
      isEmergency: true,
      createdAt: '2024-01-16T11:00:00Z',
    ),
    GovernmentOfficeModel(
      id: 'gov-004',
      name: 'PMC Water Supply & Distribution Division',
      officerName: 'Er. Sandeep Joshi (Deputy Engineer Water Works)',
      contactNumber: '020-25501300',
      secondaryContact: '+91 96899 31450',
      address: 'PMC Water Works Sub-Station, Kelkar Road, Pune - 411030',
      area: 'Ward 12 Central',
      category: 'Water Supply',
      timing: '6:00 AM - 10:00 PM (Control Room 24x7)',
      email: 'watercontrol@punecorporation.org',
      latitude: 18.5165,
      longitude: 73.8538,
      isEmergency: false,
      createdAt: '2024-01-18T09:30:00Z',
    ),
    GovernmentOfficeModel(
      id: 'gov-005',
      name: 'PMC Central Fire Station & Disaster Management',
      officerName: 'Chief Fire Officer Devendra Potphode',
      contactNumber: '101',
      secondaryContact: '020-26451707',
      address: 'Near Nehru Stadium / Budhwar Peth Station, Pune - 411002',
      area: 'Budhwar Peth / Kasba',
      category: 'Fire & Disaster',
      timing: '24x7 Emergency Service',
      email: 'fire@punecorporation.org',
      latitude: 18.5150,
      longitude: 73.8570,
      isEmergency: true,
      createdAt: '2024-01-18T10:00:00Z',
    ),
    GovernmentOfficeModel(
      id: 'gov-006',
      name: 'PMC Kamla Nehru General Hospital',
      officerName: 'Dr. Rahul Shinde (Medical Superintendent)',
      contactNumber: '020-26058200',
      secondaryContact: '108',
      address: 'Mangalwar Peth, Near Rasta Peth Power House, Pune - 411011',
      area: 'Ward 12 North Vicinity',
      category: 'Health & Hospital',
      timing: '24x7 Emergency & Trauma Care / OPD: 8:00 AM - 2:00 PM',
      email: 'knhospital@punecorporation.org',
      latitude: 18.5225,
      longitude: 73.8640,
      isEmergency: true,
      createdAt: '2024-01-20T14:00:00Z',
    ),
    GovernmentOfficeModel(
      id: 'gov-007',
      name: 'PMC Solid Waste & Health Sanitation Chowki',
      officerName: 'Shri. Dilip Jadhav (Senior Health Inspector)',
      contactNumber: '020-25501148',
      secondaryContact: '+91 98230 44510',
      address: 'Kunte Chowk, Laxmi Road, Pune - 411030',
      area: 'Bazaar Ward',
      category: 'Municipal PMC',
      timing: '6:30 AM - 2:30 PM (Morning Sanitation)',
      email: 'swmward12@punecorporation.org',
      latitude: 18.5160,
      longitude: 73.8540,
      isEmergency: false,
      createdAt: '2024-01-22T08:00:00Z',
    ),
    GovernmentOfficeModel(
      id: 'gov-008',
      name: 'Faraskhana Police Station & Traffic Division',
      officerName: 'Sr. PI Prashant Bhasme (In-Charge Officer)',
      contactNumber: '020-24451666',
      secondaryContact: '112',
      address: 'Budhwar Peth, Near Dagdusheth Temple, Pune - 411002',
      area: 'Kasba Peth',
      category: 'Police',
      timing: '24x7 Emergency Help Desk',
      email: 'faraskhana.pune@mahapolice.gov.in',
      latitude: 18.5170,
      longitude: 73.8562,
      isEmergency: true,
      createdAt: '2024-01-22T12:00:00Z',
    ),
    GovernmentOfficeModel(
      id: 'gov-009',
      name: 'Pune City Tehsil & Civil Supplies Rationing Office',
      officerName: 'Smt. Snehal Patil (Tahsildar Pune City)',
      contactNumber: '020-26122384',
      secondaryContact: '020-26123400',
      address: 'Collector Office Campus, Station Road, Pune - 411001',
      area: 'Revenue Central',
      category: 'Revenue & Post',
      timing: '10:00 AM - 5:30 PM (Mon - Fri)',
      email: 'tehsil_city@maharashtra.gov.in',
      latitude: 18.5250,
      longitude: 73.8700,
      isEmergency: false,
      createdAt: '2024-01-25T15:30:00Z',
    ),
    GovernmentOfficeModel(
      id: 'gov-010',
      name: 'Maharashtra 108 Emergency Medical Response Control',
      officerName: 'Duty Medical Officer (State Emergency Cell)',
      contactNumber: '108',
      secondaryContact: '102',
      address: 'Centralized Ambulance Dispatch Cell, Pune',
      area: 'Ward 12 Entire Area',
      category: 'Fire & Disaster',
      timing: '24x7 Free Emergency Ambulance Toll-Free',
      email: 'control@bvgemri108.org',
      latitude: 18.5204,
      longitude: 73.8567,
      isEmergency: true,
      createdAt: '2024-01-28T16:00:00Z',
    ),
  ];

  Future<List<GovernmentOfficeModel>> getOffices({
    String? category,
    String? area,
    String? query,
    bool? emergencyOnly,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
    var results = List<GovernmentOfficeModel>.from(_offices);

    if (category != null && category.isNotEmpty && category != 'All') {
      results = results.where((o) => o.category.toLowerCase() == category.toLowerCase()).toList();
    }

    if (area != null && area.isNotEmpty && area != 'All') {
      results = results.where((o) => o.area.toLowerCase().contains(area.toLowerCase())).toList();
    }

    if (emergencyOnly == true) {
      results = results.where((o) => o.isEmergency).toList();
    }

    if (query != null && query.trim().isNotEmpty) {
      final q = query.toLowerCase().trim();
      results = results.where((o) {
        return o.name.toLowerCase().contains(q) ||
            o.officerName.toLowerCase().contains(q) ||
            o.contactNumber.toLowerCase().contains(q) ||
            (o.secondaryContact?.toLowerCase().contains(q) ?? false) ||
            o.address.toLowerCase().contains(q) ||
            o.area.toLowerCase().contains(q) ||
            o.category.toLowerCase().contains(q);
      }).toList();
    }

    return results;
  }

  Future<GovernmentOfficeModel?> getOfficeById(String id) async {
    await Future.delayed(const Duration(milliseconds: 50));
    try {
      return _offices.firstWhere((o) => o.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<GovernmentOfficeModel> addOffice(GovernmentOfficeModel office) async {
    await Future.delayed(const Duration(milliseconds: 120));
    _offices.insert(0, office);
    return office;
  }

  Future<GovernmentOfficeModel> updateOffice(GovernmentOfficeModel office) async {
    await Future.delayed(const Duration(milliseconds: 120));
    final index = _offices.indexWhere((o) => o.id == office.id);
    if (index != -1) {
      _offices[index] = office;
      return office;
    }
    throw Exception('Government office not found');
  }

  Future<bool> deleteOffice(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final index = _offices.indexWhere((o) => o.id == id);
    if (index != -1) {
      _offices.removeAt(index);
      return true;
    }
    return false;
  }
}

