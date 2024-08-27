import 'package:flutter/material.dart';
import 'dart:async';
import 'package:beacon_scanner/beacon_scanner.dart';

final _beaconScanner = BeaconScanner.instance;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _beaconScanner.initialize();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: const Center(
          child: Text('Running'),
        ),
      ),
    );
  }
}
