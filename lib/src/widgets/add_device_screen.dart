import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:html' as html; // Web-specific import

import 'package:amplify_flutter/amplify_flutter.dart';

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
      final request = GraphQLRequest<String>(
        document: '''
          mutation CreateDevice(\$deviceName: String!, \$updatePeriod: Int!) {
            createDevice(deviceName: \$deviceName, updatePeriod: \$updatePeriod) {
              thingArn
              iotEndpoint
              certificates {
                certificatePem
                privateKey
                publicKey
                caCertificate
              }
              shadow
            }
          }
        ''',
        variables: {
          'deviceName': deviceName,
          'updatePeriod': updatePeriod,
        },
      );

      final response = await Amplify.API.mutate(request: request).response;

      if (response.errors.isEmpty && response.data != null) {
        final data = jsonDecode(response.data!)['createDevice'];
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
        _showSnackBar('Device added successfully');
      } else {
        debugPrint('Failed to add device. Errors: ${response.errors}');
        _showSnackBar('Failed to add device. Check logs for details.');
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

  void _downloadCertificate(String content, String fileName) {
    try {
      final bytes = utf8.encode(content);
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..target = 'blank'
        ..download = fileName;
      anchor.click();
      html.Url.revokeObjectUrl(url);
      _showSnackBar('$fileName downloaded successfully.');
    } catch (e) {
      debugPrint('Error downloading $fileName: $e');
      _showSnackBar('Error downloading $fileName: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                      style: TextStyle(color: theme.colorScheme.error),
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
                    _buildResponseBox('DeviceID', deviceId!, theme),
                    _buildResponseBox('OwnerID', _ownerID, theme),
                    _buildResponseBox('MQTT Endpoint', iotEndpoint ?? 'Unavailable', theme),
                    _buildResponseBox('Telemetry Topic', telemetryTopic ?? 'Unavailable', theme),
                    _buildResponseBox('Shadow Get Topic', shadowGetTopic ?? 'Unavailable', theme),
                    _buildResponseBox(
                        'Shadow Update Topic', shadowUpdateTopic ?? 'Unavailable', theme),
                    _buildResponseBox(
                        'Shadow Delta Topic', shadowDeltaTopic ?? 'Unavailable', theme),
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

  Widget _buildResponseBox(String title, String content, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.2),
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
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(content, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}
