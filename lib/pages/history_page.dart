import 'package:flutter/material.dart';
import 'package:absensi/config/app_theme.dart';
import 'package:absensi/services/absensi_service.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _absensiService = AbsensiService();

  bool _isLoadingHistory = true;
  bool _historyFromCache = false;
  String? _historyError;
  DateTime? _historyFetchedAt;
  List<AbsensiHistoryDay> _historyItems = const [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadHistory(forceRefresh: true);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory({bool forceRefresh = false}) async {
    if (!forceRefresh && _historyItems.isEmpty) {
      setState(() => _isLoadingHistory = true);
    }

    final result = await _absensiService.getHistory(
      perPage: 60,
      forceRefresh: forceRefresh,
    );

    if (!mounted) return;
    setState(() {
      if (result.success) {
        _historyItems = result.data;
        _historyFromCache = result.fromCache;
        _historyFetchedAt = result.fetchedAt;
        _historyError = null;
      } else {
        _historyError = result.message;
      }
      _isLoadingHistory = false;
    });

    if (forceRefresh && !result.success) {
      _showSnackBar(result.message, AppTheme.snackErrorBg);
    }
  }

  void _showSnackBar(String message, Color backgroundColor) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: AppTheme.snackTextColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatDate(String rawDate) {
    final date = DateTime.tryParse(rawDate);
    if (date == null) return rawDate;

    const weekdays = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];

    final weekday = weekdays[date.weekday - 1];
    final month = months[date.month - 1];
    return '$weekday, ${date.day} $month ${date.year}';
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '--:--';
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Color _statusColor(String status, bool isDark) {
    switch (status.toLowerCase()) {
      case 'hadir':
        return isDark ? Colors.greenAccent.shade100 : Colors.green.shade600;
      case 'izin':
      case 'cuti':
        return isDark ? Colors.orangeAccent.shade100 : Colors.orange.shade700;
      case 'sakit':
        return isDark ? Colors.blueAccent.shade100 : Colors.blue.shade700;
      default:
        return isDark ? Colors.redAccent.shade100 : Colors.red.shade700;
    }
  }

  IconData _jenisIcon(String jenis) {
    switch (jenis.toLowerCase()) {
      case 'masuk':
        return Icons.login_rounded;
      case 'pulang':
        return Icons.logout_rounded;
      case 'izin':
        return Icons.assignment_turned_in_rounded;
      case 'sakit':
        return Icons.local_hospital_rounded;
      case 'cuti':
        return Icons.beach_access_rounded;
      default:
        return Icons.error_outline_rounded;
    }
  }

  String _jenisLabel(String jenis) {
    final value = jenis.toLowerCase();
    if (value.isEmpty) return 'Tidak diketahui';
    return '${value[0].toUpperCase()}${value.substring(1)}';
  }

  List<AbsensiHistoryLog> _fallbackLogsFromDay(AbsensiHistoryDay day) {
    final logs = <AbsensiHistoryLog>[];
    if (day.jamMasuk != null && day.jamMasuk!.isNotEmpty) {
      logs.add(
        AbsensiHistoryLog(
          jenis: 'masuk',
          jam: day.jamMasuk,
          source: null,
          keterangan: null,
        ),
      );
    }
    if (day.jamPulang != null && day.jamPulang!.isNotEmpty) {
      logs.add(
        AbsensiHistoryLog(
          jenis: 'pulang',
          jam: day.jamPulang,
          source: null,
          keterangan: null,
        ),
      );
    }
    if (logs.isEmpty && day.status.isNotEmpty) {
      logs.add(
        AbsensiHistoryLog(
          jenis: day.status,
          jam: null,
          source: null,
          keterangan: null,
        ),
      );
    }
    return logs;
  }

  Widget _buildHistoryTimeline({
    required bool isDark,
    required bool isCompact,
    required Color textColor,
    required Color subtitleColor,
  }) {
    if (_isLoadingHistory && _historyItems.isEmpty) {
      return Center(
        child: CircularProgressIndicator(
          color: isDark ? Colors.white : AppTheme.accent,
        ),
      );
    }

    if (_historyError != null && _historyItems.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.wifi_off_rounded,
                size: 42,
                color:
                    isDark
                        ? Colors.white.withValues(alpha: 0.6)
                        : Colors.grey[500],
              ),
              const SizedBox(height: 12),
              Text(
                _historyError!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textColor,
                  fontSize: isCompact ? 13 : 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: _loadHistory,
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    if (_historyItems.isEmpty) {
      return _buildEmptyState(
        icon: Icons.history_rounded,
        title: 'Belum ada data absensi',
        subtitle: 'Riwayat absensi akan muncul di sini',
        isDark: isDark,
        textColor: textColor,
        subtitleColor: subtitleColor,
        isCompact: isCompact,
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadHistory(forceRefresh: true),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(2, 0, 2, isCompact ? 100 : 120),
        itemCount: _historyItems.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            final syncText =
                _historyFetchedAt == null
                    ? 'Sinkronisasi belum tersedia'
                    : (_historyFromCache
                        ? 'Menampilkan cache lokal • ${_formatTime(_historyFetchedAt)}'
                        : 'Sinkron server • ${_formatTime(_historyFetchedAt)}');

            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Text(
                syncText,
                style: TextStyle(
                  fontSize: isCompact ? 11 : 12,
                  color:
                      _historyFromCache
                          ? (isDark
                              ? Colors.orangeAccent.shade100
                              : Colors.orange.shade700)
                          : subtitleColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }

          final day = _historyItems[index - 1];
          final isLast = index == _historyItems.length;
          final statusColor = _statusColor(day.status, isDark);
          final logs = day.logs.isEmpty ? _fallbackLogsFromDay(day) : day.logs;

          return Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 24,
                    child: Column(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          margin: const EdgeInsets.only(top: 14),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: statusColor,
                          ),
                        ),
                        if (!isLast)
                          Expanded(
                            child: Container(
                              width: 2,
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              color:
                                  isDark
                                      ? Colors.white.withValues(alpha: 0.18)
                                      : Colors.grey[300],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.all(isCompact ? 12 : 14),
                      decoration: BoxDecoration(
                        color:
                            isDark
                                ? Colors.white.withValues(alpha: 0.07)
                                : Colors.grey[50],
                        borderRadius: BorderRadius.circular(
                          isCompact ? 12 : 14,
                        ),
                        border: Border.all(
                          color:
                              isDark
                                  ? Colors.white.withValues(alpha: 0.12)
                                  : Colors.grey[200]!,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _formatDate(day.tanggal),
                                  style: TextStyle(
                                    fontSize: isCompact ? 13 : 14,
                                    fontWeight: FontWeight.w700,
                                    color: textColor,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  _jenisLabel(day.status),
                                  style: TextStyle(
                                    fontSize: isCompact ? 10 : 11,
                                    color: statusColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ...logs.map(
                            (log) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    _jenisIcon(log.jenis),
                                    size: isCompact ? 16 : 18,
                                    color: subtitleColor,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${_jenisLabel(log.jenis)}'
                                          '${(log.jam ?? '').isNotEmpty ? ' • ${log.jam}' : ''}',
                                          style: TextStyle(
                                            fontSize: isCompact ? 12 : 13,
                                            fontWeight: FontWeight.w600,
                                            color: textColor,
                                          ),
                                        ),
                                        if ((log.keterangan ?? '').isNotEmpty)
                                          Text(
                                            log.keterangan!,
                                            style: TextStyle(
                                              fontSize: isCompact ? 11 : 12,
                                              color: subtitleColor,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
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
          );
        },
      ),
    );
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
                  'Timeline harian absensi dan cuti',
                  style: TextStyle(
                    fontSize: isCompact ? 12 : 13,
                    color: subtitleColor,
                  ),
                ),
                SizedBox(height: sectionSpacing),

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
                      color:
                          isDark
                              ? AppTheme.secondaryDeep
                              : AppTheme.primaryDark,
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

                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildHistoryTimeline(
                        isDark: isDark,
                        isCompact: isCompact,
                        textColor: textColor,
                        subtitleColor: subtitleColor,
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
