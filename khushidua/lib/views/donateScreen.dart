import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../constants/colors.dart';
import '../constants/donation.dart';
import '../constants/theme.dart';
import '../widgets/customSnackbar.dart';

/// The LearningSouls donation page, inside the app.
///
/// When the page cannot load — no network, a DNS failure, a server error —
/// the reader gets the link itself and a button that hands it to the phone's
/// own browser, so a donation is never blocked by the in-app view.
class DonateScreen extends StatefulWidget {
  const DonateScreen({super.key});

  @override
  State<DonateScreen> createState() => _DonateScreenState();
}

class _DonateScreenState extends State<DonateScreen> {
  late final WebViewController _web;
  int _progress = 0;
  bool _failed = false;

  /// The page being loaded, so an HTTP error for it can be told apart from
  /// one for an image or script on it.
  String? _pageUrl;

  @override
  void initState() {
    super.initState();
    _web = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppSurface.page)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (p) {
            if (mounted) setState(() => _progress = p);
          },
          onPageStarted: (url) {
            _pageUrl = url;
            if (mounted) setState(() => _progress = 0);
          },
          onWebResourceError: (error) {
            // Sub-resources (an ad pixel, a font) fail all the time without
            // breaking the page; only a failed page itself is an error.
            if (error.isForMainFrame ?? true) _showFallback();
          },
          onHttpError: (error) {
            final status = error.response?.statusCode ?? 0;
            final url = error.request?.uri.toString();
            if (status >= 400 && (url == null || url == _pageUrl)) {
              _showFallback();
            }
          },
          onNavigationRequest: (request) {
            // Payment apps and mail links cannot open inside a web view.
            final uri = Uri.tryParse(request.url);
            if (uri != null &&
                !uri.isScheme('http') &&
                !uri.isScheme('https')) {
              launchUrl(uri, mode: LaunchMode.externalApplication);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(kDonationUrl));
  }

  void _showFallback() {
    if (mounted && !_failed) setState(() => _failed = true);
  }

  void _retry() {
    setState(() {
      _failed = false;
      _progress = 0;
    });
    _web.loadRequest(Uri.parse(kDonationUrl));
  }

  Future<void> _openInBrowser() async {
    final opened = await launchUrl(
      Uri.parse(kDonationUrl),
      mode: LaunchMode.externalApplication,
    );
    if (!opened) {
      CustomSnackbar.show(
        "Error".tr,
        "Could not open the browser. Copy the link instead.".tr,
        isSuccess: false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Back steps through the donation site's own pages before leaving.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (!_failed && await _web.canGoBack()) {
          await _web.goBack();
        } else if (context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppSurface.page,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: rbluedark),
          title: Text(
            "Support LearningSouls".tr,
            style: const TextStyle(
              color: rbluedark,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            IconButton(
              tooltip: "Open in browser".tr,
              icon: const Icon(Icons.open_in_browser_rounded),
              onPressed: _openInBrowser,
            ),
          ],
          bottom: _failed || _progress >= 100
              ? null
              : PreferredSize(
                  preferredSize: const Size.fromHeight(3),
                  child: LinearProgressIndicator(
                    value: _progress == 0 ? null : _progress / 100,
                    minHeight: 3,
                    backgroundColor: Colors.transparent,
                    valueColor: const AlwaysStoppedAnimation(rbluedark),
                  ),
                ),
        ),
        body: _failed ? _buildFallback() : WebViewWidget(controller: _web),
      ),
    );
  }

  Widget _buildFallback() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpace.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpace.xl),
              decoration: BoxDecoration(
                color: rbluedark.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.wifi_off_rounded,
                size: 48,
                color: rbluedark.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: AppSpace.xl),
            Text(
              "The donation page could not load".tr,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: rbluedark,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpace.sm),
            Text(
              "Check your connection and try again, or open the link in your browser."
                  .tr,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppText.onPageMuted, fontSize: 14),
            ),
            const SizedBox(height: AppSpace.lg),
            // The link itself, so it can be copied into any browser by hand.
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.lg,
                vertical: AppSpace.md,
              ),
              decoration: plainCardDecoration(),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.link_rounded, color: rbluedark, size: 18),
                  const SizedBox(width: AppSpace.sm),
                  Flexible(
                    child: SelectableText(
                      kDonationUrl,
                      style: const TextStyle(
                        color: rbluedark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: "Copy link".tr,
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    color: rbluedark,
                    onPressed: () {
                      Clipboard.setData(
                        const ClipboardData(text: kDonationUrl),
                      );
                      CustomSnackbar.show(
                        "Copied".tr,
                        kDonationUrl,
                        isSuccess: true,
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpace.xl),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _openInBrowser,
                style: FilledButton.styleFrom(
                  backgroundColor: rbluedark,
                  padding: const EdgeInsets.symmetric(vertical: AppSpace.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.pillAll,
                  ),
                ),
                icon: const Icon(Icons.open_in_browser_rounded),
                label: Text("Open in browser".tr),
              ),
            ),
            const SizedBox(height: AppSpace.sm),
            TextButton.icon(
              onPressed: _retry,
              style: TextButton.styleFrom(foregroundColor: rbluedark),
              icon: const Icon(Icons.refresh_rounded),
              label: Text("Try again".tr),
            ),
          ],
        ),
      ),
    );
  }
}
