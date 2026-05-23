import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:flutter_svg/flutter_svg.dart';

// ══════════════════════════════════════════════════════════════════════════════
// CUSTOM SYMBOL PAINTERS
// ══════════════════════════════════════════════════════════════════════════════

/// Draws the international plastic-code triangle (Möbius arrows) with a
/// number in the centre – exactly as printed on plastic packaging.
class _PlasticCodePainter extends CustomPainter {
  final int code;
  final Color color;

  const _PlasticCodePainter({required this.code, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.07
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final cx = size.width / 2;
    final cy = size.height / 2 + size.height * 0.04;
    final r = size.width * 0.38;

    // Draw three curved arrow segments forming the recycling triangle
    for (int i = 0; i < 3; i++) {
      final angle = -math.pi / 2 + i * 2 * math.pi / 3;
      final nextAngle = angle + 2 * math.pi / 3;
      final tipAngle = nextAngle - 0.22;

      // Arc segment
      final rect = Rect.fromCircle(center: Offset(cx, cy), radius: r);
      canvas.drawArc(rect, angle + 0.18, 1.75, false, paint);

      // Arrowhead
      final tipX = cx + r * math.cos(tipAngle);
      final tipY = cy + r * math.sin(tipAngle);
      final aw = size.width * 0.11;
      final arrowAngle = tipAngle + math.pi / 2;
      final path = Path()
        ..moveTo(tipX, tipY)
        ..lineTo(
          tipX - aw * math.cos(arrowAngle - 0.45),
          tipY - aw * math.sin(arrowAngle - 0.45),
        )
        ..moveTo(tipX, tipY)
        ..lineTo(
          tipX - aw * math.cos(arrowAngle + 0.45),
          tipY - aw * math.sin(arrowAngle + 0.45),
        );
      canvas.drawPath(path, paint);
    }

    // Centre number
    final tp = TextPainter(
      text: TextSpan(
        text: '$code',
        style: TextStyle(
          color: color,
          fontSize: size.width * 0.30,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(cx - tp.width / 2, cy - tp.height / 2 - size.height * 0.02),
    );
  }

  @override
  bool shouldRepaint(_PlasticCodePainter old) =>
      old.code != code || old.color != color;
}

/// Draws the WEEE crossed-out bin symbol.
class _WeeePainter extends CustomPainter {
  final Color color;
  const _WeeePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.065
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;

    // Bin body (trapezoid)
    final bodyPath = Path()
      ..moveTo(w * 0.22, h * 0.38)
      ..lineTo(w * 0.28, h * 0.85)
      ..lineTo(w * 0.72, h * 0.85)
      ..lineTo(w * 0.78, h * 0.38)
      ..close();
    canvas.drawPath(bodyPath, p);

    // Bin lid
    canvas.drawLine(Offset(w * 0.15, h * 0.38), Offset(w * 0.85, h * 0.38), p);

    // Handle on lid
    final handleRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(w * 0.5, h * 0.30),
        width: w * 0.28,
        height: h * 0.10,
      ),
      Radius.circular(w * 0.06),
    );
    canvas.drawRRect(handleRect, p);

    // Vertical lines inside bin
    for (int i = 0; i < 3; i++) {
      final x = w * (0.35 + i * 0.15);
      canvas.drawLine(Offset(x, h * 0.44), Offset(x, h * 0.79), p);
    }

    // Crossbar at bottom (gạch chéo dưới)
    final barPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.09
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(w * 0.1, h * 0.93), Offset(w * 0.9, h * 0.93), barPaint);

    // X cross
    final xPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.07
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
        Offset(w * 0.26, h * 0.40), Offset(w * 0.72, h * 0.83), xPaint);
    canvas.drawLine(
        Offset(w * 0.72, h * 0.40), Offset(w * 0.26, h * 0.83), xPaint);
  }

  @override
  bool shouldRepaint(_WeeePainter old) => old.color != color;
}

/// Simple Möbius loop (recycling arrows triangle) without a number.
class _MobiusPainter extends CustomPainter {
  final Color color;
  final double strokeRatio;
  const _MobiusPainter({required this.color, this.strokeRatio = 0.07});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * strokeRatio
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.40;

    for (int i = 0; i < 3; i++) {
      final angle = -math.pi / 2 + i * 2 * math.pi / 3;
      final nextAngle = angle + 2 * math.pi / 3;
      final tipAngle = nextAngle - 0.22;

      final rect = Rect.fromCircle(center: Offset(cx, cy), radius: r);
      canvas.drawArc(rect, angle + 0.18, 1.75, false, paint);

      final tipX = cx + r * math.cos(tipAngle);
      final tipY = cy + r * math.sin(tipAngle);
      final aw = size.width * 0.11;
      final arrowAngle = tipAngle + math.pi / 2;
      final path = Path()
        ..moveTo(tipX, tipY)
        ..lineTo(tipX - aw * math.cos(arrowAngle - 0.45),
            tipY - aw * math.sin(arrowAngle - 0.45))
        ..moveTo(tipX, tipY)
        ..lineTo(tipX - aw * math.cos(arrowAngle + 0.45),
            tipY - aw * math.sin(arrowAngle + 0.45));
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_MobiusPainter old) => old.color != color;
}

// ══════════════════════════════════════════════════════════════════════════════
// SVG SYMBOL LIBRARY  (black strokes – tinted at render time via colorFilter)
// ══════════════════════════════════════════════════════════════════════════════

const _svgFoodGrade = r'''<svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg"><g stroke="black" stroke-linecap="round" stroke-linejoin="round" fill="none" stroke-width="5"><line x1="20" y1="5" x2="20" y2="40"/><line x1="28" y1="5" x2="28" y2="40"/><line x1="36" y1="5" x2="36" y2="40"/><line x1="44" y1="5" x2="44" y2="40"/><line x1="20" y1="30" x2="44" y2="30"/><line x1="32" y1="30" x2="32" y2="95"/><path d="M62,5 L75,58"/><path d="M88,5 L75,58"/><line x1="65" y1="22" x2="85" y2="22" stroke-width="4"/><line x1="75" y1="58" x2="75" y2="78"/><line x1="62" y1="78" x2="88" y2="78"/><line x1="60" y1="88" x2="90" y2="88"/><line x1="62" y1="78" x2="60" y2="88"/><line x1="88" y1="78" x2="90" y2="88"/></g></svg>''';

const _svgFragile = r'''<svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg"><g stroke="black" stroke-linecap="round" stroke-linejoin="round" fill="none" stroke-width="5"><path d="M30,5 L50,58"/><path d="M70,5 L50,58"/><line x1="34" y1="23" x2="66" y2="23" stroke-width="4"/><line x1="50" y1="58" x2="50" y2="78"/><line x1="35" y1="78" x2="65" y2="78"/><line x1="30" y1="90" x2="70" y2="90"/><line x1="35" y1="78" x2="30" y2="90"/><line x1="65" y1="78" x2="70" y2="90"/><polyline points="40,8 36,20 43,26 39,38" stroke-width="3.5"/></g></svg>''';

const _svgUmbrella = r'''<svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg"><g stroke="black" stroke-linecap="round" stroke-linejoin="round" fill="none" stroke-width="5"><path d="M5,52 Q50,4 95,52"/><line x1="50" y1="14" x2="50" y2="52"/><line x1="50" y1="52" x2="50" y2="82"/><path d="M50,82 Q50,96 38,96 Q26,96 26,84"/><line x1="20" y1="68" x2="18" y2="80" stroke-width="4"/><line x1="36" y1="72" x2="34" y2="84" stroke-width="4"/><line x1="65" y1="70" x2="63" y2="82" stroke-width="4"/><line x1="80" y1="65" x2="78" y2="77" stroke-width="4"/></g></svg>''';

const _svgArrowsUp = r'''<svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg"><g stroke="black" stroke-linecap="round" stroke-linejoin="round" fill="none" stroke-width="6"><line x1="30" y1="88" x2="30" y2="22"/><polyline points="15,40 30,22 45,40"/><line x1="70" y1="88" x2="70" y2="22"/><polyline points="55,40 70,22 85,40"/></g></svg>''';

const _svgEnergyStar = r'''<svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg"><path d="M50,5 L61,38 L96,38 L68,57 L79,90 L50,70 L21,90 L32,57 L4,38 L39,38 Z" stroke="black" stroke-width="4" stroke-linejoin="round" fill="none"/></svg>''';

const _svgSnowflake = r'''<svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg"><g stroke="black" stroke-linecap="round" fill="none" stroke-width="6"><line x1="50" y1="8" x2="50" y2="92"/><line x1="13" y1="29" x2="87" y2="71"/><line x1="87" y1="29" x2="13" y2="71"/><line x1="36" y1="22" x2="50" y2="34"/><line x1="64" y1="22" x2="50" y2="34"/><line x1="36" y1="78" x2="50" y2="66"/><line x1="64" y1="78" x2="50" y2="66"/><line x1="21" y1="40" x2="30" y2="50"/><line x1="21" y1="60" x2="30" y2="50"/><line x1="79" y1="40" x2="70" y2="50"/><line x1="79" y1="60" x2="70" y2="50"/></g></svg>''';

const _svgMicrowave = r'''<svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg"><g stroke="black" fill="none" stroke-linecap="round"><rect x="5" y="18" width="90" height="68" rx="6" stroke-width="5"/><rect x="12" y="25" width="62" height="54" rx="4" stroke-width="4"/><path d="M20,40 Q28,32 36,40 Q44,48 52,40 Q60,32 66,40" stroke-width="4"/><path d="M20,56 Q28,48 36,56 Q44,64 52,56 Q60,48 66,56" stroke-width="4"/><circle cx="84" cy="42" r="5" stroke-width="4"/><rect x="79" y="56" width="10" height="14" rx="2" stroke-width="4"/></g></svg>''';

const _svgLeaf = r'''<svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg"><g stroke="black" fill="none" stroke-linecap="round" stroke-linejoin="round" stroke-width="5"><path d="M50,92 Q18,72 18,42 Q18,8 50,8 Q82,8 82,42 Q82,72 50,92 Z"/><line x1="50" y1="8" x2="50" y2="92"/><line x1="50" y1="38" x2="30" y2="26"/><line x1="50" y1="55" x2="28" y2="46"/><line x1="50" y1="38" x2="70" y2="26"/><line x1="50" y1="55" x2="72" y2="46"/></g></svg>''';

const _svgTrashBin = r'''<svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg"><g stroke="black" fill="none" stroke-linecap="round" stroke-linejoin="round" stroke-width="5.5"><path d="M40 18h20" stroke-width="4.5"/><path d="M44 18v6M56 18v6" stroke-width="4"/><path d="M18 25h64" stroke-width="6.5"/><path d="M24 32 L30 82 Q30 90 38 90 L62 90 Q70 90 70 82 L76 32 Z"/><line x1="40" y1="42" x2="40" y2="80" stroke-width="4" opacity="0.45"/><line x1="50" y1="42" x2="50" y2="80" stroke-width="4" opacity="0.45"/><line x1="60" y1="42" x2="60" y2="80" stroke-width="4" opacity="0.45"/></g></svg>''';

const _svgHazard = r'''<svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg"><g stroke="black" fill="none" stroke-linecap="round" stroke-linejoin="round"><path d="M50,6 L96,90 L4,90 Z" stroke-width="6"/><line x1="50" y1="30" x2="50" y2="68" stroke-width="8"/><circle cx="50" cy="80" r="5" fill="black"/></g></svg>''';

const _svgSeedling = r'''<svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg"><g stroke="black" fill="none" stroke-linecap="round" stroke-linejoin="round" stroke-width="5"><line x1="50" y1="95" x2="50" y2="52"/><path d="M50,68 Q28,58 26,34 Q38,28 50,52"/><path d="M50,58 Q72,48 74,24 Q62,18 50,52"/></g></svg>''';



const _svgThermometer = r'''<svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg"><g stroke="black" fill="none" stroke-linecap="round" stroke-linejoin="round"><circle cx="50" cy="82" r="13" stroke-width="5"/><path d="M43,78 L43,22 Q43,12 50,12 Q57,12 57,22 L57,78" stroke-width="5"/><rect x="45" y="42" width="10" height="36" fill="black" rx="2"/><line x1="57" y1="35" x2="66" y2="35" stroke-width="4"/><line x1="57" y1="50" x2="66" y2="50" stroke-width="4"/><line x1="57" y1="65" x2="64" y2="65" stroke-width="3.5"/></g></svg>''';

const _svgStacking = r'''<svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg"><g stroke="black" fill="none" stroke-linecap="round" stroke-linejoin="round" stroke-width="5"><rect x="18" y="8" width="56" height="20" rx="2"/><rect x="18" y="30" width="56" height="20" rx="2"/><rect x="18" y="52" width="56" height="20" rx="2"/><line x1="82" y1="18" x2="82" y2="72"/><polyline points="76,60 82,74 88,60"/><line x1="18" y1="82" x2="74" y2="82" stroke-width="4"/><line x1="26" y1="90" x2="66" y2="90" stroke-width="3.5"/></g></svg>''';

const _svgTrolley = r'''<svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg"><g stroke="black" fill="none" stroke-linecap="round" stroke-linejoin="round" stroke-width="5"><line x1="30" y1="8" x2="30" y2="82"/><line x1="14" y1="72" x2="60" y2="72"/><circle cx="22" cy="88" r="9"/><circle cx="56" cy="88" r="9"/><rect x="34" y="28" width="36" height="38" rx="2" stroke-width="4"/><line x1="30" y1="47" x2="70" y2="47" stroke-width="3.5"/></g></svg>''';

const _svgNoHook = r'''<svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg"><g stroke="black" fill="none" stroke-linecap="round" stroke-linejoin="round"><path d="M50,10 L50,38 Q50,60 35,68 Q18,76 18,88 Q18,96 28,96 Q40,96 44,86" stroke-width="5"/><circle cx="50" cy="50" r="42" stroke-width="5"/><line x1="20" y1="20" x2="80" y2="80" stroke-width="7"/></g></svg>''';

const _svgTidyman = r'''<svg viewBox="0 0 110 110" xmlns="http://www.w3.org/2000/svg"><g stroke="black" stroke-linecap="round" stroke-linejoin="round" fill="none" stroke-width="5"><circle cx="55" cy="12" r="9"/><line x1="55" y1="21" x2="55" y2="62"/><line x1="55" y1="35" x2="75" y2="22"/><line x1="55" y1="35" x2="40" y2="48"/><line x1="55" y1="62" x2="44" y2="90"/><line x1="55" y1="62" x2="64" y2="90"/><path d="M78,40 L78,74 Q78,78 82,78 L96,78 Q100,78 100,74 L100,40 Z" stroke-width="4"/><line x1="76" y1="40" x2="102" y2="40" stroke-width="4"/><rect x="66" y="15" width="12" height="10" rx="2" stroke-width="3.5"/></g></svg>''';

// ══════════════════════════════════════════════════════════════════════════════
// SYMBOL WIDGET BUILDER
// ══════════════════════════════════════════════════════════════════════════════

enum SymbolStyle {
  plasticCode,   // CustomPainter: tam giác Möbius + số
  weee,          // CustomPainter: thùng rác gạch chéo
  mobius,        // CustomPainter: tam giác tái chế
  mobiusPercent, // CustomPainter: tam giác + %
  textBadge,     // Styled text (CE, FCC, RoHS, PAP, GL…)
  certBadge,     // Tròn viền + chữ (UL, CSA, GS, CCC)
  colorBin,      // Thùng rác màu (VN)
  svg,           // SvgPicture.string() – ký hiệu thực tế
}

class SymbolWidgetData {
  final SymbolStyle style;
  final int? code;         // for plasticCode
  final String? text;      // for textBadge / certBadge / mobiusPercent
  final String? subText;   // for textBadge second line
  final Color? binColor;   // for colorBin
  final String? svgString; // for svg

  const SymbolWidgetData({
    required this.style,
    this.code,
    this.text,
    this.subText,
    this.binColor,
    this.svgString,
  });
}

Widget buildSymbolWidget(SymbolWidgetData data, Color primaryColor,
    {double size = 52}) {
  switch (data.style) {
    case SymbolStyle.plasticCode:
      return SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _PlasticCodePainter(
            code: data.code!,
            color: primaryColor,
          ),
        ),
      );

    case SymbolStyle.weee:
      return SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _WeeePainter(color: primaryColor),
        ),
      );

    case SymbolStyle.mobius:
      return SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _MobiusPainter(color: primaryColor),
        ),
      );

    case SymbolStyle.mobiusPercent:
      return SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: Size(size, size),
              painter: _MobiusPainter(color: primaryColor, strokeRatio: 0.065),
            ),
            Text(
              data.text ?? '%',
              style: TextStyle(
                fontSize: size * 0.22,
                fontWeight: FontWeight.w900,
                color: primaryColor,
              ),
            ),
          ],
        ),
      );

    case SymbolStyle.textBadge:
      // CE, FCC, RoHS, FDA, CCC etc. — bold text in specific style
      return SizedBox(
        width: size,
        height: size,
        child: Center(
          child: FittedBox(
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    data.text!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: data.text!.length <= 2
                          ? size * 0.38
                          : size * 0.26,
                      fontWeight: FontWeight.w900,
                      color: primaryColor,
                      letterSpacing: data.text!.length <= 3 ? 1.5 : 0.5,
                      height: 1.1,
                    ),
                  ),
                  if (data.subText != null)
                    Text(
                      data.subText!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: size * 0.17,
                        fontWeight: FontWeight.w600,
                        color: primaryColor.withValues(alpha: 0.7),
                        height: 1.1,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );

    case SymbolStyle.certBadge:
      // Circle outline with text inside (UL, GS style)
      return SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: size * 0.92,
              height: size * 0.92,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: primaryColor, width: size * 0.065),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  data.text!,
                  style: TextStyle(
                    fontSize: size * 0.30,
                    fontWeight: FontWeight.w900,
                    color: primaryColor,
                    height: 1.0,
                  ),
                ),
                if (data.subText != null)
                  Text(
                    data.subText!,
                    style: TextStyle(
                      fontSize: size * 0.15,
                      fontWeight: FontWeight.w700,
                      color: primaryColor.withValues(alpha: 0.75),
                    ),
                  ),
              ],
            ),
          ],
        ),
      );

    case SymbolStyle.colorBin:
      return SizedBox(
        width: size,
        height: size,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: size * 0.55,
              height: size * 0.55,
              padding: EdgeInsets.all(size * 0.09),
              decoration: BoxDecoration(
                color: data.binColor ?? primaryColor,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                    color: (data.binColor ?? primaryColor)
                        .withValues(alpha: 0.5),
                    width: 1.5),
              ),
              child: SvgPicture.string(
                _svgTrashBin,
                colorFilter: const ColorFilter.mode(
                  Colors.white,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ],
        ),
      );

    case SymbolStyle.svg:
      return SizedBox(
        width: size,
        height: size,
        child: SvgPicture.string(
          data.svgString!,
          width: size,
          height: size,
          colorFilter: ColorFilter.mode(primaryColor, BlendMode.srcIn),
        ),
      );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// DATA MODEL
// ══════════════════════════════════════════════════════════════════════════════

enum SymbolTag {
  recycle,
  organic,
  other,
  hazardous,
  safe,
  caution,
  danger,
  medical,
  electronic,
  bio,
  forest,
  noLitter,
  fee,
  metal,
  glass,
  paper,
  certification,
  food,
  shipping,
}

class WasteSymbol {
  final String title;
  final String subtitle;
  final String description;
  final String section;
  final SymbolTag tag;
  final String tagLabel;
  final IconData icon; // fallback
  final Color color;
  final bool isVietnam;
  final String? badge;
  final SymbolWidgetData? symbolWidget;

  const WasteSymbol({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.section,
    required this.tag,
    required this.tagLabel,
    required this.icon,
    required this.color,
    this.isVietnam = false,
    this.badge,
    this.symbolWidget,
  });
}

// ══════════════════════════════════════════════════════════════════════════════
// COLOR HELPERS
// ══════════════════════════════════════════════════════════════════════════════

Color _tagColor(SymbolTag tag) {
  switch (tag) {
    case SymbolTag.recycle:      return const Color(0xFF1565C0);
    case SymbolTag.organic:      return const Color(0xFF2E7D32);
    case SymbolTag.other:        return const Color(0xFFE65100);
    case SymbolTag.hazardous:    return const Color(0xFFC62828);
    case SymbolTag.safe:         return const Color(0xFF1565C0);
    case SymbolTag.caution:      return const Color(0xFFF57F17);
    case SymbolTag.danger:       return const Color(0xFFC62828);
    case SymbolTag.medical:      return const Color(0xFF6A1B9A);
    case SymbolTag.electronic:   return const Color(0xFF4A148C);
    case SymbolTag.bio:          return const Color(0xFF1B5E20);
    case SymbolTag.forest:       return const Color(0xFF33691E);
    case SymbolTag.noLitter:     return const Color(0xFF00695C);
    case SymbolTag.fee:          return const Color(0xFF37474F);
    case SymbolTag.metal:        return const Color(0xFF37474F);
    case SymbolTag.glass:        return const Color(0xFF0277BD);
    case SymbolTag.paper:        return const Color(0xFF4E342E);
    case SymbolTag.certification:return const Color(0xFF1A237E);
    case SymbolTag.food:         return const Color(0xFF2E7D32);
    case SymbolTag.shipping:     return const Color(0xFF4E342E);
  }
}

Color _tagBg(SymbolTag tag) => _tagColor(tag).withValues(alpha: 0.10);

// ══════════════════════════════════════════════════════════════════════════════
// SECTIONS
// ══════════════════════════════════════════════════════════════════════════════

const List<Map<String, dynamic>> _sections = [
  {
    'key': 'vn_classify',
    'title': 'Phân loại rác tại Việt Nam',
    'subtitle': 'Theo Luật Bảo vệ Môi trường 2020 (hiệu lực từ 1/1/2025)',
    'flag': '🇻🇳',
  },
  {
    'key': 'vn_bins',
    'title': 'Màu sắc thùng rác tại Việt Nam',
    'subtitle': 'Theo Thông tư Bộ Y tế & thực tế phổ biến',
    'flag': '🇻🇳',
  },
  {
    'key': 'intl_eco',
    'title': 'Ký hiệu môi trường & tái chế quốc tế',
    'subtitle': 'Thường thấy trên bao bì sản phẩm trong & ngoài nước',
    'flag': '🌍',
  },
  {
    'key': 'plastic_codes',
    'title': 'Mã nhựa quốc tế (Số 1–7)',
    'subtitle': 'Resin Identification Codes – in dưới đáy đồ nhựa',
    'flag': '🌍',
  },
  {
    'key': 'material_codes',
    'title': 'Mã vật liệu bao bì quốc tế',
    'subtitle': 'ISO 1043 / EU 97/129/EC – giấy, thủy tinh, kim loại',
    'flag': '🌍',
  },
  {
    'key': 'certification',
    'title': 'Chứng nhận an toàn & chất lượng',
    'subtitle': 'CE, FCC, UL, RoHS, CSA, TÜV, CCC, FDA, Energy Star…',
    'flag': '🌍',
  },
  {
    'key': 'food_symbols',
    'title': 'Ký hiệu an toàn thực phẩm & bao bì',
    'subtitle': 'Food Grade, Microwave Safe, Freezer Safe, BPA Free…',
    'flag': '🌍',
  },
  {
    'key': 'shipping',
    'title': 'Ký hiệu vận chuyển & bảo quản hàng hóa',
    'subtitle': 'Fragile, Keep Dry, This Way Up, Handle with Care…',
    'flag': '🌍',
  },
];

// ══════════════════════════════════════════════════════════════════════════════
// ALL SYMBOLS
// ══════════════════════════════════════════════════════════════════════════════

const List<WasteSymbol> _symbols = [

  // ══ NHÓM 1: Phân loại rác Việt Nam ══════════════════════════════════════════

  WasteSymbol(
    section: 'vn_classify',
    title: 'Rác có thể tái sử dụng, tái chế',
    subtitle: 'Nhóm 1 – Luật BVMT 2020, Điều 75',
    description:
        'Đây là nhóm rác có giá trị nhất, cần phân loại riêng để đưa vào quy trình tái chế.\n\n'
        'Bao gồm:\n'
        '• Giấy: báo, tạp chí, sách cũ, giấy văn phòng, hộp carton, bìa cứng\n'
        '• Nhựa cứng: chai PET (nước suối, nước ngọt), hộp HDPE (sữa, dầu gội), hộp PP (sữa chua, hộp cơm)\n'
        '• Kim loại: lon nhôm (bia, nước ngọt), lon sắt (đồ hộp)\n'
        '• Thủy tinh: chai lọ thủy tinh sạch\n'
        '• Vải & quần áo còn dùng được\n\n'
        'Lưu ý: Rửa sạch, để khô trước khi bỏ. Hộp sữa Tetra Pak cũng là rác tái chế. Giấy bẩn dính dầu mỡ thì không tái chế được.',
    tag: SymbolTag.recycle,
    tagLabel: 'Tái chế',
    icon: Icons.recycling_rounded,
    color: Color(0xFF1565C0),
    isVietnam: true,
    badge: '🇻🇳',
    symbolWidget: SymbolWidgetData(
      style: SymbolStyle.mobius,
    ),
  ),

  WasteSymbol(
    section: 'vn_classify',
    title: 'Rác thực phẩm (rác hữu cơ)',
    subtitle: 'Nhóm 2 – chiếm ~60–70% rác sinh hoạt VN',
    description:
        'Rác có nguồn gốc sinh học, phân hủy tự nhiên và có thể tái tạo thành phân bón hoặc biogas.\n\n'
        'Bao gồm:\n'
        '• Thức ăn thừa, cơm nguội, canh thừa\n'
        '• Vỏ trái cây, rau củ hư hỏng\n'
        '• Bã cà phê, bã trà, vỏ trứng\n'
        '• Hoa tươi đã héo\n'
        '• Cỏ cây, lá khô trong vườn\n\n'
        'KHÔNG bỏ rác hữu cơ chung với rác tái chế — thức ăn bám vào giấy/nhựa khiến chúng không tái chế được.',
    tag: SymbolTag.organic,
    tagLabel: 'Hữu cơ',
    icon: Icons.eco_rounded,
    color: Color(0xFF2E7D32),
    isVietnam: true,
    badge: '🇻🇳',
    symbolWidget: SymbolWidgetData(
      style: SymbolStyle.svg,
      svgString: _svgLeaf,
    ),
  ),

  WasteSymbol(
    section: 'vn_classify',
    title: 'Rác sinh hoạt khác (vô cơ)',
    subtitle: 'Nhóm 3 – rác không tái chế, không phân hủy',
    description:
        'Rác không tái chế được và phân hủy rất chậm, phải đưa đến bãi chôn lấp hoặc lò đốt.\n\n'
        'Bao gồm:\n'
        '• Túi nylon bẩn, màng nhựa mỏng dính thức ăn\n'
        '• Tã giấy, băng vệ sinh đã qua sử dụng\n'
        '• Sành sứ, gốm vỡ; xương động vật lớn\n'
        '• Tàn thuốc lá, giấy ăn đã dùng\n'
        '• Hộp xốp EPS bẩn (hộp cơm, cốc mì đã dùng)\n\n'
        'Tỷ lệ rác nhóm này càng thấp → việc phân loại của bạn càng hiệu quả.',
    tag: SymbolTag.other,
    tagLabel: 'Vô cơ',
    icon: Icons.delete_outline_rounded,
    color: Color(0xFFE65100),
    isVietnam: true,
    badge: '🇻🇳',
    symbolWidget: SymbolWidgetData(
      style: SymbolStyle.svg,
      svgString: _svgTrashBin,
    ),
  ),

  WasteSymbol(
    section: 'vn_classify',
    title: 'Chất thải nguy hại sinh hoạt',
    subtitle: 'Nhóm 4 – tuyệt đối không bỏ vào thùng rác thường',
    description:
        'Chứa hóa chất độc hại có thể gây bệnh hoặc ô nhiễm đất, nước, không khí nghiêm trọng.\n\n'
        'Bao gồm:\n'
        '• Pin, ắc quy (chứa chì, thủy ngân, cadmium)\n'
        '• Bóng đèn huỳnh quang CFL — chứa thủy ngân\n'
        '• Thuốc quá hạn, hóa chất tẩy rửa đậm đặc\n'
        '• Thuốc trừ sâu, dầu nhớt xe cũ\n'
        '• Sơn, dung môi, nhiệt kế thủy ngân vỡ\n\n'
        'Cách xử lý: Đưa đến điểm thu gom chất thải nguy hại của UBND phường/xã hoặc hộp thu pin tại siêu thị.',
    tag: SymbolTag.hazardous,
    tagLabel: 'Nguy hại',
    icon: Icons.warning_amber_rounded,
    color: Color(0xFFC62828),
    isVietnam: true,
    badge: '🇻🇳',
    symbolWidget: SymbolWidgetData(
      style: SymbolStyle.svg,
      svgString: _svgHazard,
    ),
  ),

  // ══ NHÓM 2: Màu thùng rác VN ════════════════════════════════════════════════

  WasteSymbol(
    section: 'vn_bins',
    title: 'Thùng xanh lá / xanh dương',
    subtitle: 'Rác sinh hoạt thông thường – phổ biến nhất',
    description:
        'Màu thùng rác phổ biến nhất tại Việt Nam, thường thấy trên vỉa hè, trong nhà dân, chung cư, trường học.\n\n'
        'Chứa: Rác sinh hoạt chung chưa phân loại (nơi chưa triển khai phân loại), hoặc rác tái chế (nơi đã thí điểm).\n\n'
        'Dung tích thường gặp: 20L (hộ gia đình nhỏ), 120L–240L (văn phòng, nhà hàng), 660L (công cộng).\n\n'
        '⚠️ Màu sắc thùng rác chưa đồng bộ toàn quốc — luôn đọc nhãn dán trên thùng tại khu vực bạn.',
    tag: SymbolTag.recycle,
    tagLabel: 'Phổ biến',
    icon: Icons.delete_rounded,
    color: Color(0xFF1B5E20),
    isVietnam: true,
    badge: '🇻🇳',
    symbolWidget: SymbolWidgetData(
      style: SymbolStyle.colorBin,
      binColor: Color(0xFF2E7D32),
    ),
  ),

  WasteSymbol(
    section: 'vn_bins',
    title: 'Thùng cam / vàng cam',
    subtitle: 'Rác vô cơ không tái chế được',
    description:
        'Thùng màu cam chứa rác vô cơ không tái chế — đưa đến bãi chôn lấp.\n\n'
        'Chứa: Túi nylon bẩn, tã giấy, băng vệ sinh, sành sứ vỡ, xương lớn, tàn thuốc, mút xốp bẩn.\n\n'
        'Ở một số địa phương, màu cam cũng dùng cho rác y tế không lây nhiễm.',
    tag: SymbolTag.other,
    tagLabel: 'Vô cơ',
    icon: Icons.delete_sweep_rounded,
    color: Color(0xFFE65100),
    isVietnam: true,
    badge: '🇻🇳',
    symbolWidget: SymbolWidgetData(
      style: SymbolStyle.colorBin,
      binColor: Color(0xFFE65100),
    ),
  ),

  WasteSymbol(
    section: 'vn_bins',
    title: 'Thùng vàng',
    subtitle: 'Rác thải y tế lây nhiễm – Thông tư 20/2021/TT-BYT',
    description:
        'Theo quy định của Bộ Y tế Việt Nam, thùng vàng chuyên dùng cho rác thải y tế có khả năng lây nhiễm.\n\n'
        'Chứa: Kim tiêm đã dùng, bơm tiêm, băng gạc vết thương, khẩu trang y tế, vật liệu phẫu thuật có dính máu/dịch cơ thể.\n\n'
        'Chỉ thấy ở: Bệnh viện, phòng khám, cơ sở y tế. Không dùng trong sinh hoạt hàng ngày.\n\n'
        'Kim tiêm tại nhà (người tiểu đường tự tiêm) cần đựng trong hộp vật sắc nhọn chuyên dụng.',
    tag: SymbolTag.medical,
    tagLabel: 'Y tế',
    icon: Icons.local_hospital_rounded,
    color: Color(0xFFF57F17),
    isVietnam: true,
    badge: '🇻🇳',
    symbolWidget: SymbolWidgetData(
      style: SymbolStyle.colorBin,
      binColor: Color(0xFFF9A825),
    ),
  ),

  WasteSymbol(
    section: 'vn_bins',
    title: 'Thùng trắng',
    subtitle: 'Rác có thể tái chế (vật liệu sạch)',
    description:
        'Thùng trắng dành cho rác tái chế sạch.\n\n'
        'Chứa: Giấy sạch, bìa carton, chai nhựa sạch, lon kim loại, chai lọ thủy tinh.\n\n'
        'Thực tế tại VN: Thùng trắng còn rất ít phổ biến. Hầu hết rác tái chế được thu gom bởi ve chai/đồng nát. Với quy định bắt buộc từ 2025, thùng tái chế dần xuất hiện nhiều hơn.',
    tag: SymbolTag.recycle,
    tagLabel: 'Tái chế',
    icon: Icons.recycling_rounded,
    color: Color(0xFF455A64),
    isVietnam: true,
    badge: '🇻🇳',
    symbolWidget: SymbolWidgetData(
      style: SymbolStyle.colorBin,
      binColor: Color(0xFF90A4AE),
    ),
  ),

  WasteSymbol(
    section: 'vn_bins',
    title: 'Thùng đen',
    subtitle: 'Chất thải đặc biệt nguy hại',
    description:
        'Thùng đen dùng cho chất thải đặc biệt nguy hại, không lây nhiễm sinh học nhưng độc hại hóa học hoặc phóng xạ.\n\n'
        'Chứa: Chất thải phóng xạ, hóa chất độc tế bào, dung môi công nghiệp, chất thải phòng thí nghiệm.\n\n'
        'Người dân bình thường rất hiếm gặp. Thường ở: trung tâm nghiên cứu, bệnh viện chuyên khoa, phòng thí nghiệm.',
    tag: SymbolTag.hazardous,
    tagLabel: 'Đặc biệt',
    icon: Icons.dangerous_rounded,
    color: Color(0xFF212121),
    isVietnam: true,
    badge: '🇻🇳',
    symbolWidget: SymbolWidgetData(
      style: SymbolStyle.colorBin,
      binColor: Color(0xFF212121),
    ),
  ),

  // ══ NHÓM 3: Ký hiệu môi trường quốc tế ══════════════════════════════════════

  WasteSymbol(
    section: 'intl_eco',
    title: 'Vòng lặp Möbius (♻)',
    subtitle: 'Ký hiệu tái chế phổ biến nhất thế giới',
    description:
        'Ba mũi tên xanh tạo thành tam giác khép kín — thiết kế năm 1970 bởi Gary Anderson (Mỹ).\n\n'
        'Ý nghĩa thực sự: Bao bì CÓ THỂ tái chế — KHÔNG phải đã được làm từ vật liệu tái chế, và không đảm bảo sẽ được tái chế.\n\n'
        'Ký hiệu này không có bản quyền, ai cũng có thể dùng — nên đôi khi bị in sai trên bao bì không thực sự tái chế được.',
    tag: SymbolTag.recycle,
    tagLabel: 'Tái chế',
    icon: Icons.recycling_rounded,
    color: Color(0xFF1565C0),
    badge: '🌍',
    symbolWidget: SymbolWidgetData(style: SymbolStyle.mobius),
  ),

  WasteSymbol(
    section: 'intl_eco',
    title: 'Möbius Loop có số %',
    subtitle: 'Tỷ lệ vật liệu tái chế đã dùng trong sản phẩm',
    description:
        'Biến thể của ký hiệu Möbius với số phần trăm (30%, 50%, 100%) ở giữa tam giác.\n\n'
        'Ý nghĩa: % cho biết bao nhiêu vật liệu cấu thành bao bì ĐÃ được làm từ vật liệu tái chế.\n\n'
        'Ví dụ: "50% Recycled" = nửa lượng nhựa làm chai đó lấy từ nhựa cũ đã tái chế.',
    tag: SymbolTag.recycle,
    tagLabel: 'Vật liệu tái chế',
    icon: Icons.recycling_rounded,
    color: Color(0xFF1565C0),
    badge: '🌍',
    symbolWidget: SymbolWidgetData(
        style: SymbolStyle.mobiusPercent, text: '30%'),
  ),

  WasteSymbol(
    section: 'intl_eco',
    title: 'Tidyman – Người ném rác vào thùng',
    subtitle: 'Nhắc nhở không xả rác bừa bãi',
    description:
        'Hình người cầm rác và ném vào thùng. KHÔNG phải ký hiệu tái chế — chỉ nhắc: "Hãy bỏ rác đúng chỗ".\n\n'
        'Nhãn hiệu của tổ chức Keep Britain Tidy (Anh), được cấp phép cho hơn 100 quốc gia.\n\n'
        'Thường thấy ở VN trên: Gói snack, kẹo, nước giải khát, hàng tiêu dùng nhanh (FMCG).',
    tag: SymbolTag.noLitter,
    tagLabel: 'Không xả rác',
    icon: Icons.delete_outline_rounded,
    color: Color(0xFF00695C),
    badge: '🌍',
    symbolWidget: SymbolWidgetData(
      style: SymbolStyle.svg,
      svgString: _svgTidyman,
    ),
  ),

  WasteSymbol(
    section: 'intl_eco',
    title: 'Green Dot – Chấm xanh đôi',
    subtitle: 'Nhà sản xuất đã đóng phí thu gom (châu Âu)',
    description:
        'Hai vòng tròn lồng vào nhau màu xanh lá và xanh dương — ký hiệu THƯỜNG GÂY NHẦM LẪN nhất.\n\n'
        'Ý nghĩa thực sự: Nhà sản xuất đã đóng phí vào hệ thống thu gom & tái chế bao bì châu Âu (EPR). KHÔNG có nghĩa là bao bì tái chế được.\n\n'
        'Sở hữu bởi PRO Europe, có mặt ở hơn 30 nước châu Âu. Tại VN chỉ gặp trên hàng nhập khẩu từ EU.',
    tag: SymbolTag.fee,
    tagLabel: 'Phí EPR',
    icon: Icons.fiber_manual_record_rounded,
    color: Color(0xFF2E7D32),
    badge: '🌍',
    symbolWidget: SymbolWidgetData(
      style: SymbolStyle.textBadge,
      text: 'Green\nDot',
    ),
  ),

  WasteSymbol(
    section: 'intl_eco',
    title: 'WEEE – Thùng rác gạch chéo',
    subtitle: 'Rác thải điện tử – KHÔNG bỏ vào thùng thường',
    description:
        'Hình thùng rác có gạch chéo và thanh ngang bên dưới. Bắt buộc theo Chỉ thị WEEE của EU.\n\n'
        'Ý nghĩa: Sản phẩm PHẢI thu gom riêng — KHÔNG được vứt vào thùng rác sinh hoạt.\n\n'
        'Lý do: Thiết bị điện tử chứa chì (Pb), thủy ngân (Hg), cadmium (Cd) — nếu chôn lấp sai sẽ thấm vào đất và nước ngầm.\n\n'
        'Thường thấy trên: Điện thoại, laptop, TV, pin, bóng đèn LED/huỳnh quang, thiết bị gia dụng.\n\n'
        'Tại VN: Từ 2025 EPR bắt buộc. Điện Máy Xanh, FPT Shop có điểm thu gom điện tử cũ.',
    tag: SymbolTag.electronic,
    tagLabel: 'Rác điện tử',
    icon: Icons.devices_other_rounded,
    color: Color(0xFF4A148C),
    badge: '🌍',
    symbolWidget: SymbolWidgetData(style: SymbolStyle.weee),
  ),

  WasteSymbol(
    section: 'intl_eco',
    title: 'Seedling – Phân hủy công nghiệp',
    subtitle: 'OK Compost Industrial / EN 13432 (TÜV Austria)',
    description:
        'Hình mầm cây với ngôi sao — của tổ chức TÜV Austria (logo OK Compost Industrial).\n\n'
        'Ý nghĩa: Bao bì phân hủy sinh học HOÀN TOÀN — nhưng CHỈ trong điều kiện ủ phân CÔNG NGHIỆP: ~58°C, vi sinh vật chuyên dụng, 12 tuần.\n\n'
        'KHÔNG ủ tại nhà được. Tại VN hạ tầng ủ công nghiệp gần như chưa có → thực tế vẫn bị chôn lấp.',
    tag: SymbolTag.bio,
    tagLabel: 'Phân hủy CN',
    icon: Icons.grass_rounded,
    color: Color(0xFF1B5E20),
    badge: '🌍',
    symbolWidget: SymbolWidgetData(
      style: SymbolStyle.svg,
      svgString: _svgSeedling,
    ),
  ),

  WasteSymbol(
    section: 'intl_eco',
    title: 'Home Compost – Ủ phân tại nhà',
    subtitle: 'OK Compost Home – phân hủy ở nhiệt độ phòng',
    description:
        'Biến thể của Seedling, phân hủy hoàn toàn tại thùng ủ gia đình trong 12 tháng ở nhiệt độ thường.\n\n'
        'Khác Seedling CN: Ủ tại nhà được, điều kiện đơn giản hơn.\n\n'
        'Tại VN: Phong trào ủ phân rác hữu cơ tại nhà (compost bucket, bokashi) đang dần phát triển ở thành phố lớn.',
    tag: SymbolTag.bio,
    tagLabel: 'Ủ phân nhà',
    icon: Icons.yard_rounded,
    color: Color(0xFF33691E),
    badge: '🌍',
    symbolWidget: SymbolWidgetData(
      style: SymbolStyle.svg,
      svgString: _svgSeedling,
    ),
  ),

  WasteSymbol(
    section: 'intl_eco',
    title: 'FSC – Rừng được quản lý bền vững',
    subtitle: 'Forest Stewardship Council',
    description:
        'Logo FSC: hình cây và ngôi sao 8 cánh. KHÔNG phải ký hiệu tái chế — chứng nhận về NGUỒN GỐC nguyên liệu.\n\n'
        'Giấy/gỗ đến từ rừng được quản lý có trách nhiệm — không phá rừng, bảo vệ đa dạng sinh học.\n\n'
        '3 loại:\n'
        '• FSC 100%: Toàn bộ từ rừng được chứng nhận\n'
        '• FSC Recycled: Toàn bộ từ vật liệu tái chế\n'
        '• FSC Mix: Hỗn hợp\n\n'
        'Thường thấy trên hộp giấy, carton, khăn giấy, sách vở, đồ gỗ.',
    tag: SymbolTag.forest,
    tagLabel: 'Rừng bền vững',
    icon: Icons.park_rounded,
    color: Color(0xFF33691E),
    badge: '🌍',
    symbolWidget: SymbolWidgetData(
      style: SymbolStyle.textBadge,
      text: 'FSC',
      subText: 'Certified',
    ),
  ),

  WasteSymbol(
    section: 'intl_eco',
    title: 'PEFC – Chứng nhận rừng bền vững',
    subtitle: 'Programme for Endorsement of Forest Certification',
    description:
        'Tổ chức chứng nhận rừng bền vững lớn nhất thế giới (tương tự FSC, phổ biến hơn ở châu Âu & châu Á).\n\n'
        'PEFC linh hoạt hơn FSC, chấp nhận rừng trồng sản xuất theo tiêu chuẩn từng quốc gia.\n\n'
        'Gặp trên bao bì nhập khẩu từ châu Âu, Nhật, Australia. Ít phổ biến hơn FSC tại VN.',
    tag: SymbolTag.forest,
    tagLabel: 'Rừng bền vững',
    icon: Icons.forest_rounded,
    color: Color(0xFF2E7D32),
    badge: '🌍',
    symbolWidget: SymbolWidgetData(
      style: SymbolStyle.textBadge,
      text: 'PEFC',
      subText: 'Certified',
    ),
  ),

  WasteSymbol(
    section: 'intl_eco',
    title: 'Nhãn xanh Việt Nam',
    subtitle: 'Vietnam Green Label – Bộ Tài nguyên Môi trường',
    description:
        'Nhãn sinh thái chính thức của Việt Nam, Bộ TN&MT cấp cho sản phẩm thân thiện môi trường.\n\n'
        'Tiêu chí: Giảm năng lượng, giảm phát thải, không chứa chất độc hại, có thể tái chế hoặc phân hủy.\n\n'
        'Áp dụng cho: Sơn tường, pin, thiết bị điện tử, sản phẩm văn phòng, vật liệu xây dựng.\n\n'
        'Chưa phổ biến rộng rãi với người tiêu dùng — ít thấy trên hàng siêu thị thông thường.',
    tag: SymbolTag.bio,
    tagLabel: 'VN Green',
    icon: Icons.verified_rounded,
    color: Color(0xFF2E7D32),
    isVietnam: true,
    badge: '🇻🇳',
    symbolWidget: SymbolWidgetData(
      style: SymbolStyle.svg,
      svgString: _svgLeaf,
    ),
  ),

  // ══ NHÓM 4: Mã nhựa 1–7 ═════════════════════════════════════════════════════

  WasteSymbol(
    section: 'plastic_codes',
    title: 'Nhựa số 1 – PET / PETE',
    subtitle: 'Polyethylene Terephthalate',
    description:
        'Nhựa trong suốt, nhẹ, cứng vừa. Số "1" trong tam giác tái chế ở đáy sản phẩm.\n\n'
        'Chịu nhiệt: Tối đa ~70°C — KHÔNG đựng nước nóng hoặc để dưới nắng lâu.\n\n'
        'Dùng cho: Chai nước suối, nước ngọt, dầu ăn, hộp thực phẩm trong suốt, khay thực phẩm siêu thị.\n\n'
        'An toàn & tái chế: An toàn dùng 1 lần. Tái chế tốt nhất trong các loại nhựa — chai PET được thu mua cao nhất bởi ve chai VN.\n\n'
        'Không tái sử dụng nhiều lần vì vết nứt vi mô tích tụ vi khuẩn.',
    tag: SymbolTag.safe,
    tagLabel: 'An toàn',
    icon: Icons.water_drop_outlined,
    color: Color(0xFF1565C0),
    badge: '🌍',
    symbolWidget: SymbolWidgetData(
        style: SymbolStyle.plasticCode, code: 1),
  ),

  WasteSymbol(
    section: 'plastic_codes',
    title: 'Nhựa số 2 – HDPE',
    subtitle: 'High-Density Polyethylene – tỷ trọng cao',
    description:
        'Nhựa cứng, chắc, thường trắng đục. Chịu nhiệt đến ~110°C.\n\n'
        'Dùng cho: Bình sữa, can nước sạch, chai dầu gội/sữa tắm/nước giặt, thùng nhựa gia dụng, ống nước.\n\n'
        'AN TOÀN NHẤT để tái sử dụng — không tiết hóa chất độc hại.\n\n'
        'Tái chế: Rất tốt — được hầu hết cơ sở tái chế chấp nhận. Tái chế thành ống nhựa, đồ nội thất ngoài trời, thùng rác.',
    tag: SymbolTag.safe,
    tagLabel: 'An toàn nhất',
    icon: Icons.local_drink_outlined,
    color: Color(0xFF0D47A1),
    badge: '🌍',
    symbolWidget: SymbolWidgetData(
        style: SymbolStyle.plasticCode, code: 2),
  ),

  WasteSymbol(
    section: 'plastic_codes',
    title: 'Nhựa số 3 – PVC',
    subtitle: 'Polyvinyl Chloride',
    description:
        'Nhựa cứng hoặc mềm dẻo. Chịu nhiệt kém, tối đa ~81°C.\n\n'
        'Dùng cho: Ống nước PVC (xây dựng), vỏ dây điện, màng bọc thực phẩm mềm, đồ chơi cũ, cửa nhựa.\n\n'
        'NGUY HẠI NHẤT: Chứa phthalate (rối loạn nội tiết). Khi đốt giải phóng dioxin — chất cực độc.\n\n'
        'Tái chế: Rất kém — hầu hết cơ sở từ chối. Bị cấm hoặc hạn chế trong bao bì thực phẩm tại EU.\n\n'
        'KHÔNG đựng thực phẩm nóng trong bao bì PVC.',
    tag: SymbolTag.danger,
    tagLabel: 'Nguy hại',
    icon: Icons.warning_rounded,
    color: Color(0xFFB71C1C),
    badge: '🌍',
    symbolWidget: SymbolWidgetData(
        style: SymbolStyle.plasticCode, code: 3),
  ),

  WasteSymbol(
    section: 'plastic_codes',
    title: 'Nhựa số 4 – LDPE',
    subtitle: 'Low-Density Polyethylene – tỷ trọng thấp',
    description:
        'Nhựa mỏng, mềm dẻo. An toàn ở nhiệt độ thường — KHÔNG dùng lò vi sóng.\n\n'
        'Dùng cho: Túi nylon mua sắm, màng bọc thực phẩm wrap, vỏ bánh kẹo/mì gói, ống tuýp mềm (kem đánh răng, kem dưỡng).\n\n'
        'Tái chế: KHÓ — quá mỏng, dễ kẹt máy phân loại. Hầu hết điểm tái chế không chấp nhận.\n\n'
        'Vấn đề MT: Túi nylon LDPE là nguồn chính của ô nhiễm vi nhựa đại dương và rác thải nhựa đường phố VN.',
    tag: SymbolTag.caution,
    tagLabel: 'Thận trọng',
    icon: Icons.shopping_bag_outlined,
    color: Color(0xFFF57F17),
    badge: '🌍',
    symbolWidget: SymbolWidgetData(
        style: SymbolStyle.plasticCode, code: 4),
  ),

  WasteSymbol(
    section: 'plastic_codes',
    title: 'Nhựa số 5 – PP',
    subtitle: 'Polypropylene',
    description:
        'Nhựa cứng hoặc bán cứng, đục mờ. Chịu nhiệt tốt hơn 160°C.\n\n'
        'Dùng cho: Hộp sữa chua, hộp cơm bento, ống hút, nắp chai, lọ thuốc, thùng Tupperware/Lock&Lock, xô chậu, ghế nhựa.\n\n'
        'AN TOÀN — loại nhựa được khuyên dùng cho thực phẩm. Có thể đựng thức ăn nóng và dùng lò vi sóng (chỉ hộp có ký hiệu lò vi sóng).\n\n'
        'Tái chế: Tốt về lý thuyết, nhưng tỷ lệ thu gom tại VN còn thấp.',
    tag: SymbolTag.safe,
    tagLabel: 'An toàn',
    icon: Icons.takeout_dining_outlined,
    color: Color(0xFF1B5E20),
    badge: '🌍',
    symbolWidget: SymbolWidgetData(
        style: SymbolStyle.plasticCode, code: 5),
  ),

  WasteSymbol(
    section: 'plastic_codes',
    title: 'Nhựa số 6 – PS / EPS',
    subtitle: 'Polystyrene & Xốp EPS (hộp xốp)',
    description:
        'PS cứng, giòn và EPS (xốp trắng phồng). Chịu nhiệt kém.\n\n'
        'Dùng cho: Hộp xốp đựng cơm mang về, cốc mì ăn liền, đĩa dùng 1 lần, hộp trứng, xốp chèn hàng.\n\n'
        'ĐÁNG LO NGẠI: Khi gặp nhiệt độ cao, PS giải phóng styrene — chất nghi gây ung thư.\n\n'
        'KHÔNG đựng cơm/thức ăn nóng trong hộp xốp!\n\n'
        'Tái chế: Cực kỳ khó — thể tích lớn, khối lượng siêu nhỏ. TP.HCM & Hà Nội đang vận động giảm dùng.',
    tag: SymbolTag.danger,
    tagLabel: 'Nguy hại',
    icon: Icons.lunch_dining_outlined,
    color: Color(0xFFC62828),
    badge: '🌍',
    symbolWidget: SymbolWidgetData(
        style: SymbolStyle.plasticCode, code: 6),
  ),

  WasteSymbol(
    section: 'plastic_codes',
    title: 'Nhựa số 7 – Other',
    subtitle: 'PC, ABS, PLA, BPA và các loại hỗn hợp',
    description:
        '"Các loại khác" — tất cả nhựa không thuộc 6 nhóm trên.\n\n'
        'Bao gồm:\n'
        '• Polycarbonate (PC): Bình nước thể thao cứng trong — có thể chứa BPA\n'
        '• ABS: Vỏ máy tính, điện thoại cũ, đồ chơi Lego\n'
        '• PLA (nhựa sinh học từ tinh bột ngô): Ống hút/dao muỗng "xanh" — KHÔNG tái chế chung với nhựa thường\n'
        '• Nhựa đa lớp multilayer: Gói mì ăn liền, bao bì snack — không tái chế\n\n'
        '⚠️ BPA trong nhựa PC gây rối loạn nội tiết — nguy hiểm với trẻ em & phụ nữ mang thai. Tìm sản phẩm "BPA-free".',
    tag: SymbolTag.caution,
    tagLabel: 'Hỗn hợp',
    icon: Icons.help_outline_rounded,
    color: Color(0xFF616161),
    badge: '🌍',
    symbolWidget: SymbolWidgetData(
        style: SymbolStyle.plasticCode, code: 7),
  ),

  // ══ NHÓM 5: Mã vật liệu bao bì ══════════════════════════════════════════════

  WasteSymbol(
    section: 'material_codes',
    title: 'PAP 20 – Carton gợn sóng',
    subtitle: 'Corrugated cardboard – thùng carton đóng gói hàng',
    description:
        'Mã PAP 20: Giấy cấu trúc gợn sóng ở giữa (thùng carton Shopee/Lazada).\n\n'
        'Nhận biết: Xé nhẹ mép thùng sẽ thấy lớp sóng bên trong.\n\n'
        'Tái chế rất tốt — được thu mua rộng rãi bởi ve chai tại VN, giá 1.000–2.500 đ/kg.\n\n'
        'Lưu ý: Tháo hết băng keo, ghim, xốp trước khi bỏ tái chế. Giữ khô — carton ướt mất giá trị.',
    tag: SymbolTag.paper,
    tagLabel: 'Giấy',
    icon: Icons.inventory_2_outlined,
    color: Color(0xFF4E342E),
    badge: '🌍',
    symbolWidget: SymbolWidgetData(
        style: SymbolStyle.textBadge, text: 'PAP\n20'),
  ),

  WasteSymbol(
    section: 'material_codes',
    title: 'PAP 21 – Bìa carton phẳng',
    subtitle: 'Non-corrugated cardboard – hộp giấy, hộp ngũ cốc',
    description:
        'Mã PAP 21: Bìa carton không có sóng, dùng làm hộp đựng sản phẩm.\n\n'
        'Thường thấy trên: Hộp ngũ cốc, hộp giày, hộp mỹ phẩm, hộp thuốc, hộp quà, hộp đựng điện thoại/laptop.\n\n'
        'Tái chế tốt khi sạch và khô. Hộp giấy dính dầu mỡ khó tái chế hơn.',
    tag: SymbolTag.paper,
    tagLabel: 'Giấy',
    icon: Icons.inbox_outlined,
    color: Color(0xFF4E342E),
    badge: '🌍',
    symbolWidget: SymbolWidgetData(
        style: SymbolStyle.textBadge, text: 'PAP\n21'),
  ),

  WasteSymbol(
    section: 'material_codes',
    title: 'PAP 22 – Giấy thông thường',
    subtitle: 'Paper – túi giấy, giấy in, báo, tạp chí',
    description:
        'Mã PAP 22: Giấy thông thường (không phải bìa cứng).\n\n'
        'Bao gồm: Túi giấy mua sắm, giấy in văn phòng, báo, tạp chí, giấy gói quà, giấy kraft nâu.\n\n'
        'Tái chế tốt khi sạch. Giấy tráng bóng/giấy ăn đã dùng không tái chế được.',
    tag: SymbolTag.paper,
    tagLabel: 'Giấy',
    icon: Icons.article_outlined,
    color: Color(0xFF5D4037),
    badge: '🌍',
    symbolWidget: SymbolWidgetData(
        style: SymbolStyle.textBadge, text: 'PAP\n22'),
  ),

  WasteSymbol(
    section: 'material_codes',
    title: 'GL 70 / 71 / 72 – Thủy tinh',
    subtitle: 'Glass – chai lọ phân theo màu',
    description:
        'Mã GL cho thủy tinh, phân theo màu:\n'
        '• GL 70: Thủy tinh KHÔNG MÀU (trong suốt)\n'
        '• GL 71: Thủy tinh XANH LÁ — chai bia, rượu vang\n'
        '• GL 72: Thủy tinh NÂU/HỔ PHÁCH — chai bia tối, nước mắm, dược phẩm\n\n'
        'Thủy tinh là vật liệu tái chế LÝ TƯỞNG NHẤT — 100% vô số lần không mất chất lượng. Tiết kiệm ~30% năng lượng.',
    tag: SymbolTag.glass,
    tagLabel: 'Thủy tinh',
    icon: Icons.wine_bar_outlined,
    color: Color(0xFF0277BD),
    badge: '🌍',
    symbolWidget: SymbolWidgetData(
        style: SymbolStyle.textBadge, text: 'GL\n70-72'),
  ),

  WasteSymbol(
    section: 'material_codes',
    title: 'ALU 41 – Nhôm',
    subtitle: 'Aluminium – lon nhôm, giấy bạc, khay nhôm',
    description:
        'Mã ALU 41: Bao bì và sản phẩm làm từ nhôm.\n\n'
        'Bao gồm: Lon nước ngọt/bia nhôm, giấy bạc bếp, khay nhôm, nắp nhôm chai lọ.\n\n'
        'Nhận biết: Nam châm KHÔNG hút nhôm (sắt thì có).\n\n'
        'Tái chế TUYỆT VỜI NHẤT — tiết kiệm 95% năng lượng so với nhôm nguyên sinh. Lon nhôm được thu mua GIÁ CAO NHẤT tại VN.',
    tag: SymbolTag.metal,
    tagLabel: 'Nhôm',
    icon: Icons.circle_outlined,
    color: Color(0xFF455A64),
    badge: '🌍',
    symbolWidget: SymbolWidgetData(
        style: SymbolStyle.textBadge, text: 'ALU\n41'),
  ),

  WasteSymbol(
    section: 'material_codes',
    title: 'FE 40 – Sắt / Thép',
    subtitle: 'Ferrous metal – lon thực phẩm, nắp kim loại từ tính',
    description:
        'Mã FE 40: Bao bì kim loại sắt/thép.\n\n'
        'Bao gồm: Lon cá hộp, thịt hộp, đậu hộp; nắp kim loại từ tính; hộp bánh/sữa bột thiếc.\n\n'
        'Nhận biết: Nam châm HÚT MẠNH sắt/thép (nhôm thì không bị hút).\n\n'
        'Tái chế tốt. Sắt phế liệu, lon đồ hộp được thu mua rộng rãi tại VN. Rửa sạch lon trước khi bỏ tái chế.',
    tag: SymbolTag.metal,
    tagLabel: 'Sắt thép',
    icon: Icons.settings_outlined,
    color: Color(0xFF37474F),
    badge: '🌍',
    symbolWidget: SymbolWidgetData(
        style: SymbolStyle.textBadge, text: 'FE\n40'),
  ),

  WasteSymbol(
    section: 'material_codes',
    title: 'C/PAP – Bao bì đa lớp (Tetra Pak)',
    subtitle: 'Composite – giấy + nhựa PE + nhôm',
    description:
        'Mã C/PAP cho bao bì đa vật liệu: giấy carton + lớp nhựa PE + lớp nhôm mỏng.\n\n'
        'Thường thấy trên: Hộp sữa Tetra Pak (Vinamilk, TH True Milk, Nestlé), nước trái cây, súp đóng gói.\n\n'
        'Tái chế PHỨC TẠP vì phải tách từng lớp. Chương trình "Vỏ hộp đổi quà" của Tetra Pak + Vinamilk thu gom tái chế tại trường học VN.',
    tag: SymbolTag.paper,
    tagLabel: 'Đa lớp',
    icon: Icons.layers_outlined,
    color: Color(0xFF795548),
    badge: '🌍',
    symbolWidget: SymbolWidgetData(
        style: SymbolStyle.textBadge, text: 'C/PAP'),
  ),

  // ══ NHÓM 6: Chứng nhận an toàn & chất lượng ══════════════════════════════════

  WasteSymbol(
    section: 'certification',
    title: 'CE – Conformité Européenne',
    subtitle: 'Bắt buộc cho tất cả sản phẩm điện tử bán tại EU',
    description:
        'Ký hiệu CE là lời cam kết của nhà sản xuất: sản phẩm tuân thủ tất cả yêu cầu về an toàn, sức khỏe và bảo vệ môi trường của Liên minh châu Âu.\n\n'
        'Đằng sau ký hiệu CE thường có 4 chữ số — mã số công ty chịu trách nhiệm kiểm tra.\n\n'
        'Áp dụng cho: Điện tử, đồ chơi, thiết bị y tế, máy móc, đèn, ổ cắm...\n\n'
        'Tại VN: Nhiều sản phẩm nhập khẩu từ EU hoặc xuất khẩu sang EU mang ký hiệu này. Đèn LED ENA Vietnam đã đạt tiêu chuẩn CE.\n\n'
        '⚠️ CE ≠ "China Export" — đây là lỗi hiểu sai phổ biến! CE là chứng nhận EU, không phải Trung Quốc.',
    tag: SymbolTag.certification,
    tagLabel: 'Bắt buộc EU',
    icon: Icons.verified_rounded,
    color: Color(0xFF1A237E),
    badge: '🌍',
    symbolWidget: SymbolWidgetData(
        style: SymbolStyle.textBadge, text: 'CE'),
  ),

  WasteSymbol(
    section: 'certification',
    title: 'FCC – Federal Communications Commission',
    subtitle: 'Bắt buộc cho thiết bị phát sóng radio bán tại Mỹ',
    description:
        'FCC là Ủy ban Truyền thông Liên Bang Mỹ. Bất kỳ thiết bị nào có khả năng phát sóng radio (WiFi, Bluetooth, 4G/5G) bán trên thị trường Mỹ và nhiều nước khác đều phải có chứng nhận này.\n\n'
        'Ý nghĩa: Mức sóng phát ra không quá cao, không gây hại sức khỏe, không can thiệp các thiết bị khác.\n\n'
        'Thường thấy trên: Smartphone, tablet, laptop, router WiFi, thiết bị Bluetooth, đồng hồ thông minh.',
    tag: SymbolTag.certification,
    tagLabel: 'Mỹ',
    icon: Icons.radio_outlined,
    color: Color(0xFF1A237E),
    badge: '🌍',
    symbolWidget: SymbolWidgetData(
        style: SymbolStyle.textBadge, text: 'FCC'),
  ),

  WasteSymbol(
    section: 'certification',
    title: 'RoHS – Restriction of Hazardous Substances',
    subtitle: 'Hạn chế chất độc hại trong thiết bị điện tử – EU',
    description:
        'Tiêu chuẩn châu Âu: Sản phẩm KHÔNG chứa các chất nguy hiểm như:\n'
        '• Chì (Pb), Thủy ngân (Hg), Cadmium (Cd)\n'
        '• Crôm lục hóa trị (Cr⁶⁺)\n'
        '• Polybrominated biphenyls (PBB), PBDE (chất chống cháy)\n\n'
        'Bắt buộc cho mọi thiết bị điện tử bán tại EU từ 2006. Không phải lúc nào cũng ghi rõ trên sản phẩm nhưng nhà sản xuất phải có giấy chứng nhận.\n\n'
        'Cũng thấy trên nhiều sản phẩm bán tại VN, Nhật, Hàn Quốc với tiêu chuẩn tương đương.',
    tag: SymbolTag.certification,
    tagLabel: 'EU',
    icon: Icons.block_rounded,
    color: Color(0xFF1A237E),
    badge: '🌍',
    symbolWidget: SymbolWidgetData(
        style: SymbolStyle.textBadge, text: 'RoHS'),
  ),

  WasteSymbol(
    section: 'certification',
    title: 'UL – Underwriters Laboratories',
    subtitle: 'Chứng nhận an toàn điện – Bắc Mỹ & Mexico',
    description:
        'UL (Underwriters Laboratories) — tổ chức kiểm định độc lập của Mỹ, có hơn 130 năm lịch sử.\n\n'
        'Ý nghĩa: Sản phẩm đã vượt qua kiểm tra nghiêm ngặt về an toàn điện, cháy nổ và mức độ nguy hiểm đối với con người.\n\n'
        'Thường thấy ở: Thiết bị điện gia dụng, ổ cắm, dây điện, thiết bị chiếu sáng, sạc điện thoại bán tại Bắc Mỹ và Mexico.',
    tag: SymbolTag.certification,
    tagLabel: 'Mỹ & Canada',
    icon: Icons.verified_user_rounded,
    color: Color(0xFF1A237E),
    badge: '🌍',
    symbolWidget: SymbolWidgetData(
        style: SymbolStyle.certBadge, text: 'UL'),
  ),

  WasteSymbol(
    section: 'certification',
    title: 'CSA – Canadian Standards Association',
    subtitle: 'Chứng nhận an toàn – Mỹ và Canada',
    description:
        'Hình chữ "SA" nằm trong lòng chữ "C" lớn, do CSA International chứng nhận.\n\n'
        'Ý nghĩa: Sản phẩm đáp ứng tiêu chuẩn an toàn của Canada và Mỹ — tương tự UL nhưng có giá trị đặc biệt tại Canada.\n\n'
        'Thường thấy trên: Thiết bị điện gia dụng, công cụ điện, vật liệu xây dựng, thiết bị khí đốt bán ở Mỹ và Canada.',
    tag: SymbolTag.certification,
    tagLabel: 'Canada & Mỹ',
    icon: Icons.verified_user_rounded,
    color: Color(0xFF1A237E),
    badge: '🌍',
    symbolWidget: SymbolWidgetData(
        style: SymbolStyle.certBadge, text: 'CSA'),
  ),

  WasteSymbol(
    section: 'certification',
    title: 'GS – Geprüfte Sicherheit (TÜV Rheinland)',
    subtitle: 'An toàn đã kiểm tra – tiêu chuẩn Đức',
    description:
        '"Geprüfte Sicherheit" (tiếng Đức) = "An toàn đã được kiểm tra". Cấp bởi TÜV Rheinland — tập đoàn kiểm định chất lượng uy tín nhất nước Đức.\n\n'
        'Ý nghĩa: Sản phẩm đã vượt qua các bài kiểm tra an toàn nghiêm ngặt của Đức, cao hơn tiêu chuẩn CE bắt buộc.\n\n'
        'Tuy chủ yếu dùng tại thị trường Đức, nhưng được các nhà sản xuất toàn cầu coi trọng vì độ chặt chẽ và tin cậy cao.\n\n'
        'Thường thấy trên: Công cụ điện, đèn chiếu sáng, thiết bị gia dụng, đồ chơi trẻ em xuất khẩu sang Đức/EU.',
    tag: SymbolTag.certification,
    tagLabel: 'Đức',
    icon: Icons.verified_user_rounded,
    color: Color(0xFF1A237E),
    badge: '🌍',
    symbolWidget: SymbolWidgetData(
        style: SymbolStyle.certBadge, text: 'GS'),
  ),

  WasteSymbol(
    section: 'certification',
    title: 'CCC – China Compulsory Certificate',
    subtitle: 'Chứng chỉ bắt buộc cho hàng Trung Quốc',
    description:
        'CCC (China Compulsory Certificate) — chứng chỉ bắt buộc do CCIB (cơ quan quản lý chất lượng & an toàn Trung Quốc) cấp.\n\n'
        'Bắt buộc với hầu hết sản phẩm sản xuất tại Trung Quốc hoặc nhập khẩu vào thị trường Trung Quốc.\n\n'
        'Tại VN: Thường thấy trên hàng điện tử, điện gia dụng, đồ chơi trẻ em xuất xứ Trung Quốc.',
    tag: SymbolTag.certification,
    tagLabel: 'Trung Quốc',
    icon: Icons.verified_rounded,
    color: Color(0xFF1A237E),
    badge: '🌍',
    symbolWidget: SymbolWidgetData(
        style: SymbolStyle.certBadge, text: 'CCC'),
  ),

  WasteSymbol(
    section: 'certification',
    title: 'FDA – Food & Drug Administration',
    subtitle: 'Cục Quản lý Thực phẩm & Dược phẩm Mỹ',
    description:
        'Chứng nhận FDA chủ yếu cho thực phẩm, mỹ phẩm và sản phẩm y tế — nhưng đôi khi gặp trên thiết bị điện tử chăm sóc sức khỏe.\n\n'
        'Ý nghĩa: Sản phẩm an toàn cho người sử dụng, chỉ phát bức xạ ở mức cho phép, không chứa chất độc hại cấm.\n\n'
        'Tại VN: Nhiều mỹ phẩm, thực phẩm chức năng nhập khẩu từ Mỹ mang FDA approval. Một số nhà sản xuất VN cũng đăng ký FDA để xuất khẩu sang Mỹ.',
    tag: SymbolTag.certification,
    tagLabel: 'Mỹ',
    icon: Icons.medical_services_outlined,
    color: Color(0xFF1A237E),
    badge: '🌍',
    symbolWidget: SymbolWidgetData(
        style: SymbolStyle.textBadge, text: 'FDA'),
  ),

  WasteSymbol(
    section: 'certification',
    title: 'Energy Star',
    subtitle: 'Tiết kiệm năng lượng – Bắc Mỹ, EU, Nhật, Úc',
    description:
        'Chứng nhận năng lượng có từ năm 1992, dùng ở Mỹ, Canada, EU, Nhật Bản, Đài Loan, Úc, New Zealand.\n\n'
        'Ý nghĩa: Sản phẩm tiêu thụ năng lượng ÍT HƠN 20–30% so với tiêu chuẩn tối thiểu.\n\n'
        'Thường thấy trên: Tủ lạnh, máy giặt, máy lạnh, TV, máy tính, bóng đèn, màn hình, máy in.\n\n'
        'Tương đương tại VN: Nhãn năng lượng 5 sao (Bộ Công Thương) — số sao càng nhiều, thiết bị càng tiết kiệm điện.',
    tag: SymbolTag.certification,
    tagLabel: 'Tiết kiệm NL',
    icon: Icons.star_rounded,
    color: Color(0xFF1A237E),
    badge: '🌍',
    symbolWidget: SymbolWidgetData(
      style: SymbolStyle.svg,
      svgString: _svgEnergyStar,
    ),
  ),

  WasteSymbol(
    section: 'certification',
    title: 'Nhãn năng lượng Việt Nam',
    subtitle: '1–5 sao – Bộ Công Thương cấp',
    description:
        'Tại VN, hầu hết thiết bị gia dụng (quạt, máy lạnh, tủ lạnh, đèn LED...) đều được dán nhãn năng lượng.\n\n'
        'Cách đọc: Số sao càng nhiều (tối đa 5 sao) → thiết bị càng tiết kiệm điện năng.\n\n'
        'Nhãn còn ghi rõ: Hãng sản xuất, nơi chế tạo, công suất, mức tiêu thụ điện hàng năm (kWh/năm).\n\n'
        'Mẫu nhỏ in trực tiếp trên sản phẩm (đèn LED, ổ cắm). Mẫu lớn dán nhãn riêng trên thiết bị lớn (tủ lạnh, điều hòa).',
    tag: SymbolTag.certification,
    tagLabel: 'Tiết kiệm NL',
    icon: Icons.star_rounded,
    color: Color(0xFF2E7D32),
    isVietnam: true,
    badge: '🇻🇳',
    symbolWidget: SymbolWidgetData(
      style: SymbolStyle.svg,
      svgString: _svgEnergyStar,
    ),
  ),

  // ══ NHÓM 7: Ký hiệu an toàn thực phẩm & bao bì ═══════════════════════════════

  WasteSymbol(
    section: 'food_symbols',
    title: 'Food Grade – Ly & Nĩa',
    subtitle: 'An toàn tiếp xúc trực tiếp với thực phẩm',
    description:
        'Hình chiếc ly và nĩa — một trong những dấu hiệu quan trọng nhất trên dụng cụ nhà bếp và bao bì thực phẩm.\n\n'
        'Ý nghĩa: Vật liệu làm sản phẩm AN TOÀN khi tiếp xúc trực tiếp với thức ăn — không chứa và không giải phóng hóa chất độc hại vào thực phẩm.\n\n'
        'Khi mua hộp đựng, chai lọ, màng bọc thực phẩm — luôn tìm ký hiệu này để đảm bảo an toàn.\n\n'
        'Theo tiêu chuẩn EU Regulation 10/2011 và FDA 21 CFR.',
    tag: SymbolTag.food,
    tagLabel: 'Food Safe',
    icon: Icons.restaurant_rounded,
    color: Color(0xFF2E7D32),
    badge: '🌍',
    symbolWidget: SymbolWidgetData(
      style: SymbolStyle.svg,
      svgString: _svgFoodGrade,
    ),
  ),

  WasteSymbol(
    section: 'food_symbols',
    title: 'Microwave Safe – An toàn lò vi sóng',
    subtitle: 'Có thể dùng trong lò vi sóng',
    description:
        'Hình lò vi sóng hoặc sóng zigzag trong hộp. Bao bì/hộp đựng này an toàn khi dùng trong lò vi sóng.\n\n'
        'Lưu ý quan trọng:\n'
        '• Chỉ nhựa PP (số 5) thường an toàn lò vi sóng\n'
        '• Nhựa PS (số 6/hộp xốp) KHÔNG được dùng lò vi sóng — giải phóng styrene độc hại\n'
        '• Nhựa PE, PVC, PET không an toàn với nhiệt cao\n\n'
        'Tại VN: Hộp Lock&Lock, Tupperware PP đều có ký hiệu này. Kiểm tra trước khi cho vào lò.',
    tag: SymbolTag.food,
    tagLabel: 'Lò vi sóng',
    icon: Icons.microwave_rounded,
    color: Color(0xFF2E7D32),
    badge: '🌍',
    symbolWidget: SymbolWidgetData(
      style: SymbolStyle.svg,
      svgString: _svgMicrowave,
    ),
  ),

  WasteSymbol(
    section: 'food_symbols',
    title: 'Freezer Safe – An toàn ngăn đá',
    subtitle: 'Có thể bảo quản trong ngăn đông/ngăn lạnh',
    description:
        'Hình bông tuyết hoặc nhiệt kế với nhiệt độ âm (-40°C). Bao bì này an toàn để bảo quản đông lạnh.\n\n'
        'Thường thấy trên: Hộp nhựa PP, túi zip đựng thực phẩm đông lạnh, hộp thủy tinh chịu nhiệt.\n\n'
        'Lưu ý: Không phải mọi hộp nhựa đều an toàn khi đông lạnh — khi đông lạnh, nhựa có thể giòn và vỡ, giải phóng hạt vi nhựa vào thực phẩm.',
    tag: SymbolTag.food,
    tagLabel: 'Đông lạnh',
    icon: Icons.ac_unit_rounded,
    color: Color(0xFF0277BD),
    badge: '🌍',
    symbolWidget: SymbolWidgetData(
      style: SymbolStyle.svg,
      svgString: _svgSnowflake,
    ),
  ),

  WasteSymbol(
    section: 'food_symbols',
    title: 'BPA Free – Không chứa BPA',
    subtitle: 'Không có Bisphenol A – an toàn hơn cho sức khỏe',
    description:
        'BPA (Bisphenol A) là chất hóa học dùng trong sản xuất nhựa polycarbonate (PC) và epoxy resin — có trong bình nước thể thao cứng, hộp bảo quản trong suốt, nắp lon đồ hộp.\n\n'
        'Nguy cơ: BPA là chất gây rối loạn nội tiết tố — đặc biệt nguy hiểm cho trẻ em, phụ nữ mang thai và thai nhi.\n\n'
        '"BPA Free" = nhà sản xuất khẳng định sản phẩm không dùng BPA.\n\n'
        'Tuy nhiên: Một số chất thay thế BPA (như BPS, BPF) cũng có thể gây nguy cơ tương tự.',
    tag: SymbolTag.food,
    tagLabel: 'BPA Free',
    icon: Icons.health_and_safety_rounded,
    color: Color(0xFF1B5E20),
    badge: '🌍',
    symbolWidget: SymbolWidgetData(
      style: SymbolStyle.textBadge,
      text: 'BPA\nFREE',
    ),
  ),

  WasteSymbol(
    section: 'food_symbols',
    title: 'DEHP Free – Không chứa phthalate',
    subtitle: 'Không có chất làm mềm nhựa độc hại',
    description:
        'DEHP (Di(2-ethylhexyl) phthalate) là chất làm mềm nhựa PVC — thuộc nhóm phthalate, chất gây rối loạn nội tiết.\n\n'
        '"DEHP Free" / "No Phthalates" = sản phẩm nhựa không dùng các chất làm mềm nguy hiểm này.\n\n'
        'Đặc biệt quan trọng với: Đồ chơi trẻ em, bình sữa, ống y tế, màng bọc thực phẩm.\n\n'
        'EU và nhiều nước đã cấm DEHP và các phthalate tương tự trong sản phẩm tiếp xúc thực phẩm và đồ chơi.',
    tag: SymbolTag.food,
    tagLabel: 'Phthalate Free',
    icon: Icons.health_and_safety_rounded,
    color: Color(0xFF1B5E20),
    badge: '🌍',
    symbolWidget: SymbolWidgetData(
      style: SymbolStyle.textBadge,
      text: 'DEHP\nFREE',
    ),
  ),

  // ══ NHÓM 8: Ký hiệu vận chuyển & bảo quản ════════════════════════════════════

  WasteSymbol(
    section: 'shipping',
    title: 'Fragile – Dễ vỡ',
    subtitle: 'Handle with Care – Thao tác nhẹ nhàng',
    description:
        'Hình chiếc ly vỡ (hoặc tay nâng hộp cẩn thận). Hàng hóa bên trong dễ vỡ, cần thao tác nhẹ nhàng.\n\n'
        'Thường in kèm chữ "FRAGILE" hoặc "HANDLE WITH CARE".\n\n'
        'Thấy trên: Hộp đựng đồ điện tử (điện thoại, màn hình), đồ thủy tinh, gốm sứ, đồ mỹ nghệ.\n\n'
        'Tại VN: Bạn có thể yêu cầu nhà vận chuyển (GHN, GHTK, J&T...) dán nhãn "Fragile" khi gửi hàng dễ vỡ.',
    tag: SymbolTag.shipping,
    tagLabel: 'Dễ vỡ',
    icon: Icons.warning_amber_rounded,
    color: Color(0xFF4E342E),
    badge: '🌍',
    symbolWidget: SymbolWidgetData(
      style: SymbolStyle.svg,
      svgString: _svgFragile,
    ),
  ),

  WasteSymbol(
    section: 'shipping',
    title: 'Keep Dry – Giữ khô ráo',
    subtitle: 'Tránh ẩm ướt và nước',
    description:
        'Hình ô dù với giọt nước bên dưới. Sản phẩm phải được giữ ở nơi khô ráo, tránh tiếp xúc với nước và độ ẩm cao.\n\n'
        'Thường thấy trên: Hàng điện tử, thực phẩm, thuốc, hóa chất, giấy tờ tài liệu.\n\n'
        'Đôi khi đi kèm ký hiệu gói hút ẩm silica gel để duy trì môi trường khô bên trong hộp.',
    tag: SymbolTag.shipping,
    tagLabel: 'Giữ khô',
    icon: Icons.umbrella_rounded,
    color: Color(0xFF4E342E),
    badge: '🌍',
    symbolWidget: SymbolWidgetData(
      style: SymbolStyle.svg,
      svgString: _svgUmbrella,
    ),
  ),

  WasteSymbol(
    section: 'shipping',
    title: 'This Way Up – Chiều đặt hàng',
    subtitle: 'Hai mũi tên chỉ lên – đặt đúng chiều',
    description:
        'Hai mũi tên chỉ lên (↑↑). Kiện hàng phải được đặt theo chiều mũi tên chỉ — KHÔNG lật ngược.\n\n'
        'Quan trọng với: Thiết bị có chất lỏng bên trong, pin, thiết bị điện tử nhạy cảm, cây cối sống.\n\n'
        'Nếu lật ngược có thể gây rò rỉ, hư hỏng linh kiện hoặc chết cây.',
    tag: SymbolTag.shipping,
    tagLabel: 'Chiều đặt',
    icon: Icons.arrow_upward_rounded,
    color: Color(0xFF4E342E),
    badge: '🌍',
    symbolWidget: SymbolWidgetData(
      style: SymbolStyle.svg,
      svgString: _svgArrowsUp,
    ),
  ),

  WasteSymbol(
    section: 'shipping',
    title: 'Temperature Range – Nhiệt độ bảo quản',
    subtitle: 'Hình nhiệt kế với max/min – khoảng nhiệt độ cho phép',
    description:
        'Hình nhiệt kế kèm nhiệt độ tối đa và tối thiểu. Chỉ định khoảng nhiệt độ an toàn để bảo quản sản phẩm.\n\n'
        'Ví dụ: Nhiệt kế với "+25°C / -18°C" = bảo quản ở nhiệt độ từ -18°C đến +25°C.\n\n'
        'Quan trọng với: Dược phẩm, vaccine, thực phẩm tươi sống, hóa chất nhạy nhiệt.\n\n'
        'Tại VN: Đặc biệt quan trọng trong chuỗi lạnh (cold chain) vận chuyển hải sản, thịt, sữa tươi.',
    tag: SymbolTag.shipping,
    tagLabel: 'Nhiệt độ',
    icon: Icons.thermostat_rounded,
    color: Color(0xFF4E342E),
    badge: '🌍',
    symbolWidget: SymbolWidgetData(
      style: SymbolStyle.svg,
      svgString: _svgThermometer,
    ),
  ),

  WasteSymbol(
    section: 'shipping',
    title: 'Stacking Limit – Giới hạn chồng hàng',
    subtitle: 'Số lượng tối đa kiện hàng được chồng lên nhau',
    description:
        'Hình các hộp chồng lên nhau với con số bên trên. Con số cho biết số lượng kiện hàng tối đa được phép chồng.\n\n'
        'Ví dụ: Số "5" = chỉ được chồng tối đa 5 kiện lên nhau.\n\n'
        'Chồng quá giới hạn có thể làm biến dạng bao bì, hỏng sản phẩm bên trong, thậm chí sập đống hàng gây tai nạn.',
    tag: SymbolTag.shipping,
    tagLabel: 'Giới hạn chồng',
    icon: Icons.layers_rounded,
    color: Color(0xFF4E342E),
    badge: '🌍',
    symbolWidget: SymbolWidgetData(
      style: SymbolStyle.svg,
      svgString: _svgStacking,
    ),
  ),

  WasteSymbol(
    section: 'shipping',
    title: 'Do Not Use Hand Hook – Không dùng móc',
    subtitle: 'Cấm dùng móc để nâng/di chuyển hàng',
    description:
        'Hình móc cẩu bị gạch chéo. Cảnh báo KHÔNG sử dụng móc cẩu hoặc móc kim loại để nâng, di chuyển kiện hàng.\n\n'
        'Lý do: Bao bì mỏng hoặc sản phẩm bên trong nhạy cảm với lực tác dụng điểm — móc có thể xuyên thủng hoặc gây biến dạng.\n\n'
        'Thường gặp trên: Hàng đóng gói trong túi nhựa, hàng đóng trong hộp carton mỏng, hàng mềm.',
    tag: SymbolTag.shipping,
    tagLabel: 'Không dùng móc',
    icon: Icons.not_interested_rounded,
    color: Color(0xFF4E342E),
    badge: '🌍',
    symbolWidget: SymbolWidgetData(
      style: SymbolStyle.svg,
      svgString: _svgNoHook,
    ),
  ),

  WasteSymbol(
    section: 'shipping',
    title: 'Keep Frozen – Bảo quản đông lạnh',
    subtitle: 'Hình bông tuyết – phải giữ đông lạnh liên tục',
    description:
        'Hình bông tuyết ❄️ hoặc hộp với biểu tượng đông lạnh. Sản phẩm phải được bảo quản trong trạng thái đông lạnh liên tục.\n\n'
        'Khác với "Freezer Safe": "Keep Frozen" = BẮT BUỘC đông lạnh (thực phẩm đông lạnh, vaccine, mẫu sinh học). "Freezer Safe" = CÓ THỂ đông lạnh được.\n\n'
        'Tại VN: Quan trọng trong chuỗi lạnh vận chuyển tôm cá đông lạnh, thịt, các sản phẩm đông lạnh xuất khẩu.',
    tag: SymbolTag.shipping,
    tagLabel: 'Đông lạnh BẮT BUỘC',
    icon: Icons.ac_unit_rounded,
    color: Color(0xFF0277BD),
    badge: '🌍',
    symbolWidget: SymbolWidgetData(
      style: SymbolStyle.svg,
      svgString: _svgSnowflake,
    ),
  ),

  WasteSymbol(
    section: 'shipping',
    title: 'Use Trolley – Dùng xe đẩy',
    subtitle: 'Hàng nặng – cần xe đẩy để di chuyển',
    description:
        'Hình xe đẩy hàng. Kiện hàng quá nặng để một người nhấc — cần sử dụng xe đẩy hàng (pallet jack, hand truck) để di chuyển an toàn.\n\n'
        'Thường kèm thông tin trọng lượng trên nhãn (kg). Nhằm bảo vệ người lao động khỏi chấn thương cột sống và cơ bắp.',
    tag: SymbolTag.shipping,
    tagLabel: 'Xe đẩy',
    icon: Icons.shopping_cart_rounded,
    color: Color(0xFF4E342E),
    badge: '🌍',
    symbolWidget: SymbolWidgetData(
      style: SymbolStyle.svg,
      svgString: _svgTrolley,
    ),
  ),
];

// ══════════════════════════════════════════════════════════════════════════════
// HELPER CLASSES
// ══════════════════════════════════════════════════════════════════════════════

class _SectionHeader {
  final String title;
  final String subtitle;
  final String flag;
  final int count;
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.flag,
    required this.count,
  });
}

class _SymbolItem {
  final WasteSymbol symbol;
  final int globalIdx;
  const _SymbolItem({required this.symbol, required this.globalIdx});
}

// ══════════════════════════════════════════════════════════════════════════════
// SCREEN
// ══════════════════════════════════════════════════════════════════════════════

class WasteSymbolsScreen extends StatefulWidget {
  const WasteSymbolsScreen({super.key});

  @override
  State<WasteSymbolsScreen> createState() => _WasteSymbolsScreenState();
}

class _WasteSymbolsScreenState extends State<WasteSymbolsScreen> {
  int? _expandedIndex;
  String _filter = 'all';

  Widget _buildStructuredDescription(String description, Color primaryColor) {
    final blocks = description.split('\n\n');
    final List<Widget> children = [];

    for (int i = 0; i < blocks.length; i++) {
      var block = blocks[i].trim();
      if (block.isEmpty) continue;

      // 1. Check if it's a bullet point list
      if (block.contains('•') || block.startsWith('•') || block.contains('\n•')) {
        final lines = block.split('\n');
        final List<String> listItems = [];
        String? title;
        
        for (final line in lines) {
          final trimmed = line.trim();
          if (trimmed.startsWith('•')) {
            listItems.add(trimmed.substring(1).trim());
          } else if (trimmed.startsWith('-')) {
            listItems.add(trimmed.substring(1).trim());
          } else if (trimmed.isNotEmpty) {
            title = trimmed;
          }
        }

        if (listItems.isNotEmpty) {
          children.add(
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primaryColor.withValues(alpha: 0.12)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null) ...[
                    Text(
                      title.replaceAll(':', ''),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                        color: primaryColor,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  ...listItems.map((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 5.5),
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            item,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black87,
                              height: 1.45,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          );
          continue;
        }
      }

      // 2. Check if it's a key-value property block (e.g. "Chịu nhiệt: ...", "Dùng cho: ...")
      final colonIdx = block.indexOf(':');
      if (colonIdx > 0 && colonIdx < 25 && !block.startsWith('http') && !block.contains('\n')) {
        final key = block.substring(0, colonIdx).trim();
        final val = block.substring(colonIdx + 1).trim();
        
        final isWarning = val.contains('KHÔNG') || val.contains('⚠️') || val.contains('NGUY HẠI') || val.contains('tuyệt đối không') || val.contains('Cấm') || key.contains('Nguy hại') || key.contains('Cảnh báo') || key.contains('Đáng lo ngại') || key.contains('ĐÁNG LO NGẠI');
        final accentColor = isWarning ? const Color(0xFFC62828) : primaryColor;
        final bgColor = isWarning ? const Color(0xFFC62828).withValues(alpha: 0.05) : Colors.white;
        final borderColor = isWarning ? const Color(0xFFC62828).withValues(alpha: 0.18) : primaryColor.withValues(alpha: 0.12);

        children.add(
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (isWarning) ...[
                      Icon(Icons.warning_amber_rounded, color: accentColor, size: 16),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      key,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                        color: accentColor,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  val,
                  style: TextStyle(
                    fontSize: 13,
                    color: isWarning ? const Color(0xFFB71C1C) : Colors.black87,
                    height: 1.45,
                    fontWeight: isWarning ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
        continue;
      }

      // 3. Check if it's a warning or callout block
      final isWarningBlock = block.startsWith('⚠️') || 
                             block.startsWith('KHÔNG') || 
                             block.startsWith('Lưu ý:') || 
                             block.startsWith('Nguy cơ:') ||
                             block.startsWith('ĐÁNG LO NGẠI:') || 
                             block.contains('nguy hiểm') ||
                             block.startsWith('Cảnh báo:') ||
                             block.contains('tuyệt đối không') ||
                             block.contains('Tuyệt đối không');

      if (isWarningBlock) {
        final accentColor = const Color(0xFFC62828);
        children.add(
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accentColor.withValues(alpha: 0.18)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, color: accentColor, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    block,
                    style: TextStyle(
                      color: accentColor.withValues(alpha: 0.95),
                      fontSize: 13,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        continue;
      }

      // 4. Default description block
      final isIntro = i == 0;
      children.add(
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 12),
          padding: isIntro ? const EdgeInsets.all(14) : EdgeInsets.zero,
          decoration: isIntro
              ? BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: primaryColor.withValues(alpha: 0.08)),
                )
              : null,
          child: Text(
            block,
            style: TextStyle(
              color: isIntro ? Colors.black87 : Colors.grey[800],
              fontSize: isIntro ? 13.5 : 13,
              fontWeight: isIntro ? FontWeight.w500 : FontWeight.normal,
              height: 1.55,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  List<dynamic> _buildItems() {
    final List<dynamic> items = [];
    for (final section in _sections) {
      final key = section['key'] as String;
      final flag = section['flag'] as String;
      if (_filter == 'vn' && flag != '🇻🇳') continue;
      if (_filter == 'intl' && flag != '🌍') continue;

      final symbolsInSection =
          _symbols.where((s) => s.section == key).toList();
      if (symbolsInSection.isEmpty) continue;

      items.add(_SectionHeader(
        title: section['title'] as String,
        subtitle: section['subtitle'] as String,
        flag: flag,
        count: symbolsInSection.length,
      ));
      for (final sym in symbolsInSection) {
        items.add(_SymbolItem(
          symbol: sym,
          globalIdx: _symbols.indexOf(sym),
        ));
      }
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final items = _buildItems();
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      appBar: AppBar(
        title: const Text(
          'Ký hiệu rác thải & bao bì',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child:
              Container(height: 1, color: Colors.black.withValues(alpha: 0.06)),
        ),
      ),
      body: Column(
        children: [
          // ── Filter chips ──
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(0, 10, 0, 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _FilterChip(
                    label: 'Tất cả',
                    selected: _filter == 'all',
                    onTap: () => setState(() => _filter = 'all'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: '🇻🇳 Việt Nam',
                    selected: _filter == 'vn',
                    onTap: () => setState(() => _filter = 'vn'),
                    selectedColor: const Color(0xFFDA251D),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: '🌍 Quốc tế',
                    selected: _filter == 'intl',
                    onTap: () => setState(() => _filter = 'intl'),
                    selectedColor: const Color(0xFF1565C0),
                  ),
                ],
              ),
            ),
          ),

          // ── List ──
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 32),
              itemCount: items.length,
              itemBuilder: (ctx, i) {
                final item = items[i];
                if (item is _SectionHeader) return _buildSectionHeader(item);
                if (item is _SymbolItem) return _buildSymbolCard(item);
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(_SectionHeader h) {
    final isVN = h.flag == '🇻🇳';
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isVN
            ? const Color(0xFFDA251D).withValues(alpha: 0.07)
            : Colors.blueGrey.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isVN
              ? const Color(0xFFDA251D).withValues(alpha: 0.18)
              : Colors.blueGrey.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        children: [
          Text(h.flag, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  h.title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.black87),
                ),
                const SizedBox(height: 2),
                Text(
                  h.subtitle,
                  style: TextStyle(fontSize: 11.5, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isVN
                  ? const Color(0xFFDA251D).withValues(alpha: 0.12)
                  : Colors.blueGrey.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${h.count} loại',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color:
                    isVN ? const Color(0xFFDA251D) : Colors.blueGrey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSymbolCard(_SymbolItem item) {
    final s = item.symbol;
    final idx = item.globalIdx;
    final isExpanded = _expandedIndex == idx;
    final tagColor = _tagColor(s.tag);
    final tagBg = _tagBg(s.tag);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isExpanded
              ? tagColor.withValues(alpha: 0.3)
              : Colors.black.withValues(alpha: 0.06),
          width: isExpanded ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isExpanded ? 0.06 : 0.03),
            blurRadius: isExpanded ? 12 : 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => setState(
              () => _expandedIndex = isExpanded ? null : idx,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                  child: Row(
                    children: [
                      // Symbol badge
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: tagBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: s.symbolWidget != null
                            ? Center(
                                child: buildSymbolWidget(
                                  s.symbolWidget!,
                                  tagColor,
                                  size: 46,
                                ),
                              )
                            : Icon(s.icon, color: tagColor, size: 28),
                      ),
                      const SizedBox(width: 12),
                      // Text info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    s.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                                if (s.badge != null) ...[
                                  const SizedBox(width: 6),
                                  Text(s.badge!,
                                      style: const TextStyle(fontSize: 13)),
                                ],
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              s.subtitle,
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 12.5),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Tag + chevron
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: tagBg,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              s.tagLabel,
                              style: TextStyle(
                                color: tagColor,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          AnimatedRotation(
                            turns: isExpanded ? 0.5 : 0,
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: Colors.grey[400],
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── Expanded description ──
                if (isExpanded)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFBFBFA),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.black.withValues(alpha: 0.04),
                      ),
                    ),
                    child: _buildStructuredDescription(s.description, tagColor),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// FILTER CHIP WIDGET
// ══════════════════════════════════════════════════════════════════════════════

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? selectedColor;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.selectedColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = selectedColor ?? const Color(0xFF37474F);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color.withValues(alpha: 0.4) : Colors.grey[300]!,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            color: selected ? color : Colors.grey[600],
          ),
        ),
      ),
    );
  }
}
