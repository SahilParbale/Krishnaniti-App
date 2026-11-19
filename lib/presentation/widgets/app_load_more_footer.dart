import 'dart:math';
import 'package:flutter/material.dart';

class AppLoadMoreFooter extends StatelessWidget {
  final int currentCount;
  final int totalCount;
  final VoidCallback? onLoadMore;
  final bool isLoading;
  final int pageSize;
  final String label;
  final bool isMarathi;

  const AppLoadMoreFooter({
    super.key,
    required this.currentCount,
    required this.totalCount,
    required this.onLoadMore,
    this.isLoading = false,
    this.pageSize = 20,
    this.label = 'records',
    this.isMarathi = false,
  });

  @override
  Widget build(BuildContext context) {
    if (totalCount == 0) {
      return const SizedBox.shrink();
    }

    final hasMore = currentCount < totalCount;
    final remaining = max(0, totalCount - currentCount);
    final nextBatch = min(pageSize, remaining);

    if (!hasMore) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(width: 28, height: 1, color: const Color(0xFFCBD5E1)),
            const SizedBox(width: 10),
            const Icon(Icons.check_circle_outline_rounded, size: 14, color: Color(0xFF10B981)),
            const SizedBox(width: 6),
            Text(
              isMarathi
                  ? 'सर्व $totalCount $label दाखवले आहेत'
                  : 'All $totalCount $label loaded',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(width: 10),
            Container(width: 28, height: 1, color: const Color(0xFFCBD5E1)),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isMarathi
                    ? '$totalCount पैकी $currentCount $label दाखवत आहे'
                    : 'Showing $currentCount of $totalCount $label',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isMarathi ? '$remaining शिल्लक' : '$remaining remaining',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0284C7),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton.icon(
              onPressed: isLoading ? null : onLoadMore,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.arrow_downward_rounded, size: 16),
              label: Text(
                isLoading
                    ? (isMarathi ? 'लोड होत आहे...' : 'Loading...')
                    : (isMarathi
                        ? 'पुढील $nextBatch $label दाखवा'
                        : 'Load Next $nextBatch $label'),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
