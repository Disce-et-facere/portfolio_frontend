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
  bool _isLoading = false;
  String? ownerId;
  final String apiUrl = 'https://i54j20zyi1.execute-api.eu-central-1.amazonaws.com';

  String? deviceId;
  String? iotEndpoint;
  String? telemetryTopic;
  String? shadowGetTopic;
  String? shadowUpdateTopic;
  String? shadowDeltaTopic;
  String? certificatePem;
  String? privateKey;
  String? caCertificate;

  @override
  void initState() {
    super.initState();
    _initializeOwnerId();
  }

  Future<void> _initializeOwnerId() async {
    await _fetchOwnerId();
  }

  Future<void> _fetchOwnerId() async {
    try {
      final attributes = await Amplify.Auth.fetchUserAttributes();
      final ownerAttr = attributes.firstWhere(
        (attr) => attr.userAttributeKey.key == 'custom:OwnerID',
        orElse: () => AuthUserAttribute(
          userAttributeKey: CognitoUserAttributeKey.custom('OwnerID'),
          value: '',
        ),
      );
      setState(() {
        ownerId = ownerAttr.value.isNotEmpty ? ownerAttr.value : null;
      });
      debugPrint('Fetched OwnerID: $ownerId');
    } catch (e) {
      debugPrint('Error fetching OwnerID: $e');
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

    if (ownerId == null || ownerId!.isEmpty) {
      _showSnackBar('OwnerID is not set. Cannot add device.');
      debugPrint('OwnerID not set: $ownerId');
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
          "ownerID": ownerId,
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

  Future<void> _downloadCertificate(String content, String fileName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(content);

      _showSnackBar('$fileName downloaded to ${directory.path}');
    } catch (e) {
      debugPrint('Error saving $fileName: $e');
      _showSnackBar('Error downloading $fileName: $e');
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
                        onPressed: ownerId != null && ownerId!.isNotEmpty
                            ? _addDevice
                            : null,
                        child: const Text('Add Device'),
                      ),
                    ),
                  ] else ...[
                    _buildResponseBox('DeviceID', deviceId!),
                    _buildResponseBox('OwnerID', ownerId ?? 'Unavailable'),
                    _buildResponseBox('MQTT Endpoint', iotEndpoint ?? 'Unavailable'),
                    ElevatedButton(
                      onPressed: certificatePem != null
                          ? () => _downloadCertificate(certificatePem!, 'device.crt')
                          : null,
                      child: const Text('Download Device Certificate (device.crt)'),
                    ),
                    ElevatedButton(
                      onPressed: privateKey != null
                          ? () => _downloadCertificate(privateKey!, 'private.key')
                          : null,
                      child: const Text('Download Private Key (private.key)'),
                    ),
                    ElevatedButton(
                      onPressed: caCertificate != null
                          ? () => _downloadCertificate(caCertificate!, 'ca.pem')
                          : null,
                      child: const Text('Download CA Certificate (ca.pem)'),
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
}