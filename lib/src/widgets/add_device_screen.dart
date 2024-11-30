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
  final String apiUrl = const String.fromEnvironment('ADD_DEVICE_ENDPOINT');

  String? thingArn;
  String? iotEndpoint;
  String? certificatePem;
  String? privateKey;
  String? publicKey;

Future<String?> _getAccessToken() async {
  try {
    // Get the Cognito plugin
    final cognitoPlugin = Amplify.Auth.getPlugin(AmplifyAuthCognito.pluginKey);

    // Fetch the authentication session
    final cognitoSession = await cognitoPlugin.fetchAuthSession();

    // Debug: Print the session details
    debugPrint('Cognito Session: $cognitoSession');

    // Check if the user is signed in
    if (!cognitoSession.isSignedIn) {
      debugPrint('User is not signed in.');
      return null;
    }

    // Retrieve the access token
    final tokens = cognitoSession.userPoolTokensResult.value;
    final accessToken = tokens.accessToken.raw;

    // Debug: Print the access token
    debugPrint('Access Token: $accessToken');

    // Show the access token in a SnackBar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Access Token: $accessToken'),
        duration: const Duration(seconds: 10),
      ),
    );

    return accessToken;

  } on AuthException catch (e) {
    debugPrint('Error fetching access token: ${e.message}');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error fetching access token: ${e.message}'),
        duration: const Duration(seconds: 5),
      ),
    );
    return null;
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

    final requestBody = jsonEncode({
      "deviceName": deviceName,
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Sending POST request to $apiUrl with body: $requestBody',
          ),
          duration: const Duration(seconds: 5),
        ),
      );
    }

    try {
      // Fetch the access token
      final accessToken = await _getAccessToken();
      if (accessToken == null) {
        throw Exception('Access token could not be retrieved');
      }

      // Send POST request with Authorization header
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
          'Origin': 'https://main.d1oceu7bffyxdg.amplifyapp.com',
          'Access-Control-Request-Method': 'POST',
          'Access-Control-Request-Headers': 'authorization, content-type',
        },
        body: requestBody,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Response received - Status: ${response.statusCode}, Body: ${response.body}',
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      }

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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding device: $e'),
            duration: const Duration(seconds: 5),
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
