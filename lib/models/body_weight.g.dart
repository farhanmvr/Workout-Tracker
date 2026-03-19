// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'body_weight.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BodyWeightRecordAdapter extends TypeAdapter<BodyWeightRecord> {
  @override
  final int typeId = 4;

  @override
  BodyWeightRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BodyWeightRecord(
      id: fields[0] as String,
      weight: fields[1] as double,
      date: fields[2] as DateTime,
      profileId: fields[3] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, BodyWeightRecord obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.weight)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.profileId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BodyWeightRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
