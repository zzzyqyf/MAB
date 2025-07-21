// Mushroom cultivation phase definitions
enum MushroomPhase {
  spawnRun,
  primordia,
  fruiting,
  postHarvest
}

class PhaseThresholds {
  final String name;
  final String description;
  final double minHumidity;
  final double maxHumidity;
  final double minTemp;
  final double maxTemp;
  final int minLight;
  final int maxLight;
  final String icon;

  const PhaseThresholds({
    required this.name,
    required this.description,
    required this.minHumidity,
    required this.maxHumidity,
    required this.minTemp,
    required this.maxTemp,
    required this.minLight,
    required this.maxLight,
    required this.icon,
  });
}

// Phase configuration data based on grey oyster mushroom cultivation
const Map<MushroomPhase, PhaseThresholds> phaseThresholds = {
  MushroomPhase.spawnRun: PhaseThresholds(
    name: "Spawn Run",
    description: "Mycelium colonization phase",
    minHumidity: 65.0,
    maxHumidity: 70.0,
    minTemp: 25.0,
    maxTemp: 30.0,
    minLight: 0,
    maxLight: 50, // Dark phase, minimal light
    icon: "🌱",
  ),
  MushroomPhase.primordia: PhaseThresholds(
    name: "Primordia Initiation",
    description: "Pinning phase - most sensitive",
    minHumidity: 90.0,
    maxHumidity: 95.0,
    minTemp: 18.0,
    maxTemp: 22.0,
    minLight: 300,
    maxLight: 500,
    icon: "🍄",
  ),
  MushroomPhase.fruiting: PhaseThresholds(
    name: "Fruiting",
    description: "Active mushroom growth",
    minHumidity: 85.0,
    maxHumidity: 90.0,
    minTemp: 18.0,
    maxTemp: 22.0,
    minLight: 300,
    maxLight: 500,
    icon: "🌾",
  ),
  MushroomPhase.postHarvest: PhaseThresholds(
    name: "Post-Harvest Recovery",
    description: "Preparation for next flush",
    minHumidity: 90.0,
    maxHumidity: 95.0,
    minTemp: 18.0,
    maxTemp: 22.0,
    minLight: 100,
    maxLight: 300,
    icon: "📦",
  ),
};
