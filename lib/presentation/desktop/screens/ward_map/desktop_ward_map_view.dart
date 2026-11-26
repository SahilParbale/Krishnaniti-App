import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:nagarsevak_mobile/data/models/ward_map_point_model.dart';
import 'package:nagarsevak_mobile/data/repositories/ward_map_repository.dart';
import 'package:nagarsevak_mobile/presentation/desktop/shell/desktop_sidebar.dart';
import 'package:nagarsevak_mobile/presentation/screens/ward_map/ward_map_report_generator.dart';

/// Desktop Ward Map View matching WardMap.tsx verbatim:
/// - Sticky Header: Title + Subtitle + Help + Tag New Spot
/// - Top Control Toolbar: Category pills + Satellite/Vector toggle + Zoom In/Out/Reset
/// - Full-width Interactive GIS Map Canvas with red official ward boundary polygon (stroke: #FF0000)
/// - Bottom-right Floating Place Detail Card (matching lines 331-390 of WardMap.tsx)
class DesktopWardMapView extends ConsumerStatefulWidget {
  const DesktopWardMapView({super.key});

  @override
  ConsumerState<DesktopWardMapView> createState() => _DesktopWardMapViewState();
}

class _DesktopWardMapViewState extends ConsumerState<DesktopWardMapView> {
  final TransformationController _transformCtrl = TransformationController();
  String _activeCategory = 'All';
  bool _isSatelliteMode = false;
  bool _loading = true;
  List<WardMapPointModel> _allPoints = [];
  WardMapPointModel? _selectedPoint;

  static const List<Map<String, String>> _categories = [
    {'id': 'All', 'en': 'All Places', 'mr': 'All Places'},
    {'id': 'Booth', 'en': 'Polling Booths', 'mr': 'Polling Booths'},
    {'id': 'CivilWorks', 'en': 'Civil Works', 'mr': 'Civil Works'},
    {'id': 'Amenity', 'en': 'Civic Amenities', 'mr': 'Civic Amenities'},
    {'id': 'ProblemSpot', 'en': 'Problem Spots', 'mr': 'Problem Spots'},
    {'id': 'Office', 'en': 'Ward Office', 'mr': 'Ward Office'},
  ];

  @override
  void initState() {
    super.initState();
    _loadPoints();
  }

  @override
  void dispose() {
    _transformCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPoints() async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(wardMapRepoProvider);
      final pts = await repo.getWardPoints();
      if (mounted) {
        setState(() {
          _allPoints = pts;
          _loading = false;
          if (_allPoints.isNotEmpty) {
            _selectedPoint = _allPoints.first;
          }
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<WardMapPointModel> get _filteredPoints {
    if (_activeCategory == 'All') return _allPoints;
    return _allPoints.where((p) => p.category.toLowerCase() == _activeCategory.toLowerCase()).toList();
  }

  void _zoomIn() {
    final matrix = _transformCtrl.value.clone();
    matrix.scale(1.25);
    _transformCtrl.value = matrix;
  }

  void _zoomOut() {
    final matrix = _transformCtrl.value.clone();
    matrix.scale(0.80);
    _transformCtrl.value = matrix;
  }

  void _resetZoom() {
    _transformCtrl.value = Matrix4.identity();
  }

  Future<void> _openDirections(WardMapPointModel point) async {
    final uri = Uri.parse(point.googleMapsUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _copyAddress(WardMapPointModel point) {
    Clipboard.setData(ClipboardData(text: '${point.title}\n${point.address}'));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Address copied to clipboard!'), duration: Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(desktopLanguageProvider);
    final isMr = lang == 'mr';
    final items = _filteredPoints;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header (matching WardMap.tsx lines 200-225)
            _buildHeader(isMr),

            const SizedBox(height: 16),

            // 2. Control Toolbar: Category pills + Map controls
            _buildControlBar(isMr),

            const SizedBox(height: 16),

            // 3. Map Viewport with Red Boundary Polygon & Floating Card
            _buildMapContainer(items, isMr),
          ],
        ),
      ),
    );
  }

  // --- Header ---
  Widget _buildHeader(bool isMr) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.map_outlined, size: 26, color: Color(0xFF0369A1)),
                const SizedBox(width: 10),
                Text(
                  'Ward Map',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFF0F172A), letterSpacing: -0.5),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              isMr
                  ? 'Official ward boundary, polling booths and civic infrastructure map'
                  : 'Interactive ward boundary, polling booths and civic landmarks',
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
          ],
        ),

        // Download Report matching WardMap.tsx
        OutlinedButton.icon(
          onPressed: () {
            WardMapReportGenerator.generateAndPrintWardMapReport(
              context: context,
              points: _allPoints,
              categoryFilter: _activeCategory,
            );
          },
          icon: const Icon(Icons.download_rounded, size: 16, color: Color(0xFF0284C7)),
          label: const Text('Download Report', style: TextStyle(color: Color(0xFF0284C7), fontWeight: FontWeight.w600, fontSize: 14)),
          style: OutlinedButton.styleFrom(
            backgroundColor: const Color(0xFFF0F9FF),
            side: const BorderSide(color: Color(0xFFBAE6FD)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  // --- Control Bar ---
  Widget _buildControlBar(bool isMr) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Category Pills
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _categories.map((c) {
              final isSel = _activeCategory == c['id'];
              final label = isMr ? c['mr']! : c['en']!;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  onTap: () => setState(() => _activeCategory = c['id']!),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSel ? const Color(0xFF0284C7) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isSel ? const Color(0xFF0284C7) : const Color(0xFFE2E8F0)),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                        color: isSel ? Colors.white : const Color(0xFF475569),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        // Controls: Satellite Toggle + Zoom controls
        Row(
          children: [
            InkWell(
              onTap: () => setState(() => _isSatelliteMode = !_isSatelliteMode),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _isSatelliteMode ? const Color(0xFF0284C7) : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.layers_outlined, size: 16, color: _isSatelliteMode ? Colors.white : const Color(0xFF475569)),
                    const SizedBox(width: 6),
                    Text(
                      _isSatelliteMode ? 'Satellite' : 'Roadmap',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _isSatelliteMode ? Colors.white : const Color(0xFF475569)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Zoom buttons
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: Row(
                children: [
                  IconButton(icon: const Icon(Icons.add, size: 16), onPressed: _zoomIn, tooltip: 'Zoom In'),
                  const VerticalDivider(width: 1),
                  IconButton(icon: const Icon(Icons.remove, size: 16), onPressed: _zoomOut, tooltip: 'Zoom Out'),
                  const VerticalDivider(width: 1),
                  IconButton(icon: const Icon(Icons.center_focus_strong_outlined, size: 16), onPressed: _resetZoom, tooltip: 'Reset Center'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- Map Viewport Container ---
  Widget _buildMapContainer(List<WardMapPointModel> items, bool isMr) {
    return Container(
      height: 600,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: _isSatelliteMode ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: Stack(
        children: [
          // Pan & Zoom Interactive Canvas
          Positioned.fill(
            child: InteractiveViewer(
              transformationController: _transformCtrl,
              minScale: 0.6,
              maxScale: 3.5,
              child: SizedBox(
                width: 900,
                height: 600,
                child: Stack(
                  children: [
                    // Base Map Painter with official Red Ward Boundary
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _DesktopWardMapPainter(isSatellite: _isSatelliteMode),
                      ),
                    ),

                    // Point Markers
                    ...items.map((pt) {
                      final isSelected = _selectedPoint?.id == pt.id;
                      return Positioned(
                        left: 900 * pt.relativeX - 16,
                        top: 600 * pt.relativeY - 32,
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedPoint = pt),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFF0284C7) : Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                  boxShadow: [
                                    BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 4),
                                  ],
                                ),
                                child: Text(
                                  pt.title,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: isSelected ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.location_on_rounded,
                                size: 28,
                                color: isSelected ? const Color(0xFF0284C7) : pt.color,
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),

          // Bottom-right Floating Place Detail Card (matching WardMap.tsx lines 331-390)
          if (_selectedPoint != null)
            Positioned(
              right: 20,
              bottom: 20,
              child: Container(
                width: 340,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _selectedPoint!.title,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => setState(() => _selectedPoint = null),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _selectedPoint!.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _selectedPoint!.category,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _selectedPoint!.color),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _selectedPoint!.address,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.35),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _openDirections(_selectedPoint!),
                            icon: const Icon(Icons.navigation_rounded, size: 14),
                            label: const Text('Directions', style: TextStyle(fontSize: 12)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF0284C7),
                              side: const BorderSide(color: Color(0xFFBAE6FD)),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.copy_rounded, size: 18, color: Color(0xFF64748B)),
                          onPressed: () => _copyAddress(_selectedPoint!),
                          tooltip: 'Copy Address',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Vector Painter with official Red Ward Boundary matching WardMap.tsx Polygon
class _DesktopWardMapPainter extends CustomPainter {
  final bool isSatellite;

  _DesktopWardMapPainter({required this.isSatellite});

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..color = isSatellite ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Grid lines
    final gridPaint = Paint()
      ..color = isSatellite ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFE2E8F0)
      ..strokeWidth = 1.0;

    for (double x = 0; x < size.width; x += 50) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 50) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Official Ward Boundary Polygon (Red - matching strokeColor: "#FF0000", fill: 0.1)
    final boundaryPath = Path();
    boundaryPath.moveTo(size.width * 0.20, size.height * 0.20);
    boundaryPath.lineTo(size.width * 0.75, size.height * 0.15);
    boundaryPath.lineTo(size.width * 0.85, size.height * 0.50);
    boundaryPath.lineTo(size.width * 0.80, size.height * 0.80);
    boundaryPath.lineTo(size.width * 0.35, size.height * 0.85);
    boundaryPath.lineTo(size.width * 0.15, size.height * 0.60);
    boundaryPath.close();

    // Fill
    final fillPaint = Paint()
      ..color = const Color(0xFFFF0000).withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;
    canvas.drawPath(boundaryPath, fillPaint);

    // Red Border Stroke (strokeWidth: 3.0)
    final strokePaint = Paint()
      ..color = const Color(0xFFFF0000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawPath(boundaryPath, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _DesktopWardMapPainter oldDelegate) =>
      oldDelegate.isSatellite != isSatellite;
}
