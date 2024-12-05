import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'dart:io';
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
  final TextEditingController _updatePeriodController = TextEditingController();
  String _ownerID = '';
  bool _isLoading = false;

  String? deviceId;
  String? iotEndpoint;
  String? telemetryTopic;
  String? shadowGetTopic;
  String? shadowUpdateTopic;
  String? shadowDeltaTopic;
  String? certificatePem;
  String? privateKey;
  String? caCertificate;

  final String apiUrl = 'https://i54j20zyi1.execute-api.eu-central-1.amazonaws.com/';

  @override
  void initState() {
    super.initState();
    _loadOwnerID();
  }

  Future<void> _loadOwnerID() async {
    try {
      final attributes = await Amplify.Auth.fetchUserAttributes();
      final ownerIDAttribute = attributes.firstWhere(
        (attr) => attr.userAttributeKey == CognitoUserAttributeKey.custom('custom:OwnerID'),
        orElse: () => const AuthUserAttribute(
          userAttributeKey: CognitoUserAttributeKey.custom('custom:OwnerID'),
          value: '',
        ),
      );
      setState(() {
        _ownerID = ownerIDAttribute.value;
      });
      debugPrint('Loaded OwnerID: $_ownerID');
    } catch (e) {
      debugPrint('Error loading OwnerID: $e');
    }
  }

  Future<void> _addDevice() async {
    final deviceName = _deviceNameController.text.trim();
    final updatePeriodStr = _updatePeriodController.text.trim();

    if (deviceName.isEmpty) {
      _showSnackBar('Please enter a device name');
      return;
    }

    if (updatePeriodStr.isEmpty || int.tryParse(updatePeriodStr) == null) {
      _showSnackBar('Please enter a valid update period');
      return;
    }

    if (_ownerID.isEmpty) {
      _showSnackBar('OwnerID is not set. Cannot add device.');
      debugPrint('OwnerID is empty.');
      return;
    }

    final updatePeriod = int.parse(updatePeriodStr);

    setState(() {
      _isLoading = true;
    });

    try {
      final accessToken = await _getAccessToken();
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          "deviceName": deviceName,
          "updatePeriod": updatePeriod,
          "ownerID": _ownerID,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final arnParts = (data['thingArn'] as String).split(':');
        setState(() {
          deviceId = arnParts.last;
          iotEndpoint = data['iotEndpoint'];
          telemetryTopic = '$deviceId/telemetry';
          shadowGetTopic = '\$aws/things/$deviceId/shadow/get';
          shadowUpdateTopic = '\$aws/things/$deviceId/shadow/update';
          shadowDeltaTopic = '\$aws/things/$deviceId/shadow/update/delta';
          certificatePem = data['certificates']['certificatePem'];
          privateKey = data['certificates']['privateKey'];
          caCertificate = data['certificates']['caCertificate'];
        });
        debugPrint('Device added successfully: $deviceId');
      } else {
        debugPrint('Failed to add device. Status: ${response.statusCode}');
        _showSnackBar('Failed to add device. Status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error adding device: $e');
      _showSnackBar('Error adding device: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<String> _getAccessToken() async {
    try {
      final cognitoPlugin = Amplify.Auth.getPlugin(AmplifyAuthCognito.pluginKey);
      final cognitoSession = await cognitoPlugin.fetchAuthSession();
      final tokens = cognitoSession.userPoolTokensResult.value;
      return tokens.accessToken.raw;
    } catch (e) {
      debugPrint('Error fetching access token: $e');
      throw Exception('Failed to fetch access token.');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Device'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (deviceId == null) ...[
                    Text(
                      'Owner ID: ${_ownerID.isNotEmpty ? _ownerID : "Not Set"}',
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _deviceNameController,
                      decoration: const InputDecoration(
                        labelText: 'Device Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _updatePeriodController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Update Period (seconds)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: ElevatedButton(
                        onPressed: _ownerID.isNotEmpty ? _addDevice : null,
                        child: const Text('Add Device'),
                      ),
                    ),
                  ] else ...[
                    _buildResponseBox('DeviceID', deviceId!),
                    _buildResponseBox('OwnerID', _ownerID),
                    _buildResponseBox('MQTT Endpoint', iotEndpoint ?? 'Unavailable'),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildResponseBox(String title, String content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Text(content),
          ),
        ],
      ),
    );
  }
}
