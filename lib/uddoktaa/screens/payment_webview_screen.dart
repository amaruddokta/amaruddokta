import 'package:amar_uddokta/uddoktaa/widgets/background_container.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PaymentWebViewScreen extends StatefulWidget {
  final String paymentUrl; // বিকাশ/নগদ পেমেন্ট URL

  const PaymentWebViewScreen({super.key, required this.paymentUrl});

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  late final WebViewController _controller;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            setState(() {
              isLoading = true;
            });
          },
          onPageFinished: (_) {
            setState(() {
              isLoading = false;
            });
          },
          onNavigationRequest: (NavigationRequest request) {
            // ✅ Redirect success URL check
            if (request.url.contains("success") ||
                request.url.contains("payment_success")) {
              Navigator.pop(context, true); // Go back with success
              return NavigationDecision.prevent;
            }
            if (request.url.contains("cancel") ||
                request.url.contains("fail")) {
              Navigator.pop(context, false); // Go back with failure
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundContainer(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text("Bkash Payment"),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (isLoading)
              const Center(
                child: CircularProgressIndicator(color: Colors.pink),
              ),
          ],
        ),
      ),
    );
  }
}
