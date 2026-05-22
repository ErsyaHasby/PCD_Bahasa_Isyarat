// GENERATED CODE - DO NOT MODIFY BY HAND
// Run: flutter pub run build_runner build

part of 'translation_entry.dart';

class TranslationEntryAdapter extends TypeAdapter<TranslationEntry> {
  @override
  final int typeId = 1;

  @override
  TranslationEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TranslationEntry(
      id: fields[0] as String,
      translatedText: fields[1] as String,
      timestamp: fields[2] as DateTime,
      confidenceScore: fields[3] as double,
      gestureLabel: fields[4] as String?,
      isSyncedToCloud: fields[5] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, TranslationEntry obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.translatedText)
      ..writeByte(2)
      ..write(obj.timestamp)
      ..writeByte(3)
      ..write(obj.confidenceScore)
      ..writeByte(4)
      ..write(obj.gestureLabel)
      ..writeByte(5)
      ..write(obj.isSyncedToCloud);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TranslationEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
