import 'package:flutter/material.dart';

import '../models/entities.dart';
import '../services/repositories.dart';
import '../widgets/glass_container.dart';
import 'year_overview_page.dart';

class ProfileSelectionPage extends StatefulWidget {
  const ProfileSelectionPage({super.key});

  @override
  State<ProfileSelectionPage> createState() => _ProfileSelectionPageState();
}

class _ProfileSelectionPageState extends State<ProfileSelectionPage> {
  final _profileRepo = ProfileRepository();
  final _nameController = TextEditingController();
  late Future<List<Profile>> _profilesFuture;

  @override
  void initState() {
    super.initState();
    _profilesFuture = _profileRepo.getProfiles();
  }

  Future<void> _refresh() async {
    setState(() {
      _profilesFuture = _profileRepo.getProfiles();
    });
  }

  Future<void> _addProfile() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    await _profileRepo.createProfile(name);
    _nameController.clear();
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profiles'),
      ),
      body: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GlassContainer(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'New profile name',
                            hintText: 'e.g. Nauman',
                          ),
                          onSubmitted: (_) => _addProfile(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      FilledButton.icon(
                        onPressed: _addProfile,
                        icon: const Icon(Icons.add),
                        label: const Text('Save'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: GlassContainer(
                    child: FutureBuilder<List<Profile>>(
                      future: _profilesFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return Center(
                            child: Text('Error: ${snapshot.error}'),
                          );
                        }
                        final profiles = snapshot.data ?? [];
                        if (profiles.isEmpty) {
                          return const Center(
                            child: Text(
                              'No profiles yet.\nCreate your first business profile above.',
                              textAlign: TextAlign.center,
                            ),
                          );
                        }
                        return RefreshIndicator(
                          onRefresh: _refresh,
                          child: ListView.separated(
                            itemCount: profiles.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1, color: Colors.white24),
                            itemBuilder: (context, index) {
                              final profile = profiles[index];
                              return ListTile(
                                title: Text(
                                  profile.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: const Text(
                                  'Tap to manage years, cars and reports',
                                ),
                                trailing: const Icon(Icons.arrow_forward_ios),
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => YearOverviewPage(
                                        profile: profile,
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

