import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/work_history_model.dart';

final workHistoryRepoProvider = Provider<WorkHistoryRepository>((ref) {
  return WorkHistoryRepository();
});

class WorkHistoryRepository {
  static final List<WorkHistoryModel> _works = [
    WorkHistoryModel(
      id: 'work-1',
      source: 'Manual',
      title: 'Prabhag 12 CC Road Concreting & Storm Water Line',
      description:
          'Comprehensive cement-concrete road construction (1.4 km) from Shaniwar Peth Maruti Mandir to Shivaji High School with integrated storm water underground culverts to prevent seasonal waterlogging.',
      location: 'Main Road, Shaniwar Peth',
      area: 'Shaniwar Peth',
      status: 'Completed',
      date: '2025-11-20',
      amount: 1450000,
      peopleBenefited: 8500,
      feedbackRating: 4.9,
      feedbackCount: 38,
      feedbacks: [
        WorkFeedbackModel(
          id: 'fb-1',
          citizenName: 'Anil Deshmukh',
          rating: 5,
          comment: 'Excellent road quality and drainage. No waterlogging seen during heavy rains this year.',
          createdAt: '2025-11-25 10:30 AM',
        ),
        WorkFeedbackModel(
          id: 'fb-2',
          citizenName: 'Meera Kulkarni',
          rating: 5,
          comment: 'Pedestrian footpath was also nicely leveled. Very helpful for seniors.',
          createdAt: '2025-12-02 04:15 PM',
        ),
      ],
    ),
    WorkHistoryModel(
      id: 'work-2',
      source: 'Manual',
      title: 'Installation of LED High-Mast Lighting at 4 Main Chowks',
      description:
          'Erection of four 16-meter high mast lighting towers with high-efficiency energy-saving LED fixtures at key transit intersections in Prabhag 12 to enhance night safety and commuter visibility.',
      location: 'Ganpati Chowk & Tilak Statue Crossing',
      area: 'Ward 12 Central',
      status: 'Completed',
      date: '2026-01-15',
      amount: 520000,
      peopleBenefited: 18000,
      feedbackRating: 4.8,
      feedbackCount: 29,
      feedbacks: [
        WorkFeedbackModel(
          id: 'fb-3',
          citizenName: 'Rajesh Patil',
          rating: 5,
          comment: 'High mast lights have drastically improved night visibility and lowered petty street theft.',
          createdAt: '2026-01-20 08:45 PM',
        ),
      ],
    ),
    WorkHistoryModel(
      id: 'work-3',
      source: 'Manual',
      title: 'Underground Stormwater Drainage Network Overhaul',
      description:
          'Deep excavation and laying of 900mm reinforced concrete hume pipes connecting Sector 4 to the PMC municipal trunk drain, eliminating chronic monsoon overflow.',
      location: 'Subhash Lane & Old Bazaar Road',
      area: 'Bazaar Ward',
      status: 'InProgress',
      date: '2026-03-30',
      amount: 1850000,
      peopleBenefited: 12000,
      feedbackRating: 4.6,
      feedbackCount: 16,
      feedbacks: [
        WorkFeedbackModel(
          id: 'fb-4',
          citizenName: 'Sanjay Joshi',
          rating: 4,
          comment: 'Work is progressing steadily. Traffic diversions were well-managed by ward staff.',
          createdAt: '2026-02-14 11:20 AM',
        ),
      ],
    ),
    WorkHistoryModel(
      id: 'work-4',
      source: 'Manual',
      title: 'Nana-Nani Park Beautification & Open Gym Installation',
      description:
          'Revamping of municipal recreational green space with interlocked paver tracks, senior citizen benches, 8-station hydraulic open-air fitness equipment, and ornamental flora landscaping.',
      location: 'Behind Ward Office, Sector 3',
      area: 'Ward 12 North',
      status: 'Completed',
      date: '2025-10-10',
      amount: 680000,
      peopleBenefited: 4200,
      feedbackRating: 5.0,
      feedbackCount: 52,
      feedbacks: [
        WorkFeedbackModel(
          id: 'fb-5',
          citizenName: 'Sunita Gaikwad',
          rating: 5,
          comment: 'Our colony seniors visit every morning. The open gym equipment is safe and maintained properly.',
          createdAt: '2025-10-18 07:10 AM',
        ),
      ],
    ),
    WorkHistoryModel(
      id: 'work-5',
      source: 'Complaint',
      title: 'Replacement of Ruptured Potable Water Mainline',
      description:
          'Immediate municipal emergency replacement of corroded 150mm cast iron potable water supply line in response to citizen grievance, restoring 24x7 drinking water supply.',
      location: 'Near Shitala Devi Mandir, Lane 2',
      area: 'Shaniwar Peth',
      status: 'Completed',
      date: '2026-02-04',
      citizenName: 'Ramesh Kulkarni',
      amount: 195000,
      peopleBenefited: 1600,
      feedbackRating: 4.8,
      feedbackCount: 14,
      feedbacks: [
        WorkFeedbackModel(
          id: 'fb-6',
          citizenName: 'Ramesh Kulkarni',
          rating: 5,
          comment: 'Resolved within 48 hours of registering complaint on app. Very thankful to the team.',
          createdAt: '2026-02-06 02:30 PM',
        ),
      ],
    ),
    WorkHistoryModel(
      id: 'work-6',
      source: 'Manual',
      title: 'Sambhaji Park Jogging Track Resurfacing & Solar Studs',
      description:
          'Laying of high-durability synthetic EPDM rubberized jogging track (800 meters) accompanied by auto-illuminating solar road studs for early morning and evening runners.',
      location: 'Sambhaji Park Perimeter',
      area: 'Central Ward',
      status: 'InProgress',
      date: '2026-04-15',
      amount: 920000,
      peopleBenefited: 6500,
      feedbackRating: 4.5,
      feedbackCount: 18,
      feedbacks: [],
    ),
    WorkHistoryModel(
      id: 'work-7',
      source: 'Manual',
      title: 'Pre-Monsoon Silt Chamber Desilting & Grate Reinforcement',
      description:
          'Systematic desilting of 42 roadside silt chambers and replacement of damaged heavy-duty cast ductile iron grating covers across Ward 12 arterial corridors.',
      location: 'Multiple Arterial Corridors',
      area: 'Ward 12',
      status: 'Completed',
      date: '2025-06-05',
      amount: 340000,
      peopleBenefited: 14000,
      feedbackRating: 4.7,
      feedbackCount: 24,
      feedbacks: [],
    ),
    WorkHistoryModel(
      id: 'work-8',
      source: 'Help',
      title: 'Medical Financial Relief - Critical Dialysis Assistance',
      description:
          'Special tenure discretionary welfare relief sanctioned for low-income resident undergoing emergency renal dialysis and surgical catheterization.',
      location: 'Flat 12, Guruprasad Society',
      area: 'Shaniwar Peth',
      status: 'Completed',
      date: '2026-01-28',
      citizenName: 'Vandana Shinde',
      amount: 45000,
      peopleBenefited: 1,
      feedbackRating: 5.0,
      feedbackCount: 8,
      feedbacks: [
        WorkFeedbackModel(
          id: 'fb-7',
          citizenName: 'Vandana Shinde',
          rating: 5,
          comment: 'Timely help saved my family in medical crisis. Direct coordination was smooth.',
          createdAt: '2026-01-30 06:15 PM',
        ),
      ],
    ),
    WorkHistoryModel(
      id: 'work-9',
      source: 'Manual',
      title: 'EVM Polling Booth Facility Upgrades - Ramps & RO Water',
      description:
          'Providing disabled-friendly barrier-free concrete access ramps, handrails, and continuous chilled RO drinking water dispensers at Polling Stations 14, 15, and 16.',
      location: 'PMC Primary School No. 8',
      area: 'Ward 12 Central',
      status: 'Planned',
      date: '2026-05-30',
      amount: 280000,
      peopleBenefited: 5200,
      feedbackRating: 0.0,
      feedbackCount: 0,
      feedbacks: [],
    ),
    WorkHistoryModel(
      id: 'work-10',
      source: 'Manual',
      title: 'Clean Prabhag Initiative: Decentralized Waste Processing Shed',
      description:
          'Establishment of mini wet-waste organic composting drum units and dry segregation bays to process 2 tons of wet garbage locally per day.',
      location: 'Old Octroi Naka Yard',
      area: 'North Boundary',
      status: 'Completed',
      date: '2025-09-18',
      amount: 780000,
      peopleBenefited: 9500,
      feedbackRating: 4.9,
      feedbackCount: 33,
      feedbacks: [
        WorkFeedbackModel(
          id: 'fb-8',
          citizenName: 'Prakash Kadam',
          rating: 5,
          comment: 'Great initiative! Open garbage dumping near chowk has completely vanished.',
          createdAt: '2025-09-25 09:12 AM',
        ),
      ],
    ),
  ];

  Future<List<WorkHistoryModel>> getWorks() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return List.from(_works);
  }

  Future<WorkHistoryModel?> getWorkById(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      return _works.firstWhere((w) => w.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<WorkHistoryModel> addWork(WorkHistoryModel work) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _works.insert(0, work);
    return work;
  }

  Future<WorkHistoryModel> updateWork(WorkHistoryModel updatedWork) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final idx = _works.indexWhere((w) => w.id == updatedWork.id);
    if (idx != -1) {
      _works[idx] = updatedWork;
    }
    return updatedWork;
  }

  Future<bool> deleteWork(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final countBefore = _works.length;
    _works.removeWhere((w) => w.id == id);
    return _works.length < countBefore;
  }

  Future<void> addFeedback(String workId, WorkFeedbackModel feedback) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final idx = _works.indexWhere((w) => w.id == workId);
    if (idx != -1) {
      final existing = _works[idx];
      final updatedFeedbacks = [feedback, ...existing.feedbacks];
      final newCount = updatedFeedbacks.length;
      final sumRating = updatedFeedbacks.fold<double>(0, (sum, f) => sum + f.rating);
      final newAvg = double.parse((sumRating / newCount).toStringAsFixed(1));

      _works[idx] = existing.copyWith(
        feedbacks: updatedFeedbacks,
        feedbackCount: newCount,
        feedbackRating: newAvg,
      );
    }
  }
}

