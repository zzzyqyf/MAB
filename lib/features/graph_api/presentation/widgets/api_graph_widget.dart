import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/sensor_graph_data.dart';

/// Widget to display graph data using fl_chart
class ApiGraphWidget extends StatelessWidget {
  final List<DataPoint> dataPoints;
  final String title;
  final String unit;
  final Color lineColor;
  final double? minY;
  final double? maxY;

  const ApiGraphWidget({
    Key? key,
    required this.dataPoints,
    required this.title,
    required this.unit,
    required this.lineColor,
    this.minY,
    this.maxY,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (dataPoints.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No data available for selected date',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    // Convert data points to FlSpot (x = hours from midnight, y = value)
    final spots = _convertToSpots(dataPoints);
    
    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      child: LineChart(
        LineChartData(
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: lineColor,
              barWidth: 3,
              dotData: FlDotData(
                show: spots.length < 50, // Show dots only if not too many points
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: lineColor,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                color: lineColor.withOpacity(0.1),
              ),
            ),
          ],
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toStringAsFixed(0),
                    style: const TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  // Show only 3 labels: 00:00, 12:00, 24:00
                  if (value == 0) {
                    return const Padding(
                      padding: EdgeInsets.only(top: 8.0),
                      child: Text(
                        '00:00',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    );
                  } else if (value == 12) {
                    return const Padding(
                      padding: EdgeInsets.only(top: 8.0),
                      child: Text(
                        '12:00',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    );
                  } else if (value == 24) {
                    return const Padding(
                      padding: EdgeInsets.only(top: 8.0),
                      child: Text(
                        '24:00',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: false,
          ),
          borderData: FlBorderData(
            show: false,
          ),
          minX: 0,
          maxX: 24,
          minY: minY,
          maxY: maxY,
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              tooltipBgColor: Colors.black87,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  // Find the closest data point to this x value (hour)
                  final targetHour = spot.x;
                  DataPoint? closestPoint;
                  double minDiff = double.infinity;
                  
                  for (var point in dataPoints) {
                    final pointHour = point.time.hour + (point.time.minute / 60.0);
                    final diff = (pointHour - targetHour).abs();
                    if (diff < minDiff) {
                      minDiff = diff;
                      closestPoint = point;
                    }
                  }
                  
                  if (closestPoint == null) return null;
                  
                  return LineTooltipItem(
                    '${closestPoint.value.toStringAsFixed(1)}$unit\n${DateFormat('HH:mm').format(closestPoint.time)}',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }

  List<FlSpot> _convertToSpots(List<DataPoint> points) {
    // Convert time to hours from midnight (0-24)
    return points.map((point) {
      final hour = point.time.hour + (point.time.minute / 60.0) + (point.time.second / 3600.0);
      return FlSpot(hour, point.value);
    }).toList();
  }
}
