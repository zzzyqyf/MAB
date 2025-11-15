# Alarm Sound Setup

## Required Audio File

You need to add a `beep.mp3` file to this folder.

### Option 1: Download Free Sound
Download a free beep/alarm sound from:
- **Pixabay**: https://pixabay.com/sound-effects/search/beep/
- **Freesound**: https://freesound.org/search/?q=beep
- **Zapsplat**: https://www.zapsplat.com/sound-effect-category/beeps/

### Option 2: Use Online Generator
Generate a custom beep tone:
- **Online Tone Generator**: https://onlinetonegenerator.com/
  1. Set frequency to 1000 Hz (high-pitched beep)
  2. Duration: 0.5 seconds
  3. Download as MP3
  4. Name it `beep.mp3`

### Option 3: Create with Audacity (Free Software)
1. Download Audacity: https://www.audacityteam.org/
2. Generate → Tone
3. Waveform: Sine
4. Frequency: 1000 Hz
5. Duration: 0.5 seconds
6. File → Export → Export as MP3
7. Save as `beep.mp3` in this folder

### Recommended Sound Characteristics
- **Format**: MP3
- **Duration**: 0.3 - 0.5 seconds
- **Frequency**: 800-1200 Hz (high-pitched, attention-grabbing)
- **Volume**: Normalized (loud enough to hear clearly)
- **File Size**: < 50 KB

### Quick Test Commands
Once you have the file, test it works:

```dart
// In Flutter DevTools console:
import 'package:audioplayers/audioplayers.dart';
final player = AudioPlayer();
await player.play(AssetSource('sounds/beep.mp3'));
```

## File Location
Place your `beep.mp3` file directly in this folder:
```
assets/
  sounds/
    beep.mp3  ← HERE
```
