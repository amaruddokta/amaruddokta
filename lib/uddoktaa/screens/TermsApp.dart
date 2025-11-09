import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class TermsApp extends StatelessWidget {
  const TermsApp({super.key});

  Future<void> _launchURL(String url, BuildContext context) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not launch $url'),
        ),
      );
    }
  }

  TextSpan _buildTextSpans(String text, BuildContext context) {
    final RegExp urlRegex = RegExp(
      r'https?://(?:www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b(?:[-a-zA-Z0-9()@:%_\+.~#?&//=]*)',
    );

    final List<TextSpan> spans = [];
    int start = 0;

    for (final Match match in urlRegex.allMatches(text)) {
      if (match.start > start) {
        spans.add(
          TextSpan(
            text: text.substring(start, match.start),
          ),
        );
      }

      final String url = match.group(0)!;
      spans.add(
        TextSpan(
          text: url,
          style: const TextStyle(
            color: Colors.blue,
            decoration: TextDecoration.underline,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () => _launchURL(url, context),
        ),
      );

      start = match.end;
    }

    if (start < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(start),
        ),
      );
    }

    return TextSpan(children: spans);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy and Terms'),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: Supabase.instance.client
            .from('terms')
            .stream(primaryKey: ['id']).order('order'),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No terms and conditions found.'));
          }

          final terms = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: terms.length,
            itemBuilder: (context, index) {
              final term = terms[index];
              final text = term['text'] as String;
              final isHeader = term.containsKey('isHeader')
                  ? term['isHeader'] as bool
                  : false;

              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: isHeader ? 20 : 16,
                      fontWeight:
                          isHeader ? FontWeight.bold : FontWeight.normal,
                      color: Colors.black,
                    ),
                    children: [
                      _buildTextSpans(text, context),
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
