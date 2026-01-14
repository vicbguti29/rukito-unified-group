import requests
import datetime
import json
import time

API_URL = "http://localhost:8080/api"
SENSOR_ID = "CF-1"

def test_scenarios():
    print("🧪 PRUEBA DE ESCENARIOS DE TIEMPO (Downsampling & Escasez)")
    print("==========================================================")
    
    now = datetime.datetime.now()
    
    # ---------------------------------------------------------
    # CASO 1: DOWNSAMPLING (Pedir 3 Días)
    # Objetivo: Verificar que el backend no explota usando la query de agrupación por horas
    # ---------------------------------------------------------
    print("\n1. [TEST] Solicitud de Largo Alcance (3 Días -> Downsampling)...")
    start_3d = (now - datetime.timedelta(days=3)).isoformat()
    end_now = now.isoformat()
    
    url_3d = f"{API_URL}/reports/{SENSOR_ID}?start={start_3d}Z&end={end_now}Z"
    
    try:
        t0 = time.time()
        resp = requests.get(url_3d)
        duration = time.time() - t0
        
        if resp.status_code == 200:
            data = resp.json()
            # Verificar que obtuvimos respuesta válida
            print(f"   ✅ Respuesta OK en {round(duration, 3)}s")
            print(f"   -> Horas analizadas: {data.get('timeframe_minutes', 0) / 60}")
        else:
            print(f"   ❌ Falló request 3 días: {resp.status_code}")
            print(resp.text)
            
    except Exception as e:
        print(f"   ❌ Excepción: {e}")

    # ---------------------------------------------------------
    # CASO 2: ESCASEZ DE DATOS (Pedir 90 Días con data de 1 día)
    # Objetivo: Verificar KPI de Confiabilidad y que no haya errores matemáticos
    # ---------------------------------------------------------
    print("\n2. [TEST] Solicitud Masiva con Data Pobre (90 Días)...")
    start_90d = (now - datetime.timedelta(days=90)).isoformat()
    
    url_90d = f"{API_URL}/reports/{SENSOR_ID}?start={start_90d}Z&end={end_now}Z"
    
    try:
        resp = requests.get(url_90d)
        if resp.status_code == 200:
            data = resp.json()
            uptime = data.get('uptime_percentage', 100)
            print(f"   ✅ Respuesta OK")
            print(f"   -> KPI Confiabilidad (Uptime): {uptime}%")
            
            if uptime < 5.0:
                print("   ✅ Validado: El sistema reporta correctamente la falta de datos (Uptime bajo).")
            else:
                print(f"   ⚠️ Alerta: El uptime es sospechosamente alto ({uptime}%) para 90 días sin data.")
        else:
            print(f"   ❌ Falló request 90 días: {resp.status_code}")
            
    except Exception as e:
        print(f"   ❌ Excepción: {e}")

if __name__ == "__main__":
    test_scenarios()
