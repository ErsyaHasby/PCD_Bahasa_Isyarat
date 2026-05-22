import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../data/local/journal_repository.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  final _repo = JournalRepository();

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final todayCount  = _repo.getTodayEntries().length;
    final totalCount  = _repo.totalEntries;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: Stack(
          children: [
            // Background orbs
            Positioned(top: -60, right: -40,
              child: _glowOrb(AppTheme.primary.withOpacity(0.15), 220)),
            Positioned(bottom: 120, left: -60,
              child: _glowOrb(AppTheme.secondary.withOpacity(0.10), 200)),

            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    _buildHeader(),
                    const SizedBox(height: 32),
                    _buildStatsRow(todayCount, totalCount),
                    const SizedBox(height: 32),
                    _buildStartButton(context),
                    const SizedBox(height: 28),
                    _buildFeatureCards(context),
                    const Spacer(),
                    _buildRecentLabel(context),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, -0.3), end: Offset.zero)
          .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic)),
      child: FadeTransition(
        opacity: _ctrl,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('🤟', style: TextStyle(fontSize: 22)),
                ),
                const SizedBox(width: 12),
                ShaderMask(
                  shaderCallback: (b) => AppTheme.primaryGradient.createShader(b),
                  child: const Text(
                    'IsyaratAI',
                    style: TextStyle(
                      fontSize: 26, fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Selamat datang! Mulai sesi\npenerjemahan isyarat Anda hari ini.',
              style: TextStyle(
                fontSize: 15,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Stats Row ────────────────────────────────────────────────────────
  Widget _buildStatsRow(int todayCount, int totalCount) {
    return Row(
      children: [
        Expanded(child: _StatCard(
          label: 'Hari ini', value: '$todayCount', icon: '📅',
          color: AppTheme.primary,
        )),
        const SizedBox(width: 12),
        Expanded(child: _StatCard(
          label: 'Total jurnal', value: '$totalCount', icon: '📖',
          color: AppTheme.secondary,
        )),
        const SizedBox(width: 12),
        Expanded(child: _StatCard(
          label: 'Akurasi', value: '85%', icon: '🎯',
          color: AppTheme.success,
        )),
      ],
    );
  }

  // ── Start Button ─────────────────────────────────────────────────────
  Widget _buildStartButton(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/camera'),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 70,
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withOpacity(0.45),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.videocam_rounded, color: Colors.white, size: 28),
            const SizedBox(width: 12),
            const Text(
              'Mulai Penerjemahan',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_rounded,
                color: Colors.white.withOpacity(0.7), size: 20),
          ],
        ),
      ),
    );
  }

  // ── Feature Cards ────────────────────────────────────────────────────
  Widget _buildFeatureCards(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _FeatureCard(
            icon: '📖',
            label: 'Jurnal\nTerjemahan',
            color: AppTheme.secondary,
            onTap: () => context.go('/history'),
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: _FeatureCard(
            icon: '🔊',
            label: 'Suara\nAktif',
            color: AppTheme.success,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: _FeatureCard(
            icon: '⚡',
            label: 'Real-time\nAI',
            color: AppTheme.warning,
          ),
        ),
      ],
    );
  }

  // ── Recent label ─────────────────────────────────────────────────────
  Widget _buildRecentLabel(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/history'),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Riwayat Terbaru',
            style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          Text(
            'Lihat semua →',
            style: TextStyle(
              fontSize: 13, color: AppTheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _glowOrb(Color color, double size) => Container(
    width: size, height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(colors: [color, Colors.transparent]),
    ),
  );
}

// ── Reusable widgets ────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label, value, icon;
  final Color color;
  const _StatCard({
    required this.label, required this.value,
    required this.icon, required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 8),
          Text(value,
            style: TextStyle(
              fontSize: 22, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 2),
          Text(label,
            style: const TextStyle(fontSize: 11, color: AppTheme.textHint)),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final String icon, label;
  final Color color;
  final VoidCallback? onTap;
  const _FeatureCard({
    required this.icon, required this.label,
    required this.color, this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 26)),
            const SizedBox(height: 8),
            Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11, color: color,
                fontWeight: FontWeight.w500, height: 1.3)),
          ],
        ),
      ),
    );
  }
}
