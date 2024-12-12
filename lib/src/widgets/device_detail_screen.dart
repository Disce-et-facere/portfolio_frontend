import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; // For graphing
import 'package:amplify_api/amplify_api.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:amplify_flutter/amplify_flutter.dart';
import '../../models/telemetry.dart';

class DeviceDetailScreen extends StatefulWidget {
  final String deviceId;
  final String ownerID; // Add ownerID parameter

  const DeviceDetailScreen({
    super.key,
    required this.deviceId,
    required this.ownerID, // Add ownerID
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
    debugPrint('Fetching telemetry for deviceId: $deviceId and ownerID: $ownerID');
    try {
      final request = ModelQueries.list(
        telemetry.classType,
        where: telemetry.DEVICE_ID.eq(deviceId).and(telemetry.OWNERID.eq(ownerID)), // Filter by deviceId and ownerID
        limit: 50, // Fetch only the latest 50 items
      );

      debugPrint('Query: ${request.variables}');

      final response = await Amplify.API.query(request: request).response;

      debugPrint('Response: ${response.data}');
      debugPrint('Errors: ${response.errors}');

      if (response.data != null) {
        final telemetryItems = response.data!.items.whereType<telemetry>().toList();

        // Sort by timestamp descending (newest first)
        telemetryItems.sort((a, b) => b.timestamp.compareTo(a.timestamp));

        debugPrint('Filtered telemetry items: ${telemetryItems.length}');
        return telemetryItems;
      } else {
        debugPrint('No data returned for deviceId: $deviceId and ownerID: $ownerID');
        throw Exception('Failed to fetch data for deviceId: $deviceId');
      }
    } catch (e) {
      debugPrint('Error fetching device data: $e');
      throw Exception('Error fetching device data');
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

          // Group data by measurement type for the graph
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
                                    return Text(DateFormat('MM/dd').format(timestamp));
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

                                    // Format the tooltip to include timestamp and value
                                    return LineTooltipItem(
                                      '${DateFormat('MM/dd/yyyy HH:mm:ss').format(timestamp)}\nValue: $value $unitValue',
                                      const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    );
                                  }).toList();
                                },
                                getTooltipColor: (spot) => Colors.black87, // Set tooltip background color
                              ),
                              touchCallback: (FlTouchEvent event, LineTouchResponse? response) {
                                if (response != null && response.lineBarSpots != null) {
                                  final touchedSpot = response.lineBarSpots!.first;
                                  final timestamp = points[touchedSpot.x.toInt()].timestamp;
                                  final value = points[touchedSpot.x.toInt()].value;
                                  debugPrint(
                                    'Hovered over: ${DateFormat('MM/dd/yyyy HH:mm:ss').format(timestamp)}, Value: $value $unitValue',
                                  );
                                }
                              },
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
