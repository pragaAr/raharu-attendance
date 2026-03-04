import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:absensi/config/app_theme.dart';
import 'package:absensi/config/theme_provider.dart';
import 'package:absensi/services/auth_service.dart';
import 'package:absensi/pages/login_page.dart';
import 'package:absensi/utils/string_helper.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _authService = AuthService();
  Map<String, dynamic>? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await _authService.getUser();
    setState(() {
      _user = user;
      _isLoading = false;
    });
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

  String _getUsername() {
    final username = _user?['username'] as String?;
    final upper = StringHelper.upper(username);
    return upper.isEmpty ? '-' : upper;
  }

  String _getJabatan() {
    if (_user == null) return '-';
    final karyawan = _user!['karyawan'];
    if (karyawan != null && karyawan['jabatan'] != null) {
      final formatted = StringHelper.capitalizeWords(
        karyawan['jabatan']['nama'] as String?,
      );
      return formatted.isEmpty ? '-' : formatted;
    }
    return '-';
  }

  String _getDepartemen() {
    if (_user == null) return '-';
    final karyawan = _user!['karyawan'];
    if (karyawan != null && karyawan['departemen'] != null) {
      final formatted = StringHelper.capitalizeWords(
        karyawan['departemen']['nama'] as String?,
      );
      return formatted.isEmpty ? '-' : formatted;
    }
    return '-';
  }

  String _getNik() {
    if (_user == null) return '-';
    final karyawan = _user!['karyawan'];
    final nik = karyawan?['nik'] as String?;
    final upperNik = StringHelper.upper(nik);
    return upperNik.isEmpty ? '-' : upperNik;
  }

  String? _getAvatarUrl() {
    final karyawan = _user?['karyawan'];
    final fotoUrl = karyawan?['img_url']?.toString().trim();
    if (fotoUrl == null || fotoUrl.isEmpty) return null;
    return fotoUrl;
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppTheme.primaryMid : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Konfirmasi',
            style: TextStyle(
              color: isDark ? Colors.white : AppTheme.primaryDark,
            ),
          ),
          content: Text(
            'Apakah Anda yakin ingin keluar?',
            style: TextStyle(
              color:
                  isDark
                      ? Colors.white.withValues(alpha: 0.7)
                      : Colors.grey[600],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                'Batal',
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.grey[600],
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text(
                'Keluar',
                style: TextStyle(color: Color(0xFFEF5350)),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    await _authService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppTheme.primaryDark;
    final subtitleColor =
        isDark ? Colors.white.withValues(alpha: 0.5) : Colors.grey[500]!;
    final cardColor =
        isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey[50]!;
    final borderColor =
        isDark ? Colors.white.withValues(alpha: 0.12) : Colors.grey[200]!;

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
            constraints.maxHeight < 700 ||
            mediaQuery.orientation == Orientation.landscape;
        final horizontalPadding = isCompact ? 16.0 : 24.0;
        final topPadding = isCompact ? 16.0 : 24.0;
        final bottomPadding = isCompact ? 76.0 : 100.0;
        final cardPadding = isCompact ? 16.0 : 20.0;
        final sectionGap = isCompact ? 12.0 : 16.0;

        return SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              topPadding,
              horizontalPadding,
              bottomPadding,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Text(
                  'Profil',
                  style: TextStyle(
                    fontSize: isCompact ? 22 : 24,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                SizedBox(height: isCompact ? 16 : 24),

                // Avatar & Name card
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(cardPadding),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(isCompact ? 16 : 20),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              isDark
                                  ? AppTheme.accent.withValues(alpha: 0.5)
                                  : Colors.grey[200],
                        ),
                        child: GestureDetector(
                          onTap: () {
                            final fotoUrl = _getAvatarUrl();
                            if (fotoUrl == null) return;
                            _showAvatarPreview(fotoUrl, isDark);
                          },
                          child: _buildAvatar(isDark),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _getUserName(),
                        style: TextStyle(
                          fontSize: isCompact ? 17 : 18,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
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
                SizedBox(height: sectionGap),

                // Identity details
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(cardPadding),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(isCompact ? 16 : 20),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Informasi',
                        style: TextStyle(
                          fontSize: isCompact ? 14 : 15,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      SizedBox(height: isCompact ? 12 : 16),
                      _buildInfoRow(
                        Icons.badge_outlined,
                        'NIK',
                        _getNik(),
                        textColor,
                        subtitleColor,
                        isDark,
                      ),
                      _buildDivider(borderColor),
                      _buildInfoRow(
                        Icons.person_outline_rounded,
                        'Username',
                        _getUsername(),
                        textColor,
                        subtitleColor,
                        isDark,
                      ),
                      _buildDivider(borderColor),
                      _buildInfoRow(
                        Icons.work_outline_rounded,
                        'Jabatan',
                        _getJabatan(),
                        textColor,
                        subtitleColor,
                        isDark,
                      ),
                      _buildDivider(borderColor),
                      _buildInfoRow(
                        Icons.business_outlined,
                        'Departemen',
                        _getDepartemen(),
                        textColor,
                        subtitleColor,
                        isDark,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: sectionGap),

                // Settings
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(cardPadding),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(isCompact ? 16 : 20),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pengaturan',
                        style: TextStyle(
                          fontSize: isCompact ? 14 : 15,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Consumer<ThemeProvider>(
                        builder: (context, themeProvider, _) {
                          return Row(
                            children: [
                              Icon(
                                themeProvider.isDark
                                    ? Icons.dark_mode_rounded
                                    : Icons.light_mode_rounded,
                                color:
                                    isDark
                                        ? Colors.white.withValues(alpha: 0.7)
                                        : Colors.grey[600],
                                size: 22,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Mode Gelap',
                                  style: TextStyle(
                                    fontSize: isCompact ? 13 : 14,
                                    color: textColor,
                                  ),
                                ),
                              ),
                              Switch(
                                value: themeProvider.isDark,
                                onChanged: (_) => themeProvider.toggleTheme(),
                                activeColor: const Color.fromARGB(
                                  255,
                                  141,
                                  141,
                                  218,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      _buildDivider(borderColor),
                      _buildSettingsButton(
                        icon: Icons.lock_outline_rounded,
                        label: 'Ubah Password',
                        isDark: isDark,
                        textColor: textColor,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                'Fitur segera hadir',
                                style: TextStyle(
                                  color: AppTheme.snackTextColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              backgroundColor: AppTheme.snackWarningBg,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        },
                      ),
                      _buildDivider(borderColor),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: _handleLogout,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Keluar',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Icon(Icons.logout_rounded, size: 18),
                            ],
                          ),
                        ),
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

  Widget _buildAvatar(bool isDark) {
    final fotoUrl = _getAvatarUrl();

    return CircleAvatar(
      radius: 36,
      backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
      backgroundImage:
          (fotoUrl != null && fotoUrl.isNotEmpty)
              ? NetworkImage(fotoUrl)
              : null,
      child:
          (fotoUrl == null || fotoUrl.isEmpty)
              ? Icon(
                Icons.person_rounded,
                size: 36,
                color: isDark ? Colors.white70 : Colors.grey[500],
              )
              : null,
    );
  }

  void _showAvatarPreview(String fotoUrl, bool isDark) {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.primaryMid : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: InteractiveViewer(
                    minScale: 1,
                    maxScale: 4,
                    child: Image.network(
                      fotoUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) {
                        return SizedBox(
                          height: 220,
                          child: Center(
                            child: Icon(
                              Icons.broken_image_outlined,
                              color: isDark ? Colors.white70 : Colors.grey[600],
                              size: 42,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              Positioned(
                right: -8,
                top: -8,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Navigator.pop(ctx),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value,
    Color textColor,
    Color subtitleColor,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color:
                isDark ? Colors.white.withValues(alpha: 0.5) : Colors.grey[500],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 11, color: subtitleColor),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(Color color) {
    return Divider(color: color, height: 1);
  }

  Widget _buildSettingsButton({
    required IconData icon,
    required String label,
    required bool isDark,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color:
                  isDark
                      ? Colors.white.withValues(alpha: 0.7)
                      : Colors.grey[600],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontSize: 14, color: textColor),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color:
                  isDark
                      ? Colors.white.withValues(alpha: 0.3)
                      : Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }
}
