import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/wallpaper.dart';
import '../widgets/theme.dart';
import '../widgets/glassmorphic_container.dart';

class CropPreviewScreen extends StatefulWidget {
  final Wallpaper wallpaper;
  final String localFilePath;
  final Function(int) onApply; // 1: Home, 2: Lock, 3: Both

  const CropPreviewScreen({
    super.key,
    required this.wallpaper,
    required this.localFilePath,
    required this.onApply,
  });

  @override
  State<CropPreviewScreen> createState() => _CropPreviewScreenState();
}

class _CropPreviewScreenState extends State<CropPreviewScreen> {
  final TransformationController _transformationController = TransformationController();

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Wallpaper behind the crop frame (using InteractiveViewer for zoom/pan)
          InteractiveViewer(
            transformationController: _transformationController,
            boundaryMargin: const EdgeInsets.all(200),
            minScale: 1.0,
            maxScale: 4.0,
            child: Image.network(
              widget.wallpaper.fullUrl,
              fit: BoxFit.cover,
              width: size.width,
              height: size.height,
            ),
          ),

          // 2. Crop mask overlay (darkens out-of-crop areas)
          IgnorePointer(
            child: CustomPaint(
              size: size,
              painter: CropMaskPainter(
                cropWidth: size.width * 0.8,
                cropHeight: size.height * 0.72,
                borderRadius: GlintTheme.radiusLg,
              ),
            ),
          ),

          // 3. Top Close & Reset actions
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Colors.black45,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: Colors.white),
                  ),
                ),
                TextButton(
                  onPressed: _resetZoom,
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.black45,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                  ),
                  child: Text(
                    'Reset Zoom',
                    style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          // 4. Bottom crop control panel
          Positioned(
            left: 20,
            right: 20,
            bottom: 24,
            child: GlassmorphicContainer(
              isDark: isDark,
              borderRadius: GlintTheme.radiusLg,
              padding: const EdgeInsets.all(GlintTheme.gutter * 1.2),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Align Wallpaper',
                    style: GlintTheme.titleMedium(context),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    'Drag and pinch image inside the frame to adjust.',
                    textAlign: TextAlign.center,
                    style: GlintTheme.captionXs(context, color: Colors.white70),
                  ),
                  const SizedBox(height: 20.0),
                  
                  // Action buttons
                  Row(
                    children: [
                      // Cancel
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white12,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(GlintTheme.radiusDefault),
                            ),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12.0),
                      
                      // Set screen
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context); // Close preview
                            // Trigger set wallpaper sheet
                            widget.onApply(3); // Defaults to both, or shows dialog
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: GlintTheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(GlintTheme.radiusDefault),
                            ),
                          ),
                          child: const Text('Apply Crop'),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Crop mask painter creating a transparent rounded frame cutout
class CropMaskPainter extends CustomPainter {
  final double cropWidth;
  final double cropHeight;
  final double borderRadius;

  CropMaskPainter({
    required this.cropWidth,
    required this.cropHeight,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.55)
      ..style = PaintingStyle.fill;

    // Center coordinates for cutouts
    final double left = (size.width - cropWidth) / 2;
    final double top = (size.height - cropHeight) / 2;
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, top, cropWidth, cropHeight),
      Radius.circular(borderRadius),
    );

    // Combine outer rectangle and inner cutout
    final outerPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final innerPath = Path()..addRRect(rect);
    final combinedPath = Path.combine(PathOperation.difference, outerPath, innerPath);

    canvas.drawPath(combinedPath, paint);

    // Draw thin frame outline
    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    
    canvas.drawRRect(rect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
