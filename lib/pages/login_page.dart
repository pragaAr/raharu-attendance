import 'package:flutter/material.dart';
import 'package:absensi/config/app_theme.dart';
import 'package:absensi/services/auth_service.dart';
import 'package:absensi/pages/main_shell.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final result = await _authService.login(
      _usernameController.text.trim(),
      _passwordController.text,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result.success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainShell()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(result.message)),
            ],
          ),
          backgroundColor: const Color(0xFFE53935),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : AppTheme.primaryDark;
    final subtitleColor =
        isDark ? Colors.white.withValues(alpha: 0.5) : Colors.grey[600]!;
    final footerColor =
        isDark ? Colors.white.withValues(alpha: 0.3) : Colors.grey[500]!;
    final cardColor =
        isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey[50]!;
    final cardBorderColor =
        isDark ? Colors.white.withValues(alpha: 0.12) : Colors.grey[200]!;
    final logoContainerColor = isDark ? Colors.white : Colors.grey[100]!;
    final logoShadowColor =
        isDark
            ? AppTheme.primaryDeep.withValues(alpha: 0.3)
            : AppTheme.primaryDark.withValues(alpha: 0.15);
    final buttonColor = isDark ? AppTheme.accent : AppTheme.secondaryDeep;
    final buttonDisabledColor = buttonColor.withValues(alpha: 0.55);
    final buttonTextColor = Colors.white;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark ? AppTheme.darkGradient : null,
          color: isDark ? null : Colors.white,
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final mediaQuery = MediaQuery.of(context);
              final isCompact =
                  constraints.maxHeight < 700 ||
                  mediaQuery.orientation == Orientation.landscape;
              final horizontalPadding = isCompact ? 16.0 : 28.0;
              final topPadding = isCompact ? 12.0 : 20.0;
              final logoSize = isCompact ? 24.0 : 30.0;
              final cardPadding = isCompact ? 20.0 : 28.0;
              final titleFontSize = isCompact ? 24.0 : 28.0;
              final footerTopSpace = isCompact ? 20.0 : 32.0;

              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  topPadding,
                  horizontalPadding,
                  20,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        mainAxisAlignment:
                            isCompact
                                ? MainAxisAlignment.start
                                : MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: EdgeInsets.all(isCompact ? 12 : 15),
                            decoration: BoxDecoration(
                              color: logoContainerColor,
                              borderRadius: BorderRadius.circular(
                                isCompact ? 12 : 15,
                              ),
                            ),
                            child: Image.asset(
                              'assets/images/logo-icon.png',
                              height: logoSize,
                              fit: BoxFit.contain,
                            ),
                          ),
                          SizedBox(height: isCompact ? 12 : 16),
                          Text(
                            'Absensi',
                            style: TextStyle(
                              fontSize: titleFontSize,
                              fontWeight: FontWeight.w700,
                              color: titleColor,
                              letterSpacing: 1.5,
                            ),
                          ),
                          SizedBox(height: isCompact ? 24 : 40),
                          Container(
                            padding: EdgeInsets.all(cardPadding),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(
                                isCompact ? 18 : 24,
                              ),
                              border: Border.all(color: cardBorderColor),
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    'Masuk',
                                    style: TextStyle(
                                      fontSize: isCompact ? 20 : 22,
                                      fontWeight: FontWeight.w600,
                                      color: titleColor,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Silakan masukkan kredensial Anda',
                                    style: TextStyle(
                                      fontSize: isCompact ? 12 : 13,
                                      color: subtitleColor,
                                    ),
                                  ),
                                  SizedBox(height: isCompact ? 20 : 28),
                                  TextFormField(
                                    controller: _usernameController,
                                    style: TextStyle(color: titleColor),
                                    decoration: _inputDecoration(
                                      isDark: isDark,
                                      label: 'Username',
                                      icon: Icons.person_outline_rounded,
                                    ),
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'Username wajib diisi';
                                      }
                                      return null;
                                    },
                                    textInputAction: TextInputAction.next,
                                  ),
                                  SizedBox(height: isCompact ? 14 : 18),
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: _obscurePassword,
                                    style: TextStyle(color: titleColor),
                                    decoration: _inputDecoration(
                                      isDark: isDark,
                                      label: 'Password',
                                      icon: Icons.lock_outline_rounded,
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_off_rounded
                                              : Icons.visibility_rounded,
                                          color:
                                              isDark
                                                  ? Colors.white.withValues(
                                                    alpha: 0.5,
                                                  )
                                                  : Colors.grey[500],
                                          size: 20,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _obscurePassword =
                                                !_obscurePassword;
                                          });
                                        },
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Password wajib diisi';
                                      }
                                      if (value.length < 6) {
                                        return 'Password minimal 6 karakter';
                                      }
                                      return null;
                                    },
                                    textInputAction: TextInputAction.done,
                                    onFieldSubmitted: (_) => _handleLogin(),
                                  ),
                                  SizedBox(height: isCompact ? 20 : 28),
                                  SizedBox(
                                    height: isCompact ? 48 : 52,
                                    child: ElevatedButton(
                                      onPressed:
                                          _isLoading ? null : _handleLogin,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: buttonColor,
                                        foregroundColor: buttonTextColor,
                                        disabledBackgroundColor:
                                            buttonDisabledColor,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            isCompact ? 12 : 14,
                                          ),
                                        ),
                                        elevation: 0,
                                      ),
                                      child:
                                          _isLoading
                                              ? const SizedBox(
                                                height: 22,
                                                width: 22,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2.5,
                                                      color: Colors.white,
                                                    ),
                                              )
                                              : Text(
                                                'Masuk',
                                                style: TextStyle(
                                                  fontSize: isCompact ? 15 : 16,
                                                  fontWeight: FontWeight.w600,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: footerTopSpace),
                          Text(
                            'Copyright 2026 Raharu Indonesia',
                            style: TextStyle(
                              fontSize: isCompact ? 11 : 12,
                              color: footerColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required bool isDark,
    required String label,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    final labelColor =
        isDark ? Colors.white.withValues(alpha: 0.5) : Colors.grey[600]!;
    final iconColor =
        isDark ? Colors.white.withValues(alpha: 0.5) : Colors.grey[600]!;
    final fillColor =
        isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey[100]!;
    final enabledBorderColor =
        isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey[300]!;
    final errorColor =
        isDark ? const Color(0xFFEF9A9A) : const Color(0xFFD32F2F);

    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: labelColor, fontSize: 14),
      prefixIcon: Icon(icon, color: iconColor, size: 20),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: fillColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: enabledBorderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppTheme.accent, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFEF5350)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFEF5350), width: 1.5),
      ),
      errorStyle: TextStyle(color: errorColor),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}
