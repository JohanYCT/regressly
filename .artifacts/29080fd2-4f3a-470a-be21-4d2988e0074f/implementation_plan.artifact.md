# Plan de Corrección de Tests de Integración

He analizado el código de los tests y de la aplicación, y he detectado tres causas principales por las que los tests de integración están fallando:

1.  **Detección de múltiples widgets**: En la pantalla de analítica, esperas encontrar una sola vez el texto `"90.0 L"`. Sin embargo, cuando solo hay un registro, ese valor aparece en **Total**, **Promedio**, **Máximo** y **Mínimo**, lo que causa que el test falle al encontrar 4 coincidencias en lugar de una.
2.  **Selector de fecha bloqueante**: El test pulsa el icono de edición de fecha (`Icons.edit`), lo que abre un diálogo (`showDatePicker`). Como el test no cierra este diálogo, las siguientes acciones (como escribir texto) pueden fallar porque el diálogo bloquea la interfaz.
3.  **Visibilidad de elementos**: Algunos campos de texto y botones pueden estar fuera de la pantalla en dispositivos pequeños. Es necesario asegurar que sean visibles antes de interactuar con ellos.

## Cambios Propuestos

### Test de Integración

#### [MODIFY] [app_test.dart](file:///D:/Universidad/PGC/regressly/integration_test/app_test.dart)

*   Eliminar la interacción innecesaria con el selector de fecha que estaba bloqueando el flujo.
*   Añadir `tester.ensureVisible()` antes de interactuar con campos de texto y botones para evitar fallos por elementos fuera de pantalla.
*   Ser más específico al verificar el promedio en la pantalla de analítica para evitar el error de múltiples coincidencias (usando un selector que busque el descendiente del ítem "Promedio").
*   Añadir soporte básico para `sqflite_common_ffi` en el test para permitir ejecutarlo en Windows si fuera necesario (opcional pero recomendado).

## Plan de Verificación

### Pruebas Automatizadas
*   Ejecutar el test de integración corregido:
    ```bash
    flutter test integration_test/app_test.dart -d emulator-5554
    ```

### Verificación Manual
*   Observar la ejecución en el emulador para confirmar que el flujo de Configuración -> Registro -> Análisis se completa correctamente sin bloqueos.
