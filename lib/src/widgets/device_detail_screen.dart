import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; // For graphing
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/device.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';

class DeviceDetailScreen extends StatefulWidget {
  final Device device;

  const DeviceDetailScreen({super.key, required this.device});

  @override
  State<DeviceDetailScreen> createState() => _DeviceDetailScreenState();
}

class _DeviceDetailScreenState extends State<DeviceDetailScreen> {
  late Future<Map<String, GraphData>> _deviceDataFuture;

  @override
  void initState() {
    super.initState();
    _deviceDataFuture = _prepareData();
  }

  Future<Map<String, GraphData>> _prepareData() async {
    final String ownerId = await _getOwnerId();
    return _fetchDeviceData(widget.device.name, ownerId);
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

  Future<String> _getOwnerId() async {
    try {
      final attributes = await Amplify.Auth.fetchUserAttributes();
      final ownerAttr = attributes.firstWhere(
        (attr) => attr.userAttributeKey == CognitoUserAttributeKey.custom('OwnerID'),
        orElse: () => AuthUserAttribute(
          userAttributeKey: CognitoUserAttributeKey.custom('OwnerID'),
          value: '',
        ),
      );
      if (ownerAttr.value.isEmpty) {
        throw Exception('OwnerID is not set in Cognito user attributes.');
      }
      return ownerAttr.value;
    } catch (e) {
      debugPrint('Error fetching OwnerID: $e');
      throw Exception('Failed to fetch OwnerID.');
    }
  }

  Future<Map<String, GraphData>> _fetchDeviceData(String deviceName, String ownerId) async {
    const apiUrl = 'https://6zqrep9in8.execute-api.eu-central-1.amazonaws.com';
    final String accessToken = await _getAccessToken();

    try {
      final urlWithParams = Uri.parse('$apiUrl?deviceId=$deviceName&ownerID=$ownerId');
      final response = await http.get(
        urlWithParams,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final List<dynamic> data = responseData['data'];

        // Group data by measurement type
        final Map<String, List<DataPoint>> groupedData = {};

        for (var item in data) {
          final timestamp = item['timestamp'];
          final measurements = Map<String, dynamic>.from(item['data']);

          measurements.forEach((key, value) {
            if (!key.endsWith('-Unit')) {
              groupedData.putIfAbsent(key, () => []);
              groupedData[key]!.add(DataPoint(
                timestamp: DateTime.fromMillisecondsSinceEpoch(timestamp * 1000),
                value: value,
              ));
            }
          });
        }

        return groupedData.map((key, points) {
          final unit = data.firstWhere((item) => item['data'].containsKey('$key-Unit'),
              orElse: () => {})['data']['$key-Unit'] ?? '';
          return MapEntry(
            key,
            GraphData(
              measurementType: key,
              unit: unit,
              points: points,
            ),
          );
        });
      } else {
        throw Exception('Failed to fetch device data. Status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching device data: $e');
      throw Exception('Error fetching device data');
    }
  }

  Future<void> _deleteDevice() async {
    const deleteApiUrl = 'https://eipbe1x47k.execute-api.eu-central-1.amazonaws.com';
    final String accessToken = await _getAccessToken();
    final String ownerId = await _getOwnerId();

    try {
      final urlWithParams = Uri.parse('$deleteApiUrl?deviceId=${widget.device.name}&ownerID=$ownerId');
      final response = await http.delete(
        urlWithParams,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        debugPrint('Device deleted successfully.');
        if (mounted) {
          Navigator.pop(context);
        }
      } else {
        debugPrint('Failed to delete device. Status: ${response.statusCode}');
        throw Exception('Failed to delete device.');
      }
    } catch (e) {
      debugPrint('Error deleting device: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting device: $e')),
        );
      }
    }
  }


  Future<void> _showDeleteConfirmationDialog() async {
    final bool confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirm Deletion'),
            content: const Text('Are you sure you want to delete this device?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;

    if (confirmed) {
      await _deleteDevice();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Device Details: ${widget.device.name}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _showDeleteConfirmationDialog,
          ),
        ],
      ),
      body: FutureBuilder<Map<String, GraphData>>(
        future: _deviceDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No data available for this device.'));
          }

          final Map<String, GraphData> graphData = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: graphData.length,
            itemBuilder: (context, index) {
              final data = graphData.values.toList()[index];

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${data.measurementType} (${data.unit})',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 200,
                        child: LineChart(
                          LineChartData(
                            gridData: FlGridData(show: true),
                            titlesData: FlTitlesData(
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  interval: 1,
                                  getTitlesWidget: (value, meta) {
                                    final timestamp = data.points[value.toInt()].timestamp;
                                    return Text('${timestamp.month}/${timestamp.day}');
                                  },
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: true),
                              ),
                            ),
                            lineBarsData: [
                              LineChartBarData(
                                spots: data.points
                                    .asMap()
                                    .entries
                                    .map((entry) => FlSpot(
                                          entry.key.toDouble(),
                                          entry.value.value.toDouble(),
                                        ))
                                    .toList(),
                                isCurved: true,
                                barWidth: 2,
                                color: Colors.blue,
                                belowBarData: BarAreaData(show: false),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class GraphData {
  final String measurementType;
  final String unit;
  final List<DataPoint> points;

  GraphData({
    required this.measurementType,
    required this.unit,
    required this.points,
  });
}

class DataPoint {
  final DateTime timestamp;
  final double value;

  DataPoint({
    required this.timestamp,
    required this.value,
  });
}
