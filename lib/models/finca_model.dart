class FincaModel {
  final int? id;
  final String nombreProductor;
  final String nombreFinca;
  final String ubicacion;
  final int numeroVacas;
  final double precioLitro;

  FincaModel({
    this.id,
    required this.nombreProductor,
    required this.nombreFinca,
    required this.ubicacion,
    required this.numeroVacas,
    required this.precioLitro,
  });

  factory FincaModel.fromMap(Map<String, dynamic> map) {
    return FincaModel(
      id: map['id'],
      nombreProductor: map['nombre_productor'] ?? '',
      nombreFinca: map['nombre_finca'] ?? '',
      ubicacion: map['ubicacion'] ?? '',
      numeroVacas: map['numero_vacas'] ?? 0,
      precioLitro: map['precio_litro']?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'nombre_productor': nombreProductor,
      'nombre_finca': nombreFinca,
      'ubicacion': ubicacion,
      'numero_vacas': numeroVacas,
      'precio_litro': precioLitro,
    };
  }
}
