import pandas as pd
from sqlalchemy.orm import Session
from sqlalchemy import text
import datetime
import os
import random

# Constantes de Negocio
CRITICAL_EXPOSURE_LIMIT_HOURS = 4.0
ASSUMED_INVENTORY_KG = 200.0

def get_average_meat_price():
    csv_path = "../datos/precios_mercado.csv"
    if not os.path.exists(csv_path):
        csv_path = "../../datos/precios_mercado.csv"

    if os.path.exists(csv_path):
        try:
            df = pd.read_csv(csv_path)
            if not df.empty and 'precio_kg' in df.columns:
                return df['precio_kg'].mean()
        except Exception as e:
            print(f"Error leyendo precios de mercado: {e}")
            
    return 25.50

def calculate_rate_of_change(db: Session, sensor_id: str, minutes: int = 30):
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
    df['temp'] = df['temp'].astype(float)
    
    temp_diff = df['temp'].iloc[-1] - df['temp'].iloc[0]
    time_diff = (df['time'].iloc[-1] - df['time'].iloc[0]).total_seconds() / 60.0
    
    if time_diff == 0:
        return 0.0
        
    return round(temp_diff / time_diff, 4)

def get_chamber_kpis(db: Session, sensor_id: str, timeframe_minutes: int = 30):
    # 1. Obtener Umbrales desde alert_configs
    query_config = text("""
        SELECT threshold_critical_cold, threshold_critical_hot, threshold_warning_hot
        FROM alert_configs 
        WHERE sensor_id = :sensor_id
    """)
    config_row = db.execute(query_config, {"sensor_id": sensor_id}).fetchone()
    
    # Valores por defecto si no hay config
    crit_hot = -10.0
    crit_cold = -30.0
    if config_row:
        crit_cold = float(config_row[0])
        crit_hot = float(config_row[1])

    # 2. Calcular Tiempo en Riesgo
    # Downsampling: Si el periodo es > 24h, agrupamos por hora en SQL para eficiencia
    if timeframe_minutes >= 1440:
        query_text = """
            SELECT DATE_FORMAT(timestamp, '%Y-%m-%d %H:00:00') as ts, AVG(temperature) as temp
            FROM temperature_readings
            WHERE sensor_id = :sensor_id 
            AND timestamp >= NOW() - INTERVAL :minutes MINUTE
            GROUP BY ts
            ORDER BY ts ASC
        """
    else:
        query_text = """
            SELECT timestamp, temperature
            FROM temperature_readings
            WHERE sensor_id = :sensor_id 
            AND timestamp >= NOW() - INTERVAL :minutes MINUTE
            ORDER BY timestamp ASC
        """
    
    query_raw_risk = text(query_text)
    risk_rows = db.execute(query_raw_risk, {"sensor_id": sensor_id, "minutes": timeframe_minutes}).fetchall()
    
    hours_at_risk = 0.0
    
    if risk_rows:
        df_risk = pd.DataFrame(risk_rows, columns=['timestamp', 'temperature'])
        df_risk['timestamp'] = pd.to_datetime(df_risk['timestamp'])
        df_risk['temperature'] = df_risk['temperature'].astype(float)
        
        # Calcular delta tiempo
        df_risk['next_timestamp'] = df_risk['timestamp'].shift(-1)
        df_risk['duration_hours'] = (df_risk['next_timestamp'] - df_risk['timestamp']).dt.total_seconds() / 3600.0
        
        # Filtrar periodos donde T > Critical Hot OR T < Critical Cold
        critical_periods = df_risk[
            ((df_risk['temperature'] > crit_hot) | (df_risk['temperature'] < crit_cold)) &
            (df_risk['duration_hours'] < 0.2) # Evitar huecos grandes
        ]
        
        hours_at_risk = critical_periods['duration_hours'].sum()

    # 3. Costos
    avg_price_kg = get_average_meat_price()
    risk_factor = min(hours_at_risk / CRITICAL_EXPOSURE_LIMIT_HOURS, 1.0)
    estimated_cost = round(risk_factor * (avg_price_kg * ASSUMED_INVENTORY_KG), 2)

    # 4. Conteo de Alertas
    query_alerts = text("""
        SELECT severity, category, COUNT(*) as count
        FROM alerts 
        WHERE sensor_id = :sensor_id 
        AND timestamp >= NOW() - INTERVAL :minutes MINUTE
        GROUP BY severity, category
    """)
    alerts_result = db.execute(query_alerts, {"sensor_id": sensor_id, "minutes": timeframe_minutes}).fetchall()
    
    total_alerts = 0
    critical_alerts = 0
    
    # Inicializar contadores de causas
    alert_causes = {
        "Puerta Abierta": 0,
        "Falla Compresor": 0,
        "Deshielo": 0,
        "Carga Producto": 0
    }
    
    for row in alerts_result:
        # row: (severity, category, count)
        severity = row[0] # WARNING, CRITICAL
        category = row[1] # HOT_TEMP, COLD_TEMP, etc.
        count = row[2]
        
        total_alerts += count
        if severity == 'CRITICAL':
            critical_alerts += count
            
        # Simulación de causas basada en categoría
        if category == 'HOT_TEMP':
            # 70% puerta abierta, 30% falla motor
            alert_causes["Puerta Abierta"] += int(count * 0.7)
            alert_causes["Falla Compresor"] += int(count * 0.3) + (count % 2) # Resto
        elif category == 'COLD_TEMP':
            alert_causes["Falla Compresor"] += count
        elif category == 'RAPID_CHANGE':
            alert_causes["Carga Producto"] += count

    # Limpiar ceros
    alert_causes = {k: v for k, v in alert_causes.items() if v > 0}
    if not alert_causes and total_alerts > 0:
        alert_causes["Indeterminado"] = total_alerts

    # 5. Uptime
    expected_readings = float(timeframe_minutes * 12)
    query_readings_count = text("""
        SELECT COUNT(*) FROM temperature_readings 
        WHERE sensor_id = :sensor_id AND timestamp >= NOW() - INTERVAL :minutes MINUTE
    """)
    actual_readings = db.execute(query_readings_count, {"sensor_id": sensor_id, "minutes": timeframe_minutes}).scalar() or 0
    uptime = 0.0
    if expected_readings > 0:
        uptime = round(min((actual_readings / expected_readings) * 100.0, 100.0), 2)

    # 6. Texto de Análisis (Insights Generados)
    analysis_text = "Operación estable."
    if critical_alerts > 5:
        analysis_text = f"ALTO RIESGO: Se detectaron {critical_alerts} eventos críticos. Revisar compresor inmediatamente."
    elif hours_at_risk > 0.5:
        analysis_text = f"ADVERTENCIA: La cadena de frío se rompió por {round(hours_at_risk*60)} minutos acumulados."
    elif total_alerts > 0:
        analysis_text = "Se observaron desviaciones menores. Verificar cierre de puertas."

    return {
        "chamber_id": sensor_id,
        "total_alerts": total_alerts,
        "critical_alerts": critical_alerts,
        "hours_at_risk": round(hours_at_risk, 4),
        "estimated_cost": estimated_cost,
        "uptime_percentage": uptime,
        "alert_causes": alert_causes,
        "analysis_risk_text": analysis_text,
        # Campos extra opcionales para debug
        "period_minutes": timeframe_minutes
    }