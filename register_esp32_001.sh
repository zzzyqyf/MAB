#!/bin/bash
echo "🔌 Registering ESP32_001 device with MQTT broker..."
echo "=================================================="

echo "📡 Step 1: Setting device status to online..."
mosquitto_pub -h broker.mqtt.cool -t "devices/ESP32_001/status" -m "online"

echo "🌡️ Step 2: Publishing temperature data..."
mosquitto_pub -h broker.mqtt.cool -t "devices/ESP32_001/sensors/temperature" -m "23.5"

echo "💧 Step 3: Publishing humidity data..."
mosquitto_pub -h broker.mqtt.cool -t "devices/ESP32_001/sensors/humidity" -m "60.2"

echo "💡 Step 4: Publishing light status..."
mosquitto_pub -h broker.mqtt.cool -t "devices/ESP32_001/sensors/lights" -m "0"

echo "🌱 Step 5: Publishing moisture data..."
mosquitto_pub -h broker.mqtt.cool -t "devices/ESP32_001/sensors/moisture" -m "75.8"

echo ""
echo "✅ ESP32_001 device registration completed!"
echo "📊 Device should now appear as ONLINE in your Flutter app"
echo ""
echo "🔄 Starting continuous status updates (every 30 seconds)..."

# Keep device alive with periodic status updates
for i in {1..20}; do
    sleep 30
    echo "📡 Sending keep-alive signal ($i/20)..."
    mosquitto_pub -h broker.mqtt.cool -t "devices/ESP32_001/status" -m "online"
    
    # Occasionally update sensor values to simulate real device
    if [ $((i % 3)) -eq 0 ]; then
        temp=$(echo "scale=1; 23.5 + ($i * 0.3)" | bc)
        humidity=$(echo "scale=1; 60.2 + ($i * 0.5)" | bc)
        moisture=$(echo "scale=1; 75.8 - ($i * 0.2)" | bc)
        
        mosquitto_pub -h broker.mqtt.cool -t "devices/ESP32_001/sensors/temperature" -m "$temp"
        mosquitto_pub -h broker.mqtt.cool -t "devices/ESP32_001/sensors/humidity" -m "$humidity"
        mosquitto_pub -h broker.mqtt.cool -t "devices/ESP32_001/sensors/moisture" -m "$moisture"
        
        echo "📊 Updated sensors: Temp=${temp}°C, Humidity=${humidity}%, Moisture=${moisture}%"
    fi
done

echo "🏁 Registration and monitoring completed!"
