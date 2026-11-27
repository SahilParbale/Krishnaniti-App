import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Desktop Command Palette triggered via Ctrl+K or search bar
class DesktopCommandPalette extends StatefulWidget {
  final Function(String screenKey) onSelectScreen;

  const DesktopCommandPalette({super.key, required this.onSelectScreen});

  static Future<void> show(BuildContext context, Function(String) onSelect) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => DesktopCommandPalette(onSelectScreen: onSelect),
    );
  }

  @override
  State<DesktopCommandPalette> createState() => _DesktopCommandPaletteState();
}

class _CommandItem {
  final String key;
  final String title;
  final String titleMr;
  final String category;
  final IconData icon;

  const _CommandItem({
    required this.key,
    required this.title,
    // ignore: unused_element_parameter
    this.titleMr = '',
    required this.category,
    required this.icon,
  });
}

class _DesktopCommandPaletteState extends State<DesktopCommandPalette> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  int _selectedIndex = 0;

  static const List<_CommandItem> _allItems = [
    // Daily Work
    _CommandItem(key: 'dashboard', title: 'Dashboard', category: 'General', icon: Icons.dashboard_outlined),
    _CommandItem(key: 'complaints', title: 'Complaints', category: 'Daily Work', icon: Icons.report_problem_outlined),
    _CommandItem(key: 'letters', title: 'Letters & Inward/Outward', category: 'Daily Work', icon: Icons.description_outlined),
    _CommandItem(key: 'diary', title: 'Tasks & Diary', category: 'Daily Work', icon: Icons.check_box_outlined),
    _CommandItem(key: 'visitors', title: 'Visitor Log', category: 'Daily Work', icon: Icons.people_outline),
    _CommandItem(key: 'schemes', title: 'Government Schemes', category: 'Daily Work', icon: Icons.menu_book_outlined),

    // Ward Information
    _CommandItem(key: 'ward_problems', title: 'Ward Problems', category: 'Ward Info', icon: Icons.warning_amber_rounded),
    _CommandItem(key: 'ward_map', title: 'Ward GIS Map', category: 'Ward Info', icon: Icons.map_outlined),
    _CommandItem(key: 'work_history', title: 'Work History', category: 'Ward Info', icon: Icons.history_rounded),
    _CommandItem(key: 'improvements', title: 'Possible Improvements', category: 'Ward Info', icon: Icons.trending_up_rounded),
    _CommandItem(key: 'provisions', title: 'Ward Provisions', category: 'Ward Info', icon: Icons.currency_rupee_rounded),

    // Municipal Work
    _CommandItem(key: 'gb_register', title: 'GB Register', category: 'Municipal Work', icon: Icons.book_outlined),
    _CommandItem(key: 'ward_budget', title: 'Ward Budget', category: 'Municipal Work', icon: Icons.account_balance_wallet_outlined),
    _CommandItem(key: 'gov_office', title: 'Government Offices', category: 'Government Office', icon: Icons.account_balance_outlined),

    // Media & Promotion
    _CommandItem(key: 'social_analytics', title: 'Social Media Analytics', category: 'Media & Promotion', icon: Icons.insights_rounded),
    _CommandItem(key: 'newspaper', title: 'Newspaper Clippings', category: 'Media & Promotion', icon: Icons.newspaper_outlined),
    _CommandItem(key: 'media_tracking', title: 'Media Tracking', category: 'Media & Promotion', icon: Icons.public_outlined),
    _CommandItem(key: 'ai_content', title: 'AI Content Studio', category: 'Media & Promotion', icon: Icons.auto_awesome_outlined),

    // Programs & Activities
    _CommandItem(key: 'events', title: 'Events & Programs', category: 'Programs', icon: Icons.event_available_outlined),
    _CommandItem(key: 'gallery', title: 'Photo Gallery', category: 'Programs', icon: Icons.collections_outlined),

    // Political & Electoral
    _CommandItem(key: 'result_analysis', title: 'Election Results Analysis', category: 'Political', icon: Icons.bar_chart_outlined),
    _CommandItem(key: 'sadasya', title: 'Sadasya / Party Cadre', category: 'Political', icon: Icons.group_add_outlined),
    _CommandItem(key: 'surveys', title: 'Sample Surveys', category: 'Political', icon: Icons.poll_outlined),
    _CommandItem(key: 'voters', title: 'Voters Search & List', category: 'Political', icon: Icons.person_search_outlined),
    _CommandItem(key: 'team', title: 'My Team & Staff', category: 'Political', icon: Icons.badge_outlined),
    _CommandItem(key: 'opposition', title: 'Opposition Information', category: 'Political', icon: Icons.visibility_outlined),
    _CommandItem(key: 'ngo_mandals', title: 'NGO & Social Organizations', category: 'Political', icon: Icons.domain_outlined),
    _CommandItem(key: 'housing_societies', title: 'Housing Societies', category: 'Political', icon: Icons.home_work_outlined),
    _CommandItem(key: 'duplicate_voters', title: 'Duplicate Voters Check', category: 'Political', icon: Icons.content_copy_outlined),
    _CommandItem(key: 'voter_forms', title: 'Voter Registration Forms', category: 'Political', icon: Icons.assignment_outlined),
    _CommandItem(key: 'karyakarta_work', title: 'Karyakarta Work Management', category: 'Political', icon: Icons.task_alt_outlined),

    // Public Communication
    _CommandItem(key: 'sms', title: 'Bulk SMS Communication', category: 'Communication', icon: Icons.sms_outlined),
    _CommandItem(key: 'whatsapp_message', title: 'WhatsApp Messages', category: 'Communication', icon: Icons.chat_outlined),
    _CommandItem(key: 'whatsapp_call', title: 'WhatsApp Calling', category: 'Communication', icon: Icons.phone_forwarded_outlined),
    _CommandItem(key: 'voice_call', title: 'Bulk Voice Calls', category: 'Communication', icon: Icons.phone_in_talk_outlined),
    _CommandItem(key: 'ai_voice_call', title: 'AI Voice Calls', category: 'Communication', icon: Icons.support_agent_outlined),
    _CommandItem(key: 'conference_room', title: 'Virtual Conference Room', category: 'Communication', icon: Icons.video_camera_front_outlined),

    // Strategy & Settings
    _CommandItem(key: 'analysis_strategy', title: 'Analysis & Strategy', category: 'Strategy', icon: Icons.query_stats_outlined),
    _CommandItem(key: 'profile_settings', title: 'Profile Settings', category: 'Settings', icon: Icons.manage_accounts_outlined),
    _CommandItem(key: 'whatsapp_bot', title: 'WhatsApp Bot (Baileys)', category: 'Settings', icon: Icons.smart_toy_outlined),
  ];

  List<_CommandItem> _filteredItems = _allItems;

  @override
  void initState() {
    super.initState();
    _filteredItems = _allItems;
    _focusNode.requestFocus();
  }

  void _onQueryChanged(String query) {
    setState(() {
      if (query.trim().isEmpty) {
        _filteredItems = _allItems;
      } else {
        final q = query.toLowerCase();
        _filteredItems = _allItems.where((item) {
          return item.title.toLowerCase().contains(q) ||
              item.titleMr.toLowerCase().contains(q) ||
              item.category.toLowerCase().contains(q);
        }).toList();
      }
      _selectedIndex = 0;
    });
  }

  void _selectCurrent() {
    if (_filteredItems.isNotEmpty && _selectedIndex < _filteredItems.length) {
      final selected = _filteredItems[_selectedIndex];
      Navigator.of(context).pop();
      widget.onSelectScreen(selected.key);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
      child: Center(
        child: Container(
          width: 640,
          constraints: const BoxConstraints(maxHeight: 520),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 36,
                offset: const Offset(0, 14),
              ),
            ],
            border: Border.all(color: AppColors.slate200),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Search Input Box
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.slate200)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded, color: AppColors.brand600, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        focusNode: _focusNode,
                        onChanged: _onQueryChanged,
                        onSubmitted: (_) => _selectCurrent(),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.slate900,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Search modules, voters, letters, complaints... (Type to filter)',
                          hintStyle: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: AppColors.slate400,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.slate100,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.slate300),
                      ),
                      child: const Text(
                        'ESC',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.slate600),
                      ),
                    ),
                  ],
                ),
              ),

              // Filtered list
              Flexible(
                child: _filteredItems.isEmpty
                    ? Container(
                        padding: const EdgeInsets.all(40),
                        child: const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.search_off_rounded, size: 40, color: AppColors.slate300),
                            SizedBox(height: 12),
                            Text(
                              'No matching modules found',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.slate500),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                        shrinkWrap: true,
                        itemCount: _filteredItems.length,
                        itemBuilder: (context, index) {
                          final item = _filteredItems[index];
                          final isSelected = index == _selectedIndex;

                          return InkWell(
                            onTap: () {
                              Navigator.of(context).pop();
                              widget.onSelectScreen(item.key);
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              margin: const EdgeInsets.symmetric(vertical: 2),
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.brand50 : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                border: isSelected ? Border.all(color: AppColors.brand200) : null,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 34,
                                    height: 34,
                                    decoration: BoxDecoration(
                                      color: isSelected ? AppColors.brand600 : AppColors.slate100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      item.icon,
                                      size: 18,
                                      color: isSelected ? Colors.white : AppColors.slate600,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(
                                      item.title,
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                        color: isSelected ? AppColors.brand700 : AppColors.slate900,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.slate100,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      item.category,
                                      style: const TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.slate600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),

              // Footer Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: const BoxDecoration(
                  color: AppColors.slate50,
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
                  border: Border(top: BorderSide(color: AppColors.slate200)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Use Arrow keys to navigate, Enter to select',
                      style: TextStyle(fontSize: 11, color: AppColors.slate500),
                    ),
                    Text(
                      '39 Modules Integrated',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.brand600),
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
}
