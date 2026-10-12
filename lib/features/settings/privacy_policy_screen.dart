import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/services/app_settings_service.dart';
import '../../shared/widgets/widgets.dart';

/// Displays the locally bundled Privacy Policy.
///
/// The document itself always uses a white content background and black text.
/// Only the HTML hero/header uses the accent colour saved in Theme settings.
class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  static const String _assetPath = 'assets/html/privacy_policy.html';

  final AppSettingsService _settings = AppSettingsService.instance;

  late final WebViewController _controller;

  bool _isLoading = true;
  String? _errorMessage;
  int? _loadedAccentValue;
  int _loadRequest = 0;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.disabled)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: _handleNavigationRequest,
          onPageStarted: (_) {
            if (!mounted) return;
            setState(() => _isLoading = true);
          },
          onPageFinished: (_) {
            if (!mounted) return;
            setState(() => _isLoading = false);
          },
          onWebResourceError: (error) {
            if (!mounted || error.isForMainFrame == false) return;
            setState(() {
              _isLoading = false;
              _errorMessage = 'Unable to display the Privacy Policy.';
            });
          },
        ),
      );

    _settings.addListener(_handleSettingsChanged);
    unawaited(_initialise());
  }

  /// Keeps the bundled policy inside the WebView and hands every other link
  /// (mailto:, tel:, http/https) to the matching external app. Without this
  /// the WebView tries to open them itself, fails with an unknown-scheme
  /// error and the screen falls back to "Unable to display the Privacy
  /// Policy."
  NavigationDecision _handleNavigationRequest(NavigationRequest request) {
    final uri = _parseUri(request.url);
    if (uri == null) return NavigationDecision.prevent;

    if (_isBundledDocument(uri)) return NavigationDecision.navigate;

    unawaited(_openExternally(uri));
    return NavigationDecision.prevent;
  }

  /// Parses a link, adding `https://` to bare hosts such as
  /// `www.example.com` that would otherwise resolve as relative paths.
  Uri? _parseUri(String rawUrl) {
    final value = rawUrl.trim();
    if (value.isEmpty) return null;

    final uri = Uri.tryParse(value);
    if (uri == null) return null;
    if (uri.hasScheme) return uri;

    return Uri.tryParse('https://$value');
  }

  bool _isBundledDocument(Uri uri) {
    const internalSchemes = <String>{'about', 'data', 'file', 'blob'};
    return internalSchemes.contains(uri.scheme.toLowerCase());
  }

  Future<void> _openExternally(Uri uri) async {
    var opened = false;

    try {
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on Object {
      opened = false;
    }

    if (opened || !mounted) return;

    final message = uri.scheme.toLowerCase() == 'mailto'
        ? 'No email app found on this device.'
        : 'Unable to open the link.';

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _initialise() async {
    await _settings.ensureThemeSettingsLoaded();
    if (!mounted) return;
    await _loadPolicy(_settings.accentColor, force: true);
  }

  void _handleSettingsChanged() {
    if (!mounted) return;

    final accentValue = _settings.accentColor.toARGB32();
    if (_loadedAccentValue == accentValue) return;

    unawaited(_loadPolicy(_settings.accentColor));
  }

  Future<void> _loadPolicy(Color accentColor, {bool force = false}) async {
    final accentValue = accentColor.toARGB32();
    if (!force && _loadedAccentValue == accentValue) return;

    _loadedAccentValue = accentValue;
    final request = ++_loadRequest;

    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final source = await rootBundle.loadString(_assetPath);
      final darkAccent = _darken(accentColor);
      final html = source
          .replaceAll('{{APP_COLOR}}', _cssHex(accentColor))
          .replaceAll('{{APP_COLOR_DARK}}', _cssHex(darkAccent));

      if (!mounted || request != _loadRequest) return;
      await _controller.loadHtmlString(html);
    } catch (_) {
      if (!mounted || request != _loadRequest) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Unable to display the Privacy Policy.';
      });
    }
  }

  Color _darken(Color color) {
    final hsl = HSLColor.fromColor(color);
    final lightness = (hsl.lightness - 0.18).clamp(0.0, 1.0).toDouble();
    return hsl.withLightness(lightness).toColor();
  }

  String _cssHex(Color color) {
    final rgb = color.toARGB32() & 0x00FFFFFF;
    return '#${rgb.toRadixString(16).padLeft(6, '0')}';
  }

  @override
  void dispose() {
    _settings.removeListener(_handleSettingsChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const AppTopBar(
        title: 'Privacy Policy',
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SafeArea(
        top: false,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: Colors.white),
            if (_errorMessage == null)
              WebViewWidget(controller: _controller)
            else
              _PrivacyPolicyError(
                message: _errorMessage!,
                onRetry: () => _loadPolicy(
                  _settings.accentColor,
                  force: true,
                ),
              ),
            if (_isLoading && _errorMessage == null)
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
    );
  }
}

class _PrivacyPolicyError extends StatelessWidget {
  const _PrivacyPolicyError({
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
                Icons.privacy_tip_outlined,
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