import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:regressly/app_theme.dart';
import 'package:regressly/database/database_helper.dart';
import 'package:regressly/models/finca_model.dart';
import 'package:regressly/models/registro_model.dart';
import 'package:regressly/services/pdf_report_service.dart';

enum FiltroFecha {
  todo,
  esteMes,
  ultimos30Dias,
  personalizado,
}

class HistorialScreen extends StatefulWidget {
  const HistorialScreen({super.key});

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  bool _isLoading = true;
  List<RegistroModel> _allRegistros = [];
  List<RegistroModel> _filteredRegistros = [];
  FincaModel? _finca;

  FiltroFecha _filtroSeleccionado = FiltroFecha.todo;
  DateTimeRange? _customRange;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase().trim();
        _applyFilters();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final db = DatabaseHelper.instance;
      final registros = await db.queryAllRegistros();
      final finca = await db.getFinca();

      if (mounted) {
        setState(() {
          _allRegistros = registros;
          _finca = finca;
          _isLoading = false;
        });
        _applyFilters();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar historial: $e')),
        );
      }
    }
  }

  void _applyFilters() {
    final now = DateTime.now();
    List<RegistroModel> filtered = List.from(_allRegistros);

    // 1. Aplicar filtro de fecha
    switch (_filtroSeleccionado) {
      case FiltroFecha.esteMes:
        filtered = filtered.where((r) {
          try {
            final dt = DateTime.parse(r.fecha);
            return dt.year == now.year && dt.month == now.month;
          } catch (_) {
            return false;
          }
        }).toList();
        break;

      case FiltroFecha.ultimos30Dias:
        final limitDate = now.subtract(const Duration(days: 30));
        filtered = filtered.where((r) {
          try {
            final dt = DateTime.parse(r.fecha);
            return dt.isAfter(limitDate) || dt.isAtSameMomentAs(limitDate);
          } catch (_) {
            return false;
          }
        }).toList();
        break;

      case FiltroFecha.personalizado:
        if (_customRange != null) {
          final start = DateTime(_customRange!.start.year, _customRange!.start.month, _customRange!.start.day);
          final end = DateTime(_customRange!.end.year, _customRange!.end.month, _customRange!.end.day, 23, 59, 59);

          filtered = filtered.where((r) {
            try {
              final dt = DateTime.parse(r.fecha);
              return (dt.isAfter(start) || dt.isAtSameMomentAs(start)) &&
                     (dt.isBefore(end) || dt.isAtSameMomentAs(end));
            } catch (_) {
              return false;
            }
          }).toList();
        }
        break;

      case FiltroFecha.todo:
        break;
    }

    // 2. Aplicar búsqueda de texto
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((r) {
        final obs = r.observaciones.toLowerCase();
        final fecha = r.fecha.toLowerCase();
        return obs.contains(_searchQuery) || fecha.contains(_searchQuery);
      }).toList();
    }

    setState(() {
      _filteredRegistros = filtered;
    });
  }

  Future<void> _selectCustomRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _customRange ?? DateTimeRange(
        start: DateTime.now().subtract(const Duration(days: 7)),
        end: DateTime.now(),
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryGreen,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _customRange = picked;
        _filtroSeleccionado = FiltroFecha.personalizado;
      });
      _applyFilters();
    }
  }

  String _getFiltroTitulo() {
    switch (_filtroSeleccionado) {
      case FiltroFecha.todo:
        return 'Historial Completo';
      case FiltroFecha.esteMes:
        return 'Este Mes (${DateFormat('MMMM yyyy', 'es_ES').format(DateTime.now())})';
      case FiltroFecha.ultimos30Dias:
        return 'Últimos 30 días';
      case FiltroFecha.personalizado:
        if (_customRange != null) {
          final fmt = DateFormat('dd/MM/yyyy');
          return '${fmt.format(_customRange!.start)} - ${fmt.format(_customRange!.end)}';
        }
        return 'Rango Personalizado';
    }
  }

  Future<void> _exportarPdfDialog() async {
    if (_allRegistros.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay registros guardados para exportar a PDF.')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.picture_as_pdf, color: AppTheme.primaryGreen, size: 28),
                  SizedBox(width: 10),
                  Text(
                    'Exportar Reporte PDF',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Selecciona qué rango de producción deseas incluir en el documento PDF:',
                style: TextStyle(fontSize: 14, color: AppTheme.textLight),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.filter_list, color: AppTheme.primaryGreen),
                title: const Text('Registros filtrados actualmente'),
                subtitle: Text('${_filteredRegistros.length} registros (${_getFiltroTitulo()})'),
                onTap: () {
                  Navigator.pop(ctx);
                  _generarYMostrarPdf(_filteredRegistros, _getFiltroTitulo());
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.all_inclusive, color: AppTheme.lightGreen),
                title: const Text('Todo el historial completo'),
                subtitle: Text('${_allRegistros.length} registros en total'),
                onTap: () {
                  Navigator.pop(ctx);
                  _generarYMostrarPdf(_allRegistros, 'Historial Completo');
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.date_range, color: Colors.orange),
                title: const Text('Elegir rango de fechas personalizado'),
                subtitle: const Text('Seleccionar fecha inicio y fin'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                    initialDateRange: _customRange ?? DateTimeRange(
                      start: DateTime.now().subtract(const Duration(days: 30)),
                      end: DateTime.now(),
                    ),
                  );

                  if (picked != null) {
                    final start = DateTime(picked.start.year, picked.start.month, picked.start.day);
                    final end = DateTime(picked.end.year, picked.end.month, picked.end.day, 23, 59, 59);

                    final pdfRegs = _allRegistros.where((r) {
                      try {
                        final dt = DateTime.parse(r.fecha);
                        return (dt.isAfter(start) || dt.isAtSameMomentAs(start)) &&
                               (dt.isBefore(end) || dt.isAtSameMomentAs(end));
                      } catch (_) {
                        return false;
                      }
                    }).toList();

                    final fmt = DateFormat('dd/MM/yyyy');
                    final titulo = '${fmt.format(picked.start)} - ${fmt.format(picked.end)}';
                    _generarYMostrarPdf(pdfRegs, titulo);
                  }
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Future<void> _generarYMostrarPdf(List<RegistroModel> registrosExport, String tituloRango) async {
    if (registrosExport.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay registros en el rango seleccionado.')),
      );
      return;
    }

    try {
      final pdfBytes = await PdfReportService.generateProductionReport(
        registros: registrosExport,
        finca: _finca,
        tituloFiltro: tituloRango,
      );

      if (!mounted) return;

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
        name: 'Reporte_Produccion_Regressly_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al generar PDF: $e')),
        );
      }
    }
  }

  Future<void> _eliminarRegistro(RegistroModel registro) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Registro'),
        content: Text('¿Estás seguro de eliminar el registro del día ${registro.fecha}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true && registro.id != null) {
      await DatabaseHelper.instance.deleteRegistro(registro.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registro eliminado correctamente')),
        );
        _loadData();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Cálculos estadísticos para las tarjetas del filtro actual
    final totalLitros = _filteredRegistros.fold<double>(0.0, (sum, r) => sum + r.litrosTotal);
    final promedioDiario = _filteredRegistros.isNotEmpty ? totalLitros / _filteredRegistros.length : 0.0;
    
    double maxProduccion = 0.0;
    for (var r in _filteredRegistros) {
      if (r.litrosTotal > maxProduccion) maxProduccion = r.litrosTotal;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Producción'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Exportar a PDF',
            onPressed: _exportarPdfDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
          : RefreshIndicator(
              onRefresh: _loadData,
              color: AppTheme.primaryGreen,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // ============================
                    // 🔍 SECCIÓN DE FILTROS Y BÚSQUEDA
                    // ============================
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Búsqueda por texto
                          TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Buscar por fecha u observación...',
                              prefixIcon: const Icon(Icons.search, color: AppTheme.primaryGreen),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () => _searchController.clear(),
                                    )
                                  : null,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Chips de filtro por fecha
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildFilterChip('Todo', FiltroFecha.todo),
                                const SizedBox(width: 8),
                                _buildFilterChip('Este Mes', FiltroFecha.esteMes),
                                const SizedBox(width: 8),
                                _buildFilterChip('Últimos 30 días', FiltroFecha.ultimos30Dias),
                                const SizedBox(width: 8),
                                FilterChip(
                                  selected: _filtroSeleccionado == FiltroFecha.personalizado,
                                  label: Text(
                                    _filtroSeleccionado == FiltroFecha.personalizado && _customRange != null
                                        ? '${DateFormat('dd/MM').format(_customRange!.start)} - ${DateFormat('dd/MM').format(_customRange!.end)}'
                                        : 'Rango...',
                                    style: TextStyle(
                                      color: _filtroSeleccionado == FiltroFecha.personalizado
                                          ? Colors.white
                                          : AppTheme.textDark,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  avatar: Icon(
                                    Icons.date_range,
                                    size: 16,
                                    color: _filtroSeleccionado == FiltroFecha.personalizado
                                        ? Colors.white
                                        : AppTheme.primaryGreen,
                                  ),
                                  selectedColor: AppTheme.primaryGreen,
                                  backgroundColor: Colors.grey.shade200,
                                  onSelected: (_) => _selectCustomRange(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ============================
                    // 📊 TARJETAS KPIs
                    // ============================
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildMetricCard(
                              'Total Litros',
                              '${totalLitros.toStringAsFixed(1)} L',
                              Icons.water_drop,
                              AppTheme.primaryGreen,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildMetricCard(
                              'Promedio/Día',
                              '${promedioDiario.toStringAsFixed(1)} L',
                              Icons.show_chart,
                              AppTheme.lightGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildMetricCard(
                              'Registros',
                              '${_filteredRegistros.length} días',
                              Icons.calendar_today,
                              Colors.teal,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildMetricCard(
                              'Máximo Día',
                              '${maxProduccion.toStringAsFixed(1)} L',
                              Icons.grade,
                              Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Encabezado de la lista con botón de exportar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Registros (${_filteredRegistros.length})',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textDark,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _exportarPdfDialog,
                            icon: const Icon(Icons.picture_as_pdf, size: 18, color: AppTheme.primaryGreen),
                            label: const Text(
                              'PDF',
                              style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ============================
                    // 📋 LISTADO DE REGISTROS
                    // ============================
                    if (_filteredRegistros.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          children: [
                            Icon(Icons.assignment_late_outlined, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text(
                              _allRegistros.isEmpty
                                  ? 'Aún no tienes registros de producción registrados.'
                                  : 'No se encontraron registros para los filtros seleccionados.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: AppTheme.textLight, fontSize: 15),
                            ),
                            const SizedBox(height: 16),
                            if (_allRegistros.isEmpty)
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pushNamed(context, '/registro').then((_) => _loadData());
                                },
                                icon: const Icon(Icons.add),
                                label: const Text('Agregar Primer Registro'),
                              ),
                          ],
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: _filteredRegistros.length,
                        itemBuilder: (context, index) {
                          final item = _filteredRegistros[index];
                          return _buildRegistroCard(item);
                        },
                      ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildFilterChip(String label, FiltroFecha filtro) {
    final isSelected = _filtroSeleccionado == filtro;
    return FilterChip(
      selected: isSelected,
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : AppTheme.textDark,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selectedColor: AppTheme.primaryGreen,
      backgroundColor: Colors.grey.shade200,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _filtroSeleccionado = filtro;
          });
          _applyFilters();
        }
      },
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 11, color: AppTheme.textLight),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegistroCard(RegistroModel registro) {
    DateTime? parsedDate;
    try {
      parsedDate = DateTime.parse(registro.fecha);
    } catch (_) {}

    final fechaFormateada = parsedDate != null
        ? DateFormat('EEEE d "de" MMMM, yyyy', 'es_ES').format(parsedDate)
        : registro.fecha;

    final total = registro.litrosTotal > 0 ? registro.litrosTotal : 1.0;
    final pctManana = (registro.litrosManana / total).clamp(0.0, 1.0);
    final pctTarde = (registro.litrosTarde / total).clamp(0.0, 1.0);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado de la tarjeta
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.event, color: AppTheme.primaryGreen, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      fechaFormateada.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                  ],
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 20, color: Colors.grey),
                  onSelected: (value) {
                    if (value == 'eliminar') {
                      _eliminarRegistro(registro);
                    } else if (value == 'editar') {
                      Navigator.pushNamed(
                        context,
                        '/registro',
                        arguments: registro,
                      ).then((_) => _loadData());
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'editar',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 18, color: AppTheme.primaryGreen),
                          SizedBox(width: 8),
                          Text('Editar'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'eliminar',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Eliminar'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Producción en Mañana vs Tarde + Total
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.wb_sunny_outlined, size: 14, color: Colors.orange),
                            SizedBox(width: 4),
                            Text('Mañana', style: TextStyle(fontSize: 11, color: AppTheme.textLight)),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${registro.litrosManana.toStringAsFixed(1)} L',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.indigo.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.nights_stay_outlined, size: 14, color: Colors.indigo),
                            SizedBox(width: 4),
                            Text('Tarde', style: TextStyle(fontSize: 11, color: AppTheme.textLight)),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${registro.litrosTarde.toStringAsFixed(1)} L',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.water_drop, size: 14, color: Colors.white70),
                            SizedBox(width: 4),
                            Text('Total Día', style: TextStyle(fontSize: 11, color: Colors.white70)),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${registro.litrosTotal.toStringAsFixed(1)} L',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Barra visual de proporción Mañana vs Tarde
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                height: 6,
                child: Row(
                  children: [
                    Expanded(
                      flex: (pctManana * 100).round(),
                      child: Container(color: Colors.orange.shade400),
                    ),
                    Expanded(
                      flex: (pctTarde * 100).round(),
                      child: Container(color: Colors.indigo.shade400),
                    ),
                  ],
                ),
              ),
            ),

            if (registro.observaciones.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.notes, size: 14, color: AppTheme.textLight),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      registro.observaciones,
                      style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppTheme.textLight),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
