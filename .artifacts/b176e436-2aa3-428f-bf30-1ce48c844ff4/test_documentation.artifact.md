# Documentación de la Fase de Pruebas - Regressly

Esta sección detalla de manera exhaustiva las pruebas unitarias y de lógica de negocio realizadas para asegurar la fiabilidad y precisión de la aplicación **Regressly**.

## 1. Resumen de la Estrategia de Pruebas

La fase de pruebas se centró en garantizar la integridad de los datos y la exactitud de los algoritmos predictivos. Se utilizó el framework oficial `flutter_test` para ejecutar pruebas automatizadas en un entorno controlado.

**Objetivos principales:**
- Validar la persistencia y conversión de modelos de datos.
- Verificar la exactitud matemática de las regresiones lineales.
- Asegurar que las predicciones respeten las reglas de negocio (ej. valores no negativos).
- Probar casos de borde y manejo de errores.

---

## 2. Pruebas de Modelos de Datos (`RegistroModel`)

El archivo [registro_model_test.dart](file:///D:/Universidad/PGC/regressly/test/models/registro_model_test.dart) contiene las pruebas para el modelo central de la aplicación.

### Casos de Prueba Detallados:

#### A. Creación desde Map (`fromMap`)
- **Objetivo:** Verificar que los datos provenientes de la base de datos (SQLite) se mapeen correctamente a los atributos de la clase.
- **Validación:** Se comprobó que campos numéricos (`double`), cadenas (`String`) y enteros (`int`) mantengan su valor y tipo después de la instanciación.

#### B. Conversión a Map (`toMap`)
- **Objetivo:** Asegurar que el objeto pueda ser serializado correctamente para su almacenamiento.
- **Validación:** Se verificó que las llaves del mapa coincidan exactamente con las columnas esperadas por el esquema de la base de datos.

#### C. Manejo de Nulos y Valores por Defecto
- **Objetivo:** Probar la robustez del modelo ante datos incompletos.
- **Validación:** Se suministró un mapa con campos faltantes y se comprobó que el modelo asigne valores predeterminados seguros (ej. `0.0` para litros) en lugar de lanzar excepciones de puntero nulo.

---

## 3. Pruebas de Lógica de Analítica (`AnalyticsService`)

El archivo [analytics_service_test.dart](file:///D:/Universidad/PGC/regressly/test/services/analytics_service_test.dart) valida el núcleo predictivo de la aplicación.

### Bloque 1: Pruebas de Regresión Lineal

#### A. Condición de Mínimo de Datos
- **Entrada:** Lista con menos de 2 registros.
- **Resultado Esperado:** Pendiente, intercepto y R² iguales a 0.
- **Justificación:** No es posible trazar una tendencia lineal con un solo punto de datos.

#### B. Tendencia de Crecimiento Positivo
- **Entrada:** Datos controlados que siguen la función `y = 10x + 100`.
- **Validación:** El servicio debió calcular exactamente una pendiente de `10.0` y un coeficiente de determinación R² de `1.0` (ajuste perfecto).

#### C. Tendencia de Decrecimiento (Negativa)
- **Entrada:** Datos que siguen la función `y = -5x + 50`.
- **Validación:** Se confirmó que el algoritmo identifica correctamente tendencias a la baja, crucial para detectar caídas en la producción lechera.

### Bloque 2: Pruebas de Predicción

#### A. Proyección a Futuro
- **Objetivo:** Validar que el servicio genere puntos de datos adicionales basados en la tendencia calculada.
- **Validación:** Para una tendencia `y = 2x + 10`, se verificó que las predicciones para los siguientes días sigan la progresión aritmética esperada.

#### B. Restricciones Físicas (Valores No Negativos)
- **Objetivo:** Asegurar que las predicciones tengan sentido en el mundo real.
- **Validación:** Incluso si la tendencia matemática sugiere valores negativos (ej. producción cayendo drásticamente), el sistema debe truncar o manejar el resultado para que nunca devuelva litros menores a cero.

---

## 4. Herramientas y Metodología

- **Framework:** [flutter_test](https://pub.dev/packages/flutter_test) para ejecución y aserciones.
- **Técnica de Aserción:** Uso intensivo de `expect()` con comparadores de precisión (`closeTo`) para manejar errores de redondeo en cálculos de punto flotante.
- **Organización:** Estructura de `group()` para separar responsabilidades entre modelos y servicios, facilitando la identificación de fallos.

---

> [!IMPORTANT]
> Todos los tests actuales pasan con éxito (`100% pass rate`), lo que garantiza que el motor de cálculo de **Regressly** es fiable para su uso en entornos de producción agrícola.
