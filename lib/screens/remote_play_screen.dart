import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/remote.dart';
import '../models/remote_button.dart';
import '../providers/app_provider.dart';

class RemotePlayScreen extends StatefulWidget {
  final Remote remote;

  const RemotePlayScreen({super.key, required this.remote});

  @override
  State<RemotePlayScreen> createState() => _RemotePlayScreenState();
}

class _RemotePlayScreenState extends State<RemotePlayScreen> {
  List<RemoteButton> _buttons = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadButtons();
  }

  Future<void> _loadButtons() async {
    final btns = await context
        .read<AppProvider>()
        .getButtonsForRemote(widget.remote.id!);
    if (mounted) {
      setState(() {
        _buttons = btns;
        _isLoading = false;
      });
    }
  }

  Future<void> _sendSignal(RemoteButton btn) async {
    if (btn.irCode == null || btn.irCode!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Signal not learned for this button!")),
      );
      return;
    }

    try {
      // Sending format: SEND:PROTOCOL,DATA,BITS
      // We stored irCode as "PROTOCOL,DATA,BITS" (e.g., "NEC,0x20DF10EF,32")
      // So we just prepend "SEND:"
      String command = "SEND:${btn.irCode}";

      await context.read<AppProvider>().bluetooth.sendData(command);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Sent: ${btn.label}"),
            duration: const Duration(milliseconds: 500)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.remote.name),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buttons.isEmpty
              ? const Center(
                  child: Text(
                      "No buttons. Add some in edit mode (not implemented yet)."))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 15,
                    ),
                    itemCount: _buttons.length,
                    itemBuilder: (context, index) {
                      final btn = _buttons[index];
                      return Material(
                        color: Color(btn.color),
                        borderRadius: BorderRadius.circular(16),
                        elevation: 4,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => _sendSignal(btn),
                          onLongPress: () => _showRelearnDialog(btn),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                IconData(int.parse(btn.iconCode),
                                    fontFamily: 'MaterialIcons'),
                                color: Colors.white,
                                size: 36,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                btn.label,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14),
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Future<void> _showRelearnDialog(RemoteButton btn) async {
    bool isLearning = false;
    String? newCode;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: Text("Re-learn ${btn.label}?"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                    "Point your physical remote at the ESP32 and press the button."),
                const SizedBox(height: 20),
                if (isLearning)
                  const CircularProgressIndicator()
                else if (newCode != null)
                  const Column(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 40),
                      SizedBox(height: 8),
                      Text("Code Received!"),
                    ],
                  )
                else
                  const Icon(Icons.settings_remote,
                      size: 40, color: Colors.grey),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              if (newCode == null)
                TextButton(
                  onPressed: isLearning
                      ? null
                      : () async {
                          setState(() => isLearning = true);
                          try {
                            // Send LEARN command
                            await context
                                .read<AppProvider>()
                                .bluetooth
                                .sendData("LEARN:1");

                            // Wait for response
                            String? code = await context
                                .read<AppProvider>()
                                .waitForIrCode(const Duration(seconds: 15));

                            if (mounted) {
                              setState(() {
                                isLearning = false;
                                if (code != null) {
                                  newCode = code;
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              "Timeout: No signal received")));
                                }
                              });
                            }
                          } catch (e) {
                            if (mounted) {
                              setState(() => isLearning = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Error: $e")));
                            }
                          }
                        },
                  child: const Text("Start Learning"),
                ),
              if (newCode != null)
                TextButton(
                  onPressed: () async {
                    await context
                        .read<AppProvider>()
                        .updateButtonIrCode(btn.id!, newCode!);
                    if (mounted) {
                      Navigator.pop(context);
                      _loadButtons(); // Refresh list
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text("Button updated successfully!")));
                    }
                  },
                  child: const Text("Save"),
                ),
            ],
          );
        });
      },
    );
  }
}
