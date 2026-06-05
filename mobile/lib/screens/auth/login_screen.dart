import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _authService = AuthService();
  bool _loading = false;

  Future<void> _signIn(Future<void> Function() method) async {
    setState(() => _loading = true);
    try {
      await method();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Giriş başarısız: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.background, Color(0xFF1A0A2E)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                const Spacer(flex: 2),
                // Logo
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      colors: [AppTheme.accent, AppTheme.secondary],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.accent.withOpacity(0.4),
                        blurRadius: 50,
                        spreadRadius: 15,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.location_on, size: 60, color: Colors.white),
                ).animate().scale(delay: 200.ms, duration: 600.ms, curve: Curves.elasticOut),
                const SizedBox(height: 32),
                Text(
                  'CrossRoads',
                  style: Theme.of(context).textTheme.displayLarge,
                ).animate().fadeIn(delay: 400.ms, duration: 600.ms),
                const SizedBox(height: 12),
                Text(
                  'Etrafındaki insanların bıraktığı\nkapsülleri keşfet, bağlantı kur.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textSecondary,
                    height: 1.6,
                  ),
                ).animate().fadeIn(delay: 600.ms, duration: 600.ms),
                const Spacer(flex: 2),
                // Giriş Butonları
                if (_loading)
                  const CircularProgressIndicator(color: AppTheme.primary)
                else
                  Column(
                    children: [
                      _SocialButton(
                        label: 'Google ile Devam Et',
                        icon: Icons.g_mobiledata,
                        iconColor: Colors.white,
                        backgroundColor: const Color(0xFF4285F4),
                        onTap: () => _signIn(_authService.signInWithGoogle),
                      ).animate().slideY(begin: 0.3, delay: 800.ms, duration: 400.ms),
                      const SizedBox(height: 16),
                      _SocialButton(
                        label: 'Apple ile Devam Et',
                        icon: Icons.apple,
                        iconColor: Colors.black,
                        backgroundColor: Colors.white,
                        onTap: () => _signIn(_authService.signInWithApple),
                      ).animate().slideY(begin: 0.3, delay: 900.ms, duration: 400.ms),
                    ],
                  ),
                const SizedBox(height: 32),
                Text(
                  'Giriş yaparak Kullanım Koşullarını\nkabul etmiş olursunuz.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final VoidCallback onTap;

  const _SocialButton({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: iconColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        icon: Icon(icon, color: iconColor, size: 28),
        label: Text(
          label,
          style: TextStyle(
            color: iconColor,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        onPressed: onTap,
      ),
    );
  }
}
