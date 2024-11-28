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
  bool _isLoading = false;

  // Load the API URL directly
  final String apiUrl = String.fromEnvironment('ADD_DEVICE_ENDPOINT');

  String? thingArn;
  String? iotEndpoint;
  String? certificatePem;
  String? privateKey;
  String? publicKey;

  Future<void> _addDevice() async {
    final deviceName = _deviceNameController.text.trim();

    if (deviceName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a device name')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final requestBody = jsonEncode({
      'deviceName': deviceName,
    });

    print('Sending POST request with body: $requestBody');

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: requestBody,
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          setState(() {
            thingArn = data['thingArn'];
            iotEndpoint = data['iotEndpoint'];
            certificatePem = data['certificates']['certificatePem'];
            privateKey = data['certificates']['privateKey'];
            publicKey = data['certificates']['publicKey'];
          });
        } catch (e) {
          throw Exception('Error parsing response JSON: $e');
        }
      } else {
        throw Exception('Failed to add device. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error during POST request: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding device: $e'),
            duration: const Duration(seconds: 15),
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
    print('Downloading $filename');
  }
}
