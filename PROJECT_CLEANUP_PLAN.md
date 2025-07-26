# MAB Project Reorganization Plan
## Professional Structure for Final Year Project Submission

### Current Issues Identified:
1. **Multiple test files in root directory** (test_*.dart, test_*.ps1)
2. **Development documentation scattered** (multiple MQTT guides, testing docs)
3. **Temporary files and artifacts** (graphy.txt, plistfile.txt, quick_co2_test.dart)
4. **Duplicate files and unused test services**
5. **Generic Flutter README needs customization**

### Recommended Professional Structure:

```
MAB/                                    # Root project directory
├── README.md                          # Professional project description
├── SETUP_GUIDE.md                     # Installation and setup instructions
├── pubspec.yaml                       # Flutter dependencies
├── analysis_options.yaml              # Code analysis rules
├── firebase.json                      # Firebase configuration
│
├── docs/                              # All documentation
│   ├── API_DOCUMENTATION.md           # MQTT API and data formats
│   ├── ESP32_IMPLEMENTATION.md        # Hardware implementation details
│   ├── SYSTEM_ARCHITECTURE.md         # Overall system design
│   └── USER_MANUAL.md                 # End-user instructions
│
├── hardware/                          # ESP32 code and scripts
│   ├── esp32_sensor_code/             # Arduino ESP32 implementation
│   └── registration_scripts/          # Device registration utilities
│
├── lib/                               # Flutter application source
│   ├── main.dart                      # Application entry point
│   ├── injection_container.dart       # Dependency injection
│   ├── core/                          # Core utilities and errors
│   ├── features/                      # Feature-based modules
│   └── shared/                        # Shared services and widgets
│
├── test/                              # Official Flutter test directory
│   ├── widget_test.dart               # Widget tests
│   └── integration_test/              # Integration tests
│
├── android/                           # Android platform code
├── ios/                               # iOS platform code
├── web/                               # Web platform code
├── windows/                           # Windows platform code
├── linux/                             # Linux platform code
└── macos/                             # macOS platform code
```

### Files to DELETE (Development Artifacts):

#### Root Directory Test Files:
- test_simple_mqtt.dart
- test_mqtt_connection.dart
- test_mqtt.dart
- test_esp32_subscription.dart
- test_esp32_001_complete.dart
- test_co2_publisher.dart
- test_android_mqtt.dart
- quick_co2_test.dart

#### PowerShell Test Scripts:
- test_mqtt_esp32_003.ps1
- test_co2.ps1
- test_blue_light.ps1
- test_light_intensity.ps1
- test_mqtt_complete.ps1

#### Temporary Development Files:
- lib/graphy.txt
- lib/plistfile.txt
- lib/README.md (redundant)
- lib/realTimeUpdate (unclear purpose)

#### Development Documentation (to be consolidated):
- MQTT_TEST_COMMANDS.md
- MQTT_TESTING_GUIDE.md
- MQTT_PERFORMANCE_IMPROVEMENTS.md
- GRAPH_REFACTORING_SUMMARY.md

#### Unused Test Services:
- lib/shared/services/mqttTests/ (entire directory)
- lib/shared/utils/testing.dart
- lib/shared/utils/test.dart
- lib/shared/utils/finalTest.dart

### Files to MOVE and REORGANIZE:

#### Move to docs/:
- ESP32_MQTT_CODE.md → docs/ESP32_IMPLEMENTATION.md
- Create new docs from development notes

#### Move to hardware/:
- register_esp32_001.ps1 → hardware/registration_scripts/
- register_esp32_001.sh → hardware/registration_scripts/

### Files to UPDATE:

#### README.md:
Replace generic Flutter README with professional project description including:
- Project overview and objectives
- System architecture diagram
- Features and capabilities
- Technology stack
- Installation instructions
- Usage examples
- ESP32 hardware requirements

#### Create New Documentation:
- SETUP_GUIDE.md: Complete installation and configuration guide
- docs/USER_MANUAL.md: End-user operation manual
- docs/SYSTEM_ARCHITECTURE.md: Technical system design
- docs/API_DOCUMENTATION.md: MQTT data formats and API

### Professional Benefits:
1. **Clear separation** of source code, tests, documentation, and hardware
2. **Academic presentation** suitable for supervisor review
3. **Industry-standard** Flutter project structure
4. **Comprehensive documentation** for technical evaluation
5. **Clean repository** without development artifacts
6. **Maintainable codebase** for future development

### Implementation Priority:
1. **High Priority**: Remove test files and development artifacts
2. **Medium Priority**: Reorganize documentation into docs/ folder
3. **Low Priority**: Create comprehensive documentation files

This structure follows industry best practices and academic project standards.
