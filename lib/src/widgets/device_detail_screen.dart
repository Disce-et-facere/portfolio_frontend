import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; // For graphing
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:amplify_flutter/amplify_flutter.dart';
import '../../models/telemetry.dart';

class DeviceDetailScreen extends StatefulWidget {
  final String deviceId;
  final String ownerID;

  const DeviceDetailScreen({
    super.key,
    required this.deviceId,
    required this.ownerID,
  });

  @override
  State<DeviceDetailScreen> createState() => _DeviceDetailScreenState();
}

class _DeviceDetailScreenState extends State<DeviceDetailScreen> {
  late Future<List<telemetry>> _deviceDataFuture;

  @override
  void initState() {
    super.initState();
    _deviceDataFuture = _fetchDeviceData(widget.deviceId, widget.ownerID);
  }

  Future<List<telemetry>> _fetchDeviceData(String deviceId, String ownerID) async {
    debugPrint('Fetching telemetry for deviceId: $deviceId and ownerID: $ownerID using GSI');
    try {
      final request = GraphQLRequest<String>(
        document: '''
          query ListTelemetryByOwnerAndDevice(
            \$ownerID: String!
            \$device_id: ModelStringKeyConditionInput
            \$sortDirection: ModelSortDirection
            \$limit: Int
          ) {
            listTelemetryByOwnerAndDevice(
              ownerID: \$ownerID
              device_id: \$device_id
              sortDirection: \$sortDirection
              limit: \$limit
            ) {
              items {
                device_id
                timestamp
                ownerID
                deviceData
              }
            }
          }
        ''',
        variables: {
          'ownerID': ownerID,
          'device_id': {'eq': deviceId},
          'sortDirection': 'ASC',
          'limit': 50,
        },
      );

      debugPrint('GraphQL Request Variables: ${request.variables}');

      final response = await Amplify.API.query(request: request).response;

      debugPrint('Response: ${response.data}');
      debugPrint('Errors: ${response.errors}');

      if (response.data != null) {
        final responseData = jsonDecode(response.data!)['listTelemetryByOwnerAndDevice']['items'];
        final telemetryItems = responseData.map<telemetry>((item) => telemetry.fromJson(item)).toList();

        telemetryItems.sort((a, b) => a.timestamp.compareTo(b.timestamp));

        debugPrint('Fetched telemetry items (sorted): ${telemetryItems.length}');
        return telemetryItems;
      } else {
        debugPrint('No data returned for ownerID: $ownerID and deviceId: $deviceId');
        return [];
      }
    } catch (e) {
      debugPrint('Error fetching telemetry data: $e');
      throw Exception('Error fetching telemetry data');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Device Details: ${widget.deviceId}'),
      ),
      body: FutureBuilder<List<telemetry>>(
        future: _deviceDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No data available for this device.'));
          }

          final List<telemetry> telemetryData = snapshot.data!;

          final Map<String, List<DataPoint>> groupedData = {};

          for (final item in telemetryData) {
            final timestamp = item.timestamp.toSeconds();
            final measurements = jsonDecode(item.deviceData) as Map<String, dynamic>;

            measurements.forEach((key, value) {
              if (!key.endsWith('-unit')) {
                groupedData.putIfAbsent(key, () => []);
                groupedData[key]!.add(DataPoint(
                  timestamp: DateTime.fromMillisecondsSinceEpoch(timestamp * 1000),
                  value: value.toDouble(),
                ));
              }
            });
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: groupedData.keys.length,
            itemBuilder: (context, index) {
              final measurementType = groupedData.keys.elementAt(index);
              final unit = telemetryData.firstWhere(
                    (item) =>
                        (jsonDecode(item.deviceData) as Map<String, dynamic>)
                            .containsKey('$measurementType-unit'),
                    orElse: () => telemetry(
                      device_id: '',
                      timestamp: telemetryData.first.timestamp,
                      ownerID: '',
                      deviceData: '{}',
                    ),
                  )
                  .deviceData;
              final unitValue = jsonDecode(unit)['$measurementType-unit'] ?? '';

              final points = groupedData[measurementType]!;

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$measurementType ($unitValue)',
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
                                  interval: points.length > 6 ? (points.length ~/ 6).toDouble() : 1,
                                  getTitlesWidget: (value, meta) {
                                    final timestamp = points[value.toInt()].timestamp;

                                    if (value == points.length - 1) {
                                      return Text(
                                        DateFormat('MM/dd').format(timestamp),
                                        style: const TextStyle(fontSize: 10),
                                      );
                                    } else if (value % (points.length ~/ 6).toDouble() == 0) {
                                      return Text(
                                        DateFormat('MM/dd').format(timestamp),
                                        style: const TextStyle(fontSize: 10),
                                      );
                                    }
                                    return const Text('');
                                  },
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                            ),
                            lineBarsData: [
                              LineChartBarData(
                                spots: points
                                    .asMap()
                                    .entries
                                    .map((entry) => FlSpot(
                                          entry.key.toDouble(),
                                          entry.value.value,
                                        ))
                                    .toList(),
                                isCurved: true,
                                barWidth: 2,
                                color: Colors.blue,
                                belowBarData: BarAreaData(show: false),
                              ),
                            ],
                            lineTouchData: LineTouchData(
                              touchTooltipData: LineTouchTooltipData(
                                tooltipRoundedRadius: 8,
                                tooltipPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                tooltipMargin: 16,
                                getTooltipItems: (touchedSpots) {
                                  return touchedSpots.map((spot) {
                                    final dataPoint = points[spot.x.toInt()];
                                    final timestamp = dataPoint.timestamp;
                                    final value = dataPoint.value;

                                    return LineTooltipItem(
                                      '${DateFormat('MM/dd/yyyy HH:mm:ss').format(timestamp)}\nValue: $value $unitValue',
                                      const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    );
                                  }).toList();
                                },
                                getTooltipColor: (spot) => Colors.black87,
                              ),
                            ),
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

class DataPoint {
  final DateTime timestamp;
  final double value;

  DataPoint({
    required this.timestamp,
    required this.value,
  });
}
