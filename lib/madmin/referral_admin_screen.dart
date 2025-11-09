import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'referral_settings_screen.dart';

class ReferralAdminScreen extends StatefulWidget {
  const ReferralAdminScreen({super.key});

  @override
  State<ReferralAdminScreen> createState() => _ReferralAdminScreenState();
}

class _ReferralAdminScreenState extends State<ReferralAdminScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Referral Information'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ReferralSettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: Supabase.instance.client
            .from("users")
            .stream(primaryKey: ["id"]).execute(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
                child: Text("Something went wrong: ${snapshot.error}"));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data!;

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final name = user["name"] ?? "No Name";
              final referCode = user["referCode"] ?? "N/A";
              final referBalance = (user["referBalance"] ?? 0.0).toDouble();
              final isReferralActive = user["isReferralActive"] ?? false;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text("Referral Code: $referCode"),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Text("Referral Balance: ৳"),
                          Expanded(
                            child: TextFormField(
                              initialValue: referBalance.toStringAsFixed(2),
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                              ),
                              onFieldSubmitted: (value) async {
                                final newBalance = double.tryParse(value);
                                if (newBalance != null) {
                                  await Supabase.instance.client
                                      .from("users")
                                      .update({"referBalance": newBalance}).eq(
                                          "id", user["id"]);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      SwitchListTile(
                        title: const Text("Referral Active"),
                        value: isReferralActive,
                        onChanged: (value) async {
                          await Supabase.instance.client.from("users").update(
                              {"isReferralActive": value}).eq("id", user["id"]);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
