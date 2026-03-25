import 'package:flutter/material.dart';

import '../models/nauman_calc_entry.dart';
import '../utils/nauman_calc_storage.dart';
import '../widgets/glass_container.dart';
import '../models/entities.dart';

class NaumanCalculatorPage extends StatefulWidget {
  final Profile profile;

  const NaumanCalculatorPage({super.key, required this.profile});

  @override
  State<NaumanCalculatorPage> createState() =>
      _NaumanCalculatorPageState();
}

class _NaumanCalculatorPageState extends State<NaumanCalculatorPage> {
  final _storage = NaumanCalcStorage();

  final _carNameController = TextEditingController();
  final _accidentsController = TextEditingController();
  final _carfaxController = TextEditingController();

  final _expectedSellingPriceController = TextEditingController();
  final _transportationController = TextEditingController();
  final _auctionFeeController = TextEditingController();
  final _dealershipDocController = TextEditingController();
  final _profitController = TextEditingController();

  final _repairFrontDoorShellPaintController = TextEditingController();
  final _repairFenderController = TextEditingController();
  final _repairFrontLightController = TextEditingController();
  final _repairBumperFixBayAreaController = TextEditingController();

  final _expectedSellingPriceFocus = FocusNode();

  List<NaumanCalcEntry> _saved = const [];
  bool _loadingSaved = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();

    // Default values so the page doesn't look empty.
    _accidentsController.text = '0';
    _carfaxController.text = '';

    for (final c in [
      _carNameController,
      _accidentsController,
      _carfaxController,
      _expectedSellingPriceController,
      _transportationController,
      _auctionFeeController,
      _dealershipDocController,
      _profitController,
      _repairFrontDoorShellPaintController,
      _repairFenderController,
      _repairFrontLightController,
      _repairBumperFixBayAreaController,
    ]) {
      c.addListener(_recalculate);
    }

    _loadSaved();
  }

  @override
  void dispose() {
    for (final c in [
      _carNameController,
      _accidentsController,
      _carfaxController,
      _expectedSellingPriceController,
      _transportationController,
      _auctionFeeController,
      _dealershipDocController,
      _profitController,
      _repairFrontDoorShellPaintController,
      _repairFenderController,
      _repairFrontLightController,
      _repairBumperFixBayAreaController,
    ]) {
      c.removeListener(_recalculate);
      c.dispose();
    }
    _expectedSellingPriceFocus.dispose();
    super.dispose();
  }

  void _recalculate() {
    // Trigger UI refresh for computed values.
    if (mounted) setState(() {});
  }

  Future<void> _loadSaved() async {
    setState(() => _loadingSaved = true);
    final entries = await _storage.loadEntries(widget.profile.id);
    setState(() {
      _saved = entries;
      _loadingSaved = false;
    });
  }

  static double _parseDouble(String raw) {
    final cleaned = raw.trim().replaceAll(',', '').replaceAll('\$', '');
    if (cleaned.isEmpty) return 0;
    return double.tryParse(cleaned) ?? 0;
  }

  static int _parseInt(String raw) {
    final cleaned = raw.trim().replaceAll(',', '');
    if (cleaned.isEmpty) return 0;
    return int.tryParse(cleaned) ?? 0;
  }

  double get _expectedSellingPrice =>
      _parseDouble(_expectedSellingPriceController.text);
  double get _transportation => _parseDouble(_transportationController.text);
  double get _auctionFee => _parseDouble(_auctionFeeController.text);
  double get _dealershipDoc => _parseDouble(_dealershipDocController.text);
  double get _profit => _parseDouble(_profitController.text);

  double get _repairFrontDoorShellPaint =>
      _parseDouble(_repairFrontDoorShellPaintController.text);
  double get _repairFender => _parseDouble(_repairFenderController.text);
  double get _repairFrontLight =>
      _parseDouble(_repairFrontLightController.text);
  double get _repairBumperFixBayArea =>
      _parseDouble(_repairBumperFixBayAreaController.text);

  double get _repairsTotal =>
      _repairFrontDoorShellPaint +
      _repairFender +
      _repairFrontLight +
      _repairBumperFixBayArea;

  double get _total => _transportation +
      _auctionFee +
      _dealershipDoc +
      _repairsTotal +
      _profit;

  double get _finalBiddingOffer => _expectedSellingPrice - _total;

  int get _accidents => _parseInt(_accidentsController.text);
  double get _carfax => _parseDouble(_carfaxController.text);

  Future<void> _save() async {
    if (_saving) return;

    final carName = _carNameController.text.trim();
    // Let users save even if name is empty (but keep it consistent for display).
    final entry = NaumanCalcEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      profileId: widget.profile.id,
      createdAt: DateTime.now(),
      carName: carName.isEmpty ? '(Untitled)' : carName,
      accidents: _accidents,
      carfax: _carfax,
      expectedSellingPrice: _expectedSellingPrice,
      transportation: _transportation,
      auctionFee: _auctionFee,
      dealershipDoc: _dealershipDoc,
      repairFrontDoorShellPaint: _repairFrontDoorShellPaint,
      repairFender: _repairFender,
      repairFrontLight: _repairFrontLight,
      repairBumperFixBayArea: _repairBumperFixBayArea,
      profit: _profit,
      repairsTotal: _repairsTotal,
      total: _total,
      finalBiddingOffer: _finalBiddingOffer,
    );

    setState(() => _saving = true);
    await _storage.saveEntry(widget.profile.id, entry);
    setState(() => _saving = false);
    await _loadSaved();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved to Nauman calculator list')),
      );
    }
  }

  Future<void> _deleteEntry(String entryId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete saved entry?'),
        content:
            const Text('This cannot be undone. Do you want to delete it?'),
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
    );
    if (confirmed != true) return;

    await _storage.deleteEntry(widget.profile.id, entryId);
    await _loadSaved();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Deleted')),
      );
    }
  }

  void _viewEntry(NaumanCalcEntry entry) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(entry.carName),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Expected Selling Price: \$${entry.expectedSellingPrice.toStringAsFixed(2)}'),
              Text('Transportation: \$${entry.transportation.toStringAsFixed(2)}'),
              Text('Auction Fee: \$${entry.auctionFee.toStringAsFixed(2)}'),
              Text('Dealership Doc: \$${entry.dealershipDoc.toStringAsFixed(2)}'),
              const SizedBox(height: 8),
              Text('Repairs / Readiness: \$${entry.repairsTotal.toStringAsFixed(2)}'),
              Text('  - Front Door shell+paint: \$${entry.repairFrontDoorShellPaint.toStringAsFixed(2)}'),
              Text('  - Fender: \$${entry.repairFender.toStringAsFixed(2)}'),
              Text('  - Front Light: \$${entry.repairFrontLight.toStringAsFixed(2)}'),
              Text('  - Bumper Fix + Bay Area: \$${entry.repairBumperFixBayArea.toStringAsFixed(2)}'),
              const SizedBox(height: 8),
              Text('Profit: \$${entry.profit.toStringAsFixed(2)}'),
              Text('Total (all costs + profit): \$${entry.total.toStringAsFixed(2)}'),
              const SizedBox(height: 8),
              Text('Final Bidding Offer: \$${entry.finalBiddingOffer.toStringAsFixed(2)}'),
              const SizedBox(height: 8),
              Text('Accidents: ${entry.accidents}'),
              Text('Carfax: \$${entry.carfax.toStringAsFixed(2)}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalColor = _finalBiddingOffer >= 0 ? Colors.green[700] : Colors.red[700];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nauman Calculator'),
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
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _carNameController,
                    decoration: const InputDecoration(
                      labelText: 'Car name',
                      hintText: 'e.g. Subaru Impreza 2013',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          focusNode: _expectedSellingPriceFocus,
                          controller: _expectedSellingPriceController,
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Expected Selling Price',
                            prefixText: '\$',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _profitController,
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Profit',
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
                        child: TextField(
                          controller: _transportationController,
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Transportation',
                            prefixText: '\$',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _auctionFeeController,
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Auction Fee',
                            prefixText: '\$',
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),
                  TextField(
                    controller: _dealershipDocController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Dealership Doc',
                      prefixText: '\$',
                    ),
                  ),

                  const SizedBox(height: 16),
                  Text(
                    'Repairs / Readiness',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _repairFrontDoorShellPaintController,
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Front Door shell+paint',
                            prefixText: '\$',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _repairFenderController,
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Fender',
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
                        child: TextField(
                          controller: _repairFrontLightController,
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Front Light',
                            prefixText: '\$',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _repairBumperFixBayAreaController,
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Bumper Fix + Bay Area',
                            prefixText: '\$',
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  Text(
                    'Repairs Total: \$${_repairsTotal.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),

                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _accidentsController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: false,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Accidents',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _carfaxController,
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Carfax',
                            prefixText: '\$',
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.blueGrey.withOpacity(0.08),
                      border: Border.all(
                        color: Colors.blueGrey.withOpacity(0.25),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total: \$${_total.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Final Bidding Offer: \$${_finalBiddingOffer.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: totalColor,
                              ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save),
                      label: const Text('Save'),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            Expanded(
              child: GlassContainer(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Saved entries (${_saved.length})',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        IconButton(
                          onPressed: _loadSaved,
                          icon: const Icon(Icons.refresh),
                          tooltip: 'Refresh saved',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_loadingSaved)
                      const Expanded(child: Center(child: CircularProgressIndicator()))
                    else if (_saved.isEmpty)
                      const Expanded(
                        child: Center(
                          child: Text(
                            'No saved entries yet.\nFill the calculator and press Save.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: ListView.separated(
                          itemCount: _saved.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1, color: Colors.white24),
                          itemBuilder: (context, index) {
                            final entry = _saved[index];
                            final created = TimeOfDay.fromDateTime(entry.createdAt)
                                .format(context);
                            return ListTile(
                              title: Text(entry.carName),
                              subtitle: Text(
                                  'Final: \$${entry.finalBiddingOffer.toStringAsFixed(2)} • ${entry.accidents} accidents • $created'),
                              trailing: Wrap(
                                spacing: 8,
                                children: [
                                  IconButton(
                                    tooltip: 'View',
                                    icon: const Icon(Icons.remove_red_eye_outlined),
                                    onPressed: () => _viewEntry(entry),
                                  ),
                                  IconButton(
                                    tooltip: 'Delete',
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () => _deleteEntry(entry.id),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

