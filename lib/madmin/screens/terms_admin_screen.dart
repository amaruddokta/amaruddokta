import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TermsAdminScreen extends StatefulWidget {
  const TermsAdminScreen({super.key});

  @override
  State<TermsAdminScreen> createState() => _TermsAdminScreenState();
}

class _TermsAdminScreenState extends State<TermsAdminScreen> {
  final _formKey = GlobalKey<FormState>();
  final _textController = TextEditingController();
  bool _isHeader = false;
  final _supabase = Supabase.instance.client;

  Future<void> _addOrUpdateTerm({int? id}) async {
    if (_formKey.currentState!.validate()) {
      final data = {
        'text': _textController.text,
        'isHeader': _isHeader,
        'createdAt': DateTime.now().toIso8601String(),
      };
      if (id == null) {
        final response = await _supabase
            .from('terms')
            .select('order')
            .order('order', ascending: false)
            .limit(1)
            .single();
        final maxOrder = (response['order'] ?? -1) as int;
        data['order'] = maxOrder + 1;
        await _supabase.from('terms').insert(data);
      } else {
        await _supabase.from('terms').update(data).eq('id', id);
      }
      _textController.clear();
      setState(() {
        _isHeader = false;
      });
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  void _showTermDialog({Map<String, dynamic>? term}) {
    if (term != null) {
      _textController.text = term['text'];
      _isHeader = term['isHeader'] ?? false;
    } else {
      _textController.clear();
      _isHeader = false;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(term == null ? 'Add Term' : 'Edit Term'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _textController,
                  decoration: const InputDecoration(labelText: 'Text'),
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter some text' : null,
                  maxLines: 5,
                ),
                StatefulBuilder(
                  builder: (context, setDialogState) => CheckboxListTile(
                    title: const Text('Is Header'),
                    value: _isHeader,
                    onChanged: (value) {
                      setDialogState(() {
                        _isHeader = value!;
                      });
                      setState(() {});
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _addOrUpdateTerm(id: term?['id']),
            child: Text(term == null ? 'Add' : 'Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _seedData() async {
    final response = await _supabase.from('terms').select().limit(1);
    if (response.isNotEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Terms already exist.')));
      }
      return;
    }

    final initialTerms = [
      {
        'text': 'Terms and Conditions',
        'isHeader': true,
      },
      {
        'text': 'Welcome to Amar Dokane!',
        'isHeader': false,
      },
      {
        'text':
            'These terms and conditions outline the rules and regulations for the use of Amar Dokane\'s Website, located at amardokane.com.',
        'isHeader': false,
      },
      {
        'text':
            'By accessing this website we assume you accept these terms and conditions. Do not continue to use Amar Dokane if you do not agree to take all of the terms and conditions stated on this page.',
        'isHeader': false,
      },
      {'text': 'Cookies', 'isHeader': true},
      {
        'text':
            'We employ the use of cookies. By accessing Amar Dokane, you agreed to use cookies in agreement with the Amar Dokane\'s Privacy Policy.',
        'isHeader': false,
      },
    ];

    for (int i = 0; i < initialTerms.length; i++) {
      final term = initialTerms[i];
      await _supabase.from('terms').insert({
        ...term,
        'createdAt': DateTime.now().toIso8601String(),
        'order': i,
      });
    }

    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Seeded initial terms.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Terms'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showTermDialog(),
          ),
          IconButton(
            icon: const Icon(Icons.eco),
            onPressed: _seedData,
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream:
            _supabase.from('terms').stream(primaryKey: ['id']).order('order'),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No terms found. Add one!'));
          }

          var terms = snapshot.data!;

          return ReorderableListView.builder(
            itemCount: terms.length,
            itemBuilder: (context, index) {
              final term = terms[index];
              return ListTile(
                key: ValueKey(term['id']),
                title: Text(
                  term['text'],
                  style: TextStyle(
                      fontWeight: term.containsKey('isHeader')
                          ? term['isHeader']
                              ? FontWeight.bold
                              : FontWeight.normal
                          : FontWeight.normal),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _showTermDialog(term: term),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () async {
                        final bool? confirmDelete = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Confirm Delete'),
                            content: const Text(
                                'Are you sure you want to delete this term?'),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );

                        if (confirmDelete == true) {
                          await _supabase
                              .from('terms')
                              .delete()
                              .eq('id', term['id']);
                        }
                      },
                    ),
                  ],
                ),
              );
            },
            onReorder: (oldIndex, newIndex) async {
              if (oldIndex < newIndex) {
                newIndex -= 1;
              }

              final movedTerm = terms.removeAt(oldIndex);
              terms.insert(newIndex, movedTerm);

              for (int i = 0; i < terms.length; i++) {
                await _supabase
                    .from('terms')
                    .update({'order': i}).eq('id', terms[i]['id']);
              }
            },
          );
        },
      ),
    );
  }
}
