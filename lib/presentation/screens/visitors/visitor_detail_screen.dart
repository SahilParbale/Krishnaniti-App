import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../data/models/visitor_model.dart';
import '../../../data/repositories/visitors_repository.dart';
import '../../providers/auth_provider.dart';
import 'visitor_report_generator.dart';

class VisitorDetailScreen extends ConsumerStatefulWidget {
  final VisitorModel visitor;
  final VoidCallback? onVisitorUpdated;

  const VisitorDetailScreen({
    super.key,
    required this.visitor,
    this.onVisitorUpdated,
  });

  @override
  ConsumerState<VisitorDetailScreen> createState() => _VisitorDetailScreenState();
}

class _VisitorDetailScreenState extends ConsumerState<VisitorDetailScreen> {
  late VisitorModel _visitor;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _visitor = widget.visitor;
  }

  Future<void> _makePhoneCall(String number) async {
    final uri = Uri.parse('tel:$number');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openWhatsApp(String number) async {
    final clean = number.replaceAll(RegExp(r'\D'), '');
    final fullNumber = clean.length == 10 ? '91$clean' : clean;
    final uri = Uri.parse('https://wa.me/$fullNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.delete_outline, color: Colors.red, size: 22),
            SizedBox(width: 8),
            Text('Delete Visitor Log?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Text(
          'Are you sure you want to remove the visit record for "${_visitor.name}"? This action cannot be undone.',
          style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isUpdating = true);
              try {
                final repo = ref.read(visitorsRepoProvider);
                await repo.deleteVisitor(_visitor.id);
                widget.onVisitorUpdated?.call();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Visitor log deleted'), backgroundColor: Color(0xFF0F766E)),
                  );
                  Navigator.pop(context);
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete: $e'), backgroundColor: Colors.red),
                  );
                }
              } finally {
                if (mounted) setState(() => _isUpdating = false);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showEditSheet() {
    final nameCtrl = TextEditingController(text: _visitor.name);
    final mobileCtrl = TextEditingController(text: _visitor.mobile);
    final areaCtrl = TextEditingController(text: _visitor.area ?? '');
    final refCtrl = TextEditingController(text: _visitor.reference ?? '');
    final remarksCtrl = TextEditingController(text: _visitor.remarks ?? '');
    final amountCtrl = TextEditingController(text: _visitor.amount ?? '');
    final eventDateCtrl = TextEditingController(text: _visitor.eventDate ?? '');
    final eventTimeCtrl = TextEditingController(text: _visitor.eventTime ?? '');

    String selectedPurpose = _visitor.purpose;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final isGreeting = selectedPurpose == 'Greeting' || selectedPurpose == 'Invitation';
          final isDonation = selectedPurpose == 'Donation' || selectedPurpose == 'Help';

          return Container(
            height: MediaQuery.of(context).size.height * 0.90,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Edit Visitor Details',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),

                // Form
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Visitor Full Name *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                        const SizedBox(height: 6),
                        TextField(
                          controller: nameCtrl,
                          decoration: InputDecoration(
                            hintText: 'e.g. Ramesh Patil',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),

                        const SizedBox(height: 16),

                        const Text('Contact Mobile Number', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                        const SizedBox(height: 6),
                        TextField(
                          controller: mobileCtrl,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            prefixText: '+91 ',
                            hintText: '9876543210',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),

                        const SizedBox(height: 16),

                        const Text('Purpose / Reason for Visit *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          value: ['Complaint', 'Meeting', 'Greeting', 'Donation', 'Help', 'Other'].contains(selectedPurpose) ? selectedPurpose : 'Meeting',
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'Complaint', child: Text('Complaint (तक्रार)')),
                            DropdownMenuItem(value: 'Meeting', child: Text('Meeting (भेट / चर्चा)')),
                            DropdownMenuItem(value: 'Greeting', child: Text('Greeting / Invite (निमंत्रण / सत्कार)')),
                            DropdownMenuItem(value: 'Help', child: Text('Help / Relief (वैयक्तिक मदत)')),
                            DropdownMenuItem(value: 'Donation', child: Text('Donation (देणगी / निधी)')),
                            DropdownMenuItem(value: 'Other', child: Text('Other (इतर)')),
                          ],
                          onChanged: (val) {
                            if (val != null) setModalState(() => selectedPurpose = val);
                          },
                        ),

                        const SizedBox(height: 16),

                        Text(
                          isGreeting ? 'Event Venue / Address' : 'Area / Locality',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: areaCtrl,
                          decoration: InputDecoration(
                            hintText: isGreeting ? 'e.g. Shivaji Chowk Community Hall' : 'e.g. Lane 4, Sector 2',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),

                        if (isGreeting) ...[
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Event Date', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                                    const SizedBox(height: 6),
                                    TextField(
                                      controller: eventDateCtrl,
                                      decoration: InputDecoration(
                                        hintText: 'YYYY-MM-DD',
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Event Time', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                                    const SizedBox(height: 6),
                                    TextField(
                                      controller: eventTimeCtrl,
                                      decoration: InputDecoration(
                                        hintText: 'e.g. 18:30',
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],

                        if (isDonation) ...[
                          const SizedBox(height: 16),
                          const Text('Requested Amount (₹)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                          const SizedBox(height: 6),
                          TextField(
                            controller: amountCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              prefixText: '₹ ',
                              hintText: '5000',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ],

                        const SizedBox(height: 16),

                        const Text('Reference / Leader Name (Optional)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                        const SizedBox(height: 6),
                        TextField(
                          controller: refCtrl,
                          decoration: InputDecoration(
                            hintText: 'e.g. Sunil Shinde (JE)',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),

                        const SizedBox(height: 16),

                        const Text('Discussion Notes & Remarks', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                        const SizedBox(height: 6),
                        TextField(
                          controller: remarksCtrl,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: 'Discussion summary, citizen grievance details...',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),

                        const SizedBox(height: 24),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              final name = nameCtrl.text.trim();
                              if (name.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Please enter visitor name')),
                                );
                                return;
                              }
                              Navigator.pop(ctx);
                              setState(() => _isUpdating = true);
                              try {
                                final updates = {
                                  'name': name,
                                  'mobile': mobileCtrl.text.trim(),
                                  'purpose': selectedPurpose,
                                  'area': areaCtrl.text.trim(),
                                  'reference': refCtrl.text.trim(),
                                  'remarks': remarksCtrl.text.trim(),
                                  'metadata': {
                                    if (eventDateCtrl.text.trim().isNotEmpty) 'event_date': eventDateCtrl.text.trim(),
                                    if (eventTimeCtrl.text.trim().isNotEmpty) 'event_time': eventTimeCtrl.text.trim(),
                                    if (amountCtrl.text.trim().isNotEmpty) 'amount': amountCtrl.text.trim(),
                                  },
                                };

                                final repo = ref.read(visitorsRepoProvider);
                                await repo.updateVisitor(_visitor.id, updates);
                                setState(() {
                                  _visitor = _visitor.copyWith(
                                    name: name,
                                    mobile: mobileCtrl.text.trim(),
                                    purpose: selectedPurpose,
                                    area: areaCtrl.text.trim(),
                                    reference: refCtrl.text.trim(),
                                    remarks: remarksCtrl.text.trim(),
                                    eventDate: eventDateCtrl.text.trim(),
                                    eventTime: eventTimeCtrl.text.trim(),
                                    amount: amountCtrl.text.trim(),
                                  );
                                });
                                widget.onVisitorUpdated?.call();
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Visitor updated successfully'),
                                      backgroundColor: Color(0xFF0F766E),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Failed to update: $e'), backgroundColor: Colors.red),
                                  );
                                }
                              } finally {
                                if (mounted) setState(() => _isUpdating = false);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0284C7),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text('Save Changes', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMr = ref.watch(isMarathiProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF0284C7),
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0284C7),
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 24),
            onPressed: () => Navigator.pop(context),
          ),
          titleSpacing: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isMr ? 'भेट देणारा तपशील' : 'Visitor Details',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              Text(
                _visitor.formattedDate,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withOpacity(0.85),
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Export Visitor Pass PDF',
              icon: const Icon(Icons.picture_as_pdf_outlined, color: Colors.white),
              onPressed: () {
                VisitorReportGenerator.generateAndPrintVisitorSlip(_visitor);
              },
            ),
            IconButton(
              tooltip: 'Edit Visitor',
              icon: const Icon(Icons.edit_outlined, color: Colors.white),
              onPressed: _showEditSheet,
            ),
            IconButton(
              tooltip: 'Delete Log',
              icon: const Icon(Icons.delete_outline, color: Colors.white),
              onPressed: _showDeleteDialog,
            ),
          ],
        ),
        body: _isUpdating
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Overview Profile Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: const [
                          BoxShadow(color: Color(0x08000000), blurRadius: 6, offset: Offset(0, 2)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: _visitor.purposeBgColor,
                                child: Text(
                                  _visitor.name.isNotEmpty ? _visitor.name[0].toUpperCase() : 'V',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: _visitor.purposeColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _visitor.name,
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _visitor.mobile.isNotEmpty ? '+91 ${_visitor.mobile}' : 'No Mobile Added',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF64748B),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _visitor.purposeBgColor,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: _visitor.purposeColor.withOpacity(0.3)),
                                ),
                                child: Text(
                                  _visitor.purpose,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: _visitor.purposeColor,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          if (_visitor.mobile.isNotEmpty) ...[
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _makePhoneCall(_visitor.mobile),
                                    icon: const Icon(Icons.phone_rounded, size: 16, color: Color(0xFF0284C7)),
                                    label: const Text('Call Citizen', style: TextStyle(color: Color(0xFF0284C7), fontWeight: FontWeight.bold)),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: Color(0xFF0284C7)),
                                      padding: const EdgeInsets.symmetric(vertical: 9),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _openWhatsApp(_visitor.mobile),
                                    icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16, color: Colors.white),
                                    label: const Text('WhatsApp', style: TextStyle(fontWeight: FontWeight.bold)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF25D366),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 9),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Visit Info Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Visit Details',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                          ),
                          const SizedBox(height: 12),
                          _buildDetailRow(
                            Icons.calendar_today_outlined,
                            'Visit Date & Time',
                            '${_visitor.formattedDate} at ${_visitor.formattedTime}',
                          ),
                          if (_visitor.area != null && _visitor.area!.isNotEmpty)
                            _buildDetailRow(
                              Icons.location_on_outlined,
                              'Citizen Area / Ward Address',
                              _visitor.area!,
                            ),
                          if (_visitor.reference != null && _visitor.reference!.isNotEmpty)
                            _buildDetailRow(
                              Icons.person_pin_circle_outlined,
                              'Reference / Recommendation',
                              _visitor.reference!,
                            ),
                          if (_visitor.amount != null && _visitor.amount!.isNotEmpty)
                            _buildDetailRow(
                              Icons.currency_rupee_rounded,
                              'Requested Financial Assistance',
                              '₹${_visitor.amount}',
                            ),
                          if (_visitor.eventDate != null && _visitor.eventDate!.isNotEmpty)
                            _buildDetailRow(
                              Icons.celebration_outlined,
                              'Event / Invitation Schedule',
                              'Date: ${_visitor.eventDate} | Time: ${_visitor.eventTime ?? "Flexible"}',
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Remarks / Notes
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Discussion Notes & Action Taken',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _visitor.remarks != null && _visitor.remarks!.isNotEmpty
                                ? _visitor.remarks!
                                : 'No notes or special remarks logged for this visit.',
                            style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B), height: 1.5),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF0284C7)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

