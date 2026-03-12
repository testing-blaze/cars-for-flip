import 'package:flutter/material.dart';

import '../widgets/glass_container.dart';
import 'pin_lock_page.dart';

class OwnerSelectionPage extends StatefulWidget {
  const OwnerSelectionPage({super.key});

  @override
  State<OwnerSelectionPage> createState() => _OwnerSelectionPageState();
}

class _OwnerSelectionPageState extends State<OwnerSelectionPage> {
  bool _loading = false;

  Future<void> _openForOwner(String ownerName) async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PinLockPage(ownerName: ownerName),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FlipTrack'),
      ),
      body: Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Who is using the app?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _openForOwner('Nauman'),
                      child: GlassContainer(
                        padding: const EdgeInsets.symmetric(
                          vertical: 28,
                          horizontal: 16,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.person_outline, size: 40),
                            SizedBox(height: 8),
                            Text(
                              'Nauman',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'View Nauman\'s inventory',
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _openForOwner('Waleed'),
                      child: GlassContainer(
                        padding: const EdgeInsets.symmetric(
                          vertical: 28,
                          horizontal: 16,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.person_outline, size: 40),
                            SizedBox(height: 8),
                            Text(
                              'Waleed',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'View Waleed\'s inventory',
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (_loading) ...[
                const SizedBox(height: 24),
                const CircularProgressIndicator(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

