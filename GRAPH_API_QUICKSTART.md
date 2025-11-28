# Quick Start Guide - Graph API Feature

## 🚀 Quick Test

```powershell
cd "d:\fyp\Backup\MAB"
flutter run
```

1. Open any device's Overview page
2. **Double-tap** (not single tap) on any sensor card:
   - 💧 **Humidity** card → Opens Humidity graph with blue theme
   - 🌡️ **Temperature** card → Opens Temperature graph with red theme
   - 💦 **Water Level** card → Opens Water Level graph with green theme

## 🔧 Quick Configuration

### Change API Credentials
File: `lib/features/graph_api/data/datasources/graph_api_remote_datasource.dart`
```dart
static const String _email = 'uremail@gmail.com';      // Line 17
static const String _password = '12345678';             // Line 18
```

### Change Auto-Refresh Time (default: 30 seconds)
File: `lib/features/graph_api/presentation/pages/base_sensor_detail_page.dart`
```dart
Timer.periodic(const Duration(seconds: 30), ...);      // Line 65
```

## 📊 What You'll See

### Detail Page Features:
- ✅ Current sensor reading card (top)
- ✅ Date selector with calendar icon
- ✅ Daily/Weekly toggle buttons
- ✅ Interactive line chart with tooltips
- ✅ Auto-refresh every 30 seconds
- ✅ Manual refresh button
- ✅ TTS announcements

### Console Output (Success):
```
🔑 Logging in to API...
✅ API login successful, token cached
📊 Fetching graph data for controller: 94B97EC04AD4
📊 Humidity points: 24
📊 Temperature points: 24
📊 Water level points: 24
✅ ViewModel: Graph data loaded successfully
```

## 🐛 Quick Troubleshooting

| Problem | Solution |
|---------|----------|
| No data showing | Check if date has data on server, verify MAC address format |
| Login failed | Verify credentials in `graph_api_remote_datasource.dart` |
| Can't navigate | Use **double-tap** not single tap on sensor cards |
| Token keeps expiring | Token cached for 24h, should auto-refresh |

## 📁 Key Files to Know

| File | Purpose |
|------|---------|
| `graph_api_remote_datasource.dart` | API credentials & token management |
| `base_sensor_detail_page.dart` | Common UI logic for all graphs |
| `humidity_detail_page.dart` | Humidity-specific config |
| `temperature_detail_page.dart` | Temperature-specific config |
| `water_level_detail_page.dart` | Water level-specific config |
| `sensor_readings_list.dart` | Navigation trigger (double-tap) |

## 🎯 API Details

**Base URL:** `https://api.milloserver.uk`

**Login:** `POST /api/login`
```json
{
  "email": "uremail@gmail.com",
  "password": "12345678"
}
```

**Graph Data:** `GET /api/millometer/by-controller`
```
?controller_id=94B97EC04AD4
&start_time=2025-11-25T00:00:00.000Z
&end_time=2025-11-26T00:00:00.000Z
```

**Response Format:**
```json
{
  "humidity": [{"value": 85.2, "time": "2025-11-25T10:00:00Z"}, ...],
  "temperature": [{"value": 25.5, "time": "2025-11-25T10:00:00Z"}, ...],
  "water_level": [{"value": 70.3, "time": "2025-11-25T10:00:00Z"}, ...]
}
```

## ✅ Implementation Checklist

- [x] Clean Architecture structure
- [x] API authentication with token caching
- [x] Three sensor detail pages
- [x] Interactive fl_chart graphs
- [x] Calendar date selector
- [x] Daily/Weekly toggle (daily functional)
- [x] Auto-refresh (30s interval)
- [x] Error handling & empty states
- [x] TTS accessibility
- [x] Dependency injection setup

## 📝 Next Steps (If Needed)

1. **Test with real API data**
   - Verify MAC address format matches your devices
   - Check if API returns data for your date ranges

2. **Adjust credentials**
   - Replace hardcoded email/password if needed

3. **Implement weekly view**
   - Modify API call to aggregate 7 days of data
   - Update time range calculation

4. **Add user credential input**
   - Create login page for API credentials
   - Store securely in Hive

---

**For detailed information, see:** `GRAPH_API_IMPLEMENTATION.md`
