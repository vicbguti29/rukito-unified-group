from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional
import datetime

app = FastAPI(title="Rukito API")

# Configuración de CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Modelos de datos
class ColdChamber(BaseModel):
    id: str
    name: str
    content: str
    current_temperature: float
    target_temperature: float
    critical_threshold: float
    warning_threshold: float
    rate_of_change: float
    status: int
    last_update: str
    recent_temperatures: List[float]
    is_active: bool
    location: str

class AlertConfig(BaseModel):
    id: str
    sensor_id: str
    max_temperature: float
    min_temperature: float
    rate_of_change_threshold: float
    priority: int
    is_enabled: bool
    notification_channels: List[str]
    recipients: List[str]
    created_at: str
    updated_at: str

# Datos simulados (Mock Database)
chambers_db = [
    {
        "id": "CF-1",
        "name": "Cámara Frigorífica 1 (CF-1)",
        "content": "Carnes Prime",
        "current_temperature": -16.5,
        "target_temperature": -20.0,
        "critical_threshold": -18.0,
        "warning_threshold": -17.0,
        "rate_of_change": 0.5,
        "status": 1,
        "last_update": datetime.datetime.now().isoformat(),
        "recent_temperatures": [-20, -19.5, -18.5, -17.5, -16.5, -16],
        "is_active": True,
        "location": "Sala Principal"
    },
    {
        "id": "CF-2",
        "name": "Cámara Frigorífica 2 (CF-2)",
        "content": "Lácteos y Moros",
        "current_temperature": 5.0,
        "target_temperature": 4.0,
        "critical_threshold": 8.0,
        "warning_threshold": 6.0,
        "rate_of_change": 1.0,
        "status": 1,
        "last_update": datetime.datetime.now().isoformat(),
        "recent_temperatures": [3.5, 4, 4.5, 5, 5.5, 5],
        "is_active": True,
        "location": "Sala Principal"
    }
]

configs_db = {
    "CF-1": {
        "id": "CONFIG-CF-1",
        "sensor_id": "CF-1",
        "max_temperature": 5.0,
        "min_temperature": -25.0,
        "rate_of_change_threshold": 0.5,
        "priority": 2,
        "is_enabled": True,
        "notification_channels": ["sms", "push"],
        "recipients": ["+593999123456"],
        "created_at": "2024-11-11T00:00:00Z",
        "updated_at": "2024-12-11T00:00:00Z"
    }
}

# ==================== ENDPOINTS (LECTURA) ====================

@app.get("/api/chambers", response_model=List[ColdChamber])
async def get_chambers():
    """Obtiene todas las cámaras frigoríficas (Implementado por Victor Borbor)"""
    return chambers_db

@app.get("/api/chambers/{chamber_id}", response_model=ColdChamber)
async def get_chamber(chamber_id: str):
    chamber = next((c for c in chambers_db if c["id"] == chamber_id), None)
    if not chamber:
        raise HTTPException(status_code=404, detail="Cámara no encontrada")
    return chamber

@app.get("/api/config/alerts/{chamber_id}", response_model=AlertConfig)
async def get_alert_config(chamber_id: str):
    """Obtiene la configuración de alertas (Implementado por Victor Borbor)"""
    if chamber_id not in configs_db:
        # Crear una config por defecto si no existe
        return {
            "id": f"CONFIG-{chamber_id}",
            "sensor_id": chamber_id,
            "max_temperature": 5.0,
            "min_temperature": -25.0,
            "rate_of_change_threshold": 0.5,
            "priority": 1,
            "is_enabled": True,
            "notification_channels": ["push"],
            "recipients": [],
            "created_at": datetime.datetime.now().isoformat(),
            "updated_at": datetime.datetime.now().isoformat()
        }
    return configs_db[chamber_id]

# ==================== ENDPOINTS (ESCRITURA) ====================

@app.put("/api/config/alerts/{chamber_id}", response_model=AlertConfig)
async def update_alert_config(chamber_id: str, config: AlertConfig):
    """Actualiza la configuración de alertas (Implementado por Victor Borbor)"""
    configs_db[chamber_id] = config.dict()
    configs_db[chamber_id]["updated_at"] = datetime.datetime.now().isoformat()
    return configs_db[chamber_id]

@app.get("/api/health")
async def health_check():
    return {"status": "ok", "timestamp": datetime.datetime.now().isoformat()}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8080)
