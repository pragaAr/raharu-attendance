import 'package:flutter/material.dart';
import 'package:absensi/config/app_theme.dart';
import 'package:absensi/pages/home_page.dart';
import 'package:absensi/pages/history_page.dart';
import 'package:absensi/pages/profile_page.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [HomePage(), HistoryPage(), ProfilePage()];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mediaQuery = MediaQuery.of(context);
    final isCompact =
        mediaQuery.orientation == Orientation.landscape ||
        mediaQuery.size.height < 700;
    final horizontalMargin = isCompact ? 12.0 : 24.0;
    final bottomMargin = isCompact ? 12.0 : 24.0;
    final borderRadius = isCompact ? 24.0 : 30.0;
    final iconSize = isCompact ? 22.0 : 26.0;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark ? AppTheme.darkGradient : null,
          color: isDark ? null : Colors.white,
        ),
        child: IndexedStack(index: _currentIndex, children: _pages),
      ),
      extendBody: true,
      bottomNavigationBar: Container(
        margin: EdgeInsets.fromLTRB(
          horizontalMargin,
          0,
          horizontalMargin,
          bottomMargin,
        ),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.primaryMid : Colors.grey[100],
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color:
                isDark
                    ? Colors.white.withValues(alpha: 0.12)
                    : Colors.grey[300]!,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            backgroundColor: Colors.transparent,
            elevation: 0,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: isDark ? Colors.white : AppTheme.primaryDark,
            unselectedItemColor:
                isDark ? Colors.white.withValues(alpha: 0.4) : Colors.grey[400],
            showSelectedLabels: false,
            showUnselectedLabels: false,
            items: [
              BottomNavigationBarItem(
                icon: Icon(
                  _currentIndex == 0 ? Icons.home_rounded : Icons.home_outlined,
                  size: iconSize,
                ),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(
                  _currentIndex == 1
                      ? Icons.calendar_month_rounded
                      : Icons.calendar_month_outlined,
                  size: iconSize,
                ),
                label: 'Riwayat',
              ),
              BottomNavigationBarItem(
                icon: Icon(
                  _currentIndex == 2
                      ? Icons.person_rounded
                      : Icons.person_outline_rounded,
                  size: iconSize,
                ),
                label: 'Profil',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
