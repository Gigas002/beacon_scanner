import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:beacon_scanner/beacon_scanner.dart';
import 'package:logging/logging.dart';

final _logger = Logger("example");
final _beaconScanner = BeaconScanner.instance;
const _regions = <Region>[
  Region(
    identifier: 'beacon-id',
    beaconId: IBeaconId(proximityUUID: 'D546DF97-4757-47EF-BE09-3E2DCBDD0C77'),
  )
];

double _calculateDistance(int rssi, int power, double n) {
  if (rssi >= 0) {
    return -1.0;
  }

  double ratio = (power - rssi) / (10.0 * n);
  double distance = pow(10, ratio).toDouble();

  return distance;
}

Future<void> _monitorBeacons(MonitoringResult result) async {
  if (result.monitoringEventType == MonitoringEventType.didDetermineStateForRegion) {
    _logger.info('monitoring triggered');

    switch (result.monitoringState) {
      case MonitoringState.inside:
        _logger.info('monitoring: state: INSIDE');
        break;
      case MonitoringState.outside:
        _logger.info('monitoring: state: OUTSIDE');
        break;
      default:
        _logger.info('monitoring: state: UNKNOWN');
        break;
    }
  }
}

Future<void> main() async {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    // ignore: avoid_print
    print('${record.level.name}: ${record.time}: ${record.message}');
  });

  WidgetsFlutterBinding.ensureInitialized();

  await _beaconScanner.initialize();
  await _beaconScanner.setScanPeriod(const Duration(milliseconds: 1000));
  await _beaconScanner.setBetweenScanPeriod(const Duration(milliseconds: 1000));
  _beaconScanner.monitoring(_regions).listen(_monitorBeacons);

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Beacon? _beacon;

  Future<void> _rangeBeacons(RangingResult result) async {
    _logger.info('ranging triggered');
    if (result.beacons.isNotEmpty) {
      setState(() {
        _beacon = result.beacons[0];
      });

      // this is the number I've set up on my test beacon, don't use in prod
      var power = _beacon!.txPower ?? -7;
      var distance = _calculateDistance(_beacon!.rssi, power, 4.0);

      _logger.info('ranging: found beacon: $_beacon');
      _logger.info('ranging: distance: $distance');
    }
  }

  @override
  Widget build(BuildContext context) {
    _beaconScanner.ranging(_regions).listen(_rangeBeacons);

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Text('found beacon: $_beacon'),
        ),
      ),
    );
  }
}
