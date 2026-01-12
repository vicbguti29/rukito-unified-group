#!/bin/bash

BASE_URL="http://localhost:8080/api"

echo "=========================================="
echo "🕵️  RUKITO DEBUGGER - API TEST"
echo "=========================================="

# 1. Probar Historial (Simulando lo que envía Flutter)
# NOTA: Flutter suele enviar ISO8601. Probemos con y sin 'Z' (UTC)
echo -e "\n1. TESTING HISTORY (CF-1)..."
START_DATE=$(date -u -d '4 hours ago' +'%Y-%m-%dT%H:%M:%SZ')
END_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ')

echo "   Request: GET /readings/CF-1/history?start=$START_DATE&end=$END_DATE"
HTTP_CODE=$(curl -s -o response_history.json -w "%{http_code}" "$BASE_URL/readings/CF-1/history?start=$START_DATE&end=$END_DATE")

if [ "$HTTP_CODE" -eq 200 ]; then
    COUNT=$(grep -o '"id":' response_history.json | wc -l)
    echo "   ✅ SUCCESS (200). Registros encontrados: $COUNT"
    head -c 100 response_history.json
    echo "..."
else
    echo "   ❌ FAILED ($HTTP_CODE)"
    cat response_history.json
fi

# 2. Probar Update Config (Simulando PUT)
echo -e "\n\n2. TESTING CONFIG UPDATE (CF-1)..."
echo "   Request: PUT /config/alerts/CF-1"
# JSON Payload mínimo válido
JSON_DATA='{
    "id": "CONFIG-CF-1",
    "sensor_id": "CF-1", 
    "max_temperature": -5.0,
    "min_temperature": -30.0,
    "rate_of_change_threshold": 0.5,
    "priority": 1,
    "is_enabled": true,
    "notification_channels": ["sms"],
    "recipients": ["+593999"]
}'

HTTP_CODE=$(curl -s -o response_config.json -w "%{http_code}" -X PUT -H "Content-Type: application/json" -d "$JSON_DATA" "$BASE_URL/config/alerts/CF-1")

if [ "$HTTP_CODE" -eq 200 ]; then
    echo "   ✅ SUCCESS (200). Configuración actualizada."
    cat response_config.json
else
    echo "   ❌ FAILED ($HTTP_CODE)"
    cat response_config.json
fi

# 3. Probar Reporte Analytics (CF-2) - Ver por qué falta data
echo -e "\n\n3. TESTING REPORT (CF-2)..."
echo "   Request: GET /reports/CF-2"
HTTP_CODE=$(curl -s -o response_report.json -w "%{http_code}" "$BASE_URL/reports/CF-2")

if [ "$HTTP_CODE" -eq 200 ]; then
    echo "   ✅ SUCCESS (200)."
    cat response_report.json
else
    echo "   ❌ FAILED ($HTTP_CODE)"
    cat response_report.json
fi

echo -e "\n\n=========================================="
echo "🏁 TEST COMPLETO"
echo "=========================================="
