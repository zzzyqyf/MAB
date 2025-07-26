# User Manual
**MAB - Mushroom Agriculture Monitoring System**

## 📱 Welcome to MAB

The Mushroom Agriculture Monitoring (MAB) app helps you monitor environmental conditions for optimal mushroom growing. This guide will help you get started and make the most of your monitoring system.

## 🚀 Getting Started

### First Launch
1. **Download and Install** the MAB app from your device's app store
2. **Create Account** or sign in with existing credentials
3. **Grant Permissions** for notifications and network access
4. **Connect Your ESP32 Device** following the setup instructions

### Initial Setup
1. **Device Registration**
   - Ensure your ESP32 sensor device is powered on
   - Check that it's connected to WiFi (status LED should be solid)
   - The app will automatically detect new devices on the network

2. **Location Setup**
   - Give your monitoring location a meaningful name (e.g., "Greenhouse A", "Growing Room 1")
   - Set the physical location for reference

## 📊 Main Dashboard

### Understanding Your Dashboard
The main screen shows real-time data from all your sensors:

**Temperature Card** 🌡️
- Shows current temperature in Celsius
- Green: 18-24°C (optimal for mushrooms)
- Yellow: 15-18°C or 24-27°C (acceptable)
- Red: Below 15°C or above 27°C (needs attention)

**Humidity Card** 💧
- Displays relative humidity percentage
- Green: 80-95% (ideal for mushroom growth)
- Yellow: 70-80% or 95-100% (monitor closely)
- Red: Below 70% (too dry for optimal growth)

**Light Intensity Card** 💡
- Measures ambient light levels
- Green: Low light (optimal for most mushroom varieties)
- Yellow: Moderate light (acceptable)
- Red: High light (may inhibit growth)

**CO2 Levels Card** 🌬️
- Shows carbon dioxide concentration
- Green: 400-1000 ppm (good air circulation)
- Yellow: 1000-2000 ppm (monitor ventilation)
- Red: Above 2000 ppm (increase ventilation)

**Moisture Card** 💦
- Indicates substrate moisture levels
- Green: 70-85% (optimal moisture content)
- Yellow: 60-70% or 85-90% (adjust watering)
- Red: Below 60% or above 90% (immediate attention needed)

**Blue Light Card** 🔵
- Specialized light spectrum measurement
- Important for certain mushroom varieties
- Values depend on specific growing requirements

### Reading Timestamps
Each sensor card shows the last update time. Data should refresh every 5 seconds when your ESP32 device is connected.

## 📈 Historical Data and Graphs

### Viewing Trends
1. **Tap any sensor card** to view detailed historical data
2. **Select time range** using the time navigator:
   - 1 Hour: Recent short-term trends
   - 6 Hours: Medium-term patterns
   - 24 Hours: Daily cycles
   - 7 Days: Weekly trends

### Understanding Graph Data
- **Line Color**: Matches the sensor card color scheme
- **Data Points**: Each point represents a sensor reading
- **Trend Lines**: Help identify patterns over time
- **Zoom**: Pinch to zoom in on specific time periods

## 🔔 Notifications and Alerts

### Setting Up Alerts
1. **Navigate to Settings** (Profile → Settings)
2. **Choose Notification Preferences**:
   - Immediate alerts for critical conditions
   - Daily summaries
   - Weekly reports

### Alert Types
- **Critical Alerts**: Temperature too high/low, humidity issues
- **Information Alerts**: System status, device connectivity
- **Trend Alerts**: Gradual changes that may need attention

### Managing Notifications
- **Sound Options**: Choose alert tones or silent notifications
- **Time Restrictions**: Set quiet hours for notifications
- **Priority Levels**: Customize which alerts are most important

## 👤 Profile and Settings

### User Profile
- **Edit Personal Information**: Name, email, preferences
- **Accessibility Options**: 
  - Text-to-Speech: Enable voice reading of sensor values
  - Large Text: Increase text size for better visibility
  - High Contrast: Enhanced visibility options

### Device Management
- **Add New Devices**: Register additional ESP32 sensor units
- **Device Names**: Give meaningful names to each monitoring location
- **Remove Devices**: Deactivate unused or broken devices

### Application Settings
- **Units**: Choose Celsius/Fahrenheit, metric/imperial
- **Update Frequency**: Adjust how often the app checks for new data
- **Data Storage**: Manage local data retention

## 🔧 Troubleshooting

### Common Issues

**No Data Showing:**
1. Check ESP32 device power and WiFi connection
2. Verify device status LED is solid (connected)
3. Restart the app
4. Check internet connection on your mobile device

**Intermittent Data:**
1. Check WiFi signal strength near ESP32 device
2. Verify MQTT broker connectivity
3. Consider moving ESP32 closer to WiFi router

**Inaccurate Readings:**
1. Check sensor connections to ESP32
2. Calibrate sensors if needed
3. Ensure sensors are not blocked or damaged
4. Verify sensor placement in growing environment

### Getting Help
If problems persist:
1. **Check Device Status**: Look for error messages in the app
2. **Restart Everything**: Power cycle both ESP32 and app
3. **Check Network**: Ensure stable internet connection
4. **Contact Support**: Use in-app support or documentation

## 🍄 Mushroom Growing Tips

### Optimal Conditions
Based on your sensor readings, maintain these conditions for most mushroom varieties:

**Temperature**: 18-24°C (64-75°F)
- Consistent temperature is more important than exact values
- Avoid rapid temperature changes

**Humidity**: 80-95%
- High humidity is critical for mushroom development
- Use humidifiers or misting systems as needed

**Air Circulation**: 
- CO2 levels below 1000 ppm indicate good air exchange
- Fresh air exchange 4-6 times per hour

**Light**: 
- Most mushrooms prefer low light conditions
- Some varieties benefit from specific light spectrums

### Using Data for Better Growing
1. **Monitor Patterns**: Look for daily and weekly cycles
2. **Adjust Environment**: Use data to guide climate control
3. **Document Changes**: Note when you make adjustments
4. **Track Results**: Correlate environmental data with harvest success

## 🔄 Maintenance and Updates

### Regular Maintenance
- **Clean Sensors**: Gently clean DHT22 and other sensors monthly
- **Check Connections**: Ensure all wires are secure
- **Update App**: Keep the mobile app updated via app store
- **Battery Check**: If using battery power, monitor levels

### Software Updates
The app will notify you of available updates. Updates may include:
- New features and improvements
- Bug fixes and performance enhancements
- Additional sensor support
- Enhanced reporting capabilities

## 📞 Support and Resources

### Additional Learning
- **Growing Guides**: Research specific mushroom variety requirements
- **Community Forums**: Connect with other growers using MAB
- **Documentation**: Refer to technical docs for advanced features

### Technical Support
For technical issues or questions:
- **In-App Help**: Access built-in help and FAQ
- **Documentation**: Review setup guides and troubleshooting
- **Community**: Join user forums and discussion groups

---

**Happy Growing!** 🍄 Your MAB system is designed to help you achieve optimal growing conditions through continuous monitoring and data-driven insights.
