// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scan_result.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ScanResultAdapter extends TypeAdapter<ScanResult> {
  @override
  final int typeId = 0;

  @override
  ScanResult read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ScanResult(
      currencyType: fields[0] as String,
      resultStatus: fields[1] as String,
      confidenceLevel: fields[2] as double,
      dateTime: fields[3] as DateTime,
      imagePath: fields[4] as String?,
      backImagePath: fields[5] as String?,
      yoloResults: (fields[6] as List?)?.map((e) => Map<String, dynamic>.from(e)).toList(),
      threadMetrics: fields[7] != null ? Map<String, dynamic>.from(fields[7]) : null,
    );
  }

  @override
  void write(BinaryWriter writer, ScanResult obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.currencyType)
      ..writeByte(1)
      ..write(obj.resultStatus)
      ..writeByte(2)
      ..write(obj.confidenceLevel)
      ..writeByte(3)
      ..write(obj.dateTime)
      ..writeByte(4)
      ..write(obj.imagePath)
      ..writeByte(5)
      ..write(obj.backImagePath)
      ..writeByte(6)
      ..write(obj.yoloResults)
      ..writeByte(7)
      ..write(obj.threadMetrics);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScanResultAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
