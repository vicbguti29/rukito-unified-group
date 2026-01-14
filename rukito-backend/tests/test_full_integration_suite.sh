#!/bin/bash

BASE_URL="http://localhost:8080/api"
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo "=== INICIANDO SUITE DE PRUEBAS DE INTEGRACIÓN COMPLETA (FRONTEND CONTRACT) ==="
echo "Objetivo: Validar que el Backend cumpla con 'manual_frontend.md'"
echo ""

fail_count=0

# Función auxiliar para validar JSON y claves requeridas
validate_endpoint() {
    local name="$1"
    local endpoint="$2"
    local required_keys="$3" # Lista separada por espacios
    local method="${4:-GET}"
    local payload="$5"

    echo "Testing: $name [$method $endpoint]..."
    
    if [ "$method" == "PUT" ] || [ "$method" == "POST" ]; then
        RESPONSE=$(curl -s -X "$method" "$BASE_URL$endpoint" -H "Content-Type: application/json" -d "$payload")
    else
        RESPONSE=$(curl -s "$BASE_URL$endpoint")
    fi

    # 1. Validar si es JSON válido
    echo "$RESPONSE" | python3 -m json.tool > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ FALLÓ: Respuesta no es un JSON válido${NC}"
        echo "Respuesta: $RESPONSE"
        fail_count=$((fail_count+1))
        return
    fi

    # 2. Validar claves requeridas
    local missing=0
    for key in $required_keys; do
        if ! echo "$RESPONSE" | grep -q "\"$key\""; then
            echo -e "${RED}    ❌ Falta clave: $key${NC}"
            missing=1
        fi
    done

    if [ $missing -eq 0 ]; then
        echo -e "${GREEN}✅ PASÓ: Estructura correcta${NC}"
    else
        echo -e "${RED}❌ FALLÓ: Estructura incompleta${NC}"
        echo "Sample Response: $(echo "$RESPONSE" | head -n 5)..."
        fail_count=$((fail_count+1))
    fi
    echo "------------------------------------------------"
}

# --- 1. DASHBOARD ---
# Endpoint: GET /chambers
# Requisitos: status (ENUM), sin thresholds legacy
validate_endpoint "Dashboard_Camaras" "/chambers" "id name current_temperature status last_update is_active"

# --- 2. REPORTES ---
# Endpoint: GET /reports/{id}
# Requisitos: hours_at_risk, estimated_cost, alert_causes
validate_endpoint "Reportes_Analytics" "/reports/CF-1" "chamber_id hours_at_risk estimated_cost alert_causes analysis_risk_text"

# --- 3. HISTÓRICO ---
# Endpoint: GET /readings/{id}/history
# Requisitos: status, rate_of_change
START_DATE=$(date -u -d "1 hour ago" +"%Y-%m-%dT%H:%M:%SZ")
END_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
validate_endpoint "Historial_Lecturas" "/readings/CF-1/history?start=$START_DATE&end=$END_DATE" "sensor_id temperature status timestamp"

# --- 4. CENTRO DE ALERTAS ---
# Endpoint: GET /alerts
# Requisitos: severity, category, channels
validate_endpoint "Centro_de_Alertas" "/alerts" "id title severity category channels"

# --- 5. CONFIGURACIÓN ---
# Endpoint: GET /config/alerts/{id}
# Requisitos: thresholds object, notifications object
validate_endpoint "Configuracion_GET" "/config/alerts/CF-1" "thresholds critical_cold notifications on_critical_hot"

# Endpoint: PUT /config/alerts/{id}
PAYLOAD_CONFIG='{
  "sensor_id": "CF-1",
  "thresholds": {
    "critical_cold": -30.0,
    "target": -20.0,
    "warning_hot": -15.0,
    "critical_hot": -10.0,
    "rate_of_change": 0.8
  },
  "notifications": {
    "on_warning_hot": {"channels": ["push"], "target_roles": ["staff"]},
    "on_critical_hot": {"channels": ["push"], "target_roles": ["manager"]},
    "on_critical_cold": {"channels": ["email"], "target_roles": ["technician"]}
  },
  "is_enabled": true
}'
validate_endpoint "Configuracion_PUT" "/config/alerts/CF-1" "thresholds notifications" "PUT" "$PAYLOAD_CONFIG"

# --- 6. PERFIL DE USUARIO ---
# Endpoint: GET /users/profile
# Requisitos: email, role, phone_number
validate_endpoint "Perfil_Usuario" "/users/profile" "id name email phone_number role"


echo ""
if [ $fail_count -eq 0 ]; then
    echo -e "${GREEN}🎉 TODOS LOS TESTS PASARON EXITOSAMENTE${NC}"
else
    echo -e "${RED}⚠️  $fail_count TESTS FALLARON. REVISAR IMPLEMENTACIÓN.${NC}"
fi