import 'dart:async';
import 'package:flutter/services.dart';
import 'beacon_scanner_platform.dart';
import 'constants.dart';
import 'types/types.dart';

/// An implementation of [BeaconScannerPlatform] for iOS.
class BeaconScannerIOS extends BeaconScannerPlatform {
  /// Registers this class as the default instance of [BeaconScannerPlatform].
  static void registerWith() {
    BeaconScannerPlatform.instance = BeaconScannerIOS();
  }

  /// Method Channel used to communicate to native code.
  static const MethodChannel _channel = MethodChannel(METHOD_CHANNEL);

  /// Event Channel used to communicate to native code ranging beacons.
  static const EventChannel _rangingChannel = EventChannel(RANGING_EVENT_CHANNEL);

  /// Event Channel used to communicate to native code monitoring beacons.
  static const EventChannel _monitoringChannel = EventChannel(MONITORING_EVENT_CHANNEL);

  @override
  Future<bool> initialize() async => (await _channel.invokeMethod<bool>(METHOD_INITIALIZE)) ?? false;

  @override
  Future<bool> close() async => (await _channel.invokeMethod<bool>(METHOD_CLOSE)) ?? false;

  @override
  Stream<RangingResult> ranging(List<Region> regions) {
    final List<Map<String, dynamic>> list = regions.map((region) => region.toJson()).toList();
    final Stream<RangingResult> onRanging = _rangingChannel.receiveBroadcastStream(list).map((dynamic event) => RangingResult.fromJson(event));

    return onRanging;
  }

  @override
  Stream<MonitoringResult> monitoring(List<Region> regions) {
    final List<Map<String, dynamic>> list = regions.map((region) => region.toJson()).toList();
    final Stream<MonitoringResult> onMonitoring = _monitoringChannel.receiveBroadcastStream(list).map((dynamic event) => MonitoringResult.fromJson(event));
    
    return onMonitoring;
  }

  @override
  Future<bool> setScanPeriod(int scanPeriod) async => false;

  @override
  Future<bool> setBetweenScanPeriod(int betweenScanPeriod) async => false;
}
