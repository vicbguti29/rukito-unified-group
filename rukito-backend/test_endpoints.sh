#!/bin/bash

BASE_URL="http://localhost:8080/api"

echo "=== INICIANDO PRUEBAS DE INTEGRACIÓN RUKITO BACKEND ==="
echo ""

echo "1. Testing Health Check..."
curl -s "$BASE_URL/health" | python3 -m json.tool
echo "-----------------------------------"

echo "2. Obtener todas las Cámaras..."
curl -s "$BASE_URL/chambers" | python3 -m json.tool
echo "-----------------------------------"

echo "3. Obtener Cámara CF-1..."
curl -s "$BASE_URL/chambers/CF-1" | python3 -m json.tool
echo "-----------------------------------"

echo "4. Obtener Lecturas de CF-1..."
curl -s "$BASE_URL/readings/CF-1?limit=5" | python3 -m json.tool
echo "-----------------------------------"

echo "5. Obtener Histórico de Lecturas (Simulado)..."
# Usamos un rango amplio para asegurar datos
curl -s "$BASE_URL/readings/CF-1/history?start=2024-01-01T00:00:00Z&end=2025-12-31T23:59:59Z" | python3 -m json.tool
echo "-----------------------------------"

echo "6. Obtener Alertas de CF-1..."
curl -s "$BASE_URL/alerts/chamber/CF-1" | python3 -m json.tool
echo "-----------------------------------"

echo "7. Obtener Configuración de CF-1..."
curl -s "$BASE_URL/config/alerts/CF-1" | python3 -m json.tool
echo "-----------------------------------"

echo "8. Actualizar Configuración de CF-1..."
curl -s -X PUT "$BASE_URL/config/alerts/CF-1" \
     -H "Content-Type: application/json" \
     -d '{"max_temperature": -15.0, "min_temperature": -25.0, "rate_of_change_threshold": 0.6, "priority": 2, "is_enabled": true, "notification_channels": ["sms"], "recipients": ["+593999999999"]}' | python3 -m json.tool
echo "-----------------------------------"

echo "=== PRUEBAS FINALIZADAS ==="
