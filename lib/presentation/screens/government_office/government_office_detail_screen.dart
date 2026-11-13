import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../data/models/government_office_model.dart';
import '../../../data/repositories/government_office_repository.dart';
import '../../providers/auth_provider.dart';

class GovernmentOfficeDetailScreen extends ConsumerStatefulWidget {
  final GovernmentOfficeModel office;

  const GovernmentOfficeDetailScreen({super.key, required this.office});

  @override
  ConsumerState<GovernmentOfficeDetailScreen> createState() => _GovernmentOfficeDetailScreenState();
}

class _GovernmentOfficeDetailScreenState extends ConsumerState<GovernmentOfficeDetailScreen> {
  late GovernmentOfficeModel _currentOffice;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _currentOffice = widget.office;
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:$cleanNumber');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not initiate call to $phoneNumber')),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Calling $phoneNumber')),
        );
      }
    }
  }

  Future<void> _openMaps() async {
    final query = Uri.encodeComponent('${_currentOffice.name}, ${_currentOffice.address}');
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open map navigation')),
          );
        }
      }
    } catch (_) {
      // Fallback
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Delete Government Office'),
          ],
        ),
        content: Text(
          'Are you sure you want to remove "${_currentOffice.name}" from the civic directory? This action cannot be undone.',
          style: const TextStyle(fontSize: 14, color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isDeleting = true);
              final repo = ref.read(governmentOfficeRepoProvider);
              await repo.deleteOffice(_currentOffice.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Office entry deleted successfully'),
                    backgroundColor: Colors.red,
                  ),
                );
                Navigator.pop(context, true);
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showEditModal() {
    final isMr = ref.read(isMarathiProvider);
    final nameCtrl = TextEditingController(text: _currentOffice.name);
    final addrCtrl = TextEditingController(text: _currentOffice.address);
    final officerCtrl = TextEditingController(text: _currentOffice.officerName);
    final phoneCtrl = TextEditingController(text: _currentOffice.contactNumber);
    final areaCtrl = TextEditingController(text: _currentOffice.area);

    InputDecoration inputDec({required String hintText, IconData? prefixIcon}) {
      return InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 18, color: const Color(0xFF64748B)) : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.5),
        ),
      );
    }

    Widget fieldLabel(String label, {bool isRequired = false}) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
            ),
            if (isRequired) ...[
              const SizedBox(width: 2),
              const Text('*', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ],
          ],
        ),
      );
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (stCtx, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.90,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, -4)),
                ],
              ),
              child: Column(
                children: [
                  // Downward Dismiss Drag Handle
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      margin: const EdgeInsets.only(top: 10, bottom: 6),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),

                  // Header with Title and Close Button
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isMr ? 'सरकारी कार्यालय बदला' : 'Edit Government Office',
                          style: const TextStyle(
                            fontSize: 17.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.2,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(sheetCtx),
                          icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),

                  // Scrollable Body
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.only(
                        top: 14,
                        left: 18,
                        right: 18,
                        bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 24,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Office Name (Full Width)
                          fieldLabel(isMr ? 'कार्याल याचे नाव' : 'Office Name', isRequired: true),
                          TextField(
                            controller: nameCtrl,
                            decoration: inputDec(
                              hintText: isMr ? 'उदा. प्रभाग कार्यालय क्र. १२' : 'e.g. PMC Ward Office No. 12',
                              prefixIcon: Icons.apartment_rounded,
                            ),
                          ),
                          const SizedBox(height: 14),

                          // 2. Address (Full Width)
                          fieldLabel(isMr ? 'पत्ता' : 'Address', isRequired: true),
                          TextField(
                            controller: addrCtrl,
                            maxLines: 2,
                            decoration: inputDec(
                              hintText: isMr ? 'उदा. शनिवार वाड्यासमोर, पुणे - ४११०३०' : 'e.g. Near Shaniwar Wada, Pune - 411030',
                              prefixIcon: Icons.location_on_outlined,
                            ),
                          ),
                          const SizedBox(height: 14),

                          // 3 & 4. Officer In-Charge + Contact Number (Side-by-Side)
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    fieldLabel(isMr ? 'अधिकारी / प्रमुख' : 'Officer In-charge', isRequired: true),
                                    TextField(
                                      controller: officerCtrl,
                                      decoration: inputDec(
                                        hintText: isMr ? 'उदा. श्री. रमेश गायकवाड' : 'e.g. Shri. Ramesh Gaikwad',
                                        prefixIcon: Icons.person_outline_rounded,
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
                                    fieldLabel(isMr ? 'संपर्क' : 'Contact', isRequired: true),
                                    TextField(
                                      controller: phoneCtrl,
                                      keyboardType: TextInputType.phone,
                                      decoration: inputDec(
                                        hintText: isMr ? 'उदा. ०२०-२५५०११४०' : 'e.g. 020-25501140',
                                        prefixIcon: Icons.phone_outlined,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // 5. Location / Area (Full Width)
                          fieldLabel(isMr ? 'ठिकाण' : 'Location / Area', isRequired: true),
                          TextField(
                            controller: areaCtrl,
                            decoration: inputDec(
                              hintText: isMr ? 'उदा. शनिवार पेठ' : 'e.g. Shaniwar Peth',
                              prefixIcon: Icons.map_outlined,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Submit Button
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0284C7),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: const Icon(Icons.business_rounded, size: 18),
                              onPressed: () async {
                                if (nameCtrl.text.trim().isEmpty || phoneCtrl.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(isMr ? 'कृपया सर्व आवश्यक माहिती भरा' : 'Please fill required fields'),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                  return;
                                }

                                final updated = _currentOffice.copyWith(
                                  name: nameCtrl.text.trim(),
                                  address: addrCtrl.text.trim(),
                                  officerName: officerCtrl.text.trim().isNotEmpty ? officerCtrl.text.trim() : _currentOffice.officerName,
                                  contactNumber: phoneCtrl.text.trim(),
                                  area: areaCtrl.text.trim().isNotEmpty ? areaCtrl.text.trim() : _currentOffice.area,
                                );

                                final repo = ref.read(governmentOfficeRepoProvider);
                                await repo.updateOffice(updated);

                                if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                                if (mounted) {
                                  setState(() => _currentOffice = updated);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(isMr ? 'कार्यालय माहिती यशस्वीरित्या अद्यतनित केली!' : 'Office details updated successfully!'),
                                      backgroundColor: const Color(0xFF16A34A),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              },
                              label: Text(
                                isMr ? 'कार्यालय जतन करा' : 'Save Office',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
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
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMr = ref.watch(isMarathiProvider);
    final office = _currentOffice;

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
            tooltip: 'Back',
            onPressed: () => Navigator.pop(context, true),
          ),
          titleSpacing: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isMr ? 'कार्यालय तपशील' : 'Office Details',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.2,
                ),
              ),
              Text(
                '${office.category} • ${office.area}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w400,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.white),
              tooltip: 'Edit Office',
              onPressed: _showEditModal,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.white),
              tooltip: 'Delete Office',
              onPressed: _showDeleteConfirmation,
            ),
          ],
        ),
        body: _isDeleting
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Main Office Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: office.categoryBgColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(office.categoryIcon, size: 24, color: office.categoryColor),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: office.categoryBgColor,
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: office.categoryColor.withValues(alpha: 0.3)),
                                          ),
                                          child: Text(
                                            isMr ? office.categoryDisplayMr : office.category,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: office.categoryColor,
                                            ),
                                          ),
                                        ),
                                        if (office.isEmergency) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFEF2F2),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: const Color(0xFFFECACA)),
                                            ),
                                            child: const Text(
                                              '24x7 Helpline',
                                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      office.name,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0F172A),
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),

                          // Direct Quick Action Buttons
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF16A34A),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  icon: const Icon(Icons.phone_forwarded_rounded, size: 18),
                                  label: Text(
                                    isMr ? 'कॉल करा' : 'Call Now',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                                  ),
                                  onPressed: () => _makePhoneCall(office.contactNumber),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF0284C7),
                                    side: const BorderSide(color: Color(0xFF0284C7), width: 1.2),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  icon: const Icon(Icons.directions_outlined, size: 18),
                                  label: Text(
                                    isMr ? 'नकाशा / मार्ग' : 'Directions',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                                  ),
                                  onPressed: _openMaps,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Officer In-Charge Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.person_outline_rounded, size: 20, color: Color(0xFF0284C7)),
                              const SizedBox(width: 8),
                              Text(
                                isMr ? 'कार्यालय प्रमुख / जबाबदार अधिकारी' : 'Officer In-Charge',
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                              ),
                            ],
                          ),
                          const Divider(height: 20),
                          Text(
                            office.officerName,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(Icons.phone_in_talk_outlined, size: 16, color: Color(0xFF64748B)),
                              const SizedBox(width: 6),
                              Text(
                                office.contactNumber,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.copy_rounded, size: 18, color: Color(0xFF64748B)),
                                tooltip: 'Copy Phone',
                                visualDensity: VisualDensity.compact,
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: office.contactNumber));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Contact copied to clipboard')),
                                  );
                                },
                              ),
                            ],
                          ),
                          if (office.secondaryContact != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.support_agent_rounded, size: 16, color: Color(0xFF64748B)),
                                const SizedBox(width: 6),
                                Text(
                                  '${isMr ? "पर्यायी / हेल्पलाईन" : "Alternate Helpline"}: ${office.secondaryContact}',
                                  style: const TextStyle(fontSize: 13, color: Color(0xFF475569), fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Timings and Working Hours Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.access_time_rounded, size: 20, color: Color(0xFF0284C7)),
                              const SizedBox(width: 8),
                              Text(
                                isMr ? 'कामकाजाची वेळ व संपर्क' : 'Working Hours & Communication',
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                              ),
                            ],
                          ),
                          const Divider(height: 20),
                          _infoRow(
                            icon: Icons.schedule_rounded,
                            label: isMr ? 'कार्यालयीन वेळ' : 'Hours',
                            value: office.timing,
                          ),
                          if (office.email != null) ...[
                            const SizedBox(height: 12),
                            _infoRow(
                              icon: Icons.alternate_email_rounded,
                              label: isMr ? 'अधिकृत ईमेल' : 'Email Address',
                              value: office.email!,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Address & Location Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined, size: 20, color: Color(0xFF0284C7)),
                              const SizedBox(width: 8),
                              Text(
                                isMr ? 'पत्ता आणि परिसर' : 'Location & Address',
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                              ),
                            ],
                          ),
                          const Divider(height: 20),
                          Text(
                            office.address,
                            style: const TextStyle(fontSize: 14, color: Color(0xFF334155), height: 1.4),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.pin_drop_rounded, size: 16, color: Color(0xFF0284C7)),
                              const SizedBox(width: 4),
                              Text(
                                'Prabhag Area: ${office.area}',
                                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                              ),
                              const Spacer(),
                              TextButton.icon(
                                style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                                icon: const Icon(Icons.content_copy_rounded, size: 14),
                                label: Text(isMr ? 'पत्ता कॉपी करा' : 'Copy Address'),
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: office.address));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Address copied to clipboard')),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _infoRow({required IconData icon, required String label, required String value}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF64748B)),
        const SizedBox(width: 10),
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13.5, color: Color(0xFF0F172A), fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

