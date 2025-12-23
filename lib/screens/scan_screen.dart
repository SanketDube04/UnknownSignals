import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/bluetooth_service.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final BluetoothService _bluetoothService = BluetoothService();
  List<BluetoothDiscoveryResult> _results = [];
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  void _startScan() async {
    // Request permissions first
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location, // Required for scanning on some versions
    ].request();

    if (statuses[Permission.bluetoothScan]!.isDenied ||
        statuses[Permission.bluetoothConnect]!.isDenied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Bluetooth permissions are required to scan.")),
        );
      }
      return;
    }

    setState(() {
      _isScanning = true;
      _results = [];
    });

    final results = await _bluetoothService.startScan();

    if (mounted) {
      setState(() {
        _results = results;
        _isScanning = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Scan for Devices"),
        actions: [
          if (_isScanning)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2)),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _startScan,
            ),
        ],
      ),
      body: ListView.builder(
        itemCount: _results.length,
        itemBuilder: (context, index) {
          final result = _results[index];
          final device = result.device;
          return ListTile(
            title: Text(device.name ?? "Unknown Device"),
            subtitle: Text(device.address),
            trailing: AnimatedBuilder(
              animation: _bluetoothService,
              builder: (context, child) {
                final isConnectedToThis =
                    _bluetoothService.connectedAddress == device.address;
                return ElevatedButton(
                  onPressed: isConnectedToThis
                      ? null
                      : () async {
                          // Check Permissions first
                          Map<Permission, PermissionStatus> statuses = await [
                            Permission.bluetoothScan,
                            Permission.bluetoothConnect,
                          ].request();

                          if (statuses[Permission.bluetoothScan]!.isDenied ||
                              statuses[Permission.bluetoothConnect]!.isDenied) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        "Bluetooth permissions required!")),
                              );
                            }
                            return;
                          }

                          // Connect
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Connecting...")),
                            );
                          }
                          await _bluetoothService.connect(device.address);
                          if (mounted) {
                            if (_bluetoothService.isConnected) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Connected!")),
                              );
                              // Optional: Pop if you want to go back immediately,
                              // but user might want to see the "Connected" state.
                              // Navigator.pop(context);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text("Connection Failed!")),
                              );
                            }
                          }
                        },
                  child: Text(isConnectedToThis ? "Connected" : "Connect"),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
