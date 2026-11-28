import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/localization/app_translations.dart';
import '../../../core/services/translation_service.dart';
import '../../providers/language_provider.dart';

class ModuleDetailItem {
  final String title;
  final String subtitle;
  final String status;
  final Color statusColor;
  final String meta;
  final IconData icon;
  final String? actionLabel;

  const ModuleDetailItem({
    required this.title,
    required this.subtitle,
    required this.status,
    required this.statusColor,
    required this.meta,
    required this.icon,
    this.actionLabel,
  });
}

class ModuleDetailScreen extends StatefulWidget {
  final String title;
  final String subtitle;
  final String category;
  final IconData icon;
  final String description;
  final List<String> highlights;

  const ModuleDetailScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.icon,
    required this.description,
    required this.highlights,
  });

  @override
  State<ModuleDetailScreen> createState() => _ModuleDetailScreenState();
}

class _ModuleDetailScreenState extends State<ModuleDetailScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ModuleDetailItem> _getMockRecords() => const [];

  @override
  Widget build(BuildContext context) {
    final records = _getMockRecords();
    final query = AppTranslations.normalizeAsciiDigits(_searchController.text.trim()).toLowerCase();
    final filtered = records.where((r) {
      if (query.isEmpty) return true;
      return r.title.toLowerCase().contains(query) ||
          r.subtitle.toLowerCase().contains(query) ||
          r.meta.toLowerCase().contains(query);
    }).toList();

    return ValueListenableBuilder<String>(
      valueListenable: appLanguageValueNotifier,
      builder: (context, lang, _) {
        final displayTitle = AppTranslations.translateDirect(widget.title, lang: lang);
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
              scrolledUnderElevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
                onPressed: () => Navigator.pop(context),
              ),
              titleSpacing: 0,
              title: AppTranslatedText(
                widget.title,
                targetLanguage: lang,
                style: const TextStyle(
                  fontSize: 18.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.2,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.share_outlined, color: Colors.white, size: 21),
                  tooltip: AppTranslations.pick(lang, en: 'Share Report', mr: 'अहवाल शेअर करा', hi: 'रिपोर्ट साझा करें'),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: AppTranslatedText(
                          AppTranslations.pick(
                            lang,
                            en: 'Exporting ${widget.title} summary...',
                            mr: '$displayTitle सारांश निर्यात करत आहे...',
                            hi: '$displayTitle सारांश निर्यात किया जा रहा है...',
                          ),
                          targetLanguage: lang,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.tune_rounded, color: Colors.white, size: 21),
                  tooltip: AppTranslations.pick(lang, en: 'Filters', mr: 'फिल्टर', hi: 'फ़िल्टर'),
                  onPressed: () {},
                ),
                const SizedBox(width: 4),
              ],
            ),
            body: Column(
              children: [
                // Top Highlights Banner
                Container(
                  width: double.infinity,
                  color: const Color(0xFF0284C7),
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(widget.icon, color: Colors.white, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppTranslatedText(
                                    widget.category.toUpperCase(),
                                    targetLanguage: lang,
                                    style: const TextStyle(
                                      color: Color(0xFFBAE6FD),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  AppTranslatedText(
                                    widget.subtitle,
                                    targetLanguage: lang,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w500,
                                      height: 1.25,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: widget.highlights.map((h) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.check_circle_rounded, color: Color(0xFF34D399), size: 13),
                                  const SizedBox(width: 5),
                                  AppTranslatedText(
                                    h,
                                    targetLanguage: lang,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),

                // Search & Filter Bar
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: Color(0xFF94A3B8), size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: (v) => setState(() {}),
                            style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
                            decoration: InputDecoration(
                              hintText: AppTranslations.pick(
                                lang,
                                en: 'Search ${widget.title.toLowerCase()} records...',
                                mr: '$displayTitle नोंदी शोधा...',
                                hi: '$displayTitle रिकॉर्ड खोजें...',
                              ),
                              hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13.5),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                          ),
                        ),
                        if (_searchController.text.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              setState(() {});
                            },
                            child: const Icon(Icons.cancel, color: Color(0xFF94A3B8), size: 18),
                          ),
                      ],
                    ),
                  ),
                ),

                const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),

                // Records List
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(widget.icon, size: 54, color: Colors.grey.shade400),
                              const SizedBox(height: 12),
                              Text(
                                AppTranslations.pick(
                                  lang,
                                  en: 'No records found',
                                  mr: 'कोणत्याही नोंदी आढळल्या नाहीत',
                                  hi: 'कोई रिकॉर्ड नहीं मिला',
                                ),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final item = filtered[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x06000000),
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
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
                                        width: 38,
                                        height: 38,
                                        decoration: BoxDecoration(
                                          color: item.statusColor.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Center(
                                          child: Icon(item.icon, color: item.statusColor, size: 20),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            AppTranslatedText(
                                              item.title,
                                              targetLanguage: lang,
                                              style: const TextStyle(
                                                fontSize: 14.5,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF0F172A),
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            AppTranslatedText(
                                              item.subtitle,
                                              targetLanguage: lang,
                                              style: const TextStyle(
                                                fontSize: 12.5,
                                                color: Color(0xFF64748B),
                                                height: 1.3,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: item.statusColor.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: AppTranslatedText(
                                          AppTranslations.getStatus(item.status, lang),
                                          targetLanguage: lang,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: item.statusColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: AppTranslatedText(
                                          item.meta,
                                          targetLanguage: lang,
                                          style: const TextStyle(
                                            fontSize: 11.5,
                                            color: Color(0xFF94A3B8),
                                            fontWeight: FontWeight.w500,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (item.actionLabel != null)
                                        TextButton(
                                          onPressed: () {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: AppTranslatedText(
                                                  '${item.actionLabel}: ${item.title}',
                                                  targetLanguage: lang,
                                                  style: const TextStyle(color: Colors.white),
                                                ),
                                                backgroundColor: const Color(0xFF0284C7),
                                              ),
                                            );
                                          },
                                          style: TextButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            minimumSize: Size.zero,
                                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              AppTranslatedText(
                                                item.actionLabel!,
                                                targetLanguage: lang,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700,
                                                  color: Color(0xFF0284C7),
                                                ),
                                              ),
                                              const SizedBox(width: 2),
                                              const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Color(0xFF0284C7)),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
            floatingActionButton: FloatingActionButton.extended(
              backgroundColor: const Color(0xFF0284C7),
              foregroundColor: Colors.white,
              elevation: 3,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: AppTranslatedText(
                      AppTranslations.pick(
                        lang,
                        en: 'Opening new entry form for ${widget.title}...',
                        mr: '$displayTitle साठी नवीन नोंद फॉर्म उघडत आहे...',
                        hi: '$displayTitle के लिए नया प्रविष्टि फॉर्म खुल रहा है...',
                      ),
                      targetLanguage: lang,
                      style: const TextStyle(color: Colors.white),
                    ),
                    backgroundColor: const Color(0xFF0284C7),
                  ),
                );
              },
              icon: const Icon(Icons.add_rounded, size: 20),
              label: Text(
                AppTranslations.pick(
                  lang,
                  en: 'New ${widget.title.split(' ').first} Entry',
                  mr: 'नवीन नोंद',
                  hi: 'नई प्रविष्टि',
                ),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        );
      },
    );
  }
}
