import 'dart:async';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/services/app_settings_service.dart';
import '../../../shared/widgets/widgets.dart';

/// Lightweight HTML-based user guide.
///
/// Each guide has its own HTML file and shares one stylesheet and script.
/// Flutter supplies the saved accent colour and owns app-level navigation.
class HowToUseScreen extends StatefulWidget {
  const HowToUseScreen({super.key});

  @override
  State<HowToUseScreen> createState() => _HowToUseScreenState();
}

class _HowToUseScreenState extends State<HowToUseScreen> {
  static const String _assetPath =
      'assets/html/howtouse/how_to_use.html';

  final AppSettingsService _settings = AppSettingsService.instance;
  late final WebViewController _controller;

  bool _isLoading = true;
  bool _hasLoadedPage = false;
  bool _isShowingGuide = false;
  bool _pageReady = false;
  bool _isClosing = false;
  String? _errorMessage;
  int? _appliedAccentValue;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..addJavaScriptChannel(
        'GuideNavigation',
        onMessageReceived: _handleGuideMessage,
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (!mounted || _isClosing) return;
            setState(() {
              _isLoading = !_hasLoadedPage;
              _pageReady = false;
              _errorMessage = null;
            });
          },
          onPageFinished: (_) => unawaited(_finishPageLoad()),
          onWebResourceError: (error) {
            if (!mounted || _isClosing || error.isForMainFrame != true) return;
            setState(() {
              _isLoading = false;
              _errorMessage = 'Unable to display the user guide.';
            });
          },
        ),
      );

    _settings.addListener(_handleSettingsChanged);
    unawaited(_initialise());
  }

  Future<void> _initialise() async {
    await _settings.ensureThemeSettingsLoaded();
    if (!mounted || _isClosing) return;

    await _controller.loadFlutterAsset(_assetPath);
  }

  Future<void> _finishPageLoad() async {
    if (!mounted || _isClosing) return;

    _pageReady = true;
    await _applyAccentColor(force: true);
    if (!mounted || _isClosing) return;

    setState(() {
      _hasLoadedPage = true;
      _isLoading = false;
    });
  }

  void _handleGuideMessage(JavaScriptMessage message) {
    if (!mounted || _isClosing) return;

    final showingGuide = message.message == 'detail';
    if (_isShowingGuide == showingGuide) return;

    setState(() => _isShowingGuide = showingGuide);
  }

  void _handleSettingsChanged() {
    if (!_pageReady || _isClosing) return;
    unawaited(_applyAccentColor());
  }

  Future<void> _applyAccentColor({bool force = false}) async {
    final accent = _settings.accentColor;
    final accentValue = accent.toARGB32();
    if (!force && _appliedAccentValue == accentValue) return;

    _appliedAccentValue = accentValue;
    final darkAccent = _darken(accent);

    await _controller.runJavaScript('''
      document.documentElement.style.setProperty(
        '--app-color',
        '${_cssHex(accent)}'
      );
      document.documentElement.style.setProperty(
        '--app-color-dark',
        '${_cssHex(darkAccent)}'
      );
    ''');
  }

  Color _darken(Color color) {
    final hsl = HSLColor.fromColor(color);
    final lightness = (hsl.lightness - 0.16).clamp(0.0, 1.0).toDouble();
    return hsl.withLightness(lightness).toColor();
  }

  String _cssHex(Color color) {
    final rgb = color.toARGB32() & 0x00FFFFFF;
    return '#${rgb.toRadixString(16).padLeft(6, '0')}';
  }

  Future<void> _handleBack() async {
    if (_isClosing) return;

    if (_isShowingGuide && _pageReady) {
      if (await _controller.canGoBack()) {
        await _controller.goBack();
      } else {
        await _controller.loadFlutterAsset(_assetPath);
      }
      return;
    }

    if (!mounted) return;

    // Prevent PopScope -> maybePop -> PopScope recursion and detach the
    // Android platform view before closing the Flutter route.
    setState(() {
      _isClosing = true;
      _pageReady = false;
      _isLoading = false;
    });

    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;

    Navigator.of(context).pop();
  }

  Future<void> _retry() async {
    setState(() {
      _isLoading = true;
      _hasLoadedPage = false;
      _errorMessage = null;
    });
    await _controller.loadFlutterAsset(_assetPath);
  }

  @override
  void dispose() {
    _settings.removeListener(_handleSettingsChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final errorMessage = _errorMessage;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) unawaited(_handleBack());
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppTopBar(
          title: 'How to Use',
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          onBack: _handleBack,
        ),
        body: SafeArea(
          top: false,
          child: Stack(
            fit: StackFit.expand,
            children: [
              const ColoredBox(color: Colors.white),
              if (!_isClosing && errorMessage == null)
                WebViewWidget(controller: _controller),
              if (!_isClosing && errorMessage != null)
                _GuideError(
                  message: errorMessage,
                  onRetry: _retry,
                ),
              if (!_isClosing && _isLoading && errorMessage == null)
                ColoredBox(
                  color: Colors.white,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: _settings.accentColor,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GuideError extends StatelessWidget {
  const _GuideError({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.menu_book_outlined,
                size: 44,
                color: Colors.black54,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: onRetry,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.black,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
