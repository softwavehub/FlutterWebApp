import 'package:flutter/material.dart';
import 'package:flutterwebapp/webview_screen.dart';

// Website to be loaded inside the app
const websiteUrl = 'https://flutter.dev';

void main() {
  runApp(const HomeScreen());
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: WebViewScreen(url: websiteUrl),
    );
  }
}