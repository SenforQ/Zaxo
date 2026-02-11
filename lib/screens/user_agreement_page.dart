import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../constants/app_ui.dart';

const String _userAgreementUrl =
    'https://www.privacypolicies.com/live/277a2365-4b6a-46a5-94be-4b54f7b75c2c';

class UserAgreementPage extends StatefulWidget {
  const UserAgreementPage({super.key});

  @override
  State<UserAgreementPage> createState() => _UserAgreementPageState();
}

class _UserAgreementPageState extends State<UserAgreementPage> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(_userAgreementUrl));
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final topPadding = MediaQuery.paddingOf(context).top;
    final appBarHeight = kToolbarHeight;
    final webViewHeight = size.height - topPadding - appBarHeight;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('User Agreement', style: TextStyle(color: Colors.white)),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: kHomeBackgroundGradient,
            ),
          ),
          Positioned(
            left: 0,
            top: topPadding + appBarHeight,
            width: size.width,
            height: webViewHeight,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              child: WebViewWidget(controller: _controller),
            ),
          ),
        ],
      ),
    );
  }
}
