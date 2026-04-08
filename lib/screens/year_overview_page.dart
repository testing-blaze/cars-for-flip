import 'package:flutter/material.dart';

import '../models/entities.dart';
import '../services/repositories.dart';
import '../widgets/glass_container.dart';
import 'car_detail_page.dart';
import 'nauman_calculator_page.dart';
import 'report_page.dart';

class YearOverviewPage extends StatefulWidget {
  final Profile profile;

  const YearOverviewPage({super.key, required this.profile});

  @override
  State<YearOverviewPage> createState() => _YearOverviewPageState();
}

class _YearOverviewPageState extends State<YearOverviewPage> {
  final _yearRepo = YearRepository();
  final _carRepo = CarRepository();
  final _searchController = TextEditingController();
  String _statusFilter = 'All';
  String _readinessFilter = 'All';
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
      final currentYear = DateTime.now().year;
      final created =
          await _yearRepo.createYear(widget.profile.id, currentYear);
      _selectedYear = created;
      _years = [created];
    } else {
      _years = years;
      _selectedYear = years.first;
    }
    setState(() => _loading = false);
    await _loadCars();
  }

  Future<void> _addYear() async {
    final lastYear = _years.isNotEmpty ? _years.first.year : DateTime.now().year;
    final newYear = lastYear + 1;
    final created = await _yearRepo.createYear(widget.profile.id, newYear);
    setState(() {
      _years.insert(0, created);
      _selectedYear = created;
    });
    await _loadCars();
  }

  Future<void> _deleteSelectedYear() async {
    final year = _selectedYear;
    if (year == null) return;
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete year'),
            content: Text(
              'Delete all data for ${year.year}? This cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;
    await _yearRepo.deleteYear(year.id);
    await _loadYears();
  }

  Future<void> _loadCars() async {
    final year = _selectedYear;
    if (year == null) return;
    setState(() => _loadingCars = true);
    final cars = await _carRepo.getCarsForYearWithTotals(year.id);
    setState(() {
      _cars = cars;
      _loadingCars = false;
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

  Future<void> _openCarDetail([Map<String, dynamic>? carRow]) async {
    final year = _selectedYear;
    if (year == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CarDetailPage(
          profile: widget.profile,
          profileYear: year,
          carRow: carRow,
        ),
      ),
    );
    await _loadCars();
  }

  @override
  Widget build(BuildContext context) {
    final visibleCars = _filteredCars;
    final totalPnL = visibleCars.fold<double>(0, (sum, row) {
      final status = (row['status'] as String? ?? '').toLowerCase();
      if (status != 'sold') return sum;
      final selling = (row['selling_price'] as num?)?.toDouble() ?? 0;
      final totalCost = (row['total_cost'] as double?) ?? 0;
      return sum + selling - totalCost;
    });
    final totalPnLText =
        (totalPnL >= 0 ? '+${totalPnL.toStringAsFixed(2)}' : totalPnL.toStringAsFixed(2));
    final isNauman = widget.profile.name.toLowerCase().contains('nauman');

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.profile.name),
        actions: [
          if (isNauman)
            IconButton(
              icon: const Icon(Icons.calculate_outlined),
              tooltip: 'Nauman Calculator',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => NaumanCalculatorPage(profile: widget.profile),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.assessment),
            tooltip: 'View Report',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ReportPage(profile: widget.profile),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCarDetail(),
        icon: const Icon(Icons.add),
        label: const Text('Add car'),
      ),
      body: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            GlassContainer(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: _loading
                        ? const LinearProgressIndicator()
                        : DropdownButtonFormField<ProfileYear>(
                            value: _selectedYear,
                            decoration:
                                const InputDecoration(labelText: 'Year'),
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
                  IconButton.filledTonal(
                    onPressed: _addYear,
                    icon: const Icon(Icons.add),
                    tooltip: 'Add next year',
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: _deleteSelectedYear,
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Delete selected year',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            GlassContainer(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
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
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _statusFilter,
                      decoration: const InputDecoration(labelText: 'Status'),
                      items: const [
                        DropdownMenuItem(value: 'All', child: Text('All')),
                        DropdownMenuItem(value: 'Sold', child: Text('Sold')),
                        DropdownMenuItem(
                            value: 'Unsold', child: Text('Unsold')),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _statusFilter = value);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _readinessFilter,
                      decoration:
                          const InputDecoration(labelText: 'Readiness'),
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
                        if (value == null) return;
                        setState(() => _readinessFilter = value);
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: GlassContainer(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Year PnL:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      totalPnLText,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: totalPnL >= 0 ? Colors.green[700] : Colors.red[700],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _loadingCars
                  ? const Center(child: CircularProgressIndicator())
                  : visibleCars.isEmpty
                      ? const Center(child: Text('No cars for this year yet.'))
                      : GlassContainer(
                          padding: const EdgeInsets.all(0),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SizedBox(
                              width: 900,
                              child: DataTable(
                                showCheckboxColumn: false,
                                columnSpacing: 20,
                                columns: const [
                                  DataColumn(label: Text('Car')),
                                  DataColumn(label: Text('VIN')),
                                  DataColumn(label: Text('Readiness')),
                                  DataColumn(label: Text('Status')),
                                  DataColumn(label: Text('Selling Price')),
                                  DataColumn(label: Text('Paid Cost')),
                                  DataColumn(label: Text('Unpaid Cost')),
                                  DataColumn(label: Text('Total Cost')),
                                  DataColumn(label: Text('PnL')),
                                  DataColumn(label: Text('Details')),
                                ],
                                rows: visibleCars.map((row) {
                                  final model = row['model'] as String? ?? '';
                                  final vin = row['vin'] as String? ?? '';
                                  final readiness =
                                      row['readiness'] as String? ?? '';
                                  final status = row['status'] as String? ?? '';
                                  final sellingPrice =
                                      (row['selling_price'] as num?)?.toDouble();
                                  final paidAmount =
                                      (row['paid_amount'] as double?) ?? 0;
                                  final unpaidAmount =
                                      (row['unpaid_amount'] as double?) ?? 0;
                                  final totalCost =
                                      (row['total_cost'] as double?) ?? 0;
                                  final carPnL =
                                      (sellingPrice ?? 0) - totalCost;
                                  return DataRow(
                                    onSelectChanged: (selected) {
                                      if (selected == true) {
                                        _openCarDetail(row);
                                      }
                                    },
                                    cells: [
                                      DataCell(
                                        FittedBox(
                                          fit: BoxFit.scaleDown,
                                          alignment: Alignment.centerLeft,
                                          child: Text(model),
                                        ),
                                      ),
                                      DataCell(
                                        FittedBox(
                                          fit: BoxFit.scaleDown,
                                          alignment: Alignment.centerLeft,
                                          child: Text(vin),
                                        ),
                                      ),
                                      DataCell(
                                        readiness.isEmpty
                                            ? const SizedBox.shrink()
                                            : Align(
                                                alignment:
                                                    Alignment.centerLeft,
                                                child: FittedBox(
                                                  fit: BoxFit.scaleDown,
                                                  child: Chip(
                                                    label: Text(
                                                      readiness,
                                                      style: const TextStyle(
                                                        fontSize: 11,
                                                      ),
                                                    ),
                                                    visualDensity:
                                                        VisualDensity.compact,
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      horizontal: 4,
                                                    ),
                                                    materialTapTargetSize:
                                                        MaterialTapTargetSize
                                                            .shrinkWrap,
                                                  ),
                                                ),
                                              ),
                                      ),
                                      DataCell(
                                        status.isEmpty
                                            ? const SizedBox.shrink()
                                            : Align(
                                                alignment:
                                                    Alignment.centerLeft,
                                                child: FittedBox(
                                                  fit: BoxFit.scaleDown,
                                                  child: Chip(
                                                    label: Text(
                                                      status,
                                                      style: const TextStyle(
                                                        fontSize: 11,
                                                      ),
                                                    ),
                                                    visualDensity:
                                                        VisualDensity.compact,
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      horizontal: 4,
                                                    ),
                                                    materialTapTargetSize:
                                                        MaterialTapTargetSize
                                                            .shrinkWrap,
                                                    color:
                                                        MaterialStateProperty
                                                            .resolveWith(
                                                      (states) {
                                                        if (status
                                                            .toLowerCase()
                                                            .contains('sold')) {
                                                          return Colors.green
                                                              .withOpacity(
                                                                  0.15);
                                                        }
                                                        return Colors.blueGrey
                                                            .withOpacity(0.12);
                                                      },
                                                    ),
                                                  ),
                                                ),
                                              ),
                                      ),
                                      DataCell(
                                        FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            sellingPrice
                                                    ?.toStringAsFixed(2) ??
                                                '-',
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            paidAmount.toStringAsFixed(2),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            unpaidAmount.toStringAsFixed(2),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            totalCost.toStringAsFixed(2),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            carPnL >= 0
                                                ? '+${carPnL.toStringAsFixed(2)}'
                                                : carPnL.toStringAsFixed(2),
                                            style: TextStyle(
                                              color: carPnL >= 0
                                                  ? Colors.green[700]
                                                  : Colors.red[700],
                                            ),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              TextButton(
                                                onPressed: () =>
                                                    _openCarDetail(row),
                                                child: const Text('Go To'),
                                              ),
                                            ],
                                          ),
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

