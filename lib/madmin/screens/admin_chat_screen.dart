import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:amar_uddokta/madmin/screens/admin_chat_details_screen.dart';

class AdminChatScreen extends StatelessWidget {
  const AdminChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Chats'),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream:
            Supabase.instance.client.from('chats').stream(primaryKey: ['id']),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final chatDocs = snapshot.data!;
          return ListView.builder(
            itemCount: chatDocs.length,
            itemBuilder: (context, index) {
              final chatDoc = chatDocs[index];
              final userName = chatDoc['userName'] ?? 'No Name';
              return ListTile(
                title: Text(userName),
                subtitle: Text('User ID: ${chatDoc['id']}'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AdminChatDetailsScreen(
                          userId: chatDoc['id'], userName: userName),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
