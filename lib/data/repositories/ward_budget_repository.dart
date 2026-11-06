import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ward_budget_model.dart';

final wardBudgetRepoProvider = Provider<WardBudgetRepository>((ref) {
  return WardBudgetRepository();
});

class WardBudgetRepository {
  static final List<WardBudgetModel> _budgets = [
    WardBudgetModel(
      id: 'bdg-001',
      financialYear: '2024-2025',
      category: 'Road Resurfacing & Footpath Paving',
      totalAllocation: 5500000,
      utilizedAmount: 4650000,
      area: 'Bajirao Road & Shaniwar Peth',
      status: 'Active',
      createdAt: '2024-04-05T10:00:00Z',
      updatedAt: '2024-09-12T14:30:00Z',
    ),
    WardBudgetModel(
      id: 'bdg-002',
      financialYear: '2024-2025',
      category: 'Potable Water Pipeline & Pressure Booster',
      totalAllocation: 4200000,
      utilizedAmount: 3550000,
      area: 'Shaniwar Peth & Kasba Ward',
      status: 'Active',
      createdAt: '2024-04-10T11:15:00Z',
      updatedAt: '2024-08-20T16:45:00Z',
    ),
    WardBudgetModel(
      id: 'bdg-003',
      financialYear: '2024-2025',
      category: 'Storm Water Box Drains & Gutter Covering',
      totalAllocation: 3800000,
      utilizedAmount: 3100000,
      area: 'Kasba Peth Lowland',
      status: 'Active',
      createdAt: '2024-05-02T09:30:00Z',
      updatedAt: '2024-07-30T12:00:00Z',
    ),
    WardBudgetModel(
      id: 'bdg-004',
      financialYear: '2024-2025',
      category: 'Street Lighting & Photocell LED Towers',
      totalAllocation: 2500000,
      utilizedAmount: 1450000,
      area: 'Ward 12 Main Arteries',
      status: 'Active',
      createdAt: '2024-05-18T14:00:00Z',
      updatedAt: '2024-09-01T10:20:00Z',
    ),
    WardBudgetModel(
      id: 'bdg-005',
      financialYear: '2024-2025',
      category: 'Municipal Dispensary & Maternity Health Wing',
      totalAllocation: 3200000,
      utilizedAmount: 1800000,
      area: 'Ward 12 Central',
      status: 'Active',
      createdAt: '2024-06-01T10:45:00Z',
      updatedAt: '2024-09-15T15:10:00Z',
    ),
    WardBudgetModel(
      id: 'bdg-006',
      financialYear: '2024-2025',
      category: 'Solid Waste & Zero-Waste Composting Pits',
      totalAllocation: 2000000,
      utilizedAmount: 1650000,
      area: 'Bazaar Ward & Society Clusters',
      status: 'Active',
      createdAt: '2024-06-15T12:30:00Z',
      updatedAt: '2024-09-22T11:40:00Z',
    ),
    WardBudgetModel(
      id: 'bdg-007',
      financialYear: '2024-2025',
      category: 'Public Garden, Jogging Track & Open Gym',
      totalAllocation: 2200000,
      utilizedAmount: 950000,
      area: 'Sambhaji Garden Vicinity',
      status: 'Active',
      createdAt: '2024-07-01T09:00:00Z',
      updatedAt: '2024-08-14T17:00:00Z',
    ),
    WardBudgetModel(
      id: 'bdg-008',
      financialYear: '2024-2025',
      category: 'Municipal School Digital Lab & Classrooms',
      totalAllocation: 1600000,
      utilizedAmount: 650000,
      area: 'PMC School No. 18',
      status: 'Active',
      createdAt: '2024-07-15T15:30:00Z',
      updatedAt: '2024-09-05T13:15:00Z',
    ),
    // FY 2023-2024
    WardBudgetModel(
      id: 'bdg-101',
      financialYear: '2023-2024',
      category: 'Arterial Road Cement Concreting',
      totalAllocation: 4800000,
      utilizedAmount: 4720000,
      area: 'Bajirao Road',
      status: 'Closed',
      createdAt: '2023-04-12T10:00:00Z',
      updatedAt: '2024-03-25T16:00:00Z',
    ),
    WardBudgetModel(
      id: 'bdg-102',
      financialYear: '2023-2024',
      category: 'Drinking Water Overhead Tank Maintenance',
      totalAllocation: 3100000,
      utilizedAmount: 3050000,
      area: 'Shaniwar Peth',
      status: 'Closed',
      createdAt: '2023-05-10T11:00:00Z',
      updatedAt: '2024-03-28T14:00:00Z',
    ),
    WardBudgetModel(
      id: 'bdg-103',
      financialYear: '2023-2024',
      category: 'Gutter Replacement & Concrete Slab Coverings',
      totalAllocation: 2600000,
      utilizedAmount: 2550000,
      area: 'Kasba Peth',
      status: 'Closed',
      createdAt: '2023-06-08T09:30:00Z',
      updatedAt: '2024-03-15T12:00:00Z',
    ),
    WardBudgetModel(
      id: 'bdg-104',
      financialYear: '2023-2024',
      category: 'Ward High-Mast Lighting Installation',
      totalAllocation: 1800000,
      utilizedAmount: 1780000,
      area: 'Ward 12 Chowks',
      status: 'Closed',
      createdAt: '2023-07-02T13:45:00Z',
      updatedAt: '2024-02-20T10:30:00Z',
    ),
  ];

  Future<List<WardBudgetModel>> getBudgets({
    String? year,
    String? query,
    String? area,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
    var results = List<WardBudgetModel>.from(_budgets);

    if (year != null && year.isNotEmpty && year != 'All') {
      results = results.where((b) => b.financialYear == year).toList();
    }

    if (area != null && area.isNotEmpty && area != 'All') {
      results = results.where((b) => b.area.toLowerCase().contains(area.toLowerCase())).toList();
    }

    if (query != null && query.trim().isNotEmpty) {
      final q = query.toLowerCase().trim();
      results = results.where((b) {
        return b.category.toLowerCase().contains(q) ||
            b.area.toLowerCase().contains(q) ||
            b.financialYear.toLowerCase().contains(q);
      }).toList();
    }

    results.sort((a, b) => b.totalAllocation.compareTo(a.totalAllocation));
    return results;
  }

  Future<WardBudgetModel?> getBudgetById(String id) async {
    await Future.delayed(const Duration(milliseconds: 50));
    try {
      return _budgets.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<WardBudgetModel> addBudget(WardBudgetModel budget) async {
    await Future.delayed(const Duration(milliseconds: 120));
    _budgets.insert(0, budget);
    return budget;
  }

  Future<WardBudgetModel> updateBudget(WardBudgetModel budget) async {
    await Future.delayed(const Duration(milliseconds: 120));
    final index = _budgets.indexWhere((b) => b.id == budget.id);
    if (index != -1) {
      _budgets[index] = budget;
      return budget;
    }
    throw Exception('Budget record not found');
  }

  Future<void> updateUtilization(String id, double newUtilized) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final index = _budgets.indexWhere((b) => b.id == id);
    if (index != -1) {
      final existing = _budgets[index];
      _budgets[index] = existing.copyWith(
        utilizedAmount: newUtilized,
        updatedAt: DateTime.now().toIso8601String(),
      );
    }
  }

  Future<bool> deleteBudget(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final index = _budgets.indexWhere((b) => b.id == id);
    if (index != -1) {
      _budgets.removeAt(index);
      return true;
    }
    return false;
  }
}

