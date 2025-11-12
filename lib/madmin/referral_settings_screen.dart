import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReferralSettingsScreen extends StatefulWidget {
  const ReferralSettingsScreen({super.key});

  @override
  State<ReferralSettingsScreen> createState() => _ReferralSettingsScreenState();
}

class _ReferralSettingsScreenState extends State<ReferralSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<Map<String, double>> _bonusTiers = [];
  bool _isLoading = true;
  bool _isReferralSystemEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadBonusTiers();
  }

  Future<void> _loadBonusTiers() async {
    try {
      final settingsSnapshot = await Supabase.instance.client
          .from('referral_settings')
          .select('isEnabled')
          .eq('id', 'status')
          .single();
      if (settingsSnapshot.containsKey("isEnabled")) {
        setState(() {
          _isReferralSystemEnabled = settingsSnapshot["isEnabled"];
        });
      }
    
      final snapshot = await Supabase.instance.client
          .from('referral_settings')
          .select('tiers')
          .eq('id', 'bonus_rules')
          .single();

      if (snapshot.containsKey('tiers') && snapshot['tiers'] is List) {
        final tiers = List<Map<String, dynamic>>.from(snapshot['tiers']);
        setState(() {
          _bonusTiers.clear();
          for (var tier in tiers) {
            _bonusTiers.add({
              'minAmount': (tier['minAmount'] as num).toDouble(),
              'maxAmount': (tier['maxAmount'] as num).toDouble(),
              'bonus': (tier['bonus'] as num).toDouble(),
            });
          }
        });
      }
        } catch (e) {
      // Handle error
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _addTier() {
    setState(() {
      _bonusTiers.add({'minAmount': 0, 'maxAmount': 0, 'bonus': 0});
    });
  }

  void _removeTier(int index) {
    setState(() {
      _bonusTiers.removeAt(index);
    });
  }

  Future<void> _saveSettings() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      await Supabase.instance.client
          .from('referral_settings')
          .upsert({'id': 'bonus_rules', 'tiers': _bonusTiers});

      await Supabase.instance.client
          .from('referral_settings')
          .upsert({'id': 'status', 'isEnabled': _isReferralSystemEnabled});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Referral Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveSettings,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  SwitchListTile(
                    title: const Text('Enable Referral System'),
                    value: _isReferralSystemEnabled,
                    onChanged: (bool value) {
                      setState(() {
                        _isReferralSystemEnabled = value;
                      });
                    },
                  ),
                  const Divider(),
                  ..._bonusTiers.asMap().entries.map((entry) {
                    int index = entry.key;
                    Map<String, double> tier = entry.value;
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            TextFormField(
                              initialValue: tier['minAmount']?.toString(),
                              decoration: const InputDecoration(
                                  labelText: 'Minimum Order Amount'),
                              keyboardType: TextInputType.number,
                              onSaved: (value) {
                                _bonusTiers[index]['minAmount'] =
                                    double.tryParse(value ?? '0') ?? 0;
                              },
                            ),
                            TextFormField(
                              initialValue: tier['maxAmount']?.toString(),
                              decoration: const InputDecoration(
                                  labelText: 'Maximum Order Amount'),
                              keyboardType: TextInputType.number,
                              onSaved: (value) {
                                _bonusTiers[index]['maxAmount'] =
                                    double.tryParse(value ?? '0') ?? 0;
                              },
                            ),
                            TextFormField(
                              initialValue: tier['bonus']?.toString(),
                              decoration: const InputDecoration(
                                  labelText: 'Bonus Amount'),
                              keyboardType: TextInputType.number,
                              onSaved: (value) {
                                _bonusTiers[index]['bonus'] =
                                    double.tryParse(value ?? '0') ?? 0;
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _removeTier(index),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _addTier,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Tier'),
                  ),
                ],
              ),
            ),
    );
  }
}
