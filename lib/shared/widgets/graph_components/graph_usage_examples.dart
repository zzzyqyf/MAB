import 'package:flutter/material.dart';
import 'advanced_graph_architecture.dart';

/// Example page demonstrating the usage of the new graph architecture
/// This showcases how to implement OOP principles with minimal code repetition
class GraphDemoPage extends StatelessWidget {
  final String deviceId;
  
  const GraphDemoPage({super.key, required this.deviceId});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Device $deviceId - Sensor Graphs'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.thermostat), text: 'Temperature'),
              Tab(icon: Icon(Icons.water_drop), text: 'Humidity'),
              Tab(icon: Icon(Icons.lightbulb), text: 'Light'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Using factory pattern to create graphs
            GraphFactory.createGraph(
              deviceId: deviceId,
              type: GraphType.temperature,
            ),
            GraphFactory.createGraph(
              deviceId: deviceId,
              type: GraphType.humidity,
            ),
            GraphFactory.createGraph(
              deviceId: deviceId,
              type: GraphType.light,
            ),
          ],
        ),
      ),
    );
  }
}

/// Alternative implementation showing direct widget instantiation
class IndividualGraphPage extends StatelessWidget {
  final String deviceId;
  final GraphType graphType;
  
  const IndividualGraphPage({
    super.key,
    required this.deviceId,
    required this.graphType,
  });

  @override
  Widget build(BuildContext context) {
    // Direct instantiation using specific widget classes
    late BaseGraphWidget graphWidget;
    
    switch (graphType) {
      case GraphType.temperature:
        graphWidget = TemperatureGraphWidget(deviceId: deviceId);
        break;
      case GraphType.humidity:
        graphWidget = HumidityGraphWidget(deviceId: deviceId);
        break;
      case GraphType.light:
        graphWidget = LightGraphWidget(deviceId: deviceId);
        break;
    }
    
    return graphWidget;
  }
}

/// Usage examples in routing:
class GraphRoutes {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    final args = settings.arguments as Map<String, dynamic>?;
    
    switch (settings.name) {
      case '/temperature':
        return MaterialPageRoute(
          builder: (_) => TemperatureGraphWidget(
            deviceId: args?['deviceId'] ?? '',
          ),
        );
      case '/humidity':
        return MaterialPageRoute(
          builder: (_) => HumidityGraphWidget(
            deviceId: args?['deviceId'] ?? '',
          ),
        );
      case '/light':
        return MaterialPageRoute(
          builder: (_) => LightGraphWidget(
            deviceId: args?['deviceId'] ?? '',
          ),
        );
      case '/graphs':
        return MaterialPageRoute(
          builder: (_) => GraphDemoPage(
            deviceId: args?['deviceId'] ?? '',
          ),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Route not found')),
          ),
        );
    }
  }
}
