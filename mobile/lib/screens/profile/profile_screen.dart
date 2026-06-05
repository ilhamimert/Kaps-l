import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  Map<String, dynamic>? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;
    final result = await Supabase.instance.client
        .from('users')
        .select()
        .eq('id', uid)
        .single();
    if (mounted) setState(() { _profile = result; _loading = false; });
  }

  Future<void> _signOut() async {
    await _authService.signOut();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.go('/home'),
        ),
        title: const Text('Profil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppTheme.textSecondary),
            onPressed: _signOut,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _profile == null
              ? const Center(child: Text('Profil yüklenemedi'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Avatar
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: AppTheme.secondary,
                        backgroundImage: _profile!['avatar_url'] != null
                            ? CachedNetworkImageProvider(_profile!['avatar_url'] as String)
                            : null,
                        child: _profile!['avatar_url'] == null
                            ? Text(
                                ((_profile!['display_name'] ?? _profile!['username']) as String)[0]
                                    .toUpperCase(),
                                style: const TextStyle(fontSize: 48, color: Colors.white),
                              )
                            : null,
                      ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),
                      const SizedBox(height: 16),
                      Text(
                        _profile!['display_name'] ?? _profile!['username'] as String,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ).animate().fadeIn(delay: 200.ms),
                      Text(
                        '@${_profile!['username']}',
                        style: const TextStyle(color: AppTheme.textSecondary),
                      ).animate().fadeIn(delay: 300.ms),
                      if (_profile!['bio'] != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          _profile!['bio'] as String,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                            height: 1.6,
                          ),
                        ).animate().fadeIn(delay: 400.ms),
                      ],
                      const SizedBox(height: 40),
                      // Kapsüllerim butonu
                      _ProfileMenuTile(
                        icon: Icons.inventory_2,
                        label: 'Bıraktığım Kapsüller',
                        onTap: () {},
                      ).animate().slideX(begin: 0.3, delay: 500.ms),
                      const SizedBox(height: 8),
                      _ProfileMenuTile(
                        icon: Icons.favorite,
                        label: 'Eşleşmelerim',
                        onTap: () => context.go('/matches'),
                      ).animate().slideX(begin: 0.3, delay: 600.ms),
                    ],
                  ),
                ),
    );
  }
}

class _ProfileMenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ProfileMenuTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.primary),
            const SizedBox(width: 16),
            Text(label, style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }
}
