#!/bin/bash

ANALYTICS_DIR="analytics"
PYTHON_URL="http://localhost:8000"

echo "=== PRUEBA DE INTEGRACIÓN: ANALÍTICA Y MERCADO ==="
echo ""

# 1. Ejecutar Scraper para generar datos frescos
echo "[SCRAPER] Ejecutando simulación de mercado..."
cd $ANALYTICS_DIR
source venv/bin/activate
python3 scraper.py
echo "-----------------------------------"

# 2. Verificar que se creó el CSV (ruta desde analytics/)
if [ -f "../datos/precios_mercado.csv" ]; then
    echo "✅ Archivo de precios generado correctamente."
else
    echo "❌ Error: No se generó el archivo precios_mercado.csv en ../datos/"
    exit 1
fi

echo "-----------------------------------"

# 3. Solicitar Reporte al Servicio de Python
echo "[ANALYTICS] Consultando reporte financiero para CF-1..."
echo "ℹ️  Contexto del Análisis:"
echo "   - Periodo de Evaluación: Últimos 30 minutos"
echo "   - Criterio de Riesgo: Temperaturas > Umbral de Advertencia"
echo "   - Inventario Asumido: 200kg de carne premium"
echo "   - Factor de Pérdida: 4 horas críticas = 100% pérdida"
echo ""

# Nota: Asumimos que el servicio uvicorn ya está corriendo en el puerto 8000
RESPONSE=$(curl -s "$PYTHON_URL/analyze/report/CF-1")

if [[ "$RESPONSE" == *"detail"* ]]; then
    echo "❌ Error retornado por el servidor de Analítica:"
    echo "$RESPONSE" | python3 -m json.tool
    exit 1
fi

echo "Respuesta del Analista:"
echo "$RESPONSE" | python3 -m json.tool

# 4. Verificar si calculó costos usando Python para parsear el JSON de forma segura
COST=$(echo "$RESPONSE" | python3 -c "import sys, json; data = json.load(sys.stdin); print(data.get('estimated_cost', 0))")

echo ""
# Comparación numérica segura en Bash
if (( $(echo "$COST > 0" | bc -l) )); then
    echo "✅ ÉXITO: El sistema calculó un costo financiero de riesgo: \$$COST"
else
    echo "⚠️ AVISO: El costo estimado es $COST. Esto es normal si NO hubo horas en riesgo en el periodo consultado."
    echo "   (Para ver costos, asegúrate de haber corrido una prueba que genere estado CRÍTICO)"
fi

echo ""
echo "=== FIN DE PRUEBAS DE ANALÍTICA ==="
