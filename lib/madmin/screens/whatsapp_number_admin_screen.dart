import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WhatsappNumberAdminScreen extends StatefulWidget {
  const WhatsappNumberAdminScreen({super.key});

  @override
  State<WhatsappNumberAdminScreen> createState() =>
      _WhatsappNumberAdminScreenState();
}

class _WhatsappNumberAdminScreenState extends State<WhatsappNumberAdminScreen> {
  final TextEditingController _numberController = TextEditingController();
  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  void dispose() {
    _numberController.dispose();
    super.dispose();
  }

  Future<void> _addOrUpdateNumber(
      {String? docId, String? currentNumber}) async {
    _numberController.text = currentNumber ?? '';
    await Get.defaultDialog(
      title: docId == null ? 'Add WhatsApp Number' : 'Edit WhatsApp Number',
      content: TextField(
        controller: _numberController,
        keyboardType: TextInputType.phone,
        decoration: const InputDecoration(labelText: 'WhatsApp Number'),
      ),
      textConfirm: 'Save',
      textCancel: 'Cancel',
      onConfirm: () async {
        if (_numberController.text.isNotEmpty) {
          if (docId == null) {
            await _supabase.from('whatsappNumbers').insert({
              'number': _numberController.text,
              'timestamp': DateTime.now().toIso8601String(),
            });
          } else {
            await _supabase.from('whatsappNumbers').update({
              'number': _numberController.text,
              'timestamp': DateTime.now().toIso8601String(),
            }).eq('id', docId);
          }
          Get.back();
        } else {
          Get.snackbar('Error', 'WhatsApp number cannot be empty');
        }
      },
    );
  }

  Future<void> _deleteNumber(String docId) async {
    await Get.defaultDialog(
      title: 'Delete Number',
      middleText: 'Are you sure you want to delete this number?',
      textConfirm: 'Delete',
      textCancel: 'Cancel',
      confirmTextColor: Colors.white,
      onConfirm: () async {
        await _supabase.from('whatsappNumbers').delete().eq('id', docId);
        Get.back();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WhatsApp Numbers Admin'),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _supabase
            .from('whatsappNumbers')
            .stream(primaryKey: ['id'])
            .order('timestamp', ascending: false)
            .execute()
            .map((data) => data as List<Map<String, dynamic>>),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No WhatsApp numbers found.'));
          }

          final numbers = snapshot.data!;

          return ListView.builder(
            itemCount: numbers.length,
            itemBuilder: (context, index) {
              final doc = numbers[index];
              final number = doc['number'] as String;
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  title: Text(number),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _addOrUpdateNumber(
                            docId: doc['id'] as String, currentNumber: number),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _deleteNumber(doc['id'] as String),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrUpdateNumber(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
