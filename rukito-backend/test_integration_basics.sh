#!/bin/bash

GO_URL="http://localhost:8080/api"
PYTHON_URL="http://localhost:8000"

echo "=== PRUEBA DE INTEGRACIÓN BÁSICA (GO + PYTHON) ==="
echo ""

# 1. Verificar Backend Go
echo "[GO] Verificando estado del servidor principal..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$GO_URL/health")

if [ "$HTTP_CODE" -eq 200 ]; then
    echo "✅ Backend Go está ONLINE (Puerto 8080)"
else
    echo "❌ Backend Go NO responde. Asegúrate de iniciarlo con 'go run cmd/server/main.go'"
    exit 1
fi

echo "-----------------------------------"

# 2. Verificar Analytics Python
echo "[PYTHON] Verificando estado del servicio de análisis..."
# Nota: El endpoint /health de Python lo definimos en main.py
HTTP_CODE_PY=$(curl -s -o /dev/null -w "%{http_code}" "$PYTHON_URL/health")

if [ "$HTTP_CODE_PY" -eq 200 ]; then
    echo "✅ Analytics Python está ONLINE (Puerto 8000)"
else
    echo "❌ Analytics Python NO responde. Asegúrate de iniciarlo con 'uvicorn main:app --port 8000'"
    exit 1
fi

echo "-----------------------------------"

# 3. Probar Comunicación Python -> MySQL
echo "[PYTHON] Solicitando reporte de análisis para cámara CF-1..."
RESPONSE=$(curl -s "$PYTHON_URL/analyze/report/CF-1")

# Verificamos si la respuesta contiene el ID de la cámara (señal de éxito)
if [[ "$RESPONSE" == *"CF-1"* ]]; then
    echo "✅ Python generó el reporte correctamente:"
    echo "$RESPONSE" | python3 -m json.tool
else
    echo "❌ Error al generar reporte. Respuesta:"
    echo "$RESPONSE"
fi

echo ""
echo "=== RESUMEN ==="
echo "Si ambos servicios están en verde, la arquitectura base está lista para la Fase 4."
