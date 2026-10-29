import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// A category logo or section picture: PNG/JPG through [Image.network], SVG
/// through flutter_svg. SVGs are stored under a `.svg` name (see
/// CategoryService.save), so the download URL tells the two apart; a blob
/// URL for a file not yet uploaded has no name, so pass [svg] for it.
class NetworkPicture extends StatelessWidget {
  const NetworkPicture(
    this.url, {
    super.key,
    bool? svg,
    this.fit = BoxFit.contain,
    this.fallback,
  }) : _svg = svg;

  final String url;
  final bool? _svg;
  final BoxFit fit;
  final WidgetBuilder? fallback;

  static bool isSvg(String url) =>
      Uri.tryParse(url)?.path.toLowerCase().endsWith('.svg') ?? false;

  @override
  Widget build(BuildContext context) {
    final fallback = this.fallback;
    if (_svg ?? isSvg(url)) {
      return SvgPicture.network(
        url,
        fit: fit,
        errorBuilder:
            fallback == null ? null : (context, _, __) => fallback(context),
      );
    }
    return Image.network(
      url,
      fit: fit,
      errorBuilder:
          fallback == null ? null : (context, _, __) => fallback(context),
    );
  }
}
