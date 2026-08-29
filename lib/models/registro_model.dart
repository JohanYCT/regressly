class RegistroModel {
  final int? id;
  final String fecha;
  final double litrosManana;
  final double litrosTarde;
  final double litrosTotal;
  final String observaciones;
  final String createdAt;

  RegistroModel({
    this.id,
    required this.fecha,
    required this.litrosManana,
    required this.litrosTarde,
    required this.litrosTotal,
    required this.observaciones,
    required this.createdAt,
  });

  factory RegistroModel.fromMap(Map<String, dynamic> map) {
    return RegistroModel(
      id: map['id'],
      fecha: map['fecha'],
      litrosManana: map['litros_manana']?.toDouble() ?? 0.0,
      litrosTarde: map['litros_tarde']?.toDouble() ?? 0.0,
      litrosTotal: map['litros_total']?.toDouble() ?? 0.0,
      observaciones: map['observaciones'] ?? '',
      createdAt: map['created_at'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'fecha': fecha,
      'litros_manana': litrosManana,
      'litros_tarde': litrosTarde,
      'litros_total': litrosTotal,
      'observaciones': observaciones,
      'created_at': createdAt,
    };
  }
}
