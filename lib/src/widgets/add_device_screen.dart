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
  String? ownerId;
  final String apiUrl = 'https://i54j20zyi1.execute-api.eu-central-1.amazonaws.com';

  String? deviceId;
  String? iotEndpoint;
  String? telemetryTopic;
  String? shadowGetTopic;
  String? shadowUpdateTopic;
  String? shadowDeltaTopic;

  Future<String?> _getOwnerId() async {
    try {
      final attributes = await Amplify.Auth.fetchUserAttributes();

      // Look for "custom:OwnerID" (case-sensitive)
      final ownerAttr = attributes.firstWhere(
        (attr) => attr.userAttributeKey == CognitoUserAttributeKey.custom('OwnerID'),
        orElse: () => AuthUserAttribute(
          userAttributeKey: CognitoUserAttributeKey.custom('OwnerID'),
          value: '',
        ),
      );

      return ownerAttr.value.isNotEmpty ? ownerAttr.value : null;
    } catch (e) {
      debugPrint('Error fetching OwnerID: $e');
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

    if (ownerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OwnerID is not set. Cannot add device.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final String accessToken = await _getAccessToken();
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({"deviceName": deviceName}),
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
        });
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
  void initState() {
    super.initState();
    _fetchOwnerId();
  }

  Future<void> _fetchOwnerId() async {
    final fetchedOwnerId = await _getOwnerId();
    setState(() {
      ownerId = fetchedOwnerId;
    });
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
                    _buildResponseBox(
                      'DeviceID',
                      deviceId!,
                    ),
                    _buildResponseBox(
                      'OwnerID',
                      ownerId ?? 'Unavailable',
                    ),
                    _buildResponseBox(
                      'MQTT Endpoint',
                      iotEndpoint ?? 'Unavailable',
                    ),
                    _buildResponseBox(
                      'Telemetry Topic',
                      telemetryTopic ?? 'Unavailable',
                    ),
                    _buildResponseBox(
                      'Shadow Get Topic',
                      shadowGetTopic ?? 'Unavailable',
                    ),
                    _buildResponseBox(
                      'Shadow Update Topic',
                      shadowUpdateTopic ?? 'Unavailable',
                    ),
                    _buildResponseBox(
                      'Shadow Delta Topic',
                      shadowDeltaTopic ?? 'Unavailable',
                    ),
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

  Future<String> _getAccessToken() async {
    try {
      final cognitoPlugin = Amplify.Auth.getPlugin(AmplifyAuthCognito.pluginKey);
      final cognitoSession = await cognitoPlugin.fetchAuthSession();
      final tokens = cognitoSession.userPoolTokensResult.value;
      return tokens.accessToken.raw;
    } catch (e) {
      debugPrint('Error fetching access token: $e');
      return '';
    }
  }
}
