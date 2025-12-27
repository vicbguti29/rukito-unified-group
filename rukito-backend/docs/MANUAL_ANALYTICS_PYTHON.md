# Manual Técnico: Servicio de Analítica (Python)

## 1. Visión General
El **Servicio de Analítica** es un microservicio especializado desarrollado en **Python (FastAPI)**. Su función es descargar al backend principal de los cálculos matemáticos complejos y proporcionar inteligencia de negocio basada en datos históricos y de mercado.

**Responsabilidades:**
1.  **Cálculo de Riesgo Financiero:** Estimar cuánto dinero se perdería si la cadena de frío falla.
2.  **Integración de Mercado:** Obtener precios reales de competidores para valorar el inventario.
3.  **Análisis de Tendencias:** Calcular tasas de cambio promedio en ventanas de tiempo amplias.
4.  **Reportes Ejecutivos:** Generar el JSON consolidado que consume la vista de "Reportes" en la App.

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
El script `scraper.py` simula la navegación en sitios web de proveedores de carne para extraer precios actuales.
*   **Output:** Genera un archivo `datos/precios_mercado.csv`.
*   **Consumo:** `analysis.py` lee este CSV. Si no existe, usa un valor fallback ($25.50/kg).
*   **Cálculo:** `Promedio_Precio_Carne = Mean(Precios_CSV)`.

### 3.2. Regla de las 4 Horas (FDA/HACCP)
Para calcular el daño al producto, el sistema implementa estándares internacionales de seguridad alimentaria.

*   **Constante:** `CRITICAL_EXPOSURE_LIMIT_HOURS = 4.0`
*   **Lógica:**
    *   Si el tiempo en "Zona de Peligro" (temperatura > umbral) es **0 horas**, el riesgo es 0%.
    *   Si es **2 horas**, el riesgo es 50% (carne degradada, venta rápida necesaria).
    *   Si es **>= 4 horas**, el riesgo es **100% (Pérdida Total)**.

### 3.3. Cálculo Preciso de Tiempo en Riesgo (`hours_at_risk`)
El sistema **no estima** el tiempo contando filas (lo cual sería erróneo si hay fallas de red). Utiliza un algoritmo de **Deltas de Tiempo** con Pandas:

1.  **Ventana Relativa:** Se seleccionan datos basándose en la *última lectura disponible* hacia atrás (ej. 30 minutos), evitando errores por zonas horarias (UTC vs Local).
2.  **Cálculo de Intervalos:**
    *   `Delta = Tiempo_Lectura_Siguiente - Tiempo_Lectura_Actual`.
3.  **Filtrado:**
    *   Si `Temperatura_Actual > Umbral_Advertencia`: Sumamos `Delta` al contador de riesgo.
    *   Se ignoran "huecos" mayores a 12 minutos (asumiendo sistema apagado).

### 3.4. Fórmula de Costo Estimado
$$ Costo = Factor\_Riesgo \times (Precio\_Promedio \times Inventario\_Estimado) $$

Donde:
*   `Factor_Riesgo` = `min(Horas_Riesgo / 4.0, 1.0)`
*   `Inventario_Estimado` = 200kg (Valor base configurable).

---

## 4. API Endpoints
El servicio escucha en el puerto **8000**.

*   `GET /analyze/report/{chamber_id}`
    *   **Parámetros:** `minutes` (opcional, default=30).
    *   **Retorno:** JSON con KPIs calculados (`estimated_cost`, `uptime`, `avg_rate_of_change`).
*   `GET /analyze/statistics`
    *   Estadísticas globales del sistema.
*   `GET /health`
    *   Verificación de estado.

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
