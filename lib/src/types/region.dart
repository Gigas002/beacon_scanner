import 'package:meta/meta.dart';
import 'ibeacon_id.dart';

/// Class for managing ranging and monitoring region scanning
@immutable
class Region {
  final String identifier;

  /// ID of Beacon (UUID, Major, Minor)
  final IBeaconId? beaconId;

  const Region({
    required this.identifier,
    this.beaconId,
  });

  @override
  bool operator ==(Object other) => identical(this, other) || other is Region && runtimeType == other.runtimeType && identifier == other.identifier;

  @override
  int get hashCode => identifier.hashCode;

  @override
  String toString() => 'Region{identifier: $identifier, beaconId: $beaconId}';

  Map<String, dynamic> toJson() => <String, dynamic>{
        'identifier': identifier,
        if (beaconId != null) ...beaconId!.toJson(),
      };

  factory Region.fromJson(dynamic json) => Region(
        identifier: json['identifier'] as String,
        beaconId: IBeaconId.fromJson(json),
      );
}
