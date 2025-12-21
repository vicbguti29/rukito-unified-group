# Prototipo de Baja Fidelidad - Rukito Monitoreo de Cadena de Frío

## 📱 Herramienta de Diseño
**Figma** (Herramienta recomendada para el documento final)

---

## 🎯 Pantallas Principales

### 1. **Dashboard Principal** (Pantalla de Inicio)
**Propósito:** Visualización en tiempo real del estado de todas las cámaras frigoríficas.

#### Layout:
```
┌─────────────────────────────────────────────────────┐
│ RUKITO - Monitoreo de Cadena de Frío    DJ ●        │
├──────────────┬──────────────────────────────────────┤
│  📊          │  CF-1 (Crítica)    | CF-2 (Advertencia) │
│  ⚠️           │  -16°C             | 5°C                │
│  📈           │  ▲ +4°C ↑          | ▲ +1°C ↑           │
│  📋           │  Carnes Prime      | Lácteos            │
│  (Sidebar)   │  [Gráfico]         | [Gráfico]          │
│              │                    |                    │
│              │  REF-3 (Normal)    | Respaldo (Standby) │
│              │  2°C               | -18°C              │
│              │  ✓ Vegetales       | ✓ Batería 95%      │
│              │  [Gráfico]         | [Info Respaldo]    │
│              │                                         │
│              │  Estadísticas:                          │
│              │  3 Cámaras Operativas | Alertas: 2     │
│              │  Promedio: -3°C       | Estado: ⚠️      │
└──────────────┴──────────────────────────────────────┘
```

#### Elementos principales:
- **Tarjeta CF-1 (Rojo):** Temperatura prominente (-16°C), indicador de tendencia crítica
- **Tarjeta CF-2 (Naranja):** Advertencia por oscilación, indicador de energía
- **Tarjeta REF-3 (Verde):** Estado normal, temperatura estable
- **Tarjeta Respaldo (Verde):** Sistema de backup activo, % batería
- **Gráficos miniatura:** 6 barras mostrando histórico de 6 últimos datos
- **Badges de estado:** Online, Advertencia, Offline, Oscilación

#### Paleta de colores:
- Crítico: `#e74c3c` (Rojo)
- Advertencia: `#f39c12` (Naranja)
- Normal: `#2ecc71` (Verde)
- Info: `#3498db` (Azul)
- Fondo: Blanco `#ffffff`
- Texto: Gris oscuro `#1a1a1a`

---

### 2. **Centro de Alertas** (Alerting System)
**Propósito:** Visualizar todas las notificaciones prioritarias con detalles específicos.

#### Layout:
```
┌─────────────────────────────────────────────────────┐
│ RUKITO - Monitoreo de Cadena de Frío    DJ ●        │
├──────────────┬──────────────────────────────────────┤
│  📊          │  CENTRO DE ALERTAS                    │
│  ⚠️  ◄────────│                                       │
│  📈           │  [P1] 🚨 CF-1 en Riesgo              │
│  📋           │       Hace 3 min • Tasa: +0.5°C/min  │
│              │       Puerta detectada abierta...     │
│              │                            [CRÍTICA]   │
│              │                                       │
│              │  [P1] 📢 SMS Enviado a Don Jorge      │
│              │       Hace 2 min                      │
│              │       Mensaje de alerta entregado...  │
│              │                            [CRÍTICA]   │
│              │                                       │
│              │  [P2] ⚠️  CF-2 Oscilando              │
│              │       Hace 5 min                      │
│              │       Micro-corte de energía...       │
│              │                         [ADVERTENCIA]   │
│              │                                       │
│              │  [P3] ℹ️ REF-3 Operando Normalmente   │
│              │       Hace 1 min                      │
│              │       Temperatura estable en 2°C...   │
│              │                             [INFO]     │
│              │                                       │
│              │  [P2] ⚠️  Mantenimiento Preventivo    │
│              │       Hace 1 hora                     │
│              │       Filtros CF-1 mañana 06:00...    │
│              │                         [ADVERTENCIA]   │
└──────────────┴──────────────────────────────────────┘
```

#### Elementos principales:
- **Lista de alertas verticales** scrolleable
- **Color de borde izquierdo:** Indica prioridad (P1: Rojo, P2: Naranja, P3: Azul)
- **Badge de prioridad:** Esquina derecha (P1, P2, P3)
- **Información:** Título, timestamp, descripción, contexto técnico
- **Pulsación en tiempo real:** Las alertas críticas parpadean

#### Prioridades:
| Prioridad | Color | Trigger | Acción |
|-----------|-------|---------|--------|
| P1 | Rojo (#e74c3c) | CF-1 > -18°C o tasa > 0.4°C/min | SMS a Don Jorge + Gerente |
| P2 | Naranja (#f39c12) | CF-2 oscilaciones o Mantenimiento | Notificación app |
| P3 | Azul (#3498db) | Información/logs normales | Solo historial |

---

### 3. **Histórico de Temperaturas** (Analytics)
**Propósito:** Visualización de tendencias y análisis histórico de temperaturas.

#### Layout:
```
┌─────────────────────────────────────────────────────┐
│ RUKITO - Monitoreo de Cadena de Frío    DJ ●        │
├──────────────┬──────────────────────────────────────┤
│  📊          │  HISTÓRICO DE TEMPERATURAS            │
│  ⚠️           │                                       │
│  📈  ◄────────│  Período: [04/12] a [11/12]          │
│  📋           │  Cámara: [CF-1 ▼] [Descargar]        │
│              │                                       │
│              │  CF-1: Comportamiento últimos 7 días  │
│              │  ┌────────────────────────────────┐  │
│              │  │         ╱╲          ╱╲  ╱╲     │  │
│              │  │    ╱╲  ╱  ╲  ╱╲  ╱╲╱  ╲╱  ╲    │  │
│              │  │   ╱  ╲╱    ╲╱  ╲╱         ╲   │  │
│              │  │                           ╲  │  │
│              │  └────────────────────────────────┘  │
│              │   L   M   Mi  J   V   S   D   H      │
│              │  (Lun)(Mar)(Mié)(Jue)(Vie)(Sáb)(Dom)(Hoy)
│              │                                       │
│              │  Análisis de Datos:                  │
│              │  ├─ Máxima: -14°C (Hoy 22:15)        │
│              │  ├─ Mínima: -21°C (Jue 04:30)        │
│              │  └─ Promedio: -18°C (Últimos 7 días) │
└──────────────┴──────────────────────────────────────┘
```

#### Elementos principales:
- **Selectores de rango:** Fechas (from/to) y cámara
- **Gráfico de líneas/barras:** Histórico de 7-30 días
- **Estadísticas resumidas:** Máxima, Mínima, Promedio
- **Exportación de datos:** Botón CSV/PDF
- **Eje Y:** Temperatura (-25 a 10°C)
- **Eje X:** Tiempo (diario o por horas)

#### Tipos de visualización:
- Línea continua con puntos
- Área rellena (gradiente)
- Barras (comparativa diaria)

---

### 4. **Reportes y Análisis** (Reports/Data Analysis)
**Propósito:** Mostrar métricas agregadas y responder las 3 preguntas de análisis de datos.

#### Layout:
```
┌─────────────────────────────────────────────────────┐
│ RUKITO - Monitoreo de Cadena de Frío    DJ ●        │
├──────────────┬──────────────────────────────────────┤
│  📊          │  REPORTES Y ANÁLISIS                  │
│  ⚠️           │                                       │
│  📈           │  KPIs - Últimos 30 Días:             │
│  📋  ◄────────│  ┌─────────┬─────────┬─────────┐   │
│              │  │  2.5 h  │ $15,000 │  99.8%  │   │
│              │  │ En Riesgo│ Costo   │Uptime   │   │
│              │  └─────────┴─────────┴─────────┘   │
│              │  
│              │  Alertas: 24 (3 Críticas, 8 Adv, 13 Info)
│              │                                       │
│              │  ════════ ANÁLISIS DETALLADO ════════ │
│              │                                       │
│              │  P1: Tasa de Cambio (dT/dt) CF-1     │
│              │  ├─ Promedio: +0.45°C/min            │
│              │  ├─ Máximo: +0.8°C/min (7 dic)       │
│              │  └─ Acción: Reducir umbral a +0.4    │
│              │                                       │
│              │  P2: Correlación Alta Demanda-CF-2   │
│              │  ├─ Correlación: 0.78                │
│              │  ├─ Picos: Almuerzo (+45%) y Cena    │
│              │  └─ Acción: Revisar compresor        │
│              │                                       │
│              │  P3: Horas en Riesgo CF-1            │
│              │  ├─ Total: 4.2 horas/mes             │
│              │  ├─ Costo: ~$1,200 USD               │
│              │  └─ Acción: Monitoreo proactivo      │
└──────────────┴──────────────────────────────────────┘
```

#### Elementos principales:
- **KPI Cards:** 4 tarjetas con métricas clave
- **Tabla de alertas:** Resumen por prioridad
- **Análisis por pregunta:** Respuesta + contexto + recomendación
- **Gráficos complementarios:** Pie chart (alertas), bar chart (horas)
- **Timestamps:** Últimos 30 días

---

## 🎨 Componentes Reutilizables

### Card Genérica
```
┌─────────────────────┐
│ Título    [Badge]   │
├─────────────────────┤
│ Valor grande        │
│ Detalles secundarios│
│ [Gráfico/Info]      │
│ Timestamp           │
└─────────────────────┘
```

### Alert Item
```
┌──────────────────────────────┐
│ ► Título                 [P1]│
│   Timestamp                  │
│   Descripción detallada      │
└──────────────────────────────┘
```

### Stat Badge
```
┌─────────────┐
│   Valor     │
│  Etiqueta   │
│  Contexto   │
└─────────────┘
```

---

## 🎯 Flujo de Navegación

```
Dashboard (Inicio)
    ├─ [Click CF-1] → Detalle CF-1 → Histórico
    ├─ [Click Alerta 2] → Centro de Alertas
    │   ├─ [Click Alerta] → Detalles
    │   └─ [Click SMS] → Log SMS
    ├─ [Click Histórico] → Gráficos 7-30 días
    │   ├─ Seleccionar cámara
    │   ├─ Seleccionar período
    │   └─ Exportar datos
    └─ [Click Reportes] → KPIs y Análisis
        ├─ Pregunta 1: dT/dt
        ├─ Pregunta 2: Correlación
        └─ Pregunta 3: Horas en riesgo
```

---

## 📊 Mockups por Pantalla

### Dashboard - Tarjeta CF-1 (Detalle)

```
┌────────────────────────────────────┐
│ Cámara Frigorífica 1 (CF-1)    ⚠️  │
├────────────────────────────────────┤
│                                    │
│         -16°C                      │  ← CRÍTICO (Rojo)
│                                    │
│  Objetivo: -20°C   Diferencia: +4°C│
│  Tasa: +0.5°C/min  Contenido: Carnes│
│                                    │
│  ▁▁▂▃▄▅▆▆▇ (Gráfico de progresión)│
│                                    │
│  Última actualización: Hace 2 min  │
└────────────────────────────────────┘
```

### Alert Priority Levels

| Prioridad | Icono | Color | Sonido | Destinatario |
|-----------|-------|-------|--------|-------------|
| P1 | 🚨 | Rojo | Sí | SMS + Push |
| P2 | ⚠️ | Naranja | Opcional | Push + App |
| P3 | ℹ️ | Azul | No | Solo historial |

---

## 🎬 Animaciones y Transiciones

1. **Cambio de vista:** Fade-in 300ms
2. **Actualización de temperatura:** Suave (color flash en cambios críticos)
3. **Alerta crítica:** Pulsación 2s (pulse animation)
4. **Gráfico:** Transición suave de barras (250ms)

---

## 📏 Dimensiones y Responsive

- **Desktop:** 1920x1080 (primario)
- **Tablet:** 768-1024px (secundario)
- **Mobile:** 375-480px (soporte básico)

### Puntos de quiebre:
- `max-width: 1024px` → Grid 1 columna
- `max-width: 768px` → Sidebar colapsable
- `max-width: 480px` → Vista móvil comprimida

---

## 💾 Datos de Ejemplo

### CF-1
```json
{
  "id": "CF-1",
  "nombre": "Cámara Frigorífica 1",
  "contenido": "Carnes Prime (Vacío, Baby Back Ribs)",
  "temperatura_actual": -16,
  "temperatura_objetivo": -20,
  "temperatura_minima": -21,
  "temperatura_maxima": -14,
  "tasa_cambio": 0.5,
  "umbral_critico": -18,
  "umbral_advertencia": -17,
  "estado": "CRÍTICO",
  "ultima_actualizacion": "2024-12-11T22:15:00Z"
}
```

### Alerta
```json
{
  "id": "ALT-001",
  "titulo": "CF-1 en Riesgo de Pérdida Total",
  "prioridad": 1,
  "camara": "CF-1",
  "temperatura": -16,
  "timestamp": "2024-12-11T22:18:00Z",
  "mensaje": "Puerta detectada abierta. Temperatura subiendo desde -20°C a -16°C.",
  "costo_estimado": 15000,
  "destinatarios": ["Don Jorge", "Gerente"],
  "canal": "SMS"
}
```

---

## 📋 Checklist de Implementación

- [ ] Header con logo y usuario
- [ ] Sidebar con navegación (4 vistas)
- [ ] Dashboard con 4 tarjetas principales
- [ ] Centro de Alertas con lista prioritaria
- [ ] Histórico con gráficos
- [ ] Reportes con KPIs
- [ ] Responsive design
- [ ] Simulación de datos en tiempo real
- [ ] Notificaciones visuales

---

## 🔗 Referencia para Figma

**Colores paleta:**
- Primary: #3498db
- Success: #2ecc71
- Warning: #f39c12
- Danger: #e74c3c
- Dark: #1a1a1a
- Light: #f5f5f5

**Tipografía:**
- Títulos: 24px Bold
- Subtítulos: 16px Bold
- Body: 14px Regular
- Small: 12px Regular

**Espaciado:**
- Padding standard: 20px
- Gap entre elementos: 15px
- Border radius: 8-12px

