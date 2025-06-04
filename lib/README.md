# PlantCare Hubs - MVVM Architecture

This Flutter project follows the **MVVM (Model-View-ViewModel)** architecture pattern combined with **Clean Architecture** principles for better maintainability, testability, and scalability.

## 📁 Project Structure

```
lib/
├── core/                          # Core functionality shared across features
│   ├── constants/                 # App-wide constants
│   │   ├── app_constants.dart
│   │   ├── app_theme.dart
│   │   └── firebase_options.dart
│   ├── errors/                    # Error handling
│   │   └── failures.dart
│   ├── network/                   # Network utilities
│   ├── platform/                  # Platform-specific code
│   └── usecases/                  # Base use case classes
│       └── usecase.dart
├── features/                      # Feature-based organization
│   ├── authentication/           # Authentication feature
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   ├── models/
│   │   │   └── repositories/
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   ├── repositories/
│   │   │   └── usecases/
│   │   └── presentation/
│   │       ├── pages/
│   │       ├── viewmodels/
│   │       └── widgets/
│   ├── dashboard/                 # Dashboard feature
│   ├── device_management/         # Device management feature
│   ├── notifications/             # Notifications feature
│   ├── profile/                   # User profile feature
│   └── registration/              # Device registration feature
├── shared/                        # Shared components across features
│   ├── services/                  # Shared services
│   │   ├── TextToSpeech.dart
│   │   ├── mqttservice.dart
│   │   └── mqttTests/
│   ├── utils/                     # Utility functions
│   └── widgets/                   # Reusable UI components
│       └── Navbar.dart
├── injection_container.dart       # Dependency injection setup
└── main.dart                      # App entry point
```

## 🏗️ Architecture Layers

### 1. **Presentation Layer**
- **Pages**: Complete screens/pages of the app
- **ViewModels**: Business logic and state management using Provider/ChangeNotifier
- **Widgets**: Reusable UI components specific to features

### 2. **Domain Layer** (Business Logic)
- **Entities**: Core business objects (pure Dart classes)
- **Repositories**: Abstract interfaces for data operations
- **Use Cases**: Single responsibility business operations

### 3. **Data Layer**
- **Models**: Data transfer objects with JSON/Hive serialization
- **Data Sources**: Abstract and concrete implementations for data access
- **Repositories**: Concrete implementations of domain repositories

## 🔧 Key Components

### Dependency Injection
- Uses `get_it` package for service locator pattern
- All dependencies are registered in `injection_container.dart`
- ViewModels are provided through Provider

### State Management
- **Provider** + **ChangeNotifier** for reactive state management
- ViewModels extend ChangeNotifier for state updates
- Clear separation between UI state and business logic

### Data Persistence
- **Hive** for local data storage
- **Firebase** for cloud services
- Repository pattern for data abstraction

### Error Handling
- Custom `Failure` classes for different error types
- Either monad pattern for handling success/error states
- Centralized error handling in ViewModels

## 🚀 Getting Started

### 1. Initialize Dependencies
```dart
// All dependencies are automatically initialized in main.dart
await di.init();
await di.initializeHive();
```

### 2. Using ViewModels
```dart
// In your widget
Consumer<DeviceViewModel>(
  builder: (context, viewModel, child) {
    if (viewModel.isLoading) {
      return CircularProgressIndicator();
    }
    
    if (viewModel.hasError) {
      return Text(viewModel.errorMessage);
    }
    
    return ListView.builder(
      itemCount: viewModel.devices.length,
      itemBuilder: (context, index) {
        final device = viewModel.devices[index];
        return DeviceCard(device: device);
      },
    );
  },
)
```

### 3. Adding New Features

1. Create feature directory under `features/`
2. Implement the three layers (data, domain, presentation)
3. Add dependencies to `injection_container.dart`
4. Create ViewModels for state management
5. Build UI using the ViewModels

## 📦 Dependencies

Key packages used in this architecture:

- `provider` - State management
- `get_it` - Dependency injection
- `dartz` - Functional programming (Either, etc.)
- `hive` - Local database
- `firebase_core` - Firebase services

## 🎯 Benefits

1. **Separation of Concerns**: Each layer has a specific responsibility
2. **Testability**: Easy to unit test business logic
3. **Maintainability**: Clean code structure makes it easy to maintain
4. **Scalability**: Easy to add new features without affecting existing code
5. **Reusability**: Shared components can be reused across features

## 🔄 Data Flow

1. **UI** triggers an action (button press, etc.)
2. **ViewModel** receives the action and calls appropriate **Use Case**
3. **Use Case** coordinates with **Repository**
4. **Repository** fetches data from **Data Source**
5. Data flows back through the layers
6. **ViewModel** updates state and notifies **UI**
7. **UI** rebuilds with new state

This architecture ensures a clean, maintainable, and scalable codebase for the PlantCare Hubs application.
