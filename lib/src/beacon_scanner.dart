import 'beacon_scanner_platform.dart';
import 'types/types.dart';

/// Service for interacting with bluetooth beacon which uses iBeacon protocol
class BeaconScanner {
  /// Instance of Beacon Scanner
  static final BeaconScanner instance = BeaconScanner._();

  BeaconScanner._();

  /// Is [BeaconScanner] initialized?
  bool _isInitialized = false;

  /// Initialize scanning API
  Future<bool> initialize() async {
    if (!_isInitialized) {
      _isInitialized = await BeaconScannerPlatform.instance.initialize() ?? false;
    }

    return _isInitialized;
  }

  /// Close scanning API
  Future<bool?> close() async {
    bool? isClosed = false;

    if (_isInitialized) {
      isClosed = await BeaconScannerPlatform.instance.close();
      _isInitialized = !(isClosed ?? false);
    }

    return isClosed;
  }

  /// Start ranging iBeacons with defined [List] of [Region]s
  ///
  /// This will fire [RangingResult] whenever the iBeacon is in range
  Stream<RangingResult> ranging(List<Region> regions) => BeaconScannerPlatform.instance.ranging(regions);

  /// Start monitoring iBeacons with defined [List] of [Region]s
  ///
  /// This will fire [MonitoringResult] whenever the iBeacon is in range
  Stream<MonitoringResult> monitoring(List<Region> regions) => BeaconScannerPlatform.instance.monitoring(regions);

  /// Customize period of the beacon scan on the Android Platform
  Future<bool?> setScanPeriod(Duration scanPeriod) => BeaconScannerPlatform.instance.setScanPeriod(scanPeriod.inMilliseconds);

  /// Customize duration of the beacon scan on the Android Platform
  Future<bool?> setBetweenScanPeriod(Duration scanDuration) => BeaconScannerPlatform.instance.setBetweenScanPeriod(scanDuration.inMilliseconds);
}
