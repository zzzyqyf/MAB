# Graph Components Architecture

This directory contains a comprehensive, reusable graph architecture implementing advanced Object-Oriented Programming (OOP) principles for Flutter sensor data visualization.

## Architecture Overview

### Design Patterns Implemented

1. **Factory Pattern** - `GraphFactory` creates different graph types
2. **Strategy Pattern** - `IGraphConfiguration` defines different graph behaviors
3. **Template Method Pattern** - `BaseGraphState` provides common graph functionality
4. **Interface Segregation** - Separate interfaces for different concerns
5. **Dependency Injection** - Configuration injected into base classes

### OOP Principles Applied

- **Encapsulation**: Each component has well-defined responsibilities
- **Inheritance**: Common functionality shared through base classes
- **Polymorphism**: Different graph types behave differently while sharing interface
- **Abstraction**: Complex graph logic hidden behind simple interfaces

## Components

### Core Components

#### 1. `GraphAppBar`
Reusable AppBar component providing consistent styling across all graph screens.

```dart
GraphAppBar(
  deviceId: 'device123',
  isDeviceActive: true,
  title: 'Temperature Graph',
)
```

#### 2. `TimeRangeNavigator`
Navigation component for scrolling through time ranges with accessibility features.

```dart
TimeRangeNavigator(
  minX: 0,
  maxX: 3,
  onPrevious: () => navigatePrevious(),
  onNext: () => navigateNext(),
  cycleStartTime: startTime,
)
```

#### 3. `HistoricalDataButton`
Button component for loading historical data with consistent styling.

```dart
HistoricalDataButton(
  deviceId: 'device123',
  onDateSelected: (date, deviceId) => loadData(date, deviceId),
)
```

#### 4. `GraphContainer`
Container component providing consistent styling and layout for graphs.

```dart
GraphContainer(
  child: LineChart(chartData),
)
```

### Advanced Architecture

#### 1. `BaseGraphWidget` (Abstract)
Abstract base class for all graph widgets, enforcing consistent interface.

#### 2. `BaseGraphState` (Abstract)
Abstract state class providing common functionality:
- Data loading and saving
- Periodic data updates
- Cycle completion handling
- Navigation logic
- Touch interaction

#### 3. `IGraphConfiguration` (Interface)
Interface defining graph-specific configurations:
- Data keys
- Units
- Colors
- Storage box names
- Maximum values

#### 4. Graph Configuration Classes
Concrete implementations for different sensor types:
- `TemperatureGraphConfig`
- `HumidityGraphConfig`
- `LightGraphConfig`

#### 5. `GraphFactory`
Factory class for creating graph instances:

```dart
// Create temperature graph
final tempGraph = GraphFactory.createGraph(
  deviceId: 'device123',
  type: GraphType.temperature,
);
```

## Usage Examples

### Basic Usage (Legacy Components)

```dart
import 'package:your_app/shared/widgets/graph_components/graph_components.dart';

class MyGraphPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GraphAppBar(
        deviceId: 'device123',
        isDeviceActive: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: GraphContainer(
              child: YourChartWidget(),
            ),
          ),
          TimeRangeNavigator(
            minX: minX,
            maxX: maxX,
            onPrevious: () => {},
            onNext: () => {},
          ),
          HistoricalDataButton(
            deviceId: 'device123',
            onDateSelected: (date, deviceId) => {},
          ),
        ],
      ),
    );
  }
}
```

### Advanced Usage (New Architecture)

```dart
import 'package:your_app/shared/widgets/graph_components/graph_components.dart';

class SensorGraphsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Sensor Graphs'),
          bottom: TabBar(
            tabs: [
              Tab(text: 'Temperature'),
              Tab(text: 'Humidity'),
              Tab(text: 'Light'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            GraphFactory.createGraph(
              deviceId: 'device123',
              type: GraphType.temperature,
            ),
            GraphFactory.createGraph(
              deviceId: 'device123',
              type: GraphType.humidity,
            ),
            GraphFactory.createGraph(
              deviceId: 'device123',
              type: GraphType.light,
            ),
          ],
        ),
      ),
    );
  }
}
```

### Direct Widget Usage

```dart
// For specific graph types
TemperatureGraphWidget(deviceId: 'device123')
HumidityGraphWidget(deviceId: 'device123')  
LightGraphWidget(deviceId: 'device123')
```

## Benefits

### 1. Code Reusability
- Common UI components shared across all graphs
- Base functionality implemented once
- Configuration-driven customization

### 2. Maintainability
- Changes to common functionality affect all graphs
- Clear separation of concerns
- Type-safe configuration

### 3. Extensibility
- Easy to add new graph types
- New configurations can be added without changing existing code
- Factory pattern supports new graph types

### 4. Consistency
- Uniform UI/UX across all graphs
- Consistent behavior and interactions
- Standardized styling

### 5. Type Safety
- Enum-based graph types
- Interface-enforced configurations
- Compile-time error checking

## Migration Guide

### From Legacy Components

1. **Replace individual graph files** with factory-created widgets:
   ```dart
   // Old
   TempVsTimeGraph(deviceId: deviceId)
   
   // New
   GraphFactory.createGraph(deviceId: deviceId, type: GraphType.temperature)
   ```

2. **Update imports**:
   ```dart
   import 'package:your_app/shared/widgets/graph_components/graph_components.dart';
   ```

3. **Remove duplicate code** from legacy graph files

### Adding New Graph Types

1. **Create configuration class**:
   ```dart
   class PressureGraphConfig implements IGraphConfiguration {
     @override
     String get dataKey => 'pressure';
     @override
     String get unit => 'Pa';
     // ... implement other properties
   }
   ```

2. **Add to enum**:
   ```dart
   enum GraphType { temperature, humidity, light, pressure }
   ```

3. **Update factory**:
   ```dart
   case GraphType.pressure:
     return PressureGraphWidget(deviceId: deviceId);
   ```

4. **Create widget class**:
   ```dart
   class PressureGraphWidget extends BaseGraphWidget {
     @override
     IGraphConfiguration get configuration => PressureGraphConfig();
     
     @override
     BaseGraphState createState() => _PressureGraphState();
   }
   
   class _PressureGraphState extends BaseGraphState<PressureGraphWidget> {}
   ```

## File Structure

```
graph_components/
├── graph_components.dart              # Main export file
├── graph_app_bar.dart                # Reusable AppBar component
├── time_range_navigator.dart         # Time navigation component
├── historical_data_button.dart       # Historical data button
├── graph_container.dart              # Graph container styling
├── base_graph.dart                   # Basic base classes
├── advanced_graph_architecture.dart  # Advanced OOP architecture
├── graph_usage_examples.dart         # Usage examples
└── README.md                         # This documentation
```

## Best Practices

1. **Use Factory Pattern** for creating graphs in new code
2. **Extend BaseGraphWidget** for new graph types
3. **Implement IGraphConfiguration** for graph-specific settings
4. **Follow naming conventions** (GraphType enum values)
5. **Test configuration classes** independently
6. **Document custom configurations** with examples

## Performance Considerations

- Base classes handle common optimizations
- Timer management prevents memory leaks
- Efficient data loading and caching
- Proper widget lifecycle management

## Accessibility Features

- Voice announcements for time range navigation
- Touch feedback for data points
- High contrast support
- Screen reader compatibility
