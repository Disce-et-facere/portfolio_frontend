import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import '../settings/settings_controller.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import '../widgets/toolbar.dart';
import '../widgets/device_detail_screen.dart';
import '../../models/telemetry.dart'; // Generated telemetry model
import '../../models/ModelProvider.dart'; // Required for ModelQueries

class Dashboard extends StatefulWidget {
  const Dashboard({
    super.key,
    required this.settingsController,
  });

  final SettingsController settingsController;

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  String? userEmail;
  String ownerId = '';
  bool isLoading = true;
  List<telemetry> devices = [];
  Map<String, String> deviceStatuses = {};
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _fetchUserEmail();
    _fetchOwnerId();
  }

  Future<void> _fetchUserEmail() async {
    try {
      final attributes = await Amplify.Auth.fetchUserAttributes();
      final emailAttribute = attributes.firstWhere(
        (attr) => attr.userAttributeKey.key == 'email',
        orElse: () => const AuthUserAttribute(
          userAttributeKey: CognitoUserAttributeKey.email,
          value: 'Unknown',
        ),
      );
      setState(() {
        userEmail = emailAttribute.value;
      });
    } catch (e) {
      debugPrint('Error fetching user email: $e');
      setState(() {
        userEmail = 'Unknown';
      });
    }
  }

  Future<void> _fetchOwnerId() async {
    try {
      final attributes = await Amplify.Auth.fetchUserAttributes();
      final ownerIDAttribute = attributes.firstWhere(
        (attr) => attr.userAttributeKey == CognitoUserAttributeKey.custom('OwnerID'),
        orElse: () => const AuthUserAttribute(
          userAttributeKey: CognitoUserAttributeKey.custom('OwnerID'),
          value: '',
        ),
      );
      setState(() {
        ownerId = ownerIDAttribute.value;
      });
      if (ownerId.isNotEmpty) {
      debugPrint('OwnerID is not empty, calling _fetchDevices...');
      await _fetchDevices();
      } else {
        debugPrint('OwnerID is empty, skipping _fetchDevices.');
      }
    } catch (e) {
      debugPrint('Error fetching OwnerID: $e');
    }
  }

  Future<void> _fetchDevices() async {
    debugPrint('Starting _fetchDevices...');
    debugPrint('OwnerID passed to _fetchDevices: $ownerId');
    try {
      final query = '''
        query ListDevicesByOwnerID(
          \$ownerID: String!
          \$sortDirection: ModelSortDirection
        ) {
          listDevicesByOwnerID(
            ownerID: \$ownerID
            sortDirection: \$sortDirection
          ) {
            items {
              device_id
              timestamp
              deviceData
            }
          }
        }
      ''';

      final response = await Amplify.API.query<String>(
        request: GraphQLRequest<String>(
          document: query,
          variables: {
            'ownerID': ownerId,
            'sortDirection': 'DESC', // Ensure we get the most recent items first
          },
        ),
      ).response;

      if (response.data != null) {
        final responseData = jsonDecode(response.data!)['listDevicesByOwnerID']['items'];
        debugPrint('Response data from _fetchDevices: $responseData');

        // Group devices by their `device_id` and fetch the latest telemetry
        final groupedDevices = <String, telemetry>{};
        for (var deviceData in responseData) {
          final device = telemetry.fromJson(deviceData);
          // If device_id already exists, keep only the latest telemetry (newest timestamp)
          if (!groupedDevices.containsKey(device.device_id) ||
              device.timestamp.compareTo(groupedDevices[device.device_id]!.timestamp) > 0) {
            groupedDevices[device.device_id] = device;
          }
        }

        setState(() {
          devices = groupedDevices.values.toList();
          debugPrint('Devices list updated in state: $devices');
        });

        // Fetch shadow data only for devices without a known status
        for (final device in devices) {
          if (!deviceStatuses.containsKey(device.device_id)) {
            await _fetchShadow(device.device_id);
          }
        }
      } else {
        debugPrint('No devices found.');
      }
    } catch (e) {
      debugPrint('Error fetching devices: $e');
    }
  }

  Future<void> _fetchShadow(String deviceId) async {
    debugPrint('Fetching shadow status for device: $deviceId');

    try {
      final response = await Amplify.API.query<String>(
        request: GraphQLRequest<String>(
          document: '''
            query FetchDeviceShadow(\$deviceId: String!) {
              fetchDeviceShadow(deviceId: \$deviceId) {
                deviceId
                status
              }
            }
          ''',
          variables: {'deviceId': deviceId},
        ),
      ).response;

      if (response.data != null) {
        final shadowData = jsonDecode(response.data!)['fetchDeviceShadow'];

        if (shadowData != null) {
          final status = shadowData['status'] ?? 'Unknown';
          setState(() {
            deviceStatuses[deviceId] = status; // Update device status
          });
          debugPrint('Updated status for device $deviceId: $status');
        } else {
          debugPrint('Shadow status for $deviceId is null.');
        }
      } else {
        debugPrint('No shadow data returned for device: $deviceId');
      }
    } catch (e) {
      debugPrint('Error fetching shadow for $deviceId: $e');
    }
  }

  Future<void> _deleteDevice(String deviceId, String ownerId) async {
    try {
      final request = GraphQLRequest<String>(
        document: '''
          mutation DeleteDevice(\$deviceId: String!, \$ownerId: String!) {
            deleteDevice(deviceId: \$deviceId, ownerId: \$ownerId) {
              message
            }
          }
        ''',
        variables: {
          'deviceId': deviceId,
          'ownerId': ownerId,
        },
      );

      final response = await Amplify.API.mutate(request: request).response;

      if (response.errors.isEmpty) {
        final message = jsonDecode(response.data!)['deleteDevice']['message'];

        // Check if the widget is still mounted before calling setState or showing a SnackBar
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

          setState(() {
            devices.removeWhere((device) => device.device_id == deviceId);
          });
        }
      } else {
        throw Exception(response.errors.first.message);
      }
    } catch (e) {
      debugPrint('Error deleting device: $e');

      // Check if the widget is still mounted before showing a SnackBar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }



  Future<void> _signOut() async {
    try {
      await Amplify.Auth.signOut();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Signed out successfully')),
      );

      Navigator.of(context).pushReplacementNamed('/login');
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: $e')),
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    _scrollController.jumpTo(
      _scrollController.offset - details.delta.dx,
    );
  }

  
  @override
  Widget build(BuildContext context) {
    final messages = [
      Message(content: 'Low battery on Device 1', type: MessageType.warning),
      Message(content: 'Temperature too high on Device 2', type: MessageType.alert),
      Message(content: 'Device 3 disconnected', type: MessageType.alert),
      Message(content: 'Firmware update available for Device 1', type: MessageType.warning),
    ];

    return Scaffold(
      appBar: Toolbar(
        username: userEmail ?? 'Loading...',
        siteName: 'D-Monitor',
        settingsController: widget.settingsController,
        onSignOut: _signOut,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/bg.jpg',
              fit: BoxFit.cover,
            ),
          ),
          Column(
            children: [
              const SizedBox(height: 16),
              Expanded(
                flex: 1, // Allocate space for DeviceCards
                child: GestureDetector(
                  onHorizontalDragUpdate: _onDragUpdate,
                  child: ListView.builder(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: devices.length,
                    itemBuilder: (context, index) {
                      final device = devices[index];
                      final status = deviceStatuses[device.device_id];

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: DeviceCard(
                          device: device,
                          status: status,
                          onDelete: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Confirm Deletion'),
                                content: const Text('Are you sure you want to delete this device?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );

                            if (confirmed == true) {
                              await _deleteDevice(device.device_id, ownerId);
                            }
                          },
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DeviceDetailScreen(
                                deviceId: device.device_id,
                                ownerID: ownerId,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                flex: 2, // Allocate space for the MessageBoard
                child: MessageBoard(messages: messages),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class DeviceCard extends StatelessWidget {
  final telemetry device;
  final String? status;
  final VoidCallback onDelete;
  final VoidCallback onTap; // Added onTap callback for card navigation

  const DeviceCard({
    super.key,
    required this.device,
    this.status,
    required this.onDelete,
    required this.onTap, // Required onTap callback
  });

  @override
  Widget build(BuildContext context) {
    final deviceDataMap = jsonDecode(device.deviceData) as Map<String, dynamic>;

    final currentStatus = (status == 'connected')
        ? 'Online'
        : (status == 'disconnected')
            ? 'Offline'
            : 'Unknown';

    final iconData = (currentStatus == 'Online') ? Icons.check_circle : Icons.error;
    final iconColor = (currentStatus == 'Online') ? Colors.green : Colors.red;
    final textColor = (currentStatus == 'Online') ? Colors.green : Colors.red;

    final formattedTimestamp = DateFormat('yyyy-MM-dd HH:mm:ss').format(
      DateTime.fromMillisecondsSinceEpoch(
        device.timestamp.toSeconds() * 1000,
      ).toLocal(),
    );

    return GestureDetector(
      onTap: onTap, // Trigger the onTap callback
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center, // Center content horizontally
            children: [
              Center(
                child: Column(
                  children: [
                    Icon(
                      iconData,
                      color: iconColor,
                      size: 36,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Device ID: ${device.device_id}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Status: $currentStatus',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Last Updated: $formattedTimestamp',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: deviceDataMap.entries.map((entry) {
                  if (entry.key == 'status' || entry.key.endsWith('-unit')) return Container();

                  final unitKey = '${entry.key}-unit';
                  final unit = deviceDataMap[unitKey] ?? '';

                  return Text(
                    '${entry.key}: ${entry.value} $unit',
                    style: const TextStyle(fontSize: 12),
                  );
                }).toList(),
              ),
              const Spacer(), // Push the delete button to the bottom
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red, // Text color
                  padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                ),
                icon: const Icon(Icons.delete),
                label: const Text('Delete Device'), // Add "Delete Device" text
                onPressed: onDelete, // Trigger the onDelete callback
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Message {
  final String content;
  final MessageType type;

  Message({required this.content, required this.type});
}

enum MessageType { warning, alert, info }

class MessageBoard extends StatelessWidget {
  final List<Message> messages;

  const MessageBoard({
    super.key,
    required this.messages,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Flexible(
      flex: 1, // Adjust flex value as needed
      child: Card(
        color: colorScheme.surface,
        margin: const EdgeInsets.all(16),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Message Board',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Divider(),
              Expanded(
                child: messages.isEmpty
                    ? const Center(
                        child: Text(
                          'No messages to display.',
                          style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                        ),
                      )
                    : ListView.builder(
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          final color = _getMessageColor(message.type);
                          final icon = _getMessageIcon(message.type);

                          return ListTile(
                            leading: Icon(icon, color: color),
                            title: Text(
                              message.content,
                              style: TextStyle(color: color),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getMessageColor(MessageType type) {
    switch (type) {
      case MessageType.warning:
        return Colors.orange;
      case MessageType.alert:
        return Colors.red;
      case MessageType.info:
        return Colors.blue;
      default:
        return Colors.black;
    }
  }

  IconData _getMessageIcon(MessageType type) {
    switch (type) {
      case MessageType.warning:
        return Icons.warning;
      case MessageType.alert:
        return Icons.error;
      case MessageType.info:
        return Icons.info;
      default:
        return Icons.message;
    }
  }
}