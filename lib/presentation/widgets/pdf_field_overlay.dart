import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/entities/pdf_field_entity.dart';

class PdfFieldOverlay extends StatefulWidget {
  final PdfFieldEntity field;
  final double scale;
  final Offset offset;
  final Function(double dx, double dy) onUpdatePosition;
  final Function(double dw, double dh) onResize;
  final VoidCallback onEdit;
  final bool isEraserMode;
  final VoidCallback onErase;

  const PdfFieldOverlay({
    super.key,
    required this.field,
    required this.scale,
    required this.offset,
    required this.onUpdatePosition,
    required this.onResize,
    required this.onEdit,
    required this.isEraserMode,
    required this.onErase,
  });

  @override
  State<PdfFieldOverlay> createState() => _PdfFieldOverlayState();
}

class _PdfFieldOverlayState extends State<PdfFieldOverlay> {
  Color? _cachedColor;
  String? _lastColorStr;

  Color _parseColor(String colorStr, {Color fallback = Colors.black}) {
    if (_lastColorStr == colorStr && _cachedColor != null) return _cachedColor!;
    
    try {
      String clean = colorStr.replaceAll('#', '');
      if (!clean.startsWith('0x')) {
        if (clean.length == 6) {
          clean = '0xFF$clean';
        } else if (clean.length == 8) {
          clean = '0x$clean';
        }
      } else if (clean.startsWith('0x') && clean.length == 8) {
        clean = '0xFF${clean.substring(2)}';
      }
      _lastColorStr = colorStr;
      _cachedColor = Color(int.parse(clean));
      return _cachedColor!;
    } catch (_) {
      return fallback;
    }
  }

  double _dragDx = 0;
  double _dragDy = 0;
  
  double _resizeDw = 0;
  double _resizeDh = 0;

  @override
  void didUpdateWidget(PdfFieldOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((oldWidget.offset.dx - widget.offset.dx).abs() > 5.0 || (oldWidget.offset.dy - widget.offset.dy).abs() > 5.0) {
      _dragDx = 0;
      _dragDy = 0;
    }
    if (oldWidget.field.width != widget.field.width || oldWidget.field.height != widget.field.height) {
      _resizeDw = 0;
      _resizeDh = 0;
    }
    // Clear color cache if field might have changed (though entity is immutable)
    if (oldWidget.field.textColor != widget.field.textColor) {
      _lastColorStr = null;
    }
  }


  @override
  Widget build(BuildContext context) {
    final bool isImageOrSign = widget.field.type == PdfFieldType.image || widget.field.type == PdfFieldType.signature;
    final bool isEraser = widget.field.type == PdfFieldType.eraser;
    final bool isMarker = widget.field.type == PdfFieldType.marker;

    final bool currentIsResizable = isImageOrSign || isMarker;

    final double minSize = 15.0;
    final double currentWidth = (isEraser || isMarker) 
        ? math.max(minSize, (widget.field.width * widget.scale) + _resizeDw)
        : math.max(minSize, (widget.field.width * widget.scale) + _resizeDw);
    final double currentHeight = (isEraser || isMarker) 
        ? math.max(minSize, (widget.field.height * widget.scale) + _resizeDh)
        : math.max(minSize, (widget.field.height * widget.scale) + _resizeDh);

    return Transform.translate(
      offset: Offset(_dragDx, _dragDy),
      child: SizedBox(
        width: currentWidth + 60,
        height: currentHeight + 60,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  _dragDx += details.delta.dx;
                  _dragDy += details.delta.dy;
                });
              },
              onPanEnd: (details) {
                final dx = _dragDx;
                final dy = _dragDy;
                setState(() {
                  _dragDx = 0;
                  _dragDy = 0;
                });
                widget.onUpdatePosition(dx, dy);
              },
              onTap: widget.onEdit,
              child: Container(
                width: isImageOrSign || isEraser || isMarker ? currentWidth : null,
                height: isImageOrSign || isEraser || isMarker ? currentHeight : null,
                padding: EdgeInsets.zero,
                decoration: BoxDecoration(
                  color: (isImageOrSign && (widget.field.value == null || widget.field.value!.isEmpty))
                      ? Colors.transparent 
                      : (isEraser ? _parseColor(widget.field.backgroundColor ?? '0xFFFFFFFF') : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05)),
                  border: (isImageOrSign && (widget.field.value == null || widget.field.value!.isEmpty))
                      ? null
                      : isEraser 
                        ? Border.all(color: Colors.grey.withValues(alpha: 0.5), width: 1)
                        : Border.all(
                            color: Colors.blue.withValues(alpha: 0.8), 
                            width: 1.5, 
                          ),
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: isEraser ? null : [
                    BoxShadow(
                      color: Colors.blue.withValues(alpha: 0.1),
                      blurRadius: 4,
                    ),
                  ],
                ),
                  child: isImageOrSign
                    ? (widget.field.value != null && widget.field.value!.isNotEmpty)
                        ? Image.file(
                            File(widget.field.value!),
                            width: currentWidth,
                            height: currentHeight,
                            fit: BoxFit.fill,
                          )
                        : const SizedBox.shrink()
                      : isEraser
                          ? SizedBox(
                              width: currentWidth,
                              height: currentHeight,
                            )
                      : isMarker
                          ? SizedBox(
                              width: currentWidth,
                              height: currentHeight,
                              child: FittedBox(
                                fit: BoxFit.contain,
                                child: buildMarkerWidget(
                                  widget.field.value, 
                                  widget.field.width, 
                                  widget.field.height,
                                  color: _parseColor(widget.field.textColor),
                                ),
                              ),
                            )
                          : Container(
                              padding: widget.field.backgroundColor != null 
                                  ? const EdgeInsets.symmetric(horizontal: 8, vertical: 8)
                                  : EdgeInsets.zero,
                              decoration: widget.field.backgroundColor != null 
                                  ? BoxDecoration(
                                      color: _parseColor(widget.field.backgroundColor!),
                                      border: Border.all(color: Colors.amber.shade600, width: 2),
                                      borderRadius: BorderRadius.circular(4),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.15),
                                          blurRadius: 6,
                                          offset: const Offset(2, 4),
                                        ),
                                      ],
                                    ) 
                                  : null,
                              child: Text(
                                widget.field.value ?? '',
                                style: _buildGoogleFontStyle(
                                  widget.field.fontFamily,
                                  fontSize: widget.field.fontSize * widget.scale,
                                  color: _parseColor(widget.field.textColor),
                                  fontWeight: widget.field.isBold ? FontWeight.bold : FontWeight.normal,
                                  fontStyle: widget.field.isItalic ? FontStyle.italic : FontStyle.normal,
                                ).copyWith(height: 1.1),
                                softWrap: false,
                                overflow: TextOverflow.visible,
                              ),
                            ),
              ),
            ),
            if (currentIsResizable)
              Positioned(
                left: currentWidth - 12,
                top: currentHeight - 12,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanUpdate: (details) {
                    setState(() {
                      _resizeDw += details.delta.dx;
                      // Logic: Marker use 1:1 ratio, Others use original ratio
                      if (widget.field.type == PdfFieldType.marker) {
                        _resizeDh = _resizeDw;
                      } else {
                        final ratio = widget.field.height / widget.field.width;
                        _resizeDh = _resizeDw * ratio;
                      }
                    });
                  },
                  onPanEnd: (details) {
                    widget.onResize(_resizeDw, _resizeDh);
                  },
                  child: Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        border: Border(
                          right: BorderSide(color: Colors.blue, width: 3.0),
                          bottom: BorderSide(color: Colors.blue, width: 3.0),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );

  }

  TextStyle _buildGoogleFontStyle(
    String fontFamily, {
    double? fontSize,
    Color? color,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
  }) {
    final base = TextStyle(
      fontSize: fontSize,
      color: color,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
    );

    try {
      switch (fontFamily) {
        case 'Merriweather':
          return GoogleFonts.merriweather(textStyle: base);
        case 'Courier Prime':
          return GoogleFonts.courierPrime(textStyle: base);
        case 'Roboto':
          return GoogleFonts.roboto(textStyle: base);
        case 'Playfair Display':
          return GoogleFonts.playfairDisplay(textStyle: base);
        case 'Dancing Script':
          return GoogleFonts.dancingScript(textStyle: base);
        case 'Helvetica':
        default:
          return base;
      }
    } catch (_) {
      return base;
    }
  }

  Widget buildMarkerWidget(String? type, double width, double height, {Color color = Colors.black}) {
    switch (type) {
      case 'check':
        return Icon(Icons.check, color: color, size: width);
      case 'close':
        return Icon(Icons.close, color: color, size: width);
      case 'square':
        return Container(width: width, height: height, color: color);
      case 'circle':
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        );
      default:
        return Icon(Icons.check, color: color, size: width);
    }
  }
}
