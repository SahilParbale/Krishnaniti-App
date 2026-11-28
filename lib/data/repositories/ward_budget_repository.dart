import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/supabase_service.dart';
import '../../core/services/delta_sync_cache.dart';
import '../models/ward_budget_model.dart';

final wardBudgetRepoProvider = Provider<WardBudgetRepository>((ref) {
  return WardBudgetRepository();
});

class WardBudgetRepository {
  final SupabaseClient _client = SupabaseService.instance.client;
  String? get _tenantId => SupabaseService.instance.activeTenantId;

  Future<List<WardBudgetModel>> getBudgets({
    String? year,
    String? category,
    String? status,
    String? query,
  }) async {
    try {
      var dbQuery = _client.from('ward_provisions').select('*');

      if (_tenantId != null && _tenantId!.isNotEmpty) {
        dbQuery = dbQuery.eq('tenant_id', _tenantId!);
      }

      if (year != null && year.isNotEmpty && year != 'All') {
        dbQuery = dbQuery.eq('financial_year', year);
      }

      if (category != null && category.isNotEmpty && category != 'All') {
        dbQuery = dbQuery.eq('category', category);
      }

      if (status != null && status.isNotEmpty && status != 'All') {
        dbQuery = dbQuery.eq('status', status);
      }

      final cacheKey = 'ward_budget_${_tenantId ?? 'default'}';
      final response = await DeltaSyncCache.sync(cacheKey, (lastSyncedAt) async {
        var q = dbQuery;
        if (lastSyncedAt != null) {
          q = q.gt('updated_at', lastSyncedAt);
        }
        final res = await q.order('created_at', ascending: false);
        return (res as List<dynamic>).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      });
      var list = (response as List<dynamic>)
          .map((item) => WardBudgetModel.fromJson(item as Map<String, dynamic>))
          .toList();

      if (query != null && query.trim().isNotEmpty) {
        final q = query.trim().toLowerCase();
        list = list.where((b) {
          return b.category.toLowerCase().contains(q) ||
              b.area.toLowerCase().contains(q) ||
              b.financialYear.toLowerCase().contains(q);
        }).toList();
      }

      return list;
    } catch (_) {
      return [];
    }
  }

  Future<WardBudgetModel?> getBudgetById(String id) async {
    try {
      var query = _client.from('ward_provisions').select('*').eq('id', id);
      if (_tenantId != null && _tenantId!.isNotEmpty) {
        query = query.eq('tenant_id', _tenantId!);
      }
      final response = await query.maybeSingle();
      if (response == null) return null;
      return WardBudgetModel.fromJson(response);
    } catch (_) {
      return null;
    }
  }

  Future<WardBudgetModel> addBudget(WardBudgetModel budget) async {
    final payload = {
      'title': budget.category,
      'financial_year': budget.financialYear,
      'category': budget.category,
      'sanctioned_amount': budget.totalAllocation,
      'requested_amount': budget.utilizedAmount,
      'area': budget.area,
      'status': budget.status,
      'tenant_id': _tenantId,
      'created_at': DateTime.now().toIso8601String(),
    };

    final res = await _client.from('ward_provisions').insert(payload).select().single();
    return WardBudgetModel.fromJson(res);
  }

  Future<WardBudgetModel> updateBudget(WardBudgetModel updatedBudget) async {
    final payload = {
      'title': updatedBudget.category,
      'financial_year': updatedBudget.financialYear,
      'category': updatedBudget.category,
      'sanctioned_amount': updatedBudget.totalAllocation,
      'requested_amount': updatedBudget.utilizedAmount,
      'area': updatedBudget.area,
      'status': updatedBudget.status,
      'updated_at': DateTime.now().toIso8601String(),
    };

    var query = _client.from('ward_provisions').update(payload).eq('id', updatedBudget.id);
    if (_tenantId != null && _tenantId!.isNotEmpty) {
      query = query.eq('tenant_id', _tenantId!);
    }
    await query;
    return updatedBudget;
  }

  Future<void> updateUtilization(String id, double newAmount) async {
    try {
      var query = _client.from('ward_provisions').update({
        'requested_amount': newAmount,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', id);
      if (_tenantId != null && _tenantId!.isNotEmpty) {
        query = query.eq('tenant_id', _tenantId!);
      }
      await query;
    } catch (_) {}
  }

  Future<bool> deleteBudget(String id) async {
    try {
      var query = _client.from('ward_provisions').delete().eq('id', id);
      if (_tenantId != null && _tenantId!.isNotEmpty) {
        query = query.eq('tenant_id', _tenantId!);
      }
      await query;
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>> getBudgetSummary({String? year}) async {
    final list = await getBudgets(year: year);
    final totalAllocated = list.fold<double>(0.0, (acc, b) => acc + b.totalAllocation);
    final totalUtilized = list.fold<double>(0.0, (acc, b) => acc + b.utilizedAmount);
    final remaining = (totalAllocated - totalUtilized).clamp(0.0, double.infinity);
    final utilizationPct = totalAllocated > 0 ? ((totalUtilized / totalAllocated) * 100.0) : 0.0;

    return {
      'totalAllocated': totalAllocated,
      'totalUtilized': totalUtilized,
      'remaining': remaining,
      'utilizationPct': utilizationPct,
      'activeCategoriesCount': list.where((b) => b.status == 'Active').length,
    };
  }
}
