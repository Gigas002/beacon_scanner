import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'types/types.dart';

abstract class BeaconScannerPlatform extends PlatformInterface {
  /// Constructs a BeaconScannerPlatform
  BeaconScannerPlatform() : super(token: _token);

  static final Object _token = Object();

  static late BeaconScannerPlatform _instance;

  /// The default instance of [BeaconScannerPlatform] to use
  static BeaconScannerPlatform get instance => _instance;

  /// Platform-specific plugins should set this with their own platform-specific
  /// class that extends [BeaconScannerPlatform] when they register themselves.
  static set instance(BeaconScannerPlatform instance) {
    PlatformInterface.verify(instance, _token);
    _instance = instance;
  }

  /// Initialize scanning API.
  Future<bool> initialize() => throw UnimplementedError('initialize() has not been implemented.');

  /// Close scanning API.
  Future<bool> close() => throw UnimplementedError('close() has not been implemented.');

  /// Start ranging iBeacons with defined [List] of [Region]s.
  ///
  /// This will fire [RangingResult] whenever the iBeacons in range.
  Stream<RangingResult> ranging(List<Region> regions) => throw UnimplementedError('ranging() has not been implemented.');

  /// Start monitoring iBeacons with defined [List] of [Region]s.
  ///
  /// This will fire [MonitoringResult] whenever the iBeacons in range.
  Stream<MonitoringResult> monitoring(List<Region> regions) => throw UnimplementedError('monitoring() has not been implemented.');

  /// Customize duration of the beacon scan on the Android Platform.
  Future<bool> setScanPeriod(int scanPeriod) => throw UnimplementedError('setScanPeriod() has not been implemented.');

  /// Customize duration spent not scanning between each scan cycle on the Android Platform.
  Future<bool> setBetweenScanPeriod(int betweenScanPeriod) => throw UnimplementedError('setBetweenScanPeriod() has not been implemented.');
}
