import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// A picture uploaded in the admin panel: PNG/JPG through [Image.network],
/// SVG through flutter_svg. The panel saves SVGs under a `.svg` name, so the
/// download URL's path tells the two apart.
class NetworkPicture extends StatelessWidget {
  const NetworkPicture(
    this.url, {
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    required this.fallback,
    this.loading,
  });

  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;

  /// Shown when the picture can't be fetched or decoded.
  final WidgetBuilder fallback;

  /// Shown while the picture downloads; nothing by default.
  final WidgetBuilder? loading;

  static bool isSvg(String url) =>
      Uri.tryParse(url)?.path.toLowerCase().endsWith('.svg') ?? false;

  @override
  Widget build(BuildContext context) {
    if (isSvg(url)) {
      return SvgPicture.network(
        url,
        width: width,
        height: height,
        fit: fit,
        placeholderBuilder:
            loading ?? (_) => SizedBox(width: width, height: height),
        errorBuilder: (context, error, stackTrace) => fallback(context),
      );
    }
    return Image.network(
      url,
      width: width,
      height: height,
      fit: fit,
      loadingBuilder: loading == null
          ? null
          : (context, child, progress) =>
                progress == null ? child : loading!(context),
      errorBuilder: (context, error, stackTrace) => fallback(context),
    );
  }
}
