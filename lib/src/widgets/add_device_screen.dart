import 'package:flutter/material.dart';

class DeviceFormScreen extends StatefulWidget {
  const DeviceFormScreen({super.key});

  @override
  State<DeviceFormScreen> createState() => _DeviceFormScreenState();
}

class _DeviceFormScreenState extends State<DeviceFormScreen> {
  final TextEditingController _deviceNameController = TextEditingController();
  final TextEditingController _deviceTypeController = TextEditingController();

  Future<void> _addDevice() async {
    final deviceName = _deviceNameController.text.trim();
    final deviceType = _deviceTypeController.text.trim();

    if (deviceName.isEmpty || deviceType.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    // Call your API or backend function to add the device
    try {
      // Simulate success for now
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Device $deviceName added successfully')),
      );

      // Clear fields and navigate back
      _deviceNameController.clear();
      _deviceTypeController.clear();
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding device: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Device'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _deviceNameController,
              decoration: const InputDecoration(
                labelText: 'Device Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _deviceTypeController,
              decoration: const InputDecoration(
                labelText: 'Device Type',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                onPressed: _addDevice,
                child: const Text('Add Device'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _deviceNameController.dispose();
    _deviceTypeController.dispose();
    super.dispose();
  }
}
