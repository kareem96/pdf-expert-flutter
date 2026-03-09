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
    Key? key,
    required this.field,
    required this.scale,
    required this.offset,
    required this.onUpdatePosition,
    required this.onResize,
    required this.onEdit,
    required this.isEraserMode,
    required this.onErase,
  }) : super(key: key);

  @override
  State<PdfFieldOverlay> createState() => _PdfFieldOverlayState();
}

class _PdfFieldOverlayState extends State<PdfFieldOverlay> {
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
  }

  @override
  Widget build(BuildContext context) {
    final bool isImageOrSign = widget.field.type == PdfFieldType.image || widget.field.type == PdfFieldType.signature;
    final bool isEraser = widget.field.type == PdfFieldType.eraser;
    final bool isMarker = widget.field.type == PdfFieldType.marker;

    final double currentWidth = (isEraser || isMarker) 
        ? ((widget.field.width * widget.scale) + _resizeDw)
        : math.max(20.0, (widget.field.width * widget.scale) + _resizeDw);
    final double currentHeight = (isEraser || isMarker) 
        ? ((widget.field.height * widget.scale) + _resizeDh)
        : math.max(20.0, (widget.field.height * widget.scale) + _resizeDh);

    return Positioned(
      left: widget.offset.dx + _dragDx,
      top: widget.offset.dy + _dragDy,
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
                    : (isEraser ? Color(int.parse(widget.field.backgroundColor ?? '0xFFFFFFFF')) : Theme.of(context).colorScheme.onSurface.withOpacity(0.05)),
                border: (isImageOrSign && (widget.field.value == null || widget.field.value!.isEmpty))
                    ? null
                    : isEraser 
                      ? Border.all(color: Colors.grey.withOpacity(0.5), width: 1)
                      : Border.all(
                          color: Colors.blue.withOpacity(0.8), 
                          width: 1.5, 
                        ),
                borderRadius: BorderRadius.circular(2),
                boxShadow: isEraser ? null : [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.1),
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
                        ? Container(
                            width: currentWidth,
                            height: currentHeight,
                          )
                    : isMarker
                        ? Container(
                            width: currentWidth,
                            height: currentHeight,
                            child: FittedBox(
                              fit: BoxFit.contain,
                              child: buildMarkerWidget(
                                widget.field.value, 
                                widget.field.width, 
                                widget.field.height,
                                color: Color(int.parse(widget.field.textColor)),
                              ),
                            ),
                          )
                        : Container(
                            padding: widget.field.backgroundColor != null 
                                ? const EdgeInsets.symmetric(horizontal: 8, vertical: 8)
                                : EdgeInsets.zero,
                            decoration: widget.field.backgroundColor != null 
                                ? BoxDecoration(
                                    color: Color(int.parse(widget.field.backgroundColor!)),
                                    border: Border.all(color: Colors.amber.shade600, width: 2),
                                    borderRadius: BorderRadius.circular(4),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.15),
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
                                color: Color(int.parse(widget.field.textColor)),
                                fontWeight: widget.field.isBold ? FontWeight.bold : FontWeight.normal,
                                fontStyle: widget.field.isItalic ? FontStyle.italic : FontStyle.normal,
                              ).copyWith(height: 1.1),
                              softWrap: false,
                              overflow: TextOverflow.visible,
                            ),
                          ),
            ),
          ),
          if (isImageOrSign)
            Positioned(
              right: -20,
              bottom: -20,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanUpdate: (details) {
                  setState(() {
                    _resizeDw += details.delta.dx;
                    _resizeDh += details.delta.dy;
                  });
                },
                onPanEnd: (details) {
                  widget.onResize(_resizeDw, _resizeDh);
                },
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.blue, width: 2),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4),
                      ],
                    ),
                    child: const Icon(Icons.open_in_full, size: 16, color: Colors.blue),
                  ),
                ),
              ),
            ),
        ],
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
