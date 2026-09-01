# Plan para Robustez de Tests de Integración en Múltiples Dispositivos

El objetivo es modificar el test de integración `app_test.dart` para eliminar dependencias de tamaños de pantalla específicos y mejorar la sincronización, asegurando que funcione correctamente en dispositivos con diferentes resoluciones, densidades de píxeles y velocidades de procesamiento.

## User Review Required

> [!IMPORTANT]
> Se reemplazarán los comandos de `drag` manuales con offsets fijos por `scrollUntilVisible`, lo cual es más confiable ya que detecta dinámicamente si el elemento está en pantalla.

## Proposed Changes

### [Integration Tests]

#### [MODIFY] [app_test.dart](file:///D:/Universidad/PGC/regressly/integration_test/app_test.dart)
- Reemplazar `tester.drag` con `tester.scrollUntilVisible` para navegar en los `SingleChildScrollView`.
- Optimizar el uso de `ensureVisible` y `pumpAndSettle`.
- Asegurar que el teclado se cierre correctamente después de cada entrada de texto para evitar que oculte elementos.
- Mejorar los selectores para que sean más resistentes a cambios menores en la jerarquía de la UI.

## Verification Plan

### Automated Tests
- Ejecutar el test de integración en al menos dos emuladores con diferentes resoluciones (ej. Phone y Tablet).
- `flutter test integration_test/app_test.dart`

### Manual Verification
- Verificar que el test no falle por elementos "no encontrados" debido a problemas de scroll o teclado.
