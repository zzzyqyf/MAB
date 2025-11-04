// Mushroom cultivation mode definitions
enum CultivationMode {
  normal,
  pinning,
}

class ModeThresholds {
  final String name;
  final String description;
  final double minHumidity;
  final double maxHumidity;
  final double minTemp;
  final double maxTemp;
  final String icon;

  const ModeThresholds({
    required this.name,
    required this.description,
    required this.minHumidity,
    required this.maxHumidity,
    required this.minTemp,
    required this.maxTemp,
    required this.icon,
  });
}

// Mode configuration data
const Map<CultivationMode, ModeThresholds> modeThresholds = {
  CultivationMode.normal: ModeThresholds(
    name: "Normal Mode",
    description: "Standard cultivation conditions",
    minHumidity: 80.0,
    maxHumidity: 85.0,
    minTemp: 25.0,
    maxTemp: 30.0,
    icon: "🌱",
  ),
  CultivationMode.pinning: ModeThresholds(
    name: "Pinning Mode",
    description: "Optimized for mushroom pinning",
    minHumidity: 90.0,
    maxHumidity: 95.0,
    minTemp: 18.0,
    maxTemp: 22.0,
    icon: "🍄",
  ),
};
