import 'beacon_scanner_platform.dart';
import 'types/types.dart';

/// Service for interacting with bluetooth beacon which uses iBeacon protocol
class BeaconScanner {
  /// Instance of Beacon-Service
  static final BeaconScanner instance = BeaconScanner._();

  BeaconScanner._();

  /// Is [BeaconScanner] initialize
  bool isInitialize = false;

  /// Initialize scanning API
  Future<bool> initialize() async => isInitialize = await BeaconScannerPlatform.instance.initialize();

  /// Close scanning API.
  Future<bool> close() async {
    bool successClosed = await BeaconScannerPlatform.instance.close();
    isInitialize = !successClosed;

    return successClosed;
  }

  /// Start ranging iBeacons with defined [List] of [Region]s.
  ///
  /// This will fires [RangingResult] whenever the iBeacons in range.
  Stream<RangingResult> ranging(List<Region> regions) => BeaconScannerPlatform.instance.ranging(regions);

  /// Start monitoring iBeacons with defined [List] of [Region]s.
  ///
  /// This will fires [MonitoringResult] whenever the iBeacons in range.
  Stream<MonitoringResult> monitoring(List<Region> regions) => BeaconScannerPlatform.instance.monitoring(regions);

  /// Customize period of the beacon scan on the Android Platform.
  Future<bool> setScanPeriod(Duration scanPeriod) async => BeaconScannerPlatform.instance.setScanPeriod(scanPeriod.inMilliseconds);

  /// Customize duration of the beacon scan on the Android Platform.
  Future<bool> setBetweenScanPeriod(Duration scanDuration) async => BeaconScannerPlatform.instance.setBetweenScanPeriod(scanDuration.inMilliseconds);
}
