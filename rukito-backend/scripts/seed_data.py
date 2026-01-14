import random
import datetime
from sqlalchemy import create_engine, text
import os
from dotenv import load_dotenv
import json

# Cargar variables
env_path = os.path.join(os.path.dirname(__file__), '../.env')
load_dotenv(env_path)

DB_USER = os.getenv("DB_USER", "root")
DB_PASS = os.getenv("DB_PASSWORD", "root")
DB_HOST = os.getenv("DB_HOST", "localhost")
DB_PORT = os.getenv("DB_PORT", "3306")
DB_NAME = os.getenv("DB_NAME", "rukito")

DB_URL = f"mysql+pymysql://{DB_USER}:{DB_PASS}@{DB_HOST}:{DB_PORT}/{DB_NAME}"

def generate_demo_data():
    print("🌱 Iniciando generación de datos DEMO EXTENDIDA (3 Días)...")
    
    try:
        engine = create_engine(DB_URL)
        connection = engine.connect()
    except Exception as e:
        print(f"❌ Error conectando a la BD: {e}")
        return

    # 1. Limpieza
    print("🧹 Limpiando historial...")
    connection.execute(text("DELETE FROM alerts"))
    connection.execute(text("DELETE FROM temperature_readings"))
    
    # 2. Configuración Base
    # CF-1: Congelador Carnes (Crítico > -10)
    # CF-2: Lácteos (Crítico > 10)
    # REF-3: Verduras (Crítico > 8)
    configs = [
        ("CF-1", -30.0, -20.0, -15.0, -10.0), 
        ("CF-2", -5.0, 4.0, 7.0, 10.0),   
        ("REF-3", -2.0, 2.0, 5.0, 8.0)  
    ]
    
    for sid, c_cold, target, w_hot, c_hot in configs:
        actions_warn = json.dumps({"channels": ["push"], "target_roles": ["staff"]})
        actions_crit = json.dumps({"channels": ["push", "email"], "target_roles": ["admin"]})
        
        sql = text("""
            INSERT INTO alert_configs (id, sensor_id, threshold_critical_cold, threshold_target, threshold_warning_hot, threshold_critical_hot, 
                                     rate_of_change_threshold, actions_warning_hot, actions_critical_hot, actions_critical_cold, is_enabled)
            VALUES (:id, :sid, :cc, :tg, :wh, :ch, 0.5, :aw, :ac, :ac, 1)
            ON DUPLICATE KEY UPDATE threshold_critical_hot=:ch, threshold_target=:tg, threshold_warning_hot=:wh
        """)
        connection.execute(sql, {
            "id": f"CONF-{sid}", "sid": sid, "cc": c_cold, "tg": target, 
            "wh": w_hot, "ch": c_hot, "aw": actions_warn, "ac": actions_crit
        })
    connection.commit()

    # 3. Generación de Historia (3 Días = 4320 minutos)
    MINUTES_HISTORY = 4320 
    now = datetime.datetime.now()
    records_count = 0
    
    print(f"📊 Generando {MINUTES_HISTORY} minutos de historia por sensor...")

    # Definición de Guiones
    # CF-1: Caos Total Reciente. Estable antes, pero en las últimas 6 horas sube sin control.
    # CF-2: Recuperación. Crisis ayer, hoy mejorando pero inestable (Warning).
    # REF-3: Perfecto. Siempre en rango.

    sensors = ["CF-1", "CF-2", "REF-3"]
    
    readings_buffer = []
    alerts_buffer = []

    for i in range(MINUTES_HISTORY, -1, -1): # Desde hace 3 días hasta ahora
        timestamp = now - datetime.timedelta(minutes=i)
        
        for sensor_id in sensors:
            noise = random.uniform(-0.2, 0.2)
            temp = 0.0
            
            # --- Lógica del Director de Cine ---
            
            if sensor_id == "CF-1":
                # Base: -20. Límite Crítico: -10.
                if i > 360: # Antes de las últimas 6 horas
                    temp = -20.0 + noise # Estable
                else:
                    # Crisis progresiva: Sube de -20 a -5 en 6 horas
                    # Pendiente: 15 grados en 360 minutos = 0.04 grados/min
                    progress = (360 - i) * 0.045 
                    temp = -20.0 + progress + (noise * 2) # Más ruido en crisis

            elif sensor_id == "CF-2":
                # Base: 4.0. Límite Crítico: 10. Warning: 7.
                # Ayer (entre minuto 2800 y 1400 atrás) tuvo crisis
                if 1400 < i < 2800:
                    temp = 11.0 + (noise * 3) # Crítico sostenido (Puerta mal cerrada)
                elif i <= 1400:
                    # Se arregló, bajó rápido a 7.5 (Warning) y oscila ahí
                    temp = 7.5 + random.uniform(-0.8, 0.8) # Oscila entre warning y normal alto
                else:
                    temp = 4.0 + noise # Hace 3 días estaba bien

            elif sensor_id == "REF-3":
                # Base: 2.0. Siempre bien.
                temp = 2.0 + noise

            # --- Evaluación de Estado ---
            # Necesitamos los límites para saber el estado. Hardcodeamos los del config para velocidad.
            limits = {
                "CF-1": {"crit": -10.0, "warn": -15.0},
                "CF-2": {"crit": 10.0, "warn": 7.0},
                "REF-3": {"crit": 8.0, "warn": 5.0}
            }
            lim = limits[sensor_id]
            
            status = "NORMAL"
            severity = None
            category = "HOT_TEMP"

            if temp > lim["crit"]:
                status = "CRITICAL_HOT"
                severity = "CRITICAL"
            elif temp > lim["warn"]:
                status = "WARNING_HOT"
                severity = "WARNING"

            # Agregar a buffer de lecturas
            readings_buffer.append({
                "sid": sensor_id, "temp": round(temp, 2), "rate": round(noise, 3),
                "status": status, "ts": timestamp
            })
            
            # Generar Alertas (Esporádicas para no saturar)
            # Críticas: cada 30 min. Warning: cada 60 min.
            if severity:
                should_alert = False
                if severity == "CRITICAL" and i % 30 == 0: should_alert = True
                if severity == "WARNING" and i % 60 == 0: should_alert = True
                
                if should_alert:
                    alerts_buffer.append({
                        "id": f"ALT-{random.randint(100000,999999)}",
                        "sid": sensor_id,
                        "title": f"Alerta {sensor_id}",
                        "desc": f"Temperatura {status}: {round(temp,1)}°C",
                        "sev": severity, "cat": category, "cost": 500.0 if severity=="CRITICAL" else 0.0,
                        "chan": '["push"]', "ts": timestamp
                    })

    # Bulk Insert (Mucho más rápido que uno por uno)
    print("💾 Insertando lecturas en bloque...")
    # Partimos en bloques de 1000 para no ahogar la query
    chunk_size = 1000
    for k in range(0, len(readings_buffer), chunk_size):
        chunk = readings_buffer[k:k+chunk_size]
        connection.execute(text("""
            INSERT INTO temperature_readings (sensor_id, temperature, rate_of_change, status, timestamp)
            VALUES (:sid, :temp, :rate, :status, :ts)
        """), chunk)
        records_count += len(chunk)

    print(f"💾 Insertando {len(alerts_buffer)} alertas...")
    if alerts_buffer:
        connection.execute(text("""
            INSERT INTO alerts (id, sensor_id, title, description, severity, category, is_read, estimated_cost, channels, timestamp)
            VALUES (:id, :sid, :title, :desc, :sev, :cat, 0, :cost, :chan, :ts)
        """), alerts_buffer)

    connection.commit()
    connection.close()
    print(f"✅ ¡Base de datos poblada con {records_count} registros! (3 Días)")

if __name__ == "__main__":
    generate_demo_data()