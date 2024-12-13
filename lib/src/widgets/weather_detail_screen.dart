import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class WeatherGraphScreen extends StatelessWidget {
  final List<Map<String, dynamic>> weeklyData;

  const WeatherGraphScreen({super.key, required this.weeklyData});

  @override
  Widget build(BuildContext context) {
    final spots = weeklyData
        .asMap()
        .entries
        .map((entry) => FlSpot(
              entry.key.toDouble(),
              double.parse(entry.value['temperature']),
            ))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Stockholm Weather - Last Week')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Last Week\'s Weather (°C)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 22,
                        interval: (weeklyData.length / 6).ceil().toDouble(), // Reduce overlapping labels
                        getTitlesWidget: (value, _) {
                          final dayIndex = value.toInt();
                          if (dayIndex < 0 || dayIndex >= weeklyData.length) {
                            return const SizedBox.shrink();
                          }
                          final date = DateTime.parse(weeklyData[dayIndex]['date']);
                          return Text('${date.day}/${date.month}');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false), // Remove Y-axis titles
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      barWidth: 2,
                      color: Colors.blue,
                      belowBarData: BarAreaData(show: false),
                      dotData: FlDotData(show: true), // Show dots on the line
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      tooltipRoundedRadius: 8,
                      tooltipPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      tooltipMargin: 16,
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final index = spot.x.toInt();
                          final date = DateTime.parse(weeklyData[index]['date']);
                          final temperature = weeklyData[index]['temperature'];

                          return LineTooltipItem(
                            '${DateFormat('MM/dd/yyyy').format(date)}\nTemp: $temperature°C',
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
                        final index = touchedSpot.x.toInt();
                        final date = DateTime.parse(weeklyData[index]['date']);
                        final temperature = weeklyData[index]['temperature'];
                        debugPrint(
                          'Hovered over: ${DateFormat('MM/dd/yyyy').format(date)}, Temp: $temperature°C',
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
  }
}
