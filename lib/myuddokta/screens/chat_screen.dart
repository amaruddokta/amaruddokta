import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:amar_uddokta/myuddokta/widgets/background_container.dart'; // Your custom widget

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final SupabaseClient _supabase = Supabase.instance.client;

  // IMPORTANT: Replace with the actual logged-in user's ID
  late final String _userId;
  late final Stream<List<Map<String, dynamic>>> _messagesStream;
  bool _isAdminOnline = false;

  @override
  void initState() {
    super.initState();
    // In a real app, get the user ID from authentication
    // For example: _userId = Supabase.instance.client.auth.currentUser!.id;
    _userId = 'user_${DateTime.now().millisecondsSinceEpoch}'; // Placeholder
    _initializeChat();
    _checkAdminStatus();
  }

  void _initializeChat() async {
    // Check if a chat session exists for this user, if not, create one.
    final existingChat =
        await _supabase.from('chats').select().eq('id', _userId).maybeSingle();

    if (existingChat == null) {
      await _supabase.from('chats').insert({
        'id': _userId,
        'userName': 'Customer Name', // Replace with actual user name
        'last_message': 'Chat started',
        'last_message_time': DateTime.now().toIso8601String(),
        'is_unread_for_admin': false,
      });
    }

    // Set up the stream for messages
    setState(() {
      _messagesStream = _supabase
          .from('messages')
          .stream(primaryKey: ['id'])
          .eq('chat_id', _userId)
          .order('timestamp', ascending: false);
    });
  }

  void _checkAdminStatus() {
    // This is a placeholder. You need a way to track admin online status.
    // For simplicity, we'll assume admin is always online.
    // You can create a separate 'admin_status' table for real-time updates.
    setState(() {
      _isAdminOnline = true;
    });
  }

  void _sendMessage() async {
    if (_controller.text.trim().isEmpty) return;
    final text = _controller.text.trim();
    _controller.clear();

    // Insert message
    await _supabase.from('messages').insert({
      'chat_id': _userId,
      'text': text,
      'senderId': 'user',
      'timestamp': DateTime.now().toIso8601String(),
    });

    // Update chat list for admin
    await _supabase.from('chats').update({
      'last_message': text,
      'last_message_time': DateTime.now().toIso8601String(),
      'is_unread_for_admin': true, // Mark as unread for admin
    }).eq('id', _userId);

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.minScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundContainer(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.support_agent,
                    color: Theme.of(context).primaryColor),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Support',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                  Text(
                    _isAdminOnline ? 'Online' : 'Offline',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _messagesStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                        child: Text("No messages yet. Start a conversation!"));
                  }

                  final messages = snapshot.data!;
                  _scrollToBottom();

                  return ListView.builder(
                    reverse: true,
                    controller: _scrollController,
                    padding: const EdgeInsets.all(8.0),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isMe = message['senderId'] == 'user';
                      return _buildMessageBubble(
                          message['text'], isMe, message['timestamp']);
                    },
                  );
                },
              ),
            ),
            _buildMessageComposer(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(String text, bool isMe, dynamic timestamp) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? Colors.deepPurple[100] : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: isMe
                      ? const Radius.circular(18)
                      : const Radius.circular(0),
                  bottomRight: isMe
                      ? const Radius.circular(0)
                      : const Radius.circular(18),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    style: TextStyle(color: isMe ? Colors.black : Colors.black),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatMessageTime(timestamp),
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageComposer() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: Theme.of(context).primaryColor,
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  String _formatMessageTime(dynamic timestamp) {
    if (timestamp == null) return '';
    final dateTime = DateTime.parse(timestamp);
    return DateFormat('h:mm a').format(dateTime);
  }
}
