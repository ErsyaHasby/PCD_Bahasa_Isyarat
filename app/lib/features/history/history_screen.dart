import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../data/local/journal_repository.dart';
import '../../data/local/models/translation_entry.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _repo = JournalRepository();
  List<TranslationEntry> _entries = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  void _loadEntries() {
    setState(() => _entries = _repo.getAllEntries());
  }

  List<TranslationEntry> get _filtered => _searchQuery.isEmpty
      ? _entries
      : _entries.where((e) =>
          e.translatedText.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();

  Future<void> _deleteEntry(String id) async {
    await _repo.deleteEntry(id);
    _loadEntries();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Entri dihapus'),
          backgroundColor: AppTheme.card,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _clearAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Semua?',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text(
            'Semua riwayat terjemahan akan dihapus permanen.',
            style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Hapus', style: TextStyle(color: AppTheme.error))),
        ],
      ),
    );
    if (confirm == true) {
      await _repo.clearAll();
      _loadEntries();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(context),
              _buildSearchBar(),
              _buildSummaryChips(),
              Expanded(child: _buildList()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.go('/'),
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
          const Text('📖  Jurnal Terjemahan',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary)),
          const Spacer(),
          if (_entries.isNotEmpty)
            GestureDetector(
              onTap: _clearAll,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.error.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.error.withOpacity(0.25)),
                ),
                child: const Text('Hapus Semua',
                    style: TextStyle(fontSize: 11, color: AppTheme.error,
                        fontWeight: FontWeight.w500)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.divider),
        ),
        child: TextField(
          onChanged: (v) => setState(() => _searchQuery = v),
          style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
          decoration: InputDecoration(
            hintText: 'Cari terjemahan...',
            hintStyle: const TextStyle(fontSize: 14, color: AppTheme.textHint),
            prefixIcon: const Icon(Icons.search_rounded,
                size: 18, color: AppTheme.textHint),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryChips() {
    final today = _repo.getTodayEntries().length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          _Chip(label: '${_entries.length} Total', color: AppTheme.primary),
          const SizedBox(width: 8),
          _Chip(label: '$today Hari ini', color: AppTheme.secondary),
          const SizedBox(width: 8),
          _Chip(label: '${_filtered.length} Ditampilkan', color: AppTheme.success),
        ],
      ),
    );
  }

  Widget _buildList() {
    if (_filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('📭', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            const Text('Jurnal masih kosong',
                style: TextStyle(fontSize: 16,
                    fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
            const SizedBox(height: 6),
            Text(
              _searchQuery.isEmpty
                  ? 'Mulai sesi kamera untuk\nmencatat terjemahan'
                  : 'Tidak ada hasil untuk "$_searchQuery"',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppTheme.textHint),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: _filtered.length,
      itemBuilder: (_, i) {
        final entry = _filtered[i];
        return _JournalCard(
          entry: entry,
          onTap: () => context.go('/history/detail/${entry.id}'),
          onDelete: () => _deleteEntry(entry.id),
        );
      },
    );
  }
}

// ── Widgets ──────────────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(label,
          style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
    );
  }
}

class _JournalCard extends StatelessWidget {
  final TranslationEntry entry;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  const _JournalCard({
    required this.entry, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final confidence = entry.confidenceScore;
    final confColor = confidence >= 0.85
        ? AppTheme.success
        : confidence >= 0.70
            ? AppTheme.warning
            : AppTheme.error;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.divider),
          ),
          child: Row(
            children: [
              // Left: emoji
              Container(
                width: 46, height: 46,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text('🤟', style: TextStyle(fontSize: 20)),
                ),
              ),
              const SizedBox(width: 12),
              // Center: text + meta
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.translatedText,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.access_time_rounded,
                            size: 11, color: AppTheme.textHint),
                        const SizedBox(width: 3),
                        Text(
                          '${entry.formattedDate} • ${entry.formattedTime}',
                          style: const TextStyle(
                              fontSize: 11, color: AppTheme.textHint),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 5, height: 5,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle, color: confColor),
                        ),
                        const SizedBox(width: 3),
                        Text(entry.confidencePercent,
                            style: TextStyle(
                                fontSize: 11,
                                color: confColor,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ],
                ),
              ),
              // Right: delete button
              GestureDetector(
                onTap: onDelete,
                child: Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: AppTheme.error.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.delete_outline_rounded,
                      size: 15, color: AppTheme.error),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
