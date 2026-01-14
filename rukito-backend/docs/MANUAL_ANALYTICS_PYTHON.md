# Manual Técnico: Servicio de Analítica (Python)

## 1. Visión General
El **Servicio de Analítica** es un microservicio especializado desarrollado en **Python (FastAPI)**. Su función es descargar al backend principal de los cálculos matemáticos complejos y proporcionar inteligencia de negocio basada en datos históricos y de mercado.

**Responsabilidades:**
1.  **Cálculo de Riesgo Financiero:** Estimar pérdidas monetarias basándose en tiempo de exposición a temperaturas inseguras (tanto calor como frío extremo).
2.  **Integración de Mercado:** Obtener precios reales de competidores para valorar el inventario.
3.  **Diagnóstico de Causas:** Inferir causas probables de alertas (ej: "Puerta Abierta" vs "Falla Mecánica") analizando patrones de datos.
4.  **Generación de Insights:** Producir texto legible por humanos para explicar el estado del sistema.

---

## 2. Arquitectura del Servicio
El servicio reside en `rukito-backend/analytics/` y opera de forma independiente.

```
analytics/
├── main.py           # Servidor API (FastAPI) en puerto 8000.
├── analysis.py       # Motor de cálculo y lógica de negocio.
├── database.py       # Conexión a MySQL (SQLAlchemy).
├── scraper.py        # Script de extracción de precios web.
└── requirements.txt  # Dependencias (Pandas, SQLAlchemy, etc).
```

---

## 3. Lógica de Negocio y Algoritmos

### 3.1. Valoración de Inventario (Scraping)
El script `scraper.py` simula la navegación en sitios web de proveedores para extraer precios actuales.
*   **Output:** Genera un archivo `datos/precios_mercado.csv`.
*   **Consumo:** `analysis.py` lee este CSV. Si no existe, usa un valor fallback ($25.50/kg).

### 3.2. Regla de las 4 Horas (Estándar FDA/HACCP)
Para calcular el impacto real en el producto, el sistema implementa la regla de seguridad alimentaria:
*   Si el tiempo en zona de peligro acumulado es **>= 4 horas**, se considera **Pérdida Total (100% de riesgo)**.
*   El riesgo escala linealmente: `Factor_Riesgo = min(Horas_Riesgo / 4.0, 1.0)`.

### 3.3. Fórmula de Costo Estimado
$$ Costo = Factor\_Riesgo \times (Precio\_Promedio \times Inventario\_Estimado) $$
Donde el `Inventario_Estimado` base es de 200kg de producto premium.

### 3.4. Cálculo de Riesgo Granular (`hours_at_risk`)
A diferencia de la versión anterior, el sistema ahora evalúa **dos zonas de peligro**:
1.  **Calor Crítico (`CRITICAL_HOT`):** Temperatura > Umbral Máximo.
2.  **Frío Crítico (`CRITICAL_COLD`):** Temperatura < Umbral Mínimo (Congelación excesiva).

El algoritmo en `analysis.py`:
1.  Consulta `alert_configs` para obtener los umbrales exactos de la cámara.
2.  Calcula la duración de cada evento inseguro usando deltas de tiempo (`shift` en Pandas).
3.  Suma el tiempo total de exposición.

### 3.5. Optimización de Rendimiento (Downsampling)
Para reportes de largo alcance (ej: > 24 horas), el servicio optimiza automáticamente la consulta SQL:
*   **< 24 Horas:** Consulta datos minuto a minuto para máxima precisión.
*   **> 24 Horas:** Agrupa los datos por hora (`GROUP BY HOUR`) en la base de datos antes de traerlos a memoria. Esto reduce el volumen de datos en un factor de 60x, evitando timeouts.

### 3.6. Inferencia de Causas
El sistema analiza el historial de alertas (`alerts`) y sus categorías para generar un diagnóstico probabilístico:
*   `HOT_TEMP` + Alta frecuencia -> Probable **Puerta Abierta**.
*   `COLD_TEMP` -> Probable **Falla de Termostato**.
*   `RAPID_CHANGE` -> Probable **Carga de Producto Caliente**.

### 3.7. Generación de Texto (NLP Básico)
El servicio devuelve un campo `analysis_risk_text` listo para mostrar en el frontend.
*   *Ejemplo:* "ALTO RIESGO: Se detectaron 8 eventos críticos. Revisar compresor inmediatamente."
*   Esto elimina la necesidad de que el frontend interprete números complejos.

---

## 4. API Endpoints
El servicio escucha en el puerto **8000**.

### A. Reporte de Cámara
**GET `/analyze/report/{chamber_id}`**
*   **Parámetros:** `minutes` (int). Ventana de tiempo a analizar.
*   **Estructura JSON:**
    ```json
    {
        "chamber_id": "CF-1",
        "hours_at_risk": 1.5,
        "estimated_cost": 350.00,
        "alert_causes": {
            "Puerta Abierta": 5,
            "Falla Compresor": 1
        },
        "analysis_risk_text": "ADVERTENCIA: La cadena de frío se rompió...",
        "uptime_percentage": 98.5
    }
    ```

### B. Health Check
**GET `/health`**
*   Retorna `{"status": "analytics_ok"}` si la conexión a BD es exitosa.

---

## 5. Comandos de Ejecución

**Preparar Entorno:**
```bash
cd rukito-backend/analytics
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

**Ejecutar Servidor:**
```bash
uvicorn main:app --port 8000 --reload
```

**Actualizar Precios de Mercado:**
```bash
python scraper.py
```
El archivo `precios_mercado.csv` generado será usado automáticamente por el motor de análisis.

---

## 6. Roadmap / Futuras Implementaciones

### A. Estadísticas Globales (Dashboard Ejecutivo)
**Endpoint:** `GET /analyze/statistics`
*   **Estado Actual:** Implementado pero retorna datos simulados (Placeholder).
*   **Propósito:** Proveer un resumen gerencial de todas las cámaras (Total Pérdidas del Mes, Eficiencia Global).
*   **No consumido por el Frontend actual.**