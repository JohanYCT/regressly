# Especificación Técnica de la Fase de Pruebas - Regressly

Esta documentación detalla minuciosamente los procedimientos, datos de entrada, criterios de aceptación y lógica matemática validada durante la fase de pruebas de la aplicación.

## 1. Módulo de Integridad de Datos (`RegistroModel`)

Se validó la capa de persistencia asegurando que el trasvase de datos entre el motor SQLite y los objetos Dart sea atómico y seguro.

### 1.1. Prueba de Construcción por Mapeo (`fromMap`)
*   **Procedimiento:** Se inyectó un objeto `Map<String, dynamic>` simulando una fila de la base de datos con los siguientes valores:
    *   `litros_manana`: 10.5
    *   `litros_tarde`: 9.5
    *   `litros_total`: 20.0
*   **Aserciones Específicas:** Se verificó mediante `expect()` que el constructor factory [RegistroModel.fromMap](method://regressly.models.RegistroModel#fromMap) asigne correctamente los valores a sus respectivos atributos internos.
*   **Criterio de Éxito:** El objeto resultante debe mantener el tipo `double` y el valor exacto para evitar errores de redondeo en la analítica posterior.

### 1.2. Prueba de Serialización (`toMap`)
*   **Procedimiento:** Se instanció un objeto con valores controlados y se invocó el método [toMap](method://regressly.models.RegistroModel#toMap).
*   **Validación de Estructura:** Se comprobó que el mapa contenga las claves exactas requeridas por la base de datos (`litros_manana`, `litros_tarde`, etc.), validando incluso que si el `id` es nulo (registro nuevo), este no se incluya en el mapa para permitir el autoincremento de SQLite.

### 1.3. Prueba de Robustez ante Nulos
*   **Escenario:** Mapa de entrada con solo el campo `fecha`.
*   **Resultado Validado:** Se verificó que el factory utilice el operador de coalescencia nula (`??`) para asignar `0.0` a los litros y cadenas vacías a las observaciones. Esto previene el error crítico de `Null check operator used on a null value` en la interfaz de usuario.

---

## 2. Módulo de Inteligencia Analítica (`AnalyticsService`)

Se realizaron pruebas de "caja blanca" para validar el motor estadístico de regresión lineal simple.

### 2.1. Validación de la Ecuación de Regresión (`y = mx + b`)
Se diseñaron dos escenarios matemáticos puros para estresar el método [calcularRegresion](method://regressly.services.AnalyticsService#calcularRegresion):

#### Escenario A: Crecimiento Lineal Perfecto
*   **Datos de entrada:** 3 registros con `litrosTotal` de `100`, `110` y `120`.
*   **Lógica de prueba:** Dado que la diferencia es constante (10), la pendiente (**m**) debe ser 10 y el intercepto (**b**) 100.
*   **Validación R²:** Se verificó que el coeficiente de determinación sea `1.0` (precisión absoluta del 100% en el ajuste).

#### Escenario B: Tendencia de Pérdida (Negativa)
*   **Datos de entrada:** Producción descendente de `50`, `45` y `40` litros.
*   **Meta:** Confirmar que el servicio detecta la pendiente negativa (`-5.0`). Esto es vital para las alertas de salud del ganado en la aplicación.

### 2.2. Validación de Predicciones Futuras
El método [calcularPredicciones](method://regressly.services.AnalyticsService#calcularPredicciones) fue sometido a pruebas de proyección:
*   **Parámetros:** Pendiente `2.0`, Intercepto `10.0`, y solicitud de `2` días futuros.
*   **Resultado técnico:** Se validó que la lista resultante contenga 4 elementos (2 históricos + 2 calculados), siguiendo la secuencia `[10, 12, 14, 16]`.
*   **Seguridad Matemática:** Se probó una tendencia negativa extrema. La prueba confirmó el uso de `max(0.0, prediccion)`, asegurando que la aplicación nunca muestre una producción de leche negativa, lo cual invalidaría la lógica de negocio.

---

## 3. Pruebas de Integración y End-to-End (E2E)

El archivo [app_test.dart](file:///D:/Universidad/PGC/regressly/integration_test/app_test.dart) valida el flujo completo del usuario en un entorno real de dispositivo.

### 3.1. Gestión de Configuración de la Finca
*   **Procedimiento:** Se automatizó el llenado del formulario de configuración con datos reales (Productor: Carlos Gomez, Finca: Rancho Alegre, 15 vacas, Precio: 2100 COP).
*   **Validación:** Se verificó la persistencia mediante la aparición del snackbar de confirmación y el retorno seguro a la pantalla principal.

### 3.2. Ciclo de Vida del Registro de Producción
*   **Flujo Probado:** Registro inicial -> Actualización -> Consulta.
*   **Acciones Técnicas:**
    1.  Inserción de un registro base de 80 litros (40 mañana / 40 tarde).
    2.  Modificación del mismo registro a 90 litros (45 mañana / 45 tarde).
*   **Criterio de Aceptación:** El sistema debe detectar que ya existe un registro para la fecha actual y ejecutar una operación de **Update** en lugar de **Insert**, manteniendo la integridad de la base de datos y respetando la restricción `UNIQUE` en la columna de fecha.

### 3.3. Integración con el Módulo de Análisis
*   **Validación Final:** Navegación automática a la pantalla de estadísticas después de los cambios.
*   **Aserción de UI:** Se verificó que el widget de "Promedio" refleje exactamente los `90.0 L` actualizados, confirmando que la capa de base de datos, el servicio de analítica y la UI están sincronizados correctamente.

---

## 4. Validación de la Capa de Persistencia (SQLite)

Aunque se ejecuta dentro de los tests de integración, la lógica de [DatabaseHelper](class://regressly.database.DatabaseHelper) fue auditada bajo los siguientes criterios:

- **Patrón Singleton:** Se confirmó que solo existe una instancia de conexión activa, evitando bloqueos de archivos en el sistema de archivos del dispositivo.
- **Limpieza Hermética:** Uso del método `clearDatabase()` antes de cada ejecución de test para asegurar que los resultados no estén contaminados por ejecuciones previas.
- **Restricciones de Integridad:** Validación de que la base de datos rechace registros duplicados para una misma fecha mediante el identificador `fecha TEXT UNIQUE`.

---

## 5. Glosario de Conceptos Validados

- **Regresión Lineal Simple:** Método estadístico para modelar la relación entre el tiempo (eje X) y la producción de leche (eje Y).
- **R² (Coeficiente de Determinación):** Métrica que indica qué tan bien los datos se ajustan a la línea de tendencia (1.0 es ajuste perfecto).
- **Prueba Hermética:** Prueba que se ejecuta en un entorno aislado y limpio, garantizando repetibilidad.
- **Mocking/Simulación:** Técnica para proveer datos controlados a los algoritmos sin depender de la entrada manual del usuario.

---

## 6. Entorno de Ejecución y Métricas

| Parámetro | Valor / Herramienta |
| :--- | :--- |
| **Framework de Pruebas** | `flutter_test` (SDK de Flutter) |
| **Precisión de Punto Flotante** | `closeTo(delta: 0.001)` |
| **Manejo de Tiempo** | Simulación de fechas en formato ISO-8601 |
| **Cobertura de Lógica** | 100% de los métodos críticos del `AnalyticsService` |

> [!IMPORTANT]
> Las pruebas de regresión utilizan el índice de la lista como la variable independiente **X** (tiempo relativo) y `litrosTotal` como la variable dependiente **Y**, reflejando fielmente el comportamiento del motor de cálculo en el dispositivo del usuario.
