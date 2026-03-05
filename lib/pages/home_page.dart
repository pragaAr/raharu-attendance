import 'dart:async';
import 'package:flutter/material.dart';
import 'package:absensi/config/app_theme.dart';
import 'package:absensi/services/auth_service.dart';
import 'package:absensi/services/absensi_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:absensi/utils/string_helper.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  static const Duration _rippleDuration = Duration(milliseconds: 3200);
  static const Duration _rippleDelay = Duration(milliseconds: 1000);
  static const double _rippleOuterSize = 108;
  static const double _rippleInnerSize = 104;
  static const double _rippleOuterScaleDelta = 0.5;
  static const double _rippleInnerScaleDelta = 0.2;
  static const double _rippleOuterDarkStartAlpha = 0.55;
  static const double _rippleOuterLightStartAlpha = 0.24;
  static const double _rippleInnerDarkStartAlpha = 0.72;
  static const double _rippleInnerLightStartAlpha = 0.30;
  static const double _rippleOuterDarkStroke = 2.4;
  static const double _rippleOuterLightStroke = 1.8;
  static const double _rippleInnerDarkStroke = 3.2;
  static const double _rippleInnerLightStroke = 2.4;

  final _authService = AuthService();
  final _absensiService = AbsensiService();
  Map<String, dynamic>? _user;
  bool _isLoading = true;
  bool _isSyncingStatus = false;
  String _jamMasuk = '--:--';
  String _jamPulang = '--:--';
  bool _bisaClock = true;
  int _cooldownSisaMenit = 0;

  late Timer _clockTimer;
  DateTime _now = DateTime.now();

  late AnimationController _rippleController;
  Timer? _rippleDelayTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadInitialData();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _now = DateTime.now());
    });

    _rippleController = AnimationController(
      vsync: this,
      duration: _rippleDuration,
    );

    _rippleController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _rippleDelayTimer?.cancel();
        _rippleDelayTimer = Timer(_rippleDelay, () {
          if (!mounted) return;
          _rippleController.forward(from: 0);
        });
      }
    });

    _rippleController.forward();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _clockTimer.cancel();
    _rippleDelayTimer?.cancel();
    _rippleController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncTodayStatus(showErrorSnackBar: false);
    }
  }

  Future<void> _loadInitialData() async {
    final user = await _authService.getUser();
    if (!mounted) return;
    setState(() {
      _user = user;
    });

    await _syncTodayStatus(showErrorSnackBar: false);
    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  Future<void> _syncTodayStatus({required bool showErrorSnackBar}) async {
    if (_isSyncingStatus) return;
    if (mounted) {
      setState(() => _isSyncingStatus = true);
    }

    final result = await _absensiService.getTodayStatus();
    if (!mounted) return;

    setState(() {
      if (result.success && result.data != null) {
        _jamMasuk = result.data!.jamMasuk ?? '--:--';
        _jamPulang = result.data!.jamPulang ?? '--:--';
        _bisaClock = result.data!.bisaClock;
        _cooldownSisaMenit = result.data!.cooldownSisaMenit;
      }
      _isSyncingStatus = false;
    });

    if (!result.success && showErrorSnackBar) {
      _showStatusSnackBar(
        message: result.message,
        backgroundColor: AppTheme.snackErrorBg,
      );
    }
  }

  String _getUserName() {
    if (_user == null) return 'User';
    final karyawan = _user!['karyawan'];
    if (karyawan != null && karyawan['nama'] != null) {
      final formatted = StringHelper.capitalizeWords(
        karyawan['nama'] as String?,
      );
      return formatted.isEmpty ? 'User' : formatted;
    }
    final formatted = StringHelper.capitalizeWords(
      (_user!['name'] ?? _user!['username']) as String?,
    );
    return formatted.isEmpty ? 'User' : formatted;
  }

  String _getJabatan() {
    if (_user == null) return '';
    final karyawan = _user!['karyawan'];
    if (karyawan != null && karyawan['jabatan'] != null) {
      final formatted = StringHelper.capitalizeWords(
        karyawan['jabatan']['nama'] as String?,
      );
      return formatted.isEmpty ? '' : formatted;
    }
    return '';
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime dt) {
    const hari = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    const bulan = [
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

    final namaHari = hari[dt.weekday - 1];
    final namaBulan = bulan[dt.month - 1];
    final tanggal = dt.day.toString().padLeft(2, '0');
    return '$namaHari, $tanggal $namaBulan ${dt.year}';
  }

  void _showStatusSnackBar({
    required String message,
    required Color backgroundColor,
    Duration duration = const Duration(seconds: 3),
  }) {
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
        duration: duration,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _handleAbsen() async {
    if (!_bisaClock) {
      final message =
          _cooldownSisaMenit > 0
              ? 'Belum bisa absen pulang. Tunggu $_cooldownSisaMenit menit lagi.'
              : 'Absensi hari ini sudah lengkap.';
      _showStatusSnackBar(
        message: message,
        backgroundColor: AppTheme.snackWarningBg,
      );
      return;
    }

    // 1. Check Location Permission
    var locationStatus = await Permission.location.request();
    if (!locationStatus.isGranted) {
      _showStatusSnackBar(
        message: 'Izin lokasi dibutuhkan untuk absen',
        backgroundColor: AppTheme.snackWarningBg,
      );
      return;
    }

    if (!mounted) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // 2. Get Current Location
      Position currentPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
        ),
      );

      if (currentPosition.isMocked) {
        if (!mounted) return;
        Navigator.pop(context); // close loading
        _showStatusSnackBar(
          message:
              'Lokasi terdeteksi dari mock/fake GPS. Nonaktifkan fake location lalu coba lagi.',
          backgroundColor: AppTheme.snackErrorBg,
          duration: const Duration(seconds: 4),
        );
        return;
      }

      // 3. Get expected coordinates from user data
      final lokasi = _user?['karyawan']?['lokasi'];

      if (lokasi == null || lokasi['lat'] == null || lokasi['lng'] == null) {
        if (!mounted) return;
        Navigator.pop(context); // close loading
        _showStatusSnackBar(
          message: 'Data koordinat lokasi kerja tidak ditemukan',
          backgroundColor: AppTheme.snackErrorBg,
        );
        return;
      }

      final double targetLat =
          double.tryParse(lokasi?['lat']?.toString() ?? '') ?? 0.0;
      final double targetLng =
          double.tryParse(lokasi?['lng']?.toString() ?? '') ?? 0.0;

      // 4. Calculate Distance
      final double distanceInMeters = Geolocator.distanceBetween(
        currentPosition.latitude,
        currentPosition.longitude,
        targetLat,
        targetLng,
      );

      // Max radius 20 meters
      if (distanceInMeters > 20) {
        if (!mounted) return;
        Navigator.pop(context); // close loading

        _showStatusSnackBar(
          message:
              'Anda berada di luar jangkauan area kerja. Jarak Anda: ${distanceInMeters.toStringAsFixed(1)}m dari titik pusat.',
          backgroundColor: AppTheme.snackErrorBg,
          duration: const Duration(seconds: 4),
        );
        return;
      }

      // 5. Send to API if within radius
      final result = await _absensiService.submitAbsen(
        lat: currentPosition.latitude,
        lng: currentPosition.longitude,
        accuracy: currentPosition.accuracy,
        isMocked: currentPosition.isMocked,
      );

      if (!mounted) return;
      Navigator.pop(context); // close loading

      // Show result message
      _showStatusSnackBar(
        message: result.message,
        backgroundColor:
            result.success ? AppTheme.snackSuccessBg : AppTheme.snackErrorBg,
      );
      if (result.success) {
        await _syncTodayStatus(showErrorSnackBar: false);
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // close loading
      _showStatusSnackBar(
        message: 'Gagal akses lokasi, pastikan GPS aktif dan coba lagi.',
        backgroundColor: AppTheme.snackErrorBg,
      );
    }
  }

  Widget _buildRippleEffect(bool isDark) {
    return AnimatedBuilder(
      animation: _rippleController,
      builder: (context, child) {
        final progress = _rippleController.value;
        final rippleBaseColor = isDark ? Colors.white : AppTheme.primaryDark;
        final outerStartAlpha =
            isDark ? _rippleOuterDarkStartAlpha : _rippleOuterLightStartAlpha;
        final innerStartAlpha =
            isDark ? _rippleInnerDarkStartAlpha : _rippleInnerLightStartAlpha;
        final double outerAlpha =
            (outerStartAlpha * (1 - progress)).clamp(0.0, 1.0).toDouble();
        final double innerAlpha =
            (innerStartAlpha * (1 - progress)).clamp(0.0, 1.0).toDouble();

        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer ripple
            Transform.scale(
              scale: 1.0 + (progress * _rippleOuterScaleDelta),
              child: Container(
                width: _rippleOuterSize,
                height: _rippleOuterSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: rippleBaseColor.withValues(alpha: outerAlpha),
                    width:
                        isDark
                            ? _rippleOuterDarkStroke
                            : _rippleOuterLightStroke,
                  ),
                ),
              ),
            ),
            // Inner ripple
            Transform.scale(
              scale: 1.0 + (progress * _rippleInnerScaleDelta),
              child: Container(
                width: _rippleInnerSize,
                height: _rippleInnerSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: rippleBaseColor.withValues(alpha: innerAlpha),
                    width:
                        isDark
                            ? _rippleInnerDarkStroke
                            : _rippleInnerLightStroke,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppTheme.primaryDark;
    final subtitleColor =
        isDark ? Colors.white.withValues(alpha: 0.6) : Colors.grey[500]!;

    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: isDark ? Colors.white : AppTheme.accent,
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final mediaQuery = MediaQuery.of(context);
        final isCompact =
            constraints.maxHeight < 760 ||
            mediaQuery.orientation == Orientation.landscape;
        final horizontalPadding = isCompact ? 16.0 : 24.0;
        final topPadding = isCompact ? 16.0 : 24.0;
        final clockFontSize = isCompact ? 42.0 : 56.0;
        final indicatorFontSize = isCompact ? 17.0 : 20.0;
        final indicatorLabelSize = isCompact ? 12.0 : 13.0;
        final buttonSize = isCompact ? 84.0 : 100.0;
        final buttonIconSize = isCompact ? 40.0 : 48.0;
        final buttonGap = isCompact ? 10.0 : 14.0;
        final bottomSpacing = isCompact ? 18.0 : 80.0;
        final sectionSpacing = isCompact ? 14.0 : 0.0;
        final rippleScale = isCompact ? 0.8 : 1.0;

        final headerSection = Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Halo, ${_getUserName()}',
                    style: TextStyle(
                      fontSize: isCompact ? 18 : 20,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (_getJabatan().isNotEmpty)
                    Text(
                      _getJabatan(),
                      style: TextStyle(
                        fontSize: isCompact ? 12 : 13,
                        color: subtitleColor,
                      ),
                    ),
                ],
              ),
            ),
          ],
        );

        final clockSection = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                _formatTime(_now),
                style: TextStyle(
                  fontSize: clockFontSize,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                  letterSpacing: isCompact ? 1.2 : 2,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _formatDate(_now),
              style: TextStyle(
                fontSize: isCompact ? 12 : 13,
                color: subtitleColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );

        final absenSection = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Transform.scale(
                  scale: rippleScale,
                  child: _buildRippleEffect(isDark),
                ),
                GestureDetector(
                  onTap: _handleAbsen,
                  child: Container(
                    width: buttonSize,
                    height: buttonSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark ? AppTheme.secondaryDeep : Colors.white,
                      border: Border.all(
                        color:
                            isDark
                                ? Colors.white.withValues(alpha: 0.2)
                                : AppTheme.primaryDark.withValues(alpha: 0.15),
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                              isDark
                                  ? AppTheme.secondaryDeep.withValues(alpha: 0.4)
                                  : Colors.grey.withValues(alpha: 0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.fingerprint_rounded,
                      size: buttonIconSize,
                      color: isDark ? Colors.white : AppTheme.secondaryDeep,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: buttonGap),
            Text(
              'Absen',
              style: TextStyle(
                fontSize: isCompact ? 14 : 16,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        );

        final infoSection = Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _jamMasuk,
                    style: TextStyle(
                      fontSize: indicatorFontSize,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Jam Masuk',
                    style: TextStyle(
                      fontSize: indicatorLabelSize,
                      color: subtitleColor,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _jamPulang,
                    style: TextStyle(
                      fontSize: indicatorFontSize,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Jam Pulang',
                    style: TextStyle(
                      fontSize: indicatorLabelSize,
                      color: subtitleColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

        if (isCompact) {
          final bottomPadding = 84.0 + mediaQuery.padding.bottom;
          return SafeArea(
            bottom: false,
            child: RefreshIndicator(
              onRefresh: () => _syncTodayStatus(showErrorSnackBar: true),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  topPadding,
                  horizontalPadding,
                  bottomPadding,
                ),
                child: Column(
                  children: [
                    headerSection,
                    const SizedBox(height: 24),
                    clockSection,
                    const SizedBox(height: 28),
                    absenSection,
                    const SizedBox(height: 28),
                    infoSection,
                  ],
                ),
              ),
            ),
          );
        }

        return SafeArea(
          bottom: false,
          child: RefreshIndicator(
            onRefresh: () => _syncTodayStatus(showErrorSnackBar: true),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              children: [
                SizedBox(
                  height: constraints.maxHeight,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      topPadding,
                      horizontalPadding,
                      0,
                    ),
                    child: Column(
                      children: [
                        // --- Header ---
                        headerSection,
                        SizedBox(height: sectionSpacing),

                        // --- Live Clock ---
                        Expanded(flex: 3, child: Center(child: clockSection)),
                        SizedBox(height: sectionSpacing),

                        // --- Fingerprint Absen Button ---
                        Expanded(flex: 3, child: Center(child: absenSection)),
                        SizedBox(height: sectionSpacing),

                        // --- Jam Masuk / Jam Pulang ---
                        Expanded(flex: 2, child: Center(child: infoSection)),

                        // Bottom spacing for navbar
                        SizedBox(height: bottomSpacing),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
