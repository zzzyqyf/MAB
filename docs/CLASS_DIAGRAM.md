```mermaid
classDiagram
    direction TB
    
    %% ==========================================
    %% CORE LAYER - Base Abstractions
    %% ==========================================
    
    class Failure {
        <<abstract>>
        +String? message
    }
    
    class ServerFailure {
        +String? message
    }
    
    class CacheFailure {
        +String? message
    }
    
    class NetworkFailure {
        +String? message
    }
    
    class ValidationFailure {
        +String message
    }
    
    Failure <|-- ServerFailure
    Failure <|-- CacheFailure
    Failure <|-- NetworkFailure
    Failure <|-- ValidationFailure
    
    class UseCase~Type, Params~ {
        <<abstract>>
        +call(Params params) Future~Either~Failure, Type~~
    }
    
    class UseCaseWithoutParams~Type~ {
        <<abstract>>
        +call() Future~Either~Failure, Type~~
    }
    
    %% ==========================================
    %% DEVICE MANAGEMENT FEATURE
    %% ==========================================
    
    namespace DeviceManagement {
        %% Domain Layer - Entities
        class Device {
            +String id
            +String name
            +String status
            +String sensorStatus
            +DateTime lastUpdated
            +Map~String, dynamic~? sensorData
            +copyWith() Device
        }
        
        %% Domain Layer - Repository (Abstract)
        class DeviceRepository {
            <<interface>>
            +getAllDevices() Future~Either~Failure, List~Device~~~
            +getDeviceById(String id) Future~Either~Failure, Device~~
            +addDevice(Device device) Future~Either~Failure, void~~
            +updateDevice(Device device) Future~Either~Failure, void~~
            +deleteDevice(String id) Future~Either~Failure, void~~
            +updateDeviceStatus(String id, String status) Future~Either~Failure, void~~
            +watchDevices() Stream~List~Device~~
        }
        
        %% Domain Layer - Use Cases
        class GetAllDevices {
            -DeviceRepository repository
            +call() Future~Either~Failure, List~Device~~~
        }
        
        class GetDeviceById {
            -DeviceRepository repository
            +call(GetDeviceByIdParams params) Future~Either~Failure, Device~~
        }
        
        class AddDevice {
            -DeviceRepository repository
            +call(AddDeviceParams params) Future~Either~Failure, void~~
        }
        
        class UpdateDevice {
            -DeviceRepository repository
            +call(UpdateDeviceParams params) Future~Either~Failure, void~~
        }
        
        class DeleteDevice {
            -DeviceRepository repository
            +call(DeleteDeviceParams params) Future~Either~Failure, void~~
        }
        
        %% Data Layer - Model
        class DeviceModel {
            +String id
            +String name
            +String status
            +String sensorStatus
            +DateTime lastUpdated
            +Map~String, dynamic~? sensorData
            +fromJson(Map json)$ DeviceModel
            +toJson() Map~String, dynamic~
            +fromHiveMap(Map map)$ DeviceModel
            +toHiveMap() Map~String, dynamic~
            +copyWith() DeviceModel
        }
        
        %% Data Layer - DataSource
        class DeviceLocalDataSource {
            <<interface>>
            +getAllDevices() Future~List~DeviceModel~~
            +getDeviceById(String id) Future~DeviceModel~
            +addDevice(DeviceModel device) Future~void~
            +updateDevice(DeviceModel device) Future~void~
            +deleteDevice(String id) Future~void~
            +updateDeviceStatus(String id, String status) Future~void~
            +watchDevices() Stream~List~DeviceModel~~
        }
        
        class DeviceLocalDataSourceImpl {
            -Box deviceBox
            +getAllDevices() Future~List~DeviceModel~~
            +getDeviceById(String id) Future~DeviceModel~
            +addDevice(DeviceModel device) Future~void~
            +updateDevice(DeviceModel device) Future~void~
            +deleteDevice(String id) Future~void~
            +updateDeviceStatus(String id, String status) Future~void~
            +watchDevices() Stream~List~DeviceModel~~
        }
        
        %% Data Layer - Repository Implementation
        class DeviceRepositoryImpl {
            -DeviceLocalDataSource localDataSource
            +getAllDevices() Future~Either~Failure, List~Device~~~
            +getDeviceById(String id) Future~Either~Failure, Device~~
            +addDevice(Device device) Future~Either~Failure, void~~
            +updateDevice(Device device) Future~Either~Failure, void~~
            +deleteDevice(String id) Future~Either~Failure, void~~
            +updateDeviceStatus(String id, String status) Future~Either~Failure, void~~
            +watchDevices() Stream~List~Device~~
        }
        
        %% Presentation Layer - ViewModel
        class DeviceViewModel {
            -GetAllDevices _getAllDevices
            -GetDeviceById _getDeviceById
            -AddDevice _addDevice
            -UpdateDevice _updateDevice
            -DeleteDevice _deleteDevice
            +DeviceViewState state
            +List~Device~ devices
            +Device? selectedDevice
            +String errorMessage
            +loadDevices() Future~void~
            +loadDeviceById(String id) Future~void~
            +addNewDevice(Device device) Future~bool~
            +updateExistingDevice(Device device) Future~bool~
            +deleteExistingDevice(String id) Future~bool~
        }
        
        class DeviceManager {
            -Box? _deviceBox
            -Map~String, MqttService~ _mqttServices
            -Map~String, dynamic~ _sensorData
            -DeviceDiscoveryService? _discoveryService
            +List~Map~ devices
            +bool isMuted
            +bool isDeviceActive
            +initHive() Future~void~
            +addDevice(Map device) Future~void~
            +removeDevice(String id) Future~void~
            +updateSensorData(String id, Map data) void
            +getSensorDataForDeviceId(String id) Map
            +toggleMute(bool value) void
            +clearAllDevices() Future~void~
        }
    }
    
    %% Device Management Relationships
    Device <|-- DeviceModel
    DeviceRepository <|.. DeviceRepositoryImpl
    DeviceLocalDataSource <|.. DeviceLocalDataSourceImpl
    DeviceRepositoryImpl --> DeviceLocalDataSource
    DeviceRepositoryImpl --> DeviceModel
    
    GetAllDevices --> DeviceRepository
    GetDeviceById --> DeviceRepository
    AddDevice --> DeviceRepository
    UpdateDevice --> DeviceRepository
    DeleteDevice --> DeviceRepository
    
    UseCaseWithoutParams <|-- GetAllDevices
    UseCase <|-- GetDeviceById
    UseCase <|-- AddDevice
    UseCase <|-- UpdateDevice
    UseCase <|-- DeleteDevice
    
    DeviceViewModel --> GetAllDevices
    DeviceViewModel --> GetDeviceById
    DeviceViewModel --> AddDevice
    DeviceViewModel --> UpdateDevice
    DeviceViewModel --> DeleteDevice
    
    DeviceManager --> MqttService
    DeviceManager --> DeviceDiscoveryService
    
    %% ==========================================
    %% GRAPH API FEATURE
    %% ==========================================
    
    namespace GraphAPI {
        %% Domain Layer - Entities
        class SensorGraphData {
            +List~DataPoint~ humidity
            +List~DataPoint~ temperature
            +List~DataPoint~ waterLevel
            +bool hasData
        }
        
        class DataPoint {
            +double value
            +DateTime time
        }
        
        %% Domain Layer - Repository (Abstract)
        class GraphRepository {
            <<interface>>
            +getGraphData(String controllerId, DateTime startTime, DateTime endTime) Future~Either~Failure, SensorGraphData~~
            +clearAuthToken() Future~Either~Failure, void~~
        }
        
        %% Domain Layer - Use Cases
        class GetGraphData {
            -GraphRepository repository
            +call(GetGraphDataParams params) Future~Either~Failure, SensorGraphData~~
        }
        
        %% Data Layer - Model
        class GraphDataModel {
            +List~GraphDataPoint~ humidity
            +List~GraphDataPoint~ temperature
            +List~GraphDataPoint~ waterLevel
            +fromJson(Map json)$ GraphDataModel
            +toJson() Map~String, dynamic~
        }
        
        class AuthResponseModel {
            +bool success
            +String message
            +AuthData data
            +fromJson(Map json)$ AuthResponseModel
        }
        
        %% Data Layer - DataSource
        class GraphApiRemoteDataSource {
            -Client client
            -Box _authBox
            +initialize() Future~void~
            +getGraphData(String controllerId, DateTime startTime, DateTime endTime) Future~GraphDataModel~
            +clearToken() Future~void~
            -_getValidToken() Future~String~
            -_login() Future~String~
        }
        
        %% Data Layer - Repository Implementation
        class GraphRepositoryImpl {
            -GraphApiRemoteDataSource remoteDataSource
            +getGraphData(String controllerId, DateTime startTime, DateTime endTime) Future~Either~Failure, SensorGraphData~~
            +clearAuthToken() Future~Either~Failure, void~~
        }
        
        %% Presentation Layer - ViewModel
        class GraphApiViewModel {
            -GetGraphData getGraphDataUseCase
            +GraphApiState state
            +SensorGraphData? graphData
            +String errorMessage
            +bool isLoading
            +bool hasData
            +fetchGraphData(String controllerId, DateTime startTime, DateTime endTime) Future~void~
            +clearData() void
        }
    }
    
    %% Graph API Relationships
    SensorGraphData --> DataPoint
    GraphRepository <|.. GraphRepositoryImpl
    GraphRepositoryImpl --> GraphApiRemoteDataSource
    GraphApiRemoteDataSource --> GraphDataModel
    GraphApiRemoteDataSource --> AuthResponseModel
    
    GetGraphData --> GraphRepository
    UseCase <|-- GetGraphData
    
    GraphApiViewModel --> GetGraphData
    
    %% ==========================================
    %% MQTT & COMMUNICATION SERVICES
    %% ==========================================
    
    namespace SharedServices {
        class MqttManager {
            <<singleton>>
            -MqttServerClient _client
            -bool _isConnected
            -Map~String, Function~ _deviceCallbacks
            -Map~String, List~String~~ _deviceSubscriptions
            +instance$ MqttManager
            +bool isConnected
            +initialize() Future~void~
            +registerDevice(String deviceId, Function callback) Future~void~
            +unregisterDevice(String deviceId) void
            +publishMessage(String topic, String payload) Future~void~
            +subscribeToTopic(String topic) void
            -_setupMqttClient() Future~void~
            -_onConnected() void
            -_onDisconnected() void
            -_handleMqttMessage(List messages) void
        }
        
        class MqttService {
            +String deviceId
            +double? temperature
            +double? humidity
            +int? lightState
            +int? blueLightState
            +double? co2Level
            +double? moisture
            +String? deviceStatus
            +String? mode
            +int? countdownSeconds
            +Function onDataReceived
            +Function onDeviceConnectionStatusChange
            +setupMqttClient() Future~void~
            +handleMessage(String topic, String message) void
            +disconnect() void
            -_parseJsonPayload(String payload) Map
            -_parseValue(dynamic value) double?
        }
        
        class DeviceDiscoveryService {
            -MqttServerClient _client
            -Map~String, DeviceInfo~ _discoveredDevices
            -bool _isConnected
            +Stream~DeviceInfo~ deviceRegistered
            +Stream~String~ deviceUnregistered
            +Stream~DeviceInfo~ deviceUpdated
            +Map~String, DeviceInfo~ discoveredDevices
            +bool isConnected
            +initialize() Future~void~
            +startDiscovery() Future~void~
            +stopDiscovery() void
            +dispose() void
        }
        
        class DeviceInfo {
            +String deviceId
            +String deviceName
            +String location
            +List~String~ capabilities
            +String firmware
            +DateTime lastSeen
            +Map~String, dynamic~? metadata
            +fromJson(Map json)$ DeviceInfo
            +toJson() Map~String, dynamic~
            +copyWith() DeviceInfo
        }
        
        class TextToSpeech {
            -FlutterTts _tts$
            -bool _isInitialized$
            +initialize()$ Future~void~
            +speak(String message)$ Future~void~
        }
        
        class AlarmService {
            <<singleton>>
            -FlutterTts _tts
            -AudioPlayer _audioPlayer
            -Timer? _beepTimer
            -bool _isAlarmActive
            -String? _currentAlarmReason
            +bool isAlarmActive
            +String? currentAlarmReason
            +startAlarm(String reason, String deviceId, String deviceName) Future~void~
            +stopAlarm() Future~void~
            +snoozeAlarm(Duration duration) void
            -_playBeep() Future~void~
            -_speakAlarmReason() Future~void~
        }
        
        class FcmService {
            <<singleton>>
            -FirebaseMessaging _firebaseMessaging
            -FlutterLocalNotificationsPlugin _localNotifications
            -AlarmService _alarmService
            -String? _fcmToken
            +String? fcmToken
            +initialize() Future~void~
            +setContext(BuildContext context) void
            -_requestPermissions() Future~void~
            -_initializeLocalNotifications() Future~void~
            -_getFcmToken() Future~void~
            -_setupMessageHandlers() void
            -_handleForegroundMessage(RemoteMessage message) void
        }
    }
    
    %% Shared Services Relationships
    MqttService --> MqttManager
    DeviceDiscoveryService --> DeviceInfo
    FcmService --> AlarmService
    
    %% ==========================================
    %% DASHBOARD FEATURE
    %% ==========================================
    
    namespace Dashboard {
        class CultivationMode {
            <<enumeration>>
            normal
            pinning
        }
        
        class ModeThresholds {
            +String name
            +String description
            +double minHumidity
            +double maxHumidity
            +double minTemp
            +double maxTemp
            +String icon
        }
        
        class ModeControllerService {
            <<singleton>>
            +String deviceId
            -CultivationMode _currentMode
            -DateTime? _pinningEndTime
            -bool _isPinningActive
            +bool humidifier1On
            +bool humidifier2On
            +bool fan1On
            +bool fan2On
            +CultivationMode currentMode
            +DateTime? pinningEndTime
            +bool isPinningActive
            +int? remainingSeconds
            +String? formattedRemainingTime
            +setMode(CultivationMode mode, int? timerSeconds) Future~void~
            +cancelPinningMode() Future~void~
            -_setupMqttListener() void
            -_handleActuatorStatus(String topic, String message) void
        }
        
        class SensorStatusService {
            +String deviceId
            +evaluateTemperatureStatus(double value, CultivationMode mode) SensorStatus
            +evaluateHumidityStatus(double value, CultivationMode mode) SensorStatus
            +evaluateWaterLevelStatus(double value) SensorStatus
            +getStatusColor(SensorStatus status) Color
            +getStatusIcon(SensorStatus status) IconData
        }
    }
    
    %% Dashboard Relationships
    ModeControllerService --> CultivationMode
    ModeControllerService --> ModeThresholds
    ModeControllerService --> MqttManager
    SensorStatusService --> CultivationMode
    
    %% ==========================================
    %% AUTHENTICATION FEATURE
    %% ==========================================
    
    namespace Authentication {
        class AuthService {
            -FirebaseAuth _auth
            +User? currentUser
            +Stream~User?~ authStateChanges
            +signInWithEmail(String email, String password) Future~UserCredential~
            +signUpWithEmail(String email, String password) Future~UserCredential~
            +signOut() Future~void~
            +sendPasswordResetEmail(String email) Future~void~
            +verifyPhoneNumber(String phoneNumber) Future~void~
        }
        
        class AuthWrapper {
            +Widget child
            +build(BuildContext context) Widget
            -_handleAuthStateChange(User? user) void
        }
    }
    
    %% Authentication Relationships
    AuthWrapper --> AuthService
    
    %% ==========================================
    %% NOTIFICATION FEATURE
    %% ==========================================
    
    namespace Notifications {
        class NotificationModel {
            +String id
            +String title
            +String body
            +String type
            +DateTime timestamp
            +bool isRead
            +String? deviceId
            +Map~String, dynamic~? data
            +fromJson(Map json)$ NotificationModel
            +toJson() Map~String, dynamic~
            +copyWith() NotificationModel
        }
        
        class NotificationService {
            -FlutterLocalNotificationsPlugin _plugin
            -Box _notificationsBox
            +initialize() Future~void~
            +showNotification(String title, String body) Future~void~
            +scheduleNotification(String title, String body, DateTime scheduledTime) Future~void~
            +cancelNotification(int id) Future~void~
            +cancelAllNotifications() Future~void~
            +getStoredNotifications() List~NotificationModel~
            +markAsRead(String id) Future~void~
            +deleteNotification(String id) Future~void~
            +clearAllNotifications() Future~void~
        }
    }
    
    %% Notification Relationships
    NotificationService --> NotificationModel
    FcmService --> NotificationService
    
    %% ==========================================
    %% PROFILE FEATURE
    %% ==========================================
    
    namespace Profile {
        class UserProfile {
            +String id
            +String email
            +String? displayName
            +String? photoUrl
            +DateTime createdAt
            +Map~String, dynamic~? preferences
            +fromFirestore(DocumentSnapshot doc)$ UserProfile
            +toFirestore() Map~String, dynamic~
        }
        
        class ProfileService {
            -FirebaseFirestore _firestore
            -FirebaseAuth _auth
            +getUserProfile() Future~UserProfile?~
            +updateDisplayName(String name) Future~void~
            +updatePreferences(Map preferences) Future~void~
            +deleteAccount() Future~void~
        }
    }
    
    %% Profile Relationships
    ProfileService --> UserProfile
    ProfileService --> AuthService
    
    %% ==========================================
    %% REGISTRATION FEATURE
    %% ==========================================
    
    namespace Registration {
        class DeviceRegistrationService {
            +String? currentDeviceId
            +String? currentDeviceName
            +registerDevice(String deviceId, String name, String location) Future~bool~
            +unregisterDevice(String deviceId) Future~bool~
            +validateDeviceId(String deviceId) bool
        }
        
        class BluetoothProvisioningService {
            -BluetoothDevice? _connectedDevice
            -bool _isScanning
            +bool isConnected
            +bool isScanning
            +Stream~List~BluetoothDevice~~ scanResults
            +startScan() Future~void~
            +stopScan() Future~void~
            +connectToDevice(BluetoothDevice device) Future~bool~
            +disconnectDevice() Future~void~
            +sendWifiCredentials(String ssid, String password) Future~bool~
            +sendMqttConfig(String broker, int port, String username, String password) Future~bool~
        }
        
        class UserDeviceService {
            -FirebaseFirestore _firestore
            -FirebaseAuth _auth
            +getUserDevices() Future~List~Map~~
            +addDeviceToUser(String deviceId, String name) Future~void~
            +removeDeviceFromUser(String deviceId) Future~void~
            +shareDeviceWithUser(String deviceId, String userEmail) Future~void~
        }
    }
    
    %% Registration Relationships
    DeviceRegistrationService --> MqttManager
    BluetoothProvisioningService --> DeviceRegistrationService
    UserDeviceService --> DeviceManager
    
    %% ==========================================
    %% CROSS-FEATURE RELATIONSHIPS
    %% ==========================================
    
    %% DeviceManager is central to many features
    DeviceManager --> DeviceViewModel : uses
    DeviceManager --> MqttManager : uses
    DeviceManager --> AlarmService : triggers
    
    %% Mode controller affects sensor evaluation
    SensorStatusService --> ModeControllerService : gets thresholds
    
    %% Alarm service uses FCM for remote alerts
    AlarmService --> FcmService : sends alerts
```
