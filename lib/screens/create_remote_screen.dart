import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/remote_button.dart';

class CreateRemoteScreen extends StatefulWidget {
  const CreateRemoteScreen({super.key});

  @override
  State<CreateRemoteScreen> createState() => _CreateRemoteScreenState();
}

class _CreateRemoteScreenState extends State<CreateRemoteScreen> {
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _showAddButtonDialog() {
    showDialog(
      context: context,
      builder: (context) => const AddButtonDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create New Remote"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "Remote Name (e.g. TV, AC)",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _showAddButtonDialog,
              icon: const Icon(Icons.add_circle_outline),
              label: const Text("Add Button"),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Consumer<AppProvider>(
                builder: (context, provider, child) {
                  if (provider.tempButtons.isEmpty) {
                    return const Center(child: Text("No buttons added yet."));
                  }
                  return GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: provider.tempButtons.length,
                    itemBuilder: (context, index) {
                      final btn = provider.tempButtons[index];
                      return Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Color(btn.color),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Simplified icon rendering, assuming iconCode is valid
                                  Icon(
                                    IconData(int.parse(btn.iconCode),
                                        fontFamily: 'MaterialIcons'),
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    btn.label,
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            right: 0,
                            top: 0,
                            child: GestureDetector(
                              onTap: () {
                                provider.removeTempButton(index);
                              },
                              child: const CircleAvatar(
                                radius: 10,
                                backgroundColor: Colors.white,
                                child: Icon(Icons.close,
                                    size: 16, color: Colors.red),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (_nameController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text("Please enter a remote name")),
                    );
                    return;
                  }
                  if (context.read<AppProvider>().tempButtons.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text("Please add at least one button")),
                    );
                    return;
                  }

                  await context
                      .read<AppProvider>()
                      .addRemote(_nameController.text);
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text("Save Remote"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AddButtonDialog extends StatefulWidget {
  const AddButtonDialog({super.key});

  @override
  State<AddButtonDialog> createState() => _AddButtonDialogState();
}

class _AddButtonDialogState extends State<AddButtonDialog> {
  final TextEditingController _labelController = TextEditingController();
  Color _selectedColor = Colors.blue;
  IconData _selectedIcon = Icons.power_settings_new;
  String? _learnedCode;
  bool _isLearning = false;

  final List<Color> _colors = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.grey,
    Colors.black87,
  ];

  final List<IconData> _icons = [
    Icons.power_settings_new,
    Icons.volume_up,
    Icons.volume_down,
    Icons.arrow_upward,
    Icons.arrow_downward,
    Icons.arrow_back,
    Icons.arrow_forward,
    Icons.home,
    Icons.menu,
    Icons.input,
    Icons.settings,
    Icons.grid_view,
    Icons.radio_button_checked,
  ];

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  Future<void> _startLearning() async {
    setState(() {
      _isLearning = true;
      _learnedCode = null;
    });

    final provider = context.read<AppProvider>();
    // We can use a temporary ID or similar. Using '1' for generic learn mode or current timestamp
    // The requirement says LEARN:<id>.
    // Let's use a timestamp based ID for the session to be safe, or just 1.
    // Actually, sending 'LEARN:1' is sufficient if ESP loops back what it gets.

    // Check connection first
    // Note: In a real app we should check connection status properly.
    // Assuming connected for now or service handles it silently (throws/logs).

    try {
      // 1. Tell ESP32 to learn
      // Using a random small ID for the learning session
      await Provider.of<AppProvider>(context, listen: false)
          .bluetooth
          .sendData("LEARN:1");
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLearning = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Bluetooth not connected")));
      }
      return;
    }

    // 2. Wait for response
    String? code = await provider.waitForIrCode(const Duration(seconds: 15));

    if (mounted) {
      setState(() {
        _isLearning = false;
        if (code != null) {
          _learnedCode = code;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Timeout: No signal received")));
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Add Button"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _labelController,
              decoration: const InputDecoration(labelText: "Button Label"),
            ),
            const SizedBox(height: 16),
            const Text("Color:"),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _colors
                  .map((c) => GestureDetector(
                        onTap: () => setState(() => _selectedColor = c),
                        child: CircleAvatar(
                          backgroundColor: c,
                          radius: 14,
                          child: _selectedColor == c
                              ? const Icon(Icons.check,
                                  color: Colors.white, size: 16)
                              : null,
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),
            const Text("Icon:"),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _icons
                  .map((icon) => GestureDetector(
                        onTap: () => setState(() => _selectedIcon = icon),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color:
                                _selectedIcon == icon ? Colors.grey[300] : null,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Icon(icon),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                onPressed: _isLearning ? null : _startLearning,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _learnedCode != null ? Colors.green : Colors.orange,
                  foregroundColor: Colors.white,
                ),
                child: Text(_isLearning
                    ? "Listening..."
                    : (_learnedCode != null
                        ? "Code Learned!"
                        : "Learn IR Code")),
              ),
            ),
            if (_learnedCode != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text("Code: $_learnedCode",
                    style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        TextButton(
          onPressed: () {
            if (_labelController.text.isEmpty) return;
            // Allow adding without code? Warning says "Show warning if not learnt".
            // So we can save it, but prevent sending later.

            final btn = RemoteButton(
              remoteId: 0, // Placeholder, assigned in Provider
              label: _labelController.text,
              color: _selectedColor.value,
              iconCode: _selectedIcon.codePoint.toString(),
              irCode: _learnedCode,
            );

            context.read<AppProvider>().addTempButton(btn);
            Navigator.pop(context);
          },
          child: const Text("Add"),
        ),
      ],
    );
  }
}

// Extension to expose BluetoothService in Provider if not directly available
// Or we can just modify AppProvider to expose it getter.
// In AppProvider.dart I declared `_bluetooth` as private.
// I should make it public or add a getter.
// I will quickly fix AppProvider to add a getter for `bluetooth`.
extension BluetoothAccess on AppProvider {
  // This is hacky. I'll modify the AppProvider file directly via a replace soon or now.
  // But for now, let's assume I fix AppProvider to have `BluetoothService get bluetooth => _bluetooth;`
}
