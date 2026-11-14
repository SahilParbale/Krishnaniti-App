import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../data/models/newspaper_clipping_model.dart';

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
    final titleMrCtrl = TextEditingController(text: _clipping.titleMarathi);
    final titleEnCtrl = TextEditingController(text: _clipping.title);
    final descMrCtrl =
        TextEditingController(text: _clipping.descriptionMarathi);
    final descEnCtrl = TextEditingController(text: _clipping.description);
    final actionCtrl =
        TextEditingController(text: _clipping.actionTaken ?? '');
    final pageCtrl =
        TextEditingController(text: _clipping.pageNumber ?? 'Page 3');
    String newspaper = _clipping.newspaper;
    String sentiment = _clipping.sentiment;

    InputDecoration inputDec({String? hint, String? prefixText}) {
      return InputDecoration(
        hintText: hint,
        prefixText: prefixText,
        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
        prefixStyle: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.5),
        ),
      );
    }

    Widget fieldLabel(String text, {bool isRequired = false}) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 5.0),
        child: RichText(
          text: TextSpan(
            text: text,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
            children: isRequired
                ? const [
                    TextSpan(
                      text: ' *',
                      style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                  ]
                : [],
          ),
        ),
      );
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.88,
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
              padding: EdgeInsets.only(
                top: 8,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 20,
              ),
              child: Column(
                children: [
                  // Top Drag Handle
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      margin: const EdgeInsets.only(top: 6, bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0284C7).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.edit_note_rounded, color: Color(0xFF0284C7), size: 20),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Edit Clipping Details',
                          style: TextStyle(fontSize: 17.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                        onPressed: () => Navigator.pop(ctx),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Coverage Type & Newspaper side-by-side
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    fieldLabel('Coverage Type'),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: GestureDetector(
                                            onTap: () => setModalState(() => sentiment = 'positive'),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(vertical: 10),
                                              decoration: BoxDecoration(
                                                color: sentiment == 'positive' ? const Color(0xFF16A34A) : const Color(0xFFF1F5F9),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              alignment: Alignment.center,
                                              child: Text(
                                                'Positive',
                                                style: TextStyle(
                                                  color: sentiment == 'positive' ? Colors.white : const Color(0xFF334155),
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
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
                                              padding: const EdgeInsets.symmetric(vertical: 10),
                                              decoration: BoxDecoration(
                                                color: sentiment == 'negative' ? const Color(0xFFDC2626) : const Color(0xFFF1F5F9),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              alignment: Alignment.center,
                                              child: Text(
                                                'Issue',
                                                style: TextStyle(
                                                  color: sentiment == 'negative' ? Colors.white : const Color(0xFF334155),
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
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
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    fieldLabel('Newspaper', isRequired: true),
                                    DropdownButtonFormField<String>(
                                      initialValue: newspaper,
                                      decoration: inputDec(),
                                      items: const [
                                        DropdownMenuItem(value: 'Sakal', child: Text('Sakal')),
                                        DropdownMenuItem(value: 'Lokmat', child: Text('Lokmat')),
                                        DropdownMenuItem(value: 'Maharashtra Times', child: Text('Maharashtra Times')),
                                        DropdownMenuItem(value: 'Pudhari', child: Text('Pudhari')),
                                        DropdownMenuItem(value: 'Loksatta', child: Text('Loksatta')),
                                        DropdownMenuItem(value: 'The Indian Express', child: Text('The Indian Express')),
                                      ],
                                      onChanged: (val) {
                                        if (val != null) {
                                          setModalState(() => newspaper = val);
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Headline Marathi & Headline English side-by-side
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    fieldLabel('Headline (Marathi / Regional)', isRequired: true),
                                    TextField(
                                      controller: titleMrCtrl,
                                      decoration: inputDec(hint: 'Road resurfacing in Ward 12...'),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    fieldLabel('Headline (English)'),
                                    TextField(
                                      controller: titleEnCtrl,
                                      decoration: inputDec(hint: 'Major development fund...'),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Page & Edition
                          fieldLabel('Page & Edition'),
                          TextField(
                            controller: pageCtrl,
                            decoration: inputDec(hint: 'Page 3 • Pune Metro'),
                          ),
                          const SizedBox(height: 12),

                          // Description
                          fieldLabel('Description / Article Summary'),
                          TextField(
                            controller: descMrCtrl,
                            maxLines: 3,
                            decoration: inputDec(hint: 'Summary of published coverage...'),
                          ),
                          const SizedBox(height: 12),

                          // Civic Action Taken
                          fieldLabel('Civic Action Taken'),
                          TextField(
                            controller: actionCtrl,
                            maxLines: 2,
                            decoration: inputDec(hint: 'Action taken by corporator after news...'),
                          ),
                          const SizedBox(height: 20),

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
                                final updated = _clipping.copyWith(
                                  titleMarathi: titleMrCtrl.text.trim(),
                                  title: titleEnCtrl.text.trim(),
                                  descriptionMarathi: descMrCtrl.text.trim(),
                                  description: descEnCtrl.text.trim(),
                                  actionTaken: actionCtrl.text.trim(),
                                  newspaper: newspaper,
                                  sentiment: sentiment,
                                  pageNumber: pageCtrl.text.trim().isNotEmpty
                                      ? pageCtrl.text.trim()
                                      : _clipping.pageNumber,
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

