import 'package:flutter/material.dart';

/// Overlay widget that draws scanning viewfinder corners and an animated laser beam.
class ScannerOverlay extends StatefulWidget {
  final Widget child;
  final bool isScanning;
  final Color scanColor;

  const ScannerOverlay({
    super.key,
    required this.child,
    this.isScanning = true,
    this.scanColor = const Color(0xFF4F46E5),
  });

  @override
  State<ScannerOverlay> createState() => _ScannerOverlayState();
}

class _ScannerOverlayState extends State<ScannerOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _animation = Tween<double>(begin: 0.05, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.isScanning) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(ScannerOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isScanning && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.isScanning && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: CustomPaint(
            painter: _CornerBracketsPainter(
              color: widget.scanColor,
              strokeWidth: 3.5,
              cornerLength: 26.0,
            ),
          ),
        ),
        if (widget.isScanning)
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return CustomPaint(
                size: Size.infinite,
                painter: _LaserScanPainter(
                  positionFactor: _animation.value,
                  laserColor: widget.scanColor,
                ),
              );
            },
          ),
      ],
    );
  }
}

class _LaserScanPainter extends CustomPainter {
  final double positionFactor;
  final Color laserColor;

  _LaserScanPainter({
    required this.positionFactor,
    required this.laserColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height * positionFactor;

    // Draw glowing gradient band behind the laser line
    const bandHeight = 40.0;
    final Rect bandRect = Rect.fromLTRB(
      10,
      y - bandHeight,
      size.width - 10,
      y,
    );

    final Paint glowPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          laserColor.withOpacity(0.0),
          laserColor.withOpacity(0.25),
        ],
      ).createShader(bandRect);

    canvas.drawRect(bandRect, glowPaint);

    // Draw main bright laser line
    final Paint linePaint = Paint()
      ..color = laserColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(12, y),
      Offset(size.width - 12, y),
      linePaint,
    );

    // Draw center indicator pulse
    final Paint dotPaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(size.width / 2, y), 3.0, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _LaserScanPainter oldDelegate) {
    return oldDelegate.positionFactor != positionFactor ||
        oldDelegate.laserColor != laserColor;
  }
}

class _CornerBracketsPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double cornerLength;

  _CornerBracketsPainter({
    required this.color,
    required this.strokeWidth,
    required this.cornerLength,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    const offset = 8.0;

    // Top-Left
    canvas.drawLine(
      const Offset(offset, offset),
      Offset(offset + cornerLength, offset),
      paint,
    );
    canvas.drawLine(
      const Offset(offset, offset),
      Offset(offset, offset + cornerLength),
      paint,
    );

    // Top-Right
    canvas.drawLine(
      Offset(size.width - offset, offset),
      Offset(size.width - offset - cornerLength, offset),
      paint,
    );
    canvas.drawLine(
      Offset(size.width - offset, offset),
      Offset(size.width - offset, offset + cornerLength),
      paint,
    );

    // Bottom-Left
    canvas.drawLine(
      Offset(offset, size.height - offset),
      Offset(offset + cornerLength, size.height - offset),
      paint,
    );
    canvas.drawLine(
      Offset(offset, size.height - offset),
      Offset(offset, size.height - offset - cornerLength),
      paint,
    );

    // Bottom-Right
    canvas.drawLine(
      Offset(size.width - offset, size.height - offset),
      Offset(size.width - offset - cornerLength, size.height - offset),
      paint,
    );
    canvas.drawLine(
      Offset(size.width - offset, size.height - offset),
      Offset(size.width - offset, size.height - offset - cornerLength),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _CornerBracketsPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.cornerLength != cornerLength;
  }
}
