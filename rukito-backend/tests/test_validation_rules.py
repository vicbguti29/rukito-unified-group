import requests
import json

API_URL = "http://localhost:8080/api"
SENSOR_ID = "CF-1"

def test_validations():
    print("🛡️  PRUEBA DE VALIDACIONES DE NEGOCIO (Backend Shield)")
    print("=====================================================")
    
    # Payload Base (Válido)
    valid_payload = {
        "sensor_id": SENSOR_ID,
        "thresholds": {
            "critical_cold": -30.0,
            "target": -20.0,
            "warning_hot": -15.0,
            "critical_hot": -10.0,
            "rate_of_change": 1.0
        },
        "notifications": {}, # Simplificado
        "is_enabled": True
    }

    # CASO 1: Crítico Frío > Crítico Calor (Imposible)
    print("\n1. [TEST] Enviando incoherencia física (Frío > Calor)...")
    bad_payload = valid_payload.copy()
    bad_payload["thresholds"] = {
        "critical_cold": 0.0,
        "target": -20.0,
        "warning_hot": -15.0,
        "critical_hot": -10.0, # -10 es MENOR que 0. Error.
        "rate_of_change": 1.0
    }
    
    resp = requests.put(f"{API_URL}/config/alerts/{SENSOR_ID}", json=bad_payload)
    if resp.status_code == 400:
        print(f"   ✅ RECHAZADO CORRECTAMENTE (400): {resp.text.strip()}")
    else:
        print(f"   ❌ ACEPTADO INCORRECTAMENTE ({resp.status_code}). El backend permitió física imposible.")

    # CASO 2: Objetivo fuera de rango seguro (Target > Warning)
    print("\n2. [TEST] Enviando Target peligroso (Target > Warning)...")
    bad_payload_2 = valid_payload.copy()
    bad_payload_2["thresholds"] = {
        "critical_cold": -30.0,
        "target": -5.0, # Mayor que Warning (-15)
        "warning_hot": -15.0,
        "critical_hot": -10.0,
        "rate_of_change": 1.0
    }
    
    resp = requests.put(f"{API_URL}/config/alerts/{SENSOR_ID}", json=bad_payload_2)
    if resp.status_code == 400:
        print(f"   ✅ RECHAZADO CORRECTAMENTE (400): {resp.text.strip()}")
    else:
        print(f"   ❌ ACEPTADO INCORRECTAMENTE ({resp.status_code}). El backend permitió configuración inestable.")

if __name__ == "__main__":
    test_validations()
