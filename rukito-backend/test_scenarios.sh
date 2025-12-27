#!/bin/bash

API_URL="http://localhost:8080/api"

echo "=== PRUEBA DE ESCENARIOS (CONTROLADA) ==="
echo "Asegúrate de haber iniciado el servidor con: export SIMULATION_MODE=SCENARIO && go run cmd/server/main.go"
echo ""

# --- FASE 1: INICIO (0-15s) ---
# CF-1 debería estar MAL (-16°C)
# CF-2 debería estar BIEN (4°C)
echo "[T=5s] Verificando estado inicial..."
sleep 5

TEMP_CF1=$(curl -s "$API_URL/chambers/CF-1" | grep "current_temperature" | awk '{print $2}' | tr -d ',')
TEMP_CF2=$(curl -s "$API_URL/chambers/CF-2" | grep "current_temperature" | awk '{print $2}' | tr -d ',')

echo "   CF-1 Temp: $TEMP_CF1 (Esperado: -16)"
echo "   CF-2 Temp: $TEMP_CF2 (Esperado: 4)"

# --- FASE 2: TRANSICIÓN (20s+) ---
# CF-1 debería ARREGLARSE (-21°C)
# CF-2 debería FALLAR (10°C)
echo ""
echo "[T=25s] Esperando transición de escenarios..."
sleep 20

TEMP_CF1_FINAL=$(curl -s "$API_URL/chambers/CF-1" | grep "current_temperature" | awk '{print $2}' | tr -d ',')
TEMP_CF2_FINAL=$(curl -s "$API_URL/chambers/CF-2" | grep "current_temperature" | awk '{print $2}' | tr -d ',')

echo "   CF-1 Temp: $TEMP_CF1_FINAL (Esperado: -21 -> ARREGLADO)"
echo "   CF-2 Temp: $TEMP_CF2_FINAL (Esperado: 10 -> FALLÓ)"

# --- VERIFICACIÓN ALERTAS ---
echo ""
echo "[ALERTA] Verificando si se generó alerta para CF-1..."
ALERTS=$(curl -s "$API_URL/alerts/chamber/CF-1")
if [[ "$ALERTS" == *"ALERTA CRÍTICA"* ]]; then
    echo "✅ Alerta CF-1 Detectada."
else
    echo "❌ No se encontró alerta para CF-1."
fi

echo ""
echo "=== FIN DE PRUEBA DE ESCENARIOS ==="
