import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebViewScreen extends StatefulWidget {
  final String url;

  const WebViewScreen({super.key, required this.url});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController webViewController;
  var loadingPercentage = 0;
  bool hasInternetConnection = true;

  @override
  void initState() {
    super.initState();
    initializeWebView();
  }

  void initializeWebView() {
    webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onNavigationRequest: (NavigationRequest request) async {
          if (request.url.startsWith(widget.url)) {
            return NavigationDecision.navigate;
          } else {
            await launchExternalUrl(request.url);
            return NavigationDecision.prevent;
          }
        },
        onProgress: (progress) {
          if (mounted) {
            setState(() {
              loadingPercentage = progress;
            });
          }
        },
        onPageFinished: (url) {
          if (mounted) {
            setState(() {
              hasInternetConnection = true;
              loadingPercentage = 100;
            });
          }
        },
        onWebResourceError: (error) {
          if (error.errorType == WebResourceErrorType.hostLookup ||
              error.errorType == WebResourceErrorType.connect) { // اصلاح خطا
            if (mounted) {
              setState(() {
                hasInternetConnection = false;
                loadingPercentage = 0;
              });
            }
          }
        },
      ))
      ..loadRequest(Uri.parse(widget.url));
  }

  Future<void> retryConnection() async {
    if (mounted) {
      setState(() {
        loadingPercentage = 0;
        hasInternetConnection = true;
      });
    }
    webViewController.reload();
  }

  void goToPreviousPage(bool canGoBack) {
    if (canGoBack) {
      webViewController.goBack();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<bool>(
        future: webViewController.canGoBack(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final canWebViewGoBack = snapshot.data!;
          return PopScope(
            canPop: !canWebViewGoBack,
            onPopInvokedWithResult: (didPop, result) {
              if (!didPop) {
                goToPreviousPage(canWebViewGoBack);
              }
            },
            child: Scaffold(
              body: hasInternetConnection
                  ? RefreshIndicator(
                      onRefresh: retryConnection,
                      child: Stack(
                        children: [
                          WebViewWidget(controller: webViewController),
                          if (loadingPercentage > 0 && loadingPercentage < 100)
                            LinearProgressIndicator(
                              value: loadingPercentage / 100.0,
                              color: Theme.of(context).primaryColor,
                            ),
                        ],
                      ),
                    )
                  : showNetworkErrorScreen(),
            ),
          );
        },
      ),
    );
  }

  Widget showNetworkErrorScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.wifi_off,
            size: 100,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 20),
          const Text(
            'Could not load the page. Check your connection.',
            style: TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: retryConnection,
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Future<void> launchExternalUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to handle your request')),
      );
    }
  }
}