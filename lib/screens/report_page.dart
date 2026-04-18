import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/entities.dart';
import '../services/repositories.dart';
import '../utils/save_report.dart';
import '../widgets/glass_container.dart';
import 'car_detail_page.dart';

class ReportPage extends StatefulWidget {
  final Profile profile;

  const ReportPage({super.key, required this.profile});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  final _yearRepo = YearRepository();
  final _carRepo = CarRepository();
  final _costRepo = CarCostRepository();
  final _searchController = TextEditingController();
  String _statusFilter = 'All';
  String _readinessFilter = 'All';
  String _repairReportCarId = 'all';
  bool _repairPreviewLoading = false;
  double _repairPreviewTotal = 0;
  double _repairPreviewPaid = 0;
  double _repairPreviewUnpaid = 0;
  ProfileYear? _selectedYear;
  List<ProfileYear> _years = [];
  List<Map<String, dynamic>> _cars = [];
  bool _loading = true;
  bool _loadingCars = false;

  @override
  void initState() {
    super.initState();
    _loadYears();
  }

  Future<void> _loadYears() async {
    setState(() => _loading = true);
    final years = await _yearRepo.getYearsForProfile(widget.profile.id);
    if (years.isEmpty) {
      setState(() => _loading = false);
      return;
    }
    _years = years;
    _selectedYear = years.first;
    setState(() => _loading = false);
    await _loadCars();
  }

  Future<void> _loadCars() async {
    final year = _selectedYear;
    if (year == null) return;
    setState(() => _loadingCars = true);
    final cars = await _carRepo.getCarsForYearWithTotals(year.id);
    setState(() {
      _cars = cars;
      final exists = _repairReportCarId == 'all'
          ? true
          : cars.any((c) => c['id'] == _repairReportCarId);
      if (!exists) _repairReportCarId = 'all';
      _loadingCars = false;
    });
    await _loadRepairPreview();
  }

  Future<void> _loadRepairPreview() async {
    final boughtCars = _boughtCars;
    if (boughtCars.isEmpty) {
      if (!mounted) return;
      setState(() {
        _repairPreviewLoading = false;
        _repairPreviewTotal = 0;
        _repairPreviewPaid = 0;
        _repairPreviewUnpaid = 0;
      });
      return;
    }

    final selectedCars = _repairReportCarId == 'all'
        ? boughtCars
        : boughtCars
            .where((row) => (row['id'] as String?) == _repairReportCarId)
            .toList();

    if (!mounted) return;
    setState(() => _repairPreviewLoading = true);

    double total = 0;
    double paid = 0;
    double unpaid = 0;

    for (final car in selectedCars) {
      final carId = car['id'] as String;
      final items = await _costRepo.getCostItemsForCar(carId);
      for (final item in items) {
        total += item.amount;
        if (item.status.toLowerCase() == 'paid') {
          paid += item.amount;
        } else {
          unpaid += item.amount;
        }
      }
    }

    if (!mounted) return;
    setState(() {
      _repairPreviewTotal = total;
      _repairPreviewPaid = paid;
      _repairPreviewUnpaid = unpaid;
      _repairPreviewLoading = false;
    });
  }

  List<Map<String, dynamic>> get _filteredCars {
    final query = _searchController.text.toLowerCase().trim();
    return _cars.where((row) {
      final model = (row['model'] as String? ?? '').toLowerCase();
      final vin = (row['vin'] as String? ?? '').toLowerCase();
      final status = (row['status'] as String? ?? '').toLowerCase();
      final readiness = (row['readiness'] as String? ?? '').toLowerCase();
      final matchesSearch =
          query.isEmpty || model.contains(query) || vin.contains(query);
      final matchesStatus = _statusFilter == 'All'
          ? true
          : status == _statusFilter.toLowerCase();
      final matchesReadiness = _readinessFilter == 'All'
          ? true
          : readiness == _readinessFilter.toLowerCase();
      return matchesSearch && matchesStatus && matchesReadiness;
    }).toList();
  }

  double get _yearPnLSoldOnly {
    return _filteredCars.fold<double>(0, (sum, row) {
      final status = (row['status'] as String? ?? '').toLowerCase();
      if (status != 'sold') return sum;
      final selling = (row['selling_price'] as num?)?.toDouble() ?? 0;
      final totalCost = (row['total_cost'] as double?) ?? 0;
      return sum + selling - totalCost;
    });
  }

  List<Map<String, dynamic>> get _boughtCars {
    return _cars.where((row) {
      final buying = (row['buying_price'] as num?)?.toDouble() ?? 0;
      return buying > 0;
    }).toList();
  }

  String _buildCsv() {
    const sep = ',';
    final sb = StringBuffer();
    sb.writeln(
      'Profile${sep}Year${sep}Car${sep}VIN${sep}Readiness${sep}Status${sep}Buying Price${sep}Selling Price${sep}Total Cost${sep}PnL',
    );
    final year = _selectedYear?.year ?? 0;
    for (final row in _filteredCars) {
      final model = (row['model'] as String? ?? '').replaceAll(',', ' ');
      final vin = (row['vin'] as String? ?? '').replaceAll(',', ' ');
      final readiness = (row['readiness'] as String? ?? '').replaceAll(',', ' ');
      final status = (row['status'] as String? ?? '').replaceAll(',', ' ');
      final buying = (row['buying_price'] as num?)?.toDouble();
      final selling = (row['selling_price'] as num?)?.toDouble();
      final totalCost = (row['total_cost'] as double?) ?? 0;
      final pnl = (selling ?? 0) - totalCost;
      sb.writeln(
        '${widget.profile.name.replaceAll(sep, " ")}$sep$year$sep$model$sep$vin$sep$readiness$sep$status$sep${buying?.toStringAsFixed(2) ?? ""}$sep${selling?.toStringAsFixed(2) ?? ""}$sep${totalCost.toStringAsFixed(2)}$sep${pnl.toStringAsFixed(2)}',
      );
    }
    return sb.toString();
  }

  Future<void> _saveReport() async {
    final cars = _filteredCars;
    if (cars.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No data to save. Apply filters or add cars.')),
        );
      }
      return;
    }
    final csv = _buildCsv();
    final dateStr = DateFormat('yyyy-MM-dd_Hms').format(DateTime.now());
    final filename = 'FlipTrack_Report_${widget.profile.name}_${_selectedYear?.year ?? "all"}_$dateStr.csv';
    await saveReportToDevice(filename, csv);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Report saved as $filename')),
      );
    }
  }

  Future<void> _saveRepairReport() async {
    final boughtCars = _boughtCars;
    if (boughtCars.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No bought cars found for repair report.')),
        );
      }
      return;
    }

    final selectedCars = _repairReportCarId == 'all'
        ? boughtCars
        : boughtCars
            .where((row) => (row['id'] as String?) == _repairReportCarId)
            .toList();

    if (selectedCars.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selected car not found.')),
        );
      }
      return;
    }

    const sep = ',';
    final sb = StringBuffer();
    sb.writeln(
      'Profile${sep}Year${sep}Car${sep}VIN${sep}Repair Date${sep}Status${sep}Description${sep}Amount',
    );

    double total = 0;
    double paid = 0;
    double unpaid = 0;

    for (final car in selectedCars) {
      final carId = car['id'] as String;
      final model = (car['model'] as String? ?? '').replaceAll(',', ' ');
      final vin = (car['vin'] as String? ?? '').replaceAll(',', ' ');
      final items = await _costRepo.getCostItemsForCar(carId);

      for (final item in items) {
        final status = item.status.trim();
        final statusLower = status.toLowerCase();
        total += item.amount;
        if (statusLower == 'paid') {
          paid += item.amount;
        } else {
          unpaid += item.amount;
        }
        sb.writeln(
          '${widget.profile.name.replaceAll(sep, " ")}$sep${_selectedYear?.year ?? ""}$sep$model$sep$vin$sep${DateFormat('yyyy-MM-dd').format(item.date)}$sep${status.replaceAll(sep, " ")}$sep${item.description.replaceAll(sep, " ")}$sep${item.amount.toStringAsFixed(2)}',
        );
      }
    }

    sb.writeln();
    sb.writeln('Summary${sep}Value');
    sb.writeln('Total Repair Amount$sep${total.toStringAsFixed(2)}');
    sb.writeln('Paid Amount$sep${paid.toStringAsFixed(2)}');
    sb.writeln('Unpaid Amount$sep${unpaid.toStringAsFixed(2)}');

    final dateStr = DateFormat('yyyy-MM-dd_Hms').format(DateTime.now());
    final selectedName = _repairReportCarId == 'all'
        ? 'all_bought_cars'
        : (selectedCars.first['model'] as String? ?? 'car')
            .replaceAll(' ', '_')
            .toLowerCase();
    final filename =
        'FlipTrack_Repair_Report_${widget.profile.name}_${_selectedYear?.year ?? "all"}_${selectedName}_$dateStr.csv';
    await saveReportToDevice(filename, sb.toString());

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Repair report saved as $filename')),
      );
    }
  }

  Future<void> _openCarDetail(Map<String, dynamic> row) async {
    final year = _selectedYear;
    if (year == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CarDetailPage(
          profile: widget.profile,
          profileYear: year,
          carRow: row,
        ),
      ),
    );
    await _loadCars();
  }

  @override
  Widget build(BuildContext context) {
    final visibleCars = _filteredCars;
    final yearPnL = _yearPnLSoldOnly;
    final yearPnLText = yearPnL >= 0
        ? '+${yearPnL.toStringAsFixed(2)}'
        : yearPnL.toStringAsFixed(2);

    return Scaffold(
      appBar: AppBar(
        title: const Text('View Report'),
      ),
      body: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GlassContainer(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _loading
                            ? const LinearProgressIndicator()
                            : DropdownButtonFormField<ProfileYear>(
                                value: _selectedYear,
                                decoration: const InputDecoration(labelText: 'Year'),
                                items: _years
                                    .map(
                                      (y) => DropdownMenuItem(
                                        value: y,
                                        child: Text(y.year.toString()),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  setState(() => _selectedYear = value);
                                  _loadCars();
                                },
                              ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            labelText: 'Search by model or VIN',
                            prefixIcon: Icon(Icons.search),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _statusFilter,
                          decoration: const InputDecoration(labelText: 'Status'),
                          items: const [
                            DropdownMenuItem(value: 'All', child: Text('All')),
                            DropdownMenuItem(value: 'Sold', child: Text('Sold')),
                            DropdownMenuItem(value: 'Unsold', child: Text('Unsold')),
                          ],
                          onChanged: (value) {
                            if (value != null) setState(() => _statusFilter = value);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _readinessFilter,
                          decoration: const InputDecoration(labelText: 'Readiness'),
                          items: const [
                            DropdownMenuItem(value: 'All', child: Text('All')),
                            DropdownMenuItem(
                              value: 'In progress',
                              child: Text('In progress'),
                            ),
                            DropdownMenuItem(
                              value: 'Complete',
                              child: Text('Complete'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) setState(() => _readinessFilter = value);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Year PnL (Sold only): $yearPnLText',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: yearPnL >= 0 ? Colors.green[700] : Colors.red[700],
                      ),
                ),
                FilledButton.icon(
                  onPressed: visibleCars.isEmpty ? null : _saveReport,
                  icon: const Icon(Icons.download),
                  label: const Text('Save report'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            GlassContainer(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _repairReportCarId,
                      decoration: const InputDecoration(
                        labelText: 'Repair report scope',
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: 'all',
                          child: Text('All bought cars'),
                        ),
                        ..._boughtCars.map(
                          (row) => DropdownMenuItem(
                            value: row['id'] as String,
                            child: Text(
                              '${row['model'] as String? ?? 'Car'} (${row['vin'] as String? ?? ''})',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _repairReportCarId = value);
                          _loadRepairPreview();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: _boughtCars.isEmpty ? null : _saveRepairReport,
                    icon: const Icon(Icons.download_for_offline_outlined),
                    label: const Text('Save repair report'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            GlassContainer(
              padding: const EdgeInsets.all(12),
              child: _repairPreviewLoading
                  ? const LinearProgressIndicator()
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Repair totals',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        Text(
                          'Total: \$${_repairPreviewTotal.toStringAsFixed(2)}  |  Paid: \$${_repairPreviewPaid.toStringAsFixed(2)}  |  Unpaid: \$${_repairPreviewUnpaid.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _loadingCars
                  ? const Center(child: CircularProgressIndicator())
                  : visibleCars.isEmpty
                      ? const Center(
                          child: Text(
                            'No cars match the filters. Change filters or add cars.',
                            textAlign: TextAlign.center,
                          ),
                        )
                      : GlassContainer(
                          padding: const EdgeInsets.all(0),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SingleChildScrollView(
                              child: DataTable(
                                columnSpacing: 16,
                                showCheckboxColumn: false,
                                columns: const [
                                  DataColumn(label: Text('Car')),
                                  DataColumn(label: Text('VIN')),
                                  DataColumn(label: Text('Readiness')),
                                  DataColumn(label: Text('Status')),
                                  DataColumn(label: Text('Buying')),
                                  DataColumn(label: Text('Selling')),
                                  DataColumn(label: Text('Paid')),
                                  DataColumn(label: Text('Unpaid')),
                                  DataColumn(label: Text('Total')),
                                  DataColumn(label: Text('PnL')),
                                  DataColumn(label: Text('Details')),
                                ],
                                rows: visibleCars.map((row) {
                                  final model = row['model'] as String? ?? '';
                                  final vin = row['vin'] as String? ?? '';
                                  final readiness = row['readiness'] as String? ?? '';
                                  final status = row['status'] as String? ?? '';
                                  final buying = (row['buying_price'] as num?)?.toDouble();
                                  final selling = (row['selling_price'] as num?)?.toDouble();
                                  final paidAmount = (row['paid_amount'] as double?) ?? 0;
                                  final unpaidAmount = (row['unpaid_amount'] as double?) ?? 0;
                                  final totalCost = (row['total_cost'] as double?) ?? 0;
                                  final pnl = (selling ?? 0) - totalCost;
                                  return DataRow(
                                    cells: [
                                      DataCell(Text(model)),
                                      DataCell(Text(vin)),
                                      DataCell(Text(readiness)),
                                      DataCell(Text(status)),
                                      DataCell(Text(buying?.toStringAsFixed(2) ?? '-')),
                                      DataCell(Text(selling?.toStringAsFixed(2) ?? '-')),
                                      DataCell(Text(paidAmount.toStringAsFixed(2))),
                                      DataCell(Text(unpaidAmount.toStringAsFixed(2))),
                                      DataCell(Text(totalCost.toStringAsFixed(2))),
                                      DataCell(
                                        Text(
                                          pnl >= 0 ? '+${pnl.toStringAsFixed(2)}' : pnl.toStringAsFixed(2),
                                          style: TextStyle(
                                            color: pnl >= 0 ? Colors.green[700] : Colors.red[700],
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        TextButton(
                                          onPressed: () => _openCarDetail(row),
                                          child: const Text('Go To'),
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
