import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/capsule_model.dart';
import '../../services/capsule_service.dart';
import '../../theme/app_theme.dart';

class OpenCapsuleScreen extends StatefulWidget {
  final String capsuleId;
  const OpenCapsuleScreen({super.key, required this.capsuleId});

  @override
  State<OpenCapsuleScreen> createState() => _OpenCapsuleScreenState();
}

class _OpenCapsuleScreenState extends State<OpenCapsuleScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _shakeCtrl;
  CapsuleModel? _capsule;
  bool _opened = false;
  bool _loading = true;
  bool _replying = false;
  final _replyCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _loadCapsule();
  }

  Future<void> _loadCapsule() async {
    try {
      final response = await Supabase.instance.client
          .from('capsules')
          .select()
          .eq('id', widget.capsuleId)
          .single();
      if (mounted) {
        setState(() {
          _capsule = CapsuleModel.fromJson({...response, 'distance_meters': 0.0});
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openCapsule() async {
    _shakeCtrl.forward(from: 0);
    await Future.delayed(const Duration(milliseconds: 600));
    setState(() => _opened = true);
    await CapsuleService().unlockCapsule(capsuleId: widget.capsuleId);
  }

  Future<void> _sendReply() async {
    if (_replyCtrl.text.trim().isEmpty) return;
    setState(() => _replying = true);
    try {
      await CapsuleService().unlockCapsule(
        capsuleId: widget.capsuleId,
        replyText: _replyCtrl.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cevabın gönderildi 💌'), backgroundColor: Colors.green),
        );
        context.go('/home');
      }
    } finally {
      if (mounted) setState(() => _replying = false);
    }
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    _replyCtrl.dispose();
    super.dispose();
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
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _capsule == null
              ? const Center(child: Text('Kapsül bulunamadı'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Kapsül kutusu
                      GestureDetector(
                        onTap: _opened ? null : _openCapsule,
                        child: AnimatedBuilder(
                          animation: _shakeCtrl,
                          builder: (context, child) {
                            final shake = _shakeCtrl.value < 0.5
                                ? _shakeCtrl.value * 20 - 5
                                : (1 - _shakeCtrl.value) * 20 - 5;
                            return Transform.rotate(
                              angle: _opened ? 0 : shake * 0.05,
                              child: child,
                            );
                          },
                          child: Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: _opened
                                    ? [AppTheme.primary, AppTheme.accent]
                                    : [AppTheme.cardDark, const Color(0xFF2A1A4A)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: (_opened ? AppTheme.primary : AppTheme.secondary)
                                      .withOpacity(0.4),
                                  blurRadius: _opened ? 40 : 20,
                                  spreadRadius: _opened ? 10 : 5,
                                ),
                              ],
                            ),
                            child: Center(
                              child: _opened
                                  ? Text(
                                      _capsule!.moodEmoji,
                                      style: const TextStyle(fontSize: 60),
                                    ).animate().scale(duration: 400.ms, curve: Curves.elasticOut)
                                  : Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.lock, size: 48, color: AppTheme.primary),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Açmak için dokun',
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: AppTheme.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ),

                      if (_opened) ...[
                        const SizedBox(height: 40),

                        // Mesaj içeriği
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppTheme.cardDark,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _capsule!.contentText,
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  height: 1.7,
                                ),
                              ),
                              if (_capsule!.songName != null) ...[
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    const Icon(Icons.music_note, color: AppTheme.primary, size: 18),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${_capsule!.songName} — ${_capsule!.artistName ?? ''}',
                                      style: const TextStyle(color: AppTheme.textSecondary),
                                    ),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 8),
                              Text(
                                _capsule!.distanceLabel,
                                style: const TextStyle(color: AppTheme.primary, fontSize: 12),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.2),

                        const SizedBox(height: 24),

                        // Cevap alanı
                        Text(
                          'Cevap ver ve eşleş',
                          style: Theme.of(context).textTheme.titleMedium,
                        ).animate().fadeIn(delay: 200.ms),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _replyCtrl,
                          maxLines: 3,
                          maxLength: 300,
                          decoration: const InputDecoration(
                            hintText: 'Bu kapsüle bir şey söyle...',
                          ),
                        ).animate().fadeIn(delay: 300.ms),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _replying ? null : _sendReply,
                            child: _replying
                                ? const CircularProgressIndicator(color: Colors.black)
                                : const Text('Cevabı Gönder 💌'),
                          ),
                        ).animate().fadeIn(delay: 400.ms),
                      ],
                    ],
                  ),
                ),
    );
  }
}
