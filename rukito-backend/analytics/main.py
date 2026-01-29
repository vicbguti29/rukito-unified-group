from fastapi import FastAPI, Depends, HTTPException
from sqlalchemy.orm import Session
from database import get_db
import analysis
import datetime

app = FastAPI(title="Rukito Analytics Service")

@app.api_route("/", methods=["GET", "HEAD"])
@app.api_route("/health", methods=["GET", "HEAD"])
def health_check():
    return {"status": "analytics_ok", "timestamp": datetime.datetime.now().isoformat()}

@app.get("/analyze/report/{chamber_id}")
def get_report(chamber_id: str, minutes: int = 30, start: str = None, end: str = None, db: Session = Depends(get_db)):
    """
    Endpoint principal de análisis consumido por el Backend Go.
    Ahora soporta fechas absolutas (start/end en ISO8601) o ventana móvil (minutes).
    """
    try:
        data = analysis.get_chamber_kpis(db, chamber_id, timeframe_minutes=minutes, start_date=start, end_date=end)
        return data
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/analyze/statistics")
def get_global_stats(db: Session = Depends(get_db)):
    """
    Métricas agregadas de todo el sistema.
    """
    # Aquí podríamos sumar horas en riesgo de todas las cámaras
    return {
        "system_health": "good",
        "total_risk_exposure": 15000.0,
        "active_analysis": True
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)