import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../data/models/newspaper_clipping_model.dart';
import '../../widgets/app_modal_sheet.dart';
import '../../widgets/app_image_picker.dart';
import '../../widgets/app_date_picker.dart';

class NewspaperClippingDetailScreen extends StatefulWidget {
  final NewspaperClippingModel clipping;
  final VoidCallback? onUpdated;
  final VoidCallback? onDeleted;

  const NewspaperClippingDetailScreen({
    super.key,
    required this.clipping,
    this.onUpdated,
    this.onDeleted,
  });

  @override
  State<NewspaperClippingDetailScreen> createState() =>
      _NewspaperClippingDetailScreenState();
}

class _NewspaperClippingDetailScreenState
    extends State<NewspaperClippingDetailScreen> {
  late NewspaperClippingModel _clipping;
  bool _showMarathi = true;

  @override
  void initState() {
    super.initState();
    _clipping = widget.clipping;
  }

  void _copySummary() {
    final text =
        '${_clipping.newspaper} (${_clipping.date})\n${_showMarathi ? _clipping.titleMarathi : _clipping.title}\n\n${_showMarathi ? _clipping.descriptionMarathi : _clipping.description}';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('News clipping summary copied to clipboard!'),
        backgroundColor: Color(0xFF0284C7),
      ),
    );
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.delete_outline_rounded, color: Colors.red),
              SizedBox(width: 8),
              Text(
                'Delete Clipping',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to delete this clipping from ${_clipping.newspaper}?',
            style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel',
                  style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                widget.onDeleted?.call();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Newspaper clipping deleted successfully.')),
                );
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _showEditModal() {
    final titleCtrl = TextEditingController(text: _clipping.titleMarathi.isNotEmpty ? _clipping.titleMarathi : _clipping.title);
    final descCtrl = TextEditingController(text: _clipping.descriptionMarathi.isNotEmpty ? _clipping.descriptionMarathi : _clipping.description);
    final urlCtrl = TextEditingController(text: _clipping.imageUrl.startsWith('http') ? _clipping.imageUrl : '');
    String sentiment = _clipping.sentiment;
    DateTime selectedDate = DateTime.tryParse(_clipping.date) ?? DateTime.now();
    XFile? pickedImage = (!_clipping.imageUrl.startsWith('http') && _clipping.imageUrl.isNotEmpty) ? XFile(_clipping.imageUrl) : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final dateFormatted = DateFormat('yyyy-MM-dd').format(selectedDate);
            return Container(
              constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 20,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  AppModalHeader(
                    icon: Icons.newspaper_rounded,
                    title: 'वृत्तपत्र कात्रण संपादन / Edit Clipping',
                    subtitle: 'कात्रण माहिती व तपशील अद्यतनित करा',
                    onClose: () => Navigator.pop(ctx),
                  ),
                  Flexible(
              child: ListView(
                shrinkWrap: true,
                      padding: EdgeInsets.only(
                        left: 20,
                        right: 20,
                        top: 16,
                        bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 24,
                      ),
                      children: [
                        // 1 & 2: Type & Date side-by-side
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const AppFieldLabel(
                                    label: 'बातमी स्वरूप (प्रकार) / Type',
                                    isRequired: true,
                                  ),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () => setModalState(() => sentiment = 'positive'),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(vertical: 10.5),
                                            decoration: BoxDecoration(
                                              color: sentiment == 'positive' ? const Color(0xFF16A34A) : const Color(0xFFF1F5F9),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(
                                                color: sentiment == 'positive' ? const Color(0xFF16A34A) : const Color(0xFFCBD5E1),
                                              ),
                                            ),
                                            alignment: Alignment.center,
                                            child: Text(
                                              'सकारात्मक / Positive',
                                              style: TextStyle(
                                                color: sentiment == 'positive' ? Colors.white : const Color(0xFF334155),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 11.5,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () => setModalState(() => sentiment = 'negative'),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(vertical: 10.5),
                                            decoration: BoxDecoration(
                                              color: sentiment == 'negative' ? const Color(0xFFDC2626) : const Color(0xFFF1F5F9),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(
                                                color: sentiment == 'negative' ? const Color(0xFFDC2626) : const Color(0xFFCBD5E1),
                                              ),
                                            ),
                                            alignment: Alignment.center,
                                            child: Text(
                                              'समस्या / Issue',
                                              style: TextStyle(
                                                color: sentiment == 'negative' ? Colors.white : const Color(0xFF334155),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 11.5,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const AppFieldLabel(
                                    label: 'तारीख / Date',
                                    isRequired: true,
                                  ),
                                  GestureDetector(
                                    onTap: () async {
                                      final picked = await showThemedDatePicker(
                                        context: modalCtx,
                                        initialDate: selectedDate,
                                        firstDate: DateTime(2020),
                                        lastDate: DateTime(2035),
                                      );
                                      if (picked != null) {
                                        setModalState(() {
                                          selectedDate = picked;
                                        });
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: const Color(0xFFCBD5E1), width: 1.0),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFF0284C7)),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              dateFormatted,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF0F172A),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // 3. Title
                        const AppFieldLabel(
                          label: 'बातमी शीर्षक / Headline',
                          isRequired: true,
                        ),
                        TextField(
                          controller: titleCtrl,
                          decoration: appInputDecoration(
                            hint: 'उदा. प्रभाग १२ मध्ये रस्त्याचे डांबरीकरण...',
                          ),
                        ),
                        const SizedBox(height: 14),

                        // 4. Image Picker (Camera & Storage)
                        AppImagePickerField(
                          label: 'कात्रण फोटो (कॅमेरा व मोबाइल स्टोरेज)',
                          isRequired: false,
                          initialFiles: pickedImage != null ? [pickedImage!] : [],
                          onFilesChanged: (files) {
                            setModalState(() {
                              pickedImage = files.isNotEmpty ? files.first : null;
                            });
                          },
                        ),
                        const SizedBox(height: 14),

                        // 5. URL
                        const AppFieldLabel(
                          label: 'बातमी लिंक / वेब URL (Web URL)',
                          isRequired: false,
                          optionalHint: 'Optional',
                        ),
                        TextField(
                          controller: urlCtrl,
                          keyboardType: TextInputType.url,
                          decoration: appInputDecoration(
                            hint: 'https://example.com/news-article...',
                            prefixIcon: const Icon(Icons.link_rounded, size: 18, color: Color(0xFF64748B)),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // 6. Description
                        const AppFieldLabel(
                          label: 'बातमीचा तपशील / गोषवारा (Description)',
                          isRequired: false,
                          optionalHint: 'Optional',
                        ),
                        TextField(
                          controller: descCtrl,
                          maxLines: 3,
                          decoration: appInputDecoration(
                            hint: 'बातमीचा संक्षिप्त गोषवारा...',
                          ),
                        ),
                        const SizedBox(height: 24),

                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0284C7),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () {
                              final text = titleCtrl.text.trim();
                              if (text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('कृपया बातमी शीर्षक प्रविष्ट करा')),
                                );
                                return;
                              }
                              final updated = _clipping.copyWith(
                                titleMarathi: text,
                                title: text,
                                descriptionMarathi: descCtrl.text.trim(),
                                description: descCtrl.text.trim(),
                                date: dateFormatted,
                                sentiment: sentiment,
                                imageUrl: pickedImage != null
                                    ? pickedImage!.path
                                    : (urlCtrl.text.trim().isNotEmpty ? urlCtrl.text.trim() : _clipping.imageUrl),
                              );
                              setState(() => _clipping = updated);
                              widget.onUpdated?.call();
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Clipping updated successfully!'),
                                  backgroundColor: Color(0xFF16A34A),
                                ),
                              );
                            },
                            child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
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
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF0284C7),
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0284C7),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Newspaper Clipping Details',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                '${_clipping.newspaper} • ${_clipping.date}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 10.5,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.copy_rounded,
                  color: Colors.white, size: 20),
              tooltip: 'Copy Summary',
              onPressed: _copySummary,
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined,
                  color: Colors.white, size: 20),
              tooltip: 'Edit Clipping',
              onPressed: _showEditModal,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded,
                  color: Colors.white, size: 20),
              tooltip: 'Delete Clipping',
              onPressed: _showDeleteDialog,
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main Media Clipping Container
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // High-Res Image Preview
                    Stack(
                      children: [
                        _buildClippingImage(),
                        // Sentiment Badge Top Left
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: _clipping.sentimentBgColor,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: _clipping.sentimentColor, width: 0.8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircleAvatar(
                                    radius: 4,
                                    backgroundColor: _clipping.sentimentColor),
                                const SizedBox(width: 5),
                                Text(
                                  _clipping.sentimentLabelMarathi,
                                  style: TextStyle(
                                    color: _clipping.sentimentColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Date Badge Top Right
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _clipping.date,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Publication Metadata Strip
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF1F5F9),
                        border: Border(
                            bottom: BorderSide(
                                color: Color(0xFFE2E8F0), width: 0.8)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _clipping.newspaperBrandColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _clipping.newspaper,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '${_clipping.edition} • ${_clipping.pageNumber}',
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFF475569),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          if (_clipping.journalistName != null)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.person_outline_rounded,
                                    size: 13, color: Color(0xFF64748B)),
                                const SizedBox(width: 3),
                                Text(
                                  _clipping.journalistName!,
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),

                    // Content Section
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Language Switcher Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Headline & Article',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    GestureDetector(
                                      onTap: () => setState(
                                          () => _showMarathi = true),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: _showMarathi
                                              ? const Color(0xFF0284C7)
                                              : Colors.transparent,
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          'Regional',
                                          style: TextStyle(
                                            color: _showMarathi
                                                ? Colors.white
                                                : const Color(0xFF64748B),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () => setState(
                                          () => _showMarathi = false),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: !_showMarathi
                                              ? const Color(0xFF0284C7)
                                              : Colors.transparent,
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          'English',
                                          style: TextStyle(
                                            color: !_showMarathi
                                                ? Colors.white
                                                : const Color(0xFF64748B),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Headline
                          Text(
                            _showMarathi
                                ? _clipping.titleMarathi
                                : _clipping.title,
                            style: const TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.bold,
                              height: 1.45,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Description
                          Text(
                            _showMarathi
                                ? _clipping.descriptionMarathi
                                : _clipping.description,
                            style: const TextStyle(
                              fontSize: 13.5,
                              height: 1.6,
                              color: Color(0xFF334155),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Civic Action Taken Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _clipping.isPositive
                        ? const Color(0xFFBBF7D0)
                        : const Color(0xFFFECACA),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: _clipping.isPositive
                                ? const Color(0xFFDCFCE7)
                                : const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _clipping.isPositive
                                ? Icons.task_alt_rounded
                                : Icons.published_with_changes_rounded,
                            size: 16,
                            color: _clipping.sentimentColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _clipping.isPositive
                            ? 'Development Milestone'
                            : 'Civic Action Taken',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: _clipping.sentimentColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _clipping.actionTaken ??
                          'Conducted inspection with municipal engineers and resolved the civic issue.',
                      style: const TextStyle(
                        fontSize: 12.5,
                        height: 1.5,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Share / Export Actions
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0284C7),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.share_rounded, size: 18),
                      label: const Text('Share Summary',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: _copySummary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClippingImage() {
    Widget placeholder() => Container(
          width: double.infinity,
          height: 200,
          color: Colors.grey.shade200,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.newspaper_rounded,
                  size: 52, color: Colors.grey.shade400),
              const SizedBox(height: 8),
              Text(
                '${_clipping.newspaper} Press Clipping',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ],
          ),
        );

    if (_clipping.imageUrl.startsWith('http://') ||
        _clipping.imageUrl.startsWith('https://')) {
      return Image.network(
        _clipping.imageUrl,
        width: double.infinity,
        height: 240,
        fit: BoxFit.cover,
        errorBuilder: (ctx, err, stack) => placeholder(),
      );
    }
    try {
      final file = File(_clipping.imageUrl);
      if (file.existsSync()) {
        return Image.file(
          file,
          width: double.infinity,
          height: 240,
          fit: BoxFit.cover,
          errorBuilder: (ctx, err, stack) => placeholder(),
        );
      }
    } catch (_) {}
    return placeholder();
  }
}

