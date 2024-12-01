import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';

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
  final String apiEndpoint = 'https://i54j20zyi1.execute-api.eu-central-1.amazonaws.com/amplify-d1oceu7bffyxdg-ma-createDeviceFunctionlamb-oG9vHtl2RenF';
  final String apiUrl = const String.fromEnvironment('ADD_DEVICE_ENDPOINT');

  String? thingArn;
  String? iotEndpoint;
  String? certificatePem;
  String? privateKey;
  String? publicKey;

Future<String> _getAccessToken() async {
  try {
    final cognitoPlugin = Amplify.Auth.getPlugin(AmplifyAuthCognito.pluginKey);

    final cognitoSession = await cognitoPlugin.fetchAuthSession();

    if (!cognitoSession.isSignedIn) {
      debugPrint('User is not signed in.');
      return "NOT SIGNED IN!";
    }
    final tokens = cognitoSession.userPoolTokensResult.value;
    final String accessToken = tokens.accessToken.raw;

    debugPrint('Access Token: $accessToken');

    return accessToken;

  } on AuthException catch (e) {
    debugPrint('Error fetching access token: ${e.message}');
    return "NO ACCESS TOKEN!";
  }
}

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

    try {
      final String accessToken = await _getAccessToken();
      final response = await http.post(
        Uri.parse(apiEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
            "deviceName": deviceName
      }),
      );
      
      debugPrint('Response received - Status: ${response.statusCode}, Body: ${response.body}',);

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
          debugPrint('Error parsing response JSON: $e');
          throw Exception('Error parsing response JSON: $e');
        }
      } else {
        debugPrint('Failed to add device. Status: ${response.statusCode}');
        throw Exception('Failed to add device. Status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error adding device: $e');
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
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Downloading $filename'),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }
}
