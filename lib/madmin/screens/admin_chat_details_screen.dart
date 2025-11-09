import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminChatDetailsScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const AdminChatDetailsScreen(
      {super.key, required this.userId, required this.userName});

  @override
  State<AdminChatDetailsScreen> createState() => _AdminChatDetailsScreenState();
}

class _AdminChatDetailsScreenState extends State<AdminChatDetailsScreen> {
  final TextEditingController _messageController = TextEditingController();
  final SupabaseClient _supabase = Supabase.instance.client;

  void _sendMessage() async {
    if (_messageController.text.isNotEmpty) {
      await _supabase.from('messages').insert({
        'chat_id': widget.userId,
        'text': _messageController.text,
        'senderId': 'admin', // Or a specific admin ID
      });
      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat with ${widget.userName}'),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _supabase
                  .from('messages')
                  .stream(primaryKey: ['id'])
                  .eq('chat_id', widget.userId)
                  .order('timestamp', ascending: false),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
                final messages = snapshot.data!;
                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message['senderId'] == 'admin';
                    return ListTile(
                      title: Align(
                        alignment:
                            isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isMe ? Colors.green : Colors.grey[300],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            message['text'],
                            style: TextStyle(
                              color: isMe ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Enter your message...',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
