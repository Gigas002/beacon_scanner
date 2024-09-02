import 'package:meta/meta.dart';

@immutable
class IBeaconId {
  static const String NOT_DEFINED_UUID = '';
  static const int NOT_DEFINED_MAJOR_ID = -1;
  static const int NOT_DEFINED_MINOR_ID = -1;

  /// Empty = not defined
  final String proximityUUID;

  /// -1 = not defined
  final int majorId;

  /// -1 = not defined
  final int minorId;

  const IBeaconId({
    required this.proximityUUID,
    this.majorId = NOT_DEFINED_MAJOR_ID,
    this.minorId = NOT_DEFINED_MINOR_ID,
  });

  bool get isDefined => proximityUUID != NOT_DEFINED_UUID && majorId == NOT_DEFINED_MAJOR_ID && minorId == NOT_DEFINED_MINOR_ID;

  factory IBeaconId.fromJson(dynamic json) => IBeaconId(
        proximityUUID: (json['proximityUUID'] as String?) ?? NOT_DEFINED_UUID,
        majorId: (json['major'] as int?) ?? NOT_DEFINED_MAJOR_ID,
        minorId: (json['minor'] as int?) ?? NOT_DEFINED_MINOR_ID,
      );

  Map<String, dynamic> toJson() => {
        'proximityUUID': proximityUUID,
        if (majorId != NOT_DEFINED_MAJOR_ID) 'major': majorId,
        if (minorId != NOT_DEFINED_MINOR_ID) 'minor': minorId,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IBeaconId &&
          runtimeType == other.runtimeType &&
          proximityUUID == other.proximityUUID &&
          majorId == other.majorId &&
          minorId == other.minorId;

  @override
  int get hashCode => proximityUUID.hashCode ^ majorId.hashCode ^ minorId.hashCode;

  @override
  String toString() => 'BeaconId{proximityUUID: $proximityUUID, majorId: $majorId, minorId: $minorId}';
}
