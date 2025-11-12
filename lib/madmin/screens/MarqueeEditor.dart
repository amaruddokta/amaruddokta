import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MarqueeEditor extends StatefulWidget {
  const MarqueeEditor({super.key});

  @override
  State<MarqueeEditor> createState() => _MarqueeEditorState();
}

class _MarqueeEditorState extends State<MarqueeEditor> {
  final TextEditingController _controller = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentText();
  }

  Future<void> _loadCurrentText() async {
    try {
      final response = await Supabase.instance.client
          .from('admin_notice')
          .select('admin_text')
          .eq('id', 1)
          .single();

      if (!mounted) return;

      if (response['admin_text'] != null) {
        _controller.text = response['admin_text'];
      } else {
        // যদি ডাটা না থাকে, নতুন তৈরি করুন
        await _createInitialData();
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to load marquee text: $error"),
          backgroundColor: Colors.orange,
        ),
      );
      debugPrint("Load error: $error");
    }
  }

  Future<void> _createInitialData() async {
    try {
      await Supabase.instance.client.from('admin_notice').insert({
        'id': 1,
        'admin_text': 'Welcome to our app!',
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String()
      });
    } catch (error) {
      debugPrint('Error creating initial data: $error');
    }
  }

  Future<void> _updateText() async {
    setState(() => _loading = true);
    try {
      await Supabase.instance.client.from('admin_notice').upsert({
        'id': 1,
        'admin_text': _controller.text,
        'updated_at': DateTime.now().toIso8601String()
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Marquee Text Updated Successfully"),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Error: $error"),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      debugPrint("Update error details: $error");
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(24),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "📝 Update Marquee Text",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue[800],
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _controller,
              maxLines: 3,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Enter marquee text here...",
                labelText: "Marquee Text",
                contentPadding: EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _updateText,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: _loading
                    ? SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : const Icon(Icons.save, size: 20),
                label: Text(
                  _loading ? "Updating..." : "Update Marquee Text",
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Note: Make sure RLS policies are enabled in Supabase",
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
