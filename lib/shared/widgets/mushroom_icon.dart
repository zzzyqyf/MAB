import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// A decorative mushroom icon widget for accessibility-friendly UI decoration
class MushroomIcon extends StatelessWidget {
  final double size;
  final Color? color;
  final String? semanticLabel;
  
  const MushroomIcon({
    Key? key,
    this.size = 32.0,
    this.color,
    this.semanticLabel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final iconColor = color ?? AppColors.primary;
    
    return Semantics(
      label: semanticLabel ?? 'Decorative mushroom icon',
      child: Container(
        width: size,
        height: size,
        child: CustomPaint(
          painter: MushroomPainter(color: iconColor),
        ),
      ),
    );
  }
}

/// Custom painter to draw a simple mushroom icon
class MushroomPainter extends CustomPainter {
  final Color color;
  
  MushroomPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    final strokePaint = Paint()
      ..color = AppColors.onSurface
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    
    final width = size.width;
    final height = size.height;
    
    // Draw mushroom cap (top half oval)
    final capRect = Rect.fromLTWH(
      width * 0.1, 
      height * 0.1, 
      width * 0.8, 
      height * 0.5
    );
    
    canvas.drawOval(capRect, paint);
    canvas.drawOval(capRect, strokePaint);
    
    // Draw mushroom stem (rectangle)
    final stemRect = Rect.fromLTWH(
      width * 0.4, 
      height * 0.35, 
      width * 0.2, 
      height * 0.5
    );
    
    final stemPaint = Paint()
      ..color = color.withOpacity(0.7)
      ..style = PaintingStyle.fill;
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(stemRect, Radius.circular(width * 0.05)), 
      stemPaint
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(stemRect, Radius.circular(width * 0.05)), 
      strokePaint
    );
    
    // Add decorative spots on the cap
    final spotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    // Large spot
    canvas.drawCircle(
      Offset(width * 0.3, height * 0.25), 
      width * 0.05, 
      spotPaint
    );
    
    // Medium spot
    canvas.drawCircle(
      Offset(width * 0.6, height * 0.3), 
      width * 0.03, 
      spotPaint
    );
    
    // Small spot
    canvas.drawCircle(
      Offset(width * 0.7, height * 0.2), 
      width * 0.02, 
      spotPaint
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

/// A collection of mushroom icons with different variations
class MushroomIconSet extends StatelessWidget {
  final double spacing;
  final double iconSize;
  
  const MushroomIconSet({
    Key? key,
    this.spacing = 8.0,
    this.iconSize = 24.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        MushroomIcon(
          size: iconSize,
          color: AppColors.success,
          semanticLabel: 'Green mushroom decoration',
        ),
        SizedBox(width: spacing),
        MushroomIcon(
          size: iconSize,
          color: AppColors.warning,
          semanticLabel: 'Orange mushroom decoration',
        ),
        SizedBox(width: spacing),
        MushroomIcon(
          size: iconSize,
          color: AppColors.error,
          semanticLabel: 'Red mushroom decoration',
        ),
      ],
    );
  }
}
