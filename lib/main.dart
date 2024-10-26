import 'package:flutter/material.dart';
import 'package:flutterwebapp/webview_screen.dart';

// Website to be loaded inside the app
const WEBSITE_URL = 'https://flutter.dev';

void main() {
  runApp(HomeScreen());
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: WebViewScreen(url: WEBSITE_URL),
    );
  }
}