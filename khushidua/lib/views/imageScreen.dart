import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:khushidua/models/subCategoryModel.dart';

/// A section's illustration, full screen. Pinch or double-tap to zoom.
/// Opened from the image at the top of the dua list.
class ImageScreen extends StatefulWidget {
  final SubCategoryModel subCategoryModel;
  const ImageScreen({super.key, required this.subCategoryModel});

  @override
  State<ImageScreen> createState() => _ImageScreenState();
}

class _ImageScreenState extends State<ImageScreen> {
  static const double _doubleTapScale = 2.5;

  final TransformationController _transform = TransformationController();
  TapDownDetails? _doubleTapDown;

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  /// Zooms in on the tapped point, or back out if already zoomed.
  void _onDoubleTap() {
    if (_transform.value.getMaxScaleOnAxis() > 1.01) {
      _transform.value = Matrix4.identity();
      return;
    }
    final point = _doubleTapDown?.localPosition ?? Offset.zero;
    _transform.value = Matrix4.identity()
      ..translateByDouble(
        -point.dx * (_doubleTapScale - 1),
        -point.dy * (_doubleTapScale - 1),
        0,
        1,
      )
      ..scaleByDouble(_doubleTapScale, _doubleTapScale, 1, 1);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        // The Stack must fill the screen itself: sized by its children, it
        // shrank to the close button and squeezed the image into that corner.
        body: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: GestureDetector(
                onDoubleTapDown: (details) => _doubleTapDown = details,
                onDoubleTap: _onDoubleTap,
                child: InteractiveViewer(
                  transformationController: _transform,
                  maxScale: 4,
                  // The Hero fills the screen so the picture grows smoothly
                  // from the card into place, instead of flying into a
                  // zero-sized box while the image lays out.
                  child: Hero(
                    tag: 'section_image_${widget.subCategoryModel.id}',
                    child: SizedBox.expand(
                      child: Image.network(
                        widget.subCategoryModel.image,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, progress) =>
                            progress == null
                            ? child
                            : const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              ),
                        errorBuilder: (context, error, stackTrace) =>
                            const Center(
                              child: Icon(
                                Icons.image_not_supported_rounded,
                                size: 50,
                                color: Colors.white54,
                              ),
                            ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.paddingOf(context).top + 8,
              left: 8,
              child: IconButton(
                onPressed: () => Get.back(),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black.withValues(alpha: 0.4),
                ),
                icon: const Icon(Icons.close_rounded, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
