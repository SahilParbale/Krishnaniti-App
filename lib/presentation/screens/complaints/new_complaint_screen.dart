import 'package:flutter/material.dart';
import 'new_complaint_bottom_sheet.dart';

class NewComplaintScreen extends StatelessWidget {
  final String initialTab;
  final String? prefillVoterId;
  final String? prefillVoterName;

  const NewComplaintScreen({
    super.key,
    this.initialTab = 'Complaints',
    this.prefillVoterId,
    this.prefillVoterName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: NewComplaintBottomSheet(
          initialTab: initialTab,
          prefillVoterId: prefillVoterId,
          prefillVoterName: prefillVoterName,
        ),
      ),
    );
  }
}
