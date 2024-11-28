import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AddDeviceScreen extends StatefulWidget {
  const AddDeviceScreen({super.key});

  @override
  State<AddDeviceScreen> createState() => _AddDeviceScreenState();
}

class _AddDeviceScreenState extends State<AddDeviceScreen> {
  final TextEditingController _deviceNameController = TextEditingController();
  final TextEditingController _aliasController = TextEditingController();
  final List<Sensor> _sensors = [];
  bool _isLoading = false;

  // Load the API URL directly
  final String apiUrl = const String.fromEnvironment('ADD_DEVICE_API_URL');

  String? thingArn;
  String? iotEndpoint;
  String? certificatePem;
  String? privateKey;
  String? publicKey;

  Future<void> _addDevice() async {
    final deviceName = _deviceNameController.text.trim();
    final alias = _aliasController.text.trim();

    if (deviceName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a device name')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });
    
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'deviceName': deviceName,
          'alias': alias,
          'sensors': _sensors.map((sensor) => sensor.toJson()).toList(),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(jsonDecode(response.body));
        setState(() {
          thingArn = data['thingArn'];
          iotEndpoint = data['iotEndpoint'];
          certificatePem = data['certificates']['certificatePem'];
          privateKey = data['certificates']['privateKey'];
          publicKey = data['certificates']['publicKey'];
        });
      } else {
        throw Exception('Failed to add device');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding device: $e'),
            duration: Duration(seconds: 15), // Set the duration here
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Device'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (thingArn == null) ...[
                    TextField(
                      controller: _deviceNameController,
                      decoration: const InputDecoration(
                        labelText: 'Device Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _aliasController,
                      decoration: const InputDecoration(
                        labelText: 'Alias (optional)',
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
                  ] else ...[
                    Text('Thing ARN: $thingArn'),
                    Text('IoT Endpoint: $iotEndpoint'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        _downloadFile(certificatePem!, 'certificate.pem');
                      },
                      child: const Text('Download Certificate'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        _downloadFile(privateKey!, 'private.key');
                      },
                      child: const Text('Download Private Key'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        _downloadFile(publicKey!, 'public.key');
                      },
                      child: const Text('Download Public Key'),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  void _downloadFile(String content, String filename) {
    // Use a package like `flutter_file_saver` or `path_provider` to save the file
    print('Downloading $filename');
  }
}

class Sensor {
  String name;
  String dataType;

  Sensor({required this.name, required this.dataType});

  Map<String, dynamic> toJson() => {
        'name': name,
        'dataType': dataType,
      };
}