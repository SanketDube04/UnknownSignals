import 'package:flutter/material.dart';
import '../models/remote.dart';
import '../models/remote_button.dart';
import '../services/database_service.dart';
import '../services/bluetooth_service.dart';

class AppProvider with ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  final BluetoothService _bluetooth = BluetoothService();
  BluetoothService get bluetooth => _bluetooth;

  List<Remote> _remotes = [];
  List<Remote> get remotes => _remotes;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Create Remote State
  List<RemoteButton> _tempButtons = [];
  List<RemoteButton> get tempButtons => _tempButtons;

  AppProvider() {
    _loadRemotes();
  }

  Future<void> _loadRemotes() async {
    _isLoading = true;
    notifyListeners();
    _remotes = await _db.getRemotes();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addRemote(String name) async {
    int id = await _db.insertRemote(Remote(
      name: name,
      createdAt: DateTime.now().toIso8601String(),
    ));

    // Save buttons
    for (var btn in _tempButtons) {
      await _db.insertButton(RemoteButton(
        remoteId: id,
        label: btn.label,
        color: btn.color,
        iconCode: btn.iconCode,
        irCode: btn.irCode,
      ));
    }

    _tempButtons.clear();
    await _loadRemotes();
  }

  void addTempButton(RemoteButton btn) {
    _tempButtons.add(btn);
    notifyListeners();
  }

  void removeTempButton(int index) {
    _tempButtons.removeAt(index);
    notifyListeners();
  }

  void clearTempButtons() {
    _tempButtons.clear();
    notifyListeners();
  }

  Future<void> deleteRemote(int id) async {
    await _db.deleteRemote(id);
    await _loadRemotes();
  }

  // IR Learning Helper
  // Listen to bluetooth stream for code
  Future<String?> waitForIrCode(Duration timeout) async {
    try {
      // Filter for messages starting with "LEARNED:"
      // We take the first element that matches the condition
      String rawMessage = await _bluetooth.dataStream
          .firstWhere((msg) => msg.startsWith("LEARNED:"))
          .timeout(timeout);

      // Strip "LEARNED:" prefix to get the code ("PROTO,ADDR,CMD,BITS")
      return rawMessage.substring("LEARNED:".length);
    } catch (e) {
      return null;
    }
  }

  Future<List<RemoteButton>> getButtonsForRemote(int remoteId) async {
    return await _db.getButtonsForRemote(remoteId);
  }

  Future<void> updateButtonIrCode(int buttonId, String irCode) async {
    await _db.updateButtonIrCode(buttonId, irCode);
    // We don't necessarily need to reload remotes since buttons are loaded per screen,
    // but notifying listeners is good practice.
    notifyListeners();
  }
}
