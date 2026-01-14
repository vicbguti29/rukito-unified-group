import requests
import json
import time
from sqlalchemy import create_engine, text
import datetime

API_URL = "http://localhost:8080/api"
DB_USER = "root"
DB_PASS = "root"
DB_HOST = "localhost"
DB_PORT = "3306"
DB_NAME = "rukito"
DB_URL = f"mysql+pymysql://{DB_USER}:{DB_PASS}@{DB_HOST}:{DB_PORT}/{DB_NAME}"

def test_history_reliability():
    print("📜 PRUEBA DE FIABILIDAD HISTÓRICA (Paginación, Vacíos, Estado)")
    print("==============================================================")
    
    engine = create_engine(DB_URL)
    conn = engine.connect()

    # 1. SETUP: Inyectar datos masivos para prueba de paginación
    print("\n1. [SETUP] Inyectando 60 alertas de prueba...")
    
    # Asegurar que existe la cámara CF-TEST (Foreign Key)
    conn.execute(text("INSERT IGNORE INTO chambers (id, name, is_active) VALUES ('CF-TEST', 'Test Chamber', 1)"))
    
    # Limpiamos alertas de prueba anteriores
    conn.execute(text("DELETE FROM alerts WHERE title LIKE 'TEST_PAGINATION%'\n"))
    
    alerts_data = []
    base_time = datetime.datetime.now()
    
    for i in range(60):
        # Cada alerta 1 minuto más antigua que la anterior
        ts = base_time - datetime.timedelta(minutes=i)
        alerts_data.append({
            "id": f"PAG-{i}", "sid": "CF-TEST", "title": f"TEST_PAGINATION {i}", 
            "desc": "Testing...", "sev": "WARNING", "cat": "HOT_TEMP", "ts": ts
        })
        
    for a in alerts_data:
        conn.execute(text("""
            INSERT INTO alerts (id, sensor_id, title, description, severity, category, timestamp, is_read)
            VALUES (:id, :sid, :title, :desc, :sev, :cat, :ts, 0)
        """), a)
    conn.commit()
    print("   -> Datos inyectados.")

    # ---------------------------------------------------------
    # CASO 1: PAGINACIÓN DEFAULT
    # ---------------------------------------------------------
    print("\n2. [TEST] Paginación por defecto (Esperado: 50 items)...")
    # Pedimos alertas de CF-TEST sin especificar limite (default backend es 50)
    resp = requests.get(f"{API_URL}/alerts/chamber/CF-TEST")
    
    if resp.status_code == 200:
        items = resp.json()
        count = len(items)
        print(f"   -> Recibidos: {count}")
        
        if count == 50:
            print("   ✅ CORRECTO: El backend respeta el límite por defecto de 50.")
            # Verificar orden (el primero debe ser el más reciente -> PAG-0)
            if items[0]["id"] == "PAG-0":
                print("   ✅ CORRECTO: Orden cronológico descendente (Lo más nuevo primero).")
            else:
                print(f"   ❌ ERROR: Orden incorrecto. Primero fue {items[0]['id']}")
        else:
            print(f"   ❌ ERROR: Se esperaban 50 items, llegaron {count}.")
    else:
        print(f"   ❌ ERROR API: {resp.status_code}")

    # ---------------------------------------------------------
    # CASO 2: RESPUESTA VACÍA SEGURA
    # ---------------------------------------------------------
    print("\n3. [TEST] Consulta de Rango Vacío (Esperado: Lista vacía [], no null)...")
    # Pedimos historia del año 1990
    start_old = "1990-01-01T00:00:00Z"
    end_old = "1990-01-02T00:00:00Z"
    
    resp = requests.get(f"{API_URL}/readings/CF-TEST/history?start={start_old}&end={end_old}")
    
    if resp.status_code == 200:
        raw_text = resp.text
        data = resp.json()
        print(f"   -> Respuesta Raw: {raw_text}")
        
        if isinstance(data, list) and len(data) == 0:
            print("   ✅ CORRECTO: Devuelve lista vacía []. Frontend seguro.")
        elif data is None: # Null en JSON
            print("   ❌ ERROR CRÍTICO: Devuelve 'null'. El frontend explotará.")
        else:
            print(f"   ⚠️ RARO: Devuelve {type(data)} -> {data}")
    else:
        print(f"   ❌ ERROR API: {resp.status_code}")

    # ---------------------------------------------------------
    # CASO 3: CICLO DE VIDA (Marcar como Leído)
    # ---------------------------------------------------------
    print("\n4. [TEST] Marcar Alerta como Leída (PATCH)...")
    target_alert = "PAG-0" # Usamos una de las que creamos
    
    # A. Verificar estado inicial
    check_sql = text("SELECT is_read FROM alerts WHERE id = :id")
    initial_state = conn.execute(check_sql, {"id": target_alert}).scalar()
    print(f"   -> Estado Inicial DB: {initial_state} (0=False)")
    
    if initial_state != 0:
        print("   ⚠️ Estado inicial inválido para la prueba.")
    
    # B. Ejecutar Acción
    patch_url = f"{API_URL}/alerts/{target_alert}/read"
    print(f"   -> PATCH {patch_url}")
    resp = requests.patch(patch_url)
    
    if resp.status_code == 200:
        # C. Verificar Respuesta
        json_resp = resp.json()
        if json_resp.get("is_read") is True:
            print("   ✅ API confirma cambio (JSON response).")
        else:
            print("   ❌ API dice que no cambió.")
            
        # D. Verificar Persistencia en DB
        conn.commit() # Refrescar snapshot de la transacción
        final_state = conn.execute(check_sql, {"id": target_alert}).scalar()
        print(f"   -> Estado Final DB: {final_state}")
        
        if final_state == 1:
            print("   ✅ ÉXITO TOTAL: El cambio persistió en base de datos.")
        else:
            print("   ❌ ERROR CRÍTICO: El cambio NO se guardó en la DB.")
    else:
        print(f"   ❌ ERROR API PATCH: {resp.status_code}")

    # Limpieza final
    conn.execute(text("DELETE FROM chambers WHERE id = 'CF-TEST'"))
    conn.close()

if __name__ == "__main__":
    test_history_reliability()
