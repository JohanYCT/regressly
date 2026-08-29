import 'dart:math';
import 'package:regressly/models/registro_model.dart';

class RegressionResult {
  final double pendiente;
  final double intercepto;
  final double r2;

  RegressionResult({
    required this.pendiente,
    required this.intercepto,
    required this.r2,
  });
}

class AnalyticsService {
  /// Calcula la regresión lineal simple y el coeficiente R2.
  RegressionResult calcularRegresion(List<RegistroModel> registros) {
    if (registros.length < 2) {
      return RegressionResult(pendiente: 0, intercepto: 0, r2: 0);
    }

    int n = registros.length;
    double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;

    for (int i = 0; i < n; i++) {
      double x = i.toDouble();
      double y = registros[i].litrosTotal;
      sumX += x;
      sumY += y;
      sumXY += x * y;
      sumX2 += x * x;
    }

    double denominador = (n * sumX2 - sumX * sumX);
    double pendiente = 0;
    double intercepto = 0;

    if (denominador != 0) {
      pendiente = (n * sumXY - sumX * sumY) / denominador;
      intercepto = (sumY - pendiente * sumX) / n;
    }

    double r2 = _calcularR2(registros, pendiente, intercepto);

    return RegressionResult(
      pendiente: pendiente,
      intercepto: intercepto,
      r2: r2,
    );
  }

  /// Calcula las predicciones para los días existentes más N días futuros.
  List<double> calcularPredicciones(
    List<RegistroModel> registros,
    double pendiente,
    double intercepto,
    int diasFuturos,
  ) {
    List<double> predicciones = [];
    int n = registros.length;

    for (int i = 0; i < n + diasFuturos; i++) {
      double prediccion = intercepto + pendiente * i;
      predicciones.add(max(0.0, prediccion));
    }
    return predicciones;
  }

  double _calcularR2(
    List<RegistroModel> registros,
    double pendiente,
    double intercepto,
  ) {
    if (registros.isEmpty) return 0;

    double sumY = 0;
    for (var r in registros) {
      sumY += r.litrosTotal;
    }
    double meanY = sumY / registros.length;

    double ssRes = 0;
    double ssTot = 0;

    for (int i = 0; i < registros.length; i++) {
      double yReal = registros[i].litrosTotal;
      double yPred = intercepto + pendiente * i;

      ssRes += pow(yReal - yPred, 2);
      ssTot += pow(yReal - meanY, 2);
    }

    return ssTot == 0 ? 0 : 1 - (ssRes / ssTot);
  }
}
