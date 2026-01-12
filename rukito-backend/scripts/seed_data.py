import random
import datetime
from sqlalchemy import create_engine, text
import os
from dotenv import load_dotenv

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
    print("🌱 Iniciando generación de datos MEJORADA...")
    
    try:
        engine = create_engine(DB_URL)
        connection = engine.connect()
    except Exception as e:
        print(f"❌ Error conectando a la BD: {e}")
        return

    # 1. Limpieza
    print("🧹 Limpiando tablas de historial...")
    connection.execute(text("DELETE FROM temperature_readings"))
    connection.execute(text("DELETE FROM alerts"))
    
    # 2. Asegurar Configuración Base (Para que no falle el Update Config)
    print("⚙️ Asegurando configuraciones para las 3 cámaras...")
    configs = [
        # ID, Sensor, Max(Calor), Min(Frio), Prioridad
        # CF-1: Congelador. Alerta si sube de -15 (calor) o baja de -30 (frío extremo)
        ("CONFIG-CF-1", "CF-1", -15.0, -30.0, 0), 
        # CF-2: Refrigerador. Alerta si sube de 10 o baja de 0
        ("CONFIG-CF-2", "CF-2", 10.0, 0.0, 1),   
        # REF-3: Refrigerador Verduras.
        ("CONFIG-REF-3", "REF-3", 8.0, 0.0, 2)  
    ]
    
    for cid, sid, max_t, min_t, prio in configs:
        # Upsert (Insertar si no existe, actualizar si existe)
        sql = text("""
            INSERT INTO alert_configs (id, sensor_id, max_temperature, min_temperature, rate_of_change_threshold, priority, is_enabled, notification_channels, recipients)
            VALUES (:id, :sid, :max, :min, 0.5, :prio, 1, '["push"]', '["+593999999"]')
            ON DUPLICATE KEY UPDATE max_temperature=:max
        """)
        connection.execute(sql, {"id": cid, "sid": sid, "max": max_t, "min": min_t, "prio": prio})

    connection.commit()

    # 3. Escenarios de Simulación
    sensors = [
        {"id": "CF-1", "base": -20.0, "type": "CRISIS", "limit": -18.0},
        {"id": "CF-2", "base": 4.0, "type": "OSCILLATION", "limit": 8.0},
        {"id": "REF-3", "base": 2.0, "type": "STABLE", "limit": 5.0},
    ]

    now = datetime.datetime.now()
    records_count = 0

    print("📊 Generando 300 minutos de historia para 3 cámaras...")

    for sensor in sensors:
        current_temp = sensor["base"]
        
        for i in range(300, -1, -1): # 5 horas atrás
            timestamp = now - datetime.timedelta(minutes=i)
            noise = random.uniform(-0.3, 0.3)
            
            # Lógica de escenarios
            if sensor["type"] == "CRISIS":
                # Empieza bien, pero en los últimos 45 min sube descontrolado
                if i < 45:
                    current_temp += 0.15 # Sube rápido
                    noise = random.uniform(0, 0.2)
                else:
                    current_temp = sensor["base"] + noise

            elif sensor["type"] == "OSCILLATION":
                # Cada 60 minutos simula puerta abierta (sube 4 grados)
                cycle = i % 60
                if cycle < 10: # Duración del evento 10 min
                    current_temp = sensor["base"] + 3.0 + noise # Warning
                else:
                    current_temp = sensor["base"] + noise

            elif sensor["type"] == "STABLE":
                current_temp = sensor["base"] + noise

            # Determinar Status
            status = "NORMAL"
            if current_temp > sensor["limit"]:
                status = "CRÍTICO"
            elif current_temp > (sensor["limit"] - 1.0):
                status = "ADVERTENCIA"

            # Insertar Lectura
            connection.execute(text("""
                INSERT INTO temperature_readings (sensor_id, temperature, rate_of_change, status, timestamp)
                VALUES (:sid, :temp, :rate, :status, :ts)
            """), {
                "sid": sensor["id"],
                "temp": round(current_temp, 2),
                "rate": round(noise, 3),
                "status": status,
                "ts": timestamp
            })
            records_count += 1

            # Generar Alerta (Solo 1 por evento para no saturar)
            if status == "CRÍTICO" and i % 20 == 0: 
                connection.execute(text("""
                    INSERT INTO alerts (id, title, description, priority, type, sensor_id, is_read, estimated_cost, timestamp)
                    VALUES (:id, :title, :desc, 0, 0, :sid, 0, 5000.0, :ts)
                """), {
                    "id": f"ALT-{random.randint(10000,99999)}",
                    "title": f"ALERTA {sensor['id']}",
                    "desc": f"Temp alta: {round(current_temp,1)}°C",
                    "sid": sensor["id"],
                    "ts": timestamp
                })
            
            elif status == "ADVERTENCIA" and i % 30 == 0:
                 connection.execute(text("""
                    INSERT INTO alerts (id, title, description, priority, type, sensor_id, is_read, estimated_cost, timestamp)
                    VALUES (:id, :title, :desc, 1, 1, :sid, 0, 0.0, :ts)
                """), {
                    "id": f"ALT-{random.randint(10000,99999)}",
                    "title": f"Advertencia {sensor['id']}",
                    "desc": f"Oscilación detectada: {round(current_temp,1)}°C",
                    "sid": sensor["id"],
                    "ts": timestamp
                })

    connection.commit()
    connection.close()
    print(f"✅ ¡Base de datos poblada con {records_count} registros!")

if __name__ == "__main__":
    generate_demo_data()