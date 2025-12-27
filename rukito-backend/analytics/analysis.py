import pandas as pd
from sqlalchemy.orm import Session
from sqlalchemy import text
import datetime
import os

# Constantes de Negocio
# Según estándares FDA/HACCP, si un alimento perecedero permanece en la "Zona de Peligro"
# por más de 4 horas, se considera no apto para el consumo (Pérdida Total).
CRITICAL_EXPOSURE_LIMIT_HOURS = 4.0
ASSUMED_INVENTORY_KG = 200.0

def get_average_meat_price():
    """
    Lee el archivo de precios de mercado generado por el scraper y calcula el promedio.
    Si no existe, retorna un valor por defecto.
    """
    csv_path = "../datos/precios_mercado.csv"
    
    # Intentar ruta relativa desde la carpeta analytics
    if not os.path.exists(csv_path):
        # Fallback para ejecución desde tests
        csv_path = "../../datos/precios_mercado.csv"

    if os.path.exists(csv_path):
        try:
            df = pd.read_csv(csv_path)
            if not df.empty and 'precio_kg' in df.columns:
                return df['precio_kg'].mean()
        except Exception as e:
            print(f"Error leyendo precios de mercado: {e}")
            
    return 25.50 # Precio default (aprox $25/kg)

def calculate_rate_of_change(db: Session, sensor_id: str, minutes: int = 30):
    """
    Calcula dT/dt (grados por minuto) en el rango de tiempo especificado.
    """
    query = text("""
        SELECT temperature, timestamp 
        FROM temperature_readings 
        WHERE sensor_id = :sensor_id 
        AND timestamp >= NOW() - INTERVAL :minutes MINUTE
        ORDER BY timestamp ASC
    """)
    
    result = db.execute(query, {"sensor_id": sensor_id, "minutes": minutes}).fetchall()
    
    if len(result) < 2:
        return 0.0

    df = pd.DataFrame(result, columns=['temp', 'time'])
    
    # Asegurar que la temperatura sea float para evitar conflictos con Decimal
    df['temp'] = df['temp'].astype(float)
    
    # Calcular diferencia de temperatura y tiempo
    temp_diff = df['temp'].iloc[-1] - df['temp'].iloc[0]
    time_diff = (df['time'].iloc[-1] - df['time'].iloc[0]).total_seconds() / 60.0 # en minutos
    
    if time_diff == 0:
        return 0.0
        
    return round(temp_diff / time_diff, 4)

def get_chamber_kpis(db: Session, sensor_id: str, timeframe_minutes: int = 30):
    """
    Genera los KPIs requeridos por el frontend.
    El periodo es configurable en minutos (preparado para integración con frontend).
    """
    # --- CÁLCULO PRECISO DE TIEMPO EN RIESGO ---
    # Traemos un buffer de datos más amplio para evitar problemas de timezone en SQL vs App
    # Filtramos la ventana exacta en Python.
    query_raw_risk = text("""
        SELECT timestamp, temperature, warning_threshold
        FROM temperature_readings tr
        JOIN chambers c ON tr.sensor_id = c.id
        WHERE tr.sensor_id = :sensor_id 
        ORDER BY tr.timestamp ASC
        LIMIT 2000
    """)
    
    risk_rows = db.execute(query_raw_risk, {"sensor_id": sensor_id}).fetchall()
    
    hours_at_risk = 0.0
    
    if risk_rows:
        df_risk = pd.DataFrame(risk_rows, columns=['timestamp', 'temperature', 'threshold'])
        df_risk['timestamp'] = pd.to_datetime(df_risk['timestamp'])
        
        # Filtro estricto en Python: Últimos X minutos exactos
        # Usamos el tiempo de la última lectura como referencia "NOW" para ser consistentes con los datos
        # si los datos son antiguos, o datetime.now() si son en tiempo real.
        # Para evitar problemas si la BD está en UTC y el sistema no, usamos la última lectura como ancla.
        last_reading_time = df_risk['timestamp'].max()
        cutoff_time = last_reading_time - datetime.timedelta(minutes=timeframe_minutes)
        
        df_window = df_risk[df_risk['timestamp'] >= cutoff_time].copy()
        
        if not df_window.empty:
            # Calcular la diferencia de tiempo con la lectura siguiente
            df_window['next_timestamp'] = df_window['timestamp'].shift(-1)
            df_window['duration_hours'] = (df_window['next_timestamp'] - df_window['timestamp']).dt.total_seconds() / 3600.0
            
            critical_periods = df_window[
                (df_window['temperature'] > df_window['threshold']) & 
                (df_window['duration_hours'] < 0.2) # Max gap 12 min
            ]
            
            hours_at_risk = critical_periods['duration_hours'].sum()

    # Obtener precio promedio del mercado real
    avg_price_kg = get_average_meat_price()
    
    # Riesgo = (Horas en Riesgo / Límite Crítico) * Valor del Inventario
    risk_factor = min(hours_at_risk / CRITICAL_EXPOSURE_LIMIT_HOURS, 1.0)
    estimated_cost = round(risk_factor * (avg_price_kg * ASSUMED_INVENTORY_KG), 2)

    # Calcular Total de Alertas Reales en el intervalo
    query_alerts = text("""
        SELECT COUNT(*) 
        FROM alerts 
        WHERE sensor_id = :sensor_id 
        AND timestamp >= NOW() - INTERVAL :minutes MINUTE
    """)
    total_alerts = db.execute(query_alerts, {"sensor_id": sensor_id, "minutes": timeframe_minutes}).scalar() or 0

    # Calcular Uptime (Confiabilidad)
    # Esperamos 1 lectura cada 5 segundos -> 12 lecturas por minuto
    expected_readings = float(timeframe_minutes * 12)
    
    query_readings_count = text("""
        SELECT COUNT(*) 
        FROM temperature_readings 
        WHERE sensor_id = :sensor_id 
        AND timestamp >= NOW() - INTERVAL :minutes MINUTE
    """)
    actual_readings = db.execute(query_readings_count, {"sensor_id": sensor_id, "minutes": timeframe_minutes}).scalar() or 0
    
    uptime = 0.0
    if expected_readings > 0:
        uptime = (actual_readings / expected_readings) * 100.0
    
    uptime_percentage = round(min(uptime, 100.0), 2)

    return {
        "chamber_id": sensor_id,
        "hours_at_risk": round(hours_at_risk, 4),
        "estimated_cost": estimated_cost,
        "uptime_percentage": uptime_percentage,
        "avg_rate_of_change": calculate_rate_of_change(db, sensor_id, timeframe_minutes),
        "total_alerts": total_alerts,
        "timeframe_minutes": timeframe_minutes
    }
