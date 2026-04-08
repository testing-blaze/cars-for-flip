import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/entities.dart';
import '../services/repositories.dart';
import '../widgets/glass_container.dart';

class CarDetailPage extends StatefulWidget {
  final Profile profile;
  final ProfileYear profileYear;
  final Map<String, dynamic>? carRow;

  const CarDetailPage({
    super.key,
    required this.profile,
    required this.profileYear,
    this.carRow,
  });

  @override
  State<CarDetailPage> createState() => _CarDetailPageState();
}

class _CarDetailPageState extends State<CarDetailPage> {
  final _carRepo = CarRepository();
  final _costRepo = CarCostRepository();

  final _modelController = TextEditingController();
  final _vinController = TextEditingController();
  String _readinessValue = 'In progress';
  String _statusValue = 'Unsold';
  final _buyingPriceController = TextEditingController();
  final _mileageController = TextEditingController();
  DateTime? _purchaseDate;
  final _sellingPriceController = TextEditingController();

  final _costDescriptionController = TextEditingController();
  final _costAmountController = TextEditingController();
  DateTime _costDate = DateTime.now();
  String _costStatusValue = 'Unpaid';
  String? _editingCostId;

  Car? _car;
  List<CarCostItem> _items = [];
  bool _savingCar = false;
  bool _loadingItems = false;

  @override
  void initState() {
    super.initState();
    final row = widget.carRow;
    if (row != null) {
      _car = Car.fromJson(row);
      _modelController.text = _car!.model;
      _vinController.text = _car!.vin;
      _readinessValue =
          _car!.readiness == 'Complete' ? 'Complete' : 'In progress';
      _statusValue = _car!.status == 'Sold' ? 'Sold' : 'Unsold';
      _buyingPriceController.text =
          _car!.buyingPrice?.toStringAsFixed(2) ?? '';
      _mileageController.text = _car!.mileage?.toString() ?? '';
      _purchaseDate = _car!.purchaseDate;
      _sellingPriceController.text =
          _car!.sellingPrice?.toStringAsFixed(2) ?? '';
      _loadItems();
    }
  }

  Future<void> _loadItems() async {
    final car = _car;
    if (car == null) return;
    setState(() => _loadingItems = true);
    final items = await _costRepo.getCostItemsForCar(car.id);
    setState(() {
      _items = items;
      _loadingItems = false;
    });
  }

  Future<void> _saveCar() async {
    final model = _modelController.text.trim();
    final vin = _vinController.text.trim();
    if (model.isEmpty || vin.isEmpty) return;

    setState(() => _savingCar = true);
    final car = await _carRepo.createOrUpdateCar(
      id: _car?.id,
      profileYearId: widget.profileYear.id,
      model: model,
      vin: vin,
      readiness: _readinessValue,
      status: _statusValue,
      buyingPrice: double.tryParse(_buyingPriceController.text.trim()),
      mileage: int.tryParse(_mileageController.text.trim()),
      purchaseDate: _purchaseDate,
      sellingPrice: double.tryParse(_sellingPriceController.text.trim()),
    );
    setState(() {
      _car = car;
      _savingCar = false;
    });
    await _loadItems();
  }

  Future<void> _addCostItem() async {
    final car = _car;
    if (car == null) {
      await _saveCar();
      if (_car == null) return;
    }
    final amount = double.tryParse(_costAmountController.text.trim());
    if (amount == null) return;

    if (_editingCostId == null) {
      await _costRepo.addCostItem(
        carId: _car!.id,
        date: _costDate,
        status: _costStatusValue,
        description: _costDescriptionController.text.trim(),
        notes: '',
        amount: amount,
      );
    } else {
      await _costRepo.updateCostItem(
        id: _editingCostId!,
        date: _costDate,
        status: _costStatusValue,
        description: _costDescriptionController.text.trim(),
        amount: amount,
      );
    }

    _costDescriptionController.clear();
    _costAmountController.clear();
    setState(() {
      _costStatusValue = 'Unpaid';
      _costDate = DateTime.now();
      _editingCostId = null;
    });

    await _loadItems();
  }

  double get _totalCost =>
      (_car?.buyingPrice ?? 0) +
      _items.fold(0, (sum, i) => sum + i.amount.toDouble());

  double get _paidAmount => _items.fold<double>(0, (sum, i) {
        if (i.status.toLowerCase() == 'paid') return sum + i.amount;
        return sum;
      });

  double get _unpaidAmount => _items.fold<double>(0, (sum, i) {
        if (i.status.toLowerCase() != 'paid') return sum + i.amount;
        return sum;
      });

  Future<void> _pickPurchaseDate() async {
    final now = DateTime.now();
    final initial = _purchaseDate ?? DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 2),
    );
    if (picked == null) return;
    setState(() => _purchaseDate = picked);
  }

  Future<void> _deleteCostItem(String id) async {
    await _costRepo.deleteCostItem(id);
    await _loadItems();
  }

  void _startEditCostItem(CarCostItem item) {
    setState(() {
      _editingCostId = item.id;
      _costDate = item.date;
      _costDescriptionController.text = item.description;
      _costAmountController.text = item.amount.toStringAsFixed(2);
      _costStatusValue = item.status.isEmpty ? 'Unpaid' : item.status;
    });
  }

  Future<void> _pickCostDate() async {
    final now = DateTime.now();
    final initial = DateTime(_costDate.year, _costDate.month, _costDate.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 2),
    );
    if (picked == null) return;
    setState(() => _costDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MM/dd');
    final purchaseDateLabel = _purchaseDate == null
        ? 'Select purchase date'
        : DateFormat('MMM d, yyyy').format(_purchaseDate!);
    final title = _car?.model.isNotEmpty == true
        ? _car!.model
        : 'New car for ${widget.profileYear.year}';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Container(
        color: Colors.transparent,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.profile.name,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text('Year ${widget.profileYear.year}'),
              const SizedBox(height: 16),
              GlassContainer(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _modelController,
                            decoration:
                                const InputDecoration(labelText: 'Car model'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _vinController,
                            decoration:
                                const InputDecoration(labelText: 'VIN'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _readinessValue,
                            decoration: const InputDecoration(
                              labelText: 'Readiness',
                            ),
                            items: const [
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
                              setState(() => _readinessValue = value);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _statusValue,
                            decoration: const InputDecoration(
                              labelText: 'Status',
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'Sold',
                                child: Text('Sold'),
                              ),
                              DropdownMenuItem(
                                value: 'Unsold',
                                child: Text('Unsold'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() => _statusValue = value);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _buyingPriceController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Buying price',
                              prefixText: '\$',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _mileageController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Mileage',
                              suffixText: 'mi',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton.icon(
                        onPressed: _pickPurchaseDate,
                        icon: const Icon(Icons.calendar_today_outlined),
                        label: Text(purchaseDateLabel),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _sellingPriceController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Selling price',
                        prefixText: '\$',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.icon(
                        onPressed: _savingCar ? null : _saveCar,
                        icon: _savingCar
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.save),
                        label: const Text('Save car'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Cost details',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Total: \$${_totalCost.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Paid: \$${_paidAmount.toStringAsFixed(2)}  |  Unpaid: \$${_unpaidAmount.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              GlassContainer(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _pickCostDate,
                            icon: const Icon(Icons.calendar_today_outlined),
                            label: Text(dateFormat.format(_costDate)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _costDescriptionController,
                            decoration:
                                const InputDecoration(labelText: 'Description'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _costAmountController,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Amount',
                              prefixText: '\$',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _costStatusValue,
                            decoration: const InputDecoration(
                              labelText: 'Status',
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'Paid',
                                child: Text('Paid'),
                              ),
                              DropdownMenuItem(
                                value: 'Unpaid',
                                child: Text('Unpaid'),
                              ),
                              DropdownMenuItem(
                                value: 'To Order',
                                child: Text('To Order'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() => _costStatusValue = value);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        FilledButton.icon(
                          onPressed: _addCostItem,
                          icon: Icon(_editingCostId == null
                              ? Icons.add
                              : Icons.save),
                          label: Text(
                              _editingCostId == null ? 'Add row' : 'Save row'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _loadingItems
                  ? const Center(child: CircularProgressIndicator())
                  : _items.isEmpty
                      ? const Text('No cost rows yet.')
                      : GlassContainer(
                          padding: const EdgeInsets.all(0),
                          child: DataTable(
                            columnSpacing: 16,
                            showCheckboxColumn: false,
                            columns: const [
                              DataColumn(label: Text('Date')),
                              DataColumn(label: Text('Description')),
                              DataColumn(label: Text('Amount')),
                              DataColumn(label: Text('Status')),
                              DataColumn(label: Text('')),
                            ],
                            rows: _items.map((item) {
                              return DataRow(
                                cells: [
                                  DataCell(
                                      Text(dateFormat.format(item.date)),
                                      onTap: () => _startEditCostItem(item)),
                                  DataCell(
                                    Text(item.description),
                                    onTap: () => _startEditCostItem(item),
                                  ),
                                  DataCell(
                                    Text(item.amount.toStringAsFixed(2)),
                                    onTap: () => _startEditCostItem(item),
                                  ),
                                  DataCell(
                                    Text(item.status),
                                    onTap: () => _startEditCostItem(item),
                                  ),
                                  DataCell(
                                    IconButton(
                                      tooltip: 'Delete row',
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        size: 18,
                                      ),
                                      onPressed: () =>
                                          _deleteCostItem(item.id),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
            ],
          ),
        ),
      ),
    );
  }
}

