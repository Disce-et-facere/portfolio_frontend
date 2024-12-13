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
      appBar: AppBar(title: const Text('Stockholm Weather - Forecast')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Temperature Forecast (°C)',
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
                        interval: (weeklyData.length / 6).ceil().toDouble(),
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
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      barWidth: 2,
                      color: Colors.blue,
                      belowBarData: BarAreaData(show: false),
                      dotData: FlDotData(show: true),
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
                          final rawDate = weeklyData[index]['date'];
                          final date = DateTime.parse(rawDate);
                          final temperature = weeklyData[index]['temperature'];
                          final time = DateFormat('HH:mm:ss').format(date); // Format timestamp

                          return LineTooltipItem(
                            '${DateFormat('MM/dd/yyyy').format(date)} $time\nTemp: $temperature°C',
                            const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          );
                        }).toList();
                      },
                      getTooltipColor: (spot) => Colors.black87,
                    ),
                    touchCallback: (FlTouchEvent event, LineTouchResponse? response) {
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
