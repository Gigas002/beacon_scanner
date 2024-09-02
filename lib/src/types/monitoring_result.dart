import 'monitoring_state.dart';
import 'monitoring_event_type.dart';
import 'package:flutter/foundation.dart';
import 'region.dart';

/// Class for managing monitoring result from scanning iBeacon process.
@immutable
class MonitoringResult {
  /// The [MonitoringEventType] of monitoring result
  final MonitoringEventType monitoringEventType;

  /// The [MonitoringState] of monitoring result
  final MonitoringState monitoringState;

  /// The monitoring [Region]
  final Region region;

  const MonitoringResult({
    required this.monitoringEventType,
    required this.region,
    this.monitoringState = MonitoringState.unknown,
  });

  /// Constructor to deserialize dynamic json into [MonitoringResult]
  factory MonitoringResult.fromJson(dynamic json) => MonitoringResult(
        monitoringEventType: MonitoringEventType.values.firstWhere((e) => e.name == json['event']),
        monitoringState: MonitoringState.values.firstWhere((e) => e.name == json['state'], orElse: () => MonitoringState.unknown),
        region: Region.fromJson(json['region']),
      );

  /// Return the serializable of this object into [Map]
  Map<String, dynamic> toJson() => <String, dynamic>{
        'event': monitoringEventType.name,
        'region': region.toJson(),
        'state': monitoringState.name,
      };
}
