import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/services/supabase_service.dart';
import 'app_modal_sheet.dart';

/// Standardized Image / Document Upload widget across all popups.
/// Directly mirrors Nagarsevak-Managment MultiFileUpload with two unified buttons:
/// [Camera] (कॅमेरा) and [Phone Storage / Gallery] (फोन स्टोरेज / गॅलरी)
/// followed by thumbnail previews with remove (X) capability.
class AppImagePickerField extends StatefulWidget {
  final String? label;
  final bool isRequired;
  final bool isMarathi;
  final bool allowMultiple;
  final List<XFile> initialFiles;
  final String? initialUrl;
  final bool? enableCamera;
  final ValueChanged<List<XFile>> onFilesChanged;
  final VoidCallback? onInitialUrlRemoved;

  const AppImagePickerField({
    super.key,
    this.label,
    this.isRequired = false,
    this.isMarathi = false,
    this.allowMultiple = false,
    this.initialFiles = const [],
    this.initialUrl,
    this.enableCamera,
    required this.onFilesChanged,
    this.onInitialUrlRemoved,
  });

  @override
  State<AppImagePickerField> createState() => _AppImagePickerFieldState();
}

class _AppImagePickerFieldState extends State<AppImagePickerField> {
  final ImagePicker _picker = ImagePicker();
  late List<XFile> _files;
  String? _existingUrl;

  @override
  void initState() {
    super.initState();
    _files = List.from(widget.initialFiles);
    _existingUrl = widget.initialUrl;
  }

  @override
  void didUpdateWidget(covariant AppImagePickerField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialFiles != oldWidget.initialFiles) {
      _files = List.from(widget.initialFiles);
    }
    if (widget.initialUrl != oldWidget.initialUrl) {
      _existingUrl = widget.initialUrl;
    }
  }

  Future<void> _pick(ImageSource source) async {
    try {
      final isDesktopPlatform = kIsWeb || (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux));
      if (source == ImageSource.gallery || isDesktopPlatform) {
        // Use FilePicker to allow images and PDF / document files matching web MultiFileUpload
        final List<PlatformFile> platformFiles;
        if (widget.allowMultiple) {
          platformFiles = await FilePicker.pickFiles(
            type: FileType.custom,
            allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx', 'xlsx', 'xls', 'txt'],
          );
        } else {
          final single = await FilePicker.pickFile(
            type: FileType.custom,
            allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx', 'xlsx', 'xls', 'txt'],
          );
          platformFiles = single != null ? [single] : [];
        }

        if (platformFiles.isNotEmpty) {
          final newXFiles = platformFiles.map((f) => f.xFile).toList();

          if (newXFiles.isNotEmpty) {
            setState(() {
              if (widget.allowMultiple) {
                _files.addAll(newXFiles);
              } else {
                _files = [newXFiles.first];
                _existingUrl = null;
              }
            });
            widget.onFilesChanged(_files);
            return;
          }
        }
        return;
      }

      final picked = await _picker.pickImage(source: source);
      if (picked != null) {
        setState(() {
          if (widget.allowMultiple) {
            _files.add(picked);
          } else {
            _files = [picked];
            _existingUrl = null;
          }
        });
        widget.onFilesChanged(_files);
      }
    } catch (_) {
      try {
        final picked = await _picker.pickImage(source: source);
        if (picked != null) {
          setState(() {
            if (widget.allowMultiple) {
              _files.add(picked);
            } else {
              _files = [picked];
              _existingUrl = null;
            }
          });
          widget.onFilesChanged(_files);
        }
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.isMarathi
                    ? 'फाईल किंवा फोटो निवडताना त्रुटी आली'
                    : 'Failed to pick file or document',
              ),
            ),
          );
        }
      }
    }
  }

  void _removeFile(int index) {
    setState(() {
      _files.removeAt(index);
    });
    widget.onFilesChanged(_files);
  }

  void _removeExistingUrl() {
    setState(() {
      _existingUrl = null;
    });
    widget.onInitialUrlRemoved?.call();
  }

  @override
  Widget build(BuildContext context) {
    final isMr = widget.isMarathi;
    final hasImages = _files.isNotEmpty || (_existingUrl != null && _existingUrl!.isNotEmpty);
    final isDesktopPlatform = kIsWeb || (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux));
    final allowCamera = (widget.enableCamera ?? !isDesktopPlatform) && !isDesktopPlatform;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null && widget.label!.isNotEmpty)
          AppFieldLabel(
            label: widget.label!,
            isRequired: widget.isRequired,
            optionalHint: isMr ? 'ऐच्छिक' : 'Optional',
          ),

        // Attachment Selector: Desktop Dropzone (No Camera on PC) vs Mobile Buttons
        if (!allowCamera)
          Material(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () => _pick(ImageSource.gallery),
              borderRadius: BorderRadius.circular(12),
              hoverColor: const Color(0xFFEFF6FF),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.cloud_upload_outlined,
                        size: 24,
                        color: Color(0xFF0284C7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isMr ? 'अपलोड करण्यासाठी क्लिक करा किंवा निवडा' : 'Click to upload or browse photos / files',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.allowMultiple
                          ? (isMr ? 'एकापेक्षा जास्त फोटो/कागदपत्रे निवडा (कमाल ५०MB)' : 'Select one or more photos or documents (Max 50MB)')
                          : (isMr ? 'फोटो किंवा कागदपत्र निवडा (कमाल ५०MB)' : 'Select photo or document (Max 50MB)'),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          // Mobile: Two side-by-side action buttons: Camera & Phone Storage
          Row(
            children: [
              // 1. Camera Button
              Expanded(
                child: Material(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: () => _pick(ImageSource.camera),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: const BoxDecoration(
                              color: Color(0xFFEFF6FF),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt_outlined,
                              size: 18,
                              color: Color(0xFF0284C7),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  isMr ? 'कॅमेरा' : 'Camera',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E293B),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  isMr ? 'फोटो काढा' : 'Take photo',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF64748B),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // 2. Phone Storage / Gallery Button
              Expanded(
                child: Material(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: () => _pick(ImageSource.gallery),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: const BoxDecoration(
                              color: Color(0xFFECFDF5),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.photo_library_outlined,
                              size: 18,
                              color: Color(0xFF059669),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  isMr ? 'फोन स्टोरेज' : 'Phone Storage',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E293B),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  isMr ? 'गॅलरी निवडा' : 'From gallery',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF64748B),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

        // Previews of selected images
        if (hasImages) ...[
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Existing URL preview
                if (_existingUrl != null && _existingUrl!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: 68,
                            height: 68,
                            color: const Color(0xFFF1F5F9),
                            child: FutureBuilder<String>(
                              future: SupabaseService.instance.getSignedStorageUrl(_existingUrl!, bucket: 'documents'),
                              builder: (context, snap) {
                                final loadUrl = (snap.hasData && snap.data!.isNotEmpty) ? snap.data! : _existingUrl!;
                                return Image.network(
                                  loadUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => const Center(
                                    child: Icon(Icons.broken_image_rounded, size: 24, color: Color(0xFF94A3B8)),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        Positioned(
                          top: -6,
                          right: -6,
                          child: GestureDetector(
                            onTap: _removeExistingUrl,
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                color: Color(0xFFEF4444),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close_rounded, size: 13, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Newly picked local files
                ..._files.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final file = entry.value;
                  final isPdf = file.name.toLowerCase().endsWith('.pdf');

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: 68,
                            height: 68,
                            color: isPdf ? const Color(0xFFFEF2F2) : const Color(0xFFF1F5F9),
                            child: isPdf
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.picture_as_pdf_rounded, size: 24, color: Color(0xFFDC2626)),
                                        const SizedBox(height: 2),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 4),
                                          child: Text(
                                            file.name,
                                            style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Color(0xFF991B1B)),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : kIsWeb
                                    ? Image.network(file.path, fit: BoxFit.cover)
                                    : Image.file(
                                        File(file.path),
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, _, _) => Center(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              const Icon(Icons.insert_drive_file_rounded, size: 22, color: Color(0xFF0284C7)),
                                              Text(
                                                file.name,
                                                style: const TextStyle(fontSize: 8, color: Color(0xFF475569)),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                          ),
                        ),
                        Positioned(
                          top: -6,
                          right: -6,
                          child: GestureDetector(
                            onTap: () => _removeFile(idx),
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                color: Color(0xFFEF4444),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close_rounded, size: 13, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
