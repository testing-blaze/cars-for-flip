import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/entities.dart';
import '../services/repositories.dart';
import '../utils/pin_utils.dart';
import '../widgets/glass_container.dart';
import 'year_overview_page.dart';

class PinLockPage extends StatefulWidget {
  final String ownerName;

  const PinLockPage({super.key, required this.ownerName});

  @override
  State<PinLockPage> createState() => _PinLockPageState();
}

class _PinLockPageState extends State<PinLockPage> {
  final _profileRepo = ProfileRepository();
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  final _emailController = TextEditingController();
  final _resetEmailController = TextEditingController();

  Profile? _profile;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile =
        await _profileRepo.getOrCreateProfileByName(widget.ownerName);
    setState(() {
      _profile = profile;
      _loading = false;
    });
  }

  Future<void> _createPin() async {
    final pin = _pinController.text.trim();
    final confirm = _confirmPinController.text.trim();
    final email = _emailController.text.trim();

    if (!isValidPinFormat(pin) || pin != confirm || email.isEmpty) {
      setState(() {
        _error = 'Enter 4-digit PIN twice and a valid email.';
      });
      return;
    }

    final updated = await _profileRepo.updateProfileSecurity(
      profileId: _profile!.id,
      email: email,
      pinHash: hashPin(pin),
    );
    setState(() {
      _profile = updated;
      _error = null;
    });
    _goToOverview();
  }

  Future<void> _unlock() async {
    final pin = _pinController.text.trim();
    if (!isValidPinFormat(pin)) {
      setState(() => _error = 'PIN must be 4 digits.');
      return;
    }
    final expected = _profile!.pinHash;
    if (expected == null || expected.isEmpty) {
      setState(() => _error = 'No PIN set yet. Create a new one.');
      return;
    }
    if (hashPin(pin) != expected) {
      setState(() => _error = 'Incorrect PIN.');
      return;
    }
    setState(() => _error = null);
    _goToOverview();
  }

  Future<void> _showResetDialog() async {
    _resetEmailController.text = '';
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reset PIN'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter your registered email to reset your PIN.',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _resetEmailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final email = _resetEmailController.text.trim();
                if (email.isEmpty || email != (_profile?.email ?? '')) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text('Email does not match the one on this profile.'),
                    ),
                  );
                  return;
                }
                Navigator.of(context).pop();
                // Allow setting a new PIN after email verification.
                setState(() {
                  _profile = Profile(
                    id: _profile!.id,
                    name: _profile!.name,
                    email: _profile!.email,
                    pinHash: null,
                  );
                  _pinController.clear();
                  _confirmPinController.clear();
                  _error = 'Enter a new 4-digit PIN.';
                });
              },
              child: const Text('Verify'),
            ),
          ],
        );
      },
    );
  }

  void _goToOverview() {
    final profile = _profile;
    if (profile == null) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => YearOverviewPage(profile: profile),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    final hasPin = profile?.pinHash != null && profile!.pinHash!.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.ownerName),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: GlassContainer(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          hasPin
                              ? 'Enter your 4-digit PIN'
                              : 'Create a 4-digit PIN',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        if (!hasPin) ...[
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email (for PIN reset)',
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        TextField(
                          controller: _pinController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(4),
                          ],
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: '4-digit PIN',
                          ),
                        ),
                        if (!hasPin) ...[
                          const SizedBox(height: 12),
                          TextField(
                            controller: _confirmPinController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(4),
                            ],
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Confirm PIN',
                            ),
                          ),
                        ],
                        if (_error != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _error!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        FilledButton(
                          onPressed: hasPin ? _unlock : _createPin,
                          child: Text(hasPin ? 'Unlock' : 'Save PIN'),
                        ),
                        if (hasPin) ...[
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: _showResetDialog,
                            child: const Text('Forgot PIN?'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

