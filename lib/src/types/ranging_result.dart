import 'package:meta/meta.dart';
import 'beacon.dart';
import 'region.dart';

@immutable
class RangingResult {
  final Region region;
  final List<Beacon> beacons;

  const RangingResult({
    required this.region,
    required this.beacons,
  });

  Map<String, dynamic> toJson() => {
        'region': region,
        'beacons': beacons.map((e) => e.toJson()).toList(),
      };

  factory RangingResult.fromJson(dynamic json) => RangingResult(
        region: Region.fromJson(json['region']),
        beacons: (json['beacons'] as List<dynamic>).map((e) => Beacon.fromJson(e)).toList(),
      );
}
