import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/graph_api_viewmodel.dart';
import '../widgets/date_selector_widget.dart';
import '../widgets/api_graph_widget.dart';
import '../../../../shared/services/TextToSpeech.dart';
import '../../domain/entities/sensor_graph_data.dart';

/// Base class for sensor detail pages with API graph
abstract class BaseSensorDetailPage extends StatefulWidget {
  final String deviceId;
  final String mqttId; // MAC address
  final String title;

  const BaseSensorDetailPage({
    Key? key,
    required this.deviceId,
    required this.mqttId,
    required this.title,
  }) : super(key: key);
}

abstract class BaseSensorDetailPageState<T extends BaseSensorDetailPage> extends State<T> {
  DateTime _selectedDate = DateTime.now();
  Timer? _refreshTimer;
  bool _showCalendar = false;

  // Abstract methods to be implemented by subclasses
  String get sensorType; // 'humidity', 'temperature', or 'water'
  Color get chartColor;
  IconData get icon;
  String get unit;
  double? get minY;
  double? get maxY;
  List<DataPoint> getDataPoints(SensorGraphData graphData);

  @override
  void initState() {
    super.initState();
    // Load data after first frame to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadGraphData();
      }
    });
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    // Auto-refresh every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _loadGraphData();
      }
    });
  }

  void _loadGraphData() {
    final viewModel = Provider.of<GraphApiViewModel>(context, listen: false);
    
    // Calculate time range for selected date (24 hours)
    final startTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      0,
      0,
      0,
    );
    
    final endTime = startTime.add(const Duration(days: 1));

    // Remove colons from MAC address (94B97EC04AD4 format expected)
    final controllerId = widget.mqttId.replaceAll(':', '');
    
    debugPrint('📊 Loading $sensorType data for controller: $controllerId');
    
    viewModel.fetchGraphData(
      controllerId: controllerId,
      startTime: startTime,
      endTime: endTime,
    );
  }

  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
      _showCalendar = false;
    });
    _loadGraphData();
    TextToSpeech.speak('Selected ${_formatDate(date)}');
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        leading: Container(
          margin: const EdgeInsets.all(8),
          child: Material(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => Navigator.of(context).pop(),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
        title: Text(
          widget.title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: chartColor,
        elevation: 0,
      ),
      body: Consumer<GraphApiViewModel>(
        builder: (context, viewModel, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date display with calendar button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selected Date',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(_selectedDate),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _showCalendar = !_showCalendar;
                        });
                      },
                      icon: Icon(_showCalendar ? Icons.close : Icons.calendar_today, size: 20),
                      label: Text(_showCalendar ? 'Close' : 'Select Date'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: chartColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),

                // Calendar (collapsible)
                if (_showCalendar) ...[
                  DateSelectorWidget(
                    initialDate: _selectedDate,
                    onDateSelected: _onDateSelected,
                  ),
                  const SizedBox(height: 16),
                ],

                // Graph container
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '$sensorType Graph',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (viewModel.isLoading)
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      if (viewModel.hasError)
                        _buildErrorWidget(viewModel.errorMessage)
                      else if (viewModel.hasData && viewModel.graphData != null)
                        ApiGraphWidget(
                          dataPoints: getDataPoints(viewModel.graphData!),
                          title: sensorType,
                          unit: unit,
                          lineColor: chartColor,
                          minY: minY,
                          maxY: maxY,
                        )
                      else if (!viewModel.isLoading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: Text('No data available'),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorWidget(String message) {
    // Check if this is an SSL/ALPN error
    final isSSLError = message.contains('Handshake') || 
                       message.contains('ALPN') || 
                       message.contains('INVALID_ALPN_PROTOCOL');
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            Icon(
              isSSLError ? Icons.security : Icons.error_outline,
              size: 64,
              color: isSSLError ? Colors.orange[400] : Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              isSSLError ? 'Connection Issue' : 'Error loading data',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
            if (isSSLError) ...[
              Text(
                'The API server connection requires advanced SSL/TLS protocols.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This may work better on a physical device.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ] else ...[
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadGraphData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: chartColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
