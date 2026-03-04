import 'package:flutter/material.dart';
import 'package:absensi/config/app_theme.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppTheme.primaryDark;
    final subtitleColor =
        isDark ? Colors.white.withValues(alpha: 0.5) : Colors.grey[500]!;

    return LayoutBuilder(
      builder: (context, constraints) {
        final mediaQuery = MediaQuery.of(context);
        final isCompact =
            constraints.maxHeight < 700 ||
            mediaQuery.orientation == Orientation.landscape;
        final horizontalPadding = isCompact ? 16.0 : 24.0;
        final topPadding = isCompact ? 16.0 : 24.0;
        final sectionSpacing = isCompact ? 14.0 : 20.0;

        return SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              topPadding,
              horizontalPadding,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Text(
                  'Riwayat',
                  style: TextStyle(
                    fontSize: isCompact ? 22 : 24,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Histori kehadiran dan cuti',
                  style: TextStyle(
                    fontSize: isCompact ? 12 : 13,
                    color: subtitleColor,
                  ),
                ),
                SizedBox(height: sectionSpacing),

                // Tab Bar
                Container(
                  decoration: BoxDecoration(
                    color:
                        isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.grey[100],
                    borderRadius: BorderRadius.circular(isCompact ? 12 : 14),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: isDark ? AppTheme.accent : AppTheme.primaryDark,
                      borderRadius: BorderRadius.circular(isCompact ? 10 : 12),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelColor: Colors.white,
                    unselectedLabelColor:
                        isDark
                            ? Colors.white.withValues(alpha: 0.5)
                            : Colors.grey[500],
                    labelStyle: TextStyle(
                      fontSize: isCompact ? 13 : 14,
                      fontWeight: FontWeight.w600,
                    ),
                    tabs: const [
                      Tab(text: 'Absensi'),
                      Tab(text: 'Cuti / Libur'),
                    ],
                  ),
                ),
                SizedBox(height: sectionSpacing),

                // Tab content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildEmptyState(
                        icon: Icons.history_rounded,
                        title: 'Belum ada data absensi',
                        subtitle: 'Riwayat absensi akan muncul di sini',
                        isDark: isDark,
                        textColor: textColor,
                        subtitleColor: subtitleColor,
                        isCompact: isCompact,
                      ),
                      _buildEmptyState(
                        icon: Icons.event_note_rounded,
                        title: 'Belum ada data cuti',
                        subtitle: 'Riwayat cuti dan libur akan muncul di sini',
                        isDark: isDark,
                        textColor: textColor,
                        subtitleColor: subtitleColor,
                        isCompact: isCompact,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
    required Color textColor,
    required Color subtitleColor,
    required bool isCompact,
  }) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: isCompact ? 68 : 80,
            height: isCompact ? 68 : 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color:
                  isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.grey[100],
            ),
            child: Icon(
              icon,
              size: isCompact ? 30 : 36,
              color:
                  isDark
                      ? Colors.white.withValues(alpha: 0.3)
                      : Colors.grey[400],
            ),
          ),
          SizedBox(height: isCompact ? 12 : 16),
          Text(
            title,
            style: TextStyle(
              fontSize: isCompact ? 15 : 16,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: isCompact ? 12 : 13,
              color: subtitleColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
