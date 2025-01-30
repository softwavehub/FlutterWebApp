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
  final ScrollController scrollController = ScrollController();
  var loadingPercentage = 0;
  bool hasInternetConnection = true;

  @override
  void initState() {
    initializeWebView();
    super.initState();
  }

  void initializeWebView() {
    webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onNavigationRequest: (NavigationRequest request) async {
          // If URL is external, open it in a relevant app
          if (request.url.startsWith(widget.url)) {
            return NavigationDecision.navigate;
          } else {
            launchExternalUrl(request.url);
            return NavigationDecision.prevent;
          }
        },
        onProgress: (progress) {
          setState(() {
            loadingPercentage = progress;
          });
        },
        onWebResourceError: (error) {
          if (error.errorType != WebResourceErrorType.unknown) {
            setState(() {
              hasInternetConnection = false;
            });
          }
        },
      ))
      ..loadRequest(Uri.parse(widget.url));
  }

  Future<void> retryConnection() async {
    setState(() {
      loadingPercentage = 0;
      hasInternetConnection = true;
    });
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
      child: FutureBuilder(
        future: webViewController.canGoBack(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final canWebViewGoBack = snapshot.data as bool;
            return PopScope(
              canPop: !canWebViewGoBack,
              onPopInvokedWithResult: (didPop, result) {
                if (!didPop) {
                  goToPreviousPage(canWebViewGoBack);
                }
              },
              child: Scaffold(
                body: RefreshIndicator(
                  // Wrap with RefreshIndicator
                  onRefresh: refreshWebView,
                  // Call the refresh function
                  child: SingleChildScrollView(
                    controller: scrollController,
                    physics: AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height,
                      child: hasInternetConnection
                          ? Stack(
                              children: [
                                WebViewWidget(controller: webViewController),
                                if (loadingPercentage > 0 &&
                                    loadingPercentage < 100)
                                  LinearProgressIndicator(
                                    value: loadingPercentage / 100.0,
                                  ),
                              ],
                            )
                          : showNetworkErrorScreen(),
                    ),
                  ),
                ),
              ),
            );
          } else {
            return const Center(
                child: CircularProgressIndicator()); // Loading indicator
          }
        },
      ),
    );
  }

  // Returns a network error widget
  Widget showNetworkErrorScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off, size: 100, color: Colors.black),
          SizedBox(height: 20),
          Text(
            'Could not load the page.',
            style: TextStyle(fontSize: 18),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: retryConnection,
            child: Text('Try Again'),
          ),
        ],
      ),
    );
  }

  // Passes the received URL to be opened by another application
  Future<void> launchExternalUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } else {
      const snackBar = SnackBar(content: Text('Unable to handle your request'));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    }
  }

  Future<void> refreshWebView() async {
    setState(() {
      loadingPercentage = 0; // Reset loading percentage before reload
    });
    webViewController.reload();
  }
}
