import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../models/capsule_model.dart';
import '../../services/capsule_service.dart';
import '../../services/location_service.dart';
import '../../theme/app_theme.dart';

final locationProvider = FutureProvider<Position?>((ref) async {
  return LocationService.getCurrentPosition();
});

final nearbyCapsuleProvider = FutureProvider.family<List<CapsuleModel>, LatLng>((ref, pos) async {
  return CapsuleService().getNearbyCapsules(lat: pos.latitude, lon: pos.longitude);
});

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final MapController _mapController = MapController();
  LatLng? _userPosition;
  List<CapsuleModel> _capsules = [];

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    final pos = await LocationService.getCurrentPosition();
    if (pos == null || !mounted) return;
    final latLng = LatLng(pos.latitude, pos.longitude);
    setState(() => _userPosition = latLng);
    _mapController.move(latLng, 18);
    _loadCapsules(latLng);
  }

  Future<void> _loadCapsules(LatLng pos) async {
    final capsules = await CapsuleService().getNearbyCapsules(
      lat: pos.latitude,
      lon: pos.longitude,
    );
    if (mounted) setState(() => _capsules = capsules);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _userPosition ?? const LatLng(41.015137, 28.979530),
              initialZoom: 17,
              onMapEvent: (event) {
                if (event is MapEventMoveEnd && _userPosition != null) {
                  _loadCapsules(_mapController.camera.center);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'io.crossroads.app',
              ),
              if (_userPosition != null)
                MarkerLayer(markers: [
                  Marker(
                    point: _userPosition!,
                    width: 40,
                    height: 40,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.accent,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(color: AppTheme.accent.withOpacity(0.6), blurRadius: 15, spreadRadius: 5),
                        ],
                      ),
                    ),
                  ),
                ]),
              MarkerLayer(
                markers: _capsules.map((c) => Marker(
                  point: _userPosition ?? const LatLng(41.015137, 28.979530),
                  width: 56,
                  height: 56,
                  child: GestureDetector(
                    onTap: () => context.go('/home/capsule/open/${c.id}'),
                    child: _CapsuleMarker(capsule: c),
                  ),
                )).toList(),
              ),
            ],
          ),
          // Üst bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _MapButton(
                    icon: Icons.person,
                    onTap: () => context.go('/profile'),
                  ),
                  const Spacer(),
                  _MapButton(
                    icon: Icons.favorite,
                    onTap: () => context.go('/matches'),
                  ),
                ],
              ),
            ),
          ),
          // Alt buton - Kapsül bırak
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: () => context.go('/home/capsule/create'),
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [AppTheme.accent, AppTheme.secondary],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.accent.withOpacity(0.5),
                        blurRadius: 25,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.add, size: 36, color: Colors.white),
                ),
              ),
            ),
          ),
          // Yakındaki kapsül sayısı
          if (_capsules.isNotEmpty)
            Positioned(
              bottom: 130,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.cardDark.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_capsules.length} kapsül yakında',
                    style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CapsuleMarker extends StatelessWidget {
  final CapsuleModel capsule;
  const _CapsuleMarker({required this.capsule});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: capsule.isIndoor
              ? [const Color(0xFF9B59B6), const Color(0xFF6C3483)]
              : [AppTheme.primary, AppTheme.accent],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.5),
            blurRadius: 12,
            spreadRadius: 3,
          ),
        ],
      ),
      child: Center(
        child: Text(capsule.moodEmoji, style: const TextStyle(fontSize: 22)),
      ),
    );
  }
}

class _MapButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _MapButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppTheme.cardDark.withOpacity(0.9),
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10)],
        ),
        child: Icon(icon, color: AppTheme.textPrimary, size: 22),
      ),
    );
  }
}
