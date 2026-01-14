# Manual de Pruebas y Validación (Test Suite)

## 1. Introducción
Rukito cuenta con una suite de pruebas automatizada robusta y organizada. Las pruebas cubren desde la disponibilidad básica de los servicios hasta la lógica de negocio compleja, integridad de datos y casos borde.

Todos los scripts se encuentran en la carpeta: `rukito-backend/tests/`.

**Consideraciones Previas:**
*   Asegúrese de que ambos servicios (Go en puerto 8080, Python en puerto 8000) estén corriendo.
*   Algunas pruebas modifican temporalmente la base de datos (inyectan datos de prueba), pero están diseñadas para limpiar después de sí mismas.

---

## 2. Scripts de Prueba Activos

### 2.1. `test_full_integration_suite.sh` (Contrato API)
*   **Objetivo:** Verificar que el Backend cumple estrictamente con el contrato JSON esperado por el Frontend.
*   **Alcance:**
    *   Prueba TODOS los endpoints (`/chambers`, `/reports`, `/alerts`, `/config`, `/users`).
    *   Valida la existencia de claves críticas (ej: `thresholds`, `alert_causes`).
*   **Uso:** Ejecutar antes de cualquier entrega al equipo de Frontend.
*   **Señal de Éxito:** "🎉 TODOS LOS TESTS PASARON EXITOSAMENTE".

### 2.2. `test_logic_verification.py` (Cerebro Analítico)
*   **Objetivo:** Validar que la matemática del negocio funciona.
*   **Lógica:**
    1.  Limpia los datos de una cámara de prueba.
    2.  Inyecta un escenario controlado (ej: 3 horas bien, 2 horas mal) directamente en MySQL.
    3.  Consulta la API de Reportes.
    4.  Verifica que `hours_at_risk` sea exactamente lo esperado (Matemática) y que `alert_causes` infiera la causa correcta (Lógica).
*   **Importancia:** Garantiza que no estamos mostrando "números aleatorios".

### 2.3. `test_config_persistence.py` (Integridad de Datos)
*   **Objetivo:** Asegurar que los JSON complejos de configuración no se corrompen al guardarse en MySQL.
*   **Flujo:**
    1.  Envía una configuración compleja (canales anidados, roles específicos).
    2.  Lee inmediatamente la configuración.
    3.  Compara bit a bit la entrada y la salida.
*   **Importancia:** Crucial para asegurar que las reglas de notificación se respeten.

### 2.4. `test_analytics_scenarios.py` (Casos Borde y Performance)
*   **Objetivo:** Probar la robustez del sistema ante situaciones extremas.
*   **Escenarios:**
    1.  **Downsampling:** Pide reporte de 3 días. Verifica que la respuesta sea rápida (uso de promedios horarios).
    2.  **Escasez:** Pide reporte de 90 días con poca data. Verifica que el sistema no colapse y reporte baja confiabilidad.

### 2.5. `test_validation_rules.py` (Escudo de Seguridad)
*   **Objetivo:** Verificar que el Backend rechaza configuraciones físicamente imposibles.
*   **Prueba:** Intenta guardar `Critical Cold > Critical Hot`.
*   **Éxito:** Recibir un error `400 Bad Request`.

### 2.6. `test_integration_basics.sh` (Ping)
*   **Objetivo:** Diagnóstico rápido de "Vida". Verifica que los puertos 8080 y 8000 responden.

### 2.7. `test_analytics_integration.sh` (Python Aislado)
*   **Objetivo:** Probar el subsistema de Python (Scraper + API) sin pasar por Go. Útil para depurar errores internos de Analítica.

---

## 3. Matriz de Solución de Problemas

| Síntoma | Test Fallido | Causa Probable | Solución |
| :--- | :--- | :--- | :--- |
| **JSON Error / Estructura** | `test_full_integration_suite` | Cambio en `models.go` no reflejado en JSON tags. | Revisar nombres de campos JSON. |
| **Cálculo de Riesgo Erróneo** | `test_logic_verification` | Desfase de Zona Horaria (UTC vs Local) o bug en query SQL. | Revisar `analysis.py` y configuración de servidor MySQL. |
| **Error 500 en Reportes** | `test_analytics_scenarios` | Fallo en formato de fecha o librería Pandas. | Revisar logs de Python (`uvicorn`). |
| **Configuración "Zombie"** | `test_config_persistence` | Error en serialización JSON en `sensor_service.go` o `config.go`. | Verificar `json.Marshal/Unmarshal`. |

---

## 4. Ejecución Recomendada
Para una validación completa del sistema, ejecute:

```bash
cd rukito-backend/tests
./test_full_integration_suite.sh
# Si pasa, proceda con las pruebas lógicas específicas según necesidad.
```