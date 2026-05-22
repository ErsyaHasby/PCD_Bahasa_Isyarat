import 'package:hive/hive.dart';

part 'translation_entry.g.dart';

@HiveType(typeId: 1)
class TranslationEntry extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String translatedText;

  @HiveField(2)
  late DateTime timestamp;

  @HiveField(3)
  late double confidenceScore;

  @HiveField(4)
  String? gestureLabel;

  @HiveField(5)
  bool isSyncedToCloud;

  TranslationEntry({
    required this.id,
    required this.translatedText,
    required this.timestamp,
    required this.confidenceScore,
    this.gestureLabel,
    this.isSyncedToCloud = false,
  });

  String get formattedTime {
    final h = timestamp.hour.toString().padLeft(2, '0');
    final m = timestamp.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String get formattedDate {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${timestamp.day} ${months[timestamp.month]} ${timestamp.year}';
  }

  String get confidencePercent =>
      '${(confidenceScore * 100).toStringAsFixed(0)}%';
}
