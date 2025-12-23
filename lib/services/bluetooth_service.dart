import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class BluetoothService extends ChangeNotifier {
  static final BluetoothService _instance = BluetoothService._internal();

  factory BluetoothService() {
    return _instance;
  }

  BluetoothService._internal();

  BluetoothConnection? _connection;
  bool _isConnecting = false;
  bool get isConnecting => _isConnecting;
  bool get isConnected => _connection != null && _connection!.isConnected;

  String? _connectedAddress;
  String? get connectedAddress => _connectedAddress;

  // Stream for incoming data (e.g. learned codes)
  final _dataStreamController = StreamController<String>.broadcast();
  Stream<String> get dataStream => _dataStreamController.stream;

  Future<List<BluetoothDiscoveryResult>> startScan() async {
    List<BluetoothDiscoveryResult> results = [];
    try {
      // Start discovery
      StreamSubscription? streamSubscription;
      Completer<List<BluetoothDiscoveryResult>> completer = Completer();

      streamSubscription =
          FlutterBluetoothSerial.instance.startDiscovery().listen((r) {
        results.add(r);
      });

      streamSubscription.onDone(() {
        completer.complete(results);
      });

      // Stop scanning after 5 seconds to be safe if not stopped automatically or to return quick results
      Future.delayed(Duration(seconds: 5), () {
        FlutterBluetoothSerial.instance.cancelDiscovery();
      });

      return completer.future;
    } catch (e) {
      debugPrint("Error scanning: $e");
      return [];
    }
  }

  Future<void> connect(String address) async {
    if (_isConnecting) return;

    _isConnecting = true;
    notifyListeners();

    try {
      _connection = await BluetoothConnection.toAddress(address);
      _connectedAddress = address;
      debugPrint('Connected to the device');

      _connection!.input!.listen((Uint8List data) {
        String message = utf8.decode(data).trim();
        debugPrint('Data received: $message');
        _dataStreamController.add(message);
      }).onDone(() {
        debugPrint('Disconnected by remote request');
        _connection = null;
        _connectedAddress = null;
        notifyListeners();
      });
    } catch (e) {
      debugPrint('Cannot connect, exception occured');
      _connection = null;
    } finally {
      _isConnecting = false;
      notifyListeners();
    }
  }

  Future<void> sendData(String message) async {
    if (_connection != null && _connection!.isConnected) {
      _connection!.output.add(utf8.encode(message + "\r\n"));
      await _connection!.output.allSent;
      debugPrint("Sent: $message");
    } else {
      debugPrint("Not connected. Cannot send: $message");
      throw Exception("Not connected");
    }
  }

  Future<void> disconnect() async {
    await _connection?.close();
    _connection = null;
    _connectedAddress = null;
    notifyListeners();
  }
}
