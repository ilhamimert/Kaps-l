import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../services/capsule_service.dart';
import '../../services/location_service.dart';
import '../../theme/app_theme.dart';

class CreateCapsuleScreen extends StatefulWidget {
  const CreateCapsuleScreen({super.key});

  @override
  State<CreateCapsuleScreen> createState() => _CreateCapsuleScreenState();
}

class _CreateCapsuleScreenState extends State<CreateCapsuleScreen> {
  final _textCtrl = TextEditingController();
  final _songCtrl = TextEditingController();
  final _artistCtrl = TextEditingController();
  bool _isIndoor = false;
  String? _selectedMood;
  bool _loading = false;
  int _charCount = 0;

  static const _moods = {
    'happy': '😊 Mutlu',
    'sad': '😢 Hüzünlü',
    'excited': '🎉 Heyecanlı',
    'calm': '😌 Sakin',
    'nostalgic': '🌅 Nostaljik',
    'romantic': '💕 Romantik',
    'curious': '🤔 Meraklı',
  };

  Future<void> _submit() async {
    if (_textCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);

    try {
      final pos = await LocationService.getCurrentPosition();
      if (pos == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Konum alınamadı'), backgroundColor: Colors.red),
          );
        }
        return;
      }

      await CapsuleService().createCapsule(
        lat: pos.latitude,
        lon: pos.longitude,
        isIndoor: _isIndoor,
        contentText: _textCtrl.text.trim(),
        songName: _songCtrl.text.isEmpty ? null : _songCtrl.text.trim(),
        artistName: _artistCtrl.text.isEmpty ? null : _artistCtrl.text.trim(),
        mood: _selectedMood,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kapsülün bırakıldı 💌'), backgroundColor: Colors.green),
        );
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _songCtrl.dispose();
    _artistCtrl.dispose();
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
        title: const Text('Kapsül Bırak'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mesaj alanı
            Text('Ne hissediyorsun?',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 16),
            TextField(
              controller: _textCtrl,
              maxLines: 5,
              maxLength: 300,
              onChanged: (v) => setState(() => _charCount = v.length),
              decoration: InputDecoration(
                hintText: 'Şu an tam burada, tam bu anda...',
                counterStyle: const TextStyle(color: AppTheme.textSecondary),
                filled: true,
                fillColor: AppTheme.cardDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
              ),
            ).animate().fadeIn(delay: 100.ms),

            const SizedBox(height: 24),

            // Ruh hali seçimi
            Text('Ruh halin?', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _moods.entries.map((e) {
                final selected = _selectedMood == e.key;
                return GestureDetector(
                  onTap: () => setState(() => _selectedMood = selected ? null : e.key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: selected ? AppTheme.primary : AppTheme.cardDark,
                    ),
                    child: Text(
                      e.value,
                      style: TextStyle(
                        color: selected ? Colors.black : AppTheme.textPrimary,
                        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ).animate().fadeIn(delay: 200.ms),

            const SizedBox(height: 24),

            // Şarkı
            Text('Şu an ne dinliyorsun?',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _songCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Şarkı adı',
                      prefixIcon: Icon(Icons.music_note, color: AppTheme.primary),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _artistCtrl,
                    decoration: const InputDecoration(hintText: 'Sanatçı'),
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 300.ms),

            const SizedBox(height: 24),

            // Kapalı mekan toggle
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.home, color: AppTheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Kapalı mekan', fontWeight: FontWeight.w600),
                        Text(
                          'Kafe, AVM, binadaysan aç — GPS hataları telafi edilir',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isIndoor,
                    onChanged: (v) => setState(() => _isIndoor = v),
                    activeColor: AppTheme.primary,
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 400.ms),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.black)
                    : const Text('Kapsülü Bırak 💌'),
              ),
            ).animate().slideY(begin: 0.5, delay: 500.ms),
          ],
        ),
      ),
    );
  }
}
