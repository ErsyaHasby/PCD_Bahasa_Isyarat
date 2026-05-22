import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/tts_service.dart';
import '../../core/theme/app_theme.dart';
import '../../data/local/journal_repository.dart';
import '../../data/local/models/translation_entry.dart';

class TranslationDetailScreen extends StatefulWidget {
  final String entryId;
  const TranslationDetailScreen({super.key, required this.entryId});
  @override
  State<TranslationDetailScreen> createState() =>
      _TranslationDetailScreenState();
}

class _TranslationDetailScreenState extends State<TranslationDetailScreen>
    with SingleTickerProviderStateMixin {
  final _tts  = TtsService();
  final _repo = JournalRepository();
  TranslationEntry? _entry;
  late AnimationController _ctrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500))
      ..forward();
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _entry = _repo.getEntryById(widget.entryId);
    _tts.initialize();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _tts.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_entry == null) {
      return Scaffold(
        backgroundColor: AppTheme.bg,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('❌', style: TextStyle(fontSize: 40)),
              const SizedBox(height: 12),
              const Text('Entri tidak ditemukan',
                  style: TextStyle(color: AppTheme.textPrimary, fontSize: 16)),
              TextButton(
                  onPressed: () => context.go('/history'),
                  child: const Text('Kembali')),
            ],
          ),
        ),
      );
    }

    final entry = _entry!;
    final confColor = entry.confidenceScore >= 0.85
        ? AppTheme.success
        : entry.confidenceScore >= 0.70
            ? AppTheme.warning
            : AppTheme.error;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fade,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Top bar ─────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.go('/history'),
                        child: Container(
                          width: 38, height: 38,
                          decoration: BoxDecoration(
                            color: AppTheme.card,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppTheme.divider),
                          ),
                          child: const Icon(Icons.arrow_back_rounded,
                              size: 18, color: AppTheme.textPrimary),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text('Detail Terjemahan',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary)),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // ── Main card ───────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primary.withOpacity(0.15),
                          AppTheme.card,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                          color: AppTheme.primary.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('🤟', style: TextStyle(fontSize: 40)),
                        const SizedBox(height: 12),
                        Text(
                          entry.translatedText,
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (entry.gestureLabel != null)
                          Text(
                            'Gestur: ${entry.gestureLabel}',
                            style: const TextStyle(
                                fontSize: 13, color: AppTheme.textHint),
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ── Meta info ───────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _MetaTile(
                        icon: Icons.access_time_rounded,
                        label: 'Waktu',
                        value: entry.formattedTime,
                        color: AppTheme.secondary,
                      ),
                      const SizedBox(width: 10),
                      _MetaTile(
                        icon: Icons.calendar_today_rounded,
                        label: 'Tanggal',
                        value: entry.formattedDate,
                        color: AppTheme.primary,
                      ),
                      const SizedBox(width: 10),
                      _MetaTile(
                        icon: Icons.verified_rounded,
                        label: 'Akurasi',
                        value: entry.confidencePercent,
                        color: confColor,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── Confidence bar ───────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.divider),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Tingkat Kepercayaan AI',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.textSecondary,
                                    fontWeight: FontWeight.w500)),
                            Text(entry.confidencePercent,
                                style: TextStyle(
                                    fontSize: 16,
                                    color: confColor,
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: entry.confidenceScore,
                            backgroundColor: AppTheme.divider,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(confColor),
                            minHeight: 8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(),

                // ── Action buttons ───────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _tts.speak(entry.translatedText),
                          icon: const Icon(Icons.volume_up_rounded),
                          label: const Text('Putar Suara'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            await _repo.deleteEntry(entry.id);
                            if (context.mounted) context.go('/history');
                          },
                          icon: const Icon(Icons.delete_outline_rounded,
                              color: AppTheme.error),
                          label: const Text('Hapus Entri',
                              style: TextStyle(color: AppTheme.error)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: AppTheme.error),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetaTile extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;
  const _MetaTile({
    required this.icon, required this.label,
    required this.value, required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.18)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: color)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    fontSize: 10, color: AppTheme.textHint)),
          ],
        ),
      ),
    );
  }
}
