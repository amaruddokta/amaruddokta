import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:get/get.dart';

class CallNumberAdminScreen extends StatefulWidget {
  const CallNumberAdminScreen({super.key});

  @override
  State<CallNumberAdminScreen> createState() => _CallNumberAdminScreenState();
}

class _CallNumberAdminScreenState extends State<CallNumberAdminScreen> {
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
      title: docId == null ? 'Add Call Number' : 'Edit Call Number',
      content: TextField(
        controller: _numberController,
        keyboardType: TextInputType.phone,
        decoration: const InputDecoration(labelText: 'Phone Number'),
      ),
      textConfirm: 'Save',
      textCancel: 'Cancel',
      onConfirm: () async {
        if (_numberController.text.isNotEmpty) {
          if (docId == null) {
            await _supabase.from('adminNumbers').insert({
              'cnumbers': _numberController.text,
              'created_at': DateTime.now().toIso8601String(),
            });
          } else {
            await _supabase.from('adminNumbers').update({
              'cnumbers': _numberController.text,
              'updated_at': DateTime.now().toIso8601String(),
            }).eq('id', docId);
          }
          Get.back();
        } else {
          Get.snackbar('Error', 'Phone number cannot be empty');
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
        await _supabase.from('adminNumbers').delete().eq('id', docId);
        Get.back();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Call Numbers Admin'),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _supabase
            .from('adminNumbers')
            .stream(primaryKey: ['id']).order('created_at', ascending: false),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No call numbers found.'));
          }

          final numbers = snapshot.data!;

          return ListView.builder(
            itemCount: numbers.length,
            itemBuilder: (context, index) {
              final numberData = numbers[index];
              final number = numberData['cnumbers'] as String;
              final docId = numberData['id'] as String;
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
                            docId: docId, currentNumber: number),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _deleteNumber(docId),
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
