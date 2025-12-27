import pandas as pd
from sqlalchemy.orm import Session
from sqlalchemy import text
import datetime

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
    
    # Calcular diferencia de temperatura y tiempo
    temp_diff = df['temp'].iloc[-1] - df['temp'].iloc[0]
    time_diff = (df['time'].iloc[-1] - df['time'].iloc[0]).total_seconds() / 60.0 # en minutos
    
    if time_diff == 0:
        return 0.0
        
    return round(temp_diff / time_diff, 4)

def get_chamber_kpis(db: Session, sensor_id: str, days: int = 30):
    """
    Genera los KPIs requeridos por el frontend (Fase 3.4).
    """
    # Consulta para horas en riesgo (donde temp > warning_threshold)
    # Nota: Simplificado para el reporte. En prod se calcularía por intervalos reales.
    query_risk = text("""
        SELECT COUNT(*) * 5 / 60 as hours_at_risk
        FROM temperature_readings tr
        JOIN chambers c ON tr.sensor_id = c.id
        WHERE tr.sensor_id = :sensor_id 
        AND tr.temperature > c.warning_threshold
        AND tr.timestamp >= NOW() - INTERVAL :days DAY
    """)
    
    risk_data = db.execute(query_risk, {"sensor_id": sensor_id, "days": days}).fetchone()
    hours_at_risk = float(risk_data[0]) if risk_data else 0.0
    
    # Simulación de costo (basado en el scraping futuro o valores fijos)
    estimated_cost = round(hours_at_risk * 285.5, 2) # $285.5 es un factor de riesgo por hora
    
    return {
        "chamber_id": sensor_id,
        "hours_at_risk": hours_at_risk,
        "estimated_cost": estimated_cost,
        "uptime_percentage": 99.8, # Mock por ahora
        "avg_rate_of_change": calculate_rate_of_change(db, sensor_id),
        "total_alerts": 12, # Mock
        "monthly_cost": round(estimated_cost * 0.1, 2)
    }
