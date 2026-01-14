import requests
import json
import sys

API_URL = "http://localhost:8080/api"
SENSOR_ID = "CF-1"

def test_config_round_trip():
    print(f"🧪 INICIANDO PRUEBA DE PERSISTENCIA JSON (Round-Trip) para {SENSOR_ID}")
    print("=====================================================================")

    # 1. Obtener estado original (Backup)
    print("1. [BACKUP] Leyendo configuración actual...")
    resp = requests.get(f"{API_URL}/config/alerts/{SENSOR_ID}")
    if resp.status_code != 200:
        print(f"❌ Error leyendo config inicial: {resp.status_code}")
        return
    original_config = resp.json()
    print("   -> Backup realizado.")

    # 2. Definir Payload de Prueba (Datos Complejos)
    # Usamos valores únicos para asegurar que no estamos leyendo datos cacheados o por defecto
    test_channels = ["sms", "whatsapp", "pager"] 
    test_roles = ["manager", "external_auditor"]
    
    test_payload = {
        "sensor_id": SENSOR_ID,
        "thresholds": {
            "critical_cold": -35.5, # Decimal específico
            "target": -22.0,
            "warning_hot": -18.0,
            "critical_hot": -12.5,
            "rate_of_change": 1.5
        },
        "notifications": {
            # Probamos anidación profunda
            "on_warning_hot": {
                "channels": ["push"], 
                "target_roles": ["staff"]
            },
            "on_critical_hot": {
                "channels": test_channels, # <--- VERIFICACIÓN CLAVE
                "target_roles": test_roles
            },
            "on_critical_cold": {
                "channels": ["email"], 
                "target_roles": ["technician"]
            }
        },
        "is_enabled": True
    }

    print("2. [UPDATE] Enviando nueva configuración compleja...")
    # Imprimimos lo que vamos a enviar para debug visual
    # print(json.dumps(test_payload, indent=2))
    
    resp = requests.put(f"{API_URL}/config/alerts/{SENSOR_ID}", json=test_payload)
    if resp.status_code != 200:
        print(f"❌ Error en PUT: {resp.status_code} - {resp.text}")
        return
    
    # 3. Leer de nuevo (Round-Trip)
    print("3. [VERIFY] Leyendo configuración desde la BD...")
    resp = requests.get(f"{API_URL}/config/alerts/{SENSOR_ID}")
    new_config = resp.json()

    # 4. Comparación Profunda
    print("4. [ASSERT] Comparando datos enviados vs recibidos...")
    
    failures = []

    # A. Verificar Umbrales (Floats)
    sent_thresh = test_payload["thresholds"]
    recv_thresh = new_config.get("thresholds", {})
    
    if recv_thresh.get("critical_cold") != sent_thresh["critical_cold"]:
        failures.append(f"Umbral incorrecto. Enviado {sent_thresh['critical_cold']}, Recibido {recv_thresh.get('critical_cold')}")

    # B. Verificar Estructura JSON Anidada (Arrays y Strings)
    recv_notif = new_config.get("notifications", {})
    recv_crit_hot = recv_notif.get("on_critical_hot", {})
    
    # Verificar Canales
    recv_channels = recv_crit_hot.get("channels", [])
    # Ordenamos listas para comparar contenido sin importar orden
    if sorted(recv_channels) != sorted(test_channels):
        failures.append(f"JSON Array corrupto (Channels). Enviado {test_channels}, Recibido {recv_channels}")

    # Verificar Roles
    recv_roles = recv_crit_hot.get("target_roles", [])
    if sorted(recv_roles) != sorted(test_roles):
        failures.append(f"JSON Array corrupto (Roles). Enviado {test_roles}, Recibido {recv_roles}")

    # 5. Resultado y Restauración
    if not failures:
        print("\n✅ ¡ÉXITO! La persistencia de datos complejos JSON funciona perfectamente.")
    else:
        print("\n❌ FALLO DE INTEGRIDAD DE DATOS:")
        for f in failures:
            print(f"   - {f}")
            
    # Restaurar
    print("\n5. [CLEANUP] Restaurando configuración original...")
    requests.put(f"{API_URL}/config/alerts/{SENSOR_ID}", json=original_config)
    print("   -> Restaurado.")

if __name__ == "__main__":
    test_config_round_trip()
