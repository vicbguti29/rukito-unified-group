import sys
import os
import datetime
import random
from sqlalchemy import create_engine, text
import requests
import json
import time

# Configuración de rutas relativa al script
# tests/ está un nivel abajo de backend/, y analytics/ está en backend/analytics
current_dir = os.path.dirname(os.path.abspath(__file__))
analytics_path = os.path.join(current_dir, '..', 'analytics')
sys.path.append(analytics_path)

from database import get_db

# URLs
API_URL = "http://localhost:8080/api"

# DB Connection
DB_USER = "root"
DB_PASS = "root"
DB_HOST = "localhost"
DB_PORT = "3306"
DB_NAME = "rukito"
DB_URL = f"mysql+pymysql://{DB_USER}:{DB_PASS}@{DB_HOST}:{DB_PORT}/{DB_NAME}"

def run_logic_test():
    print("🧪 INICIANDO PRUEBA DE LÓGICA DE NEGOCIO Y ANALÍTICA")
    print("===================================================")
    
    engine = create_engine(DB_URL)
    conn = engine.connect()

    # 1. PREPARACIÓN: Limpiar CF-1
    print("1. [SETUP] Limpiando datos de CF-1...")
    conn.execute(text("DELETE FROM temperature_readings WHERE sensor_id = 'CF-1'"))
    conn.execute(text("DELETE FROM alerts WHERE sensor_id = 'CF-1'"))
    
    conn.execute(text("""
        UPDATE alert_configs 
        SET threshold_warning_hot = -15.0, threshold_critical_hot = -10.0 
        WHERE sensor_id = 'CF-1'
    """))
    conn.commit()

    # 2. INYECCIÓN DE GUION (Últimas 5 horas)
    print("2. [INJECTION] Insertando escenario controlado...")
    
    # Sincronización de Tiempo: Obtener hora de la BD para alinear la inyección
    db_now = conn.execute(text("SELECT NOW()")).scalar()
    print(f"   -> DB Time: {db_now} | Python Time: {datetime.datetime.now()}")
    
    # Usamos la hora de la DB como ancla
    start_time = db_now - datetime.timedelta(hours=5)
    
    readings = []
    alerts = []
    
    for i in range(300): # 300 minutos = 5 horas
        ts = start_time + datetime.timedelta(minutes=i)
        
        if i < 180: # Primeras 3 horas (Normal)
            temp = -20.0 + random.uniform(-0.1, 0.1)
            status = "NORMAL"
        else: # Últimas 2 horas (CRISIS)
            temp = -5.0 + random.uniform(-0.1, 0.1) 
            status = "CRITICAL_HOT"
            
            if i % 30 == 0: 
                alerts.append({
                    "id": f"TEST-{i}", "sid": "CF-1", "title": "Test Alert", 
                    "sev": "CRITICAL", "cat": "HOT_TEMP", "ts": ts
                })

        readings.append({
            "sid": "CF-1", "temp": temp, "rate": 0.1, "status": status, "ts": ts
        })

    # Bulk Insert Lecturas
    for r in readings:
        conn.execute(text("""
            INSERT INTO temperature_readings (sensor_id, temperature, rate_of_change, status, timestamp)
            VALUES (:sid, :temp, :rate, :status, :ts)
        """), r)
        
    # Bulk Insert Alertas (con canales default)
    for a in alerts:
        conn.execute(text("""
            INSERT INTO alerts (id, sensor_id, title, severity, category, timestamp, channels)
            VALUES (:id, :sid, :title, :sev, :cat, :ts, '["test"]')
        """), a)
        
    conn.commit()
    print(f"   -> Inyectadas {len(readings)} lecturas y {len(alerts)} alertas.")

    # 3. VERIFICACIÓN
    print("3. [VERIFY] Consultando API de Reportes...")
    time.sleep(1)
    
    try:
        # El backend Go espera start/end en formato ISO
        start_iso = start_time.isoformat()
        end_iso = db_now.isoformat()
        
        url = f"{API_URL}/reports/CF-1?start={start_iso}Z&end={end_iso}Z"
        print(f"   -> Requesting: {url}")
        response = requests.get(url)
        
        if response.status_code != 200:
            print(f"❌ ERROR API: {response.status_code} - {response.text}")
            return

        data = response.json()
        
        failures = []
        
        # A. Horas en Riesgo
        risk = data.get("hours_at_risk", 0)
        print(f"   -> Horas en Riesgo reportadas: {risk}")
        # Ajustamos el rango aceptable. Si hay desfase de segundos puede ser 1.98 o 2.02
        if not (1.8 <= risk <= 2.2):
            failures.append(f"Cálculo de riesgo incorrecto. Esperado ~2.0, Recibido {risk}")

        # B. Detección de Causas
        causes = data.get("alert_causes", {})
        print(f"   -> Causas detectadas: {causes}")
        
        # Verificamos tipo de dato
        if not isinstance(causes, dict):
             failures.append(f"alert_causes no es un diccionario. Es {type(causes)}")
        else:
             if "Puerta Abierta" not in causes and "Falla Compresor" not in causes:
                 failures.append("Fallo en inferencia de causas. No detectó problemas mecánicos/físicos.")

        # C. Texto de Insights
        text_analysis = data.get("analysis_risk_text", "")
        print(f"   -> Texto generado: '{text_analysis}'")
        if "ALTO RIESGO" not in text_analysis and "ADVERTENCIA" not in text_analysis:
            failures.append("El texto de análisis no refleja la gravedad de la crisis simulada.")

        if not failures:
            print("\n✅ ¡PRUEBA LÓGICA EXITOSA! El cerebro del sistema funciona correctamente.")
        else:
            print("\n❌ PRUEBA FALLIDA. Errores encontrados:")
            for f in failures:
                print(f"   - {f}")

    except Exception as e:
        import traceback
        traceback.print_exc()
        print(f"❌ Excepción ejecutando test: {e}")
    finally:
        conn.close()

if __name__ == "__main__":
    run_logic_test()